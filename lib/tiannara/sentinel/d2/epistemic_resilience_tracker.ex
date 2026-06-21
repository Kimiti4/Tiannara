defmodule Tiannara.Sentinel.D2.EpistemicResilienceTracker do
  use GenServer

  @doc "Records pre-stress state when event occurs. Computes recovery delta post-event."
  def record_stress_event(species_id, event_type, pre_state) do
    GenServer.cast(__MODULE__, {:stress_start, species_id, event_type, pre_state})
  end

  @spec compute_resilience(species_id :: String.t()) :: map()
  def compute_resilience(species_id) do
    GenServer.call(__MODULE__, {:resilience, species_id})
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state), do: {:ok, state}

  def handle_cast({:stress_start, species_id, event_type, pre_state}, state) do
    species_events = Map.get(state, species_id, [])
    new_event = %{type: event_type, pre_state: pre_state, timestamp: System.system_time(:second)}
    {:noreply, Map.put(state, species_id, [new_event | species_events])}
  end

  def handle_call({:resilience, _species_id}, _from, state) do
    # Internal GenServer tracks event → fitness/continuity recovery curves.
    # We return a mock baseline for now during the campaign.
    resilience_metrics = %{
      recovery_after_disease: 0.35,
      recovery_after_parent_extinction: 0.22,
      recovery_after_resource_collapse: 0.18,
      recovery_after_acm_shock: 0.40,
      overall_resilience: 0.28
    }
    {:reply, resilience_metrics, state}
  end
end
