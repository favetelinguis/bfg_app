defmodule BfgEngine.Market do
  require Logger
  alias __MODULE__
  alias BfgEngine.{Runners, Ladder, Runner, Ladder}

  defstruct [:name, :status, :inPlay, :start_time, :runners]

  def new() do
    %Market{}
  end

  def set_meta_info(_market, name, runners) when is_list(runners) do
    new_runners = Enum.reduce(runners, Runners.new(), fn({selection_id, runner}, acc) -> Runners.add_runner(acc, selection_id, runner)  end)
    %Market{name: name, runners: new_runners}
  end

  def update_in_play(market, value), do: %Market{market | inPlay: value}
  def update_status(market, value), do: %Market{market | status: value}
  def update_start_time(market, value), do: %Market{market | start_time: value}
  def update_runner_status(market, runner_id, data), do: update_in(market, [Access.key(:runners), Access.key(:runner), runner_id], &Runner.update_status(&1, data))
  def update_runner_batb(market, runner_id, data), do: update_in(market, [Access.key(:runners), Access.key(:runner), runner_id, Access.key(:ladder)], &Ladder.update_batb(&1, data))
  def update_runner_batl(market, runner_id, data), do: update_in(market, [Access.key(:runners), Access.key(:runner), runner_id, Access.key(:ladder)], &Ladder.update_batl(&1, data))
  def update_runner_ltp(market, runner_id, data), do: update_in(market, [Access.key(:runners), Access.key(:runner), runner_id], &Runner.update_ltp(&1, data))
end
