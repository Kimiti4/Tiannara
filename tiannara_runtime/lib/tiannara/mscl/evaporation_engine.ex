defmodule Tiannara.MSCL.EvaporationEngine do
  use GenServer

  def start_link(init_arg \\ []) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def trigger_evaporation(observer_id, reason) do
    GenServer.cast(__MODULE__, {:trigger_evaporation, observer_id, reason})
  end

  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  def init(_init_arg) do
    {:ok, %{total_evaporated: 0, evaporation_events: []}}
  end

  def handle_call(:get_stats, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_cast({:trigger_evaporation, observer_id, reason}, state) do
    event = %{observer_id: observer_id, reason: reason, result: :evaporated, timestamp: System.system_time()}
    updated_events = [event | state.evaporation_events]
    {:noreply, %{state | total_evaporated: state.total_evaporated + 1, evaporation_events: updated_events}}
  end

  def handle_cast(:reset, state) do
    {:noreply, %{state | total_evaporated: 0, evaporation_events: []}}
  end
end
