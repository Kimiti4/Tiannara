defmodule Tiannara.ASC.Crucible.RepairPhylogeny.RepairLineage do
  @moduledoc """
  Represents a continuous family of repairs - the evolutionary lineage from ancestor to descendants.
  
  A lineage tracks:
  - Ancestry chain (root → parent → child)
  - Fitness evolution over time
  - Transfer history across projects
  - Survival across epochs
  - Descendant generation count
  
  This is the core unit of engineering phylogeny analysis.
  """

  alias Tiannara.ASC.Crucible.RepairPattern

  @derive Jason.Encoder
  defstruct [
    # Identity
    id: nil,
    root_pattern_id: nil,
    current_pattern_id: nil,
    
    # Temporal
    generation: 0,
    created_at: nil,
    updated_at: nil,
    
    # Phylogenetic
    species_id: nil,
    ancestor_ids: [],
    descendant_ids: [],
    
    # Evolutionary History
    fitness_history: [],
    survival_epochs: 0,
    transfer_count: 0,
    repair_count: 0,
    
    # Status
    status: :active  # :active, :extinct
    
  ]

  @type t :: %__MODULE__{}

  @doc """
  Create a new lineage from a founding repair pattern.
  
  The first pattern in a lineage becomes the root ancestor.
  """
  def from_root_pattern(%RepairPattern{} = pattern, species_id, generation, _epoch_id) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    %__MODULE__{
      id: generate_lineage_id(pattern.id),
      root_pattern_id: pattern.id,
      current_pattern_id: pattern.id,
      generation: generation,
      species_id: species_id,
      ancestor_ids: [pattern.id],
      descendant_ids: [],
      fitness_history: [{generation, pattern.repair_fitness}],
      survival_epochs: 1,
      transfer_count: 0,
      repair_count: 1,
      created_at: now,
      updated_at: now,
      status: :active
    }
  end

  @doc """
  Add a descendant pattern to an existing lineage.
  
  This represents evolutionary branching - a new pattern derived from an ancestor.
  """
  def add_descendant(%__MODULE__{} = lineage, %RepairPattern{} = descendant, generation) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    %__MODULE__{
      lineage
      | current_pattern_id: descendant.id,
        descendant_ids: lineage.descendant_ids ++ [descendant.id],
        fitness_history: lineage.fitness_history ++ [{generation, descendant.repair_fitness}],
        repair_count: lineage.repair_count + 1,
        updated_at: now
    }
  end

  @doc """
  Record a successful transfer for this lineage.
  """
  def record_transfer(%__MODULE__{} = lineage) do
    %__MODULE__{
      lineage
      | transfer_count: lineage.transfer_count + 1
    }
  end

  @doc """
  Increment survival epoch counter.
  """
  def increment_survival(%__MODULE__{} = lineage) do
    %__MODULE__{
      lineage
      | survival_epochs: lineage.survival_epochs + 1
    }
  end

  @doc """
  Mark lineage as extinct.
  """
  def mark_extinct(%__MODULE__{} = lineage) do
    %__MODULE__{
      lineage
      | status: :extinct
    }
  end

  @doc """
  Calculate lineage depth (number of generations from root to current).
  """
  def depth(%__MODULE__{} = lineage) do
    length(lineage.ancestor_ids) + length(lineage.descendant_ids)
  end

  @doc """
  Calculate average fitness across lineage history.
  """
  def average_fitness(%__MODULE__{} = lineage) do
    case lineage.fitness_history do
      [] -> 0.0
      history ->
        Enum.sum_by(history, fn {_gen, fitness} -> fitness end) / length(history)
    end
  end

  @doc """
  Calculate fitness improvement rate (trend over time).
  """
  def fitness_improvement_rate(%__MODULE__{} = lineage) do
    case lineage.fitness_history do
      [_single] -> 0.0
      history ->
        sorted = Enum.sort_by(history, fn {gen, _fit} -> gen end)
        first_fit = elem(hd(sorted), 1)
        last_fit = elem(List.last(sorted), 1)
        
        if first_fit > 0 do
          (last_fit - first_fit) / first_fit
        else
          0.0
        end
    end
  end

  @doc """
  Check if lineage is deep enough to be considered evolutionarily significant.
  """
  def is_significant?(%__MODULE__{} = lineage) do
    depth(lineage) >= 3 and lineage.survival_epochs >= 2
  end

  @doc """
  Get lineage metrics for observability.
  """
  def get_metrics(%__MODULE__{} = lineage) do
    %{
      lineage_id: lineage.id,
      root_pattern_id: lineage.root_pattern_id,
      current_pattern_id: lineage.current_pattern_id,
      depth: depth(lineage),
      average_fitness: Float.round(average_fitness(lineage), 3),
      fitness_improvement_rate: Float.round(fitness_improvement_rate(lineage), 3),
      survival_epochs: lineage.survival_epochs,
      transfer_count: lineage.transfer_count,
      repair_count: lineage.repair_count,
      ancestor_count: length(lineage.ancestor_ids),
      descendant_count: length(lineage.descendant_ids),
      status: lineage.status
    }
  end

  # Private Helpers

  defp generate_lineage_id(root_pattern_id) do
    "lineage_#{root_pattern_id}"
  end
end
