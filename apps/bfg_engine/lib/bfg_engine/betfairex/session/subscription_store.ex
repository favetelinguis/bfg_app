defmodule BfgEngine.Betfairex.Session.SubscriptionStore do
  use Agent
  require Logger

  @me __MODULE__

  def start_link(_) do
    Agent.start_link(
      fn ->
        Logger.info("#{@me} started")

        %{
          order_state: nil,
          market_state: nil
        }
      end,
      name: @me
    )
  end

  def get_order_subscription_state() do
    Agent.get(@me, fn %{order_state: state} ->
      Logger.debug("In get_order_subscription_state")
      state
    end)
  end

  def set_order_subscription_state(new_state) do
    Agent.update(@me, fn state ->
      Logger.debug("In set_order_subscription_state")
      %{state | order_state: new_state}
    end)
  end

  def get_market_subscription_state() do
    Agent.get(@me, fn %{market_state: state} ->
      Logger.debug("In get_market_subscription_state")
      state
    end)
  end

  def set_market_subscription_state(new_state) do
    Agent.update(@me, fn state ->
      Logger.debug("In set_market_subscription_state")
      %{state | market_state: new_state}
    end)
  end
end
