defmodule BfgEngine.StrategyRulesTest do
  use ExUnit.Case
  doctest BfgEngine.StrategyRules

  alias BfgEngine.StrategyRules

  test "we start over after happy path of full strategy execution" do
    %StrategyRules{state: :initialized} = rules = StrategyRules.new()
    {:ok, rules} = StrategyRules.check(rules, :place_exit)
    {:ok, rules} = StrategyRules.check(rules, :place_entry)
    {:ok, rules} = StrategyRules.check(rules, :take_profit)
    %StrategyRules{state: :initialized} = rules
  end

  test "we start over after emergency exit" do
    %StrategyRules{state: :initialized} = rules = StrategyRules.new()
    {:ok, rules} = StrategyRules.check(rules, :place_exit)
    {:ok, rules} = StrategyRules.check(rules, :emergency_stop)
    %StrategyRules{state: :initialized} = rules
  end

  test "we start over if stoploss is triggered" do
    %StrategyRules{state: :initialized} = rules = StrategyRules.new()
    {:ok, rules} = StrategyRules.check(rules, :place_exit)
    {:ok, rules} = StrategyRules.check(rules, :place_entry)
    {:ok, rules} = StrategyRules.check(rules, :stop_loss)
    %StrategyRules{state: :initialized} = rules
  end
end