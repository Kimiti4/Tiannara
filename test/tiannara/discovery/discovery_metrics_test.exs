defmodule Tiannara.Discovery.DiscoveryMetricsTest do
  use ExUnit.Case, async: false
  alias Tiannara.Discovery.DiscoveryMetrics

  setup do
    case Process.whereis(DiscoveryMetrics) do
      nil ->
        {:ok, pid} = DiscoveryMetrics.start_link([])
        on_exit(fn -> Process.unlink(pid); Process.exit(pid, :normal) end)
      pid ->
        on_exit(fn -> Process.unlink(pid); Process.exit(pid, :normal) end)
    end
    :ok
  end

  describe "tracking discovery events" do
    test "tracks discovery creation" do
      DiscoveryMetrics.track_event(:discovery_created, %{gap_id: "gap_1"})
      :timer.sleep(50)
      summary = DiscoveryMetrics.get_metrics_summary()
      assert summary.discoveries.initiated == 1
    end

    test "tracks discovery completion" do
      DiscoveryMetrics.track_event(:discovery_created, %{gap_id: "gap_1"})
      DiscoveryMetrics.track_event(:discovery_completed, %{})
      :timer.sleep(50)
      summary = DiscoveryMetrics.get_metrics_summary()
      assert summary.discoveries.completed == 1
    end

    test "tracks discovery abandonment" do
      DiscoveryMetrics.track_event(:discovery_created, %{gap_id: "gap_1"})
      DiscoveryMetrics.track_event(:discovery_abandoned, %{})
      :timer.sleep(50)
      summary = DiscoveryMetrics.get_metrics_summary()
      assert summary.discoveries.abandoned == 1
    end

    test "tracks experiment planning" do
      DiscoveryMetrics.track_event(:experiments_planned, %{count: 5})
      :timer.sleep(50)
      assert DiscoveryMetrics.get_metrics_summary().experiments.planned == 5
    end

    test "tracks evidence collection" do
      DiscoveryMetrics.track_event(:evidence_collected, %{evidence_count: 10, confidence_delta: 0.5})
      :timer.sleep(50)
      summary = DiscoveryMetrics.get_metrics_summary()
      assert summary.evidence.collected == 10
    end
  end

  describe "KPI queries" do
    test "discovery velocity returns reasonable values" do
      DiscoveryMetrics.track_event(:discovery_created, %{gap_id: "g1"})
      DiscoveryMetrics.track_event(:discovery_completed, %{})
      :timer.sleep(50)
      velocity = DiscoveryMetrics.get_discovery_velocity()
      assert velocity.completed >= 1
      assert velocity.per_hour > 0
    end

    test "experiment success rate" do
      DiscoveryMetrics.track_event(:outcome_recorded, %{outcome: :supported, stage: :test, duration_ms: 50})
      DiscoveryMetrics.track_event(:outcome_recorded, %{outcome: :falsified, stage: :test, duration_ms: 30})
      :timer.sleep(50)
      rate = DiscoveryMetrics.get_experiment_success_rate()
      assert rate.supported == 1
      assert rate.total == 2
      assert rate.rate == 0.5
    end

    test "bottleneck stage identification" do
      DiscoveryMetrics.track_event(:outcome_recorded, %{outcome: :supported, stage: :analysis, duration_ms: 500})
      DiscoveryMetrics.track_event(:outcome_recorded, %{outcome: :falsified, stage: :execution, duration_ms: 100})
      :timer.sleep(50)
      assert DiscoveryMetrics.get_bottleneck_stage() == :analysis
    end

    test "health score is between 0 and 1" do
      DiscoveryMetrics.track_event(:discovery_created, %{gap_id: "g1"})
      DiscoveryMetrics.track_event(:discovery_completed, %{})
      DiscoveryMetrics.track_event(:outcome_recorded, %{outcome: :supported, stage: :test, duration_ms: 50})
      :timer.sleep(50)
      score = DiscoveryMetrics.get_health_score()
      assert is_float(score)
      assert score >= 0.0 and score <= 1.0
    end
  end

  describe "metrics summary" do
    test "returns complete summary with all KPI groups" do
      DiscoveryMetrics.track_event(:discovery_created, %{gap_id: "g1"})
      DiscoveryMetrics.track_event(:experiments_planned, %{count: 3})
      DiscoveryMetrics.track_event(:evidence_collected, %{evidence_count: 7, confidence_delta: 0.6})
      :timer.sleep(50)
      summary = DiscoveryMetrics.get_metrics_summary()
      assert Map.has_key?(summary, :discoveries)
      assert Map.has_key?(summary, :experiments)
      assert Map.has_key?(summary, :evidence)
      assert Map.has_key?(summary, :outcomes)
      assert Map.has_key?(summary, :health_score)
      assert Map.has_key?(summary, :bottleneck_stage)
    end
  end
end
