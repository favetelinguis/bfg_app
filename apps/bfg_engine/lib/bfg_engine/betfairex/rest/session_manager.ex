defmodule BfgEngine.Betfairex.Rest.SessionManager do
  @moduledoc """
  Manages the rest connection to betfair,
  responsible for:
  - Preventing the session to expire, holds the session alive forever
  - If for any reason the session expires this service is toped wich will restart the process and the stream subscriptions
  - Check once a minut if the rest connection is alive

  Emitts the following events
  - RestConnection describes the status of the connection

  """
  use Connection
  require Logger

  @username Application.get_env(:bfg_engine, :betfair_user)
  @password Application.get_env(:bfg_engine, :betfair_password)
  @app_key Application.get_env(:bfg_engine, :betfair_app_key)

  @keep_alive_ms Application.get_env(:bfg_engine, :keep_alive_ms)
  @initial_state %{
    alive: false,
    login_time: nil,
    last_keep_alive: nil,
    keep_alive_ref: nil,
    session_token: nil
  }

  alias BfgEngine.Betfairex.Api.{Login, Session, Betting}
  alias BfgEngine.Betfairex.Stream.SubscriptionManager
  alias BfgEngine.PubSub
  alias BfgEngine.Events.RestConnection

  # Client #####################################################################
  #
  #
  def start_link(), do: Connection.start_link(__MODULE__, nil, name: __MODULE__)

  def send_betting(endpoint, body) when is_map(body) and is_bitstring(endpoint),
    do: Connection.call(__MODULE__, {:send_betting, {endpoint, body}})

  def invalidate_session(), do: Connection.call(__MODULE__, :invalidate_session)

  # Callbacks #####################################################################
  #
  #
  def init(_) do
    Logger.info("#{__MODULE__} started")
    {:connect, :init, @initial_state}
  end

  def child_spec(_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :worker
    }
  end

  def connect(_, %{alive: false} = s) do
    body = %{username: @username, password: @password}

    "/certlogin"
    |> Login.post(body)
    |> handle_login_response(s)
  end

  @doc """
  Clean up last connection before trying to reconnect
  """
  def disconnect(info, %{alive: true, session_token: session_token, keep_alive_ref: ref} = s) do
    # Try to logout, dont case if we success or not
    headers = ["X-Application": @app_key, "X-Authentication": session_token]

    "/logout"
    |> Session.post("", headers)

    # Cancel last keep alive
    Process.cancel_timer(ref)

    # Remove from state things from last session
    s = %{s | alive: false}

    case info do
      {:call_failed, from} ->
        Connection.reply(from, {:error, :reconnecting})
    end

    {:connect, :reconnect, s}
  end

  @doc """
  Make sure no calls can be made on the connection if its closed
  """
  def handle_call(_, _, %{alive: false} = s) do
    {:reply, {:error, :closed}, s}
  end

  def handle_call({:send_betting, {endpoint, body}}, from, %{session_token: session_token} = s) do
    headers = ["X-Application": @app_key, "X-Authentication": session_token]

    endpoint
    |> Betting.post(body, headers)
    |> handle_response(s, from)
  end

  def handle_call(:invalidate_session, _from, s) do
    Logger.warn("Session has been invalidated, setting up new session")
    {:stop, :normal, nil}
  end

  def handle_info(:keep_alive, %{session_token: session_token} = s) do
    headers = ["X-Application": @app_key, "X-Authentication": session_token]

    "/keepAlive"
    |> Session.post("", headers)
    |> handle_keep_alive_response(s)
  end

  # Impl functions #####################################################################
  #
  #
  @doc """
  Login sucessful
  """
  defp handle_login_response(
         {:ok, %{status_code: 200, body: %{loginStatus: "SUCCESS", sessionToken: session_token}}},
         s
       ) do
    s = %{
      s
      | alive: true,
        login_time: Timex.now(),
        session_token: session_token
    }

    ref = schedule_keep_alive()
    Logger.info("Login sucessful with token #{session_token}")
    PubSub.publish(RestConnection.new(:connected))

    # Setup subscriptions
    SubscriptionManager.subscribe_market_stream(session_token)
    SubscriptionManager.subscribe_order_stream(session_token)

    {:ok, %{s | keep_alive_ref: ref}}
  end

  @doc """
  Login fail from betfair, we can not start the application
  """
  defp handle_login_response(
         {:ok, %{status_code: 200, body: %{loginStatus: error}}},
         s
       ) do
    Logger.error("Login failed with betfair error #{error}")
    PubSub.publish(RestConnection.new(:disconnected))
    {:stop, error, s}
  end

  @doc """
  Login fails with no 200 response from betfair try again after 4seconds
  """
  defp handle_login_response(
         {:ok, %{status_code: status_code, body: body}},
         s
       )
       when status_code != 200 do
    Logger.warn(
      "Failed to connect to betfair with statuscode: #{status_code} trying to reconnect in 4 seconds"
    )

    PubSub.publish(RestConnection.new(:connecting))
    {:backoff, 4000, s}
  end

  defp schedule_keep_alive() do
    Process.send_after(self(), :keep_alive, @keep_alive_ms)
  end

  @doc """
  Keep alive successful
  """
  defp handle_keep_alive_response({:ok, %{status_code: 200, body: %{status: "SUCCESS"}}}, s) do
    Logger.info("Keep alive successfully done")
    ref = schedule_keep_alive()
    {:noreply, %{s | last_keep_alive: Timex.now(), keep_alive_ref: ref}}
  end

  @doc """
  All problems with keep alive, create a new session and resubscribe streams
  """
  defp handle_keep_alive_response(resp, s) do
    Logger.warn("Keep alive failed with response #{inspect(resp)} trying to reconnect")
    {:stop, :normal, s}
  end

  def handle_response({:ok, %{status_code: 200, body: {:ok, body}}}, s, _) do
    Logger.debug(fn -> "Response from betting operation #{inspect(body)}" end)
    {:reply, {:ok, body}, s}
  end

  def handle_response(
        {:ok,
         %{
           status_code: 400,
           body:
             {:ok,
              %{
                detail: %{
                  APINGException: %{
                    errorCode: "INVALID_SESSION_INFORMATION",
                    errorDetails: details
                  }
                }
              }}
         }},
        s,
        _from
      ) do
    # Since the streams need to resubscribe with the new session token we restart the process wich will take down the subscriptions also
    Logger.warn("APINGException INVALID_SESSION_INFORMATION with details #{inspect(details)}")
    {:stop, :normal, s}
  end

  def handle_response(
        {:ok,
         %{
           status_code: 400,
           body:
             {:ok, %{detail: %{APINGException: %{errorCode: error_code, errorDetails: details}}}}
         }},
        s,
        _from
      ) do
    Logger.warn("APINGException #{inspect(error_code)} with details #{inspect(details)}")
    {:reply, {:error, :betfair_exception}, s}
  end

  def handle_response(msg, s, _from) do
    Logger.warn("Error in response: #{inspect(msg)}")
    {:reply, {:error, :something_went_wrong}, s}
  end
end
