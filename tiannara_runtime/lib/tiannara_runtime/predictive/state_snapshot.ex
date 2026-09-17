defmodule TiannaraRuntime.Predictive.StateSnapshot do
  @moduledoc """
  PHASE 4A: State Snapshot Engine
  
  Captures immutable snapshots of CAL + CIS state at each simulation tick.
  
  These snapshots form the foundation for:
  - Forward simulation (predicting future states)
  - Historical replay (temporal navigation)
  - Causal tracing (decision lineage)
  
  Design Principle: Append-only, immutable, traceable
  """
  
  use GenServer
  require Logger
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Capture a snapshot of current system state.
  
  Returns: {:ok, snapshot_id} or {:error, reason}
  """
  def capture_state(state_data, parent_trace_id \\ nil) do
    GenServer.call(__MODULE__, {:capture, state_data, parent_trace_id})
  end
  
  @doc """
  Get snapshot by ID.
  """
  def get_snapshot(snapshot_id) do
    GenServer.call(__MODULE__, {:get, snapshot_id})
  end
  
  @doc """
  Get snapshots within time range.
  """
  def get_snapshots_in_range(start_time, end_time) do
    GenServer.call(__MODULE__, {:range, start_time, end_time})
  end
  
  @doc """
  Get latest N snapshots.
  """
  def get_latest_snapshots(count \\ 10) do
    GenServer.call(__MODULE__, {:latest, count})
  end
  
  @doc """
  Get total snapshot count.
  """
  def get_snapshot_count() do
    GenServer.call(__MODULE__, :count)
  end
  
  # Server Callbacks
  
  @impl true
  def init(_opts) do
    state = %{
      snapshots: %{},           # snapshot_id -> snapshot_data
      timeline: [],             # ordered list of snapshot_ids
      index_by_time: %{},       # timestamp -> [snapshot_ids]
      next_id: 1
    }
    
    Logger.info("✅ StateSnapshot engine initialized")
    {:ok, state}
  end
  
  @impl true
  def handle_call({:capture, state_data, parent_trace_id}, _from, state) do
    # Generate unique snapshot ID
    snapshot_id = "snap_#{state.next_id}"
    trace_id = parent_trace_id || generate_trace_id()
    
    # Build immutable snapshot
    snapshot = %{
      id: snapshot_id,
      trace_id: trace_id,
      timestamp: DateTime.utc_now() |> DateTime.to_unix(:millisecond),
      cal_state: extract_cal_state(state_data),
      cis_state: extract_cis_state(state_data),
      metrics: extract_metrics(state_data),
      created_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }
    
    # Store in append-only timeline
    new_state = %{
      state |
      snapshots: Map.put(state.snapshots, snapshot_id, snapshot),
      timeline: state.timeline ++ [snapshot_id],
      index_by_time: update_time_index(state.index_by_time, snapshot.timestamp, snapshot_id),
      next_id: state.next_id + 1
    }
    
    Logger.debug("📸 Captured snapshot: #{snapshot_id} (trace: #{trace_id})")
    
    {:reply, {:ok, snapshot_id}, new_state}
  end
  
  @impl true
  def handle_call({:get, snapshot_id}, _from, state) do
    case Map.get(state.snapshots, snapshot_id) do
      nil -> {:reply, {:error, :not_found}, state}
      snapshot -> {:reply, {:ok, snapshot}, state}
    end
  end
  
  @impl true
  def handle_call({:range, start_time, end_time}, _from, state) do
    # Find snapshots in time range
    snapshot_ids = Enum.filter(state.timeline, fn id ->
      case Map.get(state.snapshots, id) do
        nil -> false
        snap -> snap.timestamp >= start_time && snap.timestamp <= end_time
      end
    end)
    
    snapshots = Enum.map(snapshot_ids, &Map.get(state.snapshots, &1))
    {:reply, {:ok, snapshots}, state}
  end
  
  @impl true
  def handle_call({:latest, count}, _from, state) do
    latest_ids = Enum.take(Enum.reverse(state.timeline), count)
    snapshots = Enum.map(latest_ids, &Map.get(state.snapshots, &1))
    {:reply, {:ok, snapshots}, state}
  end
  
  @impl true
  def handle_call(:count, _from, state) do
    {:reply, {:ok, length(state.timeline)}, state}
  end
  
  # Private Functions
  
  defp generate_trace_id() do
    "trace_#{:erlang.unique_integer([:positive])}_#{System.monotonic_time(:millisecond)}"
  end
  
  defp extract_cal_state(state_data) do
    # Extract Coalition Activity Layer state
    %{
      coalitions: Map.get(state_data, :coalitions, []),
      active_coalition: Map.get(state_data, :active_coalition),
      arbitration_state: Map.get(state_data, :arbitration, %{}),
      coherence_scores: Map.get(state_data, :coherence_scores, %{})
    }
  end
  
  defp extract_cis_state(state_data) do
    # Extract Cognitive Immune System state
    %{
      entropy_level: Map.get(state_data, :entropy, 0.0),
      interventions: Map.get(state_data, :interventions, []),
      quarantine_zones: Map.get(state_data, :quarantine_zones, []),
      damping_active: Map.get(state_data, :damping_active, false)
    }
  end
  
  defp extract_metrics(state_data) do
    # Extract key performance metrics
    %{
      total_coalitions: length(Map.get(state_data, :coalitions, [])),
      avg_coherence: calculate_avg_coherence(state_data),
      entropy: Map.get(state_data, :entropy, 0.0),
      stability_score: calculate_stability_score(state_data)
    }
  end
  
  defp calculate_avg_coherence(state_data) do
    coalitions = Map.get(state_data, :coalitions, [])
    if Enum.empty?(coalitions) do
      0.0
    else
      coherences = Enum.map(coalitions, &Map.get(&1, :coherence, 0.0))
      Enum.sum(coherences) / length(coherences)
    end
  end
  
  defp calculate_stability_score(state_data) do
    entropy = Map.get(state_data, :entropy, 0.0)
    coherence = calculate_avg_coherence(state_data)
    
    # Stability = high coherence + optimal entropy (0.55-0.75)
    entropy_factor = if entropy >= 0.55 and entropy <= 0.75, do: 1.0, else: 0.5
    coherence * entropy_factor
  end
  
  defp update_time_index(index, timestamp, snapshot_id) do
    # Group snapshots by second for efficient range queries
    second_key = div(timestamp, 1000)
    
    existing = Map.get(index, second_key, [])
    Map.put(index, second_key, existing ++ [snapshot_id])
  end
end
