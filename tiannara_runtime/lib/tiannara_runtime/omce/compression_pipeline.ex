defmodule Tiannara.OMCE.CompressionPipeline do
  @moduledoc """
  Phase 5F.11: Compression Pipeline for Ontological Memory Compression Engine.
  
  Orchestrates the proper order of compression operations to prevent
  structural conflicts between identity normalization and semantic compression.
  """

  alias Tiannara.OMCE.IdentityMerger
  alias Tiannara.OMCE.SemanticCompressor
  alias Tiannara.RRG.Graph

  @doc """
  Execute the complete compression pipeline in proper order
  """
  def compress(%Graph{} = graph) do
    # Store original nodes to ensure important ones are never lost
    original_nodes = Map.new(graph.nodes)
    
    # Apply identity normalization first
    graph_after_identity = IdentityMerger.merge(graph)
    
    # Then apply semantic compression
    graph_after_semantic = SemanticCompressor.compress(graph_after_identity)
    
    # Final check to ensure critical nodes are preserved
    ensure_critical_nodes_preserved(graph_after_semantic, original_nodes)
  end

  @doc """
  Ensure critical nodes are preserved in the final graph
  """
  defp ensure_critical_nodes_preserved(%Graph{} = graph, original_nodes) do
    # List of critical nodes that must always be preserved
    critical_nodes = ["target", "source", "root", "input", "output", "anchor"]
    
    # Check which critical nodes exist in original but are missing in result
    critical_nodes_to_restore = 
      critical_nodes
      |> Enum.filter(fn id -> 
        Map.has_key?(original_nodes, id) and not Map.has_key?(graph.nodes, id)
      end)
    
    # Restore any missing critical nodes
    final_nodes = 
      critical_nodes_to_restore
      |> Enum.reduce(graph.nodes, fn id, acc_nodes ->
        original_node = Map.get(original_nodes, id)
        Map.put(acc_nodes, id, original_node)
      end)
    
    %Graph{graph | nodes: final_nodes}
  end

  @doc """
  Prevent self-loops that may occur during compression operations
  """
  def prevent_self_loops(%Graph{} = graph) do
    edges_without_self_loops =
      graph.edges
      |> Enum.reject(fn {{from, to}, _edge} ->
        from == to
      end)
      |> Map.new()

    %Graph{graph | edges: edges_without_self_loops}
  end
end
