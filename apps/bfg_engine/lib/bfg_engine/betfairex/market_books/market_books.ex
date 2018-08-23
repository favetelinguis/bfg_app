defmodule BfgEngine.Betfairex.MarketBooks do

  alias BfgEngine.Betfairex.MarketBooks.MarketBook
  def new() do
    %{}
  end

  def update(market_books, nil) do
    market_books
  end

  def update(market_books, updates) do
    Enum.reduce(updates, market_books, fn market_book, cache ->
      Map.update(cache, market_book.id, MarketBook.new(market_book), &MarketBook.update(&1, market_book))
    end)
  end
end
