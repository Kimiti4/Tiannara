defmodule Tiannara.Sentinel.SentinelRuntimeTest do
  use ExUnit.Case, async: false

  alias Tiannara.Sentinel.{SentinelRuntime, ObservationBuffer, PatternDetector, AnomalyClassifier, PriorityEngine}

  describe "SentinelRuntime" do
    test "status returns all subsystem statuses" do
      status = SentinelRuntime.status()
      assert Map.has_key?(status, :scheduler)
      assert Map.has_key?(status, :buffer)
      assert Map.has_key?(status, :patterns)
      assert Map.has_key?(status, :anomalies)
      assert Map.has_key?(status, :priorities)
    end

    test "health returns runtime health map" do
      health = SentinelRuntime.health()
      assert health.status == :healthy
      assert is_integer(health.observations_total)
      assert is_integer(health.anomalies_detected)
      assert is_integer(health.active_priorities)
      assert is_integer(health.patterns_tracked)
    end

    test "recent_observations returns empty list initially" do
      assert SentinelRuntime.recent_observations(10) == []
    end

    test "research_priorities returns list" do
      assert is_list(SentinelRuntime.research_priorities())
    end
  end
end
