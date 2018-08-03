defmodule BfgEngine.Cerebro do
  use GenServer

  require Logger

  alias BfgEngine.{MarketsServer, RestConnection, MarketCache, MarketServer, StrategyCache, OrderCache}

  def start_link(login_credentials) do
    GenServer.start_link(__MODULE__, login_credentials, name: __MODULE__)
  end

  def init(%{password: password, username: username, app_key: app_key}) do
    with(
      {:ok, _} <- RestConnection.start_link(username, password, app_key),
      [_|_] = market_ids <- MarketsServer.list_market_ids(),
      :ok <- start_servers(market_ids),
      # _ <- Process.sleep(2000),
      :ok <- RestConnection.subscribe(market_ids)
    )
     do
       Logger.info("Cerebro started, let the money flow!")
      {:ok, "Cerebro started, let the money flow!"}
    end
  end

  @doc """
  Takes a list of markets and start a market server for each market
  initiating with marketId marketName and runners [runnerId runnerName]
  """
  defp start_servers(market_ids) do
    # Start a strategy server for each market
    # Enum.each(market_ids, &StrategyCache.server_process/1)

    # Start a order server for each market
    # Enum.each(market_ids, &OrderCache.server_process/1)

    # For each market start a new server
    Enum.each(market_ids, &MarketCache.server_process/1)
    # Init the race card state for the created servers
    # TODO this can be moved to use MarketsServer
    Enum.each(MarketsServer.list_markets(), &MarketServer.init_market(MarketCache.server_process(&1.marketId), &1))

    :ok
  end
end
