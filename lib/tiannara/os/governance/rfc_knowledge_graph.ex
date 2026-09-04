defmodule TiannaraOS.Governance.RFCKnowledgeGraph do
  require Logger
  @moduledoc """
  RFCKnowledgeGraph - Replayable proposal relationship graph
  
  Models constitutional evolution as a directed graph where proposals
  are nodes and relationships are edges. The entire graph is reconstructible
  from ledger events alone, making it archaeologically explainable.
  
  ## Owner
  GovernanceValidationLaboratory (existing, frozen)
  
  ## Relationship Types
  - `depends_on` - Proposal requires another proposal's changes
  - `supersedes` - Proposal replaces/invalidates previous proposal
  - `extends` - Proposal builds upon previous proposal
  - `conflicts_with` - Proposal contradicts another proposal
  - `references` - Proposal cites another proposal as evidence
  - `implements` - Proposal implements requirements from another
  - `validates` - Proposal validates claims in another proposal
  - `invalidates` - Proposal proves another proposal wrong
  
  ## Guarantees
  - Entire graph reconstructible from ledger events
  - No runtime state (ETS/GenServer)
  - Deterministic traversal
  - Content-addressed edges
  - Archaeological explainability
  """

  alias TiannaraOS.Governance.ProposalEvent

  @type relationship_type ::
          :depends_on | :supersedes | :extends | :conflicts_with |
          :references | :implements | :validates | :invalidates

  @type edge :: %{
    source: String.t(),
    target: String.t(),
    relationship: relationship_type,
    evidence_hash: String.t(),
    timestamp: DateTime.t()
  }

  @type t :: %{
    nodes: MapSet.t(String.t()),
    edges: [edge()],
    adjacency: %{String.t() => %{relationship_type => [String.t()]}}
  }

  @spec build_from_ledger([ProposalEvent.t()]) :: t()
  def build_from_ledger(events) do
    nodes =
      events
      |> Enum.map(& &1.proposal_id)
      |> Enum.uniq()
      |> MapSet.new()

    edges = extract_relationships(events)
    adjacency = build_adjacency(edges)

    %{nodes: nodes, edges: edges, adjacency: adjacency}
  end

  @spec get_dependencies(t(), String.t()) :: [String.t()]
  def get_dependencies(%{adjacency: adj}, proposal_id) do
    Map.get(adj, proposal_id, %{})
    |> Map.get(:depends_on, [])
  end

  @spec get_superseded(t(), String.t()) :: [String.t()]
  def get_superseded(%{adjacency: adj}, proposal_id) do
    Map.get(adj, proposal_id, %{})
    |> Map.get(:supersedes, [])
  end

  @spec get_references_to(t(), String.t()) :: [String.t()]
  def get_references_to(%{edges: edges}, proposal_id) do
    edges
    |> Enum.filter(fn edge ->
      edge.target == proposal_id and edge.relationship == :references
    end)
    |> Enum.map(& &1.source)
  end

  @spec get_lineage(t(), String.t()) :: [String.t()]
  def get_lineage(graph, proposal_id) do
    do_get_lineage(graph, proposal_id, [])
    |> Enum.reverse()
  end

  @spec detect_cycles(t()) :: {:ok, []} | {:error, [String.t()]}
  def detect_cycles(%{adjacency: adj, nodes: nodes}) do
    visited = MapSet.new()

    Enum.reduce_while(MapSet.to_list(nodes), {:ok, []}, fn node, {:ok, _} ->
      case dfs_cycle_check(adj, node, visited, []) do
        {:cycle, path} -> {:halt, {:error, path}}
        :no_cycle -> {:cont, {:ok, []}}
      end
    end)
  end

  @spec calculate_metrics(t()) :: map()
  def calculate_metrics(%{nodes: nodes, edges: edges}) do
    node_count = MapSet.size(nodes)
    edge_count = length(edges)

    avg_degree = if node_count > 0, do: edge_count * 2 / node_count, else: 0

    relationship_counts =
      edges
      |> Enum.group_by(& &1.relationship)
      |> Enum.map(fn {k, v} -> {Atom.to_string(k), length(v)} end)
      |> Map.new()

    density = if node_count > 1, do: edge_count / (node_count * (node_count - 1)), else: 0

    %{
      node_count: node_count,
      edge_count: edge_count,
      average_degree: Float.round(avg_degree, 3),
      relationship_distribution: relationship_counts,
      density: density
    }
  end

  @spec to_json_map(t()) :: map()
  def to_json_map(%{nodes: nodes, edges: edges}) do
    %{
      nodes: MapSet.to_list(nodes),
      edges:
        Enum.map(edges, fn edge ->
          %{
            source: edge.source,
            target: edge.target,
            relationship: Atom.to_string(edge.relationship),
            evidence_hash: edge.evidence_hash,
            timestamp: DateTime.to_iso8601(edge.timestamp)
          }
        end)
    }
  end

  @spec compute_hash(t()) :: String.t()
  def compute_hash(graph) do
    json_map = to_json_map(graph)
    json = Jason.encode!(json_map)
    :crypto.hash(:sha256, json) |> Base.encode16(case: :lower)
  end

  # === Private Implementation ===

  defp extract_relationships(events) do
    events
    |> Enum.filter(fn event ->
      Map.has_key?(event, :metadata) and not is_nil(event.metadata)
    end)
    |> Enum.flat_map(fn event ->
      extract_edges_from_event(event)
    end)
  end

  defp extract_edges_from_event(event) do
    metadata = Map.get(event, :metadata, %{})
    edges = []

    edges =
      if Map.has_key?(metadata, :depends_on) do
        deps = metadata.depends_on

        dep_edges =
          Enum.map(List.wrap(deps), fn dep_id ->
            %{
              source: event.proposal_id,
              target: dep_id,
              relationship: :depends_on,
              evidence_hash: event.event_hash,
              timestamp: event.timestamp
            }
          end)

        edges ++ dep_edges
      else
        edges
      end

    edges =
      if Map.has_key?(metadata, :supersedes) do
        sups = metadata.supersedes

        sup_edges =
          Enum.map(List.wrap(sups), fn sup_id ->
            %{
              source: event.proposal_id,
              target: sup_id,
              relationship: :supersedes,
              evidence_hash: event.event_hash,
              timestamp: event.timestamp
            }
          end)

        edges ++ sup_edges
      else
        edges
      end

    edges
  end

  defp build_adjacency(edges) do
    Enum.reduce(edges, %{}, fn edge, acc ->
      source = edge.source
      rel = edge.relationship
      target = edge.target

      acc
      |> Map.put_new(source, %{})
      |> update_in([source, rel], fn existing ->
        [target | List.wrap(existing)]
      end)
    end)
  end

  defp do_get_lineage(graph, proposal_id, visited) do
    if proposal_id in visited do
      visited
    else
      visited = [proposal_id | visited]
      deps = get_dependencies(graph, proposal_id)
      Enum.reduce(deps, visited, fn dep_id, acc ->
        do_get_lineage(graph, dep_id, acc)
      end)
    end
  end

  defp dfs_cycle_check(adj, node, visited, path) do
    if MapSet.member?(visited, node) do
      :no_cycle
    else
      visited = MapSet.put(visited, node)
      path = [node | path]

      neighbors =
        Map.get(adj, node, %{})
        |> Map.values()
        |> List.flatten()

      Enum.reduce_while(neighbors, :no_cycle, fn neighbor, _acc ->
        if neighbor in path do
          {:halt, {:cycle, Enum.reverse([neighbor | path])}}
        else
          case dfs_cycle_check(adj, neighbor, visited, path) do
            {:cycle, cycle_path} -> {:halt, {:cycle, cycle_path}}
            :no_cycle -> {:cont, :no_cycle}
          end
        end
      end)
    end
  end
end

