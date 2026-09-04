defmodule Tiannara.SOPL.MetaGenome do
  @moduledoc """
  SOPL-5: MetaGenome, retrofitted to the REA contract.
  """
  @behaviour Tiannara.REA.EvolutionaryOrganism
  
  alias Tiannara.REA.{EvolutionaryIdentity, EvolutionaryRuin, LineageRegistry, EvolutionaryEnvironment}
  
  defstruct [
    :identity,
    :niche,
    :mutation_strategy,
    :selection_strategy,
    :recombination_strategy,
    :speciation_strategy,
    :pressure_strategy,
    causal_genome: nil,
    last_eval_fitness: 0.0,
    peak_fitness: 0.0
  ]
  
  @type t :: %__MODULE__{}
  
  @spec spawn(non_neg_integer(), term(), map()) :: t()
  def spawn(epoch, niche, traits) do
    identity = EvolutionaryIdentity.root(:meta_genome, :meta_law, epoch, traits)
    LineageRegistry.register(identity)
    %__MODULE__{
      identity: identity,
      niche: niche,
      mutation_strategy: Map.get(traits, :mutation_strategy, %{
        base_radius: 0.1,
        tier_2_probability: 0.5,
        tier_3_probability: 0.0
      }),
      selection_strategy: Map.get(traits, :selection_strategy, %{
        fitness_weight: 0.4,
        potential_weight: 0.2,
        outlier_weight: 0.2,
        ruin_weight: 0.2
      }),
      recombination_strategy: Map.get(traits, :recombination_strategy, %{
        compatibility_strictness: 0.9,
        max_fragments_per_law: 5
      }),
      speciation_strategy: Map.get(traits, :speciation_strategy, %{
        divergence_threshold: 0.15,
        required_longevity: 100
      }),
      pressure_strategy: Map.get(traits, :pressure_strategy, %{
        predator_intensity: 0.5,
        disease_intensity: 0.5,
        scarcity_profile: :moderate,
        extinction_threshold: 0.8
      }),
      causal_genome: Tiannara.REA.Topo.CausalGenome.random(),
      last_eval_fitness: 0.0,
      peak_fitness: 0.0
    }
  end

  @impl true
  def evolutionary_level, do: :meta_genome
  
  @impl true
  def identity(%__MODULE__{identity: id}), do: id
  
  @impl true
  def niche(%__MODULE__{niche: n}), do: n
  
  @impl true
  def fitness(%__MODULE__{} = meta, environment) do
    overhead_penalty = Map.get(environment.pressures, :meta_overhead, 0.0)
    max(0.0, meta.last_eval_fitness - overhead_penalty)
  end
  
  @impl true
  def mutate(%__MODULE__{} = meta, environment) do
    new_identity = EvolutionaryIdentity.descend(meta.identity, current_epoch())
    LineageRegistry.register(new_identity)
    drift = fn v -> v * (1 + (:rand.uniform() - 0.5) * 0.1) end
    
    p_strat = %{meta.pressure_strategy | 
      predator_intensity: drift.(meta.pressure_strategy.predator_intensity),
      disease_intensity: drift.(meta.pressure_strategy.disease_intensity)
    }
    
    {new_causal, _muts} = if meta.causal_genome do
      Tiannara.REA.Topo.CausalMutator.mutate(meta.causal_genome, environment)
    else
      {Tiannara.REA.Topo.CausalGenome.random(), []}
    end
    
    %{meta |
      identity: new_identity,
      pressure_strategy: p_strat,
      causal_genome: new_causal
    }
  end
  
  @impl true
  def recombine(%__MODULE__{} = primary, partners, _environment) do
    new_identity = EvolutionaryIdentity.recombine(
      [primary.identity | Enum.map(partners, & &1.identity)],
      current_epoch()
    )
    LineageRegistry.register(new_identity)
    
    p2 = hd(partners)
    
    %__MODULE__{
      identity: new_identity,
      niche: primary.niche,
      mutation_strategy: primary.mutation_strategy,
      selection_strategy: primary.selection_strategy,
      recombination_strategy: p2.recombination_strategy,
      speciation_strategy: p2.speciation_strategy,
      pressure_strategy: primary.pressure_strategy,
      causal_genome: primary.causal_genome,
      last_eval_fitness: 0.0,
      peak_fitness: 0.0
    }
  end
  
  @impl true
  def extinct?(%__MODULE__{} = meta, environment) do
    meta.last_eval_fitness < Map.get(environment.pressures, :minimum_meta_viability, 0.2)
  end
  
  @impl true
  def archive(%__MODULE__{} = meta, opts) do
    env = Keyword.get(opts, :environment, %EvolutionaryEnvironment{})
    frozen_identity = LineageRegistry.mark_extinct(meta.identity.id, current_epoch())
    current_fit = fitness(meta, env)
    
    EvolutionaryRuin.from_organism(meta, frozen_identity, [
      peak_fitness: max(meta.peak_fitness || 0.0, current_fit),
      terminal_fitness: current_fit,
      collapse_reason: Keyword.get(opts, :reason, :fitness_collapse),
      pressure_vector: Keyword.get(opts, :pressure_vector, %{}),
      epoch: current_epoch(),
      trait_fossil: %{
        strategy_snapshot: %{
          mutation: meta.mutation_strategy,
          selection: meta.selection_strategy,
          pressure: meta.pressure_strategy
        },
        achieved_meta_fitness: meta.last_eval_fitness,
        epoch: current_epoch()
      }
    ])
  end

  # --- Causal Signaling ---
  
  @impl true
  def emit_signals(%__MODULE__{identity: identity} = meta) do
    epoch = current_epoch()
    alias Tiannara.REA.Causal.Signal
    
    # MetaGenome emits signals based on its achieved fitness and diversity strategies
    diversity = if meta.speciation_strategy.divergence_threshold < 0.2, do: 0.8, else: 0.2
    innovation = if meta.mutation_strategy.tier_3_probability > 0.0, do: 0.9, else: 0.1
    
    [
      Signal.emit(:resilience, meta.last_eval_fitness, identity, :meta_genome, epoch),
      Signal.emit(:diversity_index, diversity, identity, :meta_genome, epoch),
      Signal.emit(:innovation_rate, innovation, identity, :meta_genome, epoch)
    ]
  end

  @impl true
  def receive_pressure(%__MODULE__{} = meta, pressure) do
    # Resilience pressure from Civilizations makes selection stricter
    resilience_pressure = Map.get(pressure, :resilience, 0.0)
    # Innovation pressure from Epistemology makes mutation wider
    innovation_pressure = Map.get(pressure, :innovation_rate, 0.0)
    
    new_selection = %{meta.selection_strategy | ruin_weight: clamp(meta.selection_strategy.ruin_weight + (0.1 * resilience_pressure), 0.0, 1.0)}
    new_mutation = %{meta.mutation_strategy | base_radius: clamp(meta.mutation_strategy.base_radius + (0.05 * innovation_pressure), 0.0, 1.0)}
    
    %{meta |
      selection_strategy: new_selection,
      mutation_strategy: new_mutation
    }
  end

  defp current_epoch do
    DateTime.utc_now()
  end
  
  defp clamp(v, lo, hi), do: v |> max(lo) |> min(hi)
end
