defmodule BfgEngine.OrderCache do
  @moduledoc false
  require Logger

  def start_link() do
    Logger.info(fn -> "Starting order cache" end)

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

  @doc """
  Returns the pid of the started process
  """
  def server_process(market_id) do
    case start_child(market_id) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  def start_child(market_id) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {BfgEngine.OrderServer, market_id}
    )
  end
end
