defmodule Tiannara.Discovery.DiscoveryMetricsPropertiesTest do
  use ExUnit.Case, async: false
  use ExUnitProperties

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

  describe "KPI invariants" do
    property "health_score is always in [0.0, 1.0]" do
      check all discoveries <- integer(0..50),
                supported <- integer(0..20),
                falsified <- integer(0..20),
                inconclusive <- integer(0..20) do
        pid = Process.whereis(DiscoveryMetrics)
        if discoveries > 0 do
          Enum.each(1..discoveries, fn _ ->
            DiscoveryMetrics.track_event(:discovery_created, %{gap_id: "gap_prop"})
          end)
          Enum.each(1..discoveries, fn _ ->
            DiscoveryMetrics.track_event(:discovery_completed, %{})
          end)
        end
        if supported > 0 do
          Enum.each(1..supported, fn _ ->
            DiscoveryMetrics.track_event(:outcome_recorded, %{outcome: :supported, stage: :prop, duration_ms: 50})
          end)
        end
        if falsified > 0 do
          Enum.each(1..falsified, fn _ ->
            DiscoveryMetrics.track_event(:outcome_recorded, %{outcome: :falsified, stage: :prop, duration_ms: 30})
          end)
        end
        if inconclusive > 0 do
          Enum.each(1..inconclusive, fn _ ->
            DiscoveryMetrics.track_event(:outcome_recorded, %{outcome: :inconclusive, stage: :prop, duration_ms: 10})
          end)
        end
        :timer.sleep(50)
        score = GenServer.call(pid, :health_score)
        assert is_float(score)
        assert score >= 0.0 and score <= 1.0
      end
    end

    property "success_rate is always between 0 and 1" do
      check all supported <- integer(0..10),
                total <- integer(0..20) do
        pid = Process.whereis(DiscoveryMetrics)
        if supported > 0 do
          Enum.each(1..supported, fn _ ->
            DiscoveryMetrics.track_event(:outcome_recorded, %{outcome: :supported, stage: :prop, duration_ms: 50})
          end)
        end
        falsified_count = max(0, total - supported)
        if falsified_count > 0 do
          Enum.each(1..falsified_count, fn _ ->
            DiscoveryMetrics.track_event(:outcome_recorded, %{outcome: :falsified, stage: :prop, duration_ms: 30})
          end)
        end
        :timer.sleep(50)
        rate = GenServer.call(pid, :experiment_success_rate)
        assert rate.rate >= 0.0 and rate.rate <= 1.0
      end
    end

    property "average_confidence_delta does not exceed valid range" do
      check all deltas <- list_of(float(min: -0.5, max: 0.5), max_length: 10) do
        pid = Process.whereis(DiscoveryMetrics)
        Enum.each(deltas, fn d ->
          DiscoveryMetrics.track_event(:evidence_collected, %{evidence_count: 1, confidence_delta: d})
        end)
        :timer.sleep(50)
        avg = GenServer.call(pid, :average_confidence_delta)
        assert avg >= -0.5 and avg <= 0.5
      end
    end

    property "metrics_summary is self-consistent" do
      check all disco_init <- integer(0..10),
                disco_comp <- integer(0..10) do
        pid = Process.whereis(DiscoveryMetrics)
        if disco_init > 0 do
          Enum.each(1..disco_init, fn _ ->
            DiscoveryMetrics.track_event(:discovery_created, %{gap_id: "prop"})
          end)
        end
        comp_count = min(disco_comp, disco_init)
        if comp_count > 0 do
          Enum.each(1..comp_count, fn _ ->
            DiscoveryMetrics.track_event(:discovery_completed, %{})
          end)
        end
        :timer.sleep(50)
        summary = GenServer.call(pid, :metrics_summary)
        assert summary.discoveries.initiated >= summary.discoveries.completed
        assert summary.discoveries.completed + summary.discoveries.abandoned <= summary.discoveries.initiated
      end
    end
  end
end
