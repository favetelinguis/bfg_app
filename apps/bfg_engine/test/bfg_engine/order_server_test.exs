defmodule BfgEngine.OrderServerTest do
  use ExUnit.Case
  require Hub

  alias BfgEngine.{OrderServer, OrderCache}

  @singel_limit_unmatched %{
    clk: "AJoyALIoAPw4AOweAKkW",
    id: 2,
    oc: [
      %{
        id: "1.146054800",
        orc: [
          %{
            fullImage: true,
            id: 10_721_835,
            uo: [
              %{
                id: "131888402717",
                ot: "L",
                p: 1.01,
                pd: 1_532_685_359_000,
                pt: "L",
                rac: "",
                rc: "REG_LGA",
                rfo: "",
                rfs: "STOP",
                s: 2,
                sc: 0,
                side: "L",
                sl: 0,
                sm: 0,
                sr: 2,
                status: "E",
                sv: 0
              }
            ]
          }
        ]
      }
    ],
    op: "ocm",
    pt: 1_532_685_537_504
  }

  @singel_lapse_at_inplay %{
    clk: "ALyWFgCjoBAAqs0ZAJq8EQDI3Qw=",
    id: 2,
    oc: [
      %{
        id: "1.146054800",
        orc: [
          %{
            id: 10_721_835,
            uo: [
              %{
                id: "131888402717",
                ld: 1_532_695_330_000,
                ot: "L",
                p: 1.01,
                pd: 1_532_685_359_000,
                pt: "L",
                rac: "",
                rc: "REG_LGA",
                rfo: "",
                rfs: "STOP",
                s: 2,
                sc: 0,
                side: "L",
                sl: 2,
                sm: 0,
                sr: 0,
                status: "EC",
                sv: 0
              }
            ]
          }
        ]
      }
    ],
    op: "ocm",
    pt: 1_532_695_331_519
  }

  @singel_cancel %{
    clk: "ALswAKZCAP9EAKkuAPhB",
    id: 2,
    oc: [
      %{
        id: "1.146054800",
        orc: [
          %{
            id: 10_721_835,
            uo: [
              %{
                id: "131888402717",
                ot: "L",
                p: 1.01,
                pd: 1_532_757_870_000,
                pt: "L",
                rac: "",
                rc: "REG_LGA",
                rfo: "",
                rfs: "STOP",
                s: 2,
                sc: 2,
                side: "L",
                sl: 0,
                sm: 0,
                sr: 0,
                status: "EC",
                sv: 0
              }
            ]
          }
        ]
      }
    ],
    op: "ocm",
    pt: 1_532_758_228_129
  }

  @market_close %{
    clk: "AJKBFwDt2xAAv7UaALiQEgDcmQ0=",
    id: 2,
    oc: [%{closed: true, id: "1.146054800"}],
    op: "ocm",
    pt: 1_532_695_660_659
  }

  test "one new limit order unmatched" do
    msg = get_in(@singel_limit_unmatched, [:oc, Access.at(0)])
    market_id = "1.146054800"
    bet_id = "131888402717"
    selection_id = 10_721_835
    Hub.subscribe(market_id, [{:trade, _, _, _}], multi: true)
    {:ok, pid} = OrderServer.start_link(market_id)

    OrderServer.generate_events(pid, msg)

    # Assert the state is updated with
    expected = get_in(msg, [:orc, Access.at(0), :uo, Access.at(0)])
    expected_size_remaining = expected[:sr]
    expected_size_matched = expected[:sm]
    expected_reference = expected[:rfs]
    ^expected = OrderServer.get_order(pid, bet_id)

    assert_received {:trade, ^selection_id, ^bet_id,
                     %{
                       rfs: ^expected_reference,
                       size_remaining: ^expected_size_remaining,
                       size_matched: ^expected_size_matched
                     }}
  end

  test "limit order lapses when turning inplay" do
    open_trade = get_in(@singel_limit_unmatched, [:oc, Access.at(0)])
    lapse_trade = get_in(@singel_lapse_at_inplay, [:oc, Access.at(0)])
    market_id = "1.146054800"
    bet_id = "131888402717"
    selection_id = 10_721_835
    Hub.subscribe(market_id, [{:trade, _, _, _}], multi: true)
    {:ok, pid} = OrderServer.start_link(market_id)

    OrderServer.generate_events(pid, open_trade)
    OrderServer.generate_events(pid, lapse_trade)

    # Assert the state is updated with
    expected = get_in(lapse_trade, [:orc, Access.at(0), :uo, Access.at(0)])
    expected_size_remaining = expected[:sr]
    expected_size_matched = expected[:sm]
    expected_reference = expected[:rfs]
    ^expected = OrderServer.get_order(pid, bet_id)

    assert_received {:trade, ^selection_id, ^bet_id,
                     %{
                       rfs: ^expected_reference,
                       size_remaining: ^expected_size_remaining,
                       size_matched: ^expected_size_matched
                     }}
  end

  test "market closes" do
    open_trade = get_in(@singel_limit_unmatched, [:oc, Access.at(0)])
    lapse_trade = get_in(@singel_lapse_at_inplay, [:oc, Access.at(0)])
    market_close = get_in(@market_close, [:oc, Access.at(0)])
    market_id = "1.146054800"
    bet_id = "131888402717"
    selection_id = 10_721_835
    Hub.subscribe(market_id, [{:trade, _, _, _}], multi: true)
    {:ok, pid} = OrderServer.start_link(market_id)

    OrderServer.generate_events(pid, open_trade)
    OrderServer.generate_events(pid, lapse_trade)
    OrderServer.generate_events(pid, market_close)

    # Assert the state is updated with
    expected = get_in(lapse_trade, [:orc, Access.at(0), :uo, Access.at(0)])
    expected_size_remaining = expected[:sr]
    expected_size_matched = expected[:sm]
    expected_reference = expected[:rfs]
    ^expected = OrderServer.get_order(pid, bet_id)

    assert_received {:trade, ^selection_id, ^bet_id,
                     %{
                       rfs: ^expected_reference,
                       size_remaining: ^expected_size_remaining,
                       size_matched: ^expected_size_matched
                     }}
  end

  test "limit order canceled" do
    open_trade = get_in(@singel_limit_unmatched, [:oc, Access.at(0)])
    cancel_trade = get_in(@singel_cancel, [:oc, Access.at(0)])
    market_id = "1.146054800"
    bet_id = "131888402717"
    selection_id = 10_721_835
    Hub.subscribe(market_id, [{:trade, _, _, _}], multi: true)
    {:ok, pid} = OrderServer.start_link(market_id)

    OrderServer.generate_events(pid, open_trade)
    OrderServer.generate_events(pid, cancel_trade)

    # Assert the state is updated with
    expected = get_in(cancel_trade, [:orc, Access.at(0), :uo, Access.at(0)])
    expected_size_remaining = expected[:sr]
    expected_size_matched = expected[:sm]
    expected_reference = expected[:rfs]
    ^expected = OrderServer.get_order(pid, bet_id)

    assert_received {:trade, ^selection_id, ^bet_id,
                     %{
                       rfs: ^expected_reference,
                       size_remaining: ^expected_size_remaining,
                       size_matched: ^expected_size_matched
                     }}
  end
end
