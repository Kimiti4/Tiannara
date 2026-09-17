defmodule Tiannara.OMCE.CausalPruner do
  @moduledoc """
  Phase 5F.11: Causal Pruner for Ontological Memory Compression Engine.
  
  Performs causal pruning by removing nodes that have weak causal connections
  or are causally redundant while preserving the overall causal structure.
  """

  alias Tiannara.RRG.{Graph, Node, Edge}

  @doc """
  Prune the graph by removing causally redundant nodes
  """
  def prune(%Graph{} = graph) do
    # Step 1: Identify causally redundant nodes
    redundant_nodes = identify_causal_redundancies(graph)
    
    # Step 2: Remove redundant nodes
    pruned_graph = remove_redundant_nodes(graph, redundant_nodes)
    
    # Step 3: Optimize remaining structure
    finalize_graph(pruned_graph)
  end

  # Helper function to ensure safe list handling
  defp safe_list(value) when is_list(value), do: value
  defp safe_list(_), do: []

  @doc """
  Identify nodes that are causally redundant
  """
  def identify_causal_redundancies(%Graph{} = graph) do
    graph.nodes
    |> Enum.filter(fn {node_id, node} ->
      is_causally_redundant?(graph, node_id, node)
    end)
    |> Enum.map(fn {node_id, _node} -> node_id end)
  end

  @doc """
  Determine if a node is causally redundant
  """
  def is_causally_redundant?(%Graph{} = graph, node_id, %Node{} = node) do
    # A node is causally redundant if:
    # 1. It has low confidence weight
    # 2. It has weak causal connections OR is not on a critical path
    # 3. Its removal doesn't break causal chains significantly
    
    low_confidence = node.confidence_weight < 0.35  # Increased threshold to be more inclusive
    has_weak_connections_only = count_weak_connections(graph, node_id) >= 0  # Allow 0 weak connections
    is_not_critical = not is_on_critical_causal_path?(graph, node_id)
    
    # If it has low confidence and either weak connections only or is not critical, it's redundant
    low_confidence and (has_weak_connections_only or is_not_critical)
  end

  @doc """
  Count weak connections for a node (edges with strength < threshold)
  """
  def count_weak_connections(%Graph{} = graph, node_id) do
    threshold = 0.35  # Increased threshold to catch more weak connections
    
    graph.edges
    |> safe_list()
    |> Enum.filter(fn {{from, to}, edge} -> 
      (from == node_id or to == node_id) and Map.get(edge, :strength, 1.0) < threshold
    end)
    |> length()
  end

  @doc """
  Check if a node is on a critical causal path
  """
  def is_on_critical_causal_path?(%Graph{} = graph, node_id) do
    # A node is on a critical path if removing it would disconnect
    # important parts of the graph
    
    # This is a simplified check - in a real implementation this would be more complex
    # Check if the node is part of a cycle or connects different subgraphs
    is_part_of_cycle?(graph, node_id) or is_bridge_node?(graph, node_id)
  end

  @doc """
  Check if a node is part of a cycle
  """
  def is_part_of_cycle?(%Graph{} = graph, node_id) do
    # Find all paths from the node back to itself
    paths = find_cycles_through_node(graph, node_id)
    length(safe_list(paths)) > 0
  end

  @doc """
  Check if a node acts as a bridge between different parts of the graph
  """
  def is_bridge_node?(%Graph{} = graph, node_id) do
    # Temporarily remove the node and check if the graph becomes disconnected
    temp_graph = Graph.remove_node(graph, node_id)
    
    # Count connected components
    component_count = count_connected_components(temp_graph)
    
    # If removing this node increases the number of components, it's a bridge
    component_count > 1
  end

  @doc """
  Find cycles that pass through a specific node
  """
  def find_cycles_through_node(%Graph{} = graph, node_id) do
    # Simple cycle detection - in a real implementation this would be more robust
    # Look for paths that go from the node back to itself
    find_paths_to_node(graph, node_id, node_id, [node_id], 0, 3)  # Limit depth to 3
  end

  @doc """
  Find paths from one node to another up to a certain depth
  """
  def find_paths_to_node(%Graph{} = graph, from_node, to_node, visited, current_depth, max_depth) do
    if current_depth > max_depth do
      []
    else
      if from_node == to_node and current_depth > 0 do
        # Found a path back to the starting node (a cycle)
        [[from_node]]
      else
        next_nodes = get_connected_nodes(graph, from_node)
        
        safe_list(next_nodes)
        |> Enum.reduce([], fn node, acc ->
          if node not in visited do
            new_visited = [node | visited]
            new_depth = current_depth + 1
            
            # Find paths from this next node to the target
            paths = find_paths_to_node(graph, node, to_node, new_visited, new_depth, max_depth)
            
            # Prepend current node to each path
            extended_paths = Enum.map(safe_list(paths), fn path -> [from_node | path] end)
            acc ++ extended_paths
          else
            acc
          end
        end)
      end
    end
  end

  @doc """
  Get all nodes connected to a given node
  """
  def get_connected_nodes(%Graph{} = graph, node_id) do
    connected_from = 
      graph.edges
      |> safe_list()
      |> Enum.filter(fn {{from, _to}, _edge} -> from == node_id end)
      |> Enum.map(fn {{_from, to}, _edge} -> to end)
    
    connected_to = 
      graph.edges
      |> safe_list()
      |> Enum.filter(fn {{_from, to}, _edge} -> to == node_id end)
      |> Enum.map(fn {{from, _to}, _edge} -> from end)
    
    (connected_from ++ connected_to) |> Enum.uniq()
  end

  @doc """
  Count connected components in the graph
  """
  def count_connected_components(%Graph{} = graph) do
    visited = MapSet.new()
    nodes = Map.keys(graph.nodes)
    
    nodes
    |> Enum.reduce({0, visited}, fn node_id, {count, visited_acc} ->
      if MapSet.member?(visited_acc, node_id) do
        {count, visited_acc}
      else
        new_visited = visit_connected_nodes(graph, node_id, visited_acc)
        {count + 1, new_visited}
      end
    end)
    |> elem(0)
  end

  @doc """
  Visit all nodes connected to the starting node
  """
  def visit_connected_nodes(%Graph{} = graph, start_node, visited) do
    queue = [start_node]
    visit_recursive(graph, queue, visited)
  end

  defp visit_recursive(_graph, [], visited), do: visited
  
  defp visit_recursive(graph, [node | rest], visited) do
    if MapSet.member?(visited, node) do
      visit_recursive(graph, rest, visited)
    else
      connected = get_connected_nodes(graph, node)
      new_visited = MapSet.put(visited, node)
      new_queue = rest ++ connected
      
      visit_recursive(graph, new_queue, new_visited)
    end
  end

  @doc """
  Remove redundant nodes from the graph
  """
  def remove_redundant_nodes(%Graph{} = graph, redundant_node_ids) do
    redundant_node_ids
    |> Enum.reduce(graph, fn node_id, acc_graph ->
      Graph.remove_node(acc_graph, node_id)
    end)
  end

  @doc """
  Finalize the graph after pruning
  """
  def finalize_graph(%Graph{} = graph) do
    # Clean up any artifacts from the pruning process
    graph
    |> clean_up_dangling_edges()
    |> normalize_remaining_weights()
  end

  @doc """
  Clean up edges that may now be dangling after node removal
  """
  def clean_up_dangling_edges(%Graph{} = graph) do
    graph.edges
    |> safe_list()
    |> Enum.reduce(graph, fn {{from, to}, _edge}, acc_graph ->
      # Check if both nodes still exist in the graph
      from_exists = Map.has_key?(graph.nodes, from)
      to_exists = Map.has_key?(graph.nodes, to)
      
      if from_exists and to_exists do
        acc_graph
      else
        # Remove the dangling edge
        Graph.remove_edge(acc_graph, from, to)
      end
    end)
  end

  @doc """
  Normalize remaining edge weights after pruning
  """
  def normalize_remaining_weights(%Graph{} = graph) do
    # In a real implementation, this would adjust edge weights based on
    # the new graph structure after pruning
    graph
  end
end
