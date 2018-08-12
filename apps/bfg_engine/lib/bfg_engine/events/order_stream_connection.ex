defmodule BfgEngine.Events.OrderStreamConnection do

  alias __MODULE__

  defstruct [:status, header: %BfgEngine.Events.Header{}]

  def topic(), do: %OrderStreamConnection{}.__struct__

  def new(status) when status in [:connecting, :connected, :disconnected] do
    %OrderStreamConnection{status: status}
  end
end
