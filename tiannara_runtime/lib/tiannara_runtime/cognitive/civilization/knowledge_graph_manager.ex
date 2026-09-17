defmodule TiannaraRuntime.Cognitive.Civilization.KnowledgeGraphManager do
  def initialize do
    {:ok, %{nodes: [], edges: [], domains: %{}, version: 1}}
  end

  def add_node(graph, node) do
    nodes = Map.get(graph, :nodes) ++ [node]
    domain = Map.get(node, :domain)
    domains = Map.get(graph, :domains)
    current = Map.get(domains, domain, 0)
    updated_domains = Map.put(domains, domain, current + 1)
    {:ok, graph |> Map.put(:nodes, nodes) |> Map.put(:domains, updated_domains)}
  end

  def add_edge(graph, source_id, target_id, relationship) do
    edge = %{source: source_id, target: target_id, relationship: relationship}
    edges = Map.get(graph, :edges) ++ [edge]
    {:ok, Map.put(graph, :edges, edges)}
  end

  def query_by_domain(graph, domain) do
    result = Enum.filter(Map.get(graph, :nodes), fn n -> Map.get(n, :domain) == domain end)
    {:ok, result}
  end

  def merge(graph_a, graph_b) do
    nodes_a = Map.get(graph_a, :nodes, [])
    nodes_b = Map.get(graph_b, :nodes, [])
    edges_a = Map.get(graph_a, :edges, [])
    edges_b = Map.get(graph_b, :edges, [])
    domains_a = Map.get(graph_a, :domains, %{})
    domains_b = Map.get(graph_b, :domains, %{})

    existing_ids = MapSet.new(Enum.map(nodes_a, fn n -> Map.get(n, :id) end))
    new_nodes = Enum.reject(nodes_b, fn n -> MapSet.member?(existing_ids, Map.get(n, :id)) end)

    existing_edge_keys = MapSet.new(Enum.map(edges_a, fn e -> {Map.get(e, :source), Map.get(e, :target), Map.get(e, :relationship)} end))
    new_edges = Enum.reject(edges_b, fn e -> MapSet.member?(existing_edge_keys, {Map.get(e, :source), Map.get(e, :target), Map.get(e, :relationship)}) end)

    merged_domains = Map.merge(domains_a, domains_b, fn _k, v1, v2 -> v1 + v2 end)

    merged = %{
      nodes: nodes_a ++ new_nodes,
      edges: edges_a ++ new_edges,
      domains: merged_domains,
      version: max(Map.get(graph_a, :version, 1), Map.get(graph_b, :version, 1)) + 1
    }
    {:ok, merged}
  end

  def summarize(graph) do
    summary = %{
      node_count: length(Map.get(graph, :nodes, [])),
      edge_count: length(Map.get(graph, :edges, [])),
      domain_count: map_size(Map.get(graph, :domains, %{}))
    }
    {:ok, summary}
  end
end
