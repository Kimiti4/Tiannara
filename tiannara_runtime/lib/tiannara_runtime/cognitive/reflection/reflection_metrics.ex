defmodule TiannaraRuntime.Cognitive.Reflection.ReflectionMetrics do
  def initialize do
    %{reflection_count: 0, pattern_count: 0, bias_count: 0, bias_severities: [], outcome_count: 0, lesson_count: 0, session_durations: [], created_at: :erlang.unique_integer([:positive])}
  end

  def record_reflection(metrics, session) do
    %{metrics | reflection_count: Map.get(metrics, :reflection_count, 0) + 1, outcome_count: Map.get(metrics, :outcome_count, 0) + length(Map.get(session, :outcomes, [])), lesson_count: Map.get(metrics, :lesson_count, 0) + length(Map.get(session, :lessons, []))}
  end

  def record_pattern(metrics, _pattern) do
    %{metrics | pattern_count: Map.get(metrics, :pattern_count, 0) + 1}
  end

  def record_bias(metrics, bias) do
    %{metrics | bias_count: Map.get(metrics, :bias_count, 0) + 1, bias_severities: Map.get(metrics, :bias_severities, []) ++ [Map.get(bias, :severity, 0.0)]}
  end

  def summary(metrics) do
    sevs = Map.get(metrics, :bias_severities, [])
    avg_bias = if sevs == [], do: 0.0, else: Enum.sum(sevs) / length(sevs)
    {:ok, %{reflection_count: Map.get(metrics, :reflection_count, 0), pattern_count: Map.get(metrics, :pattern_count, 0), bias_count: Map.get(metrics, :bias_count, 0), outcome_count: Map.get(metrics, :outcome_count, 0), lesson_count: Map.get(metrics, :lesson_count, 0), average_bias_severity: avg_bias}}
  end
end
