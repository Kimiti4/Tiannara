defmodule TiannaraRuntime.Civilization.Planning.PlanningArchaeology do
  def record(planner, objective_engine, origin) do
    planning_narrative = build_narrative(planner)
    objective_evolution = build_evolution(objective_engine)
    roadmap_history = build_roadmap_history(planner)
    archaeology = %{
      id: "arch_#{:erlang.unique_integer([:positive])}",
      planning_narrative: planning_narrative,
      objective_evolution: objective_evolution,
      roadmap_history: roadmap_history,
      origin: origin
    }
    {:ok, archaeology}
  end

  defp build_narrative(planner) do
    plans = Map.values(planner)
    statuses = Enum.map(plans, fn p -> Map.get(p, :status) end)
    %{
      plan_count: length(plans),
      status_distribution: Enum.frequencies(statuses),
      summary: "civilization_planning_record"
    }
  end

  defp build_evolution(objective_engine) do
    objectives = Map.get(objective_engine, :objectives, %{})
    ordered = Map.get(objective_engine, :ordered_ids, [])
    %{
      total_objectives: map_size(objectives),
      ordered_ids: ordered,
      trajectory: Enum.map(ordered, fn id -> Map.get(objectives, id, %{}) end)
    }
  end

  defp build_roadmap_history(planner) do
    plans = Map.values(planner)
    Enum.map(plans, fn p ->
      %{
        id: Map.get(p, :id),
        status: Map.get(p, :status),
        horizon: Map.get(p, :horizon)
      }
    end)
  end

  def explain(archaeology) do
    narrative = Map.get(archaeology, :planning_narrative, %{})
    {:ok, Map.get(narrative, :summary, "no_narrative")}
  end

  def get_lineage(archaeology) do
    lineage = %{
      origin: Map.get(archaeology, :origin),
      objective_evolution: Map.get(archaeology, :objective_evolution, %{}),
      roadmap_history: Map.get(archaeology, :roadmap_history, [])
    }
    {:ok, lineage}
  end
end
