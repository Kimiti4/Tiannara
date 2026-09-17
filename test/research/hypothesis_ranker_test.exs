defmodule Tiannara.Research.HypothesisRankerTest do
  use ExUnit.Case, async: false

  alias Tiannara.Research.HypothesisRanker

  describe "HypothesisRanker" do
    test "generate_from_priorities returns hypotheses" do
      priorities = [%{id: "p1", domain: :memory, signal: :total_memory, score: 0.9, rationale: "high memory"}]
      hypotheses = HypothesisRanker.generate_from_priorities(priorities)
      assert length(hypotheses) > 0
      assert hd(hypotheses).domain == :memory
    end

    test "generate_from_priorities multiple priorities" do
      priorities = [
        %{id: "p1", domain: :memory, signal: :total_memory, score: 0.9, rationale: "high memory"},
        %{id: "p2", domain: :performance, signal: :latency, score: 0.7, rationale: "slow"}
      ]
      hypotheses = HypothesisRanker.generate_from_priorities(priorities)
      assert length(hypotheses) >= 2
    end

    test "rank sorts by score descending" do
      hypotheses = [
        %{id: "h1", title: "low", eig_score: 0.2, feasibility: 0.2, urgency: 0.2, domain: :memory, signal: :test, source_priority_id: nil, confidence: 0.5, rank_score: 0.0, rationale: "", falsification_criteria: "", evidence_for: [], evidence_against: [], status: :pending, created_at: nil, updated_at: nil, statement: ""},
        %{id: "h2", title: "high", eig_score: 0.9, feasibility: 0.9, urgency: 0.9, domain: :memory, signal: :test, source_priority_id: nil, confidence: 0.5, rank_score: 0.0, rationale: "", falsification_criteria: "", evidence_for: [], evidence_against: [], status: :pending, created_at: nil, updated_at: nil, statement: ""}
      ]
      ranked = HypothesisRanker.rank(hypotheses)
      assert length(ranked) == 2
      assert hd(ranked).id == "h2"
      assert hd(ranked).rank_score > List.last(ranked).rank_score
    end

    test "active_count returns count" do
      assert is_integer(HypothesisRanker.active_count())
    end

    test "status returns ranker info" do
      status = HypothesisRanker.status()
      assert Map.has_key?(status, :total_hypotheses)
      assert Map.has_key?(status, :total_generated)
      assert Map.has_key?(status, :total_ranked)
      assert Map.has_key?(status, :by_status)
    end
  end
end
