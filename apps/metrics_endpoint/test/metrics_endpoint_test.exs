defmodule MetricsEndpointTest do
  use ExUnit.Case
  doctest MetricsEndpoint

  test "greets the world" do
    assert MetricsEndpoint.hello() == :world
  end
end
