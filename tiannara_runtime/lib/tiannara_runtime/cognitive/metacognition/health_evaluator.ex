defmodule TiannaraRuntime.Cognitive.Metacognition.HealthEvaluator do
  @moduledoc "Phase 18.8 — Evaluate cognitive health across multiple dimensions"

  def assess(monitor_history, config) do
    monitors = if is_list(monitor_history), do: Enum.take(monitor_history, -50), else: []
    count = length(monitors)
    avg = fn key ->
      if count > 0, do: Enum.reduce(monitors, 0.0, fn m, acc -> acc + Map.get(m, key, 0.0) end) / count, else: 0.0
    end
    avg_load = avg.(:cognitive_load)
    avg_error = avg.(:error_rate)
    avg_latency = avg.(:latency_ms)
    avg_pressure = avg.(:memory_pressure)
    avg_throughput = avg.(:throughput)
    lat_variance = if count < 2 do
      0.0
    else
      variance = Enum.reduce(monitors, 0.0, fn m, acc -> acc + (Map.get(m, :latency_ms, 0.0) - avg_latency) ** 2 end) / count
      min(variance / 1000.0, 1.0)
    end
    stability = 1.0 - min(avg_load + avg_error, 1.0)
    max_tp = max(Map.get(config, :max_throughput, 100.0), 0.001)
    throughput_health = min(avg_throughput / max_tp, 1.0)
    dimensions = %{cognitive_load: min(avg_load, 1.0), error_density: min(avg_error, 1.0), response_time_variance: lat_variance, resource_pressure: min(avg_pressure, 1.0), stability_index: max(stability, 0.0), throughput_health: throughput_health}
    overall = Enum.sum(Map.values(dimensions)) / map_size(dimensions)
    status = if overall < 0.4, do: :healthy, else: if overall < 0.7, do: :degraded, else: :critical
    {:ok, %{dimensions: dimensions, overall: overall, status: status, assessed_at: :erlang.unique_integer([:positive])}}
  end

  def compare(health_a, health_b) do
    dims_a = Map.get(health_a, :dimensions, %{})
    dims_b = Map.get(health_b, :dimensions, %{})
    all_keys = MapSet.to_list(MapSet.union(MapSet.new(Map.keys(dims_a)), MapSet.new(Map.keys(dims_b))))
    deltas = Map.new(all_keys, fn k -> {k, Map.get(dims_b, k, 0.0) - Map.get(dims_a, k, 0.0)} end)
    {:ok, %{deltas: deltas, overall_delta: Map.get(health_b, :overall, 0.0) - Map.get(health_a, :overall, 0.0), status_change: {Map.get(health_a, :status), Map.get(health_b, :status)}}}
  end
end
