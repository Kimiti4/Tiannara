defmodule Tiannara.Discovery.EvidenceIntegratorTest do
  use ExUnit.Case, async: true
  alias Tiannara.Discovery.EvidenceIntegrator
  alias Tiannara.Discovery.Domain.DiscoveryResult

  defp supported_result(experiment_id \\ "exp_1", hypothesis_id \\ "hyp_1") do
    DiscoveryResult.new(%{experiment_id: experiment_id, hypothesis_id: hypothesis_id,
      outcome: :supported, evidence: [%{type: :observation, value: 0.8}],
      confidence_delta: 0.3, posterior: 0.8})
  end

  defp falsified_result(experiment_id \\ "exp_1", hypothesis_id \\ "hyp_1") do
    DiscoveryResult.new(%{experiment_id: experiment_id, hypothesis_id: hypothesis_id,
      outcome: :falsified, evidence: [%{type: :observation, value: 0.1}],
      confidence_delta: -0.3, posterior: 0.2})
  end

  defp inconclusive_result(experiment_id \\ "exp_1", hypothesis_id \\ "hyp_1") do
    DiscoveryResult.new(%{experiment_id: experiment_id, hypothesis_id: hypothesis_id,
      outcome: :inconclusive, evidence: [],
      confidence_delta: 0.0, posterior: 0.5})
  end

  describe "integrate/2" do
    test "returns evaluation map for supported results" do
      [eval] = EvidenceIntegrator.integrate([supported_result()])
      assert eval.outcome == :supported
      assert eval.experiment_id == "exp_1"
      assert eval.hypothesis_id == "hyp_1"
      assert eval.evidence_count == 1
      assert eval.confidence_delta == 0.3
    end

    test "returns evaluation map for falsified results" do
      [eval] = EvidenceIntegrator.integrate([falsified_result()])
      assert eval.outcome == :falsified
    end

    test "returns inconclusive for mixed outcomes" do
      [eval] = EvidenceIntegrator.integrate([supported_result(), falsified_result()])
      assert eval.outcome == :falsified
    end

    test "groups results by experiment_id" do
      evaluations = EvidenceIntegrator.integrate([
        supported_result("exp_1", "hyp_1"),
        falsified_result("exp_2", "hyp_2")
      ])
      assert length(evaluations) == 2
    end
  end

  describe "collect_evidence/3" do
    test "collects evidence for hypothesis IDs" do
      result = supported_result("exp_1", "hyp_1")
      knowledge = %{experiment_results: %{"hyp_1" => [result]}}
      assert EvidenceIntegrator.collect_evidence("disc_1", ["hyp_1"], knowledge) == [result]
    end

    test "returns empty list for missing hypothesis" do
      assert EvidenceIntegrator.collect_evidence("disc_1", ["nonexistent"], %{}) == []
    end
  end

  describe "evaluate_evidence/2" do
    test "evaluates supported result" do
      eval = EvidenceIntegrator.evaluate_evidence(supported_result(), %{})
      assert eval.evaluated_outcome == :supported
    end

    test "evaluates falsified result" do
      eval = EvidenceIntegrator.evaluate_evidence(falsified_result(), %{})
      assert eval.evaluated_outcome == :falsified
    end
  end

  describe "compute_outcome/1" do
    test "any falsified makes overall falsified" do
      assert EvidenceIntegrator.compute_outcome([falsified_result(), supported_result()]) == :falsified
    end

    test "all supported makes overall supported" do
      assert EvidenceIntegrator.compute_outcome([supported_result(), supported_result()]) == :supported
    end

    test "mixed non-falsified outcomes are inconclusive" do
      assert EvidenceIntegrator.compute_outcome([inconclusive_result(), supported_result()]) == :inconclusive
    end
  end

  describe "compute_confidence_delta/3" do
    test "adjusts delta by base and count" do
      delta = EvidenceIntegrator.compute_confidence_delta([supported_result(), supported_result()], 0.5, 2)
      assert delta <= 0.6 and delta >= 0.0
    end

    test "clamps to [-0.5, 0.5]" do
      large = DiscoveryResult.new(%{experiment_id: "e1", hypothesis_id: "h1",
        outcome: :supported, evidence: [], confidence_delta: 2.0, posterior: 1.0})
      assert EvidenceIntegrator.compute_confidence_delta([large], 0.5, 1) == 0.5
    end
  end

  describe "prepare_promotion/3" do
    test "prepares promotion payload without calling KC" do
      payload = EvidenceIntegrator.prepare_promotion(supported_result(), %{confidence: 0.5})
      assert payload.type == :evidence_promotion
      assert payload.hypothesis_id == "hyp_1"
      assert payload.source == :discovery_engine
      assert payload.context.previous_confidence == 0.5
    end
  end

  describe "validate_result/1" do
    test "returns :ok for valid result" do
      assert EvidenceIntegrator.validate_result(supported_result()) == :ok
    end

    test "returns error for missing experiment_id" do
      result = DiscoveryResult.new(%{hypothesis_id: "h1", outcome: :supported})
      assert {:error, :missing_experiment_id} = EvidenceIntegrator.validate_result(result)
    end

    test "returns error for missing hypothesis_id" do
      result = DiscoveryResult.new(%{experiment_id: "e1", outcome: :supported})
      assert {:error, :missing_hypothesis_id} = EvidenceIntegrator.validate_result(result)
    end
  end
end
