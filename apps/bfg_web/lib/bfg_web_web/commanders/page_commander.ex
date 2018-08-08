defmodule BfgWebWeb.PageCommander do
  use Drab.Commander
  require Hub
  require Logger

  defhandler subscribe_market(socket, _sender, market_id) do
    Logger.debug("Change subscription to #{market_id} is it string #{is_binary(market_id)}")
    sub = Hub.subscribe(market_id, _)
    :ok = BfgWebWeb.Manager.set_running(pid: self(), sub: sub)
    handle_event(socket, market_id)
  end

  defp handle_event(socket, market_id) do
    receive do
      :change_subscription ->
        Logger.debug("Out with the old in with the new")
        :ok

      msg ->
        Logger.warn("Got msg #{inspect(msg)} for #{inspect market_id}")
        {:ok, events} = Drab.Live.peek(socket, :genevent)

        socket
        |> poke(genevent: inspect(msg) <> "\n" <> events)

        handle_event(socket, market_id)
    end
  end
end
