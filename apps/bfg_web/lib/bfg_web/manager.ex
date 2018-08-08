defmodule BfgWebWeb.Manager do
  use GenServer
  require Logger

  @me __MODULE__
  @initial_state %{sub: nil, pid: nil}

  def set_running(pid: pid, sub: sub) do
    GenServer.call(@me, {:running_process, pid, sub})
  end

  def get_state() do
    GenServer.call(@me, :get_state)
  end

  def handle_call(:get_state, _from, %{pid: pid} = state) do
    {:reply, pid, state}
  end

  def handle_call({:running_process, pid, sub}, _from, %{sub: old_sub, pid: old_pid} = state) do
    if old_sub && old_pid do
      Hub.unsubscribe(old_sub)
      send(old_pid, :change_subscription)
    end
    {:reply, :ok, %{state | sub: sub, pid: pid}}
  end

  def start_link(_) do
    GenServer.start_link(@me, nil, name: @me)
  end

  def init(_) do
    {:ok, @initial_state}
  end

end
