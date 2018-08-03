defmodule BfgEngine.OrderServerTest do
  use ExUnit.Case
  require Timex
  require Hub
  import ExUnit.CaptureLog

  alias BfgEngine.{StrategyServer, MarketServer, Market, Ladder}
  @market_id "1.146128087"
  @favorite_selection_id 19_467_345
  @market %BfgEngine.Market{
    inPlay: false,
    name: "6f Nov Stks",
    runners: %BfgEngine.Runners{
      runner: %{
        18_910_501 => %BfgEngine.Runner{
          ladder: %BfgEngine.Ladder{
            batb: [[0, 13, 1.98], [1, 12.5, 2.19]],
            batl: [[0, 280, 21.2], [1, 300, 2.2]]
          },
          ltp: 12.5,
          name: "Shining",
          status: "ACTIVE"
        },
        19_199_918 => %BfgEngine.Runner{
          ladder: %BfgEngine.Ladder{
            batb: [[0, 8.8, 1.47], [1, 8.6, 1.97]],
            batl: [[0, 13.5, 4.19], [1, 42, 21]]
          },
          ltp: 8.8,
          name: "Sibirica",
          status: "ACTIVE"
        },
        19_450_870 => %BfgEngine.Runner{
          ladder: %BfgEngine.Ladder{
            batb: [[0, 7.8, 1.98], [1, 7.6, 2.35]],
            batl: [[0, 280, 21.2], [1, 300, 2.2]]
          },
          ltp: nil,
          name: "Satwa Park",
          status: "ACTIVE"
        },
        19_467_345 => %BfgEngine.Runner{
          ladder: %BfgEngine.Ladder{
            batb: [[0, 2.48, 3.16], [1, 2.46, 4.16]],
            batl: [[0, 2.74, 2.2], [1, 2.78, 2.83]]
          },
          ltp: 2.52,
          name: "No Way Jose",
          status: "ACTIVE"
        },
        19_629_454 => %BfgEngine.Runner{
          ladder: %BfgEngine.Ladder{
            batb: [[0, 2.82, 22.93], [1, 2.72, 4.91]],
            batl: [[0, 3.35, 2], [1, 3.4, 1.78]]
          },
          ltp: 2.86,
          name: "Shorter Skirt",
          status: "ACTIVE"
        },
        19_902_238 => %BfgEngine.Runner{
          ladder: %BfgEngine.Ladder{
            batb: [[0, 4.1, 2.56], [1, 4, 7.1]],
            batl: [[0, 5.1, 3.2], [1, 5.2, 26.4]]
          },
          ltp: 4,
          name: "Accommodate",
          status: "ACTIVE"
        }
      }
    },
    start_time: "2018-07-30T12:20:00.000Z",
    status: "OPEN"
  }

  setup do
    {:ok, pid} = MarketServer.start_link(@market_id, @market)
    {:ok, market_pid: pid}
  end

  test "test emergency stop if matching exit before entry", %{market_pid: market_pid} do
    market_id = @market_id
    favorite = @favorite_selection_id
    Hub.subscribe("decisions", _)
    {:ok, pid} = StrategyServer.start_link(market_id)
    # Need to wait for strategy to be initialized before sending message
    assert capture_log(fn ->
             1 = Hub.publish(market_id, {:marketTime, Timex.shift(Timex.now(), hours: 3)})
             # Need to wait for all logs to be generated
             Process.sleep(3000)
           end) =~ "Strategy is initialized on 1.146128087 for 19467345"

    assert capture_log(fn ->
             1 = Hub.publish(market_id, {:batl, 19_467_345, [[0, 2.82, 22.93], [1, 2.72, 4.91]]})
             # Need to wait for all logs to be generated
             Process.sleep(1000)
           end) =~ "Decision for placing exit sent"

    assert_receive {:exit, market_id, _}

    assert capture_log(fn ->
             msg =
               {:trade, favorite, "131888402717",
                %{
                  rfs: "STOP",
                  size_remaining: 2,
                  size_matched: 0,
                  size_lapsed: 0,
                  size_cancelled: 0,
                  size_voided: 0
                }}

             1 = Hub.publish(market_id, msg)
             Process.sleep(1000)
           end) =~ "Placing exit executed"

    assert capture_log(fn ->
             msg =
               {:trade, favorite, "131888402717",
                %{
                  rfs: "STOP",
                  size_remaining: 1,
                  size_matched: 1,
                  size_lapsed: 0,
                  size_cancelled: 0,
                  size_voided: 0
                }}

             1 = Hub.publish(market_id, msg)
             Process.sleep(1000)
           end) =~ "Decision for emergency exit sent"

    assert_receive {:emergency_stop, market_id, _}
  end

  test "test happy path", %{market_pid: market_pid} do
    market_id = @market_id
    favorite = @favorite_selection_id
    Hub.subscribe("decisions", _)
    {:ok, pid} = StrategyServer.start_link(market_id)
    # Need to wait for strategy to be initialized before sending message
    assert capture_log(fn ->
             1 = Hub.publish(market_id, {:marketTime, Timex.shift(Timex.now(), hours: 3)})
             # Need to wait for all logs to be generated
             Process.sleep(3000)
           end) =~ "Strategy is initialized on 1.146128087 for 19467345"

    assert capture_log(fn ->
             1 = Hub.publish(market_id, {:batl, 19_467_345, [[0, 2.82, 22.93], [1, 2.72, 4.91]]})
             # Need to wait for all logs to be generated
             Process.sleep(1000)
           end) =~ "Decision for placing exit sent at price 36"

    assert_receive {:exit, market_id, _}

    assert capture_log(fn ->
             msg =
               {:trade, favorite, "131888402717",
                %{
                  rfs: "STOP",
                  size_remaining: 2,
                  size_matched: 0,
                  size_lapsed: 0,
                  size_cancelled: 0,
                  size_voided: 0
                }}

             1 = Hub.publish(market_id, msg)
             Process.sleep(1000)
           end) =~ "Placing exit executed"

    assert capture_log(fn ->
             1 = Hub.publish(market_id, {:ltp, 19_467_345, 38})
             # Need to wait for all logs to be generated
             Process.sleep(1000)
           end) =~ "Decision for placing entry sent at price 38"

    assert_receive {:entry, market_id, _}
  end

  test "unable to place LAY exit 1000" do

  end

  test "unable to place BACK exit at 1.01" do

  end
end
