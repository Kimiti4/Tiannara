defmodule TiannaraRuntime.Evolution.Supervisor do
  @moduledoc """
  PHASE 5B: Evolutionary Selection Supervisor
  
  Orchestrates the complete evolutionary feedback loop:
  
    World execution → Metrics collection → Fitness evaluation → 
    Selection pressure → Fork/survive/die → New world population
  
  Runs periodic selection cycles to apply evolutionary pressure across all worlds.
  
  Configuration:
    - selection_interval_ms: Time between selection cycles (default: 10000ms = 10s)
    - min_worlds: Minimum worlds to maintain (prevents total extinction)
    - max_worlds: Maximum worlds allowed (prevents resource exhaustion)
  """
  
  use GenServer
  require Logger
  
  alias TiannaraRuntime.Evolution.{
    FitnessEngine,
    SelectionOrchestrator,
    WorldPruningSystem,
    SurvivalPressureModel
  }
  
  # Default configuration
  @default_selection_interval 10_000  # 10 seconds
  @min_worlds 2
  @max_worlds 10
  
  # State
  defstruct [
    selection_interval: @default_selection_interval,
    min_worlds: @min_worlds,
    max_worlds: @max_worlds,
    cycle_count: 0,
    running: false
  ]
  
  # ============================================================================
  # Public API
  # ============================================================================
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Start the evolutionary selection loop.
  """
  def start_selection(pid) do
    GenServer.cast(pid, :start_selection)
  end
  
  @doc """
  Stop the selection loop.
  """
  def stop_selection(pid) do
    GenServer.cast(pid, :stop_selection)
  end
  
  @doc """
  Run a single manual selection cycle.
  """
  def run_cycle(pid) do
    GenServer.call(pid, :run_cycle)
  end
  
  @doc """
  Get current selection statistics.
  """
  def get_stats(pid) do
    GenServer.call(pid, :get_stats)
  end
  
  # ============================================================================
  # GenServer Callbacks
  # ============================================================================
  
  @impl true
  def init(opts) do
    interval = Keyword.get(opts, :selection_interval, @default_selection_interval)
    min_w = Keyword.get(opts, :min_worlds, @min_worlds)
    max_w = Keyword.get(opts, :max_worlds, @max_worlds)
    
    Logger.info("🧬 Evolution.Supervisor initialized (interval: #{interval}ms)")
    
    state = %__MODULE__{
      selection_interval: interval,
      min_worlds: min_w,
      max_worlds: max_w,
      cycle_count: 0,
      running: false
    }
    
    {:ok, state}
  end
  
  @impl true
  def handle_cast(:start_selection, state) do
    if state.running do
      Logger.warning("⚠️  Selection loop already running")
      {:noreply, state}
    else
      Logger.info("▶️  Starting evolutionary selection loop")
      schedule_cycle()
      {:noreply, %{state | running: true}}
    end
  end
  
  @impl true
  def handle_cast(:stop_selection, state) do
    Logger.info("⏸️  Stopping evolutionary selection loop")
    {:noreply, %{state | running: false}}
  end
  
  @impl true
  def handle_call(:run_cycle, _from, state) do
    result = execute_selection_cycle(state)
    {:reply, result, state}
  end
  
  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      cycle_count: state.cycle_count,
      running: state.running,
      selection_interval: state.selection_interval,
      min_worlds: state.min_worlds,
      max_worlds: state.max_worlds
    }
    
    {:reply, {:ok, stats}, state}
  end
  
  @impl true
  def handle_info(:selection_cycle, state) do
    if state.running do
      execute_selection_cycle(state)
      schedule_cycle()
      {:noreply, %{state | cycle_count: state.cycle_count + 1}}
    else
      {:noreply, state}
    end
  end
  
  # ============================================================================
  # Private Functions
  # ============================================================================
  
  defp schedule_cycle() do
    Process.send_after(self(), :selection_cycle, @default_selection_interval)
  end
  
  defp execute_selection_cycle(state) do
    Logger.info("🔄 Running selection cycle ##{state.cycle_count + 1}")
    
    try do
      # Step 1: Get all active worlds
      {:ok, worlds} = TiannaraRuntime.WorldRegistry.list_worlds()
      
      if length(worlds) == 0 do
        Logger.warning("⚠️  No active worlds for selection")
        {:ok, %{survivors: [], unstable: [], extinction_risk: []}}
      else
        # Step 2: Enforce world count limits
        worlds = enforce_world_limits(worlds, state)
        
        # Step 3: Collect metrics for each world
        worlds_with_metrics = Enum.map(worlds, fn world ->
          metrics = collect_world_metrics(world.id)
          %{world | metrics: metrics}
        end)
        
        # Step 4: Run selection orchestrator
        classification = SelectionOrchestrator.run(worlds_with_metrics)
        
        # Step 5: Apply adaptive responses
        apply_adaptive_responses(classification)
        
        # Step 6: Publish selection events
        SelectionOrchestrator.publish_selection_events(classification)
        
        # Log results
        log_selection_results(classification)
        
        {:ok, classification}
      end
      
    rescue
      e ->
        Logger.error("❌ Selection cycle failed: #{inspect(e)}")
        {:error, e}
    end
  end
  
  defp enforce_world_limits(worlds, state) do
    active_count = length(worlds)
    
    if active_count > state.max_worlds do
      Logger.warning("⚠️  World count (#{active_count}) exceeds maximum (#{state.max_worlds})")
      sorted = Enum.sort_by(worlds, & &1.fitness)
      count_to_remove = active_count - state.max_worlds
      {sacrifice, survivors} = Enum.split(sorted, count_to_remove)
      Enum.each(sacrifice, fn world ->
        WorldPruningSystem.terminate_world(world.id)
      end)
      survivors
    else
      worlds
    end
  end
  
  defp collect_world_metrics(world_id) do
    case try_world_state_metrics(world_id) do
      {:ok, metrics} ->
        metrics
      :error ->
        case TiannaraRuntime.WorldRegistry.get_world(world_id) do
          {:ok, world} -> compute_metrics_from_world(world)
          _ -> default_metrics()
        end
    end
  end
  
  defp apply_adaptive_responses(classification) do
    # Process extinction risk worlds
    Enum.each(classification.extinction_risk, fn item ->
      case WorldPruningSystem.evaluate(item) do
        :terminate ->
          WorldPruningSystem.terminate_world(item.world.id)
        
        {:warning, updated_data} ->
          # Track countdown but don't terminate yet
          Logger.debug("📊 World #{item.world.id} in warning zone")
        
        :safe ->
          :ok
      end
    end)
    
    # Process unstable worlds for potential forking
    Enum.each(classification.unstable, fn item ->
      case SelectionOrchestrator.adaptive_response(item) do
        :fork ->
          trigger_adaptive_fork(item.world.id)
        
        :continue ->
          :ok
        
        :terminate ->
          WorldPruningSystem.terminate_world(item.world.id)
      end
    end)
  end
  
  defp trigger_adaptive_fork(parent_world_id) do
    Logger.info("🍴 Triggering adaptive fork for world #{parent_world_id}")
    
    mutation = %{
      fork_type: :adaptive_exploration,
      mutation_rate: 0.05,
      timestamp: System.system_time(:second)
    }
    
    case TiannaraRuntime.WorldForkEngine.fork(parent_world_id, mutation) do
      {:ok, child_id} ->
        Logger.info("✅ Adaptive fork successful: #{parent_world_id} → #{child_id}")
      
      {:error, reason} ->
        Logger.error("❌ Adaptive fork failed: #{inspect(reason)}")
    end
  end
  
  defp log_selection_results(classification) do
    survivor_count = length(classification.survivors)
    unstable_count = length(classification.unstable)
    extinction_count = length(classification.extinction_risk)
    
    Logger.info("📊 Selection Results:")
    Logger.info("   Survivors: #{survivor_count}")
    Logger.info("   Unstable: #{unstable_count}")
    Logger.info("   Extinction Risk: #{extinction_count}")
  end
  
  defp try_world_state_metrics(world_id) do
    case Registry.lookup(TiannaraRuntime.WorldRegistry, world_id) do
      [{sup_pid, _}] ->
        children = Supervisor.which_children(sup_pid)
        case Enum.find(children, fn {id, _, _, _} -> id == TiannaraRuntime.WorldStateManager end) do
          {_, pid, _, _} when is_pid(pid) ->
            case TiannaraRuntime.WorldStateManager.get_state(pid) do
              {:ok, wsm_state} -> {:ok, build_metrics_from_wsm(wsm_state)}
              _ -> :error
            end
          _ -> :error
        end
      _ -> :error
    end
  end

  defp build_metrics_from_wsm(wsm_state) do
    sm = Map.get(wsm_state, :system_metrics, %{})
    entropy = Map.get(sm, :entropy, 0.5)
    coherence = Map.get(sm, :coherence, 0.5)
    stability = Map.get(sm, :stability_score, 0.5)
    intervention = Map.get(sm, :intervention_density, 0.0)
    %{
      coherence_stability: clamp_metric(coherence),
      recovery_speed: clamp_metric(stability),
      coalition_success_rate: clamp_metric(coherence * 0.8 + stability * 0.2),
      entropy_instability: clamp_metric(entropy),
      collapse_frequency: clamp_metric(entropy * 0.3),
      entropy_growth_rate: clamp_metric(entropy * 0.1),
      cis_intervention_density: clamp_metric(intervention),
      cal_instability_index: clamp_metric(1.0 - stability),
      entropy: clamp_metric(entropy),
      active_coalitions: max(1, round(coherence * 5)),
      cis_intervention_intensity: clamp_metric(intervention),
      instability_vector: (entropy - 0.5) * 2,
      coalition_positions: []
    }
  end

  defp compute_metrics_from_world(world) do
    now = System.system_time(:second)
    age = max(now - (world.created_at || now), 1)
    time_since_update = max(now - (world.last_updated || now), 0)
    gen_factor = min((world.generation || 0) / 10.0, 1.0)
    age_factor = min(age / 3600.0, 1.0)
    fitness = Map.get(world, :fitness, 0.5)
    %{
      coherence_stability: clamp_metric(fitness * 0.7 + gen_factor * 0.3),
      recovery_speed: clamp_metric(1.0 - min(time_since_update / 300.0, 1.0) * 0.5),
      coalition_success_rate: clamp_metric(fitness * 0.6 + age_factor * 0.4),
      entropy_instability: clamp_metric(1.0 - fitness * 0.5),
      collapse_frequency: clamp_metric((1.0 - fitness) * 0.4),
      entropy_growth_rate: clamp_metric((1.0 - fitness) * 0.3),
      cis_intervention_density: clamp_metric((1.0 - fitness) * 0.2),
      cal_instability_index: clamp_metric(1.0 - fitness),
      entropy: clamp_metric(1.0 - fitness * 0.6),
      active_coalitions: max(1, round(fitness * 5)),
      cis_intervention_intensity: clamp_metric((1.0 - fitness) * 0.3),
      instability_vector: (1.0 - fitness) * 2 - 1,
      coalition_positions: []
    }
  end

  defp default_metrics() do
    %{
      coherence_stability: 0.5,
      recovery_speed: 0.5,
      coalition_success_rate: 0.5,
      entropy_instability: 0.3,
      collapse_frequency: 0.2,
      entropy_growth_rate: 0.2,
      cis_intervention_density: 0.1,
      cal_instability_index: 0.5,
      entropy: 0.4,
      active_coalitions: 1,
      cis_intervention_intensity: 0.2,
      instability_vector: 0.0,
      coalition_positions: []
    }
  end

  defp clamp_metric(v) when is_number(v), do: max(0.0, min(1.0, v))
  defp clamp_metric(_), do: 0.5
end
