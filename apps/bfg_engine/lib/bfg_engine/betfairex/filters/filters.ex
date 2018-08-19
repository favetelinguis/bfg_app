defmodule BfgEngine.Betfairex.Filters do
  use Timex

  def default_race_card_request() do
    %{
      filter: %{
        eventTypeIds: ["7"],
        marketTypeCodes: ["WIN"],
        marketCountries: ["GB"],
        marketStartTime: %{
          from: to_string(Timex.today) <> "T00:00:00Z",
          to: to_string(Timex.shift(Timex.today, days: 1)) <> "T23:59:00Z"
        }
      },
      marketProjection: [
        #"MARKET_START_TIME",
        #"RUNNER_DESCRIPTION"
      ],
      # sort: "FIRST_TO_START",
      maxResults: 3
  }
  end

  def place_orders_request(size, price, market_id, selection_id, side, ref, async \\ true) when side == "LAY" or side == "BACK" do
    instruction =  %{
      selectionId: selection_id,
      side: side,
      orderType: "LIMIT",
      limitOrder: %{
      size: size,
      price: price,
      persistenceType: "LAPSE"
      }
      }
    %{
      marketId: market_id,
      instructions: [instruction],
      customerStrategyRef: ref,
      async: async
    }
  end

  def cancel_orders_request(market_id, bet_id) do
    instruction = %{
      betId: bet_id
    }
    %{
      marketId: market_id,
      instructions: [instruction]
  }
  end
end
