defmodule BfgEngine.Betfairex.Cache.OrderCache do
  use GenServer
  require Logger

  @me __MODULE__

  alias BfgEngine.Betfairex.OrderBooks

  def start_link(_) do
    GenServer.start_link(@me, nil, name: @me)
  end

  def update(msg, publish_time) do
    GenServer.call(@me, {:update, msg, publish_time})
  end

  def init(_) do
    Logger.info("#{@me} started")
    {:ok, {Timex.now(), OrderBooks.new}}
  end

  def handle_call({:update, orders, publish_time}, _from, {last_msg_time, orders_cache} = state) do
    if Timex.before?(publish_time, last_msg_time) do
      # IF this ever happens I must update this to call insted of cast
      # TODO log count to prometheis
      Logger.error("Out of order messages in order cache")
      # TODO this should not update the cache and we should resubscribe the merket stream to get a fresh image
      {:reply, :ok, state}
    else
      updated_orders = OrderBooks.update(orders_cache, orders)
      # TODO dont put publish time here since not all markets are change with each update, this should be put per order in the cache
      {:reply, :ok, {publish_time, updated_orders}}
    end
  end
end
