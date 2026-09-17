defmodule Tiannara.OPC.V3.OLEF.AutonomousFramework do
  @moduledoc """
  Autonomous Framework demonstrating how ODEF + RODL eliminate need for central runtime
  Shows distributed observer physics without centralized control
  """

  alias Tiannara.OPC.V3.OLEF.{ODEF, RODL, DistributedObserver, PressureMesh}

  defstruct [
    :odef,
    :rodl,
    :local_registry,
    :distributed_state
  ]

  @type t :: %__MODULE__{
    odef: ODEF.t(),
    rodl: RODL.t(),
    local_registry: map(),
    distributed_state: map()
  }

  @doc """
  Creates an autonomous framework instance
  """
  def new(config \\ %{}) do
    # Create initial mesh and observers
    mesh = PressureMesh.new(Map.get(config, :mesh_dimensions, {10, 10}))
    
    initial_observers = 
      Map.get(config, :initial_observers, [])
      |> Enum.map(&DistributedObserver.new/1)
    
    # Create ODEF with initial setup
    odef = ODEF.new(%{
      mesh: mesh,
      observers: initial_observers
    })
    
    # Create RODL with default definitions
    rodl = RODL.new(Map.get(config, :rodl_definitions, []))
    
    %__MODULE__{
      odef: odef,
      rodl: rodl,
      local_registry: %{},
      distributed_state: %{
        initialized: false,
        step_counter: 0,
        peer_nodes: Map.get(config, :peer_nodes, [])
      }
    }
  end

  @doc """
  Initializes the autonomous system
  """
  def initialize(%__MODULE__{} = framework) do
    # Activate RODL with current state
    activated_rodl = RODL.activate(framework.rodl, framework.odef.mesh, framework.odef.observers)
    
    # Update distributed state
    updated_state = %{
      initialized: true,
      step_counter: 0,
      peer_nodes: framework.distributed_state.peer_nodes
    }
    
    %{
      framework |
      rodl: activated_rodl,
      distributed_state: updated_state
    }
  end

  @doc """
  Executes one autonomous step without central coordination
  """
  def execute_step(%__MODULE__{} = framework) do
    # Get current state from ODEF
    current_mesh = framework.odef.mesh
    current_observers = framework.odef.observers
    
    # Execute RODL rules
    {updated_mesh, updated_observers} = RODL.execute_rules(framework.rodl, current_mesh, current_observers)
    
    # Update ODEF with results
    updated_odef = 
      framework.odef
      |> Map.put(:mesh, updated_mesh)
      |> Map.put(:observers, updated_observers)
    
    # Execute ODEF dynamics
    final_odef = ODEF.execute_step(updated_odef)
    
    # Execute RODL step
    final_rodl = RODL.execute_step(framework.rodl)
    
    # Update step counter
    updated_counter = framework.distributed_state.step_counter + 1
    
    updated_state = %{
      initialized: framework.distributed_state.initialized,
      step_counter: updated_counter,
      peer_nodes: framework.distributed_state.peer_nodes
    }
    
    %{
      framework |
      odef: final_odef,
      rodl: final_rodl,
      distributed_state: updated_state
    }
  end

  @doc """
  Runs the autonomous system continuously
  """
  def run_autonomously(%__MODULE__{} = framework, duration_ms \\ :infinity) do
    start_time = System.os_time(:millisecond)
    
    run_loop(framework, start_time, duration_ms)
  end

  defp run_loop(framework, start_time, :infinity) do
    # Execute one step
    updated_framework = execute_step(framework)
    
    # Check termination conditions (if any)
    if should_terminate?(updated_framework) do
      updated_framework
    else
      # Continue execution
      run_loop(updated_framework, start_time, :infinity)
    end
  end

  defp run_loop(framework, start_time, duration_ms) when is_integer(duration_ms) do
    current_time = System.os_time(:millisecond)
    
    if current_time - start_time < duration_ms do
      # Execute one step
      updated_framework = execute_step(framework)
      
      # Check termination conditions
      if should_terminate?(updated_framework) do
        updated_framework
      else
        # Continue execution
        run_loop(updated_framework, start_time, duration_ms)
      end
    else
      framework  # Time limit reached
    end
  end

  defp should_terminate?(framework) do
    # Check for equilibrium state as termination condition
    equilibrium_reached = PressureMesh.check_equilibrium(framework.odef.mesh, 0.001)
    
    # Or check if step limit reached (if configured)
    max_steps = Application.get_env(:tiannara_runtime, :max_autonomous_steps, :infinity)
    
    case max_steps do
      :infinity -> equilibrium_reached
      limit when is_integer(limit) -> 
        framework.distributed_state.step_counter >= limit or equilibrium_reached
    end
  end

  @doc """
  Registers a local observer definition with the autonomous system
  """
  def register_observer_definition(%__MODULE__{} = framework, definition) do
    updated_rodl = RODL.add_definition(framework.rodl, definition)
    
    %{
      framework |
      rodl: updated_rodl
    }
  end

  @doc """
  Applies external pressure to the autonomous system
  """
  def apply_external_pressure(%__MODULE__{} = framework, source_id, pressure_value, coordinates) do
    updated_odef = ODEF.apply_pressure(framework.odef, source_id, pressure_value, coordinates)
    
    %{
      framework |
      odef: updated_odef
    }
  end

  @doc """
  Checks if the system has reached equilibrium
  """
  def is_equilibrium_reached?(%__MODULE__{} = framework) do
    PressureMesh.check_equilibrium(framework.odef.mesh, 0.001)
  end

  @doc """
  Gets current system statistics
  """
  def get_statistics(%__MODULE__{} = framework) do
    odef_stats = ODEF.get_statistics(framework.odef)
    rodl_state = RODL.get_state(framework.rodl)
    
    pressure_field = PressureMesh.calculate_pressure_field(framework.odef.mesh)
    
    %{
      odef_stats: odef_stats,
      rodl_state: rodl_state,
      pressure_field_stats: calculate_pressure_field_stats(pressure_field),
      step_counter: framework.distributed_state.step_counter,
      equilibrium_reached: is_equilibrium_reached?(framework)
    }
  end

  defp calculate_pressure_field_stats(pressure_field) do
    if map_size(pressure_field) == 0 do
      %{count: 0, avg: 0.0, min: 0.0, max: 0.0}
    else
      pressures = Map.values(pressure_field)
      %{
        count: length(pressures),
        avg: Enum.sum(pressures) / length(pressures),
        min: Enum.min(pressures),
        max: Enum.max(pressures)
      }
    end
  end

  @doc """
  Demonstrates the elimination of central runtime with a complete example
  """
  def demonstrate_no_central_runtime do
    # Create an autonomous framework with initial configuration
    framework_config = %{
      mesh_dimensions: {20, 20},
      initial_observers: [
        %{
          id: "observer_1",
          position: {5, 5},
          capabilities: [:observe, :adapt, :communicate],
          pressure_sensitivity: 1.2
        },
        %{
          id: "observer_2", 
          position: {15, 15},
          capabilities: [:observe, :report],
          pressure_sensitivity: 0.8
        }
      ],
      rodl_definitions: [
        # Adaptive observer that moves away from high pressure
        RODL.define_observer("adaptive_1", {10, 10}, %{
          pressure_sensitivity: 1.0,
          capabilities: [:observe, :adapt]
        })
        |> RODL.add_behavior(:pressure_response, %{threshold: 0.4, sensitivity: 0.9})
        |> RODL.add_trigger(
          {:pressure_above, {10, 10}, 0.6}, 
          {:move_observer, "adaptive_1", {11, 11}}
        )
      ]
    }
    
    # Create and initialize the framework
    framework = new(framework_config) |> initialize()
    
    # Apply some initial pressure to stimulate the system
    framework = apply_external_pressure(framework, "external_stimulus", 0.8, {10, 10})
    
    # Run autonomously for a period of time
    IO.puts("Starting autonomous execution...")
    
    # Execute 100 steps of autonomous operation
    final_framework = 
      Enum.reduce(1..100, framework, fn _, acc_framework ->
        execute_step(acc_framework)
      end)
    
    # Get final statistics
    stats = get_statistics(final_framework)
    
    IO.puts("Autonomous execution completed.")
    IO.inspect(stats, label: "Final Statistics")
    
    # Verify that the system operated without central coordination
    %{
      autonomous_execution: true,
      steps_executed: stats.step_counter,
      equilibrium_reached: stats.equilibrium_reached,
      observers_active: stats.odef_stats.observer_count,
      pressure_distribution: stats.pressure_field_stats
    }
  end
end
