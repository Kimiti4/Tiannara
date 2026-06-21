defmodule Tiannara.ASC.MetaScience.ProgramEvolutionEngine do
  @moduledoc """
  Phase 7: Meta-Science.
  Applies evolutionary pressure to research genomes themselves.
  
  High fitness genomes reproduce (crossover).
  Medium fitness genomes mutate.
  Low fitness genomes go extinct.
  Novel offspring that are sufficiently different become new species.
  """
  
  alias Tiannara.ASC.MetaScience.ResearchGenome
  require Logger

  @extinction_starvation_threshold 3  # Epochs of near-zero output before extinction
  @speciation_distance_threshold 0.4  # How different a genome must be to be a new species
  @min_population 2
  @max_population 12

  @doc """
  Evolves the population of research genomes based on their fitness.
  Returns the new population.
  """
  def evolve_population(genomes) do
    active = Enum.filter(genomes, & &1.status == :active)
    
    Logger.info("🧬 [EvolutionEngine] Evolving population of #{length(active)} active genomes...")
    
    # 1. Extinction: kill starving genomes
    survivors = Enum.filter(active, fn genome -> 
      should_survive?(genome)
    end)
    
    extinct_count = length(active) - length(survivors)
    if extinct_count > 0 do
      Logger.warning("💀 [EvolutionEngine] #{extinct_count} genome(s) went EXTINCT.")
    end
    
    # 2. Reproduction: high-fitness genomes produce offspring
    offspring = reproduce(survivors)
    
    # 3. Mutation: medium-fitness genomes produce variants
    mutants = mutate_medium_fitness(survivors)
    
    # 4. Combine and enforce population limits
    new_population = (survivors ++ offspring ++ mutants)
    |> Enum.sort_by(& &1.fitness, :desc)
    |> Enum.take(@max_population)
    
    # 5. Ensure minimum population (seed if necessary)
    new_population = ensure_minimum_population(new_population)
    
    # 6. Age all survivors
    new_population = Enum.map(new_population, fn g ->
      %{g | epochs_alive: g.epochs_alive + 1}
    end)
    
    Logger.info("🧬 [EvolutionEngine] New population: #{length(new_population)} genomes")
    new_population
  end

  # --- Extinction ---

  defp should_survive?(genome) do
    cond do
      genome.epochs_starving >= @extinction_starvation_threshold ->
        Logger.info("  💀 EXTINCT: '#{genome.name}' (starved for #{genome.epochs_starving} epochs)")
        false
      genome.fitness <= 0 and genome.epochs_alive > 3 ->
        Logger.info("  💀 EXTINCT: '#{genome.name}' (zero fitness after #{genome.epochs_alive} epochs)")
        false
      true ->
        true
    end
  end

  # --- Reproduction (Crossover) ---

  defp reproduce(genomes) when length(genomes) < 2, do: []
  defp reproduce(genomes) do
    # Select top 50% as parents
    parents = genomes 
    |> Enum.sort_by(& &1.fitness, :desc) 
    |> Enum.take(max(2, trunc(length(genomes) * 0.5)))
    
    # Generate offspring from parent pairs
    Enum.reduce(parents, [], fn parent_a, acc ->
      parent_b = Enum.random(parents -- [parent_a])
      if parent_b do
        child = crossover(parent_a, parent_b)
        [child | acc]
      else
        acc
      end
    end)
    |> Enum.uniq_by(& &1.id)
  end

  defp crossover(%ResearchGenome{} = parent_a, %ResearchGenome{} = parent_b) do
    child_id = "genome_hybrid_#{:erlang.unique_integer([:positive])}"
    
    # Blend domain weights (weighted average by parent fitness)
    total_fitness = parent_a.fitness + parent_b.fitness + 0.001
    a_weight = parent_a.fitness / total_fitness
    b_weight = parent_b.fitness / total_fitness
    
    blended_domains = blend_maps(parent_a.domain_weights, parent_b.domain_weights, a_weight, b_weight)
    blended_methods = blend_maps(parent_a.methodology_blend, parent_b.methodology_blend, a_weight, b_weight)
    
    # Normalize to sum to 1.0
    blended_domains = normalize_map(blended_domains)
    blended_methods = normalize_map(blended_methods)
    
    child = %ResearchGenome{
      id: child_id,
      name: generate_hybrid_name(parent_a.name, parent_b.name),
      generation: max(parent_a.generation, parent_b.generation) + 1,
      lineage: [parent_a.id, parent_b.id],
      domain_weights: blended_domains,
      methodology_blend: blended_methods,
      exploration_bias: (parent_a.exploration_bias + parent_b.exploration_bias) / 2,
      exploitation_bias: (parent_a.exploitation_bias + parent_b.exploitation_bias) / 2,
      compute_efficiency: trunc((parent_a.compute_efficiency + parent_b.compute_efficiency) / 2),
      risk_tolerance: (parent_a.risk_tolerance + parent_b.risk_tolerance) / 2,
      mutation_rate: max(parent_a.mutation_rate, parent_b.mutation_rate),
      fitness: 0.0,
      epochs_alive: 0,
      epochs_starving: 0,
      total_utility_generated: 0.0,
      total_compute_consumed: 0,
      status: :active,
      created_at: System.system_time(:millisecond)
    }
    
    # Speciation check: is this child sufficiently different from all existing genomes?
    if is_novel_species?(child, [parent_a, parent_b]) do
      Logger.info("  🌟 SPECIATION: '#{child.name}' is a novel species!")
    else
      Logger.info("  👶 OFFSPRING: '#{child.name}' (Gen #{child.generation})")
    end
    
    child
  end

  # --- Mutation ---

  defp mutate_medium_fitness(genomes) do
    genomes
    |> Enum.filter(fn g -> g.fitness > 0 end)
    |> Enum.flat_map(fn genome ->
      if :rand.uniform() < genome.mutation_rate do
        [mutate_genome(genome)]
      else
        []
      end
    end)
  end

  defp mutate_genome(%ResearchGenome{} = parent) do
    mutant_id = "genome_mutant_#{:erlang.unique_integer([:positive])}"
    
    # Perturb domain weights
    mutated_domains = parent.domain_weights
    |> Enum.map(fn {k, v} -> {k, max(0.0, v + (:rand.uniform() - 0.5) * 0.2)} end)
    |> normalize_map()
    
    # Perturb methodology blend
    mutated_methods = parent.methodology_blend
    |> Enum.map(fn {k, v} -> {k, max(0.0, v + (:rand.uniform() - 0.5) * 0.2)} end)
    |> normalize_map()
    
    %ResearchGenome{
      parent |
      id: mutant_id,
      name: "#{parent.name} (Mutant)",
      generation: parent.generation + 1,
      lineage: [parent.id],
      domain_weights: mutated_domains,
      methodology_blend: mutated_methods,
      exploration_bias: clamp(parent.exploration_bias + (:rand.uniform() - 0.5) * 0.1),
      exploitation_bias: clamp(parent.exploitation_bias + (:rand.uniform() - 0.5) * 0.1),
      risk_tolerance: clamp(parent.risk_tolerance + (:rand.uniform() - 0.5) * 0.1),
      mutation_rate: clamp(parent.mutation_rate + (:rand.uniform() - 0.5) * 0.05),
      fitness: 0.0,
      epochs_alive: 0,
      epochs_starving: 0,
      status: :active,
      created_at: System.system_time(:millisecond)
    }
  end

  # --- Speciation Detection ---

  defp is_novel_species?(child, existing_genomes) do
    Enum.all?(existing_genomes, fn genome ->
      genetic_distance(child, genome) > @speciation_distance_threshold
    end)
  end

  defp genetic_distance(%ResearchGenome{} = a, %ResearchGenome{} = b) do
    # Euclidean distance between domain weights and methodology blends
    domain_dist = map_distance(a.domain_weights, b.domain_weights)
    method_dist = map_distance(a.methodology_blend, b.methodology_blend)
    param_dist = abs(a.exploration_bias - b.exploration_bias) + abs(a.risk_tolerance - b.risk_tolerance)
    
    (domain_dist + method_dist + param_dist) / 3.0
  end

  defp map_distance(map_a, map_b) do
    all_keys = Map.keys(map_a) ++ Map.keys(map_b) |> Enum.uniq()
    
    all_keys
    |> Enum.map(fn k -> 
      a_val = Map.get(map_a, k, 0.0)
      b_val = Map.get(map_b, k, 0.0)
      (a_val - b_val) * (a_val - b_val)
    end)
    |> Enum.sum()
    |> :math.sqrt()
  end

  # --- Population Management ---

  defp ensure_minimum_population(population) when length(population) >= @min_population, do: population
  defp ensure_minimum_population(population) do
    needed = @min_population - length(population)
    seeds = Enum.map(1..needed, fn i ->
      domain = Enum.random([:transfer_physics, :repair_ecology, :architecture])
      method = Enum.random([:targeted_experimentation, :brute_force_mutation, :meta_learning])
      ResearchGenome.seed("Emergency Seed #{i}", domain, method)
    end)
    population ++ seeds
  end

  # --- Helpers ---

  defp blend_maps(map_a, map_b, weight_a, weight_b) do
    all_keys = Map.keys(map_a) ++ Map.keys(map_b) |> Enum.uniq()
    
    Enum.map(all_keys, fn k ->
      a_val = Map.get(map_a, k, 0.0)
      b_val = Map.get(map_b, k, 0.0)
      {k, a_val * weight_a + b_val * weight_b}
    end)
    |> Map.new()
  end

  defp normalize_map(map) do
    total = Enum.reduce(map, 0, fn {_k, v}, acc -> acc + v end)
    if total > 0 do
      Enum.map(map, fn {k, v} -> {k, v / total} end) |> Map.new()
    else
      map
    end
  end

  defp clamp(val, min \\ 0.0, max \\ 1.0), do: max(min, min(val, max))

  defp generate_hybrid_name(name_a, name_b) do
    parts_a = String.split(name_a, " ")
    parts_b = String.split(name_b, " ")
    
    a_prefix = List.first(parts_a) || "Hybrid"
    b_suffix = List.last(parts_b) || "Program"
    
    "Hybrid #{a_prefix}-#{b_suffix}"
  end
end
