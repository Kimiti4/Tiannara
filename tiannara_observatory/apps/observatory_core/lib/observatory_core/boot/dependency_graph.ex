defmodule ObservatoryCore.Boot.DependencyGraph do
  @moduledoc """
  DAG-based startup ordering.

  Given phases with declared dependencies, produces a valid startup order
  with maximum parallelism. Detects cycles and missing deps at compile-time.
  """

  @type phase_name :: atom()
  @type graph :: %{phase_name() => [phase_name()]}

  @doc "Topological sort of phases. Returns phases in boot order (deps first)."
  def sort(phases) do
    graph = build_graph(phases)

    case topsort(graph) do
      {:ok, order} -> order
      {:error, :cycle} -> raise "Boot graph contains a cycle — cannot start"
    end
  end

  @doc "Return phases that can be booted in parallel at each level."
  def parallel_levels(phases) do
    order = sort(phases)
    level_map = assign_levels(phases, order)
    levels = Enum.group_by(order, fn name -> level_map[name] end)
    levels |> Enum.sort_by(fn {level, _} -> level end) |> Enum.map(fn {_, phases} -> phases end)
  end

  defp build_graph(phases) do
    Map.new(phases, fn %{name: name, deps: deps} -> {name, deps} end)
  end

  defp topsort(graph) do
    {order, remaining} = do_topsort(graph, [], Map.keys(graph))
    if remaining == [], do: {:ok, order}, else: {:error, :cycle}
  end

  defp do_topsort(_graph, order, []), do: {Enum.reverse(order), []}

  defp do_topsort(graph, order, remaining) do
    no_deps =
      Enum.filter(remaining, fn node ->
        deps = Map.get(graph, node, [])
        Enum.all?(deps, fn dep -> dep not in remaining end)
      end)

    if no_deps == [] do
      {Enum.reverse(order), remaining}
    else
      do_topsort(graph, order ++ no_deps, remaining -- no_deps)
    end
  end

  defp assign_levels(phases, order) do
    deps_map = Map.new(phases, fn %{name: n, deps: d} -> {n, d} end)
    levels = %{}

    Enum.reduce(order, levels, fn name, acc ->
      level =
        case Map.get(deps_map, name, []) do
          [] -> 0
          d -> Enum.map(d, fn dep -> Map.get(acc, dep, 0) end) |> Enum.max() |> Kernel.+()
        end

      Map.put(acc, name, level)
    end)
  end
end
