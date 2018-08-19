defmodule BfgEngine.Betfairex.BetfairexSupervisor do
  use Supervisor
  require Logger

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      BfgEngine.Betfairex.Cache.MarketCache,
      BfgEngine.Betfairex.Cache.OrderCache,
      BfgEngine.Betfairex.Session.SubscriptionStore,
      BfgEngine.Betfairex.Session.SessionSupervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
