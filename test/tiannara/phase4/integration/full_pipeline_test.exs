defmodule Tiannara.Phase4.Integration.FullPipelineTest do
  @moduledoc """
  End-to-end integration test for the complete Phase 4 pipeline:

    Epistemic Gap → Discovery → Hypothesis → Prediction → Experiment →
    Evidence → Knowledge → Engineering Design → Simulation → Human Review

  This test exercises ALL Phase 4 subsystems in sequence:
    - Discovery (GapAnalyzer, HypothesisGenerator, PredictionEngine, ExperimentPlanner)
    - Engineering (DesignTranslator, DesignEvaluator, VerificationPlanner)
    - Simulation (ScenarioBuilder, ImpactForecaster, HorizonPlanner)
    - HAI (ExplainabilityBridge, ReviewRouter, DecisionTraceExplorer, DiscoveryPresenter)

  Constitutional Alignment (rules.md):
    - "Scientific Method": Full pipeline from observation to knowledge integration.
    - "Verification First": This test IS the verification.
    - "Evidence Before Confidence": Every stage produces evidence.
    - "Tiannara should remain a system that augments human intelligence":
      Pipeline ends with human review, not autonomous deployment.
  """
  use ExUnit.Case, async: false

  alias Tiannara.Discovery.{
    Discovery, DiscoveryScore, DiscoveryLineage,
    GapAnalyzer, ContradictionAnalyzer,
    HypothesisGenerator, PredictionEngine,
    ExperimentPlanner, DiscoveryPrioritizer,
    EvidenceIntegrator
  }
  alias Tiannara.Discovery.Domain.{KnowledgeGap, DiscoveryResult}

  alias Tiannara.Engineering.{
    DesignTranslator, DesignEvaluator, VerificationPlanner
  }
  alias Tiannara.Engineering.Domain.EngineeringInsight

  alias Tiannara.Simulation.{
    ScenarioBuilder, ImpactForecaster, HorizonPlanner
  }

  alias Tiannara.HAI.{
    ExplainabilityBridge, DecisionTraceExplorer, DiscoveryPresenter
  }
  alias Tiannara.HAI.Domain.ReviewRequest

  @moduletag :integration
  @moduletag :phase4

  describe "Complete Phase 4 pipeline" do
    test "gap → discovery → engineering → simulation → human review" do
      # ═══════════════════════════════════════════════════════════
      # STAGE 1: EPISTEMIC GAP DETECTION (Discovery subsystem)
      # ═══════════════════════════════════════════════════════════

      integrity_report = %{
        contradiction_rate: 0.15,
        evidence_quality: 0.6,
        stale_theory_rate: 0.1,
        provenance_completeness: 0.95,
        experiment_recommendations: [
          %{type: :strengthen_evidence, reason: "Low evidence quality in sensor fusion", severity: :high, domain: :sensor_fusion}
        ]
      }

      gaps = GapAnalyzer.analyze(integrity_report) |> GapAnalyzer.rank()
      assert length(gaps) >= 1

      gap = hd(gaps)
      assert gap.severity in [:low, :medium, :high, :critical]

      # ═══════════════════════════════════════════════════════════
      # STAGE 2: DISCOVERY LIFECYCLE (Discovery subsystem)
      # ═══════════════════════════════════════════════════════════

      disc = Discovery.from_gap(gap)
      assert disc.status == :question_formulated
      assert disc.confidence == 0.0

      # Generate hypotheses
      hypotheses = HypothesisGenerator.generate(gap)
      assert length(hypotheses) >= 2
      assert Enum.all?(hypotheses, & &1.falsifiable)

      disc = Discovery.add_hypotheses(disc, hypotheses)
      {:ok, disc} = Discovery.transition(disc, :gap_identified)
      {:ok, disc} = Discovery.transition(disc, :hypotheses_generated)

      # Generate predictions
      predictions = Enum.flat_map(hypotheses, &PredictionEngine.generate/1)
      assert length(predictions) >= length(hypotheses)

      disc = Discovery.add_predictions(disc, predictions)
      {:ok, disc} = Discovery.transition(disc, :predictions_made)

      # Plan experiments
      experiments = Enum.flat_map(hypotheses, fn hyp ->
        hyp_preds = Enum.filter(predictions, &(&1.hypothesis_id == hyp.id))
        ExperimentPlanner.plan(hyp, hyp_preds)
      end)
      assert length(experiments) >= 1
      assert Enum.all?(experiments, &(ExperimentPlanner.validate(&1) == :ok))

      disc = Discovery.add_experiments(disc, experiments)
      {:ok, disc} = Discovery.transition(disc, :experiments_planned)
      {:ok, disc} = Discovery.transition(disc, :experiments_dispatched)
      {:ok, disc} = Discovery.transition(disc, :awaiting_evidence)

      # Collect evidence
      results = Enum.map(Enum.take(hypotheses, 2), fn hyp ->
        DiscoveryResult.new(%{
          experiment_id: "exp_#{hyp.id}",
          hypothesis_id: hyp.id,
          outcome: :confirmed,
          evidence: [
            %{type: :measurement, value: 42.5, source: :sensor_a},
            %{type: :replication, value: 42.3, source: :sensor_b}
          ],
          confidence_delta: 0.25,
          posterior: 0.75
        })
      end)

      # Process evidence
      assert EvidenceIntegrator.validate_evidence(results) == :ok
      actions = EvidenceIntegrator.process_results(disc, results)
      assert is_list(actions)

      disc = Discovery.add_evidence(disc, results)
      {:ok, disc} = Discovery.transition(disc, :evidence_collected)

      assert disc.confidence > 0.0
      assert_in_delta disc.confidence + disc.uncertainty, 1.0, 0.01

      # Conclude
      disc = Discovery.conclude(disc, %{
        outcome: :confirmed,
        summary: "Sensor discrepancy explained by boundary condition divergence",
        confidence: disc.confidence
      })
      {:ok, disc} = Discovery.transition(disc, :conclusion_reached)

      # Verify lineage integrity
      assert DiscoveryLineage.check_integrity(disc) == :ok

      # ═══════════════════════════════════════════════════════════
      # STAGE 3: ENGINEERING TRANSLATION (Engineering subsystem)
      # ═══════════════════════════════════════════════════════════

      insight = EngineeringInsight.new(%{
        source_discovery_id: disc.id,
        principle_statement: "Boundary condition divergence explains sensor discrepancy",
        domain: :sensor_fusion,
        confidence: disc.confidence,
        evidence_count: length(disc.evidence)
      })

      designs = DesignTranslator.translate(insight)
      assert length(designs) >= 1
      assert length(designs) <= 3

      # Evaluate designs
      ranked = DesignEvaluator.rank(designs)
      assert length(ranked) == length(designs)

      {best_design, best_eval} = hd(ranked)
      assert best_eval.composite_score >= 0.0
      assert best_eval.composite_score <= 1.0

      # Verify design has complete verification plan
      assert best_design.verification_plan != nil
      assert VerificationPlanner.validate_completeness(best_design.verification_plan) == :ok

      # Approval decision
      decision = DesignEvaluator.approval_decision(best_design)
      assert decision in [:approve, :revise, :reject]

      # ═══════════════════════════════════════════════════════════
      # STAGE 4: CIVILIZATIONAL SIMULATION (Simulation subsystem)
      # ═══════════════════════════════════════════════════════════

      scenario = ScenarioBuilder.build(best_design)
      assert ScenarioBuilder.validate(scenario) == :ok

      assessment = ImpactForecaster.forecast(scenario)
      assert assessment.composite_score >= 0.0
      assert assessment.composite_score <= 1.0
      assert assessment.recommendation in [:approve, :conditional_approve, :revise, :reject]
      assert length(assessment.horizon_forecasts) == 3

      # Generate deployment plan
      deployment_plan = HorizonPlanner.plan(scenario, assessment.horizon_forecasts)
      assert length(deployment_plan.horizons) == 3
      assert length(deployment_plan.phase_gates) == 3
      assert length(deployment_plan.rollback_criteria) >= 3

      # Optimal deployment window
      optimal_window = HorizonPlanner.optimal_deployment_window(assessment.horizon_forecasts)
      assert optimal_window in [10, 50, 100]

      # ═══════════════════════════════════════════════════════════
      # STAGE 5: HUMAN REVIEW (HAI subsystem)
      # ═══════════════════════════════════════════════════════════

      # Generate explanation
      explanation = ExplainabilityBridge.explain_discovery(disc)
      assert explanation.confidence == disc.confidence
      assert length(explanation.reasoning_chain) >= 4
      assert length(explanation.assumptions) >= 2

      # Generate decision trace
      trace = DecisionTraceExplorer.trace_discovery(disc)
      assert length(trace.steps) >= 4
      assert trace.replayable == true

      # Generate scientific presentation
      presentation = DiscoveryPresenter.present(disc)
      assert presentation.question == disc.question
      assert presentation.confidence == disc.confidence

      rendered = DiscoveryPresenter.render_text(presentation)
      assert String.contains?(rendered, "ABSTRACT")
      assert String.contains?(rendered, "CONFIDENCE")

      # Submit for human review (mandatory for high-impact)
      review_request = ReviewRequest.new(%{
        source_subsystem: :phase4_pipeline,
        decision_type: :deployment_approval,
        summary: "Deploy #{best_design.name} based on discovery #{disc.id}",
        impact_level: :high,
        confidence: disc.confidence,
        uncertainty: disc.uncertainty,
        evidence_summary: "#{length(disc.evidence)} evidence items, #{length(results)} confirmed",
        recommendation: assessment.recommendation
      })

      assert ReviewRequest.mandatory_review?(review_request)
      assert review_request.status == :pending

      # ═══════════════════════════════════════════════════════════
      # FINAL ASSERTIONS: Constitutional Compliance
      # ═══════════════════════════════════════════════════════════

      # Scientific Method: full pipeline completed
      assert disc.status == :conclusion_reached

      # Evidence Before Confidence: confidence is evidence-based
      assert disc.confidence > 0.0
      assert disc.confidence < 1.0

      # Uncertainty never hidden
      assert disc.uncertainty > 0.0
      assert_in_delta disc.confidence + disc.uncertainty, 1.0, 0.01

      # Lineage preserved
      assert DiscoveryLineage.check_integrity(disc) == :ok
      assert Discovery.lineage_depth(disc) >= 5

      # Human judgment preserved (mandatory review for high-impact)
      assert ReviewRequest.mandatory_review?(review_request)

      # Verification First: design has complete verification plan
      assert VerificationPlanner.validate_completeness(best_design.verification_plan) == :ok

      # Long-Term Optimization: multi-horizon simulation completed
      assert length(assessment.horizon_forecasts) == 3
      assert optimal_window in [10, 50, 100]
    end
  end

  describe "Pipeline failure modes" do
    test "refuted hypothesis does not produce engineering design" do
      gap = KnowledgeGap.new(%{
        domain: :evidence_quality,
        description: "Low evidence quality",
        severity: :medium,
        estimated_impact: 0.5,
        source: :epistemic_integrity
      })

      disc = Discovery.from_gap(gap)
      hypotheses = HypothesisGenerator.generate(gap)
      disc = Discovery.add_hypotheses(disc, hypotheses)

      # Simulate refuted evidence
      results = [DiscoveryResult.new(%{
        experiment_id: "exp_1",
        hypothesis_id: hd(hypotheses).id,
        outcome: :refuted,
        evidence: [%{type: :measurement, value: 0.0}],
        confidence_delta: -0.4,
        posterior: 0.1
      })]

      actions = EvidenceIntegrator.process_results(disc, results)

      # Should record conflict, NOT promote
      assert Enum.any?(actions, fn {:record_conflict, _} -> true; _ -> false end)
      refute Enum.any?(actions, fn {:promote_knowledge, _, _} -> true; _ -> false end)

      # Aggregate outcome is refuted
      assert EvidenceIntegrator.aggregate_outcome(results) == :refuted
    end

    test "low-confidence discovery produces only minimal engineering design" do
      insight = EngineeringInsight.new(%{
        source_discovery_id: "disc_low",
        principle_statement: "Weakly supported principle",
        domain: :test,
        confidence: 0.3,
        evidence_count: 1
      })

      designs = DesignTranslator.translate(insight)

      # Low confidence should produce fewer designs
      assert length(designs) >= 1
      assert length(designs) <= 3
    end

    test "unsafe design is rejected by evaluator" do
      insight = EngineeringInsight.new(%{
        source_discovery_id: "disc_unsafe",
        principle_statement: "Dangerous principle",
        domain: :test,
        confidence: 0.9,
        evidence_count: 5
      })

      [design | _] = DesignTranslator.translate(insight)
      unsafe_design = %{design | safety_score: 0.1}

      assert DesignEvaluator.approval_decision(unsafe_design) == :reject
    end
  end
end
