defmodule BfgEngine.StrategyServer do
  @moduledoc """
  Responisble for making trading decisions for a market
  """
  use GenServer, restart: :transient
  require Logger
  require Hub

  alias BfgEngine.{
    Market,
    Runner,
    ServerRegistry,
    MarketServer,
    MarketCache,
    RestConnection,
    StrategyRules,
    Ladder
  }

  @init_state %{
    market_id: nil,
    timer_ref: nil,
    rules: StrategyRules.new(),
    init_subscription: nil,
    exit_price: nil,
    ltp_subscription: nil
  }

  # Client

  # Server
  def start_link(market_id) do
    Logger.info(fn -> "Starting strategy server for #{market_id}" end)
    GenServer.start_link(__MODULE__, market_id, name: via_tuple(market_id))
  end

  defp via_tuple(market_id) do
    {__MODULE__, market_id}
    |> ServerRegistry.via_tuple()
  end

  @impl true
  def init(market_id) do
    subscribe(market_id)
    {:ok, %{@init_state | market_id: market_id}}
  end

  @impl true
  @doc """
  Cancel any ongoing trigger, this says the market time has changed, i should only ever get this message once
  Check if we are closer then 10mins from start
  If we have more then 10 mins schedule an event to trigger 10 mins before
  Register the timer ref in state
  """
  def handle_info({:marketTime, market_start_time} = msg, %{timer_ref: timer_ref} = state) do
    with {:ok, rules} <- StrategyRules.check(state.rules, :set_strategy_start_trigger) do
      if timer_ref do
        Logger.warn("Market time changed")
        Process.cancel_timer(timer_ref)
      end

      interval_10_mins_before_start =
        Timex.Interval.new(from: Timex.now(), until: Timex.shift(market_start_time, minutes: -13))

      interval_30_seconds_before_start =
        Timex.Interval.new(from: Timex.now(), until: Timex.shift(market_start_time, seconds: -30))

      # TODO i woner if CEST is correct even when winter time?
      timezone = Timex.Timezone.get("Europe/Stockholm", Timex.now())
      newdt = Timex.Timezone.convert(market_start_time, timezone)

      ref =
        case Timex.before?(Timex.now(), market_start_time) do
          # true -> Logger.info(fn -> "Trigger set for strategy that starts #{newdt}}" end);{:ok, Process.send_after(self(), :init_strategy, Timex.Interval.duration(interval_until_trigger, :seconds) * 1000)}
          true ->
            Logger.info(fn -> "Temporary trigger for test" end)
            # Send a trigger 30 seconds before market goes inplay
            Process.send_after(
              self(),
              :turning_inplay,
              Timex.Interval.duration(interval_30_seconds_before_start, :seconds) * 1000
            )

            # Send a trigger x secs before market goes inlay to start trading
            {:ok, Process.send_after(self(), :init_strategy, 2000)}

          false ->
            Logger.info(fn -> "We are to close to market start to start a strategy" end)
            {:error, "Not started"}

          _ ->
            Logger.error(
              "Unable to handle time #{inspect(market_start_time)} and #{inspect(Timex.now())}"
            )
        end

      case ref do
        {:ok, ref_id} ->
          {:noreply, %{state | timer_ref: ref_id, rules: rules}}

        # TODO we are not clearning up if there was a canceld timer ref
        {:error, _} ->
          {:noreply, state}
      end
    else
      :error ->
        Logger.error("Got message #{inspect(msg)} when in #{inspect(state.rules)}")
        {:noreply, state}
    end
  end

  @impl true
  @doc """
  Init strategy
  Right now have a demo strategy:
  Once triggerd find the favorite for the market
  Send a lay bet at 1.01?
  Create an order server for the returned betid
  Subscribe on order events from that order id that is returned
  Once I get the message that the order is open cancel it
  """
  def handle_info(:init_strategy = msg, %{market_id: market_id} = state) do
    with {:ok, rules} <- StrategyRules.check(state.rules, :init_strategy) do
      selection_id =
        market_id
        |> MarketCache.server_process()
        |> MarketServer.get_favorite()

      {:ok, batl_subscription} =
        Hub.subscribe(market_id, {:batl, selection_id, _}, bind_quoted: [id: selection_id])

      Logger.debug("Strategy is initialized on #{market_id} for #{selection_id}")
      {:noreply, %{state | rules: rules, init_subscription: batl_subscription}}
    else
      :error ->
        Logger.error("Got message #{inspect(msg)} when in #{inspect(state.rules)}")
        {:noreply, state}
    end
  end

  @doc """
  This is the function where prices are investigated to find empty
  spots to place exits in
  """
  def handle_info(
        {:batl, selection_id, _ladder} = msg,
        %{market_id: market_id, init_subscription: sub} = state
      ) do
    with {:ok, rules} <- StrategyRules.check(state.rules, :send_exit) do
      Hub.publish("decisions", {:exit, market_id, "bla"})
      # If we find a place to put a trade in unsubscribe from batl to not slow down the strategy
      Hub.unsubscribe(sub)
      ltp_subscription = Hub.subscribe(market_id, {:ltp, _, _})
      # TODO this needs to be from batl
      exit_price = 36
      Logger.debug(fn -> "Decision for placing exit sent at price #{exit_price}" end)
      # TODO only update ruels if strategy is triggered else just use old state
      {:noreply,
       %{
         state
         | rules: rules,
           exit_price: exit_price,
           ltp_subscription: ltp_subscription,
           init_subscription: nil
       }}
    else
      :error ->
        # its possible to get some more batl before the unsubscription is done but they should just go here
        Logger.warn("Got message #{inspect(msg)} when in #{inspect(state.rules)}")
        {:noreply, state}
    end
  end

  @doc """
  Gets triggered as the first message when a stop order is placed and it is not matched
  """
  def handle_info(
        {:trade, selection_id, bet_id,
         %{rfs: "STOP", size_matched: 0, size_lapsed: 0, size_cancelled: 0, size_voided: 0} = msg},
        %{market_id: market_id} = state
      ) do
    with {:ok, rules} <- StrategyRules.check(state.rules, :exit_recived) do
      Logger.debug(fn -> "Placing exit executed" end)
      {:noreply, %{state | rules: rules}}
    else
      :error ->
        Logger.warn("Got message #{inspect(msg)} when in #{inspect(state.rules)}")
        {:noreply, state}
    end
  end

  @doc """
  Handles when matching starts of the exit before entry is placed
  """
  def handle_info(
        {:trade, selection_id, bet_id,
         %{rfs: "STOP", size_matched: sm, size_lapsed: 0, size_cancelled: 0, size_voided: 0} = msg},
        %{market_id: market_id} = state
      )
      when sm > 0 do
    with {:ok, rules} <- StrategyRules.check(state.rules, :emergency_stop) do
      Hub.publish("decisions", {:emergency_stop, market_id, "bla"})
      Logger.debug(fn -> "Decision for emergency exit sent" end)
      {:noreply, %{state | rules: rules}}
    else
      :error ->
        Logger.warn("Got message #{inspect(msg)} when in #{inspect(state.rules)}")
        {:noreply, state}
    end
  end

  @doc """

  """
  def handle_info(
        {:ltp, selection_id, ltp} = msg,
        %{market_id: market_id, exit_price: exit_price, ltp_subscription: sub} = state
      ) do
    with {:ok, rules} <- StrategyRules.check(state.rules, :place_entry) do
      # Now when hardcoded batl im putting in a lay exit I want to back one level below
      # So find what the price is one level below the exit_pricet
      case Ladder.find_entry_price(exit_price, "LAY") == ltp do
        true ->
          Hub.publish("decisions", {:entry, market_id, "bla"})
          # no need to subscribe to ltp after entry
          Hub.unsubscribe(sub)
          Logger.debug(fn -> "Decision for placing entry sent at price #{ltp}" end)
          {:noreply, %{state | rules: rules, ltp_subscription: nil}}

        false ->
          Logger.debug(fn -> "Not triggering entry exit #{exit_price} ltp #{ltp}" end)
          {:noreply, state}
      end
    else
      :error ->
        # its possible to get some more batl before the unsubscription is done but they should just go here
        Logger.warn("Got message #{inspect(msg)} when in #{inspect(state.rules)}")
        {:noreply, state}
    end
  end

  @doc """
  Confirms that entry is recived, places the stop order right after
  """
  def handle_info(
        {:trade, selection_id, bet_id,
         %{rfs: "ENTRY"} = msg},
        %{market_id: market_id} = state
      ) do
    with {:ok, rules} <- StrategyRules.check(state.rules, :entry_recived) do
      # When entry is recived we set the stop loss
      # TODO do i need to cancel the stop loss when the entry is recived
      Hub.publish("decisions", {:stop_loss, market_id, "bla"})
      Logger.debug(fn -> "Decision for stop loss sent" end)
      {:noreply, %{state | rules: rules}}
    else
      :error ->
        Logger.warn("Got message #{inspect(msg)} when in #{inspect(state.rules)}")
        {:noreply, state}
    end
  end

  @doc """
  Confirms that entry is recived, places the stop order right after
  """
  def handle_info(
        {:trade, selection_id, bet_id,
         %{rfs: "STOP_LOSS"} = msg},
        %{market_id: market_id} = state
      ) do
    with {:ok, rules} <- StrategyRules.check(state.rules, :stop_loss_recived) do
      # When entry is recived we set the stop loss
      # TODO do i need to cancel the stop loss when the entry is recived
      Hub.publish("decisions", {:stop_loss, market_id, "bla"})
      Logger.debug(fn -> "Decision for stop loss sent" end)
      {:noreply, %{state | rules: rules}}
    else
      :error ->
        Logger.warn("Got message #{inspect(msg)} when in #{inspect(state.rules)}")
        {:noreply, state}
    end
  end

  @doc """
  Triggered when there is 30 seconds left until inplay, send decission to exit all trades and greenup
  """
  def handle_info(
        :turning_inplay = msg,
        %{market_id: market_id, exit_price: exit_price, ltp_subscription: sub} = state
      ) do
    with {:ok, rules} <- StrategyRules.check(state.rules, :turning_inplay) do
      Hub.publish("decisions", {:greenup, market_id, "bla"})
      Logger.debug(fn -> "Decision for greening up" end)
      {:noreply, %{state | rules: rules}}
    else
      :error ->
        # its possible to get some more batl before the unsubscription is done but they should just go here
        Logger.warn("Got message #{inspect(msg)} when in #{inspect(state.rules)}")
        {:noreply, state}
    end
  end

  # We need a handle info for enty that when recived will set
  def handle_info(msg, state) do
    Logger.warn(
      "In catch all from strategy server of #{state[:market_id]} and got message #{inspect(msg)}"
    )

    {:noreply, state}
  end

  defp subscribe(market_id) do
    Hub.subscribe(market_id, {:marketTime, time}, count: 1)
    Hub.subscribe(market_id, [{:trade, _, _, _}], multi: true)
  end
end

# Last message when a market closes
# %{clk: "ALanLwDgkjMA28Mt", id: 3, mc: [%{con: true, id: "1.146054800", marketDefinition: %{betDelay: 1, bettingType: "ODDS", bspMarket: true, bspReconciled: true, complete: true, countryCode: "GB", crossMatching: false, discountAllowed: true, eventId: "28818850", eventTypeId: "7", inPlay: true, marketBaseRate: 5, marketTime: "2018-07-27T12:40:00.000Z", marketType: "WIN", numberOfActiveRunners: 0, numberOfWinners: 1, openDate: "2018-07-27T12:40:00.000Z", persistenceEnabled: true, priceLadderDefinition: %{type: "CLASSIC"}, raceType: "Hurdle", regulators: ["MR_INT"], runners: [%{adjustmentFactor: 0.769, id: 10868462, removalDate: "2018-07-27T08:33:54.000Z", sortPriority: 1, status: "REMOVED"}, %{adjustmentFactor: 35.534, bsp: 3.5981460337815383, id:10721835, sortPriority: 2, status: "LOSER"}, %{adjustmentFactor: 21.277, bsp: 3.65, id: 11115511, sortPriority: 3, status: "LOSER"}, %{adjustmentFactor: 14.286, bsp: 8.6, id: 11404383, sortPriority: 4, status: "LOSER"}, %{adjustmentFactor: 7.692, bsp: 7.522053326, id: 10500776, sortPriority: 5, status: "LOSER"}, %{adjustmentFactor: 6.25, bsp: 24.66899722788046, id: 18105902, sortPriority: 6, status: "LOSER"}, %{adjustmentFactor: 4.545, bsp: 20, id: 11757735, sortPriority: 7, status: "WINNER"}, %{adjustmentFactor: 2.5, bsp: 35.37697770956351, id: 18890002, sortPriority: 8, status: "LOSER"}, %{adjustmentFactor: 2.381, bsp: 34, id: 16301858, sortPriority: 9, status: "LOSER"}, %{adjustmentFactor: 2.273, bsp: 116.001650931, id: 13195145, sortPriority: 10, status: "LOSER"}, %{adjustmentFactor: 1.429, bsp: 62.684962937, id: 8225254, sortPriority: 11, status: "LOSER"}, %{adjustmentFactor: 1, bsp: 170.310354849127, id:12793233, sortPriority: 12, status: "LOSER"}, %{adjustmentFactor: 0.833, bsp: 42.97957565175369, id: 8397429, sortPriority: 13, status: "LOSER"}], runnersVoidable: false, settledTime: "2018-07-27T12:46:13.000Z", status: "CLOSED", suspendTime: "2018-07-27T12:40:00.000Z", timezone: "Europe/London", turnInPlayEnabled: true, venue: "Uttoxeter", version: 2311092320}, rc: [%{id: 16301858, ltp: 550}, %{id: 11757735, ltp: 2}, %{id: 11115511, ltp: 2}, %{id: 18105902, ltp: 550}, %{id: 8397429, ltp: 530}, %{id: 18890002, ltp: 550}, %{id: 8225254, ltp: 540}, %{id: 11404383, ltp: 550}, %{id: 12793233, ltp: 550}, %{id: 10721835, ltp: 2.5}, %{id: 13195145, ltp: 32},%{id: 10500776, ltp: 550}]}], op: "mcm", pt: 1532695797992}
