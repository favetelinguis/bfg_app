defmodule BfgEngine.Betfairex.OrderBooks.OrderBook do

  alias BfgEngine.Betfairex.OrderBooks.OrderBookRunners

  def new(order_book, event_time) do
    %{
      event_time: event_time,
      market_id: order_book[:id],
      runners: OrderBookRunners.new(order_book[:orc])
    }
  end

  def update(order_book, update, event_time) do
    %{order_book |
    event_time: event_time,
    runners: OrderBookRunners.update(order_book.runners, update[:orc])}
  end
end
