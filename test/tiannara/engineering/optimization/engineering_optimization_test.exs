defmodule Tiannara.Engineering.Optimization.EngineeringOptimizationTest do
  use ExUnit.Case, async: true
  alias Tiannara.Engineering.Optimization.{ArchitectureGenerator, MultiObjectiveOptimizer}
  alias Tiannara.Engineering.Domain.{EngineeringDesign, DesignComponent}

  defp test_design(opts \\ []) do
    comps = [
      %DesignComponent{name: "processor", type: :core, complexity: 0.4, reusability: 0.8, description: "Main processor", interfaces: [], dependencies: [], resource_cost: %{compute: 100, memory: 50}},
      %DesignComponent{name: "memory", type: :storage, complexity: 0.3, reusability: 0.7, description: "Memory module", interfaces: [], dependencies: ["processor"], resource_cost: %{compute: 10, memory: 200}}
    ]
    %EngineeringDesign{
      id: opts[:id] || "design_1",
      name: opts[:name] || "Test Design",
      description: "A test engineering design",
      architecture: %{pattern: opts[:pattern] || :monolithic, scaling_strategy: opts[:scaling] || :vertical, data_flow: :hybrid, components: ["processor", "memory"], coupling: :tight},
      components: comps,
      resource_requirements: %{compute: opts[:compute] || 500, memory: opts[:memory] || 1000, time_hours: opts[:time] || 50},
      feasibility: opts[:feasibility] || 0.8,
      risk: opts[:risk] || 0.3,
      safety_score: opts[:safety] || 0.85,
      lineage: []
    }
  end

  describe "ArchitectureGenerator" do
    test "generate_alternatives/2 produces alternative designs" do
      design = test_design()
      alternatives = ArchitectureGenerator.generate_alternatives(design, 3)
      assert length(alternatives) == 3
      Enum.each(alternatives, fn alt ->
        assert is_struct(alt, EngineeringDesign)
        assert alt.id != design.id
        assert String.contains?(alt.name, "alternative")
      end)
    end

    test "generate_alternatives/2 with different patterns" do
      design = test_design(%{pattern: :monolithic})
      alternatives = ArchitectureGenerator.generate_alternatives(design, 6)
      patterns = Enum.map(alternatives, fn a -> Map.get(a.architecture, :pattern) end)
      assert Enum.any?(patterns, fn p -> p != :monolithic end)
    end

    test "evaluate_sustainability/1 returns sustainability scores" do
      design = test_design()
      result = ArchitectureGenerator.evaluate_sustainability(design)
      assert Map.has_key?(result, :composite)
      assert Map.has_key?(result, :scores)
      assert result.design_id == design.id
      assert result.pattern == :monolithic
    end

    test "evaluate_sustainability/1 with different patterns gives different scores" do
      monolithic = ArchitectureGenerator.evaluate_sustainability(test_design(%{pattern: :monolithic}))
      hexagonal = ArchitectureGenerator.evaluate_sustainability(test_design(%{pattern: :hexagonal}))
      assert monolithic.composite != hexagonal.composite
    end
  end

  describe "MultiObjectiveOptimizer" do
    test "evaluate/1 returns all objectives" do
      design = test_design()
      evaluation = MultiObjectiveOptimizer.evaluate(design)
      assert Map.has_key?(evaluation, :cost)
      assert Map.has_key?(evaluation, :sustainability)
      assert Map.has_key?(evaluation, :reliability)
      assert Map.has_key?(evaluation, :safety)
      assert Map.has_key?(evaluation, :performance)
      assert Map.has_key?(evaluation, :manufacturability)
      Enum.each([:cost, :sustainability, :reliability, :safety, :performance, :manufacturability], fn obj ->
        assert Map.get(evaluation, obj) >= 0.0 and Map.get(evaluation, obj) <= 1.0
      end)
    end

    test "pareto_front/1 returns non-dominated designs" do
      design_a = test_design(%{id: "a", compute: 100, safety: 0.9})
      design_b = test_design(%{id: "b", compute: 200, safety: 0.8})
      front = MultiObjectiveOptimizer.pareto_front([design_a, design_b])
      assert length(front) >= 1
    end

    test "select_best/2 returns non-nil" do
      designs = [test_design(%{id: "a"}), test_design(%{id: "b", compute: 300, feasibility: 0.6})]
      best = MultiObjectiveOptimizer.select_best(designs)
      assert best != nil
      assert is_struct(best, EngineeringDesign)
    end

    test "select_best/2 with empty list returns nil" do
      assert MultiObjectiveOptimizer.select_best([]) == nil
    end

    test "dominates?/2 returns false for identical evaluations" do
      eval = MultiObjectiveOptimizer.evaluate(test_design())
      refute MultiObjectiveOptimizer.dominates?(eval, eval)
    end

    test "weighted_score/2 is higher with favorable weights" do
      good_eval = %{cost: 0.9, sustainability: 0.8, reliability: 0.8, safety: 0.9, performance: 0.8, manufacturability: 0.8}
      bad_eval = %{cost: 0.2, sustainability: 0.3, reliability: 0.3, safety: 0.4, performance: 0.3, manufacturability: 0.3}
      weights = %{safety: 0.5, cost: 0.3, sustainability: 0.2}
      assert MultiObjectiveOptimizer.weighted_score(good_eval, weights) > MultiObjectiveOptimizer.weighted_score(bad_eval, weights)
    end
  end
end
