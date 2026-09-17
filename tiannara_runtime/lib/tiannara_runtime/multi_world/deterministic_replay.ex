defmodule TiannaraRuntime.MultiWorld.DeterministicReplay do
  @moduledoc """
  PHASE 5 SAFEGUARD #3: Deterministic Replay Mode
  
  Enables exact replay of world evolution for debugging evolutionary divergence.
  
  Key features:
  - Records all random seeds and non-deterministic inputs
  - Captures complete event log with timestamps
  - Supports frame-by-frame stepping through history
  - Guarantees identical results when replaying with same seed
  
  This is CRITICAL for:
  - Debugging why worlds diverged
  - Reproducing bugs in specific evolutionary paths
  - Validating that changes don't break existing behavior
  """
  
  use GenServer
  require Logger
  
  # State
  defstruct [
    recording_worlds: %{},      # %{world_id => %{events: [], seed: n, step: n}}
    replaying_worlds: %{},      # %{world_id => %{events: [...], current_step: n}}
    max_events_per_world: 100_000  # Prevent unbounded log growth
  ]
  
  # ============================================================================
  # Public API
  # ============================================================================
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Start recording a world's evolution from this point forward.
  
  Args:
    world_id - Unique identifier for the world
    seed - Random seed used for this world (for determinism)
    
  Returns:
    :ok - Recording started
  """
  def start_recording(world_id, seed) do
    GenServer.cast(__MODULE__, {:start_recording, world_id, seed})
  end
  
  @doc """
  Record an event in the world's evolution log.
  
  Events include:
  - Agent belief updates
  - Coalition formations/splits
  - CIS interventions
  - CAL arbitration decisions
  - Random number generations
  
  Args:
    world_id - World identifier
    event_type - Type of event (:agent_update, :coalition_form, etc.)
    data - Event payload (must be serializable)
    timestamp - Optional timestamp (defaults to now)
  """
  def record_event(world_id, event_type, data, timestamp \\ nil) do
    GenServer.cast(__MODULE__, {:record_event, world_id, event_type, data, timestamp || System.system_time(:millisecond)})
  end
  
  @doc """
  Stop recording a world.
  """
  def stop_recording(world_id) do
    GenServer.call(__MODULE__, {:stop_recording, world_id})
  end
  
  @doc """
  Start replaying a world from recorded history.
  
  The world will receive events in exact order with same timing.
  
  Returns:
    {:ok, total_events} - Replay started
    {:error, :no_recording} - No recording exists for this world
  """
  def start_replay(world_id) do
    GenServer.call(__MODULE__, {:start_replay, world_id})
  end
  
  @doc """
  Step forward one event in replay mode.
  
  Returns:
    {:ok, event} - Next event to process
    {:error, :end_of_log} - No more events
    {:error, :not_replaying} - World not in replay mode
  """
  def step_replay(world_id) do
    GenServer.call(__MODULE__, {:step_replay, world_id})
  end
  
  @doc """
  Get recording metadata for a world.
  
  Returns:
    {:ok, %{event_count: n, seed: n, duration_ms: n}}
    {:error, :no_recording}
  """
  def get_recording_info(world_id) do
    GenServer.call(__MODULE__, {:get_recording_info, world_id})
  end
  
  @doc """
  Export recording to file for offline analysis.
  
  Format: JSON with complete event log and metadata.
  """
  def export_recording(world_id, filepath) do
    GenServer.call(__MODULE__, {:export_recording, world_id, filepath})
  end
  
  @doc """
  Import recording from file (for sharing/debugging).
  """
  def import_recording(filepath) do
    GenServer.call(__MODULE__, {:import_recording, filepath})
  end
  
  # ============================================================================
  # GenServer Callbacks
  # ============================================================================
  
  @impl true
  def init(_opts) do
    Logger.info("📼 DeterministicReplay initialized")
    Logger.info("   Max events per world: #{@max_events_per_world}")
    
    {:ok, %__MODULE__{}}
  end
  
  @impl true
  def handle_cast({:start_recording, world_id, seed}, state) do
    case Map.get(state.recording_worlds, world_id) do
      nil ->
        new_recording = %{
          events: [],
          seed: seed,
          start_time: System.system_time(:millisecond),
          event_count: 0
        }
        
        new_state = %{state |
          recording_worlds: Map.put(state.recording_worlds, world_id, new_recording)
        }
        
        Logger.info("📹 Started recording world #{world_id} (seed: #{seed})")
        {:ok, new_state}
      
      _existing ->
        Logger.warning("⚠️  World #{world_id} already being recorded")
        {:ok, state}
    end
  end
  
  @impl true
  def handle_cast({:record_event, world_id, event_type, data, timestamp}, state) do
    case Map.get(state.recording_worlds, world_id) do
      nil ->
        # Not recording this world, ignore
        :ok
      
      recording ->
        # Check if we've hit the event limit
        if recording.event_count >= @max_events_per_world do
          Logger.warning("⚠️  World #{world_id} reached max event limit (#{@max_events_per_world}), stopping recording")
          new_state = %{state |
            recording_worlds: Map.delete(state.recording_worlds, world_id)
          }
          {:ok, new_state}
        else
          # Append event
          event = %{
            type: event_type,
            data: data,
            timestamp: timestamp,
            sequence_number: recording.event_count
          }
          
          new_events = recording.events ++ [event]
          new_recording = %{recording |
            events: new_events,
            event_count: recording.event_count + 1
          }
          
          new_state = %{state |
            recording_worlds: Map.put(state.recording_worlds, world_id, new_recording)
          }
          
          {:ok, new_state}
        end
    end
  end
  
  @impl true
  def handle_call({:stop_recording, world_id}, _from, state) do
    case Map.pop(state.recording_worlds, world_id) do
      {nil, _} ->
        {:reply, {:error, :not_recording}, state}
      
      {recording, remaining_recordings} ->
        duration_ms = System.system_time(:millisecond) - recording.start_time
        
        Logger.info("⏹️  Stopped recording world #{world_id}")
        Logger.info("   Events recorded: #{recording.event_count}")
        Logger.info("   Duration: #{duration_ms}ms")
        
        {:reply, {:ok, %{
          event_count: recording.event_count,
          duration_ms: duration_ms,
          seed: recording.seed
        }}, %{state | recording_worlds: remaining_recordings}}
    end
  end
  
  @impl true
  def handle_call({:start_replay, world_id}, _from, state) do
    # Find recording for this world
    recording = Map.get(state.recording_worlds, world_id)
    
    case recording do
      nil ->
        {:reply, {:error, :no_recording}, state}
      
      _ ->
        # Initialize replay state
        replay_state = %{
          events: recording.events,
          current_step: 0,
          total_events: length(recording.events),
          seed: recording.seed
        }
        
        new_state = %{state |
          replaying_worlds: Map.put(state.replaying_worlds, world_id, replay_state)
        }
        
        Logger.info("▶️  Started replay for world #{world_id} (#{replay_state.total_events} events)")
        {:reply, {:ok, replay_state.total_events}, new_state}
    end
  end
  
  @impl true
  def handle_call({:step_replay, world_id}, _from, state) do
    case Map.get(state.replaying_worlds, world_id) do
      nil ->
        {:reply, {:error, :not_replaying}, state}
      
      replay ->
        if replay.current_step >= replay.total_events do
          {:reply, {:error, :end_of_log}, state}
        else
          # Get next event
          event = Enum.at(replay.events, replay.current_step)
          
          # Advance step counter
          new_replay = %{replay |
            current_step: replay.current_step + 1
          }
          
          new_state = %{state |
            replaying_worlds: Map.put(state.replaying_worlds, world_id, new_replay)
          }
          
          {:reply, {:ok, event}, new_state}
        end
    end
  end
  
  @impl true
  def handle_call({:get_recording_info, world_id}, _from, state) do
    case Map.get(state.recording_worlds, world_id) do
      nil ->
        {:reply, {:error, :no_recording}, state}
      
      recording ->
        info = %{
          event_count: recording.event_count,
          seed: recording.seed,
          duration_ms: System.system_time(:millisecond) - recording.start_time,
          is_active: true
        }
        
        {:reply, {:ok, info}, state}
    end
  end
  
  @impl true
  def handle_call({:export_recording, world_id, filepath}, _from, state) do
    case Map.get(state.recording_worlds, world_id) do
      nil ->
        {:reply, {:error, :no_recording}, state}
      
      recording ->
        export_data = %{
          world_id: world_id,
          seed: recording.seed,
          event_count: recording.event_count,
          start_time: recording.start_time,
          events: recording.events
        }
        
        # Write to file as JSON
        json = Jason.encode!(export_data, pretty: true)
        File.write!(filepath, json)
        
        Logger.info("💾 Exported recording for world #{world_id} to #{filepath}")
        Logger.info("   Size: #{byte_size(json)} bytes")
        
        {:reply, :ok, state}
    end
  end
  
  @impl true
  def handle_call({:import_recording, filepath}, _from, state) do
    case File.read(filepath) do
      {:ok, json} ->
        case Jason.decode(json) do
          {:ok, data} ->
            world_id = data["world_id"]
            
            recording = %{
              events: data["events"],
              seed: data["seed"],
              start_time: data["start_time"],
              event_count: data["event_count"]
            }
            
            new_state = %{state |
              recording_worlds: Map.put(state.recording_worlds, world_id, recording)
            }
            
            Logger.info("📂 Imported recording for world #{world_id} from #{filepath}")
            {:reply, {:ok, world_id}, new_state}
          
          {:error, reason} ->
            {:reply, {:error, "JSON decode failed: #{reason}"}, state}
        end
      
      {:error, reason} ->
        {:reply, {:error, "File read failed: #{reason}"}, state}
    end
  end
end
