defmodule Tiannara.ASC.Crucible.RepairPhylogeny.RepairDescendant do
  @moduledoc """
  Represents an evolutionary transition - a child pattern derived from a parent.
  
  Descendants track:
  - Parent-child relationships in repair evolution
  - Mutation types (strategy changes, parameter tuning, etc.)
  - Fitness deltas (improvement or degradation)
  - Survival outcomes
  - Transfer success across projects
  
  This is the fundamental unit of evolutionary branching analysis.
  """



  @derive Jason.Encoder
  defstruct [
    # Identity
    id: nil,
    parent_pattern_id: nil,
    child_pattern_id: nil,
    
    # Evolutionary
    mutation_type: :unknown,
    fitness_delta: 0.0,
    generation: 0,
    
    # Outcome
    survived: false,
    transfer_success: false,
    
    # Temporal
    created_at: nil
    
  ]

  @type t :: %__MODULE__{}

  @doc """
  Create a descendant record representing an evolutionary transition.
  
  Captures the moment when a new pattern branches from an existing one.
  """
  def from_evolution(parent, child, generation) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    fitness_delta = child.repair_fitness - parent.repair_fitness
    
    %__MODULE__{
      id: generate_descendant_id(parent.id, child.id),
      parent_pattern_id: parent.id,
      child_pattern_id: child.id,
      mutation_type: classify_mutation(parent, child),
      fitness_delta: Float.round(fitness_delta, 3),
      generation: generation,
      survived: child.success_rate > 0.5,
      transfer_success: child.transferability > 0.6,
      created_at: now
    }
  end

  defp classify_mutation(parent, child) do
    cond do
      # Strategy change
      parent.repair_strategy != child.repair_strategy ->
        :strategy_change
      
      # Parameter tuning (same strategy, different parameters)
      parent.parameters != child.parameters && parent.repair_strategy == child.repair_strategy ->
        :parameter_tuning
      
      # Scope expansion (applied to more contexts)
      length(child.projects_used || []) > length(parent.projects_used || []) ->
        :scope_expansion
      
      # Specialization (narrowed application)
      length(child.projects_used || []) < length(parent.projects_used || []) ->
        :specialization
      
      # Fitness improvement without structural change
      child.repair_fitness > parent.repair_fitness * 1.1 ->
        :fitness_optimization
      
      # Default: unknown mutation
      true ->
        :unknown
    end
  end

  @doc """
  Mark descendant as survived (successful adaptation).
  """
  def mark_survived(%__MODULE__{} = descendant) do
    %__MODULE__{
      descendant
      | survived: true
    }
  end

  @doc """
  Mark descendant as successfully transferred.
  """
  def mark_transferred(%__MODULE__{} = descendant) do
    %__MODULE__{
      descendant
      | transfer_success: true
    }
  end

  @doc """
  Get descendant metrics for observability.
  """
  def get_metrics(%__MODULE__{} = descendant) do
    %{
      descendant_id: descendant.id,
      parent_pattern_id: descendant.parent_pattern_id,
      child_pattern_id: descendant.child_pattern_id,
      mutation_type: descendant.mutation_type,
      fitness_delta: descendant.fitness_delta,
      generation: descendant.generation,
      survived: descendant.survived,
      transfer_success: descendant.transfer_success
    }
  end

  # Private Helpers

  defp generate_descendant_id(parent_id, child_id) do
    "descendant_#{parent_id}_#{child_id}"
  end
end
