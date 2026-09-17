defmodule TiannaraRuntime.Legacy.Tiannara.OLEF.FieldSupervisor do
  @moduledoc """
  Phase 5F.5 — OLEF Field Supervisor
  
  Core diffusion engine that redistributes computational pressure
  across nodes using gradient-based load balancing.
  
  Replaces centralized control with distributed field dynamics.
  
  ## Architecture Principle
  
  > Computation is not managed, it flows through pressure gradients.
  """
  
  use GenServer
  require Logger

  @default_diffusion_rate 0.12
  @equilibrium_tolerance 0.05
  @rebalancing_interval_ms 5_000

  def start_link(init_arg \\ []) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  Register a new node in the pressure field.
  """
  def register_node(node_id, capacity \\ 100.0) do
    GenServer.cast(__MODULE__, {:register_node, node_id, capacity})
  end

  @doc """
  Report current load for a node.
  """
  def report_load(node_id, current_load) do
    GenServer.cast(__MODULE__, {:report_load, node_id, current_load})
  end

  @doc """
  Request pressure redistribution.
  """
  def request_redistribution do
    GenServer.cast(__MODULE__, :request_redistribution)
  end

  @doc """
  Get current field state.
  """
  def get_field_state do
    GenServer.call(__MODULE__, :get_field_state)
  end

  # ── Callbacks ─────────────────────────────────────────────────────────────

  @impl true
  def init(_init_arg) do
    state = %{
      nodes: %{},
      pressure_field: %{},
      diffusion_rate: @default_diffusion_rate,
      rebalancing_timer: nil,
      redistribution_history: []
    }

    Logger.info("🌊 OLEF FieldSupervisor initialized")
    
    timer = Process.send_after(self(), :periodic_rebalancing, @rebalancing_interval_ms)
    
    {:ok, %{state | rebalancing_timer: timer}}
  end

  @impl true
  def handle_call(:get_field_state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_cast({:register_node, node_id, capacity}, state) do
    updated_nodes = Map.put(state.nodes, node_id, %{
      capacity: capacity,
      current_load: 0.0,
      pressure: 0.0,
      registered_at: System.system_time()
    })
    
    Logger.info("🌊 OLEF: Node #{node_id} registered with capacity #{capacity}")
    
    {:noreply, %{state | nodes: updated_nodes}}
  end

  @impl true
  def handle_cast({:inject_rule, rule}, state) do
    Logger.info("🌊 OLEF: Injected rule #{inspect(rule.id)}")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:report_load, node_id, current_load}, state) do
    case Map.get(state.nodes, node_id) do
      nil ->
        Logger.warning("🌊 OLEF: Unknown node #{node_id} reporting load")
        {:noreply, state}
      
      node_info ->
        pressure = current_load / max(node_info.capacity, 0.0001)
        updated_node = %{node_info | current_load: current_load, pressure: pressure}
        updated_nodes = Map.put(state.nodes, node_id, updated_node)
        
        updated_pressure_field = Map.put(state.pressure_field, node_id, pressure)
        
        {:noreply, %{state | nodes: updated_nodes, pressure_field: updated_pressure_field}}
    end
  end

  @impl true
  def handle_cast({:evacuate_pressure, incoming_pressure}, state) do
    Logger.warning("🌊 OLEF: Emergency evacuation triggered with pressure #{incoming_pressure}")
    
    redistributed = redistribute_pressure_across_nodes(state, incoming_pressure)
    
    updated_nodes = merge_redistributed_load(state.nodes, redistributed)
    updated_pressure_field = recalculate_pressure_field(updated_nodes)
    
    history_entry = %{
      type: :emergency_evacuation,
      incoming_pressure: incoming_pressure,
      redistributed_to: map_size(redistributed),
      timestamp: System.system_time()
    }
    
    updated_history = [history_entry | state.redistribution_history] |> Enum.take(50)
    
    {:noreply, %{state | nodes: updated_nodes, pressure_field: updated_pressure_field, redistribution_history: updated_history}}
  end

  @impl true
  def handle_cast({:prepare_evacuation, incoming_pressure}, state) do
    Logger.warning("🌊 OLEF: Preparing for potential evacuation (pressure: #{incoming_pressure})")
    
    prebalance_nodes(state)
    
    {:noreply, state}
  end

  @impl true
  def handle_cast(:request_redistribution, state) do
    Logger.debug("🌊 OLEF: Manual redistribution requested")
    
    rebalanced_state = perform_rebalancing(state)
    
    {:noreply, rebalanced_state}
  end

  @impl true
  def handle_cast(:reset, state) do
    {:noreply, %{state | nodes: %{}, pressure_field: %{}, redistribution_history: []}}
  end

  @impl true
  def handle_info(:periodic_rebalancing, state) do
    Logger.debug("🌊 OLEF: Periodic rebalancing cycle")
    
    rebalanced_state = perform_rebalancing(state)
    
    Process.send_after(self(), :periodic_rebalancing, @rebalancing_interval_ms)
    
    {:noreply, %{rebalanced_state | rebalancing_timer: Process.send_after(self(), :periodic_rebalancing, @rebalancing_interval_ms)}}
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp redistribute_pressure_across_nodes(state, incoming_pressure) do
    total_capacity = Enum.reduce(state.nodes, 0.0, fn {_id, node}, acc ->
      acc + node.capacity
    end)
    
    state.nodes
    |> Enum.map(fn {node_id, node} ->
      proportional_share = node.capacity / max(total_capacity, 0.0001)
      assigned_pressure = incoming_pressure * proportional_share * state.diffusion_rate
      {node_id, assigned_pressure}
    end)
    |> Enum.into(%{})
  end

  defp merge_redistributed_load(nodes, redistributed) do
    Enum.reduce(redistributed, nodes, fn {node_id, extra_load}, acc_nodes ->
      case Map.get(acc_nodes, node_id) do
        nil -> acc_nodes
        node ->
          new_load = node.current_load + extra_load
          updated_node = %{node | current_load: new_load}
          Map.put(acc_nodes, node_id, updated_node)
      end
    end)
  end

  defp recalculate_pressure_field(nodes) do
    Enum.map(nodes, fn {node_id, node} ->
      pressure = node.current_load / max(node.capacity, 0.0001)
      {node_id, pressure}
    end)
    |> Enum.into(%{})
  end

  defp perform_rebalancing(state) do
    Logger.debug("🌊 OLEF: Performing load rebalancing")
    
    pressures = Map.values(state.pressure_field)
    
    if length(pressures) < 2 do
      state
    else
      mean_pressure = Enum.sum(pressures) / length(pressures)
      variance = Enum.sum(Enum.map(pressures, fn p -> (p - mean_pressure) ** 2 end)) / length(pressures)
      std_dev = :math.sqrt(variance)
      
      if std_dev > @equilibrium_tolerance do
        Logger.info("🌊 OLEF: High variance detected (#{std_dev}), applying diffusion")
        apply_diffusion(state, mean_pressure)
      else
        Logger.debug("🌊 OLEF: Field within equilibrium tolerance")
        state
      end
    end
  end

  defp apply_diffusion(state, target_pressure) do
    updated_nodes = Enum.map(state.nodes, fn {node_id, node} ->
      current_pressure = node.current_load / max(node.capacity, 0.0001)
      pressure_diff = target_pressure - current_pressure
      
      adjustment = pressure_diff * state.diffusion_rate
      new_load = node.current_load + (adjustment * node.capacity)
      
      {node_id, %{node | current_load: max(0.0, new_load)}}
    end)
    |> Enum.into(%{})
    
    updated_pressure_field = recalculate_pressure_field(updated_nodes)
    
    history_entry = %{
      type: :diffusion_applied,
      target_pressure: target_pressure,
      timestamp: System.system_time()
    }
    
    updated_history = [history_entry | state.redistribution_history] |> Enum.take(50)
    
    %{state | nodes: updated_nodes, pressure_field: updated_pressure_field, redistribution_history: updated_history}
  end

  defp prebalance_nodes(state) do
    Logger.debug("🌊 OLEF: Pre-balancing nodes for anticipated load")
    
    updated_nodes = Enum.map(state.nodes, fn {node_id, node} ->
      reserved_capacity = node.capacity * 0.2
      available_capacity = node.capacity - node.current_load
      
      if available_capacity < reserved_capacity do
        Logger.warning("🌊 OLEF: Node #{node_id} approaching capacity limit")
      end
      
      {node_id, node}
    end)
    |> Enum.into(%{})
    
    %{state | nodes: updated_nodes}
  end
end
