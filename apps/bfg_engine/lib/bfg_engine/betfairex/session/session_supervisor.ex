defmodule BfgEngine.Betfairex.Session.SessionSupervisor do
  # Automatically defines child_spec/1
  use Supervisor
  require Logger

  def start_link(arg) do
    Logger.info("#{__MODULE__} started")
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      BfgEngine.Betfairex.Session.SessionManager,
      BfgEngine.Betfairex.Stream.SubscriptionManager
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
