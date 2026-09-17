defmodule Tiannara.OLEF.NodeRegistry do
  use GenServer

  def start_link(init_arg \\ []) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def register_node(node_id, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:register_node, node_id, metadata})
  end

  def unregister_node(node_id) do
    GenServer.cast(__MODULE__, {:unregister_node, node_id})
  end

  def update_health(node_id, health_status) do
    GenServer.cast(__MODULE__, {:update_health, node_id, health_status})
  end

  def get_active_nodes do
    GenServer.call(__MODULE__, :get_active_nodes)
  end

  def get_node_details(node_id) do
    GenServer.call(__MODULE__, {:get_node_details, node_id})
  end

  def get_neighborhood_map do
    GenServer.call(__MODULE__, :get_neighborhood_map)
  end

  def init(_init_arg) do
    state = %{
      nodes: %{},
      neighborhoods: %{}
    }
    {:ok, state}
  end

  def handle_call(:get_active_nodes, _from, state) do
    active = Enum.filter(state.nodes, fn {_id, info} -> info.status == :active end) |> Enum.into(%{})
    {:reply, {:ok, active}, state}
  end

  def handle_call({:get_node_details, node_id}, _from, state) do
    case Map.get(state.nodes, node_id) do
      nil -> {:reply, {:error, :node_not_found}, state}
      details -> {:reply, {:ok, details}, state}
    end
  end

  def handle_call(:get_neighborhood_map, _from, state) do
    {:reply, {:ok, state.neighborhoods}, state}
  end

  def handle_cast({:register_node, node_id, metadata}, state) do
    node_info = %{
      id: node_id,
      status: :active,
      health: :healthy,
      metadata: metadata,
      registered_at: System.system_time()
    }
    updated_nodes = Map.put(state.nodes, node_id, node_info)
    default_neighbors = Map.keys(updated_nodes) -- [node_id]
    updated_neighborhoods = Map.put(state.neighborhoods, node_id, default_neighbors)
    {:noreply, %{state | nodes: updated_nodes, neighborhoods: updated_neighborhoods}}
  end

  def handle_cast({:unregister_node, node_id}, state) do
    updated_nodes = Map.delete(state.nodes, node_id)
    updated_neighborhoods = Map.delete(state.neighborhoods, node_id)
    updated_neighborhoods = Enum.map(updated_neighborhoods, fn {nid, neighbors} ->
      {nid, List.delete(neighbors, node_id)}
    end) |> Enum.into(%{})
    {:noreply, %{state | nodes: updated_nodes, neighborhoods: updated_neighborhoods}}
  end

  def handle_cast({:update_health, node_id, health_status}, state) do
    case Map.get(state.nodes, node_id) do
      nil ->
        {:noreply, state}
      node_info ->
        updated_info = %{node_info | health: health_status}
        updated_nodes = Map.put(state.nodes, node_id, updated_info)
        {:noreply, %{state | nodes: updated_nodes}}
    end
  end

  def handle_cast(:reset, state) do
    {:noreply, %{state | nodes: %{}, neighborhoods: %{}}}
  end
end
