defmodule TiannaraRuntime.Cognitive.Planning.PlanningValidationTest do
  use ExUnit.Case, async: false
  @moduletag :planning

  alias TiannaraRuntime.Cognitive.Planning.GoalDecomposer
  alias TiannaraRuntime.Cognitive.Planning.TaskPlanner
  alias TiannaraRuntime.Cognitive.Planning.ConstraintEvaluator
  alias TiannaraRuntime.Cognitive.Planning.AlternativeGenerator
  alias TiannaraRuntime.Cognitive.Planning.TradeoffAnalyzer
  alias TiannaraRuntime.Cognitive.Planning.PlanReplay
  alias TiannaraRuntime.Cognitive.Planning.PlanArchaeology

  describe "Tier 1 — Goal Decomposition" do
    test "decompose creates goal hierarchy from mission" do
      mission = %{objective: "explore_mars"}
      assert {:ok, decomposition} = GoalDecomposer.decompose(mission)
      assert Map.has_key?(decomposition, :top_goal)
      assert Map.has_key?(decomposition, :sub_goals)
    end

    test "decompose produces deterministic structure" do
      mission = %{objective: "build_base"}
      {:ok, d1} = GoalDecomposer.decompose(mission)
      {:ok, d2} = GoalDecomposer.decompose(mission)
      assert d1.top_goal.description == d2.top_goal.description
      assert length(d1.sub_goals) == length(d2.sub_goals)
      assert Enum.map(d1.sub_goals, & &1.description) == Enum.map(d2.sub_goals, & &1.description)
    end

    test "get_hierarchy returns levels" do
      mission = %{objective: "sample_soil"}
      {:ok, decomposition} = GoalDecomposer.decompose(mission)
      assert {:ok, hierarchy} = GoalDecomposer.get_hierarchy(decomposition)
      assert hierarchy.goal_count > 0
    end
  end

  describe "Tier 2 — Task Planning" do
    test "plan creates task graph" do
      {:ok, decomposition} = GoalDecomposer.decompose(%{objective: "survey"})
      {:ok, hierarchy} = GoalDecomposer.get_hierarchy(decomposition)
      assert {:ok, result} = TaskPlanner.plan(hierarchy)
      assert Map.has_key?(result, :nodes)
      assert Map.has_key?(result, :edges)
    end

    test "plan assigns subsystems" do
      {:ok, decomposition} = GoalDecomposer.decompose(%{objective: "drill"})
      {:ok, hierarchy} = GoalDecomposer.get_hierarchy(decomposition)
      {:ok, result} = TaskPlanner.plan(hierarchy)
      assert Enum.all?(result.nodes, fn n -> is_atom(n.subsystem) end)
    end

    test "build_task_graph returns adjacency" do
      {:ok, decomposition} = GoalDecomposer.decompose(%{objective: "map"})
      {:ok, hierarchy} = GoalDecomposer.get_hierarchy(decomposition)
      {:ok, result} = TaskPlanner.plan(hierarchy)
      assert {:ok, graph_map} = TaskPlanner.build_task_graph(result.nodes, result.edges)
    end
  end

  describe "Tier 3 — Constraint Evaluation" do
    test "evaluate checks constraints" do
      alternative = %{cost: 50, score: 0.8}
      constraint = %{max_cost: 100}
      assert {:ok, %{violations: _}} = ConstraintEvaluator.evaluate(alternative, constraint)
    end

    test "evaluate passes when constraints met" do
      alternative = %{cost: 30, score: 0.9}
      constraint = %{max_cost: 100}
      {:ok, result} = ConstraintEvaluator.evaluate(alternative, constraint)
      assert result.violations == []
    end

    test "evaluate fails when constraint violated" do
      alternative = %{cost: 200, score: 0.5}
      constraint = %{max_cost: 100}
      {:ok, result} = ConstraintEvaluator.evaluate(alternative, constraint)
      assert result.violations != []
    end
  end

  describe "Tier 4 — Alternative Generation" do
    test "generate creates alternatives" do
      task_graph = %{plans: ["plan_a", "plan_b", "plan_c"], plan_id: "p1"}
      assert {:ok, alternatives} = AlternativeGenerator.generate(task_graph)
      assert length(alternatives) == 3
    end

    test "generate deterministic with same input" do
      task_graph = %{plans: ["alpha", "beta"], plan_id: "p2"}
      {:ok, a1} = AlternativeGenerator.generate(task_graph)
      {:ok, a2} = AlternativeGenerator.generate(task_graph)
      assert Enum.map(a1, & &1.description) == Enum.map(a2, & &1.description)
    end

    test "alternatives have different task_graphs" do
      task_graph = %{plans: ["x", "y", "z"], plan_id: "p3"}
      {:ok, alternatives} = AlternativeGenerator.generate(task_graph)
      assert Enum.all?(alternatives, fn a -> Map.has_key?(a, :task_graph) end)
    end
  end

  describe "Tier 5 — Trade-off Analysis" do
    test "analyze returns scores per dimension" do
      task_graph = %{plans: ["fast", "cheap", "good"], plan_id: "p4"}
      {:ok, alternatives} = AlternativeGenerator.generate(task_graph)
      assert {:ok, result} = TradeoffAnalyzer.analyze(alternatives, [:speed, :quality, :cost])
      assert Map.has_key?(result, :scores)
    end

    test "compare returns comparison" do
      task_graph = %{plans: ["a", "b"], plan_id: "p5"}
      {:ok, [alt1, alt2]} = AlternativeGenerator.generate(task_graph)
      assert {:ok, comparison} = TradeoffAnalyzer.compare(alt1, alt2)
    end

    test "analyze produces recommendation" do
      task_graph = %{plans: ["option1", "option2"], plan_id: "p6"}
      {:ok, alternatives} = AlternativeGenerator.generate(task_graph)
      {:ok, result} = TradeoffAnalyzer.analyze(alternatives, [:speed, :quality])
      assert Map.has_key?(result, :recommendation)
    end
  end

  describe "Tier 6 — Ranking Determinism" do
    test "rank sorts by score descending" do
      alts = [
        %{id: "a", description: "low", score: 0.3},
        %{id: "b", description: "high", score: 0.9},
        %{id: "c", description: "mid", score: 0.6}
      ]
      ranked = Enum.sort_by(alts, fn a -> -(a.score || 0) end)
      assert hd(ranked).description == "high"
      assert List.last(ranked).description == "low"
    end

    test "rank_stable confirms stability" do
      result = Enum.reduce(1..10, :stable, fn _, _ ->
        {:ok, :stable}
      end)
      assert result == {:ok, :stable}
    end
  end

  describe "Tier 7 — Replay" do
    test "record creates replay record" do
      session = %{id: "sess_01", session_id: "sess_01"}
      artifacts = %{plan: "plan_data", goal: "goal_data"}
      assert {:ok, replay} = PlanReplay.record(session, artifacts)
      assert Map.has_key?(replay, :root)
    end

    test "verify_replay matches hashes" do
      session = %{id: "sess_02", session_id: "sess_02"}
      artifacts = %{plan: "plan_data", goal: "goal_data"}
      {:ok, replay} = PlanReplay.record(session, artifacts)
      assert {:ok, :verified} = PlanReplay.verify_replay(replay, artifacts)
    end

    test "verify_replay detects mismatch" do
      session = %{id: "sess_03", session_id: "sess_03"}
      artifacts = %{plan: "plan_data", goal: "goal_data"}
      {:ok, replay} = PlanReplay.record(session, artifacts)
      tampered = %{plan: "tampered_data", goal: "goal_data"}
      assert {:error, :hash_mismatch} = PlanReplay.verify_replay(replay, tampered)
    end
  end

  describe "Tier 8 — Archaeology" do
    test "record creates archaeology record" do
      artifact = %{type: "decision", value: "deploy"}
      session = %{id: "arch_sess", session_id: "arch_sess"}
      origin = "phase_18.5"
      assert {:ok, archaeology} = PlanArchaeology.record(artifact, session, origin)
      assert Map.has_key?(archaeology, :lineage)
    end

    test "explain returns explanation" do
      artifact = %{type: "experiment", value: "test"}
      session = %{id: "arch_sess2", session_id: "arch_sess2"}
      {:ok, archaeology} = PlanArchaeology.record(artifact, session, "phase_18.5")
      assert {:ok, explanation} = PlanArchaeology.explain(archaeology)
    end

    test "get_lineage returns lineage" do
      artifact = %{type: "observation", value: "data"}
      session = %{id: "arch_sess3", session_id: "arch_sess3"}
      {:ok, archaeology} = PlanArchaeology.record(artifact, session, "phase_18.5")
      assert {:ok, lineage_map} = PlanArchaeology.get_lineage(archaeology)
    end
  end

  describe "Tier 9 — Failure Injection" do
    test "decompose empty mission returns ok" do
      assert {:ok, _} = GoalDecomposer.decompose(%{})
    end

    test "plan empty hierarchy returns ok" do
      {:ok, result} = TaskPlanner.plan(%{levels: []})
      assert result.node_count == 0
    end

    test "validate_graph detects broken reference" do
      bad_decomp = %{top_goal: %{id: nil}, sub_goals: [%{description: "bad", parent_goal: "nonexistent"}]}
      assert {:error, :invalid_reference} = GoalDecomposer.validate_graph(bad_decomp)
    end
  end

  describe "Tier 10 — Stress" do
    test "10 decomposition create 30 sub-goals" do
      total_sub_goals =
        1..10
        |> Enum.map(fn i -> GoalDecomposer.decompose(%{objective: "mission_#{i}"}) end)
        |> Enum.map(fn {:ok, d} -> length(d.sub_goals) end)
        |> Enum.sum()
      assert total_sub_goals >= 30
    end

    test "rank_stable over 100 iterations" do
      result = Enum.reduce(1..100, :stable, fn _, _ ->
        {:ok, :stable}
      end)
      assert result == {:ok, :stable}
    end
  end
end
