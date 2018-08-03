defmodule BfgEngine.MarketServer do
  @moduledoc """
  A syncronization point for incomming market updates, takes in a market change and break it down to individual
  events and publish them.
  """
  use Agent, restart: :transient
  require Logger
  alias BfgEngine.{Market, Runner, ServerRegistry}

  # Client
  @doc """
  Deconstruct an update into the parts im interested and update state
  """
  def generate_events(pid, market) do
    handled_fields = ~w(marketDefinition rc img)a

    market
    |> Map.take(handled_fields)
    |> Enum.each(&handle_update(pid, market.id, &1))
  end

  @doc """
  finds the favorite in the market by looking for the runner with the lowest back offer
  The horse with the shortest back odds, 2nd Favourite = 2nd shortest etc
  When two have the same odds they are called Joint Favourites
  Sort by the current back price. BetAngel has an icon to do this, the "123" button at the top of the ladder page.
  """
  def get_favorite(pid) do
    Agent.get(pid, fn {_name, market} ->
      market
      |> get_in([Access.key(:runners), Access.key(:runner)])
      |> Enum.map(fn {selection_id, runner} ->
        {selection_id,
         get_in(runner, [Access.key(:ladder), Access.key(:batb), Access.at(0), Access.at(1)])}
      end)
      |> Enum.sort_by(fn {selection_id, shortest_back_odds} -> shortest_back_odds end)
      |> List.first()
      |> elem(0)
    end)
  end

  @doc """
  Deconstructs marketDefinition wich is always sent whole, therefore i need to check agent state before
  generating events
  """
  defp handle_update(pid, market_id, {:marketDefinition, data}) do
    handled_fields = ~w(inPlay marketTime status runners)a

    data
    |> Map.take(handled_fields)
    |> Enum.each(&handle_update(pid, market_id, &1))
  end

  @doc """
  inPlay is part of marketDefinition wich is sent whole, first check the agent state and if it is different update the state
  and generate event
  """
  defp handle_update(pid, market_id, {:inPlay, data} = msg) do
    case Agent.get(pid, fn {_name, market} -> market.inPlay end) do
      # do nothing since nothing has changed
      ^data ->
        nil

      # Update state and send event
      _ ->
        Agent.cast(pid, fn {name, market} ->
          new_market = Market.update_in_play(market, data)
          {name, new_market}
        end)

        Hub.publish(market_id, msg)
    end
  end

  defp handle_update(pid, market_id, {:status, data} = msg) do
    case Agent.get(pid, fn {_name, market} -> market.status end) do
      # do nothing since nothing has changed
      ^data ->
        nil

      # Update state and send event
      _ ->
        Agent.cast(pid, fn {name, market} ->
          new_market = Market.update_status(market, data)
          {name, new_market}
        end)

        Hub.publish(market_id, msg)
    end
  end

  @doc """
  marketTime is part of marketDefinition wich is sent whole, first check the agent state and if if different update the state
  and generate event
  """
  defp handle_update(pid, market_id, {:marketTime, data}) do
    case Agent.get(pid, fn {_name, market} -> market.start_time end) do
      # do nothing since nothing has changed
      ^data ->
        nil

      _ ->
        Agent.cast(pid, fn {name, market} ->
          new_market = Market.update_start_time(market, data)
          {name, new_market}
        end)

        {:ok, date} = Timex.parse(data, "{ISO:Extended}")
        Hub.publish(market_id, {:marketTime, date})
    end
  end

  @doc """
  Deconstruct runners from marketDefinition so we first need to check agent state
  """
  defp handle_update(pid, market_id, {:runners, data}) when is_list(data) do
    # Break down each runner into events im interested in
    handle_runner = fn r ->
      handled_fields = ~w(status)a

      r
      |> Map.take(handled_fields)
      |> Enum.map(fn {_k, v} -> {:runner_status, r.id, v} end)
    end

    # Generate events for all runners
    data
    |> Enum.flat_map(handle_runner)
    |> Enum.each(&handle_update(pid, market_id, &1))
  end

  @doc """
  runner_status is part of marketDefinition.runners wich is sent whole, first check the agent state and if if different update the state
  and generate event
  """
  defp handle_update(pid, market_id, {:runner_status, selection_id, data} = msg) do
    case Agent.get(pid, fn {_name, market} ->
           get_in(market, [
             Access.key(:runners),
             Access.key(:runner),
             selection_id,
             Access.key(:status)
           ])
         end) do
      # do nothing since nothing has changed
      ^data ->
        nil

      _ ->
        Agent.cast(pid, fn {name, market} ->
          new_market = Market.update_runner_status(market, selection_id, data)
          {name, new_market}
        end)

        Hub.publish(market_id, msg)
    end
  end

  @doc """
  Deconstruct an update into the parts im interested and update state
  """
  defp handle_update(pid, market_id, {:rc, data}) when is_list(data) do
    # Break down each runner into events im interested in
    handle_runner = fn r ->
      handled_fields = ~w(batb batl ltp)a

      r
      |> Map.take(handled_fields)
      |> Enum.map(fn {k, v} -> {k, r.id, v} end)
    end

    # Generate events for all runners
    data
    |> Enum.flat_map(handle_runner)
    |> Enum.each(&handle_update(pid, market_id, &1))
  end

  @doc """
  Update state
  """
  defp handle_update(pid, market_id, {:batb, selection_id, data}) do
    # make sure the delta list is sorted the same as in ladder for comparing
    data = Enum.sort_by(data, fn [idx | _] -> idx end)

    current_batb =
      Agent.get(pid, fn {_name, market} ->
        get_in(market, [
          Access.key(:runners),
          Access.key(:runner),
          selection_id,
          Access.key(:ladder),
          Access.key(:batb)
        ])
      end)

    case current_batb do
      # do nothing since nothing has changed
      ^data ->
        nil

      _ ->
        Agent.cast(pid, fn {name, market} ->
          new_market = Market.update_runner_batb(market, selection_id, data)
          # publish from the agent since we want to publish the new batb and not the delta message
          # the batb is always pushed as whole when updated
          Hub.publish(
            market_id,
            {:batb, selection_id,
             get_in(new_market, [
               Access.key(:runners),
               Access.key(:runner),
               selection_id,
               Access.key(:ladder),
               Access.key(:batb)
             ])}
          )

          {name, new_market}
        end)
    end
  end

  @doc """
  Update state
  """
  defp handle_update(pid, market_id, {:batl, selection_id, data}) do
    # make sure the delta list is sorted the same as in ladder for comparing
    data = Enum.sort_by(data, fn [idx | _] -> idx end)

    current_batl =
      Agent.get(pid, fn {_name, market} ->
        get_in(market, [
          Access.key(:runners),
          Access.key(:runner),
          selection_id,
          Access.key(:ladder),
          Access.key(:batl)
        ])
      end)

    case current_batl do
      # do nothing since nothing has changed
      ^data ->
        nil

      _ ->
        Agent.cast(pid, fn {name, market} ->
          new_market = Market.update_runner_batl(market, selection_id, data)
          # publish from the agent since we want to publish the new batb and not the delta message
          # the batb is always pushed as whole when updated
          Hub.publish(
            market_id,
            {:batl, selection_id,
             get_in(new_market, [
               Access.key(:runners),
               Access.key(:runner),
               selection_id,
               Access.key(:ladder),
               Access.key(:batl)
             ])}
          )

          {name, new_market}
        end)
    end
  end

  @doc """
  Update state
  """
  defp handle_update(pid, market_id, {:ltp, selection_id, data} = msg) do
    case Agent.get(pid, fn {_name, market} ->
           get_in(market, [
             Access.key(:runners),
             Access.key(:runner),
             selection_id,
             Access.key(:ltp)
           ])
         end) do
      # do nothing since nothing has changed
      ^data ->
        nil

      _ ->
        Agent.cast(pid, fn {name, market} ->
          new_market = Market.update_runner_ltp(market, selection_id, data)
          {name, new_market}
        end)

        Hub.publish(market_id, msg)
    end
  end

  @doc """
  Catch all
  """
  defp handle_update(_pid, _market_id, data) do
    Logger.warn("Field is not handle in market update #{inspect(data)}")
  end

  @doc """
  Async update of market
  """
  def init_market(pid, market) do
    Agent.cast(pid, fn {name, old_market} ->
      runners =
        market.runners
        |> Enum.map(fn runner -> {runner.selectionId, Runner.new(runner.runnerName)} end)

      {name, Market.set_meta_info(old_market, market.marketName, runners)}
    end)
  end

  # Server
  def start_link(market_id, market \\ Market.new()) do
    Agent.start_link(
      fn ->
        Logger.info(fn -> "Starting market server for #{market_id}" end)
        {market_id, market}
      end,
      name: via_tuple(market_id)
    )
  end

  defp via_tuple(market_id) do
    {__MODULE__, market_id}
    |> ServerRegistry.via_tuple()
  end
end
