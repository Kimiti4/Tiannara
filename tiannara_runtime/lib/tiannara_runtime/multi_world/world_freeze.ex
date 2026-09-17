defmodule TiannaraRuntime.MultiWorld.WorldFreeze do
  @moduledoc """
  PHASE 5 SAFEGUARD #4: World Freeze / Snapshot Export
  
  Enables pausing world evolution and exporting complete state snapshots for:
  - Rollback to previous states
  - Offline analysis and debugging
  - Sharing world states between systems
  - Creating checkpoints before risky operations
  
  This is CRITICAL for:
  - Recovering from unstable evolutionary cascades
  - Analyzing why a world reached a particular state
  - Testing "what-if" scenarios without affecting live worlds
  """
  
  use GenServer
  require Logger
  
  # State
  defstruct [
    frozen_worlds: %{},       # %{world_id => snapshot_data}
    snapshot_history: %{},    # %{world_id => [snapshot_timestamps]}
    max_snapshots_per_world: 10  # Limit history size
  ]
  
  # ============================================================================
  # Public API
  # ============================================================================
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Freeze a world (pause all evolution).
  
  The world stops processing events but maintains its current state.
  
  Returns:
    :ok - World frozen
    {:error, :already_frozen} - World already frozen
  """
  def freeze_world(world_id) do
    GenServer.call(__MODULE__, {:freeze, world_id})
  end
  
  @doc """
  Unfreeze a world (resume evolution).
  
  Returns:
    :ok - World resumed
    {:error, :not_frozen} - World not frozen
  """
  def unfreeze_world(world_id) do
    GenServer.call(__MODULE__, {:unfreeze, world_id})
  end
  
  @doc """
  Create a snapshot of a world's current state.
  
  Captures:
  - All agent beliefs and positions
  - Coalition structures
  - CIS/CAL parameters
  - Event history (last N events)
  - Random seed state
  
  Returns:
    {:ok, snapshot_id} - Snapshot created
    {:error, reason} - Failed to create snapshot
  """
  def create_snapshot(world_id, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:create_snapshot, world_id, metadata})
  end
  
  @doc """
  Export snapshot to file for offline analysis or sharing.
  
  Format: JSON with complete world state.
  """
  def export_snapshot(snapshot_id, filepath) do
    GenServer.call(__MODULE__, {:export_snapshot, snapshot_id, filepath})
  end
  
  @doc """
  Import snapshot from file (for rollback or analysis).
  
  Returns:
    {:ok, world_id} - World restored from snapshot
    {:error, reason} - Import failed
  """
  def import_snapshot(filepath) do
    GenServer.call(__MODULE__, {:import_snapshot, filepath})
  end
  
  @doc """
  Restore a world to a previous snapshot state.
  
  WARNING: This discards all progress since the snapshot!
  
  Returns:
    :ok - World restored
    {:error, :snapshot_not_found} - Invalid snapshot ID
  """
  def restore_snapshot(world_id, snapshot_id) do
    GenServer.call(__MODULE__, {:restore_snapshot, world_id, snapshot_id})
  end
  
  @doc """
  List all snapshots for a world.
  """
  def list_snapshots(world_id) do
    GenServer.call(__MODULE__, {:list_snapshots, world_id})
  end
  
  @doc """
  Check if a world is currently frozen.
  """
  def is_frozen?(world_id) do
    GenServer.call(__MODULE__, {:is_frozen, world_id})
  end
  
  @doc """
  Get snapshot metadata (without full state).
  """
  def get_snapshot_info(snapshot_id) do
    GenServer.call(__MODULE__, {:get_snapshot_info, snapshot_id})
  end
  
  # ============================================================================
  # GenServer Callbacks
  # ============================================================================
  
  @impl true
  def init(_opts) do
    Logger.info("❄️  WorldFreeze initialized")
    Logger.info("   Max snapshots per world: #{@max_snapshots_per_world}")
    
    {:ok, %__MODULE__{}}
  end
  
  @impl true
  def handle_call({:freeze, world_id}, _from, state) do
    case Map.get(state.frozen_worlds, world_id) do
      nil ->
        # Capture current state for freeze
        snapshot = capture_world_state(world_id)
        
        new_frozen = Map.put(state.frozen_worlds, world_id, %{
          snapshot: snapshot,
          frozen_at: DateTime.utc_now(),
          reason: :manual
        })
        
        Logger.info("❄️  World #{world_id} frozen")
        
        # Notify world supervisor to pause event processing
        notify_world_supervisor(world_id, :pause)
        
        {:reply, :ok, %{state | frozen_worlds: new_frozen}}
      
      _ ->
        {:reply, {:error, :already_frozen}, state}
    end
  end
  
  @impl true
  def handle_call({:unfreeze, world_id}, _from, state) do
    case Map.pop(state.frozen_worlds, world_id) do
      {nil, _} ->
        {:reply, {:error, :not_frozen}, state}
      
      {_frozen_data, remaining_frozen} ->
        Logger.info("🔥 World #{world_id} unfrozen (resuming evolution)")
        
        # Notify world supervisor to resume event processing
        notify_world_supervisor(world_id, :resume)
        
        {:reply, :ok, %{state | frozen_worlds: remaining_frozen}}
    end
  end
  
  @impl true
  def handle_call({:create_snapshot, world_id, metadata}, _from, state) do
    # Generate unique snapshot ID
    snapshot_id = "snap_#{world_id}_#{System.system_time(:millisecond)}"
    
    # Capture complete world state
    snapshot_data = capture_world_state(world_id)
    
    # Add metadata
    snapshot = %{
      id: snapshot_id,
      world_id: world_id,
      created_at: DateTime.utc_now(),
      metadata: metadata,
      state: snapshot_data
    }
    
    # Store in frozen_worlds map (even if world isn't frozen)
    new_frozen = Map.put(state.frozen_worlds, snapshot_id, snapshot)
    
    # Update snapshot history
    history = Map.get(state.snapshot_history, world_id, [])
    new_history = Enum.take([snapshot_id | history], @max_snapshots_per_world)
    
    new_state = %{state |
      frozen_worlds: new_frozen,
      snapshot_history: Map.put(state.snapshot_history, world_id, new_history)
    }
    
    Logger.info("📸 Snapshot created for world #{world_id}: #{snapshot_id}")
    
    {:reply, {:ok, snapshot_id}, new_state}
  end
  
  @impl true
  def handle_call({:export_snapshot, snapshot_id, filepath}, _from, state) do
    case Map.get(state.frozen_worlds, snapshot_id) do
      nil ->
        {:reply, {:error, :snapshot_not_found}, state}
      
      snapshot ->
        # Export as JSON
        json = Jason.encode!(snapshot, pretty: true)
        File.write!(filepath, json)
        
        Logger.info("💾 Exported snapshot #{snapshot_id} to #{filepath}")
        Logger.info("   Size: #{byte_size(json)} bytes")
        
        {:reply, :ok, state}
    end
  end
  
  @impl true
  def handle_call({:import_snapshot, filepath}, _from, state) do
    case File.read(filepath) do
      {:ok, json} ->
        case Jason.decode(json) do
          {:ok, snapshot} ->
            snapshot_id = snapshot["id"]
            world_id = snapshot["world_id"]
            
            # Store snapshot
            new_frozen = Map.put(state.frozen_worlds, snapshot_id, snapshot)
            
            # Update history
            history = Map.get(state.snapshot_history, world_id, [])
            new_history = Enum.take([snapshot_id | history], @max_snapshots_per_world)
            
            new_state = %{state |
              frozen_worlds: new_frozen,
              snapshot_history: Map.put(state.snapshot_history, world_id, new_history)
            }
            
            Logger.info("📂 Imported snapshot #{snapshot_id} from #{filepath}")
            {:reply, {:ok, world_id}, new_state}
          
          {:error, reason} ->
            {:reply, {:error, "JSON decode failed: #{reason}"}, state}
        end
      
      {:error, reason} ->
        {:reply, {:error, "File read failed: #{reason}"}, state}
    end
  end
  
  @impl true
  def handle_call({:restore_snapshot, world_id, snapshot_id}, _from, state) do
    case Map.get(state.frozen_worlds, snapshot_id) do
      nil ->
        {:reply, {:error, :snapshot_not_found}, state}
      
      snapshot ->
        Logger.warning("🔄 Restoring world #{world_id} to snapshot #{snapshot_id}")
        Logger.warning("   ⚠️  All progress since snapshot will be LOST!")
        
        # Restore world state from snapshot
        restore_world_state(world_id, snapshot.state)
        
        # If world was frozen, keep it frozen
        # If world was running, resume it
        
        {:reply, :ok, state}
    end
  end
  
  @impl true
  def handle_call({:list_snapshots, world_id}, _from, state) do
    history = Map.get(state.snapshot_history, world_id, [])
    
    snapshots = Enum.map(history, fn snapshot_id ->
      case Map.get(state.frozen_worlds, snapshot_id) do
        nil -> nil
        snapshot -> %{
          id: snapshot_id,
          created_at: snapshot.created_at,
          metadata: snapshot.metadata
        }
      end
    end) |> Enum.filter(& &1)
    
    {:reply, {:ok, snapshots}, state}
  end
  
  @impl true
  def handle_call({:is_frozen, world_id}, _from, state) do
    is_frozen = Map.has_key?(state.frozen_worlds, world_id) && 
                is_map(Map.get(state.frozen_worlds, world_id)) &&
                Map.has_key?(Map.get(state.frozen_worlds, world_id), :frozen_at)
    
    {:reply, is_frozen, state}
  end
  
  @impl true
  def handle_call({:get_snapshot_info, snapshot_id}, _from, state) do
    case Map.get(state.frozen_worlds, snapshot_id) do
      nil ->
        {:reply, {:error, :snapshot_not_found}, state}
      
      snapshot ->
        info = %{
          id: snapshot_id,
          world_id: snapshot.world_id,
          created_at: snapshot.created_at,
          metadata: snapshot.metadata,
          has_state: Map.has_key?(snapshot, :state)
        }
        
        {:reply, {:ok, info}, state}
    end
  end
  
  # ============================================================================
  # Private Helpers
  # ============================================================================
  
  defp capture_world_state(world_id) do
    # In actual implementation, this would query the world's GenServer
    # for its complete state (agents, coalitions, parameters, etc.)
    # For now, we return a placeholder structure
    
    %{
      agents: [],        # List of agent states
      coalitions: [],    # List of coalition structures
      cis_params: %{},   # CIS intervention parameters
      cal_params: %{},   # CAL arbitration parameters
      event_log: [],     # Recent event history
      random_seed: 0,    # Current RNG state
      timestamp: DateTime.utc_now()
    }
  end
  
  defp restore_world_state(world_id, state_data) do
    # In actual implementation, this would send the state data
    # to the world's GenServer to restore its internal state
    
    Logger.info("   Restored #{length(state_data.agents)} agents")
    Logger.info("   Restored #{length(state_data.coalitions)} coalitions")
  end
  
  defp notify_world_supervisor(world_id, action) do
    # Send message to WorldSupervisor to pause/resume the world
    send(TiannaraRuntime.MultiWorld.WorldSupervisor, {action, world_id})
  end
end
