defmodule Tiannara.ASC.Crucible.RepairPhylogeny.RepairClade do
  @moduledoc """
  A clade is a group of related repair lineages sharing common ancestry.
  
  Examples:
  - Rollback Clade (all rollback-related lineages)
  - Retry Clade (all retry-related lineages)
  - Auth Hardening Clade
  - Constraint Reinforcement Clade
  
  Clades represent major evolutionary branches in engineering strategy space.
  They allow analysis at the family level rather than individual lineage level.
  """

  alias Tiannara.ASC.Crucible.RepairEcology.RepairSpecies
  alias __MODULE__

  @derive Jason.Encoder
  defstruct [
    # Identity
    id: nil,
    name: nil,
    
    # Composition
    lineage_ids: [],
    species_ids: [],
    
    # Population Metrics
    population_size: 0,
    average_fitness: 0.0,
    survival_rate: 0.0,
    transferability: 0.0,
    
    # Temporal
    created_at: nil,
    updated_at: nil
    
  ]

  @type t :: %__MODULE__{}

  @doc """
  Create a new clade from a group of related species.
  
  Species are grouped by their classification (Rollback, Retry, etc.)
  to form clades representing major evolutionary families.
  """
  def from_species(species_list, generation) when is_list(species_list) and length(species_list) > 0 do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    clade_name = classify_clade_name(hd(species_list))
    
    %__MODULE__{
      id: generate_clade_id(clade_name),
      name: clade_name,
      lineage_ids: [],
      species_ids: Enum.map(species_list, & &1.id),
      population_size: Enum.sum_by(species_list, & &1.population_size),
      average_fitness: calculate_average_fitness(species_list),
      survival_rate: calculate_survival_rate(species_list),
      transferability: calculate_transferability(species_list),
      created_at: now,
      updated_at: now
    }
  end

  @doc """
  Add lineages to an existing clade.
  """
  def add_lineages(%__MODULE__{} = clade, lineage_ids) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    %__MODULE__{
      clade
      | lineage_ids: clade.lineage_ids ++ lineage_ids,
        population_size: length(clade.lineage_ids) + length(lineage_ids),
        updated_at: now
    }
  end

  @doc """
  Update clade metrics based on current state of member lineages.
  """
  def update_metrics(%__MODULE__{} = clade, lineages) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    
    active_count = Enum.count(lineages, & &1.status == :active)
    total_count = length(lineages)
    
    avg_fitness = 
      if total_count > 0 do
        Enum.sum_by(lineages, fn l -> RepairLineage.average_fitness(l) end) / total_count
      else
        0.0
      end
    
    survival_rate = 
      if total_count > 0 do
        active_count / total_count
      else
        0.0
      end
    
    avg_transferability =
      if total_count > 0 do
        Enum.sum_by(lineages, & &1.transfer_count) / total_count / 10.0
      else
        0.0
      end
    
    %__MODULE__{
      clade
      | population_size: total_count,
        average_fitness: Float.round(avg_fitness, 3),
        survival_rate: Float.round(survival_rate, 3),
        transferability: Float.round(min(avg_transferability, 1.0), 3),
        updated_at: now
    }
  end

  @doc """
  Classify clade name from representative species.
  """
  defp classify_clade_name(%RepairSpecies{} = species) do
    species.name
  end

  @doc """
  Calculate average fitness across all species in clade.
  """
  defp calculate_average_fitness(species_list) do
    case species_list do
      [] -> 0.0
      _ ->
        Enum.sum_by(species_list, & &1.fitness) / length(species_list)
    end
  end

  @doc """
  Calculate survival rate (percentage of active species).
  """
  defp calculate_survival_rate(species_list) do
    case species_list do
      [] -> 0.0
      _ ->
        active_count = Enum.count(species_list, & &1.status == :active)
        active_count / length(species_list)
    end
  end

  @doc """
  Calculate average transferability across species.
  """
  defp calculate_transferability(species_list) do
    case species_list do
      [] -> 0.0
      _ ->
        Enum.sum_by(species_list, & &1.transferability) / length(species_list)
    end
  end

  @doc """
  Get clade metrics for observability.
  """
  def get_metrics(%__MODULE__{} = clade) do
    %{
      clade_id: clade.id,
      clade_name: clade.name,
      lineage_count: length(clade.lineage_ids),
      species_count: length(clade.species_ids),
      population_size: clade.population_size,
      average_fitness: clade.average_fitness,
      survival_rate: clade.survival_rate,
      transferability: clade.transferability
    }
  end

  # Private Helpers

  defp generate_clade_id(clade_name) do
    "clade_#{String.replace(String.downcase(clade_name), " ", "_")}"
  end
end
