defmodule BfgEngine.Betfairex.MarketBooks.MarketBookRunner do
  require Logger
  alias BfgEngine.Betfairex.Ladder

  def new(update) do
    check_con(update)

    %{
      selection_id: update.id,
      last_price_traded: update[:ltp],
      total_matched: update[:tv],
      traded: Ladder.new_full_depth_ladder() |> Ladder.update_full_depth_ladder(update[:trd]),
      available_to_back:
        Ladder.new_full_depth_ladder() |> Ladder.update_full_depth_ladder(update[:atb]),
      best_available_to_back:
        Ladder.new_depth_based_ladder() |> Ladder.update_depth_based_ladder(update[:batb]),
      best_display_available_to_back:
        Ladder.new_depth_based_ladder() |> Ladder.update_depth_based_ladder(update[:bdatb]),
      available_to_lay:
        Ladder.new_full_depth_ladder() |> Ladder.update_full_depth_ladder(update[:atl]),
      best_available_to_lay:
        Ladder.new_depth_based_ladder() |> Ladder.update_depth_based_ladder(update[:batl]),
      best_display_available_to_lay:
        Ladder.new_depth_based_ladder() |> Ladder.update_depth_based_ladder(update[:bdatl]),
      starting_price_back:
        Ladder.new_full_depth_ladder() |> Ladder.update_full_depth_ladder(update[:spb]),
      starting_price_lay:
        Ladder.new_full_depth_ladder() |> Ladder.update_full_depth_ladder(update[:spl]),
      starting_price_near: update[:spn],
      starting_price_far: update[:spf],
      handicap: update[:hc]
    }
  end

  def update(market_book_runner, nil) do
    market_book_runner
  end

  def update(market_book_runner, update) do
    check_con(update)

    %{
      market_book_runner
      | last_price_traded: update[:ltp] || market_book_runner.last_price_traded,
        total_matched: update[:tv] || market_book_runner.total_matched,
        starting_price_near: update[:spn] || market_book_runner.starting_price_near,
        starting_price_far: update[:spf] || market_book_runner.starting_price_far,
        handicap: update[:hc] || market_book_runner.handicap,
        traded: Ladder.update_full_depth_ladder(market_book_runner.traded, update[:trd]),
        available_to_back:
          Ladder.update_full_depth_ladder(market_book_runner.available_to_back, update[:atb]),
        best_available_to_back:
          Ladder.update_depth_based_ladder(
            market_book_runner.best_available_to_back,
            update[:batb]
          ),
        best_display_available_to_back:
          Ladder.update_depth_based_ladder(
            market_book_runner.best_display_available_to_back,
            update[:bdatb]
          ),
        available_to_lay:
          Ladder.update_full_depth_ladder(market_book_runner.available_to_lay, update[:atl]),
        best_available_to_lay:
          Ladder.update_depth_based_ladder(
            market_book_runner.best_available_to_lay,
            update[:batl]
          ),
        best_display_available_to_lay:
          Ladder.update_depth_based_ladder(
            market_book_runner.best_display_available_to_lay,
            update[:bdatl]
          ),
        starting_price_back:
          Ladder.update_full_depth_ladder(market_book_runner.starting_price_back, update[:spb]),
        starting_price_lay:
          Ladder.update_full_depth_ladder(market_book_runner.starting_price_lay, update[:spl])
    }
  end

  defp check_con(update) do
    # TODO i should publish to prometheus if con is set
    if update[:con] do
      Logger.warn("Con is set for runner #{update.id}")
    end
  end
end
