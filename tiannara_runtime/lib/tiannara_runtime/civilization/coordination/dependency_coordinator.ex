defmodule TiannaraRuntime.Civilization.Coordination.DependencyCoordinator do
  def initialize() do
    {:ok, %{dependency_graph: %{}, order: []}}
  end

  def add_dependency(coordinator, source, target, type) do
    edge = %{source: source, target: target, type: type}
    existing = Map.get(coordinator.dependency_graph, source, [])
    {:ok, %{coordinator | dependency_graph: Map.put(coordinator.dependency_graph, source, existing ++ [edge])}}
  end

  def validate(coordinator) do
    all_nodes = coordinator.dependency_graph |> Map.keys() |> MapSet.new()
    targets = Enum.flat_map(coordinator.dependency_graph, fn {_s, edges} -> Enum.map(edges, fn e -> Map.get(e, :target) end) end)
    all_nodes = MapSet.union(all_nodes, MapSet.new(targets))
    result = detect_cycle(all_nodes, coordinator.dependency_graph)
    case result do
      {:error, _} -> {:error, :cycle_detected}
      _ -> :ok
    end
  end

  def topological_sort(coordinator) do
    graph = coordinator.dependency_graph
    all_nodes = graph |> Map.keys() |> MapSet.new()
    targets = Enum.flat_map(graph, fn {_s, edges} -> Enum.map(edges, fn e -> Map.get(e, :target) end) end)
    all_nodes = MapSet.union(all_nodes, MapSet.new(targets))
    in_degree = Enum.reduce(all_nodes, %{}, fn n, acc -> Map.put(acc, n, 0) end)
    in_degree = Enum.reduce(graph, in_degree, fn {_s, edges}, acc ->
      Enum.reduce(edges, acc, fn e, inner -> Map.put(inner, Map.get(e, :target), Map.get(inner, Map.get(e, :target), 0) + 1) end)
    end)
    queue = Enum.filter(all_nodes, fn n -> Map.get(in_degree, n, 0) == 0 end)
    do_topological_sort(graph, in_degree, queue, [])
  end

  def impact_propagation(coordinator, node_id) do
    downstream = find_downstream(coordinator.dependency_graph, node_id, [])
    {:ok, downstream}
  end

  defp detect_cycle(all_nodes, graph) do
    Enum.reduce_while(all_nodes, {:ok, MapSet.new(), MapSet.new()}, fn node, {_ok, visited, rec_stack} ->
      if MapSet.member?(visited, node) do
        {:cont, {:ok, visited, rec_stack}}
      else
        case dfs_cycle(node, graph, visited, rec_stack) do
          {:error, :cycle} -> {:halt, {:error, :cycle}}
          {_ok, new_vis, new_rec} -> {:cont, {:ok, new_vis, new_rec}}
        end
      end
    end)
  end

  defp do_topological_sort(_graph, _in_degree, [], result), do: {:ok, Enum.reverse(result)}
  defp do_topological_sort(graph, in_degree, queue, result) do
    [node | rest] = queue
    edges = Map.get(graph, node, [])
    {new_in_degree, new_queue} = Enum.reduce(edges, {in_degree, rest}, fn e, {ind, q} ->
      target = Map.get(e, :target)
      new_count = Map.get(ind, target, 0) - 1
      new_ind = Map.put(ind, target, new_count)
      new_q = if new_count == 0, do: q ++ [target], else: q
      {new_ind, new_q}
    end)
    do_topological_sort(graph, new_in_degree, new_queue, result ++ [node])
  end

  defp dfs_cycle(node, graph, visited, rec_stack) do
    if MapSet.member?(rec_stack, node) do
      {:error, :cycle}
    else
      if MapSet.member?(visited, node) do
        {:ok, visited, rec_stack}
      else
        visited = MapSet.put(visited, node)
        rec_stack = MapSet.put(rec_stack, node)
        edges = Map.get(graph, node, [])
        Enum.reduce_while(edges, {:ok, visited, rec_stack}, fn e, {_ok, vis, rec} ->
          case dfs_cycle(Map.get(e, :target), graph, vis, rec) do
            {:error, :cycle} -> {:halt, {:error, :cycle}}
            {_ok, new_vis, new_rec} -> {:cont, {:ok, new_vis, new_rec}}
          end
        end)
      end
    end
  end

  defp find_downstream(graph, node, visited) do
    if node in visited do
      visited
    else
      visited = [node | visited]
      edges = Map.get(graph, node, [])
      Enum.reduce(edges, visited, fn e, acc -> find_downstream(graph, Map.get(e, :target), acc) end)
    end
  end
end
