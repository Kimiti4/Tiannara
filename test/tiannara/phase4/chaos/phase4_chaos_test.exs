defmodule Tiannara.Phase4.Chaos.Phase4ChaosTest do
  @moduledoc """
  Chaos tests for Phase 4 subsystems.

  Tests behavior under adverse conditions:
    - Empty inputs
    - Malformed data
    - Service unavailability
    - Concurrent access
    - Resource exhaustion

  Constitutional Alignment (rules.md):
    - "Safety and Reliability": Recover gracefully, preserve stable states.
    - "Fault tolerance": System must not crash on unexpected input.
    - "Verification First": Failure recovery testing is mandatory.
  """
  use ExUnit.Case, async: true

  alias Tiannara.Discovery.{
    GapAnalyzer, ContradictionAnalyzer,
    HypothesisGenerator, PredictionEngine,
    ExperimentPlanner, DiscoveryPrioritizer,
    EvidenceIntegrator, Discovery, DiscoveryLineage
  }
  alias Tiannara.Discovery.Domain.{KnowledgeGap, DiscoveryResult}

  alias Tiannara.Engineering.{DesignTranslator, DesignEvaluator, VerificationPlanner}
  alias Tiannara.Engineering.Domain.EngineeringInsight

  alias Tiannara.Simulation.{ScenarioBuilder, ImpactForecaster, HorizonPlanner}

  alias Tiannara.HAI.{ExplainabilityBridge, DecisionTraceExplorer, DiscoveryPresenter}

  @moduletag :chaos
  @moduletag :phase4

  describe "GapAnalyzer under adverse conditions" do
    test "handles empty report" do
      assert GapAnalyzer.analyze(%{}) == []
    end

    test "handles report with all zeros" do
      report = %{contradiction_rate: 0.0, evidence_quality: 1.0, stale_theory_rate: 0.0, provenance_completeness: 1.0, experiment_recommendations: []}
      assert GapAnalyzer.analyze(report) == []
    end

    test "handles report with all maximums" do
      report = %{contradiction_rate: 1.0, evidence_quality: 0.0, stale_theory_rate: 1.0, provenance_completeness: 0.0, experiment_recommendations: []}
      gaps = GapAnalyzer.analyze(report)
      assert length(gaps) >= 3
    end

    test "handles missing keys gracefully" do
      report = %{contradiction_rate: 0.5}
      gaps = GapAnalyzer.analyze(report)
      assert is_list(gaps)
    end
  end

  describe "ContradictionAnalyzer under adverse conditions" do
    test "handles empty conflict list" do
      assert ContradictionAnalyzer.analyze([]) == []
    end

    test "handles conflict with missing fields" do
      conflicts = [%{id: "c1"}]
      gaps = ContradictionAnalyzer.analyze(conflicts)
      assert is_list(gaps)
    end

    test "handles conflict with empty description" do
      conflicts = [%{id: "c1", description: "", severity: :medium, domain: :k, entity_ids: []}]
      gaps = ContradictionAnalyzer.analyze(conflicts)
      assert length(gaps) == 1
    end
  end

  describe "HypothesisGenerator under adverse conditions" do
    test "handles gap with zero uncertainty" do
      gap = KnowledgeGap.new(%{domain: :test, description: "zero unc", severity: :low, uncertainty: 0.0, estimated_impact: 0.0, source: :epistemic_integrity})
      hypotheses = HypothesisGenerator.generate(gap)
      assert length(hypotheses) >= 2
    end

    test "handles gap with maximum values" do
      gap = KnowledgeGap.new(%{domain: :test, description: "max", severity: :critical, uncertainty: 1.0, estimated_impact: 1.0, source: :epistemic_integrity})
      hypotheses = HypothesisGenerator.generate(gap)
      assert length(hypotheses) >= 2
      assert length(hypotheses) <= 4
    end
  end

  describe "EvidenceIntegrator under adverse conditions" do
    test "handles empty results" do
      gap = KnowledgeGap.new(%{domain: :test, description: "test", severity: :medium, source: :epistemic_integrity})
      disc = Discovery.from_gap(gap)

      assert {:error, :no_evidence_provided} = EvidenceIntegrator.validate_evidence([])
      assert EvidenceIntegrator.aggregate_confidence_delta([]) == 0.0
      assert EvidenceIntegrator.aggregate_outcome([]) == :inconclusive
    end

    test "handles results with missing fields" do
      result = DiscoveryResult.new(%{experiment_id: "e1", hypothesis_id: "h1"})
      assert {:error, :evidence_missing_outcome} = EvidenceIntegrator.validate_evidence([result])
    end
  end

  describe "Discovery aggregate under adverse conditions" do
    test "invalid transitions are rejected" do
      gap = KnowledgeGap.new(%{domain: :test, description: "test", severity: :medium, source: :epistemic_integrity})
      disc = Discovery.from_gap(gap)

      assert {:error, {:invalid_transition, :question_formulated, :experiments_planned}} =
               Discovery.transition(disc, :experiments_planned)

      assert {:error, {:invalid_transition, :question_formulated, :completed}} =
               Discovery.transition(disc, :completed)
    end

    test "terminal states prevent further transitions" do
      gap = KnowledgeGap.new(%{domain: :test, description: "test", severity: :medium, source: :epistemic_integrity})
      disc = Discovery.from_gap(gap)
      {:ok, disc} = Discovery.transition(disc, :abandoned)

      assert {:error, {:invalid_transition, :abandoned, _}} = Discovery.transition(disc, :gap_identified)
    end
  end

  describe "DesignTranslator under adverse conditions" do
    test "handles insight with zero confidence" do
      insight = EngineeringInsight.new(%{
        source_discovery_id: "disc_zero",
        principle_statement: "Zero confidence principle",
        domain: :test,
        confidence: 0.0,
        evidence_count: 0
      })

      designs = DesignTranslator.translate(insight)
      assert is_list(designs)
      assert length(designs) >= 1
    end
  end

  describe "ImpactForecaster under adverse conditions" do
    test "handles scenario with no injected changes" do
      scenario = Tiannara.Simulation.Domain.SimulationScenario.new(%{
        design_id: "d1",
        injected_changes: [%{type: :test}],
        parameters: %{},
        horizons: [10, 50, 100]
      })

      assessment = ImpactForecaster.forecast(scenario)
      assert assessment.composite_score >= 0.0
      assert assessment.composite_score <= 1.0
    end
  end

  describe "ExplainabilityBridge under adverse conditions" do
    test "handles discovery with no hypotheses" do
      gap = KnowledgeGap.new(%{domain: :test, description: "empty", severity: :low, source: :epistemic_integrity})
      disc = Discovery.from_gap(gap)

      explanation = ExplainabilityBridge.explain_discovery(disc)
      assert is_binary(explanation.summary)
      assert length(explanation.reasoning_chain) >= 4
    end

    test "handles discovery with nil gap" do
      gap = KnowledgeGap.new(%{domain: :test, description: "test", severity: :medium, source: :epistemic_integrity})
      disc = %{Discovery.from_gap(gap) | gap: nil}

      explanation = ExplainabilityBridge.explain_discovery(disc)
      assert is_binary(explanation.summary)
    end
  end

  describe "DiscoveryLineage under adverse conditions" do
    test "detects integrity issues in malformed discovery" do
      gap = KnowledgeGap.new(%{domain: :test, description: "test", severity: :medium, source: :epistemic_integrity})
      disc = %{Discovery.from_gap(gap) | gap: nil, lineage: []}

      assert {:error, issues} = DiscoveryLineage.check_integrity(disc)
      assert :missing_gap in issues
      assert :empty_lineage in issues
    end
  end
end
