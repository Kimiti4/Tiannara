defmodule Tiannara.SOPL.LawSpecies do
  @moduledoc """
  SOPL-4: Law Species, retrofitted to the REA contract.
  
  The new primary evolutionary unit of cosmology. Groups %UniverseArchetype{} 
  and %LawGenome{} instances that share common evolutionary structure, 
  tracking emergent properties invisible at the fragment level.
  """
  @behaviour Tiannara.REA.EvolutionaryOrganism
  
  alias Tiannara.REA.{EvolutionaryIdentity, EvolutionaryRuin, LineageRegistry, EvolutionaryEnvironment}
  
  defstruct [
    :identity,
    :ancestor_lineage,      
    :defining_fragments,    
    :constitutional_profile,
    :pathology_profile,     
    :attractor_affinity,    
    :emergent_properties,
    :niche_specialization,
    :adaptive_capacity,
    :universes,            
    peak_fitness: 0.0
  ]
  
  @type t :: %__MODULE__{}
  
  @spec spawn(non_neg_integer(), term(), map()) :: t()
  def spawn(epoch, niche, traits) do
    identity = EvolutionaryIdentity.root(:law_species, :species, epoch, traits)
    LineageRegistry.register(identity)
    %__MODULE__{
      identity: identity,
      niche_specialization: niche,
      ancestor_lineage: Map.get(traits, :ancestor_lineage, []),
      defining_fragments: Map.get(traits, :defining_fragments, []),
      constitutional_profile: Map.get(traits, :constitutional_profile, %{}),
      pathology_profile: Map.get(traits, :pathology_profile, []),
      attractor_affinity: Map.get(traits, :attractor_affinity, :none),
      emergent_properties: Map.get(traits, :emergent_properties, []),
      adaptive_capacity: Map.get(traits, :adaptive_capacity, 0.0),
      universes: [],
      peak_fitness: 0.0
    }
  end

  @impl true
  def evolutionary_level, do: :law_species
  
  @impl true
  def identity(%__MODULE__{identity: id}), do: id
  
  @impl true
  def niche(%__MODULE__{niche_specialization: n}), do: n
  
  @impl true
  def fitness(%__MODULE__{} = species, environment) do
    base = species.adaptive_capacity
    diversity_bonus = length(species.emergent_properties) * 0.1
    base + diversity_bonus + Map.get(environment.resources, :table_coverage_bonus, 0.0)
  end
  
  @impl true
  def mutate(%__MODULE__{} = species, _environment) do
    new_identity = EvolutionaryIdentity.descend(species.identity, current_epoch())
    LineageRegistry.register(new_identity)
    drift = fn v -> v * (1 + (:rand.uniform() - 0.5) * 0.1) end
    %{species |
      identity: new_identity,
      adaptive_capacity: drift.(species.adaptive_capacity)
    }
  end
  
  @impl true
  def recombine(%__MODULE__{} = primary, partners, _environment) do
    new_identity = EvolutionaryIdentity.recombine(
      [primary.identity | Enum.map(partners, & &1.identity)],
      current_epoch()
    )
    LineageRegistry.register(new_identity)
    
    n = length(partners) + 1
    avg = fn field ->
      Enum.map([primary | partners], &Map.get(&1, field, 0)) |> Enum.sum() |> Kernel./(n)
    end
    
    all_fragments = Enum.flat_map([primary | partners], & &1.defining_fragments) |> Enum.uniq()
    all_emergent = Enum.flat_map([primary | partners], & &1.emergent_properties) |> Enum.uniq()
    
    %__MODULE__{
      identity: new_identity,
      niche_specialization: primary.niche_specialization,
      defining_fragments: all_fragments,
      emergent_properties: all_emergent,
      adaptive_capacity: avg.(:adaptive_capacity),
      ancestor_lineage: primary.ancestor_lineage,
      constitutional_profile: primary.constitutional_profile,
      pathology_profile: primary.pathology_profile,
      attractor_affinity: primary.attractor_affinity,
      universes: [],
      peak_fitness: 0.0
    }
  end
  
  @impl true
  def extinct?(%__MODULE__{} = species, environment) do
    species.adaptive_capacity < Map.get(environment.pressures, :minimum_viability, 0.1) or
    length(species.pathology_profile) > 5
  end
  
  @impl true
  def archive(%__MODULE__{} = species, opts) do
    env = Keyword.get(opts, :environment, %EvolutionaryEnvironment{})
    frozen_identity = LineageRegistry.mark_extinct(species.identity.id, current_epoch())
    current_fit = fitness(species, env)
    
    EvolutionaryRuin.from_organism(species, frozen_identity, [
      peak_fitness: max(species.peak_fitness || 0.0, current_fit),
      terminal_fitness: current_fit,
      collapse_reason: Keyword.get(opts, :reason, :fitness_collapse),
      pressure_vector: Keyword.get(opts, :pressure_vector, %{}),
      epoch: current_epoch(),
      trait_fossil: %{
        surviving_laws: length(species.universes),
        complexity: length(species.emergent_properties),
        adaptive_capacity: species.adaptive_capacity
      }
    ])
  end

  # --- Causal Signaling ---
  
  @impl true
  def emit_signals(%__MODULE__{identity: identity} = species) do
    epoch = current_epoch()
    alias Tiannara.REA.Causal.Signal
    [
      Signal.emit(:symmetry_stability, species.adaptive_capacity, identity, :law_species, epoch),
      Signal.emit(:perturbation_survival, 1.0 / (1.0 + length(species.pathology_profile)), identity, :law_species, epoch),
      Signal.emit(:diversity_index, length(species.emergent_properties) * 0.1, identity, :law_species, epoch)
    ]
  end

  @impl true
  def receive_pressure(%__MODULE__{} = species, pressure) do
    # Innovation from Civilization, coherence from Epistemology, diversity floor from MetaGenome
    innovation_rate = Map.get(pressure, :innovation_rate, 0.0)
    stability_pressure = Map.get(pressure, :symmetry_stability, 0.0)
    diversity_floor = Map.get(pressure, :diversity_index, 0.0)
    
    # We mutate adaptive_capacity based on these
    new_capacity = species.adaptive_capacity * (1.0 + 0.1 * stability_pressure) + 0.05 * innovation_rate
    new_capacity = max(new_capacity, diversity_floor)
    
    %{species | adaptive_capacity: clamp(new_capacity, 0.0, 1.0)}
  end

  defp current_epoch do
    DateTime.utc_now()
  end
  
  defp clamp(v, lo, hi), do: v |> max(lo) |> min(hi)
end
