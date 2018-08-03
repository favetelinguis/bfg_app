defmodule BfgEngineTest do
  use ExUnit.Case
  doctest BfgEngine

  test "greets the world" do
    assert BfgEngine.hello() == :world
  end
end
