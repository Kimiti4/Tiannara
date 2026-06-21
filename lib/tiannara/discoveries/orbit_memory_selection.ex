defmodule Tiannara.REA.OrbitMemorySelection do
  @moduledoc """
  Core engine for Phase 11.13 (Orbit Memory Selection Physics).
  Establishes the scientific framework for understanding lineage survival, selection sweeps,
  extinction events, and dominance curves in memetic memory ecology.
  """

  @species_file_path "data/orbit_memory_species.ndjson"

  @doc """
  Loads the species archive from NDJSON file. Falls back to default species if missing.
  """
  def load_species do
    if File.exists?(@species_file_path) do
      File.read!(@species_file_path)
      |> String.split("\n", trim: true)
      |> Enum.map(&Jason.decode!/1)
      |> Enum.map(&normalize_keys/1)
    else
      default_species()
    end
  end

  @doc """
  Saves the species archive to NDJSON file.
  """
  def save_species(species_list) do
    content =
      species_list
      |> Enum.map(&Jason.encode!/1)
      |> Enum.join("\n")
      
    content = content <> "\n"
    File.write!(@species_file_path, content)
  end

  @doc """
  Runs evolutionary selection sweeps over a series of generations.
  Updates populations based on fitness relative to the population mean.
  """
  def run_selection_sweep(population, generations \\ 10, volatility \\ 0.0) do
    Enum.reduce(1..generations, {population, []}, fn gen_idx, {pop_acc, trace_acc} ->
      # Calculate average fitness
      total_pop = Enum.sum(Enum.map(pop_acc, & &1.population))
      
      avg_fitness =
        if total_pop > 0 do
          Enum.sum(Enum.map(pop_acc, fn s -> s.fitness * s.population end)) / total_pop
        else
          0.0
        end

      # Update populations using replicator dynamics
      updated_pop =
        Enum.map(pop_acc, fn s ->
          # Apply environmental volatility as random pertubation to fitness
          effective_fitness = 
            if volatility > 0.0 do
              # Deteministic pseudo-randomness based on species id and generation
              seed = :erlang.phash2({s.species_id, gen_idx})
              noise = (rem(seed, 200) / 100.0 - 1.0) * volatility
              max(0.01, min(0.99, s.fitness + noise))
            else
              s.fitness
            end

          growth_factor = 
            if avg_fitness > 0.0 do
              1.0 + 0.3 * (effective_fitness - avg_fitness)
            else
              1.0
            end

          new_pop = round(s.population * growth_factor)
          # Extinction threshold: if population drops below 5, it goes to 0
          final_pop = if new_pop < 5, do: 0, else: new_pop

          # Recalculate extinction risk
          extinction_risk = 
            cond do
              final_pop == 0 -> 1.0
              final_pop < 20 -> 0.85
              true -> Float.round(max(0.01, 1.0 - (final_pop / 300.0)), 4)
            end

          %{s | population: final_pop, extinction_risk: extinction_risk}
        end)

      # Log Events
      events = detect_sweep_events(pop_acc, updated_pop)

      trace_step = %{
        generation: gen_idx,
        populations: Map.new(updated_pop, & {&1.species_id, &1.population}),
        events: events
      }

      {updated_pop, trace_acc ++ [trace_step]}
    end)
  end

  # Helpers
  defp normalize_keys(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), v} end)
  end

  defp detect_sweep_events(old_pop, new_pop) do
    extinctions =
      Enum.flat_map(new_pop, fn ns ->
        os = Enum.find(old_pop, &(&1.species_id == ns.species_id))
        if os.population > 0 and ns.population == 0 do
          [%{type: :extinction, species_id: ns.species_id, message: "Lineage #{ns.species_id} went extinct."}]
        else
          []
        end
      end)

    # Determine dominant species
    total_new_pop = Enum.sum(Enum.map(new_pop, & &1.population))
    dominance =
      if total_new_pop > 0 do
        Enum.flat_map(new_pop, fn ns ->
          ratio = ns.population / total_new_pop
          if ratio >= 0.40 and ns.population >= 100 do
            [%{type: :dominance, species_id: ns.species_id, ratio: Float.round(ratio, 4), message: "Lineage #{ns.species_id} dominates with #{Float.round(ratio * 100, 2)}% of the population."}]
          else
            []
          end
        end)
      else
        []
      end

    # Growth and decline events
    trends =
      Enum.flat_map(new_pop, fn ns ->
        os = Enum.find(old_pop, &(&1.species_id == ns.species_id))
        cond do
          os.population > 0 and ns.population / os.population >= 1.15 ->
            [%{type: :growth, species_id: ns.species_id, message: "Lineage #{ns.species_id} grew by #{Float.round((ns.population/os.population - 1.0) * 100, 2)}%."}]
          os.population > 0 and ns.population / os.population <= 0.85 ->
            [%{type: :decline, species_id: ns.species_id, message: "Lineage #{ns.species_id} declined by #{Float.round((1.0 - ns.population/os.population) * 100, 2)}%."}]
          true ->
            []
        end
      end)

    extinctions ++ dominance ++ trends
  end

  def default_species do
    [
      %{species_id: "stability_species_root", parent_species: nil, population: 250, fitness: 0.75, mpp: 0.60, mes: 0.70, functor_retention: 0.70, compression_ratio: 2.5, inheritance_stability: 0.85, domain_coverage: 3, mutation_recovery: 0.50, extinction_risk: 0.10},
      %{species_id: "stability_species_alpha", parent_species: "stability_species_root", population: 125, fitness: 0.82, mpp: 0.74, mes: 0.80, functor_retention: 0.68, compression_ratio: 3.1, inheritance_stability: 0.92, domain_coverage: 4, mutation_recovery: 0.61, extinction_risk: 0.17},
      %{species_id: "recovery_species_beta", parent_species: "stability_species_root", population: 80, fitness: 0.72, mpp: 0.65, mes: 0.70, functor_retention: 0.55, compression_ratio: 2.8, inheritance_stability: 0.85, domain_coverage: 3, mutation_recovery: 0.82, extinction_risk: 0.25},
      %{species_id: "phoenix_species_gamma", parent_species: "stability_species_root", population: 45, fitness: 0.58, mpp: 0.50, mes: 0.60, functor_retention: 0.78, compression_ratio: 4.2, inheritance_stability: 0.70, domain_coverage: 5, mutation_recovery: 0.40, extinction_risk: 0.45},
      %{species_id: "collapse_species_omega", parent_species: "stability_species_root", population: 12, fitness: 0.18, mpp: 0.20, mes: 0.15, functor_retention: 0.30, compression_ratio: 1.5, inheritance_stability: 0.40, domain_coverage: 1, mutation_recovery: 0.15, extinction_risk: 0.92},
      %{species_id: "specialist_species_sigma", parent_species: "stability_species_alpha", population: 90, fitness: 0.79, mpp: 0.85, mes: 0.65, functor_retention: 0.45, compression_ratio: 5.5, inheritance_stability: 0.88, domain_coverage: 2, mutation_recovery: 0.75, extinction_risk: 0.12},
      %{species_id: "generalist_species_upsilon", parent_species: "stability_species_root", population: 150, fitness: 0.85, mpp: 0.70, mes: 0.85, functor_retention: 0.88, compression_ratio: 2.5, inheritance_stability: 0.95, domain_coverage: 6, mutation_recovery: 0.55, extinction_risk: 0.05}
    ]
  end
end

defmodule Tiannara.REA.OrbitMemoryFitnessAnalyzer do
  @moduledoc """
  Ranks Candidate Selection Variables by their predictive correlation with lineage survival and dominance.
  """

  @variables [:mpp, :functor_retention, :compression_ratio, :inheritance_stability, :domain_coverage, :mutation_recovery]

  @doc """
  Ranks fitness variables based on their correlation with survival (1.0 - extinction_risk).
  """
  def rank_fitness_invariants(population) do
    survivals = Enum.map(population, fn s -> 1.0 - s.extinction_risk end)

    rankings =
      Enum.map(@variables, fn var ->
        var_values = Enum.map(population, fn s -> Map.get(s, var) end)
        corr = correlation(var_values, survivals)

        # Compute P(Survival | Variable > Median)
        median_val = median(var_values)
        high_group = Enum.filter(population, fn s -> Map.get(s, var) >= median_val end)
        
        p_survival =
          if length(high_group) > 0 do
            survivor_count = Enum.count(high_group, fn s -> s.population > 20 and s.extinction_risk < 0.5 end)
            Float.round(survivor_count / length(high_group), 4)
          else
            0.0
          end

        %{
          variable: var,
          correlation: corr,
          p_survival: p_survival
        }
      end)
      |> Enum.sort_by(& &1.correlation, :desc)

    rankings
  end

  # Helper functions
  defp correlation(xs, ys) do
    n = length(xs)
    if n > 1 do
      mean_x = Enum.sum(xs) / n
      mean_y = Enum.sum(ys) / n

      numerator =
        Enum.zip(xs, ys)
        |> Enum.map(fn {x, y} -> (x - mean_x) * (y - mean_y) end)
        |> Enum.sum()

      var_x = Enum.map(xs, fn x -> :math.pow(x - mean_x, 2) end) |> Enum.sum()
      var_y = Enum.map(ys, fn y -> :math.pow(y - mean_y, 2) end) |> Enum.sum()

      denominator = :math.sqrt(var_x * var_y)
      if denominator > 0.0, do: Float.round(numerator / denominator, 4), else: 0.0
    else
      0.0
    end
  end

  defp median([]), do: 0.0
  defp median(list) do
    sorted = Enum.sort(list)
    len = length(sorted)
    if rem(len, 2) == 1 do
      Enum.at(sorted, div(len, 2))
    else
      (Enum.at(sorted, div(len, 2) - 1) + Enum.at(sorted, div(len, 2))) / 2.0
    end
  end
end

defmodule Tiannara.REA.OrbitMemoryRadiation do
  @moduledoc """
  Detects adaptive radiation, lineage splitting, and ecological niche divergence.
  """

  @doc """
  Identifies parent species with multiple children and measures trait divergence scores.
  """
  def detect_adaptive_radiation(population) do
    # Group species by parent
    by_parent = Enum.group_by(population, & &1.parent_species) |> Map.delete(nil)

    radiations =
      Enum.flat_map(by_parent, fn {parent_id, children} ->
        if length(children) >= 2 do
          # Calculate trait divergence as average standard deviation of candidate variables
          div_score = calculate_divergence_score(children)

          [%{
            parent_species: parent_id,
            children: Enum.map(children, & &1.species_id),
            divergence_score: Float.round(div_score, 4)
          }]
        else
          []
        end
      end)

    %{
      radiations: radiations,
      radiation_events_count: length(radiations)
    }
  end

  defp calculate_divergence_score(species_list) do
    traits = [:mpp, :functor_retention, :compression_ratio, :inheritance_stability, :domain_coverage, :mutation_recovery]
    n = length(species_list)

    std_devs =
      Enum.map(traits, fn trait ->
        vals = Enum.map(species_list, & Map.get(&1, trait))
        mean = Enum.sum(vals) / n
        variance = Enum.map(vals, &:math.pow(&1 - mean, 2)) |> Enum.sum() |> Kernel./(n)
        :math.sqrt(variance)
      end)

    Enum.sum(std_devs) / length(traits)
  end
end

defmodule Tiannara.REA.OrbitMemoryNiches do
  @moduledoc """
  Classifies population elements into ecological niches (generalists, specialists, dominant, extinct, endangered).
  """

  @doc """
  Sorts species into generalists, specialists, dominant, extinct, and endangered categories.
  """
  def classify_niches(population) do
    generalists = Enum.filter(population, fn s -> s.domain_coverage >= 4 and s.functor_retention >= 0.65 end)
    specialists = Enum.filter(population, fn s -> s.domain_coverage < 4 and (s.compression_ratio >= 3.0 or s.mpp >= 0.70) end)
    dominant = Enum.filter(population, fn s -> s.population >= 100 and s.fitness >= 0.75 end)
    extinct = Enum.filter(population, fn s -> s.population <= 0 end)
    endangered = Enum.filter(population, fn s -> s.population > 0 and (s.population < 30 or s.extinction_risk >= 0.50) end)

    %{
      generalists: generalists,
      specialists: specialists,
      dominant: dominant,
      extinct: extinct,
      endangered: endangered
    }
  end
end
