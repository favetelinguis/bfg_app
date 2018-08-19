# https://pragdave.me/blog/2017/07/13/decoupling-interface-and-implementation-in-elixir.html
defmodule BfgEngine.Betfairex.Stream.MarketStream do
  use Connection
  require Logger

  @me __MODULE__

  @stream_url Application.get_env(:bfg_engine, :stream_url)
  @stream_port Application.get_env(:bfg_engine, :stream_port)
  @app_key Application.get_env(:bfg_engine, :betfair_app_key)
  @keep_alive_timeout 5000

  @initial_state %{
    socket: nil,
    session_token: nil,
    initialClk: nil,
    clk: nil,
    counter: 0,
    market_ids: nil,
    msg: "",
    keep_alive_ref: nil
  }

  alias BfgEngine.Betfairex.Session.{SubscriptionStore}
  alias BfgEngine.Betfairex.Rest.{SessionManager}
  alias BfgEngine.Betfairex

  # Client
  def start_link(session_token), do: Connection.start_link(@me, session_token, name: @me)

  # Callback
  def init(session_token) do
    Process.flag(:trap_exit, true)

    state =
      SubscriptionStore.get_market_subscription_state() ||
        %{@initial_state | session_token: session_token}
    # Make sure to clean up some attributes, reduntant to always do this, only needed when loading from store
    state = %{state | socket: nil, counter: 0, msg: "", keep_alive_ref: nil}
    {:connect, :init, state}
  end

  def connect(_, state) do
    opts = [:binary, active: :once]

    case :ssl.connect(@stream_url, @stream_port, opts) do
      {:ok, socket} ->
        {:ok, %{state | socket: socket}}

      {:error, _reason} ->
        {:backoff, 5000, state}
    end
  end

  def disconnect(_info, %{socket: socket, keep_alive_ref: timer_ref} = state) do
    if timer_ref do Process.cancel_timer(timer_ref) end
    :ok = :ssl.close(socket)
    {:connect, :reconnect, %{state | counter: 0}}
  end

  def terminate(_reason, state) do
    Logger.warn("Market stream terminate called, closing socket")
    :ssl.close(state.socket)
    SubscriptionStore.set_market_subscription_state(state)
  end

  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]},
      restart: :permanent,
      shutdown: 5000,
      type: :worker
    }
  end

  @doc """
  Each time a new message comes in we reschedule the keep alive warning, if a message is not recived before the
  keep alive period then a error is logged since the connection is dead
  """
  def handle_info({:ssl, socket, msg}, %{socket: socket, msg: acc_msg} = state) do
    # Reactivate socket to recive next message
    :ssl.setopts(socket, active: :once)

    # Need to concatenate string until \r\n since socket just reads a fixed number of bytes and not the whole msg
    new_msg = acc_msg <> msg

    with(
      true <- String.ends_with?(new_msg, "\r\n"),
      {:ok, state} <- handle_msg(state, Poison.Parser.parse!(new_msg, keys: :atoms))
    ) do
      # reset msg
      {:noreply, %{state | msg: "", keep_alive_ref: reschedule_keep_alive(state.keep_alive_ref)}}
    else
      _err -> {:noreply, %{state | msg: new_msg}}
    end
  end

  def handle_info(:keep_alive, state) do
    Logger.warn("No keep alive on market stream for #{@keep_alive_timeout} resubscribing")
    {:disconnect, :reconnect, state}
  end

  def handle_info({:ssl_closed, _socket, _msg}, state) do
    Logger.warn("SSL connection closed, resubscribing")
    {:connect, :reconnect, state}
  end

  # Impl
  defp reschedule_keep_alive(timer_ref) do
    if timer_ref do
      Process.cancel_timer(timer_ref)
    end

    # Add 1000ms extra time for message
    Process.send_after(self(), :keep_alive, @keep_alive_timeout + 1000)
  end

  defp handle_msg(state, %{
         op: "status",
         statusCode: "FAILURE",
         errorCode: "INVALID_SESSION_INFORMATION"
       }) do
    Logger.warn("Invalid session in market stream, restarting session")
    SessionManager.invalidate_session()
    {:ok, state}
  end

  defp handle_msg(
         %{socket: socket, session_token: session_token} = state,
         %{op: "connection"} = msg
       ) do
    # When we connect we get back a connection message if we are successful
    # Authentication message will be sent with id: 1
    # {"op":"connection","connectionId":"002-230915140112-174"}
    Logger.info("New market stream connection with id: #{msg[:connectionId]}")
    auth_msg = %{"op" => "authentication", "appKey" => @app_key, "session" => session_token}
    next = state.counter + 1
    send_msg(socket, auth_msg, next)
    {:ok, %{state | counter: next}}
  end

  defp handle_msg(%{socket: socket, market_ids: market_ids, initialClk: initialClk, clk: clk} = state, %{
         connectionClosed: false,
         id: 1,
         op: "status",
         statusCode: "SUCCESS"
       }) do
    # After authentication message we will get a status message with id: 1 back
    # then we can subscribe order with id: 2
    # %{connectionClosed: false, id: 1, op: "status", statusCode: "SUCCESS"}
    Logger.debug("Authentication OK do subscribe")
    market_ids = market_ids || get_new_market_ids()
    next = state.counter + 1

    sub_msg = %{
      "op" => "marketSubscription",
      "initialClk" => initialClk,
      "clk" => clk,
      # TODO not sure how this works
      "conflateMs" => nil,
      "heartbeatMs" => @keep_alive_timeout,
      # TODO should prob implement support for this
      "segmentationEnabled" => false,
      "marketFilter" => %{
        "marketIds" => market_ids
      },
      "marketDataFilter" => %{
        "fields" => ["EX_BEST_OFFERS", "EX_LTP", "EX_MARKET_DEF"],
        "ladderLevels" => @ladder_levels
      }
    }

    send_msg(socket, sub_msg, next)
    {:ok, %{state | counter: next, market_ids: market_ids}}
  end

  defp handle_msg(state, %{connectionClosed: false, id: 2, op: "status", statusCode: "SUCCESS"}) do
    # After market subscription we should get a ok message
    # %{connectionClosed: false, id: 3, op: "status", statusCode: "SUCCESS"}
    # Shape of heartbeat for market subscription
    # %{clk: "AAAAAAAA", ct: "HEARTBEAT", id: 3, op: "mcm", pt: 1532374509141}
    Logger.debug(fn -> "Market subscription OK" end)
    {:ok, state}
  end

  defp handle_msg(state, %{op: "mcm", mc: markets} = msg) do
    Logger.debug("Market change #{inspect(msg)}")
    # Enum.each(
    #   markets,
    #   &BfgEngine.MarketServer.generate_events(
    #     BfgEngine.MarketCache.server_process(&1[:id]),
    #     &1
    #   ))
    BfgEngine.Repo.insert_all("markets", [[market: msg, inserted_at: Ecto.DateTime.utc()]])

    {:ok,
     %{state | initialClk: msg[:initialClk] || state.initialClk, clk: msg[:clk] || state.clk}}
  end

  defp handle_msg(state, %{op: "mcm", ct: "HEARTBEAT"} = msg) do
    Logger.debug("Market change HEARTBEAT #{inspect(msg)}")
    {:ok, %{state | initialClk: msg[:initialClk] || state.initialClk, clk: msg[:clk] || state.clk}}
  end

  defp send_msg(socket, msg, next) do
    data = Map.put(msg, :id, next)
    data = Poison.encode!(data) <> "\r\n"
    :ok = :ssl.send(socket, data)
  end

  defp get_new_market_ids() do
    {:ok, markets} = Betfairex.list_market_catalogue()
    Enum.map(markets, &Map.get(&1, :marketId))
  end
end
