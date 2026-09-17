defmodule Tiannara.Sentinel.PriorityEngineTest do
  use ExUnit.Case, async: false

  alias Tiannara.Sentinel.PriorityEngine

  describe "PriorityEngine" do
    test "priorities returns empty initially" do
      assert PriorityEngine.priorities() == []
    end

    test "update generates priorities from anomalies" do
      anomalies = [%{id: "a1", severity: :critical, type: :threshold, domain: :memory, signal: :total_memory, value: 5_000_000_000, threshold: 4_294_967_296, confidence: 0.95, rationale: "Critical memory", evidence: []}]
      assert :ok = PriorityEngine.update(anomalies, [])
      priorities = PriorityEngine.priorities()
      assert length(priorities) > 0
      assert hd(priorities).level == :immediate
    end

    test "update generates priorities from patterns" do
      patterns = [%{id: "p1", type: :trend, signal: :memory_usage, direction: :increasing, confidence: 0.95, magnitude: 0.5, rationale: "Increasing memory trend"}]
      assert :ok = PriorityEngine.update([], patterns)
      priorities = PriorityEngine.priorities()
      assert length(priorities) > 0
    end

    test "active_count returns count" do
      assert is_integer(PriorityEngine.active_count())
    end

    test "status returns engine info" do
      status = PriorityEngine.status()
      assert Map.has_key?(status, :active_priorities)
      assert Map.has_key?(status, :total_generated)
      assert Map.has_key?(status, :last_update_at)
      assert Map.has_key?(status, :levels)
    end

    test "priorities sorted by score descending" do
      anomalies = [
        %{id: "a1", severity: :critical, type: :threshold, domain: :memory, signal: :total_memory, value: 1, threshold: nil, confidence: 0.95, rationale: "test", evidence: []},
        %{id: "a2", severity: :info, type: :trend, domain: :performance, signal: :latency, value: 1, threshold: nil, confidence: 0.5, rationale: "test", evidence: []}
      ]
      PriorityEngine.update(anomalies, [])
      priorities = PriorityEngine.priorities()
      if length(priorities) >= 2 do
        scores = Enum.map(priorities, & &1.score)
        assert scores == Enum.sort(scores, :desc)
      end
    end
  end
end
