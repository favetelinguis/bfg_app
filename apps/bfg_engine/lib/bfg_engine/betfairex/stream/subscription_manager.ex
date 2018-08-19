defmodule BfgEngine.Betfairex.Stream.SubscriptionManager do
  @moduledoc false
  require Logger

  def start_link() do
    Logger.info("#{__MODULE__} started")

    DynamicSupervisor.start_link(
    name: __MODULE__,
    strategy: :one_for_one
    )
  end

  def child_spec(_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  def subscribe_market_stream(session_token) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {BfgEngine.Betfairex.Stream.MarketStream, session_token}
    )
  end

  def subscribe_order_stream(session_token) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {BfgEngine.Betfairex.Stream.OrderStream, session_token}
    )
  end
end
