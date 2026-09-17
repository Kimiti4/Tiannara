defmodule TiannaraRuntime.WorldStateManager do
  @moduledoc """
  PHASE 5A: World State Manager - Maintains isolated state for each world.
  
  Stores:
  - CAL state (coalition graph, arbitration weights)
  - CIS state (thresholds, intervention history)
  - System metrics (entropy, coherence, stability)
  - Configuration parameters
  
  This module ensures NO STATE LEAKAGE between worlds.
  Each world has its own independent state tree.
  """
  
  use GenServer
  require Logger
  
  # State
  defstruct [
    world_id: nil,
    cal_state: %{},
    cis_state: %{},
    system_metrics: %{},
    config: %{}
  ]
  
  # ============================================================================
  # Public API
  # ============================================================================
  
  def start_link(world_config) do
    GenServer.start_link(__MODULE__, world_config)
  end
  
  @doc """
  Get complete world state.
  """
  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end
  
  @doc """
  Update CAL state.
  """
  def update_cal_state(pid, cal_updates) do
    GenServer.cast(pid, {:update_cal_state, cal_updates})
  end
  
  @doc """
  Update CIS state.
  """
  def update_cis_state(pid, cis_updates) do
    GenServer.cast(pid, {:update_cis_state, cis_updates})
  end
  
  @doc """
  Update system metrics.
  """
  def update_metrics(pid, metrics) do
    GenServer.cast(pid, {:update_metrics, metrics})
  end
  
  @doc """
  Get specific metric value.
  """
  def get_metric(pid, metric_name) do
    GenServer.call(pid, {:get_metric, metric_name})
  end
  
  # ============================================================================
  # GenServer Callbacks
  # ============================================================================
  
  @impl true
  def init(world_config) do
    world_id = world_config.id
    
    initial_state = %__MODULE__{
      world_id: world_id,
      cal_state: initialize_cal_state(),
      cis_state: initialize_cis_state(),
      system_metrics: initialize_metrics(),
      config: Map.get(world_config, :config, %{})
    }
    
    Logger.info("🗃️  WorldStateManager initialized for #{world_id}")
    
    {:ok, initial_state}
  end
  
  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, {:ok, state}, state}
  end
  
  @impl true
  def handle_call({:get_metric, metric_name}, _from, state) do
    value = Map.get(state.system_metrics, metric_name)
    {:reply, {:ok, value}, state}
  end
  
  @impl true
  def handle_cast({:update_cal_state, updates}, state) do
    new_cal_state = Map.merge(state.cal_state, updates)
    {:noreply, %{state | cal_state: new_cal_state}}
  end
  
  @impl true
  def handle_cast({:update_cis_state, updates}, state) do
    new_cis_state = Map.merge(state.cis_state, updates)
    {:noreply, %{state | cis_state: new_cis_state}}
  end
  
  @impl true
  def handle_cast({:update_metrics, metrics}, state) do
    new_metrics = Map.merge(state.system_metrics, metrics)
    {:noreply, %{state | system_metrics: new_metrics}}
  end
  
  # ============================================================================
  # Private Helpers
  # ============================================================================
  
  defp initialize_cal_state() do
    %{
      coalitions: [],
      arbitration_weights: %{},
      decision_history: []
    }
  end
  
  defp initialize_cis_state() do
    %{
      thresholds: %{
        entropy_max: 0.8,
        coherence_min: 0.3,
        stability_threshold: 0.5
      },
      interventions: [],
      adjustment_history: []
    }
  end
  
  defp initialize_metrics() do
    %{
      entropy: 0.5,
      coherence: 0.5,
      stability_score: 0.5,
      intervention_density: 0.0,
      tick_count: 0
    }
  end
end
