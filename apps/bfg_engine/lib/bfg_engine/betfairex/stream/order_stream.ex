# https://pragdave.me/blog/2017/07/13/decoupling-interface-and-implementation-in-elixir.html
defmodule BfgEngine.Betfairex.Stream.OrderStream do
  use Connection
  require Logger

  @me __MODULE__

  @stream_url Application.get_env(:bfg_engine, :stream_url)
  @stream_port Application.get_env(:bfg_engine, :stream_port)
  @app_key Application.get_env(:bfg_engine, :betfair_app_key)
  @keep_alive_timeout 5000

  @lookup :oc

  @initial_state %{
    socket: nil,
    session_token: nil,
    initialClk: nil,
    clk: nil,
    counter: 0,
    msg: "",
    keep_alive_ref: nil
  }

  alias BfgEngine.Betfairex.Session.{SubscriptionStore}
  alias BfgEngine.Betfairex.Rest.{SessionManager}
  alias BfgEngine.Betfairex.Cache.OrderCache

  # Client
  def start_link(session_token), do: Connection.start_link(@me, session_token, name: @me)

  # Callbacks
  def init(session_token) do
    Process.flag(:trap_exit, true)

    state =
      SubscriptionStore.get_order_subscription_state() ||
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
    if timer_ref do
      Process.cancel_timer(timer_ref)
    end

    :ok = :ssl.close(socket)
    {:connect, :reconnect, %{state | counter: 0}}
  end

  def terminate(_reason, state) do
    Logger.warn("Order stream terminate called, closing socket")
    :ssl.close(state.socket)
    SubscriptionStore.set_order_subscription_state(state)
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
    Logger.warn("No keep alive on order stream for #{@keep_alive_timeout} resubscribing")
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
    Logger.warn("Invalid session in order stream, restarting session")
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
    Logger.info("New order stream connection with id: #{msg[:connectionId]}")
    auth_msg = %{"op" => "authentication", "appKey" => @app_key, "session" => session_token}
    next = state.counter + 1
    send_msg(socket, auth_msg, next)
    {:ok, %{state | counter: next}}
  end

  defp handle_msg(%{socket: socket, initialClk: initialClk, clk: clk} = state, %{
         connectionClosed: false,
         id: 1,
         op: "status",
         statusCode: "SUCCESS"
       }) do
    # After authentication message we will get a status message with id: 1 back
    # then we can subscribe order with id: 2
    # %{connectionClosed: false, id: 1, op: "status", statusCode: "SUCCESS"}
    Logger.debug("Authentication OK do subscribe")
    next = state.counter + 1

    sub_msg = %{
      "op" => "orderSubscription",
      "initialClk" => initialClk,
      "clk" => clk,
      # TODO can this be set to zero to get tick data?
      "conflateMs" => nil,
      "heartbeatMs" => @keep_alive_timeout,
      "includeOverallPosition" => true,
      # TODO should prob implement support for this
      "segmentationEnabled" => false
      # "partitionMatchedByStrategyRef" => true
    }

    send_msg(socket, sub_msg, next)
    {:ok, %{state | counter: next}}
  end

  defp handle_msg(state, %{connectionClosed: false, id: 2, op: "status", statusCode: "SUCCESS"}) do
    # After market subscription we should get a ok message
    # %{connectionClosed: false, id: 3, op: "status", statusCode: "SUCCESS"}
    # Shape of heartbeat for market subscription
    # %{clk: "AAAAAAAA", ct: "HEARTBEAT", id: 3, op: "mcm", pt: 1532374509141}
    Logger.debug(fn -> "Order subscription OK" end)
    {:ok, state}
  end

  defp handle_msg(state, %{op: "ocm"} = msg) do
    # TODO send conflateMs to prometheus
    # TODO send heartbeatMs to prometheus
    ct = Map.get(msg, :ct, "UPDATE")

    case ct do
      "SUB_IMAGE" ->
        on_subscription(msg)

      "RESUB_DELTA" ->
        on_resubscribe(msg)

      # on heartbeat update clk
      "HEARTBEAT" ->
        Logger.debug("Order HEARTBEAT #{inspect(msg)}")

      "UPDATE" ->
        on_update(msg)
    end

    unless ct == "HEARTBEAT" do
      BfgEngine.Repo.insert_all("orders", [[order: msg, inserted_at: Ecto.DateTime.utc()]])
    end

    {:ok,
     %{state | initialClk: msg[:initialClk] || state.initialClk, clk: msg[:clk] || state.clk}}
  end

  defp send_msg(socket, msg, next) do
    data = Map.put(msg, :id, next)
    data = Poison.encode!(data) <> "\r\n"
    :ok = :ssl.send(socket, data)
  end

  defp on_subscription(msg) do
    # TODO send count to prometheus on number subscriptions
    Logger.debug("Order SUB_IMAGE #{inspect(msg)}")

    if msg[@lookup] do
      publish_time = Timex.from_unix(msg[:pt], :milliseconds)
      OrderCache.update(msg[@lookup], publish_time)
    end
  end

  defp on_resubscribe(msg) do
    # TODO send count to prometheus on number re subscriptions
    Logger.debug("Order RESUB_DELTA #{inspect(msg)}")

    if msg[@lookup] do
      publish_time = Timex.from_unix(msg[:pt], :milliseconds)
      OrderCache.update(msg[@lookup], publish_time)
    end
  end

  defp on_update(msg) do
    Logger.debug("Order UPDATE #{inspect(msg)}")
    publish_time = Timex.from_unix(msg[:pt], :milliseconds)
    latency = Timex.diff(Timex.now, publish_time, :milliseconds)
    # TODO send latency to prometheus
    # TODO send count number updates to prometheus
    if msg[@lookup] do
      OrderCache.update(msg[@lookup], publish_time)
    end
  end
end
