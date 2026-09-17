defmodule TiannaraRuntime.Legacy.Tiannara.MSCL.Supervisor do
  @moduledoc """
  Phase 5F.5 — MSCL Root Supervisor
  
  Central stability orchestrator that monitors global pressure,
  prevents divergence overload, and triggers evacuation protocols.
  
  This is the root of the Meta-Stability Constraint Layer hierarchy.
  """
  
  use GenServer
  require Logger

  # Default initial thresholds (can be updated dynamically by AdaptiveController)
  @default_max_global_pressure 10_000.0
  @default_critical_collapse_risk 0.85
  @default_warning_collapse_risk 0.70

  def start_link(init_arg \\ []) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  Get current global pressure state.
  """
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  @doc """
  Report pressure from a specific node.
  """
  def report_pressure(node_id, pressure) do
    GenServer.cast(__MODULE__, {:report_pressure, node_id, pressure})
  end

  @doc """
  Register a new active node.
  """
  def register_node(node_id, initial_load \\ 0.0) do
    GenServer.cast(__MODULE__, {:register_node, node_id, initial_load})
  end

  @doc """
  Unregister a node.
  """
  def unregister_node(node_id) do
    GenServer.cast(__MODULE__, {:unregister_node, node_id})
  end

  @doc """
  Dynamically update stability thresholds (called by AdaptiveController).
  """
  def update_thresholds(max_pressure, critical_risk, warning_risk) do
    GenServer.cast(__MODULE__, {:update_thresholds, max_pressure, critical_risk, warning_risk})
  end

  # ── Callbacks ─────────────────────────────────────────────────────────────

  @impl true
  def init(_init_arg) do
    state = %{
      global_pressure: 0.0,
      active_nodes: %{},
      collapse_risk: 0.0,
      pressure_history: [],
      last_evacuation: nil,
      max_global_pressure: @default_max_global_pressure,
      critical_collapse_risk: @default_critical_collapse_risk,
      warning_collapse_risk: @default_warning_collapse_risk
    }

    Logger.info("🛡️ MSCL Supervisor initialized")
    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_cast({:report_pressure, node_id, pressure}, state) do
    updated_nodes = Map.put(state.active_nodes, node_id, pressure)
    
    new_global_pressure =
      updated_nodes
      |> Map.values()
      |> Enum.sum()
      |> clamp_pressure(state.max_global_pressure)

    collapse_risk = new_global_pressure / state.max_global_pressure
    
    updated_state = %{
      state
      | global_pressure: new_global_pressure,
        active_nodes: updated_nodes,
        collapse_risk: collapse_risk,
        pressure_history: update_pressure_history(state.pressure_history, new_global_pressure)
    }

    evaluate_stability(updated_state)

    {:noreply, updated_state}
  end

  @impl true
  def handle_cast({:register_node, node_id, initial_load}, state) do
    updated_nodes = Map.put(state.active_nodes, node_id, initial_load)
    Logger.info("📊 MSCL: Node #{node_id} registered with load #{initial_load}")
    {:noreply, %{state | active_nodes: updated_nodes}}
  end

  @impl true
  def handle_cast({:unregister_node, node_id}, state) do
    updated_nodes = Map.delete(state.active_nodes, node_id)
    
    new_global_pressure =
      updated_nodes
      |> Map.values()
      |> Enum.sum()
      |> clamp_pressure(state.max_global_pressure)

    collapse_risk = new_global_pressure / state.max_global_pressure

    Logger.info("📊 MSCL: Node #{node_id} unregistered")
    
    {:noreply, %{state | active_nodes: updated_nodes, global_pressure: new_global_pressure, collapse_risk: collapse_risk}}
  end

  @impl true
  def handle_cast(:reset, state) do
    {:noreply, %{state | global_pressure: 0.0, active_nodes: %{}, collapse_risk: 0.0, pressure_history: [], last_evacuation: nil}}
  end

  @impl true
  def handle_cast({:update_thresholds, max_p, crit_r, warn_r}, state) do
    Logger.info("🧠 MSCL Supervisor updating thresholds: MaxPressure=#{max_p}, Critical=#{crit_r}, Warning=#{warn_r}")
    
    # Recalculate collapse_risk based on new max_pressure
    new_risk = if max_p > 0, do: state.global_pressure / max_p, else: 1.0
    
    updated_state = %{state | 
      max_global_pressure: max_p, 
      critical_collapse_risk: crit_r, 
      warning_collapse_risk: warn_r,
      collapse_risk: new_risk
    }
    
    evaluate_stability(updated_state)
    {:noreply, updated_state}
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp clamp_pressure(p, max_p) when p > max_p, do: max_p
  defp clamp_pressure(p, _max_p) when p < 0.0, do: 0.0
  defp clamp_pressure(p, _max_p), do: p

  defp evaluate_stability(state) do
    cond do
      state.collapse_risk > state.critical_collapse_risk ->
        Logger.warning("⚠️ MSCL: CRITICAL collapse risk #{Float.round(state.collapse_risk * 100, 2)}%")
        trigger_evacuation(state.global_pressure)
        
      state.collapse_risk > state.warning_collapse_risk ->
        Logger.warning("⚠️ MSCL: HIGH collapse risk #{Float.round(state.collapse_risk * 100, 2)}%")
        notify_warning(state.global_pressure)
        
      true ->
        :ok
    end
  end

  defp trigger_evacuation(pressure) do
    Logger.warning("🚨 MSCL: Triggering emergency evacuation at pressure #{pressure}")
    
    if Process.whereis(Tiannara.OLEF.FieldSupervisor) do
      GenServer.cast(Tiannara.OLEF.FieldSupervisor, {:evacuate_pressure, pressure})
    else
      Logger.error("❌ MSCL: OLEF FieldSupervisor not available for evacuation")
    end

    GenServer.cast(__MODULE__, {:record_evacuation, System.system_time()})
  end

  defp notify_warning(pressure) do
    Logger.warning("⚠️ MSCL: Warning threshold exceeded at pressure #{pressure}")
    
    if Process.whereis(Tiannara.OLEF.FieldSupervisor) do
      GenServer.cast(Tiannara.OLEF.FieldSupervisor, {:prepare_evacuation, pressure})
    end
  end

  defp update_pressure_history(history, current_pressure) do
    updated = [{System.system_time(), current_pressure} | history]
    Enum.take(updated, 100)
  end

  @impl true
  def handle_cast({:record_evacuation, timestamp}, state) do
    {:noreply, %{state | last_evacuation: timestamp}}
  end
end
