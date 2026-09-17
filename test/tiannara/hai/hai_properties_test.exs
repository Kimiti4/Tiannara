defmodule Tiannara.HAI.PropertiesTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Tiannara.HAI.Domain.{ReviewRequest, Explanation, DecisionTrace, ProvenanceGraph, DiscoveryPresentation}
  alias Tiannara.HAI.ExplainabilityBridge
  alias Tiannara.HAI.ReviewRouter
  alias Tiannara.HAI.DecisionTraceExplorer
  alias Tiannara.HAI.DiscoveryPresenter
  alias Tiannara.Discovery.Discovery
  alias Tiannara.Discovery.Domain.HypothesisSpec
  alias Tiannara.Engineering.Domain.EngineeringDesign
  alias Tiannara.Simulation.Domain.ImpactAssessment

  property "ReviewRequest always generates a non-nil id" do
    req = ReviewRequest.new(%{impact_level: :high, source_subsystem: :test,
      decision_type: :test, summary: "Test"})
    assert req.id != nil
    assert String.starts_with?(req.id, "review_")
  end

  property "ReviewRequest.new accepts only valid impact levels" do
    for level <- ReviewRequest.impact_levels() do
      req = ReviewRequest.new(%{impact_level: level, source_subsystem: :test,
        decision_type: :test, summary: "Test"})
      assert req.impact_level == level
    end
  end

  property "only high, critical, and civilizational impact levels are mandatory review" do
    for level <- [:high, :critical, :civilizational] do
      req = %ReviewRequest{impact_level: level}
      assert ReviewRequest.mandatory_review?(req), "#{level} should be mandatory"
    end
    for level <- [:low, :medium] do
      req = %ReviewRequest{impact_level: level}
      refute ReviewRequest.mandatory_review?(req), "#{level} should not be mandatory"
    end
  end

  property "Explanation always has generated_at set" do
    exp = Explanation.new(%{subject_id: "s1", subject_type: :discovery, summary: "Test"})
    assert exp.generated_at != nil
  end

  property "Explanation reasoning_chain defaults to empty list" do
    exp = Explanation.new(%{subject_id: "s1", subject_type: :discovery, summary: "Test"})
    assert exp.reasoning_chain == []
    assert exp.evidence == []
    assert exp.assumptions == []
    assert exp.alternatives_considered == []
    assert exp.limitations == []
  end

  property "DecisionTrace is always replayable by default" do
    trace = DecisionTrace.new(%{decision_id: "d1", subsystem: :test, trigger: "Test"})
    assert trace.replayable == true
  end

  property "ProvenanceGraph nodes and edges default to empty lists" do
    graph = ProvenanceGraph.new(%{root_entity_id: "e1"})
    assert graph.nodes == []
    assert graph.edges == []
  end

  property "DiscoveryPresentation renders without error" do
    disc = %Discovery{
      id: "pres-prop-1", question: "Property test?",
      gap: %{id: "gp1", domain: :physics, severity: :low, description: "Test gap"},
      hypotheses: [%HypothesisSpec{id: "hp1", statement: "H1",
        prior: 0.5, expected_information_gain: 0.4, falsifiable: true}],
      predictions: [], experiments: [], evidence: [],
      confidence: 0.5, uncertainty: 0.5, status: :in_progress,
      lineage: [], created_at: DateTime.utc_now(), updated_at: DateTime.utc_now(), completed_at: nil
    }

    pres = DiscoveryPresenter.present(disc)
    text = DiscoveryPresenter.render_text(pres)

    assert String.contains?(text, "Autonomous Discovery")
    assert String.contains?(text, "HYPOTHESES")
    assert String.contains?(text, "EVIDENCE")
    assert String.contains?(text, "CONCLUSION")
  end

  property "DecisionTraceExplorer can summarize any trace" do
    trace = DecisionTrace.new(%{decision_id: "d1", subsystem: :test,
      trigger: "Test", steps: [
        %{step: 1, event_type: :start, description: "Start", data_summary: %{}},
        %{step: 2, event_type: :end, description: "End", data_summary: %{}}
      ], outputs: %{confidence: 0.5, status: :completed}})

    summary = DecisionTraceExplorer.summarize(trace)
    assert String.contains?(summary, "Decision Trace")
    assert String.contains?(summary, "d1")
    assert String.contains?(summary, "Confidence")
  end

  property "mandatory_review? is consistent with ReviewRouter.mandatory_review?" do
    for level <- [:low, :medium, :high, :critical, :civilizational] do
      req = %ReviewRequest{impact_level: level}
      direct = ReviewRequest.mandatory_review?(req)
      router = ReviewRouter.mandatory_review?(level)
      assert direct == router, "Mismatch for #{level}: domain=#{direct}, router=#{router}"
    end
  end
end
