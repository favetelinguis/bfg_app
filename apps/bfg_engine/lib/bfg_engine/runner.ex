defmodule BfgEngine.Runner do
  @moduledoc false
  alias __MODULE__

  defstruct [:name, :status, :ltp, :ladder]

  def new(name) do
    %BfgEngine.Runner{name: name, ladder: BfgEngine.Ladder.new()}
  end

  def update_status(runner, value), do: %Runner{runner | status: value}
  def update_ltp(runner, value), do: %Runner{runner | ltp: value}

end
