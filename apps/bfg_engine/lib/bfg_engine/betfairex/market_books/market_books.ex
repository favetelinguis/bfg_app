defmodule BfgEngine.Betfairex.MarketBooks do

  alias BfgEngine.Betfairex.MarketBooks.MarketBook
  def new() do
    %{}
  end

  def update(market_books, nil, _) do
    market_books
  end

  def update(market_books, updates, event_time) do
    Enum.reduce(updates, market_books, fn market_book, cache ->
      Map.update(cache, market_book.id, MarketBook.new(market_book, event_time), &MarketBook.update(&1, market_book, event_time))
    end)
  end
end
