defmodule BfgEngine.Betfairex.Rest do
  @moduledoc """
  Contains all restendpoints
  """
  require Logger

  alias BfgEngine.Betfairex.Filters
  import BfgEngine.Betfairex.Rest.Connection, only: [send_betting: 2]

  def list_market_catalogue() do
    send_betting("/listMarketCatalogue", Filters.default_race_card_request())
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
    send_betting("/placeOrders", Filters.place_orders_request(size, price, market_id, selection_id, side, ref))
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
    send_betting("/cancelOrders", Filters.cancel_orders_request(market_id, bet_id))
  end

end
