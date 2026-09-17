defmodule Tiannara.RRG.CTNAnomalyDetector do
  @moduledoc """
  Phase 5F.7: Causal Truth Network Anomaly Detection Engine.
  
  Detects structural and behavioral anomalies in Causal Truth Networks:
  - Contradiction loops
  - High-entropy nodes
  - Causal paradoxes
  - Ontological inconsistencies
  - Observer collapse risk patterns
  """

  alias Tiannara.RRG.{Graph, Node, Edge}

  defstruct []

  def new(), do: %__MODULE__{}

  def get_anomaly_report(%Graph{} = graph) do
    detect_anomalies(graph)
  end

  @doc """
  Detects various types of anomalies in a Causal Truth Network.
  """
  def detect_anomalies(%Graph{} = graph) do
    anomalies = []
    |> detect_contradiction_loops(graph)
    |> detect_high_entropy_nodes(graph)
    |> detect_causal_paradoxes(graph)
    |> detect_ontological_inconsistencies(graph)
    |> detect_observer_collapse_risks(graph)
    
    anomalies
  end

  # Contradiction loop detection
  defp detect_contradiction_loops(anomalies, graph) do
    contradiction_edges = 
      graph.edges
      |> Map.values()
      |> Enum.filter(fn edge -> edge.type == :contradicts end)

    loops = 
      contradiction_edges
      |> Enum.flat_map(fn edge ->
        # Check if there's a supporting path from target back to source
        # creating a contradiction loop
        find_cycles_from_node(graph, edge.to, edge.from, [:contradicts])
      end)

    loop_anomalies = 
      loops
      |> Enum.map(fn cycle ->
        %{
          type: :contradiction_loop,
          severity: calculate_cycle_severity(cycle),
          nodes: cycle,
          description: "Contradiction loop detected in Causal Truth Network"
        }
      end)

    anomalies ++ loop_anomalies
  end

  # High entropy node detection
  defp detect_high_entropy_nodes(anomalies, graph) do
    high_entropy_nodes = 
      graph.nodes
      |> Enum.filter(fn {_id, node} -> 
        node.entropy_score > 0.8 
      end)
      |> Enum.map(fn {id, node} ->
        %{
          type: :high_entropy_node,
          severity: calculate_entropy_severity(node.entropy_score),
          node_id: id,
          entropy_score: node.entropy_score,
          description: "High entropy node detected, potential instability"
        }
      end)

    anomalies ++ high_entropy_nodes
  end

  # Causal paradox detection
  defp detect_causal_paradoxes(anomalies, graph) do
    paradoxes = 
      graph.nodes
      |> Enum.flat_map(fn {node_id, node} ->
        detect_time_paradoxes_for_node(graph, node_id, node)
      end)

    paradox_anomalies = 
      paradoxes
      |> Enum.map(fn paradox ->
        %{
          type: :causal_paradox,
          severity: :high,
          details: paradox,
          description: "Causal paradox detected in temporal reasoning"
        }
      end)

    anomalies ++ paradox_anomalies
  end

  # Ontological inconsistency detection
  defp detect_ontological_inconsistencies(anomalies, graph) do
    inconsistencies = 
      graph.nodes
      |> Enum.flat_map(fn {node_id, node} ->
        detect_type_conflicts(graph, node_id, node)
      end)

    inconsistency_anomalies = 
      inconsistencies
      |> Enum.map(fn inconsistency ->
        %{
          type: :ontological_inconsistency,
          severity: :medium,
          details: inconsistency,
          description: "Ontological type conflict detected"
        }
      end)

    anomalies ++ inconsistency_anomalies
  end

  # Observer collapse risk detection
  defp detect_observer_collapse_risks(anomalies, graph) do
    # Calculate observer saturation levels
    observer_nodes = 
      graph.nodes
      |> Enum.filter(fn {_id, node} -> 
        node.type == :observer 
      end)

    risks = 
      observer_nodes
      |> Enum.filter(fn {_id, node} ->
        connected_nodes_count = count_connected_nodes(graph, node.id)
        node.confidence_weight < 0.3 and connected_nodes_count > 10
      end)
      |> Enum.map(fn {id, node} ->
        %{
          type: :observer_collapse_risk,
          severity: :high,
          observer_id: id,
          connection_count: count_connected_nodes(graph, node.id),
          confidence: node.confidence_weight,
          description: "Observer collapse risk due to low confidence and high connectivity"
        }
      end)

    anomalies ++ risks
  end

  # Helper function to find cycles in the graph
  defp find_cycles_from_node(graph, start_node, target_node, visited \\ []) do
    # Simple cycle detection - in a real implementation this would be more sophisticated
    paths = find_all_paths(graph, start_node, target_node, visited, [])
    
    paths
    |> Enum.filter(fn path -> length(path) > 2 end)  # Only meaningful cycles
  end

  # Find all paths between two nodes
  defp find_all_paths(graph, from, to, visited, current_path) do
    if from == to and length(current_path) > 0 do
      [Enum.reverse([from | current_path])]
    else
      next_nodes = get_connected_nodes(graph, from)
      
      next_nodes
      |> Enum.reduce([], fn node, acc ->
        if node not in visited do
          new_visited = [node | visited]
          new_path = [from | current_path]
          
          paths = find_all_paths(graph, node, to, new_visited, new_path)
          acc ++ paths
        else
          acc
        end
      end)
    end
  end

  # Get all nodes connected to a given node
  defp get_connected_nodes(graph, node_id) do
    graph.edges
    |> Map.values()
    |> Enum.filter(fn edge -> edge.from == node_id end)
    |> Enum.map(fn edge -> edge.to end)
    |> Enum.uniq()
  end

  # Count connected nodes
  defp count_connected_nodes(graph, node_id) do
    get_connected_nodes(graph, node_id) |> length()
  end

  # Detect time paradoxes for a node
  defp detect_time_paradoxes_for_node(graph, node_id, node) do
    # In a real implementation, this would check for temporal inconsistencies
    # where effects happen before causes
    []
  end

  # Detect type conflicts
  defp detect_type_conflicts(graph, node_id, node) do
    # Check for conflicting assertions about the same entity
    conflicting_nodes = 
      graph.nodes
      |> Enum.filter(fn {id, n} -> 
        id != node_id and 
        n.type == node.type and
        String.starts_with?(n.id, String.slice(node.id, 0..2))  # Simplified similarity check
      end)

    conflicting_nodes
    |> Enum.map(fn {id, n} ->
      %{
        conflicting_node_ids: [node_id, id],
        conflict_type: :type_conflict,
        details: %{node1: node, node2: n}
      }
    end)
  end

  # Calculate severity based on cycle properties
  defp calculate_cycle_severity(cycle) do
    case length(cycle) do
      n when n <= 3 -> :high
      n when n <= 6 -> :medium
      _ -> :low
    end
  end

  # Calculate entropy severity
  defp calculate_entropy_severity(entropy_score) do
    cond do
      entropy_score > 0.9 -> :critical
      entropy_score > 0.8 -> :high
      entropy_score > 0.6 -> :medium
      true -> :low
    end
  end
end
