defmodule TiannaraOS.ScientificTopologyResult do
  @moduledoc """
  ScientificTopologyResult - Canonical constitutional transaction for topological scientific reasoning.
  
  This artifact captures the complete audit trail of one topology analysis event, including
  theories analyzed, relationship graphs, clusters, bridge theories, isolated theories,
  contradictions, knowledge gaps, topological metrics, and all constitutional deltas.
  
  ## Key Principle: Behavioral Exposure Over Algorithm Exposure
  
  Instead of exposing graph algorithms, similarity metrics, ranking heuristics, search strategies,
  or planning algorithms, this result stores only the behavioral contract: what theories were
  analyzed, what relationships exist between them, what topology emerged, and what knowledge
  gaps were identified.
  
  ## Constitutional Discipline
  
  - One institutional behavior: analyzing relationships among theories
  - One public API: InstitutionKernel.analyze_scientific_topology/2
  - One canonical transaction: ScientificTopologyResult
  - No new persistent state: composes existing frozen primitives
  - Complete traceability: every relationship references theories
  
  ## Usage
  
      result = ScientificTopologyResult.new(institution_id, opts)
      result = ScientificTopologyResult.add_theory(result, theory_data)
      result = ScientificTopologyResult.add_relationship(result, from_id, to_id, type)
      result = ScientificTopologyResult.identify_clusters(result)
      result = ScientificTopologyResult.calculate_metrics(result)
      result = ScientificTopologyResult.mark_analyzed(result)
  """
  
  defstruct [
    # Core identification
    :id,
    :institution_id,
    :analysis_timestamp,
    
    # Theories analyzed
    :theories,
    
    # Relationship graph
    :relationship_graph,
    
    # Topological structures
    :clusters,
    :bridge_theories,
    :isolated_theories,
    :dependency_paths,
    
    # Contradictions
    :contradictions,
    
    # Knowledge gaps
    :knowledge_gaps,
    
    # Metrics
    :topological_metrics,
    :confidence,
    
    # Constitutional deltas
    :knowledge_delta,
    :ledger_delta,
    :traceability_graph,
    :lifecycle_events,
    :semantic_events,
    :governance_decisions,
    :constitutional_validation,
    
    # Status
    :status,
    :failure_reason
  ]
  
  @type t :: %__MODULE__{
    id: String.t(),
    institution_id: atom(),
    analysis_timestamp: DateTime.t(),
    theories: [map()],
    relationship_graph: map(),
    clusters: [map()],
    bridge_theories: [map()],
    isolated_theories: [map()],
    dependency_paths: [map()],
    contradictions: [map()],
    knowledge_gaps: [map()],
    topological_metrics: map() | nil,
    confidence: float(),
    knowledge_delta: map() | nil,
    ledger_delta: map() | nil,
    traceability_graph: map() | nil,
    lifecycle_events: [map()],
    semantic_events: [map()],
    governance_decisions: [map()],
    constitutional_validation: map() | nil,
    status: atom(),
    failure_reason: String.t() | nil
  }
  
  @doc """
  Create a new ScientificTopologyResult.
  
  ## Parameters
  
  - `institution_id`: atom() - institution performing analysis
  - `opts`: keyword list or map with optional fields
  
  ## Returns
  
  ScientificTopologyResult.t()
  """
  def new(institution_id, opts \\ []) do
    opts = if is_map(opts), do: Map.to_list(opts), else: opts
    
    %__MODULE__{
      id: Keyword.get(opts, :id, "topology_#{institution_id}_#{System.monotonic_time(:millisecond)}"),
      institution_id: institution_id,
      analysis_timestamp: DateTime.utc_now(),
      theories: [],
      relationship_graph: %{nodes: [], edges: []},
      clusters: [],
      bridge_theories: [],
      isolated_theories: [],
      dependency_paths: [],
      contradictions: [],
      knowledge_gaps: [],
      topological_metrics: nil,
      confidence: 0.0,
      knowledge_delta: nil,
      ledger_delta: nil,
      traceability_graph: nil,
      lifecycle_events: [],
      semantic_events: [],
      governance_decisions: [],
      constitutional_validation: nil,
      status: :initializing,
      failure_reason: nil
    }
  end
  
  @doc """
  Add a theory to the topology analysis.
  
  ## Parameters
  
  - `result`: ScientificTopologyResult.t() - target result
  - `theory_data`: map() - theory information
  
  ## Returns
  
  ScientificTopologyResult.t()
  """
  def add_theory(result, theory_data) do
    theory = %{
      theory_id: Map.get(theory_data, :theory_id, "theory_#{length(result.theories) + 1}"),
      title: Map.get(theory_data, :title, "Untitled Theory"),
      domain: Map.get(theory_data, :domain, :general),
      confidence: Map.get(theory_data, :confidence, 0.5),
      supporting_episodes: Map.get(theory_data, :supporting_episodes, []),
      formation_id: Map.get(theory_data, :formation_id, nil)
    }
    
    %{result | theories: result.theories ++ [theory]}
  end
  
  @doc """
  Add a relationship between two theories.
  
  ## Parameters
  
  - `result`: ScientificTopologyResult.t() - target result
  - `from_id`: String.t() - source theory ID
  - `to_id`: String.t() - target theory ID
  - `type`: atom() - relationship type (:supports, :contradicts, :extends, :specializes, :generalizes, :depends_on, :derived_from)
  - `confidence`: float() - confidence in relationship (0.0-1.0)
  
  ## Returns
  
  ScientificTopologyResult.t()
  """
  def add_relationship(result, from_id, to_id, type, confidence \\ 0.8) do
    edge = %{
      from: from_id,
      to: to_id,
      type: type,
      confidence: confidence
    }
    
    updated_edges = result.relationship_graph.edges ++ [edge]
    
    # Ensure nodes exist
    node_ids = Enum.map(result.relationship_graph.nodes, & &1.id)
    nodes = result.relationship_graph.nodes
    
    nodes = if from_id not in node_ids do
      nodes ++ [%{id: from_id}]
    else
      nodes
    end
    
    nodes = if to_id not in node_ids do
      nodes ++ [%{id: to_id}]
    else
      nodes
    end
    
    %{result | relationship_graph: %{nodes: nodes, edges: updated_edges}}
  end
  
  @doc """
  Identify clusters of related theories.
  
  ## Parameters
  
  - `result`: ScientificTopologyResult.t() - target result
  
  ## Returns
  
  ScientificTopologyResult.t() with identified clusters
  """
  def identify_clusters(result) do
    # Simple clustering based on connectivity
    # In production, would use more sophisticated algorithms
    clusters = identify_connected_components(result.relationship_graph)
    
    cluster_data = Enum.map(clusters, fn component ->
      %{
        cluster_id: "cluster_#{:erlang.phash2(component)}",
        theory_ids: component,
        size: length(component),
        density: calculate_cluster_density(result.relationship_graph, component)
      }
    end)
    
    %{result | clusters: cluster_data}
  end
  
  @doc """
  Identify bridge theories connecting different domains/clusters.
  
  ## Parameters
  
  - `result`: ScientificTopologyResult.t() - target result
  
  ## Returns
  
  ScientificTopologyResult.t() with identified bridge theories
  """
  def identify_bridge_theories(result) do
    bridges = find_bridge_nodes(result.relationship_graph, result.clusters)
    
    bridge_data = Enum.map(bridges, fn theory_id ->
      theory = Enum.find(result.theories, & &1.theory_id == theory_id)
      %{
        theory_id: theory_id,
        title: if(theory, do: theory.title, else: "Unknown"),
        connected_clusters: get_connected_clusters(result.clusters, theory_id),
        bridge_strength: calculate_bridge_strength(result.relationship_graph, theory_id)
      }
    end)
    
    %{result | bridge_theories: bridge_data}
  end
  
  @doc """
  Identify isolated theories with no connections.
  
  ## Parameters
  
  - `result`: ScientificTopologyResult.t() - target result
  
  ## Returns
  
  ScientificTopologyResult.t() with identified isolated theories
  """
  def identify_isolated_theories(result) do
    connected_ids = get_all_connected_ids(result.relationship_graph)
    all_ids = Enum.map(result.theories, & &1.theory_id)
    
    isolated_ids = all_ids -- connected_ids
    
    isolated_data = Enum.map(isolated_ids, fn theory_id ->
      theory = Enum.find(result.theories, & &1.theory_id == theory_id)
      %{
        theory_id: theory_id,
        title: if(theory, do: theory.title, else: "Unknown"),
        domain: if(theory, do: theory.domain, else: :unknown),
        reason_isolated: "No relationships identified"
      }
    end)
    
    %{result | isolated_theories: isolated_data}
  end
  
  @doc """
  Identify contradictions between theories.
  
  ## Parameters
  
  - `result`: ScientificTopologyResult.t() - target result
  
  ## Returns
  
  ScientificTopologyResult.t() with identified contradictions
  """
  def identify_contradictions(result) do
    contradiction_edges = Enum.filter(result.relationship_graph.edges, & &1.type == :contradicts)
    
    contradictions = Enum.map(contradiction_edges, fn edge ->
      from_theory = Enum.find(result.theories, & &1.theory_id == edge.from)
      to_theory = Enum.find(result.theories, & &1.theory_id == edge.to)
      
      %{
        theory_1_id: edge.from,
        theory_1_title: if(from_theory, do: from_theory.title, else: "Unknown"),
        theory_2_id: edge.to,
        theory_2_title: if(to_theory, do: to_theory.title, else: "Unknown"),
        confidence: edge.confidence,
        resolution_status: :unresolved
      }
    end)
    
    %{result | contradictions: contradictions}
  end
  
  @doc """
  Detect knowledge gaps based on topology analysis.
  
  ## Parameters
  
  - `result`: ScientificTopologyResult.t() - target result
  
  ## Returns
  
  ScientificTopologyResult.t() with detected knowledge gaps
  """
  def detect_knowledge_gaps(result) do
    gaps = []
    
    # Gap 1: Isolated theories suggest missing connections
    isolated_gaps = Enum.map(result.isolated_theories, fn isolated ->
      %{
        gap_type: :missing_connection,
        description: "Theory '#{isolated.title}' has no relationships to other theories",
        theory_id: isolated.theory_id,
        priority: :medium,
        suggested_action: "Investigate relationships to other theories in #{inspect(isolated.domain)}"
      }
    end)
    
    gaps = gaps ++ isolated_gaps
    
    # Gap 2: Contradictions suggest need for resolution
    contradiction_gaps = Enum.map(result.contradictions, fn contradiction ->
      %{
        gap_type: :unresolved_contradiction,
        description: "Contradiction between '#{contradiction.theory_1_title}' and '#{contradiction.theory_2_title}'",
        theory_ids: [contradiction.theory_1_id, contradiction.theory_2_id],
        priority: :high,
        suggested_action: "Design experiments to resolve contradiction"
      }
    end)
    
    gaps = gaps ++ contradiction_gaps
    
    # Gap 3: Sparse clusters suggest incomplete knowledge
    sparse_cluster_gaps = Enum.filter(result.clusters, & &1.density < 0.3)
      |> Enum.map(fn cluster ->
        %{
          gap_type: :sparse_cluster,
          description: "Cluster with low density (#{Float.round(cluster.density, 2)}) suggests incomplete knowledge",
          cluster_id: cluster.cluster_id,
          theory_count: cluster.size,
          priority: :low,
          suggested_action: "Explore additional theories to strengthen cluster"
        }
      end)
    
    gaps = gaps ++ sparse_cluster_gaps
    
    # Gap 4: Multiple disconnected clusters suggest missing bridges
    gaps = if length(result.clusters) > 1 do
      bridge_gap = %{
        gap_type: :missing_bridge,
        description: "#{length(result.clusters)} disconnected clusters suggest missing cross-domain bridges",
        cluster_count: length(result.clusters),
        priority: :medium,
        suggested_action: "Investigate potential bridging theories between clusters"
      }
      gaps ++ [bridge_gap]
    else
      gaps
    end
    
    %{result | knowledge_gaps: gaps}
  end
  
  @doc """
  Calculate topological metrics.
  
  ## Parameters
  
  - `result`: ScientificTopologyResult.t() - target result
  
  ## Returns
  
  ScientificTopologyResult.t() with calculated metrics
  """
  def calculate_metrics(result) do
    total_theories = length(result.theories)
    total_relationships = length(result.relationship_graph.edges)
    
    # Coverage: proportion of theories with at least one relationship
    connected_count = length(get_all_connected_ids(result.relationship_graph))
    coverage = if total_theories > 0 do
      Float.round(connected_count / total_theories, 4)
    else
      0.0
    end
    
    # Connectivity: average degree
    avg_degree = if total_theories > 0 do
      Float.round((total_relationships * 2) / total_theories, 4)
    else
      0.0
    end
    
    # Knowledge density: relationships per theory pair
    max_relationships = if total_theories > 1 do
      total_theories * (total_theories - 1)
    else
      1
    end
    density = Float.round(total_relationships / max_relationships, 4)
    
    # Fragmentation: number of clusters relative to theories
    fragmentation = if total_theories > 0 do
      Float.round(length(result.clusters) / total_theories, 4)
    else
      0.0
    end
    
    metrics = %{
      total_theories: total_theories,
      total_relationships: total_relationships,
      coverage: coverage,
      avg_degree: avg_degree,
      density: density,
      fragmentation: fragmentation,
      cluster_count: length(result.clusters),
      bridge_count: length(result.bridge_theories),
      isolated_count: length(result.isolated_theories),
      contradiction_count: length(result.contradictions),
      gap_count: length(result.knowledge_gaps)
    }
    
    %{result | topological_metrics: metrics}
  end
  
  @doc """
  Update overall confidence based on analysis quality.
  
  ## Parameters
  
  - `result`: ScientificTopologyResult.t() - target result
  
  ## Returns
  
  ScientificTopologyResult.t() with updated confidence
  """
  def update_confidence(result) do
    if length(result.theories) > 0 and result.topological_metrics != nil do
      # Confidence based on coverage and relationship density
      coverage_score = result.topological_metrics.coverage
      density_score = min(result.topological_metrics.density * 5, 1.0)  # Normalize
      
      confidence = (coverage_score * 0.6) + (density_score * 0.4)
      
      %{result | confidence: Float.round(confidence, 4)}
    else
      result
    end
  end
  
  @doc """
  Build traceability graph connecting topology to theories.
  
  ## Parameters
  
  - `result`: ScientificTopologyResult.t() - target result
  
  ## Returns
  
  ScientificTopologyResult.t() with traceability graph
  """
  def build_traceability_graph(result) do
    theory_to_relationships = Enum.reduce(result.relationship_graph.edges, %{}, fn edge, acc ->
      Map.update(acc, edge.from, [edge], &[edge | &1])
    end)
    
    %{result | traceability_graph: %{theory_to_relationships: theory_to_relationships}}
  end
  
  @doc """
  Verify traceability - every relationship references valid theories.
  
  ## Parameters
  
  - `result`: ScientificTopologyResult.t() - target result
  
  ## Returns
  
  boolean() - true if all relationships reference existing theories
  """
  def verify_traceability(result) do
    theory_ids = Enum.map(result.theories, & &1.theory_id)
    
    Enum.all?(result.relationship_graph.edges, fn edge ->
      edge.from in theory_ids and edge.to in theory_ids
    end)
  end
  
  @doc """
  Get bridge theories connecting different clusters.
  
  ## Parameters
  
  - `result`: ScientificTopologyResult.t() - target result
  
  ## Returns
  
  [map()] - list of bridge theories
  """
  def bridge_theories(result) do
    result.bridge_theories
  end
  
  @doc """
  Get isolated theories with no connections.
  
  ## Parameters
  
  - `result`: ScientificTopologyResult.t() - target result
  
  ## Returns
  
  [map()] - list of isolated theories
  """
  def isolated_theories(result) do
    result.isolated_theories
  end
  
  @doc """
  Count contradictions.
  
  ## Parameters
  
  - `result`: ScientificTopologyResult.t() - target result
  
  ## Returns
  
  non_neg_integer() - number of contradictions
  """
  def contradiction_count(result) do
    length(result.contradictions)
  end
  
  @doc """
  Calculate knowledge density metric.
  
  ## Parameters
  
  - `result`: ScientificTopologyResult.t() - target result
  
  ## Returns
  
  float() - knowledge density (0.0-1.0)
  """
  def knowledge_density(result) do
    if result.topological_metrics != nil do
      result.topological_metrics.density
    else
      0.0
    end
  end
  
  @doc """
  Calculate quality score based on topology completeness.
  
  ## Parameters
  
  - `result`: ScientificTopologyResult.t() - target result
  
  ## Returns
  
  ScientificTopologyResult.t() with quality assessment
  """
  def calculate_quality_score(result) do
    if result.topological_metrics != nil do
      metrics = result.topological_metrics
      
      # Weighted combination of coverage, density, and fragmentation
      coverage_weight = 0.4
      density_weight = 0.3
      fragmentation_weight = 0.3
      
      # Lower fragmentation is better
      fragmentation_score = 1.0 - min(metrics.fragmentation * 2, 1.0)
      
      quality_score = (metrics.coverage * coverage_weight) +
                      (metrics.density * density_weight) +
                      (fragmentation_score * fragmentation_weight)
      
      %{result | topological_metrics: Map.put(metrics, :quality_score, Float.round(quality_score, 4))}
    else
      result
    end
  end
  
  @doc """
  Mark topology analysis as completed.
  
  ## Parameters
  
  - `result`: ScientificTopologyResult.t() - target result
  
  ## Returns
  
  ScientificTopologyResult.t()
  """
  def mark_analyzed(result) do
    %{result | status: :analyzed}
  end
  
  @doc """
  Mark topology analysis as failed.
  
  ## Parameters
  
  - `result`: ScientificTopologyResult.t() - target result
  - `reason`: String.t() - failure reason
  
  ## Returns
  
  ScientificTopologyResult.t()
  """
  def mark_failed(result, reason) do
    %{result | status: :failed, failure_reason: reason}
  end
  
  @doc """
  Add a lifecycle event.
  
  ## Parameters
  
  - `result`: ScientificTopologyResult.t() - target result
  - `event`: map() - lifecycle event data
  
  ## Returns
  
  ScientificTopologyResult.t()
  """
  def add_lifecycle_event(result, event) do
    %{result | lifecycle_events: result.lifecycle_events ++ [event]}
  end
  
  @doc """
  Add a semantic event.
  
  ## Parameters
  
  - `result`: ScientificTopologyResult.t() - target result
  - `event_type`: atom() - type of semantic event
  - `data`: map() - event data
  
  ## Returns
  
  ScientificTopologyResult.t()
  """
  def add_semantic_event(result, event_type, data) do
    %{result | semantic_events: result.semantic_events ++ [%{type: event_type, data: data}]}
  end
  
  # Private helper functions
  
  defp identify_connected_components(graph) do
    # Simple BFS-based connected components
    nodes = Enum.map(graph.nodes, & &1.id)
    visited = MapSet.new()
    
    {components, _visited} = Enum.reduce(nodes, {[], visited}, fn node, {comps, vis} ->
      if MapSet.member?(vis, node) do
        {comps, vis}
      else
        {component, new_vis} = bfs_component(graph, node, vis)
        {[component | comps], new_vis}
      end
    end)
    
    Enum.reverse(components)
  end
  
  defp bfs_component(graph, start_node, visited) do
    queue = [start_node]
    component = []
    
    {component, visited} = bfs_loop(graph, queue, component, visited)
    {Enum.reverse(component), visited}
  end
  
  defp bfs_loop(_graph, [], component, visited) do
    {component, visited}
  end
  
  defp bfs_loop(graph, [current | rest], component, visited) do
    if MapSet.member?(visited, current) do
      bfs_loop(graph, rest, component, visited)
    else
      new_visited = MapSet.put(visited, current)
      new_component = [current | component]
      
      neighbors = get_neighbors(graph, current)
      new_queue = rest ++ neighbors
      
      bfs_loop(graph, new_queue, new_component, new_visited)
    end
  end
  
  defp get_neighbors(graph, node_id) do
    graph.edges
    |> Enum.filter(fn edge -> edge.from == node_id or edge.to == node_id end)
    |> Enum.flat_map(fn edge ->
      if edge.from == node_id, do: [edge.to], else: [edge.from]
    end)
    |> Enum.uniq()
  end
  
  defp calculate_cluster_density(graph, component) do
    node_count = length(component)
    if node_count <= 1 do
      0.0
    else
      internal_edges = Enum.count(graph.edges, fn edge ->
        edge.from in component and edge.to in component
      end)
      
      max_edges = node_count * (node_count - 1)
      Float.round(internal_edges / max_edges, 4)
    end
  end
  
  defp find_bridge_nodes(_graph, clusters) do
    # A bridge node connects to multiple clusters
    Enum.flat_map(clusters, fn cluster -> cluster.theory_ids end)
    |> Enum.uniq()
    |> Enum.filter(fn node_id ->
      connected_clusters = get_connected_clusters(clusters, node_id)
      length(connected_clusters) > 1
    end)
  end
  
  defp get_connected_clusters(clusters, theory_id) do
    Enum.filter(clusters, fn cluster ->
      theory_id in cluster.theory_ids
    end)
  end
  
  defp calculate_bridge_strength(graph, theory_id) do
    edges = Enum.filter(graph.edges, fn edge ->
      edge.from == theory_id or edge.to == theory_id
    end)
    
    length(edges) / max(length(graph.nodes), 1)
  end
  
  defp get_all_connected_ids(graph) do
    graph.edges
    |> Enum.flat_map(fn edge -> [edge.from, edge.to] end)
    |> Enum.uniq()
  end
end
