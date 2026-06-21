defmodule Tiannara.ASC.MetaScience.ResearchGenome do
  @moduledoc """
  Phase 7: The DNA of a research methodology.
  
  A genome encodes HOW a research program approaches discovery:
  - Which domains it prioritizes
  - Which methodologies it blends
  - How it balances exploration vs exploitation
  - How volatile its own parameters are
  
  Genomes can crossover, mutate, speciate, and go extinct.
  """
  
  defstruct [
    :id,
    :name,
    :generation,
    :lineage,           # [parent_a_id, parent_b_id] or [mutated_from_id]
    
    # Domain Affinity: What the program studies
    # %{transfer_physics: 0.6, repair_ecology: 0.3, architecture: 0.1}
    domain_weights: %{},
    
    # Methodology Blend: How the program approaches discovery
    # %{targeted_experimentation: 0.4, brute_force_mutation: 0.5, meta_learning: 0.1}
    methodology_blend: %{},
    
    # Strategic Parameters
    exploration_bias: 0.5,     # 0.0 = pure exploitation, 1.0 = pure exploration
    exploitation_bias: 0.5,    # 1.0 - exploration_bias for tracking convenience
    compute_efficiency: 10,    # Baseline compute cost per experiment
    risk_tolerance: 0.3,       # Willingness to pursue low-probability high-reward experiments
    
    # Evolutionary Parameters
    mutation_rate: 0.10,       # How volatile this genome's offspring are
    
    # Fitness Tracking
    fitness: 0.0,
    epochs_alive: 0,
    epochs_starving: 0,        # Consecutive epochs with near-zero output
    total_utility_generated: 0.0,
    total_compute_consumed: 0,
    
    # Lifecycle
    status: :active,           # :active, :dormant, :extinct
    created_at: nil
  ]

  @type t :: %__MODULE__{}

  @doc """
  Creates a seed genome for a specific pure methodology.
  """
  def seed(name, domain, methodology) do
    %__MODULE__{
      id: "genome_#{name |> String.downcase() |> String.replace(" ", "_")}_#{:erlang.unique_integer([:positive])}",
      name: name,
      generation: 0,
      lineage: [:seed],
      domain_weights: %{domain => 1.0},
      methodology_blend: %{methodology => 1.0},
      exploration_bias: 0.5,
      exploitation_bias: 0.5,
      compute_efficiency: baseline_cost(methodology),
      risk_tolerance: 0.3,
      mutation_rate: 0.10,
      fitness: 0.0,
      epochs_alive: 0,
      epochs_starving: 0,
      total_utility_generated: 0.0,
      total_compute_consumed: 0,
      status: :active,
      created_at: System.system_time(:millisecond)
    }
  end

  defp baseline_cost(:targeted_experimentation), do: 10
  defp baseline_cost(:brute_force_mutation), do: 5
  defp baseline_cost(:meta_learning), do: 20
  defp baseline_cost(:hybrid), do: 12
  defp baseline_cost(_), do: 10
end
