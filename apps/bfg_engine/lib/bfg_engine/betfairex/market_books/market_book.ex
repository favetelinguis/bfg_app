defmodule BfgEngine.Betfairex.MarketBooks.MarketBook do

alias BfgEngine.Betfairex.MarketBooks.{MarketDefinition, MarketBookRunners}

  def new(update, event_time) do
    %{
      event_time: event_time,
      market_definition: if update[:marketDefinition] do MarketDefinition.new(update.marketDefinition) end,
      total_matched: update[:tv],
      runners: if update[:rc] do MarketBookRunners.new(update.rc) end
    }
  end

  def update(market_book, update, event_time) do
    # TODO report to prometheus if update[:con] true
    case market_book[:img] do
      true -> new(update, event_time)
      _ ->
        %{
          market_book |
          event_time: event_time,
          market_definition: MarketDefinition.update(market_book.market_definition, update[:marketDefinition]),
          total_matched: update[:tv] || market_book.total_matched,
          runners: MarketBookRunners.update(market_book.runners, update[:rc])
        }
    end
  end
end
