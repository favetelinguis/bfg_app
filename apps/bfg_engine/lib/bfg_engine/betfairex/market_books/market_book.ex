defmodule BfgEngine.Betfairex.MarketBooks.MarketBook do

alias BfgEngine.Betfairex.MarketBooks.{MarketDefinition, MarketBookRunners}

  def new(update) do
    %{
      market_definition: if update[:marketDefinition] do MarketDefinition.new(update.marketDefinition) end,
      total_matched: update[:tv],
      runners: if update[:rc] do MarketBookRunners.new(update.rc) end
    }
  end

  def update(market_book, update) do
    # TODO report to prometheus if update[:con] true
    case market_book[:img] do
      true -> new(update)
      _ ->
        %{
          market_book |
          market_definition: MarketDefinition.update(market_book.market_definition, update[:marketDefinition]),
          total_matched: update[:tv] || market_book.total_matched,
          runners: MarketBookRunners.update(market_book.runners, update[:rc])
        }
    end
  end
end
