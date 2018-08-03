defmodule BfgEngine.OrderServer do
  @moduledoc """
  Responisble for having an order cache for all orders on the market to understand how to green up a market
  Generate trade events that others can subscribe on saying what has changed in each update
  """
  use GenServer, restart: :transient
  require Logger
  require Hub
  alias BfgEngine.{Market, Runner, ServerRegistry, MarketServer, MarketCache}

  @init_state %{market_id: nil, orders: %{}}

  # Client
  @doc """
  Deconstruct an update into the parts im interested and update state
  """
  def generate_events(pid, market) do
    Logger.debug(fn -> "In order generate events" end)
    GenServer.cast(pid, {:generate_events, market})
  end

  def get_order(pid, bet_id) do
    GenServer.call(pid, {:get_order, bet_id})
  end

  def handle_call({:get_order, bet_id}, _from, state) do
    order = get_in(state, [:orders, bet_id])
    {:reply, order, state}
  end

  @doc """
  The last order update a market get is a closed message and it
  is handled here
  """
  def handle_cast({:generate_events, %{closed: true}}, state) do
    {:noreply, state}
  end

  @doc """
  Order Changes - a list of changes to orders on a runner
  For each runner go over all Unmatched orders and update them i cache
  """
  def handle_cast({:generate_events, %{orc: orc}}, state) do
    orders =
      orc
      # handle update must return now orders map
      |> Enum.reduce(state, &handle_runner/2)

    {:noreply, %{state | orders: orders}}
  end

  @doc """
  Return a new orders object
  For a runner go over all unmatched orders
  Return the updated orders
  """
  def handle_runner(%{id: selection_id, uo: uo}, %{market_id: _market_id, orders: _orders} = acc) do
    uo
    |> Enum.reduce(Map.put(acc, :selection_id, selection_id), &handle_unmatched_order/2)
  end

  defp handle_unmatched_order(
         %{id: bet_id, rfs: rfs, sr: sr, sm: sm, sl: sl, sc: sc, sv: sv} = new_order,
         %{market_id: market_id, orders: orders, selection_id: selection_id}
       ) do
    update_in(orders, [bet_id], fn _order ->
      data = %{
        rfs: rfs, 
        size_remaining: sr, 
        size_matched: sm,
        size_lapsed: sl,
        size_cancelled: sc,
        size_voided: sv 
      }
      Hub.publish(market_id, {:trade, selection_id, bet_id, data})
      new_order
    end)
  end

  # Server
  def start_link(market_id) do
    Logger.info(fn -> "Starting order server for #{market_id}" end)
    GenServer.start_link(__MODULE__, market_id, name: via_tuple(market_id))
  end

  defp via_tuple(market_id) do
    {__MODULE__, market_id}
    |> ServerRegistry.via_tuple()
  end

  @impl true
  def init(market_id) do
    {:ok, %{@init_state | market_id: market_id}}
  end
end
