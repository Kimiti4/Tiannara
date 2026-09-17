defmodule TiannaraRuntime.Cognitive.Reflection.MetaCognitionController do
  def initialize(outcomes, patterns, biases, lessons) do
    diversity = outcome_diversity(outcomes)
    awareness = min(0.3 + diversity * 0.5, 1.0)
    readiness = min(length(lessons) * 0.15, 1.0)
    {:ok, %{
      awareness_level: awareness,
      adaptation_readiness: readiness,
      bias_profile: biases,
      pattern_library: patterns,
      lesson_library: lessons,
      outcome_count: length(outcomes),
      dimension_samples: Enum.map(outcomes, fn o -> Map.get(o, :success_score, 0.0) end),
      version: 1
    }}
  end

  def update(state, new_outcome, new_patterns, new_biases, new_lessons) do
    prev_samples = Map.get(state, :dimension_samples, [])
    all_scores = prev_samples ++ [Map.get(new_outcome, :success_score, 0.0)]
    diversity = if length(all_scores) <= 1 do
      0.0
    else
      mean = Enum.sum(all_scores) / length(all_scores)
      variance = Enum.sum(Enum.map(all_scores, fn s -> :math.pow(s - mean, 2) end)) / length(all_scores)
      min(:math.sqrt(variance) * 2.0, 1.0)
    end
    awareness = min(0.3 + diversity * 0.5, 1.0)
    total_lessons = Map.get(state, :lesson_library, []) ++ new_lessons
    readiness = min(length(total_lessons) * 0.15, 1.0)
    {:ok, %{state |
      awareness_level: awareness,
      adaptation_readiness: readiness,
      bias_profile: Map.get(state, :bias_profile, []) ++ new_biases,
      pattern_library: Map.get(state, :pattern_library, []) ++ new_patterns,
      lesson_library: total_lessons,
      outcome_count: Map.get(state, :outcome_count, 0) + 1,
      dimension_samples: all_scores,
      version: Map.get(state, :version, 0) + 1
    }}
  end

  def awareness_level(state) do
    {:ok, Map.get(state, :awareness_level, 0.0)}
  end

  def adaptation_readiness(state) do
    {:ok, Map.get(state, :adaptation_readiness, 0.0)}
  end

  def summarize(state) do
    summary = "Meta-Cognition: awareness #{Float.round(Map.get(state, :awareness_level, 0.0), 3)}, readiness #{Float.round(Map.get(state, :adaptation_readiness, 0.0), 3)}, outcomes #{Map.get(state, :outcome_count, 0)}, patterns #{length(Map.get(state, :pattern_library, []))}, lessons #{length(Map.get(state, :lesson_library, []))}, version #{Map.get(state, :version, 0)}"
    {:ok, summary}
  end

  defp outcome_diversity(outcomes) do
    scores = Enum.map(outcomes, fn o -> Map.get(o, :success_score, 0.0) end)
    case length(scores) do
      0 -> 0.0
      1 -> 0.0
      n ->
        mean = Enum.sum(scores) / n
        variance = Enum.sum(Enum.map(scores, fn s -> :math.pow(s - mean, 2) end)) / n
        min(:math.sqrt(variance) * 2.0, 1.0)
    end
  end
end
