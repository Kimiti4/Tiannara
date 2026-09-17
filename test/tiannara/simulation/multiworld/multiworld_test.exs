defmodule Tiannara.Simulation.MultiWorld.MultiWorldTest do
  use ExUnit.Case, async: true

  alias Tiannara.Simulation.MultiWorld.{
    WorldForker, CounterfactualExplorer, ConstraintRelaxer, WorldComparisonAnalyzer
  }
  alias Tiannara.Simulation.MultiWorld.Domain.{WorldFork, CounterfactualScenario}

  describe "WorldForker" do
    test "creates a valid fork" do
      fork = WorldForker.fork("snapshot_1", "test fork", [%{type: :add, target: "x"}])

      assert is_struct(fork, WorldFork)
      assert fork.parent_snapshot_id == "snapshot_1"
      assert fork.status == :created
      assert fork.seed != nil
    end

    test "creates parallel forks" do
      forks = WorldForker.fork_parallel("snap_1", "parallel", [%{type: :test}], [%{a: 1}, %{a: 2}, %{a: 3}])

      assert length(forks) == 3
      assert Enum.all?(forks, &(&1.parent_snapshot_id == "snap_1"))
    end

    test "creates counterfactual fork" do
      fork = WorldForker.fork_counterfactual("snap_1", "What if gravity were weaker?", %{type: :modify, target: :gravity, value: 0.5})

      assert Map.get(fork.parameters, :counterfactual) == true
      assert String.contains?(fork.name, "Counterfactual")
    end

    test "validates fork" do
      fork = WorldForker.fork("snap_1", "test", [%{type: :test}])
      assert WorldForker.validate(fork) == :ok

      invalid = %{fork | parent_snapshot_id: nil}
      assert {:error, :missing_parent_snapshot} = WorldForker.validate(invalid)
    end
  end

  describe "CounterfactualExplorer" do
    test "generates counterfactual scenarios" do
      variables = [
        %{name: "temperature", current_value: 20, counterfactual_value: 30},
        %{name: "pressure", current_value: 1.0, counterfactual_value: 2.0}
      ]

      scenarios = CounterfactualExplorer.explore("world_1", variables)

      assert length(scenarios) == 2
      assert Enum.all?(scenarios, &is_struct(&1, CounterfactualScenario))
    end

    test "generates interaction scenarios" do
      variables = [
        %{name: "A", current_value: 1, counterfactual_value: 2},
        %{name: "B", current_value: 3, counterfactual_value: 4},
        %{name: "C", current_value: 5, counterfactual_value: 6}
      ]

      interactions = CounterfactualExplorer.explore_interactions("world_1", variables)
      assert length(interactions) == 2
    end

    test "attributes causality" do
      scenario = CounterfactualScenario.new(%{
        question: "What if X?",
        baseline_world_id: "w1",
        confidence: 0.6
      })

      baseline = %{temperature: 20.0, pressure: 1.0}
      counterfactual = %{temperature: 30.0, pressure: 1.1}

      attribution = CounterfactualExplorer.attribute_causality(scenario, baseline, counterfactual)

      assert attribution.causal_strength >= 0.0
      assert attribution.causal_strength <= 1.0
      assert length(attribution.divergences) == 2
    end
  end

  describe "ConstraintRelaxer" do
    test "generates relaxation schedule" do
      constraints = [
        %{name: "max_temperature", value: 100},
        %{name: "min_pressure", value: 0.5}
      ]

      schedule = ConstraintRelaxer.generate_schedule(constraints, 5)
      assert length(schedule) == 10
    end

    test "analyzes sensitivity" do
      relaxations = [
        %{original_constraint: "temp", sensitivity: 0.8, relaxation_factor: 0.2},
        %{original_constraint: "temp", sensitivity: 0.7, relaxation_factor: 0.4},
        %{original_constraint: "pressure", sensitivity: 0.1, relaxation_factor: 0.2}
      ]

      analysis = ConstraintRelaxer.analyze_sensitivity(relaxations)

      assert "temp" in analysis.binding_constraints
      assert "pressure" in analysis.slack_constraints
      assert analysis.most_binding == "temp"
    end
  end

  describe "WorldComparisonAnalyzer" do
    test "compares world outcomes" do
      world_outcomes = %{
        "w1" => %{temperature: 20.0, pressure: 1.0, growth: 0.5},
        "w2" => %{temperature: 25.0, pressure: 1.0, growth: 0.7},
        "w3" => %{temperature: 30.0, pressure: 1.1, growth: 0.9}
      }

      comparison = WorldComparisonAnalyzer.compare(world_outcomes, "w1")

      assert length(comparison.world_ids) == 3
      assert comparison.composite_divergence >= 0.0
      assert comparison.composite_divergence <= 1.0
    end

    test "identifies robust outcomes" do
      world_outcomes = %{
        "w1" => %{stable: 1.0, volatile: 0.5},
        "w2" => %{stable: 1.0, volatile: 0.9},
        "w3" => %{stable: 1.0, volatile: 0.1}
      }

      comparison = WorldComparisonAnalyzer.compare(world_outcomes, "w1")
      robust = WorldComparisonAnalyzer.robust_outcomes(comparison)

      assert Enum.any?(robust, &(&1.dimension == :stable))
    end
  end
end
