defmodule TiannaraRuntime.WorldMemoryStore do
  @moduledoc """
  PHASE 5A: World Memory Store - Append-only timeline for each world.
  
  Stores chronological snapshots of world state for:
  - Temporal replay (Phase 4 Timeline Replay)
  - Causal tracing (Phase 4C)
  - Evolutionary history (Phase 5C)
  - Deterministic replay (Phase 5 Safeguard #3)
  
  CRITICAL: Memory is APPEND-ONLY. No retroactive mutations allowed.
  """
  
  use GenServer
  require Logger
  
  # Maximum snapshots to keep in memory (prevent unbounded growth)
  @max_snapshots 10_000
  
  # State
  defstruct [
    world_id: nil,
    snapshots: [],  # List of %{timestamp, state_snapshot}
    snapshot_count: 0
  ]
  
  # ============================================================================
  # Public API
  # ============================================================================
  
  def start_link(world_config) do
    GenServer.start_link(__MODULE__, world_config)
  end
  
  @doc """
  Append a new state snapshot to the timeline.
  """
  def append_snapshot(pid, snapshot_data) do
    GenServer.cast(pid, {:append_snapshot, snapshot_data})
  end
  
  @doc """
  Get snapshots within a time range.
  """
  def get_snapshots_in_range(pid, start_time, end_time) do
    GenServer.call(pid, {:get_snapshots_in_range, start_time, end_time})
  end
  
  @doc """
  Get last N snapshots.
  """
  def get_last_n_snapshots(pid, n) do
    GenServer.call(pid, {:get_last_n_snapshots, n})
  end
  
  @doc """
  Get total snapshot count.
  """
  def get_snapshot_count(pid) do
    GenServer.call(pid, :get_snapshot_count)
  end
  
  # ============================================================================
  # GenServer Callbacks
  # ============================================================================
  
  @impl true
  def init(world_config) do
    world_id = world_config.id
    
    Logger.info("💾 WorldMemoryStore initialized for #{world_id}")
    
    {:ok, %__MODULE__{
      world_id: world_id,
      snapshots: [],
      snapshot_count: 0
    }}
  end
  
  @impl true
  def handle_cast({:append_snapshot, snapshot_data}, state) do
    timestamp = :erlang.unique_integer([:positive])
    
    snapshot = %{
      timestamp: timestamp,
      tick_number: state.snapshot_count,
      data: snapshot_data
    }
    
    # Append to list (newest first for efficient retrieval)
    new_snapshots = [snapshot | state.snapshots]
    
    # Enforce max snapshot limit (drop oldest if exceeded)
    trimmed_snapshots = if length(new_snapshots) > @max_snapshots do
      Enum.take(new_snapshots, @max_snapshots)
    else
      new_snapshots
    end
    
    new_state = %{
      state
      | snapshots: trimmed_snapshots,
        snapshot_count: state.snapshot_count + 1
    }
    
    # Log every 1000 snapshots
    if rem(new_state.snapshot_count, 1000) == 0 do
      Logger.info("💾 World #{state.world_id}: #{new_state.snapshot_count} snapshots stored")
    end
    
    {:noreply, new_state}
  end
  
  @impl true
  def handle_call({:get_snapshots_in_range, start_time, end_time}, _from, state) do
    filtered = Enum.filter(state.snapshots, fn snap ->
      snap.timestamp >= start_time and snap.timestamp <= end_time
    end)
    
    # Sort by timestamp ascending (oldest first)
    sorted = Enum.sort_by(filtered, & &1.timestamp)
    
    {:reply, {:ok, sorted}, state}
  end
  
  @impl true
  def handle_call({:get_last_n_snapshots, n}, _from, state) do
    # Snapshots are stored newest-first, so take first n
    last_n = Enum.take(state.snapshots, n)
    
    # Reverse to return oldest-first
    {:reply, {:ok, Enum.reverse(last_n)}, state}
  end
  
  @impl true
  def handle_call(:get_snapshot_count, _from, state) do
    {:reply, {:ok, state.snapshot_count}, state}
  end
end
