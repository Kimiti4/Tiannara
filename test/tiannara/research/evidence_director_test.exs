defmodule Tiannara.Research.EvidenceDirectorTest do
  use ExUnit.Case, async: true

  alias Tiannara.Sentinel.EpistemicEvent
  alias Tiannara.Research.Director.EvidenceDriven
  alias Tiannara.Research.ExperimentRanker

  @moduletag :omega2_evidence_driven

  defp contradiction_event do
    EpistemicEvent.new(:contradiction_detected,
      severity: :high,
      payload: %{quantity: :x},
      confidence: 0.7,
      evidence: [%{quantity: :x, value: 10}, %{quantity: :x, value: 20}])
  end

  test "full pipeline: evidence assessment detects the contradiction" do
    result = EvidenceDriven.investigate(contradiction_event())

    assert result.evidence_assessment.sufficiency == :contradicted
    assert length(result.evidence_assessment.contradictions) == 1
    assert hd(result.evidence_assessment.contradictions).quantity == :x
  end

  test "hypotheses carry predictions, falsifiers, and evidence requirements" do
    result = EvidenceDriven.investigate(contradiction_event())

    assert length(result.hypotheses) == 3

    assert Enum.all?(result.hypotheses, &(&1.predictions != []))
    assert Enum.all?(result.hypotheses, &(&1.falsifiers != []))
    assert Enum.all?(result.hypotheses, &(&1.required_evidence != []))
    # contradicted evidence means required evidence is still missing
    assert Enum.all?(result.hypotheses, &(&1.missing_evidence != []))
  end

  test "experiment candidates are generated, ranked, and proposals are :proposed" do
    result = EvidenceDriven.investigate(contradiction_event())

    # 3 hypotheses × 3 archetypes = 9 candidates
    assert length(result.experiment_candidates) == 9

    scores = Enum.map(result.experiment_candidates, & &1.composite_score)
    assert scores == Enum.sort(scores, :desc)

    assert length(result.proposals) == 3
    assert Enum.all?(result.proposals, &(&1.status == :proposed))
    assert Enum.all?(result.proposals, &(length(&1.lineage) == 4))
  end

  test "sufficient evidence yields no missing evidence and full feasibility" do
    event =
      EpistemicEvent.new(:research_opportunity,
        severity: :medium,
        payload: %{},
        confidence: 0.8,
        evidence: [
          %{quantity: :y, value: 1},
          %{quantity: :y, value: 1},
          %{quantity: :y, value: 1}
        ])

    result = EvidenceDriven.investigate(event)

    assert result.evidence_assessment.sufficiency == :sufficient
    assert Enum.all?(result.hypotheses, &(&1.missing_evidence == []))
    assert Enum.all?(result.experiment_candidates, & &1.dependencies_available)
  end

  test "constitutionally-blocked experiments score zero (hard gate)" do
    candidate = %{
      id: :e1, hypothesis_id: :h1,
      expected_information_gain: 0.9, uncertainty_reduction: 0.9,
      scientific_relevance: 0.9, cost: 0.1, risk: 0.1,
      reproducibility: 0.9, feasibility: 1.0,
      constitutional_ok: false, dependencies_available: true
    }

    assert ExperimentRanker.score(candidate).composite_score == 0.0
  end

  test "unavailable dependencies reduce the composite score" do
    base = %{
      id: :e1, hypothesis_id: :h1,
      expected_information_gain: 0.8, uncertainty_reduction: 0.8,
      scientific_relevance: 0.8, cost: 0.2, risk: 0.2,
      reproducibility: 0.8, feasibility: 0.8, constitutional_ok: true
    }

    with_deps = ExperimentRanker.score(Map.put(base, :dependencies_available, true))
    without_deps = ExperimentRanker.score(Map.put(base, :dependencies_available, false))

    assert with_deps.composite_score > without_deps.composite_score
  end

  test "investigation is deterministic" do
    event =
      EpistemicEvent.new(:anomaly_detected,
        severity: :medium, payload: %{a: 1}, confidence: 0.5, evidence: [])

    r1 = EvidenceDriven.investigate(event)
    r2 = EvidenceDriven.investigate(event)

    assert r1.proposals == r2.proposals
    assert r1.uncertainty == r2.uncertainty
    assert r1.evidence_assessment.strength == r2.evidence_assessment.strength
  end

  test "uncertainty is always quantified" do
    result = EvidenceDriven.investigate(contradiction_event())
    assert is_number(result.uncertainty)
    assert result.uncertainty >= 0.0 and result.uncertainty <= 1.0
  end

  test "the director proposes but never executes (authority boundary)" do
    result = EvidenceDriven.investigate(contradiction_event())

    assert Enum.all?(result.proposals, &(&1.status == :proposed))

    refute function_exported?(EvidenceDriven, :execute, 1)
    refute function_exported?(EvidenceDriven, :deploy, 1)
    refute function_exported?(EvidenceDriven, :notify, 1)
  end
end