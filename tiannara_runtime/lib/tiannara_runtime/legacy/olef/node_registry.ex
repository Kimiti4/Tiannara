defmodule TiannaraRuntime.Legacy.Tiannara.OLEF.NodeRegistry do
  @moduledoc """
  Phase 5F.5 — OLEF Node Registry
  
  Maintains registry of all nodes participating in the pressure field.
  Tracks node capabilities, health status, and network topology.
  """
  
  use GenServer
  require Logger

  def start_link(init_arg \\ []) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  Register a new node.
  """
  def register_node(node_id, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:register_node, node_id, metadata})
  end

  @doc """
  Unregister a node.
  """
  def unregister_node(node_id) do
    GenServer.cast(__MODULE__, {:unregister_node, node_id})
  end

  @doc """
  Update node health status.
  """
  def update_health(node_id, health_status) do
    GenServer.cast(__MODULE__, {:update_health, node_id, health_status})
  end

  @doc """
  Get all active nodes.
  """
  def get_active_nodes do
    GenServer.call(__MODULE__, :get_active_nodes)
  end

  @doc """
  Get node details.
  """
  def get_node_details(node_id) do
    GenServer.call(__MODULE__, {:get_node_details, node_id})
  end

  @doc """
  Get neighborhood topology.
  """
  def get_neighborhood_map do
    GenServer.call(__MODULE__, :get_neighborhood_map)
  end

  # ── Callbacks ─────────────────────────────────────────────────────────────

  @impl true
  def init(_init_arg) do
    state = %{
      nodes: %{},
      neighborhoods: %{},
      registration_count: 0
    }

    Logger.info("📋 OLEF NodeRegistry initialized")
    {:ok, state}
  end

  @impl true
  def handle_call(:get_active_nodes, _from, state) do
    active = Enum.filter(state.nodes, fn {_id, info} -> info.status == :active end) |> Enum.into(%{})
    {:reply, {:ok, active}, state}
  end

  @impl true
  def handle_call({:get_node_details, node_id}, _from, state) do
    case Map.get(state.nodes, node_id) do
      nil -> {:reply, {:error, :node_not_found}, state}
      details -> {:reply, {:ok, details}, state}
    end
  end

  @impl true
  def handle_call(:get_neighborhood_map, _from, state) do
    {:reply, {:ok, state.neighborhoods}, state}
  end

  @impl true
  def handle_cast({:register_node, node_id, metadata}, state) do
    node_info = %{
      id: node_id,
      status: :active,
      health: :healthy,
      metadata: metadata,
      registered_at: System.system_time(),
      last_heartbeat: System.system_time()
    }
    
    updated_nodes = Map.put(state.nodes, node_id, node_info)
    
    default_neighbors = Map.keys(updated_nodes) -- [node_id]
    updated_neighborhoods = Map.put(state.neighborhoods, node_id, default_neighbors)
    
    Logger.info("📋 OLEF: Node #{node_id} registered")
    
    {:noreply, %{state | nodes: updated_nodes, neighborhoods: updated_neighborhoods, registration_count: state.registration_count + 1}}
  end

  @impl true
  def handle_cast({:unregister_node, node_id}, state) do
    updated_nodes = Map.delete(state.nodes, node_id)
    updated_neighborhoods = Map.delete(state.neighborhoods, node_id)
    
    updated_neighborhoods = Enum.map(updated_neighborhoods, fn {nid, neighbors} ->
      {nid, List.delete(neighbors, node_id)}
    end)
    |> Enum.into(%{})
    
    Logger.info("📋 OLEF: Node #{node_id} unregistered")
    
    {:noreply, %{state | nodes: updated_nodes, neighborhoods: updated_neighborhoods}}
  end

  @impl true
  def handle_cast({:update_health, node_id, health_status}, state) do
    case Map.get(state.nodes, node_id) do
      nil ->
        Logger.warning("📋 OLEF: Cannot update health for unknown node #{node_id}")
        {:noreply, state}
      
      node_info ->
        updated_info = %{node_info | health: health_status, last_heartbeat: System.system_time()}
        updated_nodes = Map.put(state.nodes, node_id, updated_info)
        
        Logger.debug("📋 OLEF: Node #{node_id} health updated to #{health_status}")
        
        {:noreply, %{state | nodes: updated_nodes}}
    end
  end

  @impl true
  def handle_cast(:reset, state) do
    {:noreply, %{state | nodes: %{}, neighborhoods: %{}, registration_count: 0}}
  end
end
