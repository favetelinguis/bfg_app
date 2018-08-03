defmodule BfgEngine.StrategyRules do
  alias __MODULE__

  defstruct state: :initialized

  def new() do %StrategyRules{} end

  @doc """
  If we are inplay dont alow any actions
  """
  def check(%StrategyRules{state: :inplay} = rules, _action) do
    :error
  end

  def check(%StrategyRules{state: :initialized} = rules, :set_strategy_start_trigger) do
    {:ok, %StrategyRules{rules | state: :trigger_set}}
  end

  def check(%StrategyRules{state: :trigger_set} = rules, :init_strategy) do
    {:ok, %StrategyRules{rules | state: :strategy_live}}
  end

  def check(%StrategyRules{state: :strategy_live} = rules, :send_exit) do
    {:ok, %StrategyRules{rules | state: :exit_sent}}
  end

  def check(%StrategyRules{state: :exit_sent} = rules, :exit_recived) do
    {:ok, %StrategyRules{rules | state: :exit_live}}
  end

  def check(%StrategyRules{state: :exit_live} = rules, :emergency_stop) do
    {:ok, %StrategyRules{rules | state: :initialized}}
  end

  def check(%StrategyRules{state: :exit_live} = rules, :place_entry) do
    {:ok, %StrategyRules{rules | state: :entry_placed}}
  end

  def check(%StrategyRules{state: :entry_placed} = rules, :entry_recived) do
    {:ok, %StrategyRules{rules | state: :entry_live}}
  end

  def check(%StrategyRules{state: :entry_live} = rules, :stop_loss_recived) do
    {:ok, %StrategyRules{rules | state: :am_i_winning}}
  end

  @doc """
  Must come second to last since im exiting all
  """
  def check(rules, :turning_inplay) do
    {:ok, %StrategyRules{rules | state: :inplay}}
  end

  # Catch all here we dont want to change the state so we return error, this must be the last check
  def check(_state, _action), do: :error
end
