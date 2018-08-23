
defmodule BfgEngine.Betfairex.Cache.MarketCacheTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  alias BfgEngine.Betfairex.Cache.MarketCache

  setup do
    {:ok, pid} = MarketCache.start_link(nil)
    {:ok, market_cache: pid}
  end

  test "initial image", %{market_cache: pid} do
    msg = Resources.TestResources.markets_sub_image_depth_based_ladders
    publish_time = Timex.now
    MarketCache.update(msg[:mc], publish_time)
    MarketCache.update(msg[:mc], publish_time)

    IO.inspect :sys.get_state(pid)
    assert 1 == 1
  end
end
