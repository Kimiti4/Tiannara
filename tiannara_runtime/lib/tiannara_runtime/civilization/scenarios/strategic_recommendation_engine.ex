defmodule TiannaraRuntime.Civilization.Scenarios.StrategicRecommendationEngine do
  def initialize do
    {:ok, %{recommendations: [], lineage: []}}
  end

  def generate(engine, _civilization, risks, scenarios) do
    risk_recs = Enum.map(risks, fn r ->
      %{
        id: "rec_#{:erlang.unique_integer([:positive])}",
        type: :investment,
        description: "mitigate_#{Map.get(r, :category)}",
        priority: Map.get(r, :severity, 0.5),
        evidence_refs: [Map.get(r, :description)]
      }
    end)
    scenario_recs = Enum.map(scenarios, fn s ->
      %{
        id: "rec_#{:erlang.unique_integer([:positive])}",
        type: :planning,
        description: "prepare_for_#{Map.get(s, :type)}",
        priority: 0.6,
        evidence_refs: [Map.get(s, :id)]
      }
    end)
    all_recs = risk_recs ++ scenario_recs
    {:ok, %{engine | recommendations: Map.get(engine, :recommendations, []) ++ all_recs, lineage: Map.get(engine, :lineage, []) ++ [%{generated_at: :erlang.unique_integer([:positive]), count: length(all_recs)}]}}
  end

  def get_recommendations(engine, type) do
    filtered = Enum.filter(Map.get(engine, :recommendations, []), fn r -> Map.get(r, :type) == type end)
    {:ok, filtered}
  end

  def metrics(engine) do
    recs = Map.get(engine, :recommendations, [])
    by_type = Enum.group_by(recs, fn r -> Map.get(r, :type) end)
    by_type_counts = Map.new(by_type, fn {t, list} -> {t, length(list)} end)
    {:ok, %{total: length(recs), by_type: by_type_counts}}
  end
end
