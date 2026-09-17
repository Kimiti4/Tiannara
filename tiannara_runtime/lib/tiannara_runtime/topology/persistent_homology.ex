defmodule TiannaraRuntime.Topology.PersistentHomology do
  @moduledoc """
  Phase 5F.12 — Persistent Homology Utility

  Provides approximate H0/H1 feature extraction for DFG latent folding.
  """

  @doc "Compute H0 and H1 persistence estimates for a graph." 
  def compute_h0_h1(graph) when is_map(graph) do
    nodes = Map.get(graph, :nodes, [])
    edges = Map.get(graph, :edges, [])

    components = count_connected_components(nodes, edges)
    cycles = approximate_h1(nodes, edges, components)
    anchors = select_anchor_nodes(nodes, edges, components, cycles)

    %{h0: components, h1: cycles, anchors: anchors}
  end

  @doc "Extract a persistent feature summary for a latent folding pass."
  def extract_persistent_features(graph) when is_map(graph) do
    compute_h0_h1(graph)
  end

  defp count_connected_components(nodes, edges) do
    adjacency = build_adjacency(nodes, edges)
    visited = Map.new()

    Enum.reduce(nodes, {0, visited}, fn node, {count, visited_acc} ->
      if Map.has_key?(visited_acc, node) do
        {count, visited_acc}
      else
        {new_visited, _} = traverse(node, adjacency, visited_acc)
        {count + 1, new_visited}
      end
    end)
    |> elem(0)
  end

  defp approximate_h1(nodes, edges, components) do
    edge_count = length(edges)
    node_count = length(nodes)

    max(edge_count - node_count + components, 0)
  end

  defp select_anchor_nodes(nodes, edges, components, cycles) do
    adjacency = build_adjacency(nodes, edges)

    nodes
    |> Enum.map(fn node -> {node, Map.get(adjacency, node, []) |> length()} end)
    |> Enum.sort_by(fn {_node, degree} -> -degree end)
    |> Enum.take(max(1, min(length(nodes), components + cycles)))
    |> Enum.map(&elem(&1, 0))
  end

  defp build_adjacency(nodes, edges) do
    Enum.reduce(nodes, %{}, fn node, acc -> Map.put(acc, node, []) end)
    |> add_edges(edges)
  end

  defp add_edges(adjacency, edges) do
    Enum.reduce(edges, adjacency, fn
      {from, to}, acc ->
        acc
        |> Map.update!(from, fn list -> [to | list] end)
        |> Map.update!(to, fn list -> [from | list] end)

      _other, acc -> acc
    end)
  end

  defp traverse(node, adjacency, visited) do
    stack = [node]
    {visited, _} = Enum.reduce(stack, {visited, []}, fn current, {visited_acc, stack_acc} ->
      if Map.has_key?(visited_acc, current) do
        {visited_acc, stack_acc}
      else
        neighbors = Map.get(adjacency, current, [])
        new_stack = stack_acc ++ neighbors
        {Map.put(visited_acc, current, true), new_stack}
      end
    end)

    {visited, []}
  end
end
