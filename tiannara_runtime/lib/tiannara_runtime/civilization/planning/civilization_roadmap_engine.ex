defmodule TiannaraRuntime.Civilization.Planning.CivilizationRoadmapEngine do
  def initialize do
    {:ok, %{roadmaps: [], current: nil}}
  end

  def construct(engine, objectives, plans, horizons) do
    roadmap = %{
      id: "roadmap_#{:erlang.unique_integer([:positive])}",
      timeline: build_timeline(horizons),
      program_ordering: build_program_ordering(plans),
      institution_ordering: build_institution_ordering(objectives),
      research_ordering: build_research_ordering(objectives),
      mathematics_requirements: build_mathematics_requirements(objectives),
      world_model_dependencies: build_world_model_dependencies(objectives)
    }
    {:ok, %{engine | roadmaps: Map.get(engine, :roadmaps, []) ++ [roadmap], current: roadmap}}
  end

  defp build_timeline(horizons) do
    Enum.map(horizons, fn h -> %{horizon: h, phase: "phase_#{h}"} end)
  end

  defp build_program_ordering(plans) do
    Enum.map(plans, fn p -> Map.get(p, :id) end)
  end

  defp build_institution_ordering(objectives) do
    Enum.flat_map(objectives, fn o -> Map.get(o, :required_institutions, []) end) |> Enum.uniq()
  end

  defp build_research_ordering(objectives) do
    Enum.flat_map(objectives, fn o -> Map.get(o, :required_research, []) end) |> Enum.uniq()
  end

  defp build_mathematics_requirements(objectives) do
    Enum.map(objectives, fn o ->
      %{objective: Map.get(o, :id), requirement: Map.get(o, :requires_mathematics, :mathematical_formalization)}
    end)
  end

  defp build_world_model_dependencies(objectives) do
    Enum.map(objectives, fn o ->
      %{objective: Map.get(o, :id), dependency: Map.get(o, :requires_world_model, :world_model_state)}
    end)
  end

  def get_current(engine) do
    case Map.get(engine, :current) do
      nil -> {:error, :none}
      current -> {:ok, current}
    end
  end

  def compare(engine, roadmap_a_id, roadmap_b_id) do
    roadmaps = Map.get(engine, :roadmaps, [])
    a = Enum.find(roadmaps, &(Map.get(&1, :id) == roadmap_a_id))
    b = Enum.find(roadmaps, &(Map.get(&1, :id) == roadmap_b_id))
    comparison = %{
      a_id: roadmap_a_id,
      b_id: roadmap_b_id,
      timeline_diff: length(Map.get(a, :timeline, [])) - length(Map.get(b, :timeline, [])),
      program_ordering_match: Map.get(a, :program_ordering, []) == Map.get(b, :program_ordering, [])
    }
    {:ok, comparison}
  end

  def metrics(engine) do
    {:ok, %{roadmap_count: length(Map.get(engine, :roadmaps, []))}}
  end
end
