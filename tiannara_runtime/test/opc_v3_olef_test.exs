defmodule OPCV3OLEFTest do
  use ExUnit.Case, async: true

  alias Tiannara.OPC.V3
  alias Tiannara.OPC.V3.OLEF
  alias Tiannara.OPC.V3.OLEF.{PressureMesh, DistributedObserver, ODEF, RODL, AutonomousFramework}

  describe "OPC v3 OLEF Framework" do
    test "OLEF GenServer starts successfully" do
      # Ensure any existing OLEF process is cleaned up
      if Process.whereis(OLEF) do
        Process.unregister(OLEF)
      end
      
      result = Tiannara.OPC.V3.init_olef()
      assert {:ok, %{status: :olef_initialized}} = result
    end

    test "can apply cognitive pressure through OLEF" do
      # Start OLEF if not already running
      if !Process.whereis(OLEF) do
        Tiannara.OPC.V3.init_olef()
        :timer.sleep(100)  # Allow time for initialization
      end
      
      result = Tiannara.OPC.V3.apply_cognitive_pressure("test_source", 0.5, {5, 5})
      assert result == :ok
    end

    test "can register observers with OLEF" do
      # Start OLEF if not already running
      if !Process.whereis(OLEF) do
        Tiannara.OPC.V3.init_olef()
        :timer.sleep(100)  # Allow time for initialization
      end
      
      observer_spec = %{id: "test_observer", position: {3, 3}}
      result = Tiannara.OPC.V3.register_observer(observer_spec)
      assert is_tuple(result)
    end

    test "PressureMesh creates valid mesh structure" do
      mesh = PressureMesh.new({5, 5})
      
      assert mesh.mesh_dimensions == {5, 5}
      assert is_map(mesh.nodes)
      assert is_list(mesh.connections)
      assert is_map(mesh.pressure_values)
    end

    test "DistributedObserver creation and observation" do
      observer = DistributedObserver.new(%{id: "obs_1", position: {2, 2}})
      
      pressure_field = %{{2, 2} => 0.8, {3, 3} => 0.2}
      observed = DistributedObserver.observe(observer, pressure_field)
      
      assert observed.id == "obs_1"
      assert Map.get(observed.state, :last_observation) != nil
    end

    test "ODEF executes observer dynamics" do
      config = %{
        mesh_dimensions: {10, 10},
        initial_observers: [
          %{id: "dyn_obs_1", position: {3, 3}},
          %{id: "dyn_obs_2", position: {7, 7}}
        ]
      }
      
      odef = ODEF.new(config)
      stepped_odef = ODEF.execute_step(odef)
      
      assert stepped_odef.execution_state.step_counter == 1
    end

    test "RODL compiles and executes definitions" do
      # Create a simple observer definition
      observer_def = 
        RODL.define_observer("simple_obs", {5, 5}, %{pressure_sensitivity: 1.0})
        |> RODL.add_behavior(:pressure_response, %{threshold: 0.3})
      
      rodl = RODL.new([observer_def])
      
      # Create initial state
      mesh = PressureMesh.new({10, 10})
      observers = [DistributedObserver.new(%{id: "env_obs", position: {4, 4}})]
      
      # Activate and execute
      activated = RODL.activate(rodl, mesh, observers)
      stepped = RODL.execute_step(activated)
      
      assert stepped.runtime_context.active == true
    end

    test "AutonomousFramework runs without central runtime" do
      # Create framework with minimal config
      framework = AutonomousFramework.new(%{
        mesh_dimensions: {8, 8},
        initial_observers: [
          %{id: "autonomous_1", position: {2, 2}},
          %{id: "autonomous_2", position: {6, 6}}
        ]
      })
      
      initialized_framework = AutonomousFramework.initialize(framework)
      
      # Execute one step
      stepped_framework = AutonomousFramework.execute_step(initialized_framework)
      
      assert stepped_framework.distributed_state.step_counter == 1
    end

    test "OLEF eliminates need for central runtime" do
      # This test demonstrates the key concept from the requirement:
      # How ODEF + RODL together eliminate the need for any central runtime
      result = Tiannara.OPC.V3.demonstrate_autonomous_physics()
      
      assert is_map(result)
      assert result.autonomous_execution == true
      assert is_integer(result.steps_executed)
    end
  end
end