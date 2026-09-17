defmodule TiannaraRuntime.WorldRegistrySupervisor do
  @moduledoc """
  PHASE 5A: Root supervisor for multi-world branching system.
  
  Manages the WorldRegistry (tracks all worlds) and DynamicSupervisor
  (spawns isolated world runtime trees).
  
  Architecture:
    WorldRegistrySupervisor
    ├── WorldRegistry (GenServer - world tracking)
    └── DynamicSupervisor (WorldRuntimeSupervisor - per-world isolation)
  """
  
  use Supervisor
  
  def start_link(init_arg \\ []) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  
  @impl true
  def init(_init_arg) do
    children = [
      # Registry tracks all active worlds and their metadata
      {TiannaraRuntime.WorldRegistry, []},
      
      # DynamicSupervisor spawns isolated world runtime trees
      # Each world gets its own supervision subtree
      {DynamicSupervisor, name: TiannaraRuntime.WorldRuntimeSupervisor, strategy: :one_for_one}
    ]
    
    Supervisor.init(children, strategy: :one_for_one)
  end
end
