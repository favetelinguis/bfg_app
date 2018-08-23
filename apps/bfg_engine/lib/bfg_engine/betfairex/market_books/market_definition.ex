defmodule BfgEngine.Betfairex.MarketBooks.MarketDefinition do

  def new(update) do
    %{update | runners: runners_to_map(update[:runners])}
  end

  def update(market_definition, nil) do
    market_definition
  end

  def update(_market_definition, update) do
    new(update)
  end

  defp runners_to_map(runners) do
    runners
    |> Enum.map(&{&1.id, &1})
    |> Map.new()
  end
end
