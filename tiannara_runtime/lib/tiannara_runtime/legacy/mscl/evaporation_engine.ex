defmodule TiannaraRuntime.Legacy.Tiannara.MSCL.EvaporationEngine do
  @moduledoc """
  Phase 5F.5 — MSCL Ontological Evaporation Engine
  
  Implements Hawking radiation-style evaporation for excessive
  ontological energy. When systems accumulate too much paradoxical
  or unstable content, this engine gradually evaporates it.
  
  ## Evaporation Mechanisms
  
  - **Memory Evaporation**: Dissolves unstable chronogram entries
  - **Observer Evaporation**: Merges or terminates overloaded observers
  - **Paradox Evaporation**: Resolves contradictory states through decoherence
  """
  
  use GenServer
  require Logger

  @evaporation_rate 0.05
  @critical_paradox_density 0.85
  @evaporation_interval_ms 10_000

  def start_link(init_arg \\ []) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  Trigger immediate evaporation for a specific observer.
  """
  def trigger_evaporation(observer_id, reason) do
    GenServer.cast(__MODULE__, {:trigger_evaporation, observer_id, reason})
  end

  @doc """
  Get evaporation statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  # ── Callbacks ─────────────────────────────────────────────────────────────

  @impl true
  def init(_init_arg) do
    state = %{
      total_evaporated: 0,
      evaporation_events: [],
      active_processes: [],
      monitoring_timer: nil
    }

    Logger.info("♨️ MSCL EvaporationEngine initialized")
    
    timer = Process.send_after(self(), :periodic_evaporation_check, @evaporation_interval_ms)
    
    {:ok, %{state | monitoring_timer: timer}}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_cast({:trigger_evaporation, observer_id, reason}, state) do
    Logger.warning("♨️ MSCL: Triggering evaporation for #{observer_id} (reason: #{reason})")
    
    evaporation_result = perform_evaporation(observer_id, reason)
    
    updated_events = [%{
      observer_id: observer_id,
      reason: reason,
      timestamp: System.system_time(),
      result: evaporation_result
    } | state.evaporation_events]
    
    updated_state = %{
      state
      | total_evaporated: state.total_evaporated + 1,
        evaporation_events: Enum.take(updated_events, 100)
    }
    
    {:noreply, updated_state}
  end

  @impl true
  def handle_cast(:reset, state) do
    {:noreply, %{state | total_evaporated: 0, evaporation_events: [], active_processes: []}}
  end

  @impl true
  def handle_info(:periodic_evaporation_check, state) do
    Logger.debug("♨️ MSCL: Running periodic evaporation check")
    
    Process.send_after(self(), :periodic_evaporation_check, @evaporation_interval_ms)
    
    {:noreply, state}
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp perform_evaporation(observer_id, reason) do
    Logger.info("♨️ MSCL: Evaporating ontological energy from #{observer_id}")
    
    actions_taken = case reason do
      :paradox_overload ->
        [
          {:dissolve_unstable_memories, @evaporation_rate},
          {:reduce_observer_complexity, 0.3},
          {:emit_hawking_radiation, true}
        ]
      
      :divergence_overflow ->
        [
          {:merge_with_nearest_observer, true},
          {:compress_chronogram, 0.4},
          {:reset_causal_chain, partial: true}
        ]
      
      :budget_exhaustion ->
        [
          {:terminate_low_priority_processes, 0.5},
          {:release_memory_allocation, 0.6},
          {:throttle_computation, 0.7}
        ]
      
      _ ->
        [
          {:generic_evaporation, @evaporation_rate}
        ]
    end
    
    %{
      observer_id: observer_id,
      actions_taken: actions_taken,
      estimated_energy_released: calculate_energy_release(actions_taken),
      success: true
    }
  end

  defp calculate_energy_release(actions) do
    base_energy = length(actions) * 10.0
    adjustment_factor = 1.2
    base_energy * adjustment_factor
  end
end
