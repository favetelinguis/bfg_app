defmodule BfgEngine.Subscriber do

require Logger
require Hub
use GenServer

def start_link(_) do
  GenServer.start_link(__MODULE__, nil, name: __MODULE__)
end

def subscribe_on(market_id) do
  GenServer.cast(__MODULE__, {:subscribe, market_id})
end

def handle_cast({:subscribe, market_id}, state) do
  sub = Hub.subscribe(market_id, _)
  Logger.debug("Setup test probe")
  {:noreply, state}
end

def init(_args) do
  Logger.debug("Started subscriber")
  {:ok, nil}
end

def handle_info(msg, state) do
  Logger.debug("In subscriber tester and got message #{inspect msg}")
  {:noreply, state}
end
end
