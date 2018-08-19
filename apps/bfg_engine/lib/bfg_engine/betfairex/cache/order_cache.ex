defmodule BfgEngine.Betfairex.Cache.OrderCache do
  use GenServer
  require Logger

  @me __MODULE__

  def start_link(_) do
    GenServer.start_link(@me, nil, name: @me)
  end

  def init(_) do
    Logger.info("#{@me} started")
    {:ok, nil}
  end

end
