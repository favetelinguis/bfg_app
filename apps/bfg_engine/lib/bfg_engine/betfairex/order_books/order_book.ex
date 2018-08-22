defmodule BfgEngine.Betfairex.OrderBooks.OrderBook do

  alias BfgEngine.Betfairex.OrderBooks.OrderBookRunners

  def new(order_book) do
    %{
      market_id: order_book[:id],
      runners: OrderBookRunners.new(order_book[:orc])
    }
  end

  def update(order_book, update) do
    %{order_book | runners: OrderBookRunners.update(order_book.runners, update[:orc])}
  end
end
