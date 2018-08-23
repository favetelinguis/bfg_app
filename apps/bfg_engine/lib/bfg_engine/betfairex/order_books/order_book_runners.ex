defmodule BfgEngine.Betfairex.OrderBooks.OrderBookRunners do
  alias BfgEngine.Betfairex.OrderBooks.OrderBookRunner

  def new(update) do
    update
    |> Enum.map(&{&1.id, OrderBookRunner.new(&1)})
    |> Map.new()
  end

  def update(order_book_runners, updates) do
    Enum.reduce(updates, order_book_runners, fn change, cache ->
      Map.update(
        cache,
        change[:id],
        OrderBookRunner.new(change),
        &OrderBookRunner.update(&1, change)
      )
    end)
  end
end
