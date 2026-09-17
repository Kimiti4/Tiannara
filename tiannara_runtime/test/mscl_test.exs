defmodule Tiannara.MSCLTest do
  use ExUnit.Case, async: false
  
  alias Tiannara.MSCL.Supervisor
  alias Tiannara.MSCL.ConstraintEngine
  alias Tiannara.MSCL.BudgetTracker
  alias Tiannara.MSCL.DivergenceAnalyzer
  alias Tiannara.MSCL.EvaporationEngine

  describe "MSCL Supervisor" do
    setup do
      pid =
        case Supervisor.start_link([]) do
          {:ok, pid} -> pid
          {:error, {:already_started, pid}} -> pid
        end
      GenServer.cast(Supervisor, :reset)
      %{pid: pid}
    end

    test "starts successfully", %{pid: pid} do
      assert is_pid(pid)
    end

    test "registers and tracks nodes" do
      Supervisor.register_node("node_1", 50.0)
      Supervisor.register_node("node_2", 75.0)
      
      {:ok, state} = Supervisor.get_state()
      assert map_size(state.active_nodes) == 2
      assert Map.has_key?(state.active_nodes, "node_1")
      assert Map.has_key?(state.active_nodes, "node_2")
    end

    test "reports pressure from nodes" do
      Supervisor.register_node("node_1", 0.0)
      Supervisor.report_pressure("node_1", 100.0)
      
      {:ok, state} = Supervisor.get_state()
      assert state.global_pressure > 0.0
      assert Map.get(state.active_nodes, "node_1") == 100.0
    end

    test "calculates collapse risk correctly" do
      Supervisor.register_node("node_1", 0.0)
      Supervisor.report_pressure("node_1", 8500.0)
      
      {:ok, state} = Supervisor.get_state()
      assert state.collapse_risk > 0.8
      assert state.collapse_risk <= 1.0
    end

    test "unregisters nodes properly" do
      Supervisor.register_node("node_1", 100.0)
      Supervisor.unregister_node("node_1")
      
      {:ok, state} = Supervisor.get_state()
      refute Map.has_key?(state.active_nodes, "node_1")
    end
  end

  describe "ConstraintEngine" do
    test "evaluates stable divergence" do
      result = ConstraintEngine.evaluate_divergence(0.5)
      assert elem(result, 0) == :stable
      assert elem(result, 1) == 0.5
    end

    test "compresses excessive divergence" do
      result = ConstraintEngine.evaluate_divergence(1.5)
      assert elem(result, 0) == :compressed
      assert elem(result, 1) < 1.0
    end

    test "enforces budget within limits" do
      result = ConstraintEngine.enforce_budget(500.0, 1000.0)
      assert elem(result, 0) == :ok
    end

    test "rejects budget exceeding limits" do
      result = ConstraintEngine.enforce_budget(1500.0, 1000.0)
      assert elem(result, 0) == :error
      assert elem(result, 1) == :budget_exceeded
    end

    test "calculates constraint pressure from factors" do
      factors = %{
        entropy: 0.8,
        observer_count: 0.6,
        memory_utilization: 0.7,
        causal_drift: 0.5
      }
      
      result = ConstraintEngine.calculate_constraint_pressure(factors)
      assert result.total_pressure >= 0.0
      assert result.total_pressure <= 1.0
      assert Map.has_key?(result, :components)
      assert Map.has_key?(result, :status)
    end

    test "applies emergency constraints" do
      result = ConstraintEngine.apply_emergency_constraints(%{})
      assert Map.has_key?(result, :actions_taken)
      assert length(result.actions_taken) > 0
    end
  end

  describe "BudgetTracker" do
    setup do
      pid =
        case BudgetTracker.start_link([]) do
          {:ok, pid} -> pid
          {:error, {:already_started, pid}} -> pid
        end
      GenServer.cast(BudgetTracker, :reset)
      %{pid: pid}
    end

    test "checks budget availability", %{pid: _pid} do
      result = BudgetTracker.check_budget("obs_1", :entropy, 50.0)
      assert elem(result, 0) == :ok
    end

    test "allocates budget successfully", %{pid: _pid} do
      BudgetTracker.allocate_budget("obs_1", :memory, 200.0)
      
      {:ok, budget} = BudgetTracker.get_observer_budget("obs_1")
      assert Map.get(budget.allocations, :memory) == 200.0
    end

    test "releases allocated budget", %{pid: _pid} do
      BudgetTracker.allocate_budget("obs_1", :compute, 300.0)
      BudgetTracker.release_budget("obs_1", :compute, 100.0)
      
      {:ok, budget} = BudgetTracker.get_observer_budget("obs_1")
      assert Map.get(budget.allocations, :compute) == 200.0
    end

    test "returns global metrics", %{pid: _pid} do
      {:ok, metrics} = BudgetTracker.get_global_metrics()
      assert Map.has_key?(metrics, :global_allocations)
      assert Map.has_key?(metrics, :active_observers)
    end

    test "detects insufficient budget", %{pid: _pid} do
      BudgetTracker.allocate_budget("obs_1", :entropy, 95.0)
      
      result = BudgetTracker.check_budget("obs_1", :entropy, 10.0)
      assert elem(result, 0) == :error
      assert elem(result, 1) == :insufficient_budget
    end
  end

  describe "DivergenceAnalyzer" do
    test "analyzes pairwise divergence between identical states" do
      state_a = %{value: 10, timestamp: 1000}
      state_b = %{value: 10, timestamp: 1000}
      
      result = DivergenceAnalyzer.analyze_pairwise_divergence("obs_a", "obs_b", state_a, state_b)
      assert result.divergence_score >= 0.0
      assert result.divergence_score <= 1.0
      assert result.status in [:safe, :elevated, :critical, :emergency]
    end

    test "analyzes pairwise divergence between different states" do
      state_a = %{value: 10, timestamp: 1000, causal_chain: [1, 2, 3]}
      state_b = %{value: 50, timestamp: 2000, causal_chain: [4, 5, 6]}
      
      result = DivergenceAnalyzer.analyze_pairwise_divergence("obs_a", "obs_b", state_a, state_b)
      assert result.divergence_score > 0.0
      assert result.observer_a == "obs_a"
      assert result.observer_b == "obs_b"
    end

    test "analyzes global divergence across multiple observers" do
      observer_states = %{
        "obs_1" => %{value: 10},
        "obs_2" => %{value: 20},
        "obs_3" => %{value: 15}
      }
      
      result = DivergenceAnalyzer.analyze_global_divergence(observer_states)
      assert result.mean_divergence >= 0.0
      assert result.max_divergence >= 0.0
      assert result.total_pairs == 3
    end

    test "detects anomalies in divergence history" do
      history = [
        %{observer_a: "obs_1", observer_b: "obs_2", rate_of_change: 0.2},
        %{observer_a: "obs_2", observer_b: "obs_3", rate_of_change: 0.05}
      ]
      
      result = DivergenceAnalyzer.detect_anomalies(history, 0.15)
      assert result.anomalies_detected == 1
      assert "obs_1" in result.anomalous_observers
    end
  end

  describe "EvaporationEngine" do
    setup do
      pid =
        case EvaporationEngine.start_link([]) do
          {:ok, pid} -> pid
          {:error, {:already_started, pid}} -> pid
        end
      GenServer.cast(EvaporationEngine, :reset)
      %{pid: pid}
    end

    test "triggers evaporation for paradox overload", %{pid: _pid} do
      EvaporationEngine.trigger_evaporation("obs_unstable", :paradox_overload)
      
      {:ok, stats} = EvaporationEngine.get_stats()
      assert stats.total_evaporated >= 1
    end

    test "triggers evaporation for divergence overflow", %{pid: _pid} do
      EvaporationEngine.trigger_evaporation("obs_diverged", :divergence_overflow)
      
      {:ok, stats} = EvaporationEngine.get_stats()
      assert stats.total_evaporated >= 1
      assert length(stats.evaporation_events) > 0
    end

    test "tracks evaporation events", %{pid: _pid} do
      EvaporationEngine.trigger_evaporation("obs_1", :budget_exhaustion)
      EvaporationEngine.trigger_evaporation("obs_2", :paradox_overload)
      
      {:ok, stats} = EvaporationEngine.get_stats()
      assert stats.total_evaporated >= 2
      assert length(stats.evaporation_events) >= 2
    end

    test "returns initial stats with zero evaporations", %{pid: _pid} do
      {:ok, stats} = EvaporationEngine.get_stats()
      assert stats.total_evaporated == 0
      assert stats.evaporation_events == []
    end
  end
end
