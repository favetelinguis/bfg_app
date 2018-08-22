defmodule BfgEngine.Betfairex.Cache.OrderCacheTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  alias BfgEngine.Betfairex.Cache.OrderCache

  setup do
    {:ok, pid} = OrderCache.start_link(nil)
    {:ok, order_cache: pid}
  end

  test "3 orders opened then canceled", %{order_cache: pid} do
    msg = Resources.TestResources.two_lay_one_back_unmatced
    publish_time = Timex.now
    OrderCache.update(msg[:oc], publish_time)

    msg = Resources.TestResources.two_lay_one_back_canceled
    publish_time = Timex.now
    OrderCache.update(msg[:oc], publish_time)
    # IO.inspect :sys.get_state(pid)
    assert 1 == 1
  end

  test "matched back", %{order_cache: pid} do
    msg = Resources.TestResources.some_mb
    publish_time = Timex.now
    OrderCache.update(msg[:oc], publish_time)

    # IO.inspect :sys.get_state(pid)
    assert 1 == 1
  end

  test "matched lays", %{order_cache: pid} do
    msg = Resources.TestResources.some_ml
    publish_time = Timex.now
    OrderCache.update(msg[:oc], publish_time)

    IO.inspect :sys.get_state(pid)
    assert 1 == 1
  end
end
