defmodule TiannaraRuntime.Civilization.Runtime.CivilizationScheduler do
  def initialize() do
    {:ok, %{queue: [], order: [], cycle_count: 0}}
  end

  def enqueue(scheduler, item) do
    priority = Map.get(item, :priority, 0)
    {:ok, %{scheduler | queue: [{priority, item} | scheduler.queue]}}
  end

  def schedule(scheduler, dependency_graph) do
    sorted = topological_sort(scheduler.queue, dependency_graph)
    {:ok, %{scheduler | order: sorted, cycle_count: scheduler.cycle_count + 1}}
  end

  def next(scheduler) do
    case scheduler.order do
      [] -> {:error, :empty}
      [highest | rest] -> {:ok, {highest, %{scheduler | order: rest}}}
    end
  end

  def cycle_detected?(dependency_graph) do
    {:ok, dfs_cycle_detect(dependency_graph, MapSet.new(), MapSet.new(), Map.keys(dependency_graph))}
  end

  defp topological_sort(queue, dependency_graph) do
    items = Enum.map(queue, fn {_p, item} -> item end)
    ids = Enum.map(items, fn item -> Map.get(item, :id) end)
    id_to_priority = Enum.reduce(queue, %{}, fn {p, item}, acc -> Map.put(acc, Map.get(item, :id), p) end)
    adjacency = dependency_graph
    in_degree = Enum.reduce(ids, %{}, fn id, acc -> Map.put(acc, id, count_in_degree(id, adjacency)) end)
    queue_init = Enum.filter(ids, fn id -> Map.get(in_degree, id, 0) == 0 end)
    sorted_ids = kahn_sort(ids, in_degree, adjacency, queue_init, [])
    sorted_ids
    |> Enum.sort(fn a, b -> Map.get(id_to_priority, a, 0) >= Map.get(id_to_priority, b, 0) end)
    |> Enum.map(fn id -> Enum.find(items, fn item -> Map.get(item, :id) == id end) end)
    |> Enum.reject(&is_nil/1)
  end

  defp count_in_degree(id, adjacency) do
    Enum.count(adjacency, fn {_node, deps} -> id in deps end)
  end

  defp kahn_sort(ids, in_degree, adjacency, queue, acc) do
    if queue == [] do
      acc ++ Enum.filter(ids, fn id -> id not in acc end)
    else
      [current | rest] = queue
      deps = Map.get(adjacency, current, [])
      new_in_degree = Enum.reduce(deps, in_degree, fn dep, deg -> Map.update!(deg, dep, &(&1 - 1)) end)
      new_queue = rest ++ Enum.filter(ids, fn id ->
        Map.get(new_in_degree, id, 0) == 0 and id not in acc and id not in queue and id not in rest
      end)
      kahn_sort(ids, new_in_degree, adjacency, new_queue, acc ++ [current])
    end
  end

  defp dfs_cycle_detect(_graph, _visited, _stack, []) do
    false
  end

  defp dfs_cycle_detect(graph, visited, stack, [node | rest]) do
    if MapSet.member?(visited, node) do
      dfs_cycle_detect(graph, visited, stack, rest)
    else
      if dfs_visit(graph, node, visited, stack) do
        true
      else
        dfs_cycle_detect(graph, MapSet.put(visited, node), stack, rest)
      end
    end
  end

  defp dfs_visit(graph, node, visited, stack) do
    if MapSet.member?(stack, node) do
      true
    else
      new_stack = MapSet.put(stack, node)
      deps = Map.get(graph, node, [])
      has_cycle = Enum.any?(deps, fn dep ->
        dfs_visit(graph, dep, visited, new_stack)
      end)
      if has_cycle, do: true, else: false
    end
  end
end
