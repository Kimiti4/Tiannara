defmodule Tiannara.HAI.ExplainabilityBridgeTest do
  use ExUnit.Case, async: true

  alias Tiannara.HAI.ExplainabilityBridge
  alias Tiannara.HAI.Domain.Explanation
  alias Tiannara.Discovery.Discovery
  alias Tiannara.Discovery.Domain.HypothesisSpec
  alias Tiannara.Engineering.Domain.EngineeringDesign
  alias Tiannara.Simulation.Domain.ImpactAssessment

  describe "explain_discovery/1" do
    test "generates explanation for a completed discovery" do
      disc = %Discovery{
        id: "disc-1", question: "Is P = NP?",
        gap: %{id: "gap-1", domain: :computation, severity: :high, source: :contradiction,
          description: "The P vs NP problem remains unresolved"},
        hypotheses: [%HypothesisSpec{id: "hyp-1", statement: "P != NP",
          prior: 0.8, expected_information_gain: 0.5, falsifiable: true}],
        predictions: [%{id: "pred-1"}], experiments: [%{id: "exp-1", type: :theoretical}],
        evidence: [%{experiment_id: "exp-1", outcome: :supported,
          confidence_delta: 0.05, evidence: []}],
        confidence: 0.85, uncertainty: 0.15, status: :completed,
        conclusion: %{summary: "Strong evidence suggests P != NP"},
        lineage: [%{event: :belief_updated, new_confidence: 0.85, at: DateTime.utc_now()}],
        created_at: DateTime.utc_now(), updated_at: DateTime.utc_now(), completed_at: DateTime.utc_now()
      }

      explanation = ExplainabilityBridge.explain_discovery(disc)

      assert %Explanation{} = explanation
      assert explanation.subject_type == :discovery
      assert explanation.subject_id == "disc-1"
      assert explanation.confidence == 0.85
      assert length(explanation.reasoning_chain) >= 6
      assert length(explanation.evidence) == 1
    end

    test "includes limitations for low evidence" do
      disc = %Discovery{
        id: "disc-2", question: "Test question?",
        gap: %{id: "gap-2", domain: :physics, severity: :medium, source: :observation, description: "Test"},
        hypotheses: [%HypothesisSpec{id: "hyp-2", statement: "Test hyp",
          prior: 0.5, expected_information_gain: 0.3, falsifiable: true}],
        predictions: [], experiments: [],
        evidence: [], confidence: 0.6, uncertainty: 0.4, status: :in_progress,
        lineage: [], created_at: DateTime.utc_now(), updated_at: DateTime.utc_now(), completed_at: nil
      }

      explanation = ExplainabilityBridge.explain_discovery(disc)
      assert length(explanation.limitations) > 0
    end
  end

  describe "explain_design/1" do
    test "generates explanation for an engineering design" do
      design = %EngineeringDesign{
        id: "design-1", name: "Test Design", insight_id: "insight-1",
        description: "Test principle", feasibility: 0.75,
        safety_score: 0.9, risk: :low,
        components: [%{name: "comp1"}, %{name: "comp2"}],
        architecture: %{pattern: :modular}
      }

      explanation = ExplainabilityBridge.explain_design(design)

      assert %Explanation{} = explanation
      assert explanation.subject_type == :engineering_design
      assert String.contains?(explanation.summary, "Test Design")
      assert length(explanation.reasoning_chain) == 5
    end
  end

  describe "explain_impact/1" do
    test "generates explanation for an impact assessment" do
      assessment = %ImpactAssessment{
        id: "ia-1", design_id: "design-1",
        scientific_impact: 0.7, engineering_impact: 0.6,
        civilizational_impact: 0.3, sustainability_impact: 0.5,
        safety_impact: 0.8, economic_impact: 0.4,
        composite_score: 0.55, confidence: 0.7,
        uncertainty: 0.3, recommendation: :proceed,
        horizon_forecasts: [%{horizon_years: 10, confidence: 0.6}]
      }

      explanation = ExplainabilityBridge.explain_impact(assessment)

      assert %Explanation{} = explanation
      assert explanation.subject_type == :impact_assessment
      assert String.contains?(explanation.summary, "proceed")
      assert length(explanation.evidence) == 1
    end
  end
end
