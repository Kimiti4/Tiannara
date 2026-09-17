defmodule TiannaraRuntime.Cognitive.Engines.ActivationGraph do
  @moduledoc "Phase 18.3 — Activation Graph"

  def create do
    %{nodes: %{}, edges: %{}, ordering: :topological}
  end

  def add_node(graph, node_id, node_data) do
    nodes = Map.put(graph.nodes, node_id, node_data)
    {:ok, %{graph | nodes: nodes}}
  end

  def add_edge(graph, source_id, target_id) do
    edges = Map.update(graph.edges, source_id, [target_id], fn existing -> [target_id | existing] end)
    new_graph = %{graph | edges: edges}
    if has_path?(new_graph, target_id, source_id) do
      {:error, :cycle_detected}
    else
      {:ok, new_graph}
    end
  end

  def get_topological_order(graph) do
    in_degree = build_in_degree(graph)
    all_nodes = MapSet.union(
      MapSet.new(Map.keys(graph.nodes)),
      graph.edges |> Map.values() |> List.flatten() |> MapSet.new()
    )
    queue = all_nodes |> Enum.filter(fn n -> Map.get(in_degree, n, 0) == 0 end) |> Enum.reverse()
    do_topological_sort(graph, in_degree, queue, [])
  end

  def get_neighbors(graph, node_id) do
    {:ok, Map.get(graph.edges, node_id, [])}
  end

  defp has_path?(graph, from, to, visited \\ MapSet.new()) do
    if from == to do
      true
    else
      if MapSet.member?(visited, from) do
        false
      else
        visited = MapSet.put(visited, from)
        neighbors = Map.get(graph.edges, from, [])
        Enum.any?(neighbors, fn n -> has_path?(graph, n, to, visited) end)
      end
    end
  end

  defp build_in_degree(graph) do
    Enum.reduce(graph.edges, %{}, fn {_source, targets}, acc ->
      Enum.reduce(targets, acc, fn t, acc2 ->
        Map.update(acc2, t, 1, &(&1 + 1))
      end)
    end)
  end

  defp do_topological_sort(_graph, _in_degree, [], result) do
    all_nodes = _graph.nodes |> Map.keys() |> MapSet.new()
    result_set = result |> MapSet.new()
    if MapSet.subset?(all_nodes, result_set) do
      {:ok, Enum.reverse(result)}
    else
      {:error, :cycle_detected}
    end
  end

  defp do_topological_sort(graph, in_degree, [node | queue], result) do
    neighbors = Map.get(graph.edges, node, [])
    {new_queue, new_in_degree} =
      Enum.reduce(neighbors, {queue, in_degree}, fn n, {q, id} ->
        new_degree = id[n] - 1
        new_id = Map.put(id, n, new_degree)
        if new_degree == 0 do
          {[n | q], new_id}
        else
          {q, new_id}
        end
      end)
    do_topological_sort(graph, new_in_degree, new_queue, [node | result])
  end
end
