defmodule Tiannara.OLEF.FieldSupervisor do
  use GenServer

  def start_link(init_arg \\ []) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def register_node(node_id, capacity \\ 100.0) do
    GenServer.cast(__MODULE__, {:register_node, node_id, capacity})
  end

  def report_load(node_id, current_load) do
    GenServer.cast(__MODULE__, {:report_load, node_id, current_load})
  end

  def request_redistribution do
    GenServer.cast(__MODULE__, :request_redistribution)
  end

  def get_field_state do
    GenServer.call(__MODULE__, :get_field_state)
  end

  def init(_init_arg) do
    state = %{
      nodes: %{},
      pressure_field: %{},
      diffusion_rate: 0.12,
      redistribution_history: []
    }
    {:ok, state}
  end

  def handle_call(:get_field_state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_cast({:register_node, node_id, capacity}, state) do
    updated_nodes = Map.put(state.nodes, node_id, %{
      capacity: capacity,
      current_load: 0.0,
      pressure: 0.0
    })
    {:noreply, %{state | nodes: updated_nodes}}
  end

  def handle_cast({:report_load, node_id, current_load}, state) do
    case Map.get(state.nodes, node_id) do
      nil ->
        {:noreply, state}
      node_info ->
        pressure = current_load / max(node_info.capacity, 0.0001)
        updated_node = %{node_info | current_load: current_load, pressure: pressure}
        updated_nodes = Map.put(state.nodes, node_id, updated_node)
        updated_pressure_field = Map.put(state.pressure_field, node_id, pressure)
        {:noreply, %{state | nodes: updated_nodes, pressure_field: updated_pressure_field}}
    end
  end

  def handle_cast(:request_redistribution, state) do
    history_entry = %{type: :redistribution, timestamp: System.system_time()}
    updated_history = [history_entry | state.redistribution_history] |> Enum.take(50)
    {:noreply, %{state | redistribution_history: updated_history}}
  end

  def handle_cast(:reset, state) do
    {:noreply, %{state | nodes: %{}, pressure_field: %{}, redistribution_history: []}}
  end
end
