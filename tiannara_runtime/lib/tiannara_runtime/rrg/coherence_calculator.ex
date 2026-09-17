defmodule Tiannara.RRG.CoherenceCalculator do
  @moduledoc """
  Coherence Calculator - Computes system coherence scores for the RRG system.
  Measures how well the ontology graph maintains consistent, non-contradictory knowledge.
  """

  defstruct [
    :graph,
    :contradiction_score,
    :consistency_ratio,
    :connectivity_factor,
    :last_updated
  ]

  def new(graph) do
    %__MODULE__{
      graph: graph,
      contradiction_score: 0.0,
      consistency_ratio: 1.0,
      connectivity_factor: 0.0,
      last_updated: System.system_time(:millisecond)
    }
  end

  def calculate_coherence(%{graph: graph}) do
    contradiction_score = measure_contradictions(graph)
    consistency_ratio = measure_consistency(graph)
    connectivity_factor = measure_connectivity(graph)
    
    overall_coherence = 
      consistency_ratio * 
      (1.0 - contradiction_score) * 
      connectivity_factor
    
    clamp_coherence(overall_coherence)
  end

  def measure_contradictions(graph) do
    # Count contradictory edges in the graph
    contradictory_edges = 
      graph.edges
      |> Enum.filter(fn {_key, edge} -> 
        edge.type == :contradicts
      end)
      |> length()
    
    total_edges = map_size(graph.edges)
    
    if total_edges > 0 do
      contradictory_edges / total_edges
    else
      0.0
    end
  end

  def measure_consistency(graph) do
    # Calculate ratio of supporting to contradicting relationships
    supporting_edges = 
      graph.edges
      |> Enum.filter(fn {_key, edge} -> 
        edge.type == :supports
      end)
      |> length()
    
    total_relatable_edges = 
      graph.edges
      |> Enum.filter(fn {_key, edge} -> 
        edge.type in [:supports, :contradicts]
      end)
      |> length()
    
    if total_relatable_edges > 0 do
      supporting_edges / total_relatable_edges
    else
      1.0  # Fully consistent if no relatable edges
    end
  end

  def measure_connectivity(graph) do
    # Calculate how well connected the graph is
    total_nodes = map_size(graph.nodes)
    total_edges = map_size(graph.edges)
    
    if total_nodes <= 1 do
      1.0  # Fully connected if only one or no nodes
    else
      # Maximum possible edges in undirected graph is n*(n-1)/2
      max_possible_edges = (total_nodes * (total_nodes - 1)) / 2
      if max_possible_edges > 0 do
        min(1.0, total_edges / max_possible_edges)
      else
        0.0
      end
    end
  end

  def update_graph(coherence_calc, new_graph) do
    %{coherence_calc | 
      graph: new_graph, 
      last_updated: System.system_time(:millisecond)}
  end

  def get_detailed_metrics(%{graph: graph}) do
    %{
      contradiction_score: measure_contradictions(graph),
      consistency_ratio: measure_consistency(graph),
      connectivity_factor: measure_connectivity(graph),
      total_nodes: map_size(graph.nodes),
      total_edges: map_size(graph.edges),
      coherence_score: calculate_coherence(%{graph: graph})
    }
  end

  def is_coherent?(coherence_calc, threshold \\ 0.7) do
    current_coherence = calculate_coherence(coherence_calc)
    current_coherence >= threshold
  end

  defp clamp_coherence(score) when score < 0.0, do: 0.0
  defp clamp_coherence(score) when score > 1.0, do: 1.0
  defp clamp_coherence(score), do: score
end
