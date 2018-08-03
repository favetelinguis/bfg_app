defmodule BfgEngine.RestConnectionTest do
  use ExUnit.Case
  doctest BfgEngine.RestConnection
  import ExUnit.CaptureLog

  alias BfgEngine.RestConnection

  setup do
    bypass = Bypass.open(port: 1337)
    {:ok, bypass: bypass}
  end

  test "sucessful response on login", %{bypass: bypass} do
    response = %{loginStatus: "SUCCESS", sessionToken: "pjVPLpCSG9QZ4h+bKUZWgTkceWPBTLeL3vr9qRAmipE="}
    Bypass.expect(bypass, fn conn ->
      assert "POST" == conn.method
      assert "/certlogin" == conn.request_path
      Plug.Conn.resp(conn, 200, Poison.encode!(response))
    end)
    RestConnection.start_link("user", "pwd", "key")
    Process.sleep(1000) # Start link returns imideatly
  end

  test "connection down", %{bypass: bypass} = context do
    Bypass.down(bypass)
    Process.flag(:trap_exit, true)
    output =
      capture_log(fn ->
        {:ok, _pid} = RestConnection.start_link("user", "pwd", "key")
        :timer.sleep(1000)
      end)

      pid = context[:pid]
      assert output =~ "[error] Login failed Betfair"
      assert_received({:EXIT, _, :login_failed})
  end
end
