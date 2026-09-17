defmodule Tiannara.Research.ResearchDirectorTest do
  use ExUnit.Case, async: false

  alias Tiannara.Research.ResearchDirector

  describe "ResearchDirector" do
    test "status returns all subsystem statuses" do
      status = ResearchDirector.status()
      assert Map.has_key?(status, :queue)
      assert Map.has_key?(status, :ranker)
      assert Map.has_key?(status, :planner)
      assert Map.has_key?(status, :scorer)
      assert Map.has_key?(status, :integrator)
    end

    test "health returns director health map" do
      health = ResearchDirector.health()
      assert health.status == :healthy
      assert is_integer(health.active_hypotheses)
      assert is_integer(health.pending_experiments)
      assert is_integer(health.running_experiments)
    end

    test "ingest_priorities generates hypotheses" do
      priorities = [%{id: "p1", domain: :memory, signal: :total_memory, score: 0.9, rationale: "test priority", recommended_action: "investigate"}]
      assert {:ok, count} = ResearchDirector.ingest_priorities(priorities)
      assert is_integer(count)
      assert count > 0
    end

    test "advance processes pipeline" do
      assert :ok = ResearchDirector.advance()
    end

    test "validated_knowledge returns list" do
      assert is_list(ResearchDirector.validated_knowledge())
    end
  end
end
