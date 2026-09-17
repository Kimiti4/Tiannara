defmodule Tiannara.Discovery.Quality.QualityAssessorTest do
  use ExUnit.Case, async: true

  alias Tiannara.Discovery.Quality.{
    DiscoveryQualityAssessor, ConfirmationBiasDetector,
    CircularReasoningDetector, StatisticalAnomalyDetector
  }
  alias Tiannara.Discovery.{Discovery, HypothesisGenerator, PredictionEngine, ExperimentPlanner}
  alias Tiannara.Discovery.Domain.{KnowledgeGap, DiscoveryResult}

  defp build_complete_discovery do
    gap = KnowledgeGap.new(%{
      domain: :epistemic_consistency,
      description: "Test gap",
      severity: :high,
      estimated_impact: 0.8,
      source: :epistemic_integrity
    })

    disc = Discovery.from_gap(gap)
    hypotheses = HypothesisGenerator.generate(gap)
    disc = Discovery.add_hypotheses(disc, hypotheses)

    predictions = Enum.flat_map(hypotheses, &PredictionEngine.generate/1)
    disc = Discovery.add_predictions(disc, predictions)

    experiments = Enum.flat_map(hypotheses, fn hyp ->
      hyp_preds = Enum.filter(predictions, &(&1.hypothesis_id == hyp.id))
      ExperimentPlanner.plan(hyp, hyp_preds)
    end)
    disc = Discovery.add_experiments(disc, experiments)

    results = [
      DiscoveryResult.new(%{
        experiment_id: "e1", hypothesis_id: hd(hypotheses).id,
        outcome: :confirmed, evidence: [%{x: 1}, %{x: 2}],
        confidence_delta: 0.2, posterior: 0.7
      }),
      DiscoveryResult.new(%{
        experiment_id: "e2", hypothesis_id: hd(hypotheses).id,
        outcome: :inconclusive, evidence: [%{x: 3}],
        confidence_delta: 0.05, posterior: 0.55
      })
    ]

    Discovery.add_evidence(disc, results)
  end

  describe "DiscoveryQualityAssessor.assess/1" do
    test "produces a valid quality report" do
      disc = build_complete_discovery()
      report = DiscoveryQualityAssessor.assess(disc)

      assert report.discovery_id == disc.id
      assert report.overall_score >= 0.0
      assert report.overall_score <= 1.0
      assert report.recommendation in [:pass, :pass_with_warnings, :revise, :reject]
      assert length(report.checks) == 6
    end

    test "complete discovery with mixed evidence passes QA" do
      disc = build_complete_discovery()
      assert DiscoveryQualityAssessor.passes?(disc)
    end
  end

  describe "ConfirmationBiasDetector" do
    test "detects perfect confirmation bias" do
      gap = KnowledgeGap.new(%{domain: :test, description: "test", severity: :high, source: :epistemic_integrity})
      disc = Discovery.from_gap(gap)
      hypotheses = HypothesisGenerator.generate(gap)
      disc = Discovery.add_hypotheses(disc, hypotheses)

      results = Enum.map(1..6, fn i ->
        DiscoveryResult.new(%{
          experiment_id: "e#{i}", hypothesis_id: hd(hypotheses).id,
          outcome: :confirmed, evidence: [%{x: i}],
          confidence_delta: 0.1, posterior: 0.6
        })
      end)
      disc = Discovery.add_evidence(disc, results)

      check = ConfirmationBiasDetector.detect(disc)
      assert Enum.any?(check.evidence, &(&1.type == :evidence_asymmetry))
    end

    test "passes with mixed evidence" do
      disc = build_complete_discovery()
      check = ConfirmationBiasDetector.detect(disc)
      refute Enum.any?(check.evidence, &(&1.type == :evidence_asymmetry))
    end
  end

  describe "StatisticalAnomalyDetector" do
    test "detects confidence without evidence" do
      gap = KnowledgeGap.new(%{domain: :test, description: "test", severity: :high, source: :epistemic_integrity})
      disc = %{Discovery.from_gap(gap) | confidence: 0.9, uncertainty: 0.1}

      check = StatisticalAnomalyDetector.detect(disc)
      assert Enum.any?(check.evidence, &(&1.type == :confidence_without_evidence))
    end

    test "passes with valid evidence" do
      disc = build_complete_discovery()
      check = StatisticalAnomalyDetector.detect(disc)
      assert check.passed or check.score > 0.5
    end
  end

  describe "CircularReasoningDetector" do
    test "passes for well-formed discovery" do
      disc = build_complete_discovery()
      check = CircularReasoningDetector.detect(disc)
      assert check.passed
    end
  end
end
