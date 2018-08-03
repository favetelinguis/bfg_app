defmodule BfgEngine.ServerRegistry do
  @moduledoc false
  require Logger

  def start_link do
    Logger.info(fn -> "Starting server registry" end)
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def via_tuple(key) do
    {:via, Registry, {__MODULE__, key}}
  end

  def child_spec(_) do
    Supervisor.child_spec(
      Registry,
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    )
  end
end
