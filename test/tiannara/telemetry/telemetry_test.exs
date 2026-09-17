defmodule Tiannara.Telemetry.TelemetryTest do
  use ExUnit.Case, async: true

  alias Tiannara.Telemetry.{Observation, RuntimeAdapter, AnomalyDetector, SentinelBridge}

  @moduletag :live_telemetry

  defp obs(id, memory) do
    %Observation{id: id, timestamp: id, source: :test,
                 metrics: %{total_memory: memory, process_count: 10}}
  end

  test "runtime adapter collects real BEAM metrics" do
    observation = RuntimeAdapter.collect([])

    assert is_integer(observation.metrics.total_memory)
    assert is_integer(observation.metrics.process_count)
    assert is_integer(observation.metrics.reductions)
    assert observation.source == :beam_runtime
  end

  test "anomaly detector flags monotonic memory growth" do
    window = for i <- 1..5, do: obs(i, 100 + i * 10)
    # memory: 110, 120, 130, 140, 150 — strictly increasing

    anomalies = AnomalyDetector.detect(window, growth_window: 3)
    assert Enum.any?(anomalies, &(&1.type == :monotonic_memory_growth))
  end

  test "anomaly detector does not flag stable memory" do
    window = for i <- 1..5, do: obs(i, 100)
    anomalies = AnomalyDetector.detect(window, growth_window: 3)
    refute Enum.any?(anomalies, &(&1.type == :monotonic_memory_growth))
  end

  test "anomaly detector flags threshold breaches" do
    window = [obs(1, 100), obs(2, 900)]
    anomalies = AnomalyDetector.detect(window, thresholds: %{total_memory: 500})

    assert Enum.any?(anomalies, fn a ->
             a.type == :metric_threshold_breach and a.metric == :total_memory
           end)
  end

  test "sentinel bridge turns telemetry anomalies into epistemic events" do
    window = for i <- 1..5, do: obs(i, 100 + i * 10)
    anomalies = AnomalyDetector.detect(window, growth_window: 3)
    events = SentinelBridge.to_epistemic_events(anomalies)

    assert length(events) == length(anomalies)
    assert Enum.all?(events, &(&1.type == :anomaly_detected))
  end

  test "build_heartbeat_opts produces a live observer/analyzer pair" do
    opts = SentinelBridge.build_heartbeat_opts(window_size: 3)
    observer = Keyword.fetch!(opts, :observer)
    analyzer = Keyword.fetch!(opts, :analyzer)

    # Observer returns a window of real observations.
    window = observer.()
    assert is_list(window)
    assert Enum.all?(window, &match?(%Observation{}, &1))

    # Analyzer returns a list of epistemic events (possibly empty).
    events = analyzer.(window, 1)
    assert is_list(events)
  end
end