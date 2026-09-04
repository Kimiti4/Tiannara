defmodule Tiannara.Sentinel.D2.EpistemologySpecies do
  @moduledoc """
  EpistemologySpecies organism, retrofitted to the REA contract.
  """
  @behaviour Tiannara.REA.EvolutionaryOrganism
  
  alias Tiannara.REA.{EvolutionaryIdentity, EvolutionaryRuin, LineageRegistry, EvolutionaryEnvironment}
  
  defstruct [
    :identity,
    :niche,
    :operator_set,
    :cognitive_yield,
    :coherence,
    :adaptability,
    peak_fitness: 0.0
  ]
  
  @type t :: %__MODULE__{}
  
  @spec spawn(non_neg_integer(), term(), map()) :: t()
  def spawn(epoch, niche, traits) do
    identity = EvolutionaryIdentity.root(:epistemology, :species, epoch, traits)
    LineageRegistry.register(identity)
    %__MODULE__{
      identity: identity,
      niche: niche,
      operator_set: Map.get(traits, :operator_set, []),
      cognitive_yield: 0.0,
      coherence: 1.0,
      adaptability: 1.0,
      peak_fitness: 0.0
    }
  end

  @impl true
  def evolutionary_level, do: :epistemology
  
  @impl true
  def identity(%__MODULE__{identity: id}), do: id
  
  @impl true
  def niche(%__MODULE__{niche: n}), do: n
  
  @impl true
  def fitness(%__MODULE__{} = epi, environment) do
    base_yield = epi.cognitive_yield
    coherence = epi.coherence
    acm_pressure = Map.get(environment.pressures, :acm, 0.5)
    
    (base_yield * 0.4) + (coherence * 0.4) + (epi.adaptability * acm_pressure * 0.2)
  end
  
  @impl true
  def mutate(%__MODULE__{} = epi, _environment) do
    new_identity = EvolutionaryIdentity.descend(epi.identity, current_epoch())
    LineageRegistry.register(new_identity)
    drift = fn v -> v * (1 + (:rand.uniform() - 0.5) * 0.1) end
    %{epi |
      identity: new_identity,
      cognitive_yield: drift.(epi.cognitive_yield),
      coherence: drift.(epi.coherence)
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
    
    all_ops = Enum.flat_map([primary | partners], & &1.operator_set) |> Enum.uniq()
    
    %__MODULE__{
      identity: new_identity,
      niche: primary.niche,
      operator_set: all_ops,
      cognitive_yield: avg.(:cognitive_yield),
      coherence: avg.(:coherence),
      adaptability: avg.(:adaptability),
      peak_fitness: 0.0
    }
  end
  
  @impl true
  def extinct?(%__MODULE__{} = epi, environment) do
    epi.coherence < 0.1 or
    epi.cognitive_yield < Map.get(environment.pressures, :minimum_yield, 0.0)
  end
  
  @impl true
  def archive(%__MODULE__{} = epi, opts) do
    env = Keyword.get(opts, :environment, %EvolutionaryEnvironment{})
    frozen_identity = LineageRegistry.mark_extinct(epi.identity.id, current_epoch())
    current_fit = fitness(epi, env)
    
    EvolutionaryRuin.from_organism(epi, frozen_identity, [
      peak_fitness: max(epi.peak_fitness || 0.0, current_fit),
      terminal_fitness: current_fit,
      collapse_reason: Keyword.get(opts, :reason, :internal_contradiction),
      pressure_vector: Keyword.get(opts, :pressure_vector, %{}),
      epoch: current_epoch(),
      trait_fossil: %{
        operator_frequencies: length(epi.operator_set),
        yield_history: epi.cognitive_yield,
        coherence_score: epi.coherence
      }
    ])
  end

  # --- Causal Signaling ---
  
  @impl true
  def emit_signals(%__MODULE__{identity: identity} = epi) do
    epoch = current_epoch()
    alias Tiannara.REA.Causal.Signal
    [
      Signal.emit(:cognitive_yield, epi.cognitive_yield, identity, :epistemology, epoch),
      Signal.emit(:coherence, epi.coherence, identity, :epistemology, epoch),
      Signal.emit(:operator_success, (length(epi.operator_set) * epi.cognitive_yield) / 10.0, identity, :epistemology, epoch)
    ]
  end

  @impl true
  def receive_pressure(%__MODULE__{} = epi, pressure) do
    # Stability from below (Civilization) or above (Meta)
    stability = Map.get(pressure, :symmetry_stability, 0.0)
    adaptability = Map.get(pressure, :adaptability, 0.0)
    
    %{epi |
      coherence: clamp(epi.coherence * (1.0 + 0.1 * stability), 0.0, 1.0),
      adaptability: clamp(epi.adaptability * (1.0 + 0.1 * adaptability), 0.0, 1.0)
    }
  end

  defp current_epoch do
    DateTime.utc_now()
  end
  
  defp clamp(v, lo, hi), do: v |> max(lo) |> min(hi)
end
