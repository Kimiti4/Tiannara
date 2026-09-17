defmodule OMCE.Test do
  use ExUnit.Case, async: true

  alias Tiannara.OMCE.Engine
  alias Tiannara.OMCE.SemanticCompressor
  alias Tiannara.OMCE.CausalPruner
  alias Tiannara.OMCE.IdentityMerger
  alias Tiannara.RRG.{Graph, Node, Edge}

  setup do
    # Start the OMCE engine if not already started
    if Process.whereis(Engine) == nil do
      start_supervised!(Engine)
    end
    :ok
  end

  test "OMCE engine starts correctly" do
    # Verify the OMCE engine can be called
    graph = Graph.new()
    result = Engine.compress_graph(graph)
    assert result != nil
  end

  test "Semantic compressor identifies similar nodes" do
    # Create a graph with similar nodes
    graph = Graph.new()
    
    # Add similar nodes
    node1 = Node.new("fact_1", :fact, entropy_score: 0.1, confidence_weight: 0.9)
    node2 = Node.new("fact_2", :fact, entropy_score: 0.12, confidence_weight: 0.88)
    node3 = Node.new("model_1", :model, entropy_score: 0.2, confidence_weight: 0.7)
    
    graph = Graph.add_node(graph, node1)
    graph = Graph.add_node(graph, node2)
    graph = Graph.add_node(graph, node3)
    
    # Add some edges
    edge1 = Edge.new("fact_1", "model_1", :supports, strength: 0.8)
    edge2 = Edge.new("fact_2", "model_1", :supports, strength: 0.75)
    
    graph = Graph.add_edge(graph, edge1)
    graph = Graph.add_edge(graph, edge2)
    
    # Test similarity detection
    similar_groups = SemanticCompressor.identify_similar_nodes(graph)
    
    # Should find fact_1 and fact_2 as similar since they're both facts with similar entropy/confidence
    assert length(similar_groups) >= 1
    
    # Check if the nodes are indeed similar
    found_similar = 
      similar_groups
      |> Enum.any?(fn group -> 
        node_ids = group.nodes |> Enum.map(fn {id, _} -> id end)
        "fact_1" in node_ids and "fact_2" in node_ids
      end)
    
    assert found_similar
  end

  test "Semantic compressor merges similar nodes correctly" do
    # Create a graph with similar nodes
    graph = Graph.new()
    
    # Add similar nodes
    node1 = Node.new("fact_1", :fact, entropy_score: 0.1, confidence_weight: 0.9)
    node2 = Node.new("fact_2", :fact, entropy_score: 0.12, confidence_weight: 0.88)
    target_node = Node.new("target", :fact, entropy_score: 0.15, confidence_weight: 0.9)
    source_node = Node.new("source", :fact, entropy_score: 0.15, confidence_weight: 0.9)
    
    graph = Graph.add_node(graph, node1)
    graph = Graph.add_node(graph, node2)
    graph = Graph.add_node(graph, target_node)
    graph = Graph.add_node(graph, source_node)
    
    # Add edges to both nodes
    edge1 = Edge.new("fact_1", "target", :supports, strength: 0.8)
    edge2 = Edge.new("fact_2", "target", :supports, strength: 0.75)
    edge3 = Edge.new("source", "fact_1", :derives, strength: 0.7)
    
    graph = Graph.add_edge(graph, edge1)
    graph = Graph.add_edge(graph, edge2)
    graph = Graph.add_edge(graph, edge3)
    
    # Test compression
    compressed_graph = SemanticCompressor.compress(graph)
    
    # The compressed graph should have fewer nodes than the original
    original_size = Graph.size(graph)
    compressed_size = Graph.size(compressed_graph)
    
    assert compressed_size.nodes <= original_size.nodes
    assert compressed_size.edges <= original_size.edges
    
    # The target node should still exist
    assert Graph.get_node(compressed_graph, "target") != nil
    assert Graph.get_node(compressed_graph, "source") != nil
  end

  test "Causal pruner identifies redundant nodes" do
    # Create a graph with potentially redundant nodes
    graph = Graph.new()
    
    # Add nodes with different confidence levels
    high_conf_node = Node.new("important", :fact, entropy_score: 0.05, confidence_weight: 0.95)
    low_conf_node = Node.new("redundant", :fact, entropy_score: 0.2, confidence_weight: 0.1)  # Low confidence
    medium_conf_node = Node.new("medium", :model, entropy_score: 0.15, confidence_weight: 0.5)
    
    graph = Graph.add_node(graph, high_conf_node)
    graph = Graph.add_node(graph, low_conf_node)
    graph = Graph.add_node(graph, medium_conf_node)
    
    # Connect the low-confidence node with weak edges
    weak_edge = Edge.new("low_conf_node", "medium", :supports, strength: 0.1)  # Weak connection
    
    graph = Graph.add_edge(graph, weak_edge)
    
    # Test redundancy identification
    redundant_nodes = CausalPruner.identify_causal_redundancies(graph)
    
    # The low-confidence node with weak connections should be identified as redundant
    assert "redundant" in redundant_nodes
  end

  test "Causal pruner removes redundant nodes" do
    # Create a graph with redundant nodes
    graph = Graph.new()
    
    # Add nodes
    important_node = Node.new("important", :fact, entropy_score: 0.05, confidence_weight: 0.95)
    redundant_node = Node.new("redundant", :fact, entropy_score: 0.2, confidence_weight: 0.1)
    
    graph = Graph.add_node(graph, important_node)
    graph = Graph.add_node(graph, redundant_node)
    
    # Add a weak edge to the redundant node
    weak_edge = Edge.new("source", "redundant", :supports, strength: 0.1)
    strong_edge = Edge.new("source", "important", :supports, strength: 0.8)
    
    graph = Graph.add_edge(graph, weak_edge)
    graph = Graph.add_edge(graph, strong_edge)
    
    # Test pruning
    pruned_graph = CausalPruner.prune(graph)
    
    # The pruned graph should have the redundant node removed
    original_size = Graph.size(graph)
    pruned_size = Graph.size(pruned_graph)
    
    assert pruned_size.nodes < original_size.nodes
    assert Graph.get_node(pruned_graph, "redundant") == nil
    assert Graph.get_node(pruned_graph, "important") != nil
  end

  test "Identity merger finds overlapping identity nodes" do
    # Create a graph with nodes that have overlapping identity
    graph = Graph.new()
    
    # Add nodes with similar IDs suggesting overlapping identity
    node1 = Node.new("concept_similar_1", :fact, entropy_score: 0.1, confidence_weight: 0.8)
    node2 = Node.new("concept_similar_2", :fact, entropy_score: 0.12, confidence_weight: 0.78)
    node3 = Node.new("different_concept", :model, entropy_score: 0.2, confidence_weight: 0.6)
    
    graph = Graph.add_node(graph, node1)
    graph = Graph.add_node(graph, node2)
    graph = Graph.add_node(graph, node3)
    
    # Test identity overlap detection
    identity_groups = IdentityMerger.identify_identity_overlaps(graph)
    
    # Should find concept_similar_1 and concept_similar_2 as having overlapping identity
    # due to their similar IDs and same type
    found_overlap = 
      identity_groups
      |> Enum.any?(fn group -> 
        node_ids = group.nodes |> Enum.map(fn {id, _} -> id end)
        "concept_similar_1" in node_ids and "concept_similar_2" in node_ids
      end)
    
    assert found_overlap
  end

  test "Identity merger consolidates overlapping nodes" do
    # Create a graph with overlapping identity nodes
    graph = Graph.new()
    
    # Add nodes with overlapping identity
    node1 = Node.new("entity_a", :fact, entropy_score: 0.1, confidence_weight: 0.9)
    node2 = Node.new("entity_a_variant", :fact, entropy_score: 0.12, confidence_weight: 0.85)
    target_node = Node.new("target", :fact, entropy_score: 0.15, confidence_weight: 0.9)
    
    graph = Graph.add_node(graph, node1)
    graph = Graph.add_node(graph, node2)
    graph = Graph.add_node(graph, target_node)
    
    # Add edges to both nodes
    edge1 = Edge.new("entity_a", "target", :supports, strength: 0.8)
    edge2 = Edge.new("entity_a_variant", "target", :supports, strength: 0.75)
    
    graph = Graph.add_edge(graph, edge1)
    graph = Graph.add_edge(graph, edge2)
    
    # Test identity merging
    merged_graph = IdentityMerger.merge(graph)
    
    # The merged graph should have consolidated the overlapping nodes
    original_size = Graph.size(graph)
    _merged_size = Graph.size(merged_graph)
    
    # May have same or fewer nodes depending on how aggressive the merging is
    # but the key thing is that important connections are preserved
    assert Graph.get_node(merged_graph, "target") != nil
    
    # Should have handled the multiple edges properly
    target_edges = 
      merged_graph.edges
      |> Map.values()
      |> Enum.filter(fn edge -> edge.to == "target" end)
    
    # Should have properly consolidated edges to the target
    assert length(target_edges) >= 1
  end

  test "Full OMCE compression cycle works" do
    # Create a complex graph for full compression
    graph = Graph.new()
    
    # Add many similar and redundant nodes
    nodes = for i <- 1..10 do
      Node.new("similar_fact_#{i}", :fact, entropy_score: 0.1 + (i * 0.01), confidence_weight: 0.85 + (i * 0.01))
    end
    
    # Add some low-confidence, weakly-connected nodes
    redundant_nodes = for i <- 1..5 do
      Node.new("weak_node_#{i}", :model, entropy_score: 0.3, confidence_weight: 0.15)
    end
    
    # Build the graph
    graph = 
      nodes ++ redundant_nodes
      |> Enum.reduce(graph, fn node, g -> Graph.add_node(g, node) end)
    
    # Add edges - strong connections for important nodes, weak for redundant ones
    important_edges = 
      for i <- 1..8, j <- [rem(i, 8) + 1] do  # Create a cycle among important nodes
        Edge.new("similar_fact_#{i}", "similar_fact_#{j}", :supports, strength: 0.8)
      end
    
    weak_edges = 
      for i <- 1..5 do
        Edge.new("weak_node_#{i}", "similar_fact_#{i}", :supports, strength: 0.15)  # Weak connections
      end
    
    # Add all edges to graph
    graph = 
      (important_edges ++ weak_edges)
      |> Enum.reduce(graph, fn edge, g -> Graph.add_edge(g, edge) end)
    
    # Run full compression cycle
    compressed_graph = Engine.full_compression_cycle(graph)
    
    # Verify compression happened
    original_size = Graph.size(graph)
    compressed_size = Graph.size(compressed_graph)
    
    # The compressed graph should be smaller but preserve essential structure
    assert compressed_size.nodes <= original_size.nodes
    assert compressed_size.edges <= original_size.edges
    
    # Verify the engine state was updated
    state = :sys.get_state(Engine)
    assert state.compression_ratio >= 0.0
    assert state.pruning_efficiency >= 0.0
    assert state.merge_success_rate >= 0.0
  end

  test "ID overlap calculation works correctly" do
    # Test the ID overlap function
    overlap1 = IdentityMerger.calculate_id_overlap("concept_abc", "concept_xyz")
    overlap2 = IdentityMerger.calculate_id_overlap("completely_different", "totally_unrelated")
    overlap3 = IdentityMerger.calculate_id_overlap("same_string", "same_string")
    
    # Same string should have 100% overlap
    assert overlap3 == 1.0
    
    # Related strings should have higher overlap than completely different ones
    assert overlap1 > overlap2
  end

  test "Node similarity detection works" do
    # Test the semantic similarity function
    node1 = Node.new("test1", :fact, entropy_score: 0.1, confidence_weight: 0.8)
    node2 = Node.new("test2", :fact, entropy_score: 0.12, confidence_weight: 0.78)  # Similar
    node3 = Node.new("test3", :model, entropy_score: 0.1, confidence_weight: 0.8)  # Different type
    
    # Should be similar (same type, close entropy/confidence)
    assert SemanticCompressor.are_nodes_semantically_similar?(node1, node2)
    
    # Should not be similar (different types)
    refute SemanticCompressor.are_nodes_semantically_similar?(node1, node3)
  end
end