defmodule Tiannara.Phase4.Adversarial.AdversarialTest do
  @moduledoc """
  Adversarial tests for Phase 4.

  Tests that the system resists:
    - Confirmation bias
    - Hypothesis monoculture
    - Circular reasoning
    - Evidence contamination
    - Runaway hypothesis generation

  Constitutional Alignment (rules.md):
    - "Continuous Self-Evaluation": What evidence contradicts me?
    - "Evidence Before Confidence": Never optimize for appearing correct.
    - "Bottleneck Discovery": Finding bottlenecks is a primary capability.
  """
  use ExUnit.Case, async: true

  alias Tiannara.Discovery.{
    HypothesisGenerator, DiscoveryPrioritizer, Discovery,
    PredictionEngine, ExperimentPlanner, EvidenceIntegrator
  }
  alias Tiannara.Discovery.Domain.{KnowledgeGap, DiscoveryResult}

  @moduletag :adversarial
  @moduletag :phase4

  describe "Confirmation bias resistance" do
    test "hypotheses include null hypotheses (not just confirming explanations)" do
      gap = KnowledgeGap.new(%{
        domain: :epistemic_consistency,
        description: "Apparent pattern in data",
        severity: :high,
        estimated_impact: 0.9,
        source: :epistemic_integrity
      })

      hypotheses = HypothesisGenerator.generate(gap)

      # At least one hypothesis should be an alternative explanation
      has_alternative = Enum.any?(hypotheses, fn hyp ->
        String.contains?(hyp.statement, "bias") or
        String.contains?(hyp.statement, "error") or
        String.contains?(hyp.statement, "anomaly") or
        String.contains?(hyp.statement, "confound") or
        String.contains?(hyp.statement, "null")
      end)

      assert has_alternative, "No alternative explanation found — confirmation bias risk"
    end

    test "priors are normalized (no single hypothesis dominates)" do
      gap = KnowledgeGap.new(%{
        domain: :epistemic_consistency,
        description: "Test",
        severity: :critical,
        estimated_impact: 1.0,
        source: :epistemic_integrity
      })

      hypotheses = HypothesisGenerator.generate(gap)
      max_prior = Enum.max_by(hypotheses, & &1).prior

      # No single hypothesis should have prior > 0.7 (would indicate bias)
      assert max_prior < 0.7, "Max prior #{max_prior} too high — confirmation bias risk"
    end
  end

  describe "Hypothesis monoculture resistance" do
    test "diversity enforcement limits same-domain discoveries" do
      # Create 10 discoveries all in the same domain
      discoveries = Enum.map(1..10, fn _ ->
        gap = KnowledgeGap.new(%{
          domain: :same_domain,
          description: "Same type of gap",
          severity: :high,
          estimated_impact: 0.8,
          source: :epistemic_integrity
        })
        Discovery.from_gap(gap)
      end)

      ranked = DiscoveryPrioritizer.rank_with_diversity(discoveries)

      # Should be limited (not all 10)
      assert length(ranked) < 10, "Monoculture not prevented: #{length(ranked)} same-domain discoveries"
    end

    test "monoculture detection flags concentrated domains" do
      discoveries = Enum.map(1..6, fn _ ->
        gap = KnowledgeGap.new(%{
          domain: :concentrated_domain,
          description: "Concentrated",
          severity: :high,
          estimated_impact: 0.8,
          source: :epistemic_integrity
        })
        Discovery.from_gap(gap)
      end)

      warnings = DiscoveryPrioritizer.detect_monoculture(discoveries)
      assert length(warnings) >= 1, "Monoculture not detected"
    end
  end

  describe "Runaway generation resistance" do
    test "hypothesis generation is bounded (max 4)" do
      gap = KnowledgeGap.new(%{
        domain: :epistemic_consistency,
        description: "Complex gap",
        severity: :critical,
        estimated_impact: 1.0,
        uncertainty: 1.0,
        source: :epistemic_integrity
      })

      hypotheses = HypothesisGenerator.generate(gap)
      assert length(hypotheses) <= 4, "Runaway generation: #{length(hypotheses)} hypotheses"
    end

    test "experiment planning is bounded by predictions" do
      gap = KnowledgeGap.new(%{
        domain: :epistemic_consistency,
        description: "Test",
        severity: :high,
        source: :epistemic_integrity
      })

      hypotheses = HypothesisGenerator.generate(gap)
      predictions = Enum.flat_map(hypotheses, &PredictionEngine.generate/1)

      experiments = Enum.flat_map(hypotheses, fn hyp ->
        hyp_preds = Enum.filter(predictions, &(&1.hypothesis_id == hyp.id))
        ExperimentPlanner.plan(hyp, hyp_preds)
      end)

      # Experiments should not exceed predictions
      assert length(experiments) <= length(predictions),
        "Runaway experiment generation: #{length(experiments)} experiments for #{length(predictions)} predictions"
    end
  end

  describe "Evidence contamination resistance" do
    test "evidence validation rejects empty evidence" do
      assert {:error, :no_evidence_provided} =
               EvidenceIntegrator.validate_evidence([])
    end

    test "evidence validation rejects results without outcomes" do
      result = DiscoveryResult.new(%{
        experiment_id: "e1",
        hypothesis_id: "h1",
        evidence: [%{x: 1}]
        # No outcome field
      })

      assert {:error, :evidence_missing_outcome} =
               EvidenceIntegrator.validate_evidence([result])
    end
  end
end
