defmodule BfgEngine.PubSub do
  @moduledoc false
  require Logger

  @me __MODULE__

  def start_link do
    Logger.info(fn -> "Starting pubsub registry" end)
    :ets.new(:pub_sub_ets, [:set, :named_table, :public, write_concurrency: true])
    Registry.start_link(
      keys: :duplicate,
      partitions: System.schedulers_online(),
      name: @me)
  end

  @doc """
  Subscribe to the given topic wich should be Event.topic()
  Any pid can only subscribe once
  Returns the last published message on topic or nil if no message has been published
  """
  def subscribe(topic) do
    if Enum.emty?(Registry.lookup(@me, topic)) do
      Registry.register(@me, topic, [])
    end
    get(topic)
  end

  def publish(%_{} = data) do
    key = data.__struct__
    Registry.dispatch(@me, key, fn entries ->
      for {pid, _} <- entries, do: send(pid, data)
    end)
    put(key, data) # Put after i dispatch so if i subscribe at the same time i will get the new value in the inbox
  end

  def publish(_) do
    Logger.error("Not valid input to publish")
    :error
  end

  def child_spec(_) do
    Supervisor.child_spec(
      Registry,
      id: @me,
      start: {@me, :start_link, []}
    )
  end

  defp put(key, value) do
    :ets.insert(:pub_sub_ets, {key, value})
  end

  defp get(key) do
    case :ets.lookup(:pub_sub_ets, key) do
      [{^key, value}] -> value
      [] -> nil
    end
  end
end
