defmodule TiannaraRuntime.Counterfactual.ValidationCampaignTest do
  use ExUnit.Case, async: false

  alias TiannaraRuntime.WorldModel.Ontology.{
    WorldModel, StateSpace, Variable, Parameter, Equation, EquationSystem,
    CausalGraph, CausalNode, CausalEdge
  }

  alias TiannaraRuntime.WorldModel.Counterfactual.{
    CounterfactualWorld, Intervention, DivergencePoint, BranchNode,
    BranchComparison, AlternativeTimeline, TimelineStep,
    InterventionExecutor, BranchGenerator, AlternativeTimelineBuilder,
    BranchComparator, CounterfactualReplay, CounterfactualValidation,
    CounterfactualArchaeology, CounterfactualRegistry, CounterfactualEngine
  }

  @moduletag :campaign

  defp test_world_model do
    {:ok, v1} = Variable.new(variable_id: "x", name: "x", type: :continuous, is_endogenous: true)
    {:ok, v2} = Variable.new(variable_id: "y", name: "y", type: :continuous, is_endogenous: true)
    {:ok, ss} = StateSpace.new(dimensions: 2, variable_order: ["x", "y"],
      default_initial: %{"x" => 1.0, "y" => 2.0}, support_type: :continuous)
    {:ok, p1} = Parameter.new(name: "baseline", value: 1.0, estimated_from: "x")
    expr_x = %{"form" => "constant", "parameters" => ["baseline"]}
    {:ok, eq_x} = Equation.new(target_variable: "x", expression: expr_x, type: :algebraic, derivation: :expert_provided, confidence: 0.9)
    {:ok, eq_sys} = EquationSystem.new(equations: [eq_x])
    {:ok, n1} = CausalNode.new(node_id: "x", type: :endogenous)
    {:ok, e1} = CausalEdge.new(source: "x", target: "y", type: :direct)
    {:ok, cg} = CausalGraph.new(nodes: [n1], edges: [e1], latent_variables: [], confounders: [], do_calculus_level: 2)
    {:ok, wm} = WorldModel.new(name: "test_cf_model", domain: :mathematics, state_space: ss,
      variables: [v1, v2], parameters: [p1], equations: eq_sys, causal_graph: cg, status: :operational,
      fingerprint: "fp_test_cf")
    wm
  end

  describe "C17.5.95.1 — Struct Validation" do
    test "CounterfactualWorld validates required fields" do
      assert {:error, _} = CounterfactualWorld.new(parent_model_id: "", intervention: nil,
        divergence_point: nil, timeline: nil, outcomes: [])
    end

    test "Intervention validates type and operation" do
      assert {:error, _} = Intervention.new(type: :invalid, target: "x", operation: :fix)
      assert {:error, _} = Intervention.new(type: :variable, target: "", operation: :fix)
      assert {:error, _} = Intervention.new(type: :variable, target: "x", operation: :bogus)
    end

    test "DivergencePoint validates step" do
      assert {:error, _} = DivergencePoint.new(parent_model_id: "m", step: -1, state: %{}, intervention: nil)
    end

    test "BranchNode validates depth" do
      assert {:error, _} = BranchNode.new(divergence: nil, depth: -1)
    end

    test "AlternativeTimeline validates steps" do
      assert {:error, _} = AlternativeTimeline.new(branch_id: "", steps: nil,
        initial_state: %{}, final_state: %{}, total_steps: 0)
    end

    test "TimelineStep validates step" do
      assert {:error, _} = TimelineStep.new(step: -1, state: %{}, intervention_active: false)
    end

    test "BranchComparison validates metrics" do
      assert {:error, _} = BranchComparison.new(original_id: "", counterfactual_id: "cf")
    end
  end

  describe "C17.5.95.2 — Intervention" do
    test "InterventionExecutor validates variable target" do
      wm = test_world_model()
      iv = %Intervention{type: :variable, target: "nonexistent", operation: :fix}
      assert {:error, _} = InterventionExecutor.validate_intervention(wm, iv)
    end

    test "InterventionExecutor validates structural intervention" do
      wm = test_world_model()
      iv = %Intervention{type: :structural, target: "graph", operation: :modify}
      assert :ok = InterventionExecutor.validate_intervention(wm, iv)
    end

    test "Intervention applies variable fix" do
      wm = test_world_model()
      iv = %Intervention{type: :variable, target: "x", operation: :fix, value: 42.0}
      {:ok, modified} = InterventionExecutor.apply(wm, iv)
      assert modified.state_space.default_initial["x"] == 42.0
    end

    test "Intervention removes variable" do
      wm = test_world_model()
      iv = %Intervention{type: :variable, target: "x", operation: :remove}
      {:ok, modified} = InterventionExecutor.apply(wm, iv)
      refute Enum.any?(modified.variables, fn v -> v.name == "x" end)
    end
  end

  describe "C17.5.95.3 — Branch Generation" do
    test "generates branch with divergence point" do
      wm = test_world_model()
      iv = %Intervention{type: :variable, target: "x", operation: :fix, value: 10.0}
      {:ok, bn, dp} = BranchGenerator.generate(wm, iv)
      assert bn.depth == 0
      assert dp.step == 0
      assert dp.intervention.target == "x"
    end
  end

  describe "C17.5.95.4 — Timeline Construction" do
    test "constructs alternative timeline" do
      wm = test_world_model()
      iv = %Intervention{type: :variable, target: "x", operation: :fix, value: 5.0}
      {:ok, bn, dp} = BranchGenerator.generate(wm, iv)
      {:ok, at} = AlternativeTimelineBuilder.construct(wm, bn, dp, num_steps: 5)
      assert at.total_steps > 0
      assert length(at.steps) == 6
      assert at.initial_state["x"] == 1.0
    end
  end

  describe "C17.5.95.5 — Branch Comparison" do
    test "compare returns comparison struct" do
      wm = test_world_model()
      iv = %Intervention{type: :variable, target: "x", operation: :fix, value: 10.0}
      {:ok, bn, dp} = BranchGenerator.generate(wm, iv)
      {:ok, at} = AlternativeTimelineBuilder.construct(wm, bn, dp, num_steps: 3)
      cf = %CounterfactualWorld{
        parent_model_id: wm.model_id || "test",
        intervention: iv, divergence_point: dp,
        timeline: at, outcomes: []
      }
      {:ok, bc} = BranchComparator.compare(wm.model_id || "test", cf)
      assert bc.divergence_metric >= 0.0
      assert bc.similarity_metric >= 0.0
    end
  end

  describe "C17.5.95.6 — Replay and Fingerprint" do
    test "fingerprint is deterministic" do
      iv = %Intervention{type: :variable, target: "x", operation: :fix, value: 5.0}
      dp = %DivergencePoint{parent_model_id: "m", step: 0, state: %{}, intervention: iv}
      at = %AlternativeTimeline{branch_id: "b", steps: [], initial_state: %{}, final_state: %{}, total_steps: 0}
      cf = %CounterfactualWorld{parent_model_id: "m", intervention: iv,
        divergence_point: dp, timeline: at, outcomes: []}
      fp1 = CounterfactualReplay.fingerprint(cf)
      fp2 = CounterfactualReplay.fingerprint(cf)
      assert fp1 == fp2
      assert String.starts_with?(fp1, "fp_")
    end
  end

  describe "C17.5.95.7 — Counterfactual Validation" do
    test "validates counterfactual completeness" do
      iv = %Intervention{type: :variable, target: "x", operation: :fix, value: 5.0}
      dp = %DivergencePoint{parent_model_id: "m", step: 0, state: %{x: 1.0}, intervention: iv}
      step = %TimelineStep{step: 0, state: %{x: 1.0}, intervention_active: true}
      at = %AlternativeTimeline{branch_id: "b", steps: [step], initial_state: %{x: 1.0}, final_state: %{x: 5.0}, total_steps: 1}
      cf = %CounterfactualWorld{parent_model_id: "m", intervention: iv,
        divergence_point: dp, timeline: at, outcomes: [%{}],
        assumptions: %{assumption: true}, replay_fingerprint: "fp_test"}
      {:ok, result} = CounterfactualValidation.validate(cf)
      assert result.overall == :pass
    end
  end

  describe "C17.5.95.8 — Archaeology" do
    test "records and retrieves branch evidence" do
      CounterfactualArchaeology.reset_table()
      iv = %Intervention{type: :variable, target: "x", operation: :fix, value: 5.0}
      dp = %DivergencePoint{parent_model_id: "m", step: 0, state: %{}, intervention: iv}
      at = %AlternativeTimeline{branch_id: "b", steps: [], initial_state: %{}, final_state: %{}, total_steps: 0}
      cf = %CounterfactualWorld{counterfactual_id: "cf_test_arch",
        parent_model_id: "m", intervention: iv, divergence_point: dp,
        timeline: at, outcomes: [], evidence_roots: ["root1"]}
      {:ok, ev} = CounterfactualArchaeology.record_branch(cf)
      assert String.starts_with?(ev.evidence_id, "ce_")
      {:ok, retrieved} = CounterfactualArchaeology.get_lineage("cf_test_arch")
      assert retrieved != nil
    end
  end

  describe "C17.5.95.9 — Full Pipeline" do
    test "end-to-end counterfactual creation" do
      iv = %Intervention{type: :variable, target: "x", operation: :fix, value: 10.0}
      dp = %DivergencePoint{parent_model_id: "test_mid", step: 0, state: %{x: 1.0}, intervention: iv}
      step = %TimelineStep{step: 0, state: %{x: 10.0}, intervention_active: true}
      at = %AlternativeTimeline{branch_id: "b", steps: [step], initial_state: %{x: 1.0}, final_state: %{x: 10.0}, total_steps: 1}

      cf = %CounterfactualWorld{
        parent_model_id: "test_mid",
        intervention: iv,
        divergence_point: dp,
        timeline: at,
        outcomes: [],
        assumptions: %{test: true},
        evidence_roots: ["root_test"]
      }

      {:ok, validated} = CounterfactualWorld.new(
        parent_model_id: cf.parent_model_id,
        intervention: cf.intervention,
        divergence_point: cf.divergence_point,
        timeline: cf.timeline,
        outcomes: cf.outcomes,
        assumptions: cf.assumptions,
        evidence_roots: cf.evidence_roots
      )

      fp = CounterfactualReplay.fingerprint(validated)
      cf_with_fp = %{validated | replay_fingerprint: fp}
      assert String.starts_with?(cf_with_fp.counterfactual_id, "cf_")
      assert String.starts_with?(fp, "fp_")
      assert cf_with_fp.parent_model_id == "test_mid"
    end
  end
end
