# Testcases to mimic, including bug
# https://github.com/liampauling/betfair/blob/26da8986d292f13af50262cddf85449b2f731bac/tests/unit/test_cache.py#L92

defmodule BfgEngine.RestConnectionTest do
  use ExUnit.Case
  doctest BfgEngine.Ladder

  alias BfgEngine.Ladder

  @ladder_levels Application.get_env(:bfg_engine, :ladder_levels)
  @initial_list 0..@ladder_levels-1 |> Enum.map(&([&1, nil, nil]))

  test "test_update_available_new_update" do
    book_update = [[0, 36, 0.57]]
    current = @initial_list
    expected = [[0, 36, 0.57], [1, nil, nil]]
    assert expected == Ladder.merge_prices(current, book_update)
  end

  test "test_update_available_new_replace" do
    book_update = [[0, 36, 0.57]]
    current = [[0, 36, 10.57], [1, 38, 3.57]]
    expected = [[0, 36, 0.57], [1, 38, 3.57]]
    assert expected == Ladder.merge_prices(current, book_update)
  end

  test "tests handling of betfair bug" do
    # i see the bug as betfair telling the cache to remove the order from position 1 but there is no order in position 1
    book_update = [[1, 0, 0], [0, 1.02, 1126.22]]
    current = [[0, 1.02, 1126.22], [1, nil, nil]]
    expected = [[0, 1.02, 1126.22], [1, nil, nil]]
    assert expected == Ladder.merge_prices(current, book_update)
  end

  test "test_update_available_new_remove remove first" do
    book_update = [[0, 36, 0], [1, 38, 0], [0, 38, 3.57]]
    current = [[0, 36, 10.57], [1, 38, 3.57]]
    expected = [[0, 38, 3.57], [1, nil, nil]]
    assert expected == Ladder.merge_prices(current, book_update)
  end

  test "test_update_available_new_remove remove after" do
    # Not sure this case is possible but I have support for it just in case
    book_update = [[0, 38, 3.57], [1, 38, 0], [0, 36, 0]]
    current = [[0, 36, 10.57], [1, 38, 3.57]]
    expected = [[0, 38, 3.57], [1, nil, nil]]
    assert expected == Ladder.merge_prices(current, book_update)
  end

  test "when market is done [0, 0, 0] messages is sent for all market depth" do
    # example message
    # %{clk: "AOyCLgDasDIAheUs", id: 3, mc: [%{con: true, id: "1.146054800", marketDefinition: %{betDelay: 1, bettingType: "ODDS", bspMarket: true, bspReconciled: true, complete: true, countryCode: "GB", crossMatching: true, discountAllowed: true, eventId: "28818850", eventTypeId: "7", inPlay: true, marketBaseRate: 5, marketTime: "2018-07-27T12:40:00.000Z", marketType: "WIN", numberOfActiveRunners: 12, numberOfWinners: 1, openDate: "2018-07-27T12:40:00.000Z", persistenceEnabled: true, priceLadderDefinition: %{type: "CLASSIC"}, raceType: "Hurdle", regulators: ["MR_INT"], runners: [%{adjustmentFactor: 35.534, bsp: 3.5981460337815383, id: 10721835, sortPriority: 1, status: "ACTIVE"}, %{adjustmentFactor: 21.277, bsp: 3.65, id: 11115511, sortPriority: 2, status: "ACTIVE"}, %{adjustmentFactor: 14.286, bsp: 8.6, id: 11404383, sortPriority: 3, status: "ACTIVE"}, %{adjustmentFactor: 7.692, bsp: 7.522053326, id: 10500776, sortPriority: 4, status: "ACTIVE"}, %{adjustmentFactor: 6.25, bsp: 24.66899722788046, id: 18105902, sortPriority: 5, status: "ACTIVE"}, %{adjustmentFactor: 4.545, bsp: 20, id: 11757735, sortPriority: 6, status: "ACTIVE"}, %{adjustmentFactor: 2.5, bsp: 35.37697770956351, id: 18890002, sortPriority: 7, status: "ACTIVE"}, %{adjustmentFactor: 2.381, bsp: 34, id: 16301858, sortPriority: 8, status: "ACTIVE"}, %{adjustmentFactor: 2.273, bsp: 116.001650931, id: 13195145, sortPriority: 9, status: "ACTIVE"}, %{adjustmentFactor: 1.429, bsp: 62.684962937, id: 8225254, sortPriority: 10, status: "ACTIVE"}, %{adjustmentFactor: 1, bsp: 170.310354849127, id: 12793233, sortPriority: 11, status: "ACTIVE"}, %{adjustmentFactor: 0.833, bsp: 42.97957565175369, id: 8397429,sortPriority: 12, status: "ACTIVE"}, %{adjustmentFactor: 0.769, id: 10868462, removalDate: "2018-07-27T08:33:54.000Z", sortPriority: 13, status: "REMOVED"}], runnersVoidable: false, status: "SUSPENDED", suspendTime: "2018-07-27T12:40:00.000Z", timezone: "Europe/London", turnInPlayEnabled: true, venue: "Uttoxeter", version: 2311091212}, rc: [%{batb: [[1, 0, 0], [0, 0, 0]], batl: [[1, 0, 0], [0, 0, 0]], id: 16301858, ltp: 1000}, %{batb: [[0, 0, 0], [1, 0, 0]], batl: [[1, 0, 0], [0, 0, 0]], id: 11757735, ltp: 1.01}, %{batb: [[1, 0, 0], [0, 0, 0]], batl: [[0, 0, 0], [1, 0, 0]], id: 11115511, ltp: 1000}, %{batb: [[1, 0, 0], [0, 0, 0]], batl: [[0, 0, 0], [1, 0, 0]], id: 18105902, ltp: 1000}, %{batb: [[1, 0, 0], [0, 0, 0]], batl: [[1, 0, 0], [0, 0, 0]], id: 8397429, ltp: 1000}, %{batb: [[1, 0, 0], [0, 0, 0]], batl: [[0, 0, 0], [1, 0, 0]], id: 18890002, ltp: 1000}, %{batb: [[1, 0, 0], [0, 0, 0]], batl: [[0, 0, 0], [1,0, 0]], id: 8225254, ltp: 1000}, %{batb: [[1, 0, 0], [0, 0, 0]], batl: [[0, 0, 0], [1, 0, 0]], id: 11404383, ltp: 1000}, %{batb: [[1, 0, 0], [0, 0, 0]], batl: [[1, 0, 0], [0, 0, 0]], id: 12793233, ltp: 1000}, %{batb: [[1, 0, 0], [0, 0, 0]], batl: [[1, 0, 0], [0, 0, 0]], id: 10721835, ltp: 1000}, %{batb: [[1, 0, 0], [0, 0, 0]], batl: [[1, 0, 0], [0, 0, 0]], id: 13195145, ltp: 1000}, %{batb: [[1, 0, 0], [0, 0, 0]], batl: [[1, 0, 0], [0, 0, 0]], id: 10500776, ltp: 1000}]}], op: "mcm", pt: 1532695617989}
    book_update = [[0, 0, 0], [1, 0, 0]]
    current = [[0, 36, 10.57], [1, 38, 3.57]]
    expected = [[0, nil, nil], [1, nil, nil]]
    assert expected == Ladder.merge_prices(current, book_update)
  end

  test "get price for lay exit" do
    assert Ladder.find_entry_price(36, "LAY") == 38.0
  end

  test "get price for back exit" do
    assert Ladder.find_entry_price(36, "BACK") == 34.0
  end
end
