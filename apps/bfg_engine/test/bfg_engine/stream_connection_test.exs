defmodule BfgEngine.RestConnectionTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  doctest BfgEngine.MarketStream.Betfair

  alias BfgEngine.MarketStream.Betfair

  setup do
    {:ok, s} = :ssl.connect('localhost', 1414, [packet: 4], :infinity)
    :ssl.send(s, "ping")
    {:ok, socket: s}
  end

  test "connection ok", %{socket: s} = context do
    #sequence = [ {:setup ,%{op: "connection"}}, {:setup ,%{op: "connection2"}} ]
    #:ssl.send(s, {:setup ,sequence})
    BfgEngine.MarketStream.Betfair.start_link("adsf", "adf", ["322", "333"])

    output =
      capture_log(fn ->
        {:ok, _pid} = RestConnection.start_link("user", "pwd", "key")
        :timer.sleep(1000)
      end)

      assert output =~ "TCP connection established"
  end
end
