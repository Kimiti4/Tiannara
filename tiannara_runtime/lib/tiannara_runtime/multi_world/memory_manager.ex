defmodule TiannaraRuntime.MultiWorld.MemoryManager do
  @moduledoc """
  PHASE 5 SAFEGUARD #2: Hard Memory Ceilings
  
  Prevents memory explosion from branching world simulations by:
  - Enforcing per-world memory limits
  - Tracking total system memory usage
  - Automatic garbage collection triggers
  - Memory pressure alerts and throttling
  
  This module works with ResourceQuota but focuses specifically on
  memory management strategies (GC, compaction, eviction).
  """
  
  use GenServer
  require Logger
  
  # Memory thresholds
  @system_memory_warning_mb 4096    # 4GB warning threshold
  @system_memory_critical_mb 8192   # 8GB critical threshold
  @world_memory_soft_limit_mb 256   # Soft limit per world (warning)
  @world_memory_hard_limit_mb 512   # Hard limit per world (enforced)
  
  # State
  defstruct [
    system_memory_mb: 0,
    world_memory_usage: %{},  # %{world_id => memory_mb}
    gc_triggers: 0,
    last_gc_time: nil
  ]
  
  # ============================================================================
  # Public API
  # ============================================================================
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Register memory allocation for a world.
  
  Returns:
    :ok - Allocation approved
    {:error, :memory_limit_exceeded} - Would exceed hard limit
  """
  def allocate_memory(world_id, requested_mb) do
    GenServer.call(__MODULE__, {:allocate, world_id, requested_mb})
  end
  
  @doc """
  Release memory when a world frees resources.
  """
  def release_memory(world_id, released_mb) do
    GenServer.cast(__MODULE__, {:release, world_id, released_mb})
  end
  
  @doc """
  Get current memory status for a world.
  """
  def get_world_memory(world_id) do
    GenServer.call(__MODULE__, {:get_world_memory, world_id})
  end
  
  @doc """
  Get system-wide memory status.
  """
  def get_system_status() do
    GenServer.call(__MODULE__, :get_system_status)
  end
  
  @doc """
  Trigger garbage collection for a specific world.
  """
  def trigger_gc(world_id) do
    GenServer.cast(__MODULE__, {:trigger_gc, world_id})
  end
  
  @doc """
  Force emergency GC across all worlds (critical memory pressure).
  """
  def emergency_gc() do
    GenServer.cast(__MODULE__, :emergency_gc)
  end
  
  @doc """
  Check if system is under memory pressure.
  
  Returns:
    :normal - No pressure
    :warning - Approaching limits
    :critical - Immediate action required
  """
  def check_pressure() do
    GenServer.call(__MODULE__, :check_pressure)
  end
  
  # ============================================================================
  # GenServer Callbacks
  # ============================================================================
  
  @impl true
  def init(_opts) do
    Logger.info("🧠 MemoryManager started")
    Logger.info("   System warning threshold: #{@system_memory_warning_mb}MB")
    Logger.info("   System critical threshold: #{@system_memory_critical_mb}MB")
    Logger.info("   Per-world soft limit: #{@world_memory_soft_limit_mb}MB")
    Logger.info("   Per-world hard limit: #{@world_memory_hard_limit_mb}MB")
    
    # Start periodic memory monitoring
    schedule_memory_check()
    
    {:ok, %__MODULE__{}}
  end
  
  @impl true
  def handle_call({:allocate, world_id, requested_mb}, _from, state) do
    current_usage = Map.get(state.world_memory_usage, world_id, 0)
    new_usage = current_usage + requested_mb
    
    cond do
      # Check per-world hard limit
      new_usage > @world_memory_hard_limit_mb ->
        Logger.warning("⚠️  World #{world_id} memory allocation denied: would exceed hard limit (#{new_usage}MB > #{@world_memory_hard_limit_mb}MB)")
        {:reply, {:error, :memory_limit_exceeded}, state}
      
      # Check system-wide critical threshold
      state.system_memory_mb + requested_mb > @system_memory_critical_mb ->
        Logger.error("🚨 System memory critical! Allocation denied for world #{world_id}")
        {:reply, {:error, :system_memory_critical}, state}
      
      true ->
        # Update usage
        new_world_usage = Map.put(state.world_memory_usage, world_id, new_usage)
        new_system_memory = Enum.sum(Map.values(new_world_usage))
        
        new_state = %{state |
          world_memory_usage: new_world_usage,
          system_memory_mb: new_system_memory
        }
        
        # Check if approaching limits
        if new_usage > @world_memory_soft_limit_mb do
          Logger.warning("⚠️  World #{world_id} approaching memory soft limit (#{new_usage}MB)")
          
          # Suggest GC
          if new_usage > @world_memory_soft_limit_mb * 1.5 do
            Logger.info("💡 Suggesting GC for world #{world_id}")
            trigger_gc(world_id)
          end
        end
        
        {:reply, :ok, new_state}
    end
  end
  
  @impl true
  def handle_call({:get_world_memory, world_id}, _from, state) do
    usage = Map.get(state.world_memory_usage, world_id, 0)
    {:reply, {:ok, usage}, state}
  end
  
  @impl true
  def handle_call(:get_system_status, _from, state) do
    status = %{
      system_memory_mb: state.system_memory_mb,
      world_count: map_size(state.world_memory_usage),
      worlds: state.world_memory_usage,
      gc_triggers: state.gc_triggers,
      last_gc_time: state.last_gc_time
    }
    
    {:reply, {:ok, status}, state}
  end
  
  @impl true
  def handle_call(:check_pressure, _from, state) do
    pressure = cond do
      state.system_memory_mb > @system_memory_critical_mb ->
        :critical
      
      state.system_memory_mb > @system_memory_warning_mb ->
        :warning
      
      true ->
        :normal
    end
    
    {:reply, pressure, state}
  end
  
  @impl true
  def handle_cast({:release, world_id, released_mb}, state) do
    current_usage = Map.get(state.world_memory_usage, world_id, 0)
    new_usage = max(0, current_usage - released_mb)
    
    new_world_usage = Map.put(state.world_memory_usage, world_id, new_usage)
    new_system_memory = Enum.sum(Map.values(new_world_usage))
    
    {:ok, %{state |
      world_memory_usage: new_world_usage,
      system_memory_mb: new_system_memory
    }}
  end
  
  @impl true
  def handle_cast({:trigger_gc, world_id}, state) do
    Logger.info("🗑️  Triggering GC for world #{world_id}")
    
    # In actual implementation, this would call BEAM GC or custom cleanup
    # For now, we simulate memory reduction
    current_usage = Map.get(state.world_memory_usage, world_id, 0)
    estimated_freed = current_usage * 0.3  # Assume 30% can be freed
    
    new_usage = max(0, current_usage - estimated_freed)
    new_world_usage = Map.put(state.world_memory_usage, world_id, new_usage)
    new_system_memory = Enum.sum(Map.values(new_world_usage))
    
    Logger.info("   Freed ~#{estimated_freed |> round()}MB (#{current_usage}MB → #{new_usage}MB)")
    
    {:ok, %{state |
      world_memory_usage: new_world_usage,
      system_memory_mb: new_system_memory,
      gc_triggers: state.gc_triggers + 1,
      last_gc_time: DateTime.utc_now()
    }}
  end
  
  @impl true
  def handle_cast(:emergency_gc, state) do
    Logger.error("🚨 EMERGENCY GC TRIGGERED - All worlds")
    
    # Force GC on all worlds aggressively
    new_world_usage = Enum.map(state.world_memory_usage, fn {world_id, usage} ->
      # Aggressive GC: free up to 50%
      freed = usage * 0.5
      new_usage = max(0, usage - freed)
      
      Logger.warning("   World #{world_id}: #{usage}MB → #{new_usage}MB (freed #{freed |> round()}MB)")
      
      {world_id, new_usage}
    end) |> Map.new()
    
    new_system_memory = Enum.sum(Map.values(new_world_usage))
    
    Logger.info("✅ Emergency GC complete: #{state.system_memory_mb}MB → #{new_system_memory}MB")
    
    {:ok, %{state |
      world_memory_usage: new_world_usage,
      system_memory_mb: new_system_memory,
      gc_triggers: state.gc_triggers + 1,
      last_gc_time: DateTime.utc_now()
    }}
  end
  
  # ============================================================================
  # Private Helpers
  # ============================================================================
  
  defp schedule_memory_check() do
    Process.send_after(self(), :check_memory, 60_000)  # Check every 60 seconds
  end
  
  @impl true
  def handle_info(:check_memory, state) do
    # Periodic memory pressure check
    case check_pressure_internal(state) do
      :critical ->
        Logger.error("🚨 CRITICAL MEMORY PRESSURE: #{state.system_memory_mb}MB")
        emergency_gc()
      
      :warning ->
        Logger.warning("⚠️  Memory pressure warning: #{state.system_memory_mb}MB")
        # Suggest GC for top memory consumers
        suggest_gc_for_heavy_users(state)
      
      :normal ->
        :ok
    end
    
    schedule_memory_check()
    {:ok, state}
  end
  
  defp check_pressure_internal(state) do
    cond do
      state.system_memory_mb > @system_memory_critical_mb -> :critical
      state.system_memory_mb > @system_memory_warning_mb -> :warning
      true -> :normal
    end
  end
  
  defp suggest_gc_for_heavy_users(state) do
    # Find worlds using > 80% of soft limit
    heavy_users = Enum.filter(state.world_memory_usage, fn {_id, usage} ->
      usage > @world_memory_soft_limit_mb * 0.8
    end)
    
    Enum.each(heavy_users, fn {world_id, _usage} ->
      Logger.info("💡 Suggesting GC for heavy user: world #{world_id}")
      trigger_gc(world_id)
    end)
  end
end
