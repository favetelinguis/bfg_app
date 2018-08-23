defmodule BfgEngine.Betfairex.Cache.MarketCache do
  use GenServer
  require Logger

  @me __MODULE__

  alias BfgEngine.Betfairex.MarketBooks

  def start_link(_) do
    GenServer.start_link(@me, nil, name: @me)
  end

  def init(_) do
    Logger.info("#{@me} started")
    {:ok, {Timex.now(), MarketBooks.new()}}
  end

  def update(msg, publish_time) do
    GenServer.call(@me, {:update, msg, publish_time})
  end

  def handle_call({:update, update, publish_time}, _from, {last_msg_time, cache} = state) do
    if Timex.before?(publish_time, last_msg_time) do
      # IF this ever happens I must update this to call insted of cast
      # TODO log count to prometheis
      Logger.error("Out of order messages in market cache")

      # TODO this should not update the cache and we should resubscribe the merket stream to get a fresh image
      {:reply, :ok, state}
    else
      updated_cache = MarketBooks.update(cache, update)

      # TODO dont put publish time here since not all markets are change with each update, this should be put per order in the cache
      {:reply, :ok, {publish_time, updated_cache}}
    end
  end
end
