defmodule TiannaraRuntime.Civilization.Scenarios.ScenarioComparator do
  def initialize do
    {:ok, %{rankings: [], criteria: [:scientific_output, :knowledge_growth, :infrastructure, :economic_stability, :institutional_health, :civilization_readiness]}}
  end

  def rank(comparator, scenarios) do
    criteria = Map.get(comparator, :criteria, [])
    ranked = Enum.map(scenarios, fn s ->
      scores = Enum.map(criteria, fn c -> Map.get(s, c, 0.0) end)
      avg = if length(scores) > 0, do: Enum.sum(scores) / length(scores), else: 0.0
      {Map.get(s, :id), avg}
    end)
    ordered = Enum.sort_by(ranked, fn {_id, score} -> -score end)
    {:ok, ordered}
  end

  def compare_pair(comparator, scenario_a, scenario_b) do
    criteria = Map.get(comparator, :criteria, [])
    diffs = Map.new(criteria, fn c ->
      {c, Map.get(scenario_a, c, 0.0) - Map.get(scenario_b, c, 0.0)}
    end)
    {:ok, %{scenario_a: Map.get(scenario_a, :id), scenario_b: Map.get(scenario_b, :id), differences: diffs}}
  end

  def metrics(comparator) do
    {:ok, %{ranking_count: length(Map.get(comparator, :rankings, []))}}
  end
end
