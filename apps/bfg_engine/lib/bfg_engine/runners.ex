defmodule BfgEngine.Runners do
  @moduledoc false

  defstruct [:runner]

  def new() do
    %BfgEngine.Runners{runner: %{}}
  end

  def add_runner(runners, selection_id, runner) do
    put_in(runners, [Access.key(:runner), Access.key(selection_id, runner)], runner)
  end

  def remove_runner(runners, selection_id) do
    pop_in(runners, [Access.key(:runner), Access.key(selection_id)]) |> elem(1)
  end

  @doc """
  Returns a sorted list of slection_ids where the first id is the
  runner with the lowest back offer
  """
  def get_sorted(runners) do
    nil
  end
end
