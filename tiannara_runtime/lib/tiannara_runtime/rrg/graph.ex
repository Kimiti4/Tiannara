defmodule Tiannara.RRG.Graph do
  @moduledoc """
  Rate-limiting Ontological Graph (RRG) - Core graph structure for epistemic firewall
  and bandwidth allocation for reality claims.
  """

  defstruct [
    :nodes,
    :edges,
    :metadata
  ]

  alias Tiannara.RRG.Node
  alias Tiannara.RRG.Edge

  def new do
    %__MODULE__{
      nodes: %{},
      edges: %{},
      metadata: %{
        created_at: System.system_time(:millisecond),
        version: "1.0.0"
      }
    }
  end

  def add_node(graph, %Node{} = node) do
    updated_nodes = Map.put(graph.nodes, node.id, node)
    %{graph | nodes: updated_nodes}
  end

  def add_edge(graph, %Edge{} = edge) do
    updated_edges = Map.put(graph.edges, {edge.from, edge.to}, edge)
    %{graph | edges: updated_edges}
  end

  def remove_node(graph, node_id) do
    # Remove the node
    updated_nodes = Map.delete(graph.nodes, node_id)
    
    # Remove all edges connected to this node
    updated_edges = 
      graph.edges
      |> Enum.reject(fn {{from, to}, _edge} -> from == node_id or to == node_id end)
      |> Enum.into(%{})
    
    %{graph | nodes: updated_nodes, edges: updated_edges}
  end

  def remove_edge(graph, from_id, to_id) do
    updated_edges = Map.delete(graph.edges, {from_id, to_id})
    %{graph | edges: updated_edges}
  end

  def get_node(graph, node_id) do
    Map.get(graph.nodes, node_id)
  end

  def get_edge(graph, from_id, to_id) do
    Map.get(graph.edges, {from_id, to_id})
  end

  def get_neighbors(graph, node_id) do
    # Find all edges connected to this node
    graph.edges
    |> Enum.filter(fn {{from, to}, _edge} -> from == node_id or to == node_id end)
    |> Enum.map(fn {{from, to}, _edge} -> if from == node_id, do: to, else: from end)
    |> Enum.uniq()
  end

  def get_connected_nodes(graph, node_id) do
    # Get all nodes connected via edges
    graph.edges
    |> Enum.filter(fn {{from, _to}, _edge} -> from == node_id end)
    |> Enum.map(fn {{_from, to}, _edge} -> to end)
  end

  def size(graph) do
    %{nodes: map_size(graph.nodes), edges: map_size(graph.edges)}
  end
end
