defmodule Tiannara.Metrics.MetricsTest do
  use ExUnit.Case, async: true

  alias Tiannara.Metrics.{ResearchAccelerationTracker, HumanCollaborationTracker}
  alias Tiannara.Discovery.Discovery
  alias Tiannara.Discovery.Domain.KnowledgeGap

  describe "ResearchAccelerationTracker" do
    test "computes metrics for empty discoveries" do
      result = ResearchAccelerationTracker.compute([])

      assert result.sample_size == 0
      assert result.acceleration_ratio == 1.0
    end

    test "computes metrics for completed discoveries" do
      discoveries = Enum.map(1..3, fn _ ->
        gap = KnowledgeGap.new(%{domain: :test, description: "test", severity: :high, source: :epistemic_integrity})
        disc = %{Discovery.from_gap(gap) | created_at: DateTime.add(DateTime.utc_now(), -3600, :second)}
        %{disc | status: :completed, completed_at: DateTime.utc_now()}
      end)

      result = ResearchAccelerationTracker.compute(discoveries)

      assert result.sample_size == 3
      assert result.time_to_discovery_avg >= 0.0
      assert result.throughput_per_day >= 0.0
    end
  end

  describe "HumanCollaborationTracker" do
    test "computes metrics for empty sessions" do
      result = HumanCollaborationTracker.compute([])

      assert result.total_reviews == 0
      assert result.collaboration_score == 0.0
    end

    test "computes metrics for closed sessions" do
      sessions = [
        %{status: :closed, decision: :approved, context: %{system_recommendation: :approved}, opened_at: DateTime.add(DateTime.utc_now(), -60, :second), closed_at: DateTime.utc_now()},
        %{status: :closed, decision: :modified, context: %{system_recommendation: :approved}, opened_at: DateTime.add(DateTime.utc_now(), -120, :second), closed_at: DateTime.utc_now()},
        %{status: :closed, decision: :approved, context: %{system_recommendation: :approved}, opened_at: DateTime.add(DateTime.utc_now(), -30, :second), closed_at: DateTime.utc_now()}
      ]

      result = HumanCollaborationTracker.compute(sessions)

      assert result.total_reviews == 3
      assert result.approval_rate > 0.0
      assert result.modification_rate > 0.0
      assert result.collaboration_score >= 0.0
      assert result.collaboration_score <= 1.0
    end
  end
end
