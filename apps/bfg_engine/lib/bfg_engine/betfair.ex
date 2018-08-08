defmodule BfgEngine.RestConnection do
  use Connection
  require Logger

  @loggin_attempts 3
  @keep_alive_ms Application.get_env(:bfg_engine, :keep_alive_ms)

  alias BfgEngine.API.Betfair.{Login, SessionManagement, Betting}

  def start_link(username, password, app_key) do
    Connection.start_link(__MODULE__, {username, password, app_key}, name: __MODULE__)
  end

  def list_market_catalogue() do
    send_betting(%{endpoint: "/listMarketCatalogue", body: BfgEngine.Filters.Betfair.default_race_card_request()})
  end

  @doc """
  Response if ok request
    {:ok,
      %{
        instructionReports: [
          %{
            instruction: %{
              limitOrder: %{persistenceType: "LAPSE", price: 1.01, size: 2.0},
              orderType: "LIMIT",
              selectionId: 10721835,
              side: "LAY"
            },
            orderStatus: "PENDING",
            status: "SUCCESS"
          }
        ],
        marketId: "1.146054800",
        status: "SUCCESS"
  }}
  ref can max be 15 char long
  """
  def place_orders(selection_id, size, price, market_id, side, ref) do
    send_betting(%{endpoint: "/placeOrders", body: BfgEngine.Filters.Betfair.place_orders_request(size, price, market_id, selection_id, side, ref)})
  end

  @doc """
    {:ok,
  %{
    instructionReports: [
      %{
        cancelledDate: "2018-07-28T06:01:58.000Z",
        instruction: %{betId: "131983282857"},
        sizeCancelled: 2.0,
        status: "SUCCESS"
      }
    ],
    marketId: "1.146054760",
    status: "SUCCESS"
  }}
  """
  def cancel_orders(market_id, bet_id) do
    send_betting(%{endpoint: "/cancelOrders", body: BfgEngine.Filters.Betfair.cancel_orders_request(market_id, bet_id)})
  end

  defp send_betting(%{endpoint: endpoint, body: body} = data) when is_map(body) and is_bitstring(endpoint) do
    Connection.call(__MODULE__, {:send_betting, data})
  end

  def close(), do: Connection.call(__MODULE__, :close)

  def init({username, password, app_key}) do
    s = %{
      username: username,
      password: password,
      app_key: app_key,
      session_token: nil,
      login_time: nil,
      last_keep_alive: nil,
      login_attempts: 3}
    {:connect, :init, s}
  end

  def subscribe(markets) do
    Connection.call(__MODULE__, {:subscribe, markets})
  end

  def connect(_, %{username: username, password: password} = s) do
    body = %{username: username, password: password}

    "/certlogin"
    |> Login.post(body)
    |> handle_login_response(s)
  end

  def disconnect(info, %{app_key: app_key, session_token: session_token} = s) do
    headers = ["X-Application": app_key, "X-Authentication": session_token]
    "/logout" # TODO do i need any error handling here?
    |> SessionManagement.post("", headers)
    case info do
      {:close, from} ->
        Logger.info("Logging out from betfair")
        Connection.reply(from, :ok)
      {:error, :closed} ->
        Logger.error("Connection closed")
      {:error, reason} ->
        Logger.error("Connection error: #{inspect reason}")
    end
    {:stop, :disconnected, s}
  end

  def handle_call({:subscribe, markets}, from, %{session_token: session_token, app_key: app_key} = s) do
    BfgEngine.MarketStream.Betfair.start_link(session_token, app_key, markets)
    {:reply, :ok, s}
  end

  def handle_call(:close, from, s) do
    {:disconnect, {:close, from}, s}
  end

  @doc """
  Happy path, everything went fine,
  reset login attempts, set login time, set session token
  """
  def handle_login_response(
        {:ok, %{status_code: 200, body: %{loginStatus: "SUCCESS", sessionToken: session_token}}},
        s
      ) do
    Logger.info(fn -> "Login sucessful with token #{session_token}" end)
    schedule_keep_alive()
    s = %{
      s
      | login_attempts: @loggin_attempts,
        login_time: Timex.now(),
        session_token: session_token
    }

    {:ok, s}
  end

  @doc """
  When login fails and we have NOT expired all login attempts
  wait 4 seconds and try again
  """
  def handle_login_response(
        {:ok, %{status_code: status_code, body: body}},
        %{login_attempts: login_attempts} = s
      )
      when login_attempts > 0 do
    Logger.warn("Retry login after status code: #{status_code} and maybe etfair status #{body[:loginStatus]}")
    s = %{s | login_attempts: s.login_attempts - 1}
    {:backoff, 4000, s}
  end

  @doc """
  When login fails and no more login attempts
  """
  def handle_login_response(_, s) do
    Logger.error("Login failed Betfair")
    {:stop, :login_failed, s}
  end

  def handle_info(:keep_alive, %{app_key: app_key, session_token: session_token} = s) do
    headers = ["X-Application": app_key, "X-Authentication": session_token]
    "/keepAlive"
    |> SessionManagement.post("", headers)
    |> handle_keep_alive_response(s)
  end

  @doc """
  Happy path when all is well
  Update the time for keep alive and reshedule the job
  """
  def handle_keep_alive_response({:ok, %{status_code: 200, body: %{error: "", status: "SUCCESS"}}}, s) do
    schedule_keep_alive()
    {:noreply, %{s | last_keep_alive: Timex.now}}
  end

  @doc """
  Handle INVALID_SESSION_TOKEN
  You should ensure that you handle the INVALID_SESSION_TOKEN error
  within your code by creating a new session token via the API
  login method.
  """
  def handle_keep_alive_response({:ok, %{status_code: 200, body: %{error: "INVALID_SESSION_TOKEN", status: "FAIL"}}}, s) do
    Logger.warn("Session has expired INVALID_SESSION_TOKEN will try to reconnect")
    {:connect, nil, s}
  end

  @doc """
  All other problems try desperate to reconnect
  """
  def handle_keep_alive_response(_, s) do
    Logger.error("Keep alive failed trying to reconnect")
    {:connect, nil, s}
  end

  defp schedule_keep_alive() do
    Process.send_after(self(), :keep_alive, @keep_alive_ms)
  end

  def handle_call({:send_betting, %{endpoint: endpoint, body: body} = data}, _, %{app_key: app_key, session_token: session_token} = s) do
    headers = ["X-Application": app_key, "X-Authentication": session_token]
    endpoint
    |> Betting.post(body, headers)
    |> handle_response(s)
  end

  @doc """
  Happy path when the request is possible
  """
  def handle_response({:ok, %{status_code: 200, body: {:ok, body}}}, s) do
    Logger.debug(fn -> "Response from betting #{inspect body}" end)
    {:reply, {:ok, body}, s}
  end

  @doc """
  Sad path an error se docs
  {:ok, %{detail: %{}, faultcode: "Client", faultstring: "DSC-0021"}} -> status code 404 se docs for error types
  {:error, {:invalid, <<31>>, 0}} -> another error type
  """
  def handle_response(r, s) do
    Logger.error("Response from betting #{inspect r}")
    {:reply, {:error, r}, s}
  end
end

defmodule BfgEngine.Filters.Betfair do
  use Timex

  def default_race_card_request() do
    %{
      filter: %{
        eventTypeIds: ["7"],
        marketTypeCodes: ["WIN"],
        marketCountries: ["GB"],
        marketStartTime: %{
          from: to_string(Timex.today) <> "T00:00:00Z",
          to: to_string(Timex.shift(Timex.today, days: 1)) <> "T23:59:00Z"
        }
      },
      marketProjection: [
        "MARKET_START_TIME",
        "RUNNER_DESCRIPTION"
      ],
      # sort: "FIRST_TO_START",
      maxResults: 3
  }
  end

  def place_orders_request(size, price, market_id, selection_id, side, ref, async \\ true) when side == "LAY" or side == "BACK" do
    instruction =  %{
      selectionId: selection_id,
      side: side,
      orderType: "LIMIT",
      limitOrder: %{
      size: size,
      price: price,
      persistenceType: "LAPSE"
      }
      }
    %{
      marketId: market_id,
      instructions: [instruction],
      customerStrategyRef: ref,
      async: async
    }
  end

  def cancel_orders_request(market_id, bet_id) do
    instruction = %{
      betId: bet_id
    }
    %{
      marketId: market_id,
      instructions: [instruction]
  }
  end
end

defmodule BfgEngine.Client.Betfair do
  alias BfgEngine.API.Betfair.{Login, SessionManagement}
  @betting_url "https://api.betfair.com/exchange/betting/rest/v1.0"
  @account_url "https://api.betfair.com/exchange/account/rest/v1.0"
  @session_management_url "https://identitysso.betfair.com/api"

  @doc """
  curl -q -k --cert client-2048.crt --key client-2048.key
  https://identitysso.betfair.com/api/certlogin -d
  "username=testuser&password=testpassword" -H "X-Application:
  curlCommandLineTest"
  If successful return {:ok, sessionToken}
  {
  sessionToken: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
  loginStatus: SUCCESS;
  }

  logg at error level also
  If not SUCCESS return {:error, <login status>}
  {
  loginStatus: INVALID_USERNAME_OR_PASSWORD;
  }
  """
  def login(%{username: username, password: password, app_key: app_key}) do
    body = %{username: username, password: password}

    case Login.post!("/certlogin", body) do
      %HTTPoison.Response{
        status_code: 200,
        body: [loginStatus: "SUCCESS", sessionToken: session_token]
      } ->
        {:ok, session_token}

      %HTTPoison.Response{status_code: 200, body: [loginStatus: login_status]} ->
        {:error, login_status}

      %HTTPoison.Response{status_code: status_code} ->
        {:error, status_code}
    end
  end

  @doc """
  You can use Keep Alive to extend the session timeout period. The minimum session time is currently 20 minutes (Italian Exchange). On the inte
  rnational (.com) Exchange the current session time is 4 hours. Therefore, you should request Keep Alive within this time to prevent session
  expiry. If you don't call Keep Alive within the specified timeout period, the session will expire. Please note: Session times aren't determined or
  extended based on API activity.

  {
    "token":"<token_passed_as_header>",
    "product":"product_passed_as_header",
    "status":"<status>",
    "error":"<error>"
  }

  status
  SUCCESS
  FAIL -> log error
  """
  def keep_alive(%{session_token: session_token, app_key: app_key}) do
    # TODO keep alive should be handled here in betfair since its a
    # betfair thing, i should make betfair a genserver and move all state here
    headers = ["X-Application": app_key, "X-Authentication": session_token]

    case SessionManagement.post!("/keepAlive", "", headers) do
      %HTTPoison.Response{status_code: 200, body: [error: "", status: "SUCCESS"]} ->
        {:ok, :success}

      %HTTPoison.Response{status_code: 200, body: [error: error, status: "FAIL"]} ->
        {:error, error}

      %HTTPoison.Response{status_code: status_code} ->
        {:error, status_code}
    end
  end

  @doc """
  {
    "token":"<token_passed_as_header>",
    "product":"product_passed_as_header",
    "status":"<status>",
    "error":"<error>"
  }

  status
  SUCCESS
  FAIL -> log error
  """
  def logout(%{session_token: session_token, app_key: app_key}) do
    headers = ["X-Application": app_key, "X-Authentication": session_token]

    case SessionManagement.post!("/logout", "", headers) do
      %HTTPoison.Response{status_code: 200, body: [error: "", status: "SUCCESS"]} ->
        {:ok, :success}

      %HTTPoison.Response{status_code: 200, body: [error: error, status: "FAIL"]} ->
        {:error, error}

      %HTTPoison.Response{status_code: status_code} ->
        {:error, status_code}
    end
  end

  # defp get_client(:login) do
  #   Tesla.build_client [
  #     {Tesla.Middleware.BaseUrl, @session_management_url},
  #     {Tesla.Middleware.Retry, delay: 500, max_retries: 10},
  #     {Tesla.Middleware.FormUrlencoded},
  #     {Tesla.Middleware.JSON},
  #     {Tesla.Middleware.Logger},
  #     {Tesla.Middleware.Timeout, timeout: 2_000},
  #     {Tesla.Middleware.Headers, [
  #       {"X-Application", "1"},
  #     ]}
  #   ]
  # end

  # defp get_client(:session, session_token) do
  #   Tesla.build_client [
  #     {Tesla.Middleware.BaseUrl, @session_management_url},
  #     {Tesla.Middleware.Retry, delay: 500, max_retries: 10},
  #     {Tesla.Middleware.FormUrlencoded},
  #     {Tesla.Middleware.Headers, [
  #       {"X-Authentication", session_token},
  #       {"X-Application", "1"}
  #     ]}
  #   ]
  # end

  # @doc """
  # We would therefore recommend that all Betfair API request are sent with the ‘Accept-Encoding: gzip, deflate’ request header.
  # We recommend that Connection: keep-alive header is set for all requests to guarantee a persistent connection and therefore reducing latency.
  # """
  # defp get_client(:betting, app_key, session_token) do
  #   Tesla.build_client [
  #     {Tesla.Middleware.BaseUrl, @betting_url},
  #     {Tesla.Middleware.Compression, format: "gzip"},
  #     {Tesla.Middleware.Headers, [
  #       {"X-Application", app_key},
  #       {"X-Authentication", session_token},
  #       {"Connection", "keep-alive"}
  #     ]}
  #   ]
  # end

  # defp get_client(:account, app_key, session_token) do
  #   Tesla.build_client [
  #     {Tesla.Middleware.BaseUrl, @account_url},
  #     {Tesla.Middleware.Compression, format: "gzip"},
  #     {Tesla.Middleware.Headers, [
  #       {"X-Application", app_key},
  #       {"X-Authentication", session_token},
  #     ]}
  #   ]
  # end
end

defmodule BfgEngine.API.Betfair.Login do
  @moduledoc """
    curl -q -k --cert client-2048.crt --key client-2048.key
  https://identitysso.betfair.com/api/certlogin -d
  "username=testuser&password=testpassword" -H "X-Application:
  curlCommandLineTest"
  If successful return {:ok, sessionToken}
  {
  sessionToken: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
  loginStatus: SUCCESS;
  }

  logg at error level also
  If not SUCCESS return {:error, <login status>}
  {
  loginStatus: INVALID_USERNAME_OR_PASSWORD;
  }
  """
  use HTTPoison.Base

  @base_url Application.get_env(:bfg_engine, :session_managemenet_url)

  @expected_fields ~w(sessionToken loginStatus)

  def process_url(resource) do
    @base_url <> resource
  end

  def process_request_headers(_headers) do
    [
      "X-Application": "1",
      "content-type": "application/x-www-form-urlencoded",
      Accept: "Application/json; Charset=utf-8"
    ]
  end

  def process_response_body(body) do
    body
    |> Poison.Parser.parse!(keys: :atoms)
  end

  def process_request_body(%{username: username, password: password}) do
    "username=#{URI.encode_www_form(username)}&password=#{URI.encode_www_form(password)}"
  end

  def process_request_options(_options) do
    [
      ssl: [
        certfile: "/certs/client-2048.crt",
        keyfile: "/certs/client-2048.key"
      ]
    ]
  end
end

defmodule BfgEngine.API.Betfair.SessionManagement do
  use HTTPoison.Base

  @base_url Application.get_env(:bfg_engine, :session_managemenet_url)

  def process_url(resource) do
    @base_url <> resource
  end

  def process_request_headers(headers) do
    headers ++
      [
        "content-type": "Application/json; Charset=utf-8",
        Accept: "Application/json; Charset=utf-8"
      ]
  end

  def process_response_body(body) do
    body
    |> Poison.Parser.parse(keys: :atoms)
  end

  def process_request_body(body) do
    body
    |> Poison.encode!()
  end
end

defmodule BfgEngine.API.Betfair.Betting do
  use HTTPoison.Base

  @base_url Application.get_env(:bfg_engine, :betting_url)

  def process_url(resource) do
    @base_url <> resource <> "/" # last / is importatnt else method is not found at betfair side
  end

  def process_request_headers(headers) do
    headers ++
      [
        "content-type": "Application/json; Charset=utf-8",
        "Accept": "Application/json; Charset=utf-8",
        "content-type": "application/json",
        "Accept-Encoding": "gzip, deflate",
        "Connection": "keep-alive"
      ]
  end

  @doc """
  It looks like error messages are not gziped in the response only correct messages
  example
  "{\"faultcode\":\"Client\",\"faultstring\":\"ANGX-0002\",\"detail\":{\"APINGException\":{\"requestUUID\":\"prdang038-05150915-01817065f9\",\"errorCode\":\"INVALID_INPUT_DATA\",\"errorDetails\":\"The customerStrategyRef is too long (15 character limit)\"},\"exceptionname\":\"APINGException\"}}"
  """
  def process_response_body(body) do
    # TODO i should only gunzip if it needed when i get error i should not do it for example change appkey to something invalid and try
    body
    |> :zlib.gunzip() # Is needed since the body is gziped
    |> Poison.Parser.parse(keys: :atoms)
  end

  def process_request_body(body) do
    body
    |> Poison.encode!()
  end
end

defmodule BfgEngine.MarketStream.Betfair do
  @moduledoc """
  %% The client is implemented as a gen_server which keeps one socket
  %% open to a single Redis instance. Users call us using the API in
  %% eredis.erl.
  %%
  %% The client works like this:
  %%  * When starting up, we connect to Redis with the given connection
  %%     information, or fail.
  %%  * Users calls us using gen_server:call, we send the request to Redis,
  %%    add the calling process at the end of the queue and reply with
  %%    noreply. We are then free to handle new requests and may reply to
  %%    the user later.
  %%  * We receive data on the socket, we parse the response and reply to
  %%    the client at the front of the queue. If the parser does not have
  %%    enough data to parse the complete response, we will wait for more
  %%    data to arrive.
  %%  * For pipeline commands, we include the number of responses we are
  %%    waiting for in each element of the queue. Responses are queued until
  %%    we have all the responses we need and then reply with all of them.
  """
  use Connection
  require Logger

  @stream_url Application.get_env(:bfg_engine, :stream_url)
  @stream_port Application.get_env(:bfg_engine, :stream_port)
  @ladder_levels Application.get_env(:bfg_engine, :ladder_levels)
  @keep_alive_timeout 5000 # TODO use this when subscribing to stream now i use the default

  @initial_state %{socket: nil, connection_id: nil, session_token: nil, app_key: nil, counter: 0, markets: nil, msg: "", keep_alive_ref: nil}

  @doc """
  subscriber should be the pid of the process to recive all messages from tcp socket
  """
  def start_link(session_token, app_key, markets) when is_list(markets) do
    s = %{@initial_state | session_token: session_token, app_key: app_key, markets: markets}
    Connection.start_link(__MODULE__, s, name: __MODULE__)
  end

  def send_msg(data), do: Connection.cast(__MODULE__, {:send, data})

  def recv(bytes, timeout \\ 3000) do
    Connection.call(__MODULE__, {:recv, bytes, timeout})
  end

  def close(), do: Connection.call(__MODULE__, :close)

  def init(state) do
    # Dont block the caller in init just calls connect passing nil as args
    {:connect, nil, state}
  end

  def connect(:backoff, state) do
    IO.puts("Retrying TCP connection")
    opts = [:binary, active: :once]

    case :ssl.connect('stream-api.betfair.com', 443, opts) do
      {:ok, socket} ->
        {:ok, %{state | socket: socket}}

      {:error, reason} ->
        IO.puts("TCP backoff connection error: #{inspect(reason)}")
        {:stop, :unable_to_connect, state}
    end
  end

  @doc """
  Poison.Parser.parse("{\"op\":\"status\",\"statusCode\":\"FAILURE\",\"errorCode\":\"TIMEOUT\",\"errorMessage\":\"Connection is not subscribed and is idle: 15000 ms\",\"connectionClosed\":true,\"connectionId\":\"009-110718210240-331184\"}\r\n", keys: :atoms)
  {:ok,
  %{
   connectionClosed: true,
   connectionId: "009-110718210240-331184",
   errorCode: "TIMEOUT",
   errorMessage: "Connection is not subscribed and is idle: 15000 ms",
   op: "status",
   statusCode: "FAILURE"
  }}
  """
  def connect(_info, state) do
    opts = [:binary, active: :once]

    case :ssl.connect(@stream_url, @stream_port, opts) do
      {:ok, socket} ->
        IO.puts("TCP connection established")
        {:ok, %{state | socket: socket}}

      {:error, reason} ->
        IO.puts("TCP connection error: #{inspect(reason)}")
        # Try again in 1second
        {:backoff, 1000, state}
    end

    # On establishing a connection a client receives a ConnectionMessage
    # {"op":"connection","connectionId":"002-230915140112-174"}
    # {:ok, msg} = :gen_tcp.recv(socket, 0) # Is blocking
    # TODO patternmatch on the recived message and then authenticate with the socket so it wont close
    # IO.inspect(msg)
    # {:ok, %{state | socket: socket, tls_socket: tls_socket}}
  end

  def disconnect(info, %{socket: sock} = s) do
    :ok = :ssl.close(sock)

    case info do
      {:close, from} ->
        Connection.reply(from, :ok)

      {:error, :closed} ->
        :error_logger.format("Connection closed~n", [])

      {:error, reason} ->
        reason = :inet.format_error(reason)
        :error_logger.format("Connection error: ~s~n", [reason])
    end

    {:connect, :reconnect, %{s | sock: nil}}
  end

  def handle_call(_, _, %{socket: nil} = s) do
    {:reply, {:error, :closed}, s}
  end

  def handle_cast({:send, data}, %{socket: sock} = s) do
    s = %{s | counter: s.counter + 1}
    # Add an id to every message we send
    data = Map.put(data, :id, s.counter)
    data = Poison.encode!(data) <> "\r\n"

    case :ssl.send(sock, data) do
      :ok ->
        {:noreply, s}

      {:error, _} = error ->
        {:disconnect, error, error, s}
    end
  end

  def handle_call({:recv, bytes, timeout}, _, %{sock: sock} = s) do
    case :ssl.recv(sock, bytes, timeout) do
      {:ok, _} = ok ->
        {:reply, ok, s}

      {:error, :timeout} = timeout ->
        {:reply, timeout, s}

      {:error, _} = error ->
        {:disconnect, error, error, s}
    end
  end

  def handle_call(:close, from, s) do
    {:disconnect, {:close, from}, s}
  end

  # TODO right now i only handle keep alive for market stream, break apart into two connections and dont use the same
  @doc """
  Each time a new message comes in we reschedule the keep alive warning, if a message is not recived before the
  keep alive period then a error is logged since the connection is dead
  """
  def handle_info({:ssl, socket, msg}, %{socket: socket, msg: acc_msg} = state) do
    # Reactivate socket to recive next message
    :ssl.setopts(socket, active: :once)
    # Need to concatenate string until \r\n since socket just reads a fixed number of bytes
    new_msg = acc_msg <> msg
    with(
         true <- String.ends_with?(new_msg, "\r\n"),
         {:ok, state} <- handle_msg(state, Poison.Parser.parse!(new_msg, keys: :atoms))
         ) do
      {:noreply, %{state | msg: "", keep_alive_ref: reschedule_keep_alive(state.keep_alive_ref)}} # reset msg
    else
      err -> {:noreply, %{state | msg: new_msg}}
    end
  end

  defp reschedule_keep_alive(timer_ref) do
    if timer_ref do Process.cancel_timer(timer_ref) end
    Process.send_after(self(), :keep_alive, @keep_alive_timeout + 1000)
  end

  def handle_info(:keep_alive, state) do
    # Do not Reactive socket to recive next message
    Logger.error("No keep alive on market stream for #{@keep_alive_timeout + 1000}")
    # TODO do something smart to try and reconnect using clk and initialClk see docs
    {:noreply, state}
  end

  def handle_info({:ssl_closed, socket, msg}, %{socket: socket} = state) do
    # Reactive socket to recive next message
    :ssl.setopts(socket, active: :once)

    Logger.warn("SSL connection closed")

    {:noreply, state}
  end

  def handle_info(msg, %{socket: socket} = state) do
    # Reactive socket to recive next message
    :ssl.setopts(socket, active: :once)

    Logger.warn("Got unexpected message in handle info tcp connection #{inspect(msg)}")

    {:noreply, state}
  end

  @doc """
    When we connect we get back a connection message if we are successful
    Authentication message will be sent with id: 1
    {"op":"connection","connectionId":"002-230915140112-174"}
  """
  defp handle_msg(
         %{session_token: session_token, app_key: app_key} = state,
         %{op: "connection"} = msg
       ) do
    Logger.debug(fn -> "Connection message: #{inspect msg}" end)
    send_authentication_message(session_token, app_key)
    {:ok, %{state | connection_id: msg[:connectionId]}}
  end

  @doc """
  After authentication message we will get a status message with id: 1 back
  then we can subscribe order with id: 2
  %{connectionClosed: false, id: 1, op: "status", statusCode: "SUCCESS"}
  """
  defp handle_msg(state, %{connectionClosed: false, id: 1, op: "status", statusCode: "SUCCESS"}) do
    Logger.debug(fn -> "Authentication OK do subscribe" end)
    send_order_subscription_message()
    {:ok, state}
  end

  @doc """
  After order subscription message we will get a status message with id: 2 back
  then we can subscribe markets with id: 3
  %{connectionClosed: false, id: 2, op: "status", statusCode: "SUCCESS"}
  Shape of heartbeat for order subscription
  %{clk: "AAAAAAAAAAAAAA==", ct: "HEARTBEAT", id: 2, op: "ocm", pt: 1532374449002}
  """
  defp handle_msg(state, %{connectionClosed: false, id: 2, op: "status", statusCode: "SUCCESS"}) do
    Logger.debug(fn -> "Order subscription OK do subscribe market" end)
    send_market_subscription_message(state[:markets])
    {:ok, state}
  end

  @doc """
  After market subscription we should get a ok message
  %{connectionClosed: false, id: 3, op: "status", statusCode: "SUCCESS"}
  Shape of heartbeat for market subscription
  %{clk: "AAAAAAAA", ct: "HEARTBEAT", id: 3, op: "mcm", pt: 1532374509141}
  """
  defp handle_msg(state, %{connectionClosed: false, id: 3, op: "status", statusCode: "SUCCESS"}) do
    Logger.debug(fn -> "Market subscription OK" end)
    {:ok, state}
  end

  @doc """
  TODO oc should be optional here since if there are no orders at the start oc is not in msg
  %{connectionClosed: false, id: 2, op: "status", statusCode: "SUCCESS"}
  %{clk: "AAAAAAAAAAAAAA==", conflateMs: 180000, ct: "SUB_IMAGE", heartbeatMs: 5000, id: 2, initialClk: "W6r23KwHtgaY062wB33Y1ZWqB3T+xJitB9wGjpH5pgc=", op: "ocm", pt: 1531431548305}
  %{clk: "AAAAAAAAAAAAAA==", ct: "HEARTBEAT", id: 2, op: "ocm", pt: 1531431558305}
  """
  # defp handle_msg(state, %{op: "ocm", ct: "SUB_IMAGE", oc: orders} = msg) do
  defp handle_msg(state, %{op: "ocm", oc: markets} = msg) do
    Logger.debug(fn -> "Order change #{inspect msg}" end)
    Enum.each(
      markets,
      &BfgEngine.OrderServer.generate_events(
        BfgEngine.OrderCache.server_process(&1[:id]),
        &1
      ))
    {:ok, state}
  end

  @doc """
  # If no markets then we try to subscribe to all
  %{connectionClosed: false, connectionId: "002-230718201418-1307801", errorCode: "SUBSCRIPTION_LIMIT_EXCEEDED", errorMessage: "trying to subscribe to 18385 markets whereas max allowed number was: 200", id: 3, op: "status", statusCode: "FAILURE"}
  """
  # defp handle_msg(state, %{op: "mcm", ct: "SUB_IMAGE", mc: markets} = msg) do
  defp handle_msg(state, %{op: "mcm", mc: markets} = msg) do
    Logger.debug(fn -> "Market change #{inspect msg}" end)
    Enum.each(
      markets,
      &BfgEngine.MarketServer.generate_events(
        BfgEngine.MarketCache.server_process(&1[:id]),
        &1
      ))
    {:ok, state}
  end

  defp handle_msg(state, %{op: "ocm", ct: "RESUB_DELTA"} = msg) do
    Logger.debug(fn -> "Order change patch from resubscribe #{inspect msg}" end)
    {:ok, state}
  end

  defp handle_msg(state, %{op: "mcm", ct: "RESUB_DELTA"} = msg) do
    Logger.debug(fn -> "Market change patch from resubscribe #{inspect msg}" end)
    {:ok, state}
  end

  defp handle_msg(state, %{op: "ocm", ct: "HEARTBEAT"} = msg) do
  #  Logger.debug(fn -> "Order change HEARTBEAT #{inspect msg}" end)
    {:ok, state}
  end

  defp handle_msg(state, %{op: "mcm", ct: "HEARTBEAT"} = msg) do
  #  Logger.debug(fn -> "Market change HEARTBEAT #{inspect msg}" end)
    {:ok, state}
  end

  # defp handle_msg(state, %{op: "ocm", oc: orders} = msg) do
  #   Logger.debug(fn -> "Order change #{inspect msg}" end)
  #   {:ok, state}
  # end

  # Right now i dont make a difference beftween first image and delta images
  # defp handle_msg(state, %{op: "mcm", mc: markets} = msg) do
  #   Logger.debug(fn -> "Market change #{inspect msg}" end)
  #   {:ok, state}
  # end

  defp handle_msg(state, %{clk: clk} = msg) do
    # TODO i need to update clk also for all messages here
    Logger.debug(fn -> "In catch all #{inspect msg}" end)
    {:ok, state}
  end

  @doc """
  Some common authentication errors that you should handle
  NO_APP_KEY / INVALID_APP_KEY - Check you are using the correct app key
  NO_SESSION / INVALID_SESSION_INFORMATION - Check the session is current
  NOT_AUTHORIZED - Check that you are using the correct appkey / session and that it has been setup by BDP
  MAX_CONNECTION_LIMIT_EXCEEDED - Check that you are not creating too many connections / are closing connections properly.
  """
  def send_authentication_message(session_token, app_key) do
    msg = %{"op" => "authentication", "appKey" => app_key, "session" => session_token}
    send_msg(msg)
  end

  def send_order_subscription_message() do
    msg = %{"op" => "orderSubscription", "partitionMatchedByStrategyRef" => true}
    send_msg(msg)
  end

  def send_market_subscription_message(markets) do
    msg = %{
      "op" => "marketSubscription",
      "marketFilter" => %{
        "marketIds" => markets,
      },
      "marketDataFilter" => %{
        "fields" => ["EX_BEST_OFFERS", "EX_LTP", "EX_MARKET_DEF"],
        "ladderLevels" => @ladder_levels
      }
    }
    send_msg(msg)
  end
end

# %{connectionClosed: true, connectionId: "008-120718175823-773288", errorCode: "TIMEOUT", errorMessage: "Connection is not subscribed and is idle: 15000 ms", op: "status", statusCode: "FAILURE"}

