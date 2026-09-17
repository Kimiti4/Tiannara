defmodule TiannaraRuntime.WorldRegistry do
  @moduledoc """
  PHASE 5A: World Registry - Tracks all active worlds and their metadata.
  
  Maintains:
  - World ID → metadata mapping
  - Lineage tracking (parent → children)
  - Active world count for quota enforcement
  - Process registry via Registry module
  
  This is the CONTROL PLANE for multi-world branching.
  """
  
  use GenServer
  require Logger
  
  # State
  defstruct [
    worlds: %{},              # %{world_id => world_metadata}
    lineage: %{},             # %{parent_id => [child_ids]}
    active_count: 0,
    total_created: 0
  ]
  
  # ============================================================================
  # Public API
  # ============================================================================
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Create a new world with optional parent and configuration.
  
  Returns:
    {:ok, world_id} - World created successfully
    {:error, reason} - Creation failed (quota exceeded, etc.)
  """
  def create_world(parent_world_id \\ nil, config \\ %{}) do
    GenServer.call(__MODULE__, {:create_world, parent_world_id, config})
  end
  
  @doc """
  Get world metadata by ID.
  """
  def get_world(world_id) do
    GenServer.call(__MODULE__, {:get_world, world_id})
  end
  
  @doc """
  List all active worlds.
  """
  def list_worlds() do
    GenServer.call(__MODULE__, :list_worlds)
  end
  
  @doc """
  Update world fitness score.
  """
  def update_fitness(world_id, fitness) do
    GenServer.cast(__MODULE__, {:update_fitness, world_id, fitness})
  end
  
  @doc """
  Mark world as terminated/extinct.
  """
  def terminate_world(world_id) do
    GenServer.cast(__MODULE__, {:terminate_world, world_id})
  end
  
  @doc """
  Get active world count.
  """
  def get_active_count() do
    GenServer.call(__MODULE__, :get_active_count)
  end
  
  @doc """
  Add child to parent's lineage.
  """
  def add_child(parent_id, child_id) do
    GenServer.cast(__MODULE__, {:add_child, parent_id, child_id})
  end
  
  # ============================================================================
  # GenServer Callbacks
  # ============================================================================
  
  @impl true
  def init(_opts) do
    Logger.info("📋 WorldRegistry initialized")
    {:ok, %__MODULE__{}}
  end
  
  @impl true
  def handle_call({:create_world, parent_world_id, config}, _from, state) do
    world_id = "W-#{UUID.uuid4()}"
    generation = if parent_world_id, do: get_generation(state, parent_world_id) + 1, else: 0
    
    world_metadata = %{
      id: world_id,
      parent_world: parent_world_id,
      generation: generation,
      config: config,
      status: :active,
      fitness: 0.0,
      created_at: :erlang.unique_integer([:positive]),
      last_updated: :erlang.unique_integer([:positive])
    }
    
    new_state = %{
      state
      | worlds: Map.put(state.worlds, world_id, world_metadata),
        active_count: state.active_count + 1,
        total_created: state.total_created + 1
    }
    
    # Add to lineage if has parent
    new_state = if parent_world_id do
      children = Map.get(new_state.lineage, parent_world_id, [])
      %{new_state | lineage: Map.put(new_state.lineage, parent_world_id, [world_id | children])}
    else
      new_state
    end
    
    Logger.info("🌐 Created world #{world_id} (gen #{generation}, parent: #{inspect(parent_world_id)})")
    
    {:reply, {:ok, world_id}, new_state}
  end
  
  @impl true
  def handle_call({:get_world, world_id}, _from, state) do
    case Map.get(state.worlds, world_id) do
      nil -> {:reply, {:error, :not_found}, state}
      world -> {:reply, {:ok, world}, state}
    end
  end
  
  @impl true
  def handle_call(:list_worlds, _from, state) do
    worlds_list = Map.values(state.worlds) |> Enum.filter(fn w -> w.status == :active end)
    {:reply, {:ok, worlds_list}, state}
  end
  
  @impl true
  def handle_call(:get_active_count, _from, state) do
    {:reply, {:ok, state.active_count}, state}
  end
  
  @impl true
  def handle_cast({:update_fitness, world_id, fitness}, state) do
    case Map.get(state.worlds, world_id) do
      nil ->
        Logger.warning("⚠️  Cannot update fitness for unknown world #{world_id}")
        {:noreply, state}
      
      world ->
        updated_world = %{world | fitness: fitness, last_updated: :erlang.unique_integer([:positive])}
        new_state = %{state | worlds: Map.put(state.worlds, world_id, updated_world)}
        {:noreply, new_state}
    end
  end
  
  @impl true
  def handle_cast({:terminate_world, world_id}, state) do
    case Map.get(state.worlds, world_id) do
      nil ->
        {:noreply, state}
      
      world ->
        updated_world = %{world | status: :extinct, last_updated: :erlang.unique_integer([:positive])}
        new_state = %{
          state
          | worlds: Map.put(state.worlds, world_id, updated_world),
            active_count: state.active_count - 1
        }
        
        Logger.info("💀 World #{world_id} terminated (status: extinct)")
        {:noreply, new_state}
    end
  end
  
  @impl true
  def handle_cast({:add_child, parent_id, child_id}, state) do
    children = Map.get(state.lineage, parent_id, [])
    new_lineage = Map.put(state.lineage, parent_id, [child_id | children])
    {:noreply, %{state | lineage: new_lineage}}
  end
  
  # ============================================================================
  # Private Helpers
  # ============================================================================
  
  defp get_generation(state, world_id) do
    case Map.get(state.worlds, world_id) do
      nil -> 0
      world -> world.generation
    end
  end
end
