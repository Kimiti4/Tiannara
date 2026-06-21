defmodule Tiannara.REA.EvolutionaryIdentity do
  @moduledoc """
  Universal identity for every evolutionary entity in Tiannara.
  
  This is the single source of truth for lineage, regardless of whether
  the organism is a civilization, epistemology, law species, or meta-genome.
  """
  
  @type level :: :civilization | :epistemology | :law_species | :meta_genome
  @type scale :: :individual | :species | :ecosystem | :law | :meta_law
  
  @type t :: %__MODULE__{
    id: binary(),
    parent_ids: [binary()],
    lineage_id: binary(),
    species_id: binary() | nil,
    generation: non_neg_integer(),
    birth_epoch: non_neg_integer(),
    extinction_epoch: non_neg_integer() | nil,
    level: level(),
    scale: scale(),
    trait_signature: map()
  }
  
  defstruct [
    :id,
    :lineage_id,
    :species_id,
    :birth_epoch,
    :level,
    :scale,
    parent_ids: [],
    generation: 0,
    extinction_epoch: nil,
    trait_signature: %{}
  ]
  
  @doc "Spawn a root identity."
  @spec root(level(), scale(), non_neg_integer(), map()) :: t()
  def root(level, scale, epoch, traits \\ %{}) do
    id = generate_id()
    %__MODULE__{
      id: id,
      parent_ids: [],
      lineage_id: id,
      species_id: nil,
      generation: 0,
      birth_epoch: epoch,
      level: level,
      scale: scale,
      trait_signature: traits
    }
  end
  
  @doc "Spawn a descendant via mutation."
  @spec descend(t(), non_neg_integer(), map()) :: t()
  def descend(%__MODULE__{} = parent, epoch, trait_delta \\ %{}) do
    new_traits = Map.merge(parent.trait_signature, trait_delta)
    %__MODULE__{
      id: generate_id(),
      parent_ids: [parent.id],
      lineage_id: parent.lineage_id,
      species_id: parent.species_id,
      generation: parent.generation + 1,
      birth_epoch: epoch,
      level: parent.level,
      scale: parent.scale,
      trait_signature: new_traits
    }
  end
  
  @doc "Spawn a descendant via recombination."
  @spec recombine([t()], non_neg_integer(), map()) :: t()
  def recombine([primary | _others] = parents, epoch, trait_delta \\ %{})
      when is_list(parents) do
    new_traits =
      parents
      |> Enum.reduce(%{}, fn p, acc -> Map.merge(acc, p.trait_signature) end)
      |> Map.merge(trait_delta)
    
    %__MODULE__{
      id: generate_id(),
      parent_ids: Enum.map(parents, & &1.id),
      lineage_id: primary.lineage_id,
      species_id: primary.species_id,
      generation: primary.generation + 1,
      birth_epoch: epoch,
      level: primary.level,
      scale: primary.scale,
      trait_signature: new_traits
    }
  end
  
  @doc "Mark as extinct."
  @spec mark_extinct(t(), non_neg_integer()) :: t()
  def mark_extinct(%__MODULE__{} = id, epoch), do: %{id | extinction_epoch: epoch}
  
  @doc "True if archived."
  @spec extinct?(t()) :: boolean()
  def extinct?(%__MODULE__{extinction_epoch: nil}), do: false
  def extinct?(%__MODULE__{}), do: true
  
  defp generate_id, do: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
end
