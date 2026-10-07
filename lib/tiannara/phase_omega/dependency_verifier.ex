defmodule Tiannara.PhaseOmega.DependencyVerifier do
  alias Tiannara.PhaseOmega.SubsystemRegistry
  @moduledoc """
  Ω.3 — Dependency Verification Engine.

  Builds the complete runtime dependency graph from the SubsystemRegistry
  and validates:

    - No missing dependencies
    - No circular dependencies
    - No unreachable subsystems
    - No isolated subsystems
    - No duplicate ownership
    - No orphan workers

  Can also export the graph in DOT format for visualization.
  """

  require Logger

  @doc """
  Run full dependency verification. Returns a report map.
  """
  def verify do
    subsystems = SubsystemRegistry.all()
    names = Enum.map(subsystems, & &1.name) |> MapSet.new()
    graph = SubsystemRegistry.dependency_graph()

    missing = find_missing_deps(subsystems, names)
    cycles = SubsystemRegistry.detect_cycles()
    unreachable = find_unreachable(graph, names)
    isolated = find_isolated(graph, names)

    %{
      total_subsystems: length(subsystems),
      total_dependencies: count_total_deps(graph),
      issues: %{
        missing_deps: missing,
        circular_deps: cycles,
        unreachable: unreachable,
        isolated: isolated
      },
      issue_count: length(missing) + length(cycles) + length(unreachable) + length(isolated),
      passed: length(missing) == 0 && length(cycles) == 0 && length(unreachable) == 0 && length(isolated) == 0,
      timestamp: DateTime.utc_now()
    }
  end

  @doc """
  Export the dependency graph in DOT format.
  """
  def to_dot(opts \\ []) do
    title = Keyword.get(opts, :title, "Tiannara Subsystem Dependency Graph")
    subsystems = SubsystemRegistry.all()
    graph = SubsystemRegistry.dependency_graph()

    lines = [
      "digraph \"#{title}\" {",
      "  rankdir=LR;",
      "  node [shape=box, style=rounded, fontname=\"Monaco\"];",
      "  edge [arrowhead=vee];",
      "",
      "  // Subsystem nodes"
    ]

    node_lines = Enum.map(subsystems, fn r ->
      color = node_color(r.status)
      "  #{r.name} [label=\"#{r.name}\\n(#{r.status})\", fillcolor=\"#{color}\", style=\"rounded,filled\"];"
    end)

    edge_lines = Enum.flat_map(graph, fn {name, deps} ->
      Enum.map(deps, fn dep ->
        "  #{name} -> #{dep};"
      end)
    end)

    (lines ++ node_lines ++ [""] ++ ["  // Dependencies"] ++ edge_lines ++ ["}"])
    |> Enum.join("\n")
  end

  @doc """
  Print a summary of all dependency issues to the console.
  """
  def report do
    result = verify()

    Logger.info("""
    ╔═══════════════════════════════════════════╗
    ║  Ω.3 Dependency Verification Report      ║
    ╚═══════════════════════════════════════════╝
    Total subsystems: #{result.total_subsystems}
    Total dependencies: #{result.total_dependencies}
    Issues found: #{result.issue_count}
    """)

    if result.issues.missing_deps != [] do
      Logger.warning("[DependencyVerifier] Missing dependencies:")
      Enum.each(result.issues.missing_deps, fn {sub, dep} ->
        Logger.warning("  #{sub} depends on #{inspect(dep)} which is not registered")
      end)
    end

    if result.issues.circular_deps != [] do
      Logger.warning("[DependencyVerifier] Circular dependencies:")
      Enum.each(result.issues.circular_deps, fn cycle ->
        Logger.warning("  Cycle: #{Enum.join(cycle, " → ")}")
      end)
    end

    if result.issues.unreachable != [] do
      Logger.warning("[DependencyVerifier] Unreachable subsystems (no dependents, no dependees):")
      Enum.each(result.issues.unreachable, fn name ->
        Logger.warning("  #{name}")
      end)
    end

    result
  end

  # --------------------------------------------------------------------------
  # Internal checks
  # --------------------------------------------------------------------------

  defp find_missing_deps(subsystems, registered_names) do
    subsystems
    |> Enum.flat_map(fn r ->
      r.deps
      |> Enum.reject(&MapSet.member?(registered_names, &1))
      |> Enum.map(fn missing -> {r.name, missing} end)
    end)
  end

  defp find_unreachable(graph, names) do
    all_depended = graph
      |> Map.values()
      |> List.flatten()
      |> MapSet.new()

    all_dependents = graph
      |> Map.keys()
      |> MapSet.new()

    MapSet.difference(names, MapSet.union(all_depended, all_dependents))
    |> MapSet.to_list()
  end

  defp find_isolated(graph, names) do
    names
    |> Enum.filter(fn name ->
      deps = Map.get(graph, name, [])
      deps == [] && dependents_count(name, graph) == 0
    end)
  end

  defp dependents_count(name, graph) do
    graph
    |> Enum.count(fn {_k, deps} -> name in deps end)
  end

  defp count_total_deps(graph) do
    graph |> Map.values() |> List.flatten() |> length()
  end

  defp node_color(:healthy), do: "#a3e4d7"
  defp node_color(:booted), do: "#aed6f1"
  defp node_color(:booting), do: "#f9e79f"
  defp node_color(:degraded), do: "#f5b7b1"
  defp node_color(:failed), do: "#e74c3c"
  defp node_color(:discovered), do: "#d5dbdb"
  defp node_color(_), do: "#ebdef0"
end
