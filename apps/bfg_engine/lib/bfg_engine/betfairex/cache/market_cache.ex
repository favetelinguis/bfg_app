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
    {:ok, {Timex.now(), MarketBooks.new}}
  end

    # TODO on each market there is a con true count how often for each market
    def update(msg, publish_time) do
    end

end
