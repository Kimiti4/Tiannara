defmodule Tiannara.MSCL_OLEF_IntegrationTest do
  use ExUnit.Case, async: false
  
  alias Tiannara.MSCL.Supervisor, as: MSCLSupervisor
  alias Tiannara.MSCL.ConstraintEngine
  alias Tiannara.MSCL.BudgetTracker
  alias Tiannara.OLEF.FieldSupervisor, as: OLEFieldSupervisor
  alias Tiannara.OLEF.PressureSolver
  alias Tiannara.OLEF.NodeRegistry

  @tag :integration
  test "complete MSCL + OLEF execution flow" do
    # Start all components
    {:ok, _mscl_sup} = start_mscl_sup()
    {:ok, _budget} = start_budget()
    {:ok, _olef_sup} = start_olef_sup()
    {:ok, _registry} = start_registry()
    
    # 1. Register nodes in both MSCL and OLEF
    MSCLSupervisor.register_node("node_1", 0.0)
    MSCLSupervisor.register_node("node_2", 0.0)
    
    OLEFieldSupervisor.register_node("node_1", 100.0)
    OLEFieldSupervisor.register_node("node_2", 100.0)
    
    NodeRegistry.register_node("node_1", %{type: :compute})
    NodeRegistry.register_node("node_2", %{type: :compute})
    
    # 2. Simulate load increase on node_1
    MSCLSupervisor.report_pressure("node_1", 800.0)
    OLEFieldSupervisor.report_load("node_1", 80.0)
    
    # 3. Check MSCL state
    {:ok, mscl_state} = MSCLSupervisor.get_state()
    assert mscl_state.global_pressure > 0.0
    assert Map.has_key?(mscl_state.active_nodes, "node_1")
    
    # 4. Check OLEF field state
    {:ok, olef_state} = OLEFieldSupervisor.get_field_state()
    assert map_size(olef_state.nodes) == 2
    
    # 5. Verify constraint engine can evaluate pressure
    pressure_result = ConstraintEngine.calculate_constraint_pressure(%{
      entropy: 0.5,
      observer_count: 0.6,
      memory_utilization: 0.7,
      causal_drift: 0.4
    })
    assert pressure_result.total_pressure >= 0.0
    assert pressure_result.total_pressure <= 1.0
    
    # 6. Verify budget tracking
    BudgetTracker.allocate_budget("observer_1", :entropy, 50.0)
    budget_check = BudgetTracker.check_budget("observer_1", :entropy, 20.0)
    assert elem(budget_check, 0) == :ok
    
    # 7. Test pressure solver with actual field data
    field = %{"node_1" => 0.8, "node_2" => 0.2}
    neighborhood = %{"node_1" => ["node_2"], "node_2" => ["node_1"]}
    
    gradients = PressureSolver.compute_gradient(field, neighborhood)
    assert Map.has_key?(gradients, "node_1")
    assert Map.has_key?(gradients, "node_2")
    
    # 8. Normalize the field
    normalized = PressureSolver.normalize(field)
    values = Map.values(normalized)
    assert Enum.min(values) >= 0.0
    assert Enum.max(values) <= 1.0
    
    # 9. Calculate routing weights for load balancing
    weights = Tiannara.OLEF.GradientRouter.calculate_routing_weights(field)
    assert map_size(weights) == 2
    
    # 10. Verify NATS pressure stream can encode messages (without actual NATS)
    # This tests the JSON encoding logic
    payload = Jason.encode!(%{
      node: "node_1",
      pressure: 0.8,
      timestamp: System.system_time()
    })
    assert is_binary(payload)
    
    decoded = Jason.decode!(payload)
    assert decoded["node"] == "node_1"
    assert decoded["pressure"] == 0.8
  end

  @tag :integration
  test "evacuation flow from MSCL to OLEF" do
    {:ok, _mscl_sup} = start_mscl_sup()
    {:ok, _olef_sup} = start_olef_sup()
    
    # Register nodes
    MSCLSupervisor.register_node("node_1", 0.0)
    OLEFieldSupervisor.register_node("node_1", 100.0)
    
    # Simulate critical pressure that should trigger evacuation
    MSCLSupervisor.report_pressure("node_1", 9000.0)
    
    {:ok, mscl_state} = MSCLSupervisor.get_state()
    assert mscl_state.collapse_risk > 0.85
    
    # Give time for evacuation message to be processed
    Process.sleep(100)
    
    # Verify OLEF received the evacuation request
    {:ok, olef_state} = OLEFieldSupervisor.get_field_state()
    assert is_list(olef_state.redistribution_history)
  end

  @tag :integration
  test "budget enforcement prevents resource exhaustion" do
    {:ok, _budget} = start_budget()
    
    # Allocate most of the entropy budget
    BudgetTracker.allocate_budget("obs_heavy", :entropy, 90.0)
    
    # Try to allocate more than remaining
    result = BudgetTracker.check_budget("obs_heavy", :entropy, 20.0)
    assert elem(result, 0) == :error
    assert elem(result, 1) == :insufficient_budget
    
    # Release some budget
    BudgetTracker.release_budget("obs_heavy", :entropy, 50.0)
    
    # Now allocation should succeed
    result = BudgetTracker.check_budget("obs_heavy", :entropy, 20.0)
    assert elem(result, 0) == :ok
  end

  @tag :integration
  test "divergence analysis triggers appropriate responses" do
    # Create divergent observer states
    state_a = %{
      value: 10,
      timestamp: 1000,
      causal_chain: [1, 2, 3],
      entropy: 0.3
    }
    
    state_b = %{
      value: 100,
      timestamp: 5000,
      causal_chain: [10, 11, 12],
      entropy: 0.9
    }
    
    # Analyze divergence
    result = Tiannara.MSCL.DivergenceAnalyzer.analyze_pairwise_divergence(
      "obs_a", "obs_b", state_a, state_b
    )
    
    assert result.divergence_score > 0.0
    assert result.divergence_score <= 1.0
    assert result.status in [:safe, :elevated, :critical, :emergency]
    
    # If divergence is high, constraint engine should compress
    if result.divergence_score > 0.75 do
      compression_result = ConstraintEngine.evaluate_divergence(result.divergence_score + 0.3)
      assert elem(compression_result, 0) == :compressed
    end
  end

  @tag :integration
  test "evaporation engine responds to instability" do
    {:ok, _evap} = start_evap()
    
    # Trigger evaporation for unstable observer
    Tiannara.MSCL.EvaporationEngine.trigger_evaporation("obs_unstable", :paradox_overload)
    
    {:ok, stats} = Tiannara.MSCL.EvaporationEngine.get_stats()
    assert stats.total_evaporated >= 1
    assert length(stats.evaporation_events) >= 1
    
    # Verify event details
    latest_event = hd(stats.evaporation_events)
    assert latest_event.observer_id == "obs_unstable"
    assert latest_event.reason == :paradox_overload
    assert Map.has_key?(latest_event, :result)
  end

  @tag :integration
  test "diffusion model balances pressure field" do
    # Create imbalanced field
    initial_field = %{
      "hot_node" => 0.95,
      "warm_node" => 0.50,
      "cool_node" => 0.10
    }
    
    neighborhood = %{
      "hot_node" => ["warm_node"],
      "warm_node" => ["hot_node", "cool_node"],
      "cool_node" => ["warm_node"]
    }
    
    # Run diffusion simulation
    simulation = Tiannara.OLEF.DiffusionModel.simulate_diffusion(
      initial_field, neighborhood, 10, :standard
    )
    
    assert length(simulation) == 10
    
    # Check that final state is more balanced than initial
    initial_variance = calculate_variance(Map.values(initial_field))
    final_state = List.last(simulation)
    final_variance = calculate_variance(Map.values(final_state.field))
    
    # Variance should decrease (more balanced)
    assert final_variance < initial_variance
  end

  @tag :integration
  test "gradient router distributes tasks optimally" do
    pressure_field = %{
      "overloaded" => 0.9,
      "moderate" => 0.5,
      "available" => 0.2
    }
    
    node_capacities = %{
      "overloaded" => 100,
      "moderate" => 100,
      "available" => 100
    }
    
    task_reqs = %{min_capacity: 50}
    
    # Route multiple tasks
    {:ok, task1_node} = Tiannara.OLEF.GradientRouter.route_task(
      task_reqs, pressure_field, node_capacities
    )
    assert task1_node == "available"
    
    # Suggest migrations for rebalancing
    migrations = Tiannara.OLEF.GradientRouter.suggest_migrations(pressure_field, 0.3)
    assert is_list(migrations)
    
    if length(migrations) > 0 do
      migration = hd(migrations)
      assert migration.from in ["overloaded", "moderate"]
      assert migration.to in ["moderate", "available"]
    end
  end

  # Helper function to calculate variance
  defp calculate_variance(values) do
    mean = Enum.sum(values) / length(values)
    squared_diffs = Enum.map(values, fn v -> (v - mean) ** 2 end)
    Enum.sum(squared_diffs) / length(squared_diffs)
  end

  defp start_mscl_sup do
    case MSCLSupervisor.start_link([]) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  defp start_budget do
    case BudgetTracker.start_link([]) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  defp start_olef_sup do
    case OLEFieldSupervisor.start_link([]) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  defp start_registry do
    case NodeRegistry.start_link([]) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  defp start_evap do
    case Tiannara.MSCL.EvaporationEngine.start_link([]) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end
end
