defmodule Tiannara.Research.EvidenceScorerTest do
  use ExUnit.Case, async: false

  alias Tiannara.Research.EvidenceScorer

  describe "EvidenceScorer" do
    test "score produces evidence from experiment results" do
      experiment = %{id: "e1", hypothesis: %{id: "h1"}, failure_criteria: ["Must disprove"]}
      results = %{
        executed: true,
        provenance: %{source: "evidence_scorer_test"},
        observations: [
          %{metric: :latency_p99, value: 50, unit: :ms},
          %{metric: :throughput, value: 5000, unit: :ops_per_sec},
          %{metric: :error_rate, value: 0.01, unit: :ratio}
        ]
      }
      evidence = EvidenceScorer.score(experiment, results)
      assert evidence.id
      assert evidence.confidence > 0
      assert evidence.reproducibility > 0
      assert evidence.falsification_attempted == true
    end

    test "score without observations" do
      experiment = %{id: "e2", hypothesis: %{id: "h2"}, failure_criteria: nil}
      results = %{executed: true, observations: [], provenance: %{source: "evidence_scorer_test"}}
      assert {:error, :no_observations} = EvidenceScorer.score(experiment, results)
      assert {:error, :execution_not_verified} = EvidenceScorer.score(experiment, %{observations: [], provenance: %{source: "evidence_scorer_test"}})
    end

    test "weak unfalsified observation yields low confidence" do
      experiment = %{id: "e2", hypothesis: %{id: "h2"}, failure_criteria: nil}
      results = %{
        executed: true,
        provenance: %{source: "evidence_scorer_test"},
        observations: [%{metric: :latency_p99, value: 0.01, unit: :ms}]
      }
      evidence = EvidenceScorer.score(experiment, results)
      assert evidence.confidence < 0.5
      assert evidence.falsification_attempted == false
    end

    test "total_scored returns count" do
      assert is_integer(EvidenceScorer.total_scored())
    end

    test "status returns scorer info" do
      status = EvidenceScorer.status()
      assert Map.has_key?(status, :total_scored)
      assert Map.has_key?(status, :last_score_at)
      assert Map.has_key?(status, :recent_confidences)
    end
  end
end
