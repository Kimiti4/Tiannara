defmodule Tiannara.Sentinel.PatternDetectorTest do
  use ExUnit.Case, async: false

  alias Tiannara.Sentinel.PatternDetector

  defp make_memory_obs(bytes) do
    %{type: :memory_pressure, value: %{total_bytes: bytes}, timestamp: DateTime.utc_now()}
  end

  describe "PatternDetector" do
    test "analyze with empty observations returns empty" do
      assert PatternDetector.analyze([]) == []
    end

    test "analyze with < 3 observations returns empty" do
      assert PatternDetector.analyze([make_memory_obs(100)]) == []
    end

    test "analyze detects memory trends" do
      obs = Enum.map([100, 200, 300, 400, 500], &make_memory_obs/1)
      patterns = PatternDetector.analyze(obs)
      memory_trends = Enum.filter(patterns, fn p -> p.signal == :memory_usage end)
      assert length(memory_trends) > 0
      assert hd(memory_trends).direction == :increasing
    end

    test "tracked_count returns count" do
      assert is_integer(PatternDetector.tracked_count())
    end

    test "status returns detector info" do
      status = PatternDetector.status()
      assert Map.has_key?(status, :active_patterns)
      assert Map.has_key?(status, :total_detections)
      assert Map.has_key?(status, :last_analysis_at)
      assert Map.has_key?(status, :pattern_types)
    end
  end
end
