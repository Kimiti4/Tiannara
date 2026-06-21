defmodule Tiannara.REA.EvolutionaryRuin do
  @moduledoc """
  Universal archaeology substrate.
  
  Specialized ruins (LawRuin, MetaRuin, etc.) map to this
  structure. This unifies Sentinel's archaeological queries.
  """
  
  @type collapse_reason ::
    :fitness_collapse |
    :resource_exhaustion |
    :catastrophic_shock |
    :predation |
    :stagnation |
    :internal_contradiction |
    :external_pressure
  
  @type t :: %__MODULE__{
    organism_id: binary(),
    organism_type: atom(),
    identity: Tiannara.REA.EvolutionaryIdentity.t(),
    peak_fitness: float(),
    terminal_fitness: float(),
    collapse_signature: %{
      reason: collapse_reason(),
      pressure_vector: map(),
      epoch: non_neg_integer(),
      generation_lifespan: non_neg_integer()
    },
    ancestry_depth: non_neg_integer(),
    trait_fossil: map(),
    epoch: non_neg_integer(),
    metadata: map()
  }
  
  defstruct [
    :organism_id,
    :organism_type,
    :identity,
    :peak_fitness,
    :terminal_fitness,
    :collapse_signature,
    :ancestry_depth,
    :trait_fossil,
    :epoch,
    metadata: %{}
  ]
  
  @doc "Construct a ruin from an organism and its identity at death."
  @spec from_organism(term(), Tiannara.REA.EvolutionaryIdentity.t(), keyword()) :: t()
  def from_organism(_organism, %Tiannara.REA.EvolutionaryIdentity{} = identity, opts) do
    peak = Keyword.fetch!(opts, :peak_fitness)
    terminal = Keyword.fetch!(opts, :terminal_fitness)
    reason = Keyword.fetch!(opts, :collapse_reason)
    pressure = Keyword.get(opts, :pressure_vector, %{})
    epoch = Keyword.fetch!(opts, :epoch)
    traits = Keyword.get(opts, :trait_fossil, %{})
    
    %__MODULE__{
      organism_id: identity.id,
      organism_type: identity.level,
      identity: identity,
      peak_fitness: peak,
      terminal_fitness: terminal,
      collapse_signature: %{
        reason: reason,
        pressure_vector: pressure,
        epoch: epoch,
        generation_lifespan: identity.generation
      },
      ancestry_depth: identity.generation,
      trait_fossil: traits,
      epoch: epoch
    }
  end
end
