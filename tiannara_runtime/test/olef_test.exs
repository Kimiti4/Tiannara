defmodule Tiannara.OLEFTest do
  use ExUnit.Case, async: false
  
  alias Tiannara.OLEF.FieldSupervisor
  alias Tiannara.OLEF.PressureSolver
  alias Tiannara.OLEF.GradientRouter
  alias Tiannara.OLEF.DiffusionModel
  alias Tiannara.OLEF.NodeRegistry

  describe "FieldSupervisor" do
    setup do
      pid =
        case FieldSupervisor.start_link([]) do
          {:ok, pid} -> pid
          {:error, {:already_started, pid}} -> pid
        end
      GenServer.cast(FieldSupervisor, :reset)
      %{pid: pid}
    end

    test "starts successfully", %{pid: pid} do
      assert is_pid(pid)
    end

    test "registers nodes with capacity" do
      FieldSupervisor.register_node("node_1", 100.0)
      FieldSupervisor.register_node("node_2", 200.0)
      
      {:ok, state} = FieldSupervisor.get_field_state()
      assert map_size(state.nodes) == 2
      assert Map.get(state.nodes, "node_1").capacity == 100.0
    end

    test "reports load and calculates pressure" do
      FieldSupervisor.register_node("node_1", 100.0)
      FieldSupervisor.report_load("node_1", 50.0)
      
      {:ok, state} = FieldSupervisor.get_field_state()
      node = Map.get(state.nodes, "node_1")
      assert node.current_load == 50.0
      assert node.pressure == 0.5
    end

    test "handles evacuation requests" do
      FieldSupervisor.register_node("node_1", 100.0)
      FieldSupervisor.register_node("node_2", 100.0)
      
      FieldSupervisor.request_redistribution()
      
      {:ok, state} = FieldSupervisor.get_field_state()
      assert map_size(state.nodes) == 2
    end

    test "tracks redistribution history" do
      FieldSupervisor.register_node("node_1", 100.0)
      FieldSupervisor.request_redistribution()
      
      {:ok, state} = FieldSupervisor.get_field_state()
      assert is_list(state.redistribution_history)
    end
  end

  describe "PressureSolver" do
    test "computes gradients for uniform field" do
      field = %{"node_1" => 0.5, "node_2" => 0.5, "node_3" => 0.5}
      neighborhood = %{
        "node_1" => ["node_2"],
        "node_2" => ["node_1", "node_3"],
        "node_3" => ["node_2"]
      }
      
      gradients = PressureSolver.compute_gradient(field, neighborhood)
      
      assert Map.has_key?(gradients, "node_1")
      assert Map.has_key?(gradients, "node_2")
      assert Map.has_key?(gradients, "node_3")
    end

    test "normalizes field to [0, 1] range" do
      field = %{"a" => 10.0, "b" => 20.0, "c" => 30.0}
      
      normalized = PressureSolver.normalize(field)
      
      values = Map.values(normalized)
      assert Enum.min(values) >= 0.0
      assert Enum.max(values) <= 1.0
    end

    test "applies diffusion step" do
      field = %{"node_1" => 0.8, "node_2" => 0.2}
      neighborhood = %{"node_1" => ["node_2"], "node_2" => ["node_1"]}
      
      diffused = PressureSolver.apply_diffusion(field, neighborhood, 0.12)
      
      assert Map.has_key?(diffused, "node_1")
      assert Map.has_key?(diffused, "node_2")
    end

    test "finds equilibrium through iteration" do
      field = %{"a" => 1.0, "b" => 0.0}
      neighborhood = %{"a" => ["b"], "b" => ["a"]}
      
      {:converged, converged?, final_field, iterations} = 
        PressureSolver.find_equilibrium(field, neighborhood, 100, 0.01)
      
      assert is_boolean(converged?)
      assert is_map(final_field)
      assert is_integer(iterations)
    end

    test "calculates total pressure" do
      field = %{"a" => 0.5, "b" => 0.3, "c" => 0.2}
      
      total = PressureSolver.total_pressure(field)
      assert total == 1.0
    end

    test "identifies hotspots above threshold" do
      field = %{"high_1" => 0.9, "high_2" => 0.95, "low" => 0.3}
      
      hotspots = PressureSolver.identify_hotspots(field, 0.85)
      
      assert map_size(hotspots) == 2
      assert Map.has_key?(hotspots, "high_1")
      assert Map.has_key?(hotspots, "high_2")
    end
  end

  describe "GradientRouter" do
    test "routes task to lowest pressure node" do
      pressure_field = %{"node_1" => 0.8, "node_2" => 0.2, "node_3" => 0.5}
      node_capacities = %{"node_1" => 100, "node_2" => 100, "node_3" => 100}
      task_reqs = %{min_capacity: 50}
      
      {:ok, selected} = GradientRouter.route_task(task_reqs, pressure_field, node_capacities)
      assert selected == "node_2"
    end

    test "returns error when no eligible nodes" do
      pressure_field = %{"node_1" => 0.5}
      node_capacities = %{"node_1" => 10}
      task_reqs = %{min_capacity: 100}
      
      result = GradientRouter.route_task(task_reqs, pressure_field, node_capacities)
      assert elem(result, 0) == :error
    end

    test "calculates routing weights" do
      pressure_field = %{"node_1" => 0.8, "node_2" => 0.2}
      
      weights = GradientRouter.calculate_routing_weights(pressure_field)
      
      assert Map.has_key?(weights, "node_1")
      assert Map.has_key?(weights, "node_2")
      
      total_weight = Enum.sum(Map.values(weights))
      assert_in_delta total_weight, 1.0, 0.01
    end

    test "suggests migrations for imbalanced field" do
      pressure_field = %{
        "overloaded" => 0.9,
        "balanced" => 0.5,
        "underloaded" => 0.2
      }
      
      migrations = GradientRouter.suggest_migrations(pressure_field, 0.3)
      
      assert is_list(migrations)
      if length(migrations) > 0 do
        migration = hd(migrations)
        assert Map.has_key?(migration, :from)
        assert Map.has_key?(migration, :to)
        assert Map.has_key?(migration, :pressure_delta)
      end
    end
  end

  describe "DiffusionModel" do
    test "runs standard diffusion" do
      field = %{"a" => 1.0, "b" => 0.0}
      neighborhood = %{"a" => ["b"], "b" => ["a"]}
      
      diffused = DiffusionModel.standard_diffusion(field, neighborhood, 0.12, 1)
      
      assert is_map(diffused)
      assert map_size(diffused) == 2
    end

    test "runs adaptive diffusion" do
      field = %{"a" => 1.0, "b" => 0.0}
      neighborhood = %{"a" => ["b"], "b" => ["a"]}
      
      diffused = DiffusionModel.adaptive_diffusion(field, neighborhood, 0.12, 1)
      
      assert is_map(diffused)
      assert map_size(diffused) == 2
    end

    test "simulates diffusion over time" do
      field = %{"a" => 1.0, "b" => 0.0}
      neighborhood = %{"a" => ["b"], "b" => ["a"]}
      
      simulation = DiffusionModel.simulate_diffusion(field, neighborhood, 5, :standard)
      
      assert is_list(simulation)
      assert length(simulation) == 5
      
      first_step = hd(simulation)
      assert Map.has_key?(first_step, :step)
      assert Map.has_key?(first_step, :field)
      assert Map.has_key?(first_step, :total_pressure)
    end

    test "calculates diffusion efficiency" do
      uniform_field = %{"a" => 0.5, "b" => 0.5, "c" => 0.5}
      varied_field = %{"a" => 1.0, "b" => 0.0, "c" => 0.5}
      
      efficiency_uniform = DiffusionModel.calculate_efficiency(uniform_field)
      efficiency_varied = DiffusionModel.calculate_efficiency(varied_field)
      
      assert efficiency_uniform > efficiency_varied
      assert efficiency_uniform >= 0.0
      assert efficiency_uniform <= 1.0
    end
  end

  describe "NodeRegistry" do
    setup do
      pid =
        case NodeRegistry.start_link([]) do
          {:ok, pid} -> pid
          {:error, {:already_started, pid}} -> pid
        end
      GenServer.cast(NodeRegistry, :reset)
      %{pid: pid}
    end

    test "registers nodes with metadata", %{pid: _pid} do
      NodeRegistry.register_node("node_1", %{type: :compute, region: "us-east"})
      
      {:ok, details} = NodeRegistry.get_node_details("node_1")
      assert details.id == "node_1"
      assert details.status == :active
      assert details.metadata.type == :compute
    end

    test "unregisters nodes", %{pid: _pid} do
      NodeRegistry.register_node("node_1", %{})
      NodeRegistry.unregister_node("node_1")
      
      result = NodeRegistry.get_node_details("node_1")
      assert elem(result, 0) == :error
    end

    test "updates node health status", %{pid: _pid} do
      NodeRegistry.register_node("node_1", %{})
      NodeRegistry.update_health("node_1", :degraded)
      
      {:ok, details} = NodeRegistry.get_node_details("node_1")
      assert details.health == :degraded
    end

    test "gets all active nodes", %{pid: _pid} do
      NodeRegistry.register_node("node_1", %{})
      NodeRegistry.register_node("node_2", %{})
      
      {:ok, active} = NodeRegistry.get_active_nodes()
      assert map_size(active) == 2
    end

    test "maintains neighborhood topology", %{pid: _pid} do
      NodeRegistry.register_node("node_1", %{})
      NodeRegistry.register_node("node_2", %{})
      NodeRegistry.register_node("node_3", %{})
      
      {:ok, neighborhoods} = NodeRegistry.get_neighborhood_map()
      assert map_size(neighborhoods) == 3
    end

    test "returns error for unknown node", %{pid: _pid} do
      result = NodeRegistry.get_node_details("nonexistent")
      assert elem(result, 0) == :error
      assert elem(result, 1) == :node_not_found
    end
  end
end
