defmodule Tiannara.ASC.Crucible.RepairPhylogeny.RepairAncestor do
  @moduledoc """
  Represents the root ancestor of a repair lineage.
  
  Ancestors are the founding patterns that started evolutionary lineages.
  They represent the origins of successful engineering strategies.
  
  Key questions answered by tracking ancestors:
  - Which founding strategies produced the most descendants?
  - Which ancestral environments favored long-term survival?
  - Which failure types generated the most adaptable lineages?
  """

  alias Tiannara.ASC.Crucible.RepairPattern

  @derive Jason.Encoder
  defstruct [
    # Identity
    id: nil,
    pattern_id: nil,
    species_id: nil,
    
    # Temporal
    generation_created: 0,
    created_at: nil,
    
    # Founding Context
    founding_environment: nil,
    founding_failure_type: nil,
    founding_fitness: 0.0,
    
    # Legacy Metrics
    total_descendants: 0,
    lineage_survived: false,
    max_lineage_depth: 0
    
  ]

  @type t :: %__MODULE__{}

  @doc """
  Create an ancestor record from a founding repair pattern.
  
  This captures the "birth" conditions of a new evolutionary lineage.
  """
  def from_founding_pattern(%RepairPattern{} = pattern, species_id, generation, project_domain) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    %__MODULE__{
      id: generate_ancestor_id(pattern.id),
      pattern_id: pattern.id,
      species_id: species_id,
      generation_created: generation,
      created_at: now,
      founding_environment: project_domain,
      founding_failure_type: classify_failure_type(pattern),
      founding_fitness: pattern.repair_fitness,
      total_descendants: 0,
      lineage_survived: false,
      max_lineage_depth: 1
    }
  end

  @doc """
  Update ancestor with descendant count and lineage status.
  """
  def update_legacy(%__MODULE__{} = ancestor, descendant_count, lineage_depth, lineage_survived) do
    %__MODULE__{
      ancestor
      | total_descendants: descendant_count,
        max_lineage_depth: max(ancestor.max_lineage_depth, lineage_depth),
        lineage_survived: lineage_survived
    }
  end

  defp classify_failure_type(%RepairPattern{} = pattern) do
    failure_context = String.downcase(pattern.failure_context || "")
    
    cond do
      String.contains?(failure_context, ["auth", "permission", "access"]) ->
        :authentication_failure
      String.contains?(failure_context, ["timeout", "latency", "performance"]) ->
        :performance_failure
      String.contains?(failure_context, ["null", "nil", "undefined"]) ->
        :null_reference_failure
      String.contains?(failure_context, ["constraint", "validation", "invariant"]) ->
        :constraint_violation
      String.contains?(failure_context, ["race", "concurrent", "parallel"]) ->
        :race_condition
      String.contains?(failure_context, ["memory", "leak", "overflow"]) ->
        :resource_exhaustion
      String.contains?(failure_context, ["network", "connection", "socket"]) ->
        :network_failure
      true ->
        :unknown_failure
    end
  end

  @doc """
  Get ancestor metrics for observability.
  """
  def get_metrics(%__MODULE__{} = ancestor) do
    %{
      ancestor_id: ancestor.id,
      pattern_id: ancestor.pattern_id,
      species_id: ancestor.species_id,
      generation_created: ancestor.generation_created,
      founding_environment: ancestor.founding_environment,
      founding_failure_type: ancestor.founding_failure_type,
      founding_fitness: ancestor.founding_fitness,
      total_descendants: ancestor.total_descendants,
      lineage_survived: ancestor.lineage_survived,
      max_lineage_depth: ancestor.max_lineage_depth
    }
  end

  # Private Helpers

  defp generate_ancestor_id(pattern_id) do
    "ancestor_#{pattern_id}"
  end
end
