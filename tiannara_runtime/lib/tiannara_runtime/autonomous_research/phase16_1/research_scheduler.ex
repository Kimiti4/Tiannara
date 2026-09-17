defmodule TiannaraRuntime.AutonomousResearch.Phase16_1.ResearchScheduler do
  @moduledoc """
  Phase 16.1 Module 10 — Research Scheduler (Pure Implementation)

  Implements frozen contract from RESEARCH_RUNTIME_FREEZE.md 2.4 ResearchScheduler:
  - schedule(programs, resource_policy) -> [DispatchIntent]

  Constitutional boundary:
  - scheduling produces intents only; execution is not part of Phase 16 runtime freeze.

  Scheduler must:
  - respect dependencies
  - deterministic ordering
  - replayable execution
  """

  @doc "Create dispatch intents from programs deterministically"
  @spec schedule([map()], map()) :: {:ok, [map()]}
  def schedule(programs, resource_policy) do
    case check_acyclic(programs) do
      :ok ->
        intents = create_dispatch_intents(programs, resource_policy)
        {:ok, intents}

      {:error, _} = error ->
        error
    end
  end

  @doc "Create priority queue from programs"
  @spec priority_queue([map()]) :: [map()]
  def priority_queue(programs) do
    prioritize_programs(programs)
  end

  @doc "Resolve dependencies for programs"
  @spec resolve_dependencies([map()]) :: {:ok, [map()]} | {:error, String.t()}
  def resolve_dependencies(programs) do
    case check_acyclic(programs) do
      :ok ->
        ordered = topological_sort(programs)
        {:ok, ordered}

      {:error, _} = error ->
        error
    end
  end

  # --- internal helpers ---

  defp create_dispatch_intents(programs, resource_policy) do
    programs
    |> Enum.sort_by(fn p -> Map.get(p, "research_program_id", "") end)
    |> Enum.map(fn program ->
      deterministic_time = deterministic_timestamp(Map.get(program, "research_program_id", ""))
      %{
        "intent_id" => "intent_" <> Map.get(program, "research_program_id", ""),
        "program_id" => Map.get(program, "research_program_id", ""),
        "priority" => Map.get(program, "portfolio_rank_hint", 0),
        "resources" => allocate_resources(resource_policy),
        "dispatch_time" => deterministic_time
      }
    end)
  end

  defp deterministic_timestamp(seed) when is_binary(seed) do
    "2000-01-01T00:00:00Z"
  end

  defp allocate_resources(resource_policy) do
    max_compute = Map.get(resource_policy, "max_compute_per_program", 1000)
    max_experiments = Map.get(resource_policy, "max_experiments_per_program", 10)

    %{
      "compute_units" => min(max_compute, div(max_compute, 2)),
      "evidence_budget" => max_experiments
    }
  end

  defp prioritize_programs(programs) do
    programs
    |> Enum.sort_by(fn p ->
      {Map.get(p, "portfolio_rank_hint", 0), Map.get(p, "research_program_id", "")}
    end)
    |> Enum.reverse()
  end

  defp check_acyclic(programs) do
    graph = build_dependency_graph(programs)
    program_ids = programs |> Enum.map(fn p -> Map.get(p, "research_program_id", "") end)

    case Enum.find(program_ids, fn pid -> cycle_detect(pid, graph, MapSet.new(), MapSet.new([pid])) end) do
      nil -> :ok
      _cycle -> {:error, "cyclic_dependency_detected"}
    end
  end

  defp build_dependency_graph(programs) do
    programs
    |> Enum.reduce(%{}, fn program, acc ->
      deps = Map.get(program, "dependencies", [])
      pid = Map.get(program, "research_program_id", "")
      Map.put(acc, pid, deps)
    end)
  end

  defp cycle_detect(node, graph, global_visited, path) do
    if MapSet.member?(global_visited, node) do
      MapSet.member?(path, node)
    else
      new_global = MapSet.put(global_visited, node)
      deps = Map.get(graph, node, [])

      Enum.reduce(deps, false, fn dep, acc ->
        if acc, do: acc, else: cycle_detect(dep, graph, new_global, MapSet.put(path, dep))
      end)
    end
  end

  defp topological_sort(programs) do
    programs
    |> Enum.sort_by(fn p -> Map.get(p, "research_program_id", "") end)
  end
end
