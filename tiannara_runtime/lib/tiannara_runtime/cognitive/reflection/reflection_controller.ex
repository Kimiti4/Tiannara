defmodule TiannaraRuntime.Cognitive.Reflection.ReflectionController do
  def initialize(state, config) do
    defaults = %{max_outcomes: 100, max_patterns: 50, max_lessons: 50, max_biases: 20}
    merged = Map.merge(defaults, config)
    {:ok, Map.put(state, :reflection_config, merged)}
  end

  def start_session(_controller, mission_id, decision_id) do
    session = %{id: :erlang.unique_integer([:positive]), mission_id: mission_id, decision_id: decision_id, status: :initiated, outcomes: [], patterns: [], lessons: [], bias_assessments: [], meta_state: %{}}
    {:ok, session}
  end

  def add_outcome(session, outcome) do
    {:ok, %{session | outcomes: Map.get(session, :outcomes, []) ++ [outcome]}}
  end

  def add_pattern(session, pattern) do
    {:ok, %{session | patterns: Map.get(session, :patterns, []) ++ [pattern]}}
  end

  def add_lesson(session, lesson) do
    {:ok, %{session | lessons: Map.get(session, :lessons, []) ++ [lesson]}}
  end

  def add_bias(session, bias) do
    {:ok, %{session | bias_assessments: Map.get(session, :bias_assessments, []) ++ [bias]}}
  end

  def finalize(session) do
    meta = Map.get(session, :meta_state, %{})
    updated = %{session | status: :completed, meta_state: Map.put(meta, :version, Map.get(meta, :version, 0) + 1)}
    {:ok, updated}
  end

  def summarize(session) do
    {:ok, %{outcome_count: length(Map.get(session, :outcomes, [])), pattern_count: length(Map.get(session, :patterns, [])), lesson_count: length(Map.get(session, :lessons, [])), bias_count: length(Map.get(session, :bias_assessments, [])), status: Map.get(session, :status)}}
  end
end
