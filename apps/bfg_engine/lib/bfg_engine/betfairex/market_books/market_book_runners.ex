defmodule BfgEngine.Betfairex.MarketBooks.MarketBookRunners do
  alias BfgEngine.Betfairex.MarketBooks.MarketBookRunner

  def new(updates) do
    updates
    |> Enum.map(&{&1.id, MarketBookRunner.new(&1)})
    |> Map.new()
  end

  def update(market_book_runners, nil) do
    market_book_runners
  end

  def update(market_book_runners, updates) do
    Enum.reduce(updates, market_book_runners, fn change, cache ->
      Map.update(
        cache,
        change.id,
        MarketBookRunner.new(change),
        &MarketBookRunner.update(&1, change)
      )
    end)
  end
end
