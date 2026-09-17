defmodule Tiannara.Phase4.Constitutional.ConstitutionalAuditTest do
  @moduledoc """
  Constitutional compliance audit for Phase 4.

  Verifies that every Phase 4 subsystem structurally enforces the
  constitutional principles from rules.md.

  This is not a functional test — it is a COMPLIANCE test.
  It verifies that the architecture itself prevents constitutional violations.
  """
  use ExUnit.Case, async: true

  alias Tiannara.Discovery.{Discovery, HypothesisGenerator, PredictionEngine, ExperimentPlanner, EvidenceIntegrator, DiscoveryLineage}
  alias Tiannara.Discovery.Domain.{KnowledgeGap, DiscoveryResult}
  alias Tiannara.Engineering.{DesignTranslator, DesignEvaluator, VerificationPlanner}
  alias Tiannara.Engineering.Domain.EngineeringInsight
  alias Tiannara.Simulation.{ScenarioBuilder, ImpactForecaster}
  alias Tiannara.HAI.{ExplainabilityBridge, DiscoveryPresenter}
  alias Tiannara.HAI.Domain.ReviewRequest

  @moduletag :constitutional
  @moduletag :phase4

  describe "Scientific Method compliance" do
    test "every hypothesis is falsifiable" do
      gap = KnowledgeGap.new(%{domain: :test, description: "test", severity: :high, source: :epistemic_integrity})
      hypotheses = HypothesisGenerator.generate(gap)

      Enum.each(hypotheses, fn hyp ->
        assert hyp.falsifiable == true, "Hypothesis #{hyp.id} is not falsifiable"
      end)
    end

    test "every hypothesis produces at least one falsifiable prediction" do
      gap = KnowledgeGap.new(%{domain: :test, description: "test", severity: :high, source: :epistemic_integrity})
      hypotheses = HypothesisGenerator.generate(gap)

      Enum.each(hypotheses, fn hyp ->
        predictions = PredictionEngine.generate(hyp)
        assert length(predictions) >= 1, "Hypothesis #{hyp.id} has no predictions"

        Enum.each(predictions, fn pred ->
          assert pred.falsification_criteria != nil and pred.falsification_criteria != "",
            "Prediction #{pred.id} has no falsification criteria"
        end)
      end)
    end

    test "evidence integration never bypasses KnowledgeCoordinator" do
      # EvidenceIntegrator produces actions, never calls KnowledgeCoordinator directly
      gap = KnowledgeGap.new(%{domain: :test, description: "test", severity: :high, source: :epistemic_integrity})
      disc = Discovery.from_gap(gap)

      results = [DiscoveryResult.new(%{
        experiment_id: "e1", hypothesis_id: "h1",
        outcome: :confirmed, evidence: [%{x: 1}],
        confidence_delta: 0.2, posterior: 0.7
      })]

      actions = EvidenceIntegrator.process_results(disc, results)

      # All actions are data — no direct service calls
      assert Enum.all?(actions, fn action ->
        case action do
          {:fuse_evidence, _, _, _} -> true
          {:update_discovery, _, _} -> true
          {:record_conflict, _} -> true
          {:promote_knowledge, _, _} -> true
          _ -> false
        end
      end)
    end
  end

  describe "Evidence Before Confidence compliance" do
    test "hypothesis priors are never 1.0 (absolute certainty)" do
      gap = KnowledgeGap.new(%{domain: :test, description: "test", severity: :critical, estimated_impact: 1.0, source: :epistemic_integrity})
      hypotheses = HypothesisGenerator.generate(gap)

      Enum.each(hypotheses, fn hyp ->
        assert hyp.prior < 1.0, "Hypothesis #{hyp.id} has prior = 1.0 (absolute certainty)"
        assert hyp.prior > 0.0, "Hypothesis #{hyp.id} has prior = 0.0 (impossible)"
      end)
    end

    test "discovery confidence starts at 0.0 (no prior belief)" do
      gap = KnowledgeGap.new(%{domain: :test, description: "test", severity: :high, source: :epistemic_integrity})
      disc = Discovery.from_gap(gap)

      assert disc.confidence == 0.0
      assert disc.uncertainty == 1.0
    end

    test "confidence only increases through evidence" do
      gap = KnowledgeGap.new(%{domain: :test, description: "test", severity: :high, source: :epistemic_integrity})
      disc = Discovery.from_gap(gap)

      # Before evidence
      assert disc.confidence == 0.0

      # After evidence
      results = [DiscoveryResult.new(%{
        experiment_id: "e1", hypothesis_id: "h1",
        outcome: :confirmed, evidence: [%{x: 1}],
        confidence_delta: 0.3, posterior: 0.8
      })]

      disc = Discovery.add_evidence(disc, results)
      assert disc.confidence > 0.0
    end
  end

  describe "Uncertainty Never Hidden compliance" do
    test "every discovery tracks both confidence AND uncertainty" do
      gap = KnowledgeGap.new(%{domain: :test, description: "test", severity: :high, source: :epistemic_integrity})
      disc = Discovery.from_gap(gap)

      assert Map.has_key?(disc, :confidence)
      assert Map.has_key?(disc, :uncertainty)
      assert_in_delta disc.confidence + disc.uncertainty, 1.0, 0.01
    end

    test "every explanation includes uncertainty" do
      gap = KnowledgeGap.new(%{domain: :test, description: "test", severity: :high, source: :epistemic_integrity})
      disc = Discovery.from_gap(gap)

      explanation = ExplainabilityBridge.explain_discovery(disc)
      assert Map.has_key?(explanation, :uncertainty)
      assert explanation.uncertainty >= 0.0
    end

    test "every impact assessment includes uncertainty" do
      insight = EngineeringInsight.new(%{
        source_discovery_id: "disc_1",
        principle_statement: "Test",
        domain: :test,
        confidence: 0.8,
        evidence_count: 3
      })

      [design | _] = DesignTranslator.translate(insight)
      scenario = ScenarioBuilder.build(design)
      assessment = ImpactForecaster.forecast(scenario)

      assert Map.has_key?(assessment, :uncertainty)
      assert assessment.uncertainty >= 0.0
      assert_in_delta assessment.confidence + assessment.uncertainty, 1.0, 0.01
    end
  end

  describe "Human Judgment Preserved compliance" do
    test "high-impact decisions require mandatory human review" do
      [:high, :critical, :civilizational]
      |> Enum.each(fn level ->
        request = ReviewRequest.new(%{impact_level: level})
        assert ReviewRequest.mandatory_review?(request),
          "Impact level #{level} should require mandatory review"
      end)
    end

    test "low-impact decisions are auto-approved (not blocked)" do
      request = ReviewRequest.new(%{impact_level: :low})
      refute ReviewRequest.mandatory_review?(request)
    end

    test "every presentation includes limitations (intellectual honesty)" do
      gap = KnowledgeGap.new(%{domain: :test, description: "test", severity: :high, source: :epistemic_integrity})
      disc = Discovery.from_gap(gap)

      presentation = DiscoveryPresenter.present(disc)
      assert length(presentation.limitations) >= 1
    end
  end

  describe "Verification First compliance" do
    test "every engineering design has a verification plan" do
      insight = EngineeringInsight.new(%{
        source_discovery_id: "disc_1",
        principle_statement: "Test",
        domain: :test,
        confidence: 0.8,
        evidence_count: 3
      })

      designs = DesignTranslator.translate(insight)

      Enum.each(designs, fn design ->
        assert design.verification_plan != nil, "Design #{design.id} has no verification plan"
        assert VerificationPlanner.validate_completeness(design.verification_plan) == :ok
      end)
    end

    test "verification plans include all constitutional categories" do
      insight = EngineeringInsight.new(%{
        source_discovery_id: "disc_1",
        principle_statement: "Test",
        domain: :test,
        confidence: 0.8,
        evidence_count: 3
      })

      [design | _] = DesignTranslator.translate(insight)
      plan = design.verification_plan

      # Constitutional mandate: unit, integration, stress, regression, adversarial, scalability, failure recovery, performance
      assert length(plan.unit_tests) >= 1
      assert length(plan.integration_tests) >= 1
      assert length(plan.property_tests) >= 1
      assert length(plan.chaos_tests) >= 1
      assert length(plan.performance_tests) >= 1
      assert length(plan.safety_checks) >= 1
      assert length(plan.acceptance_criteria) >= 1
    end
  end

  describe "Lineage Preserved compliance" do
    test "every discovery maintains complete lineage" do
      gap = KnowledgeGap.new(%{domain: :test, description: "test", severity: :high, source: :epistemic_integrity})
      disc = Discovery.from_gap(gap)
      hypotheses = HypothesisGenerator.generate(gap)
      disc = Discovery.add_hypotheses(disc, hypotheses)

      assert length(disc.lineage) >= 2  # creation + hypotheses_added
      assert DiscoveryLineage.check_integrity(disc) == :ok
    end

    test "lineage is append-only (never modified)" do
      gap = KnowledgeGap.new(%{domain: :test, description: "test", severity: :high, source: :epistemic_integrity})
      disc = Discovery.from_gap(gap)

      original_lineage = disc.lineage
      hypotheses = HypothesisGenerator.generate(gap)
      disc = Discovery.add_hypotheses(disc, hypotheses)

      # Original lineage entries are preserved
      assert Enum.take(disc.lineage, length(original_lineage)) == original_lineage
    end
  end

  describe "Modularity compliance" do
    test "all analyzers are pure modules (no GenServer state)" do
      # Verify that analyzers can be called without any GenServer running
      gap = KnowledgeGap.new(%{domain: :test, description: "pure test", severity: :medium, source: :epistemic_integrity})

      # These should all work without any GenServer
      assert is_list(Tiannara.Discovery.GapAnalyzer.analyze(%{}))
      assert is_list(Tiannara.Discovery.ContradictionAnalyzer.analyze([]))
      assert is_list(HypothesisGenerator.generate(gap))

      hypotheses = HypothesisGenerator.generate(gap)
      assert is_list(PredictionEngine.generate(hd(hypotheses)))

      predictions = PredictionEngine.generate(hd(hypotheses))
      assert is_list(ExperimentPlanner.plan(hd(hypotheses), predictions))
    end
  end
end
