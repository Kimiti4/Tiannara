defmodule TiannaraOS.Governance.ProposalLineage do
  @moduledoc """
  ProposalLineage - Dependency tree builder for proposals
  
  Constructs complete dependency graphs showing:
  - Parent RFC relationships
  - Supersedes chains (what this replaces)
  - Depends-on relationships (prerequisites)
  - Sibling proposals (same RFC)
  - Impact radius (what depends on this)
  
  ## Owner
  Read-only lineage analysis engine.
  
  ## Use Cases
  - Impact assessment before approval
  - Rollback planning
  - Understanding proposal context
  - Identifying circular dependencies
  """

  alias TiannaraOS.Governance.ProposalLedger

  # === Public API ===

  @doc """
  Build complete dependency tree for a proposal.
  """
  @spec build_dependency_tree(String.t()) :: {:ok, map()} | {:error, String.t()}
  def build_dependency_tree(proposal_id) do
    with {:ok, proposal} <- fetch_proposal(proposal_id),
         {:ok, events} <- fetch_events(proposal_id) do
      
      tree = %{
        root: proposal_id,
        parent_rfc: get_parent_rfc(events),
        ancestors: get_ancestors(proposal_id),
        descendants: get_descendants(proposal_id),
        prerequisites: get_prerequisites(proposal),
        dependents: get_dependents(proposal_id),
        siblings: get_siblings(proposal_id, events),
        depth: calculate_depth(proposal_id),
        breadth: calculate_breadth(proposal_id),
        has_cycles: detect_cycles(proposal_id)
      }
      
      {:ok, tree}
    end
  end

  @doc """
  Get all ancestors (proposals this supersedes, recursively).
  """
  @spec get_ancestors(String.t()) :: [String.t()]
  def get_ancestors(proposal_id) do
    do_get_ancestors(proposal_id, [])
  end

  @doc """
  Get all descendants (proposals that supersede this, recursively).
  """
  @spec get_descendants(String.t()) :: [String.t()]
  def get_descendants(proposal_id) do
    do_get_descendants(proposal_id, [])
  end

  @doc """
  Get prerequisite proposals (depends_on relationships).
  """
  @spec get_prerequisites(map()) :: [String.t()]
  def get_prerequisites(proposal) do
    Map.get(proposal, :depends_on, [])
  end

  @doc """
  Get proposals that depend on this one.
  """
  @spec get_dependents(String.t()) :: [String.t()]
  def get_dependents(target_id) do
    all_events = ProposalLedger.get_all_events()
    
    all_events
    |> Enum.filter(&(&1.type == :proposal_created))
    |> Enum.map(& &1.proposal_id)
    |> Enum.uniq()
    |> Enum.filter(fn proposal_id ->
      case fetch_proposal(proposal_id) do
        {:ok, proposal} ->
          target_id in get_prerequisites(proposal)
        {:error, _} ->
          false
      end
    end)
  end

  @doc """
  Get sibling proposals (same RFC).
  """
  @spec get_siblings(String.t(), [map()]) :: [String.t()]
  def get_siblings(proposal_id, events) do
    rfc_id = get_parent_rfc(events)
    
    if rfc_id do
      ProposalLedger.get_rfc_events(rfc_id)
      |> Enum.filter(&(&1.type == :proposal_created))
      |> Enum.map(& &1.proposal_id)
      |> Enum.uniq()
      |> Enum.reject(&(&1 == proposal_id))
    else
      []
    end
  end

  @doc """
  Calculate impact radius (how many proposals would be affected).
  """
  @spec calculate_impact_radius(String.t()) :: map()
  def calculate_impact_radius(proposal_id) do
    direct_dependents = get_dependents(proposal_id)
    all_descendants = get_descendants(proposal_id)
    
    %{
      proposal_id: proposal_id,
      direct_impact: length(direct_dependents),
      transitive_impact: length(all_descendants),
      total_affected: length(Enum.uniq(direct_dependents ++ all_descendants)),
      affected_proposals: Enum.uniq(direct_dependents ++ all_descendants)
    }
  end

  @doc """
  Detect circular dependencies.
  """
  @spec detect_cycles(String.t()) :: boolean()
  def detect_cycles(proposal_id) do
    visited = MapSet.new()
    do_detect_cycles(proposal_id, visited)
  end

  @doc """
  Get lineage summary for visualization.
  """
  @spec get_lineage_summary(String.t()) :: {:ok, map()} | {:error, String.t()}
  def get_lineage_summary(proposal_id) do
    with {:ok, tree} <- build_dependency_tree(proposal_id) do
      summary = %{
        proposal_id: proposal_id,
        total_ancestors: length(tree.ancestors),
        total_descendants: length(tree.descendants),
        total_prerequisites: length(tree.prerequisites),
        total_dependents: length(tree.dependents),
        total_siblings: length(tree.siblings),
        tree_depth: tree.depth,
        tree_breadth: tree.breadth,
        has_cycles: tree.has_cycles,
        is_root: length(tree.ancestors) == 0,
        is_leaf: length(tree.descendants) == 0
      }
      
      {:ok, summary}
    end
  end

  # === Private Functions ===

  defp do_get_ancestors(proposal_id, visited) do
    if MapSet.member?(visited, proposal_id) do
      []  # Cycle detected, stop recursion
    else
      visited = MapSet.put(visited, proposal_id)
      
      events = ProposalLedger.get_proposal_events(proposal_id)
      supersedes_chain = get_supersedes_from_events(events)
      
      Enum.flat_map(supersedes_chain, fn ancestor_id ->
        [ancestor_id | do_get_ancestors(ancestor_id, visited)]
      end)
      |> Enum.uniq()
    end
  end

  defp do_get_descendants(proposal_id, visited) do
    if MapSet.member?(visited, proposal_id) do
      []
    else
      visited = MapSet.put(visited, proposal_id)
      
      descendants = get_direct_descendants(proposal_id)
      
      Enum.flat_map(descendants, fn descendant_id ->
        [descendant_id | do_get_descendants(descendant_id, visited)]
      end)
      |> Enum.uniq()
    end
  end

  defp get_supersedes_from_events(events) do
    case Enum.find(events, &(&1.type == :proposal_superseded)) do
      nil -> []
      event -> [event.data.superseded_by]
    end
  end

  defp get_direct_descendants(proposal_id) do
    all_events = ProposalLedger.get_all_events()
    
    all_events
    |> Enum.filter(&(&1.type == :proposal_superseded))
    |> Enum.filter(&(&1.data.superseded_by == proposal_id))
    |> Enum.map(& &1.proposal_id)
    |> Enum.uniq()
  end

  defp get_parent_rfc(events) do
    case Enum.find(events, &(&1.type == :proposal_created)) do
      nil -> nil
      event -> event.rfc_id
    end
  end

  defp fetch_proposal(proposal_id) do
    case ProposalLedger.get_proposal_state(proposal_id) do
      nil -> {:error, "Proposal not found: #{proposal_id}"}
      state -> {:ok, state}
    end
  end

  defp fetch_events(proposal_id) do
    events = ProposalLedger.get_proposal_events(proposal_id)
    
    if Enum.empty?(events) do
      {:error, "No events found for proposal #{proposal_id}"}
    else
      {:ok, events}
    end
  end

  defp calculate_depth(proposal_id) do
    ancestors = get_ancestors(proposal_id)
    length(ancestors) + 1
  end

  defp calculate_breadth(proposal_id) do
    descendants = get_descendants(proposal_id)
    length(descendants) + 1
  end

  defp do_detect_cycles(proposal_id, visited) do
    if MapSet.member?(visited, proposal_id) do
      true  # Cycle found
    else
      visited = MapSet.put(visited, proposal_id)
      
      events = ProposalLedger.get_proposal_events(proposal_id)
      supersedes_chain = get_supersedes_from_events(events)
      
      Enum.any?(supersedes_chain, fn ancestor_id ->
        do_detect_cycles(ancestor_id, visited)
      end)
    end
  end
end
