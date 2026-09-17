defmodule TiannaraRuntime.Cognitive.Metacognition.SelfMonitor do
  @moduledoc "Phase 18.8 — Self-monitoring of cognitive state dimensions"

  def measure(cognitive_state) do
    state_size = map_size(cognitive_state)
    cognitive_load = min(state_size / 100.0, 1.0)
    throughput = Map.get(cognitive_state, :throughput, 0.0)
    error_count = Map.get(cognitive_state, :error_count, 0)
    total = max(Map.get(cognitive_state, :total_operations, 1), 1)
    error_rate = error_count / total
    latency_ms = Map.get(cognitive_state, :latency_ms, 0.0)
    mem_used = Map.get(cognitive_state, :memory_used, 0)
    mem_limit = max(Map.get(cognitive_state, :memory_limit, 1), 1)
    memory_pressure = min(max(mem_used / mem_limit, 0.0), 1.0)
    {:ok, %{cognitive_load: cognitive_load, throughput: throughput, error_rate: error_rate, latency_ms: latency_ms, memory_pressure: memory_pressure, monitored_at: :erlang.unique_integer([:positive])}}
  end

  def track(state, history) do
    updated = if is_list(history), do: history ++ [state], else: [state]
    {:ok, updated}
  end

  def trend(history, window) do
    monitors = if is_list(history), do: history, else: []
    recent = Enum.take(monitors, -window)
    count = length(recent)
    avg = fn key ->
      values = Enum.map(recent, &Map.get(&1, key, 0.0))
      if count > 0, do: Enum.sum(values) / count, else: 0.0
    end
    {:ok, %{cognitive_load: avg.(:cognitive_load), throughput: avg.(:throughput), error_rate: avg.(:error_rate), latency_ms: avg.(:latency_ms), memory_pressure: avg.(:memory_pressure), window: window}}
  end
end
