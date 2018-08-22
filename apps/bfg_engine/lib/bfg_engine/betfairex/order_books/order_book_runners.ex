defmodule BfgEngine.Betfairex.OrderBooks.OrderBookRunners do
  alias BfgEngine.Betfairex.OrderBooks.OrderBookRunner

  def new(order_changes) do
    order_changes
    |> Enum.map(&{&1[:id], OrderBookRunner.new(&1)})
    |> Map.new()
  end

  def update(order_book_runners, order_changes) do
    Enum.reduce(order_changes, order_book_runners, fn change, cache ->
      Map.update(
        cache,
        change[:id],
        OrderBookRunner.new(change),
        &OrderBookRunner.update(&1, change)
      )
    end)
  end
end
