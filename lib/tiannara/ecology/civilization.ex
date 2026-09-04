defmodule Tiannara.Ecology.Civilization do
  @moduledoc """
  Civilizational organism, retrofitted to the REA contract.
  
  The internal struct retains its domain-specific fields
  (economy, truth_stock, compute, etc.). The REA integration
  is additive, not replacement.
  """
  @behaviour Tiannara.REA.EvolutionaryOrganism
  
  alias Tiannara.REA.{EvolutionaryIdentity, EvolutionaryRuin, LineageRegistry, EvolutionaryEnvironment}
  
  @domains [
    :engineering, :medicine, :governance, :computation,
    :agriculture, :energy, :logistics, :cognition, :materials,
    :robotics, :economics, :philosophy, :sociology, :linguistics,
    :aerospace, :ecology, :cybernetics, :architecture, :physics,
    :chemistry
  ]

  defstruct [
    :identity,
    :niche,
    :economy,
    :truth_stock,
    :compute_capacity,
    :cohesion,
    :memory_depth,
    :domain_aptitudes,
    :domain_entropy,
    :monoculture_index,
    peak_fitness: 0.0
  ]
  
  @type t :: %__MODULE__{}
  
  @doc "Get the list of the 20 primary capability domains."
  def domains, do: @domains
  
  @doc "Spawn a new root civilization."
  @spec spawn(non_neg_integer(), map(), map()) :: t()
  def spawn(epoch, niche, traits) do
    identity = EvolutionaryIdentity.root(:civilization, :individual, epoch, traits)
    LineageRegistry.register(identity)
    
    aptitudes = Map.new(@domains, fn d -> {d, 0.1} end)
    
    %__MODULE__{
      identity: identity,
      niche: niche,
      economy: 0.0,
      truth_stock: 0.0,
      compute_capacity: 0.0,
      cohesion: 1.0,
      memory_depth: 0,
      domain_aptitudes: aptitudes,
      domain_entropy: Tiannara.Metrics.DomainAnalytics.calculate_entropy(aptitudes),
      monoculture_index: Tiannara.Metrics.DomainAnalytics.calculate_monoculture_index(aptitudes),
      peak_fitness: 0.0
    }
  end
  
  # --- Contract Implementation ---
  
  @impl true
  def evolutionary_level, do: :civilization
  
  @impl true
  def identity(%__MODULE__{identity: id}), do: id
  
  @impl true
  def niche(%__MODULE__{niche: n}), do: n
  
  @impl true
  def fitness(%__MODULE__{} = civ, environment) do
    weights = Map.get(civ.niche, :fitness_weights, default_weights())
    axes = %{
      economy: civ.economy / max(Map.get(environment.resources, :resource_ceiling, 100.0), 1.0),
      truth: civ.truth_stock,
      compute: civ.compute_capacity / max(Map.get(environment.resources, :compute_ceiling, 100.0), 1.0),
      cohesion: civ.cohesion,
      memory: civ.memory_depth / 100.0
    }
    Enum.reduce(weights, 0.0, fn {axis, w}, acc ->
      acc + w * Map.get(axes, axis, 0.0)
    end)
  end
  
  @impl true
  def mutate(%__MODULE__{} = civ, environment) do
    new_identity = EvolutionaryIdentity.descend(civ.identity, current_epoch())
    LineageRegistry.register(new_identity)
    
    # Base structural drift
    drift = fn v -> v * (1 + (:rand.uniform() - 0.5) * 0.1) end
    
    # Domain aptitude drift influenced by world specialization bias
    bias_map = Map.get(environment, :specialization_bias, %{})
    mutated_domains = Map.new(civ.domain_aptitudes, fn {domain, val} ->
      bias = Map.get(bias_map, domain, 1.0)
      # Higher bias -> positive drift tendency; lower bias -> neutral/negative drift
      domain_drift = (:rand.uniform() - 0.4) * 0.05 * bias
      {domain, clamp(val + domain_drift, 0.0, 100.0)}
    end)
    
    %{civ |
      identity: new_identity,
      economy: drift.(civ.economy),
      truth_stock: drift.(civ.truth_stock),
      compute_capacity: drift.(civ.compute_capacity),
      domain_aptitudes: mutated_domains,
      domain_entropy: Tiannara.Metrics.DomainAnalytics.calculate_entropy(mutated_domains),
      monoculture_index: Tiannara.Metrics.DomainAnalytics.calculate_monoculture_index(mutated_domains)
    }
  end
  
  @impl true
  def recombine(%__MODULE__{} = primary, partners, _environment) do
    new_identity = EvolutionaryIdentity.recombine(
      [primary.identity | Enum.map(partners, & &1.identity)],
      current_epoch()
    )
    LineageRegistry.register(new_identity)
    blended = blend_civs([primary | partners])
    %{blended | identity: new_identity}
  end
  
  @impl true
  def extinct?(%__MODULE__{} = civ, environment) do
    civ.cohesion < 0.05 or
    civ.economy < Map.get(environment.pressures, :minimum_viability, -1.0) or
    civ.truth_stock < 0.0
  end
  
  @impl true
  def archive(%__MODULE__{} = civ, opts) do
    # Fallback to empty environment for final check if needed
    env = Keyword.get(opts, :environment, %EvolutionaryEnvironment{})
    frozen_identity = LineageRegistry.mark_extinct(civ.identity.id, current_epoch())
    current_fit = fitness(civ, env)
    
    EvolutionaryRuin.from_organism(civ, frozen_identity, [
      peak_fitness: max(civ.peak_fitness || 0.0, current_fit),
      terminal_fitness: current_fit,
      collapse_reason: Keyword.get(opts, :reason, :stagnation),
      pressure_vector: Keyword.get(opts, :pressure_vector, %{}),
      epoch: current_epoch(),
      trait_fossil: %{
        economy: civ.economy,
        truth_stock: civ.truth_stock,
        compute_capacity: civ.compute_capacity,
        cohesion: civ.cohesion,
        memory_depth: civ.memory_depth
      }
    ])
  end
  
  @impl true
  def descendants(%__MODULE__{identity: id}) do
    LineageRegistry.descendants(id.id) |> Enum.map(& &1.id)
  end
  
  # --- Causal Signaling ---
  
  @impl true
  def emit_signals(%__MODULE__{identity: identity} = civ) do
    epoch = current_epoch()
    alias Tiannara.REA.Causal.Signal
    
    # Emit thresholded weighted domain vector (replaces Top-3)
    weighted_signals =
      civ.domain_aptitudes
      |> Enum.filter(fn {_domain, aptitude} -> aptitude >= 0.05 end)
      |> Enum.map(fn {domain, val} ->
        Signal.emit(:"domain_#{domain}", val, identity, :civilization, epoch)
      end)

    base_signals = [
      Signal.emit(:truth_retention, civ.truth_stock, identity, :civilization, epoch),
      Signal.emit(:compute_capacity, civ.compute_capacity, identity, :civilization, epoch),
      Signal.emit(:economic_output, civ.economy, identity, :civilization, epoch),
      Signal.emit(:cohesion, civ.cohesion, identity, :civilization, epoch),
      Signal.emit(:domain_entropy, civ.domain_entropy, identity, :civilization, epoch),
      Signal.emit(:monoculture_index, civ.monoculture_index, identity, :civilization, epoch)
    ]
    
    base_signals ++ weighted_signals
  end

  @impl true
  def receive_pressure(%__MODULE__{} = civ, pressure) do
    stability_pressure = Map.get(pressure, :symmetry_stability, 0.0)
    growth_bonus = Map.get(pressure, :cognitive_yield, 0.0)
    adaptation_pressure = Map.get(pressure, :innovation_rate, 0.0)
    
    %{civ |
      cohesion: clamp(civ.cohesion * (1.0 + 0.1 * stability_pressure), 0.0, 1.0),
      truth_stock: civ.truth_stock * (1.0 + 0.05 * growth_bonus),
      memory_depth: civ.memory_depth + trunc(10 * adaptation_pressure)
    }
  end

  # --- Helpers ---
  
  defp default_weights, do: %{economy: 0.3, truth: 0.25, compute: 0.2, cohesion: 0.15, memory: 0.1}
  
  defp blend_civs(civs) do
    n = length(civs)
    avg = fn field ->
      Enum.map(civs, &Map.get(&1, field, 0)) |> Enum.sum() |> Kernel./(n)
    end
    
    blended_domains = Enum.reduce(@domains, %{}, fn domain, acc ->
      avg_aptitude = Enum.map(civs, &Map.get(&1.domain_aptitudes, domain, 0.1)) |> Enum.sum() |> Kernel./(n)
      Map.put(acc, domain, avg_aptitude)
    end)

    %__MODULE__{
      economy: avg.(:economy),
      truth_stock: avg.(:truth_stock),
      compute_capacity: avg.(:compute_capacity),
      cohesion: avg.(:cohesion),
      memory_depth: avg.(:memory_depth),
      domain_aptitudes: blended_domains,
      domain_entropy: Tiannara.Metrics.DomainAnalytics.calculate_entropy(blended_domains),
      monoculture_index: Tiannara.Metrics.DomainAnalytics.calculate_monoculture_index(blended_domains),
      niche: hd(civs).niche
    }
  end
  
  defp current_epoch do
    DateTime.utc_now()
  end
  
  defp clamp(v, lo, hi), do: v |> max(lo) |> min(hi)
end
