defmodule TiannaraRuntime.Civilization.Scenarios.ScenarioArchaeology do
  def record(engine, generator, origin) do
    scenarios = Map.get(engine, :scenarios, %{})
    comparisons = Map.get(engine, :comparisons, [])
    recommendations = Map.get(engine, :recommendations, [])
    archaeology = %{
      id: "sarch_#{:erlang.unique_integer([:positive])}",
      scenario_narrative: %{
        scenario_count: map_size(scenarios),
        scenario_types: Enum.map(scenarios, fn {_id, s} -> Map.get(s, :type) end),
        summary: "scenario_simulation_record"
      },
      comparison_history: Enum.map(comparisons, fn c -> Map.take(c, [:scenario_a, :scenario_b, :differences]) end),
      recommendation_lineage: Enum.map(recommendations, fn r -> Map.take(r, [:id, :type, :priority]) end),
      origin: origin
    }
    {:ok, archaeology}
  end

  def explain(archaeology) do
    narrative = Map.get(archaeology, :scenario_narrative, %{})
    {:ok, Map.get(narrative, :summary, "no_narrative")}
  end

  def get_lineage(archaeology) do
    lineage = %{
      origin: Map.get(archaeology, :origin),
      comparison_history: Map.get(archaeology, :comparison_history, []),
      recommendation_lineage: Map.get(archaeology, :recommendation_lineage, [])
    }
    {:ok, lineage}
  end
end
