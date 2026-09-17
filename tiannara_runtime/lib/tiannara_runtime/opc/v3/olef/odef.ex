defmodule Tiannara.OPC.V3.OLEF.ODEF do
  @moduledoc """
  Observer Dynamics Execution Framework (ODEF)
  Provides autonomous execution capabilities for observer physics
  Works with RODL to eliminate need for central runtime
  """

  alias Tiannara.OPC.V3.OLEF.{DistributedObserver, PressureMesh}
  alias Tiannara.OPC.V3.OLEF.RODL

  defstruct [
    :observers,
    :mesh,
    :dynamics_rules,
    :execution_state,
    :distributed_registry
  ]

  @type t :: %__MODULE__{
    observers: list(DistributedObserver.t()),
    mesh: PressureMesh.t(),
    dynamics_rules: list(map()),
    execution_state: map(),
    distributed_registry: map()
  }

  @doc """
  Creates a new ODEF instance with initial configuration
  """
  def new(config \\ %{}) do
    observers = Map.get(config, :observers, [])
    mesh = Map.get(config, :mesh, PressureMesh.new())
    dynamics_rules = Map.get(config, :dynamics_rules, default_dynamics_rules())
    
    %__MODULE__{
      observers: observers,
      mesh: mesh,
      dynamics_rules: dynamics_rules,
      execution_state: %{
        paused: false,
        step_counter: 0,
        last_execution: System.os_time(:millisecond)
      },
      distributed_registry: %{}
    }
  end

  defp default_dynamics_rules do
    [
      %{
        name: :pressure_propagation,
        condition: fn mesh, _state -> 
          # Check if there's any pressure in the mesh
          pressure_values = PressureMesh.calculate_pressure_field(mesh)
          map_size(pressure_values) > 0
        end,
        action: &apply_pressure_propagation/1,
        priority: 1
      },
      %{
        name: :equilibrium_check,
        condition: fn mesh, state -> 
          (System.os_time(:millisecond) - Map.get(state, :last_equilibrium_check, 0)) > 100
        end,
        action: &check_equilibrium/1,
        priority: 2
      },
      %{
        name: :observer_sync,
        condition: fn _mesh, state -> 
          rem(Map.get(state, :step_counter, 0), 5) == 0
        end,
        action: &sync_observers/1,
        priority: 3
      }
    ]
  end

  @doc """
  Executes one step of observer dynamics
  """
  def execute_step(%__MODULE__{} = odef) do
    updated_state = Map.update!(odef.execution_state, :step_counter, &(&1 + 1))
    
    # Apply dynamics rules in priority order
    updated_odef = 
      odef
      |> apply_dynamics_rules()
      |> update_observer_states()
      |> synchronize_observers()
    
    %{updated_odef | execution_state: updated_state}
  end

  defp apply_dynamics_rules(%__MODULE__{} = odef) do
    # Sort rules by priority
    sorted_rules = Enum.sort_by(odef.dynamics_rules, &(&1.priority))
    
    # Apply each rule if its condition is met
    Enum.reduce(sorted_rules, odef, fn rule, acc_odef ->
      if rule.condition.(acc_odef.mesh, acc_odef.execution_state) do
        rule.action.(acc_odef)
      else
        acc_odef
      end
    end)
  end

  defp apply_pressure_propagation(odef) do
    # Apply any pending pressure updates to the mesh
    # This would typically come from external sources or observer actions
    odef  # In this simplified version, we'll return as is
  end

  defp check_equilibrium(odef) do
    equilibrium = PressureMesh.check_equilibrium(odef.mesh, 0.001)
    
    updated_state = Map.put(odef.execution_state, :last_equilibrium_check, System.os_time(:millisecond))
    updated_state = Map.put(updated_state, :equilibrium_state, equilibrium)
    
    %{odef | execution_state: updated_state}
  end

  defp sync_observers(odef) do
    # Synchronize observer states with current mesh
    pressure_field = PressureMesh.calculate_pressure_field(odef.mesh)
    
    updated_observers = 
      Enum.map(odef.observers, fn observer ->
        DistributedObserver.observe(observer, pressure_field)
      end)
    
    %{odef | observers: updated_observers}
  end

  defp update_observer_states(%__MODULE__{} = odef) do
    # Update each observer's state based on current conditions
    pressure_field = PressureMesh.calculate_pressure_field(odef.mesh)
    
    updated_observers = 
      Enum.map(odef.observers, fn observer ->
        # Apply observer-specific behaviors based on pressure field
        current_pressure = PressureMesh.get_pressure_at(odef.mesh, observer.position)
        
        # Update observer state with current pressure reading
        state_update = %{
          current_pressure: current_pressure,
          last_updated: System.os_time(:millisecond)
        }
        
        DistributedObserver.update_state(observer, state_update)
      end)
    
    %{odef | observers: updated_observers}
  end

  defp synchronize_observers(%__MODULE__{} = odef) do
    # Handle observer-to-observer communication and synchronization
    _pressure_field = PressureMesh.calculate_pressure_field(odef.mesh)
    
    updated_observers = 
      Enum.with_index(odef.observers)
      |> Enum.map(fn {observer, _index} ->
        # Connect observers to their neighbors
        neighboring_positions = get_neighbor_positions(observer.position)
        
        updated_observer = 
          Enum.reduce(neighboring_positions, observer, fn pos, obs ->
            # Find observer at neighboring position and establish connection
            case Enum.find(odef.observers, &(elem(&1.position, 0) == elem(pos, 0) and elem(&1.position, 1) == elem(pos, 1))) do
              nil -> obs  # No neighbor at this position
              neighbor -> DistributedObserver.connect_to(obs, neighbor.id)
            end
          end)
        
        updated_observer
      end)
    
    %{odef | observers: updated_observers}
  end

  defp get_neighbor_positions({x, y}) do
    [
      {x+1, y},   # right
      {x-1, y},   # left
      {x, y+1},   # down
      {x, y-1}    # up
    ]
  end

  @doc """
  Registers a new observer with the ODEF system
  """
  def register_observer(%__MODULE__{} = odef, observer_spec) do
    new_observer = DistributedObserver.new(observer_spec)
    updated_observers = [new_observer | odef.observers]
    
    %{odef | observers: updated_observers}
  end

  @doc """
  Removes an observer from the system
  """
  def remove_observer(%__MODULE__{} = odef, observer_id) do
    updated_observers = Enum.reject(odef.observers, &(&1.id == observer_id))
    %{odef | observers: updated_observers}
  end

  @doc """
  Applies pressure to the mesh through ODEF
  """
  def apply_pressure(%__MODULE__{} = odef, source_id, pressure_value, coordinates) do
    updated_mesh = PressureMesh.apply_pressure(odef.mesh, source_id, pressure_value, coordinates)
    %{odef | mesh: updated_mesh}
  end

  @doc """
  Executes ODEF continuously (autonomous mode)
  """
  def execute_continuously(%__MODULE__{} = odef, duration_ms \\ :infinity) do
    start_time = System.os_time(:millisecond)
    
    execute_loop(odef, start_time, duration_ms)
  end

  defp execute_loop(odef, start_time, :infinity) do
    # Infinite loop - execute step and continue
    updated_odef = execute_step(odef)
    
    # Check if execution should pause
    if Map.get(updated_odef.execution_state, :paused, false) do
      Process.sleep(10)  # Small delay to prevent busy waiting
      execute_loop(updated_odef, start_time, :infinity)
    else
      execute_loop(updated_odef, start_time, :infinity)
    end
  end

  defp execute_loop(odef, start_time, duration_ms) when is_integer(duration_ms) do
    current_time = System.os_time(:millisecond)
    
    if current_time - start_time < duration_ms do
      updated_odef = execute_step(odef)
      
      # Check if execution should pause
      if Map.get(updated_odef.execution_state, :paused, false) do
        Process.sleep(10)  # Small delay to prevent busy waiting
        execute_loop(updated_odef, start_time, duration_ms)
      else
        execute_loop(updated_odef, start_time, duration_ms)
      end
    else
      odef  # Time limit reached
    end
  end

  @doc """
  Pauses ODEF execution
  """
  def pause(%__MODULE__{} = odef) do
    updated_state = Map.put(odef.execution_state, :paused, true)
    %{odef | execution_state: updated_state}
  end

  @doc """
  Resumes ODEF execution
  """
  def resume(%__MODULE__{} = odef) do
    updated_state = Map.put(odef.execution_state, :paused, false)
    %{odef | execution_state: updated_state}
  end

  @doc """
  Gets current execution statistics
  """
  def get_statistics(%__MODULE__{} = odef) do
    %{
      step_count: odef.execution_state.step_counter,
      observer_count: length(odef.observers),
      mesh_dimensions: odef.mesh.mesh_dimensions,
      equilibrium_state: Map.get(odef.execution_state, :equilibrium_state, :unknown),
      active_connections: count_active_connections(odef.observers)
    }
  end

  defp count_active_connections(observers) do
    Enum.reduce(observers, 0, fn observer, acc ->
      acc + length(observer.connected_observers)
    end)
  end
end
