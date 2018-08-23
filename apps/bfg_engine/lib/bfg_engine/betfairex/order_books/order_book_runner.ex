defmodule BfgEngine.Betfairex.OrderBooks.OrderBookRunner do
  alias BfgEngine.Betfairex.OrderBooks.UnmatchedOrders
  alias BfgEngine.Betfairex.Ladder

  def new(runner) do
    %{
      selection_id: runner[:id],
      handicap: runner[:hc],
      matched_lays: Ladder.new_full_depth_ladder() |> Ladder.update_full_depth_ladder(runner[:ml]),
      matched_backs: Ladder.new_full_depth_ladder() |> Ladder.update_full_depth_ladder(runner[:mb]),
      unmatched_orders: UnmatchedOrders.new(runner[:uo])
    }
  end

  def update(runner, update) do
    runner
    |> Map.update!(:matched_lays, &Ladder.update_full_depth_ladder(&1, update[:ml]))
    |> Map.update!(:matched_backs, &Ladder.update_full_depth_ladder(&1, update[:mb]))
    |> Map.update!(:unmatched_orders, &UnmatchedOrders.update(&1, update[:uo]))
  end
end
