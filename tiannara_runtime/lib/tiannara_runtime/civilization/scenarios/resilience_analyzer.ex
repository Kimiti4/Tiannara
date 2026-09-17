defmodule TiannaraRuntime.Civilization.Scenarios.ResilienceAnalyzer do
  def initialize do
    {:ok, %{resilience_profiles: [], categories: [:institution, :knowledge, :infrastructure, :governance, :scientific, :economic, :mathematical]}}
  end

  def analyze(analyzer, civilization) do
    categories = Map.get(analyzer, :categories, [])
    scores = Map.new(categories, fn cat -> {cat, score_category(cat, civilization)} end)
    overall = if map_size(scores) > 0 do
      Enum.sum(Map.values(scores)) / map_size(scores)
    else
      0.0
    end
    profile = %{
      id: "profile_#{:erlang.unique_integer([:positive])}",
      scores: scores,
      overall: overall
    }
    {:ok, %{analyzer | resilience_profiles: Map.get(analyzer, :resilience_profiles, []) ++ [profile]}}
  end

  defp score_category(:institution, civ) do
    Map.get(civ, :institutional_health, 0.5) * 0.8 + Map.get(civ, :governance, 0.5) * 0.2
  end

  defp score_category(:knowledge, civ) do
    Map.get(civ, :knowledge_growth, 0.5) * 0.6 + Map.get(civ, :scientific_output, 0.5) * 0.4
  end

  defp score_category(:infrastructure, civ) do
    Map.get(civ, :infrastructure, 0.5) * 0.7 + Map.get(civ, :economic_stability, 0.5) * 0.3
  end

  defp score_category(:governance, civ) do
    Map.get(civ, :institutional_health, 0.5) * 0.5 + Map.get(civ, :civilization_readiness, 0.5) * 0.5
  end

  defp score_category(:scientific, civ) do
    Map.get(civ, :scientific_output, 0.5) * 0.7 + Map.get(civ, :knowledge_growth, 0.5) * 0.3
  end

  defp score_category(:economic, civ) do
    Map.get(civ, :economic_stability, 0.5) * 0.8 + Map.get(civ, :infrastructure, 0.5) * 0.2
  end

  defp score_category(:mathematical, civ) do
    (Map.get(civ, :scientific_output, 0.5) + Map.get(civ, :knowledge_growth, 0.5)) / 2.0
  end

  def compare(analyzer, profile_a_id, profile_b_id) do
    profiles = Map.get(analyzer, :resilience_profiles, [])
    a = Enum.find(profiles, &(Map.get(&1, :id) == profile_a_id))
    b = Enum.find(profiles, &(Map.get(&1, :id) == profile_b_id))
    scores_a = Map.get(a, :scores, %{})
    scores_b = Map.get(b, :scores, %{})
    diffs = Map.new(scores_a, fn {k, v} -> {k, v - Map.get(scores_b, k, 0.0)} end)
    {:ok, %{profile_a: profile_a_id, profile_b: profile_b_id, score_differences: diffs, overall_diff: Map.get(a, :overall, 0.0) - Map.get(b, :overall, 0.0)}}
  end

  def metrics(analyzer) do
    {:ok, %{profile_count: length(Map.get(analyzer, :resilience_profiles, []))}}
  end
end
