defmodule TiannaraRuntime.WorldSupervisor do
  @moduledoc """
  PHASE 5A: Per-World Supervisor - Isolated runtime tree for each world.
  
  Each world runs as an independent OTP supervision tree with:
  - WorldStateManager (state isolation)
  - CAL.Engine (coalition arbitration)
  - CIS.Engine (immune regulation)
  - WorldMemoryStore (append-only memory)
  - EventProcessor (NATS publishing)
  - SimulationLoop (execution tick)
  
  Strategy: :one_for_all (if any component crashes, restart entire world)
  
  This ensures complete isolation between worlds - no shared mutable state.
  """
  
  use Supervisor
  require Logger
  
  def start_link(world_config) do
    Supervisor.start_link(__MODULE__, world_config, name: via_tuple(world_config.id))
  end
  
  @impl true
  def init(world_config) do
    Logger.info("🌐 Starting WorldSupervisor for #{world_config.id}")
    
    children = [
      # State manager - isolated world state
      {TiannaraRuntime.WorldStateManager, world_config},
      
      # CAL engine - coalition arbitration logic
      {TiannaraRuntime.CAL.Engine, world_config},
      
      # CIS engine - immune regulation
      {TiannaraRuntime.CIS.Engine, world_config},
      
      # Memory store - append-only timeline
      {TiannaraRuntime.WorldMemoryStore, world_config},
      
      # Event processor - publishes to NATS
      {TiannaraRuntime.WorldEventProcessor, world_config},
      
      # Simulation loop - main execution tick
      {TiannaraRuntime.WorldSimulationLoop, world_config}
    ]
    
    Supervisor.init(children, strategy: :one_for_all)
  end
  
  # ============================================================================
  # Helper Functions
  # ============================================================================
  
  @doc """
  Get the Registry tuple for a world supervisor.
  """
  def via_tuple(world_id) do
    {:via, Registry, {TiannaraRuntime.WorldRegistry, world_id}}
  end
  
  @doc """
  Stop a world supervisor and all its children.
  """
  def stop_world(world_id) do
    case Registry.lookup(TiannaraRuntime.WorldRegistry, world_id) do
      [{pid, _}] ->
        Supervisor.stop(pid, :normal)
        Logger.info("🛑 Stopped world #{world_id}")
        :ok
      
      [] ->
        {:error, :not_found}
    end
  end
end
