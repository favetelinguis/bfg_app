defmodule BfgWebWeb.PageCommander do
  use Drab.Commander
  require Hub
  require Logger
  # onconnect :connected

  defhandler subscribe_market(socket, _sender, market_id) do
    Logger.debug("Change subscription to #{market_id} is it string #{is_binary(market_id)}")
    # BfgEngine.Subscriber.subscribe_on(market_id)
    sub = Hub.subscribe(market_id, _)
    handle_event(socket)
  end

  # def connected(socket) do
  #   sub = Hub.subscribe("market_id", _)
  #   Logger.debug("Connected and subscribed to market_id #{inspect sub}")
  #   handle_event(socket)
  # end

  defp handle_event(socket) do
    receive do
      msg  ->
        Logger.warn("Got msg #{inspect msg}")
      {:ok, events} = Drab.Live.peek(socket, :genevent)
      socket
      |> poke(genevent: inspect(msg) <> "\n" <> events)
    end
    handle_event(socket)
  end
end
