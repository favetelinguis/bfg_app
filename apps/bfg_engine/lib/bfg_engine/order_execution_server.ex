defmodule BfgEngine.OrderExecutionServer do
  require Logger
  require Hub
  def place_bet(market_id) do
    market_id
    |> MarketCache.server_process()
    |> MarketServer.get_favorite()
    |> RestConnection.place_orders(2, 1.01, market_id, "LAY", "STOP")
  end

  def cancel_bet(market_id, bet_id) do
    market_id
    |> RestConnection.cancel_orders(bet_id)
  end

  def subscribe() do
    Hub.subscribe("decisions", [{:decision, _, _}], multi: true)
  end
end
