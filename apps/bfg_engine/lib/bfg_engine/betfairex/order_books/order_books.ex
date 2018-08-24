defmodule BfgEngine.Betfairex.OrderBooks do

  alias BfgEngine.Betfairex.OrderBooks.OrderBook

  def new() do
    %{}
  end
  def update(order_books, updates, event_time) do
    Enum.reduce(updates, order_books, fn order_book, cache ->
      Map.update(cache, order_book.id, OrderBook.new(order_book, event_time), &OrderBook.update(&1, order_book, event_time))
    end)
  end
end
