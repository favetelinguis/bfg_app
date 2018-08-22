defmodule BfgEngine.Betfairex.OrderBooks.UnmatchedOrders do

  alias BfgEngine.Betfairex.OrderBooks.UnmatchedOrder

  def new(unmatched_orders) do
    unmatched_orders
    |> Enum.map(&{&1[:id], UnmatchedOrder.new(&1)})
    |> Map.new()
  end

  def update(unmatched_orders, nil) do
    unmatched_orders
  end

  def update(unmatched_orders, updates) do
    Enum.reduce(updates, unmatched_orders, fn order, cache ->
      Map.update(
        cache,
        order[:id],
        UnmatchedOrder.new(order),
        &UnmatchedOrder.update(&1, order)
      )
    end)
  end
end
