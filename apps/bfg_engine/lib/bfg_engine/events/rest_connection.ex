defmodule BfgEngine.Events.RestConnection do

  alias __MODULE__

  defstruct [:status, header: %BfgEngine.Events.Header{}]

  def topic(), do: %RestConnection{}.__struct__

  def new(status) when status in [:connecting, :connected, :disconnected] do
    %RestConnection{status: status}
  end
end
