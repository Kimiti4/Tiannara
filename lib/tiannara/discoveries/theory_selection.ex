defmodule Tiannara.REA.TheorySelection do
  @moduledoc """
  Core engine for Phase 11.16 (Theory Selection Physics).
  Establishes persistence, replicator sweeps, and selection metrics for theory tensors.
  """

  alias Tiannara.REA.TheoryTensor
  alias Tiannara.REA.DomainCrucible

  @theory_file_path "data/theory_species.ndjson"

  @doc """
  Loads the theory population archive from NDJSON file. Falls back to default theories if missing.
  """
  def load_theories do
    if File.exists?(@theory_file_path) do
      File.read!(@theory_file_path)
      |> String.split("\n", trim: true)
      |> Enum.map(&Jason.decode!/1)
      |> Enum.map(&deserialize_theory/1)
    else
      theories = default_theories()
      save_theories(theories)
      theories
    end
  end

  @doc """
  Saves the theory population archive to NDJSON file.
  """
  def save_theories(theories_list) do
    # Ensure data directory exists
    File.mkdir_p!(Path.dirname(@theory_file_path))

    content =
      theories_list
      |> Enum.map(&Jason.encode!/1)
      |> Enum.join("\n")

    File.write!(@theory_file_path, content <> "\n")
  end

  @doc """
  Runs evolutionary selection sweeps over a series of generations.
  Updates populations based on fitness relative to the population mean.
  """
  def run_theory_selection_sweep(population, generations \\ 10, volatility \\ 0.0, complexity \\ 0.0) do
    Enum.reduce(1..generations, {population, []}, fn gen_idx, {pop_acc, trace_acc} ->
      # 1. Calculate base fitness for each theory depending on environmental coordinate
      with_base_fit =
        Enum.map(pop_acc, fn t ->
          base_fit = calculate_fitness(t, volatility, complexity)
          
          # Apply environmental volatility as noise
          noise = if volatility > 0.0, do: (rem(:erlang.phash2({t.theory_id, gen_idx}), 200) / 100.0 - 1.0) * volatility * 0.1, else: 0.0
          effective_fit = max(0.01, min(0.99, base_fit + noise))
          {t, effective_fit}
        end)

      # 2. Compute mean fitness of the population
      total_pop = Enum.sum(Enum.map(pop_acc, & &1.population))
      avg_fitness =
        if total_pop > 0 do
          Enum.sum(Enum.map(with_base_fit, fn {t, fit} -> fit * t.population end)) / total_pop
        else
          0.50
        end

      # 3. Update populations using replicator dynamics
      updated_pop =
        Enum.map(with_base_fit, fn {t, fit} ->
          growth_factor =
            if avg_fitness > 0.0 do
              1.0 + 0.3 * (fit - avg_fitness)
            else
              1.0
            end

          new_pop = round(t.population * growth_factor)
          # Extinction threshold: if population drops below 5, it goes to 0
          final_pop = if new_pop < 5, do: 0, else: new_pop

          # Increment lifetime if population survived
          new_lifetime = if final_pop > 0, do: (t.lifetime || 0) + 1, else: (t.lifetime || 0)

          # Recalculate extinction risk
          extinction_risk =
            cond do
              final_pop == 0 -> 1.0
              final_pop < 20 -> 0.85
              true -> Float.round(max(0.01, 1.0 - (final_pop / 300.0)), 4)
            end

          %{t |
            population: final_pop,
            lifetime: new_lifetime,
            extinction_risk: extinction_risk
          }
        end)

      # Log sweep events
      events = detect_sweep_events(pop_acc, updated_pop)

      trace_step = %{
        generation: gen_idx,
        populations: Map.new(updated_pop, & {&1.theory_id, &1.population}),
        events: events
      }

      {updated_pop, trace_acc ++ [trace_step]}
    end)
    |> then(fn {final_pop, trace} ->
      # Calculate secondary metrics at the end of the sweep
      mean_lifetime = Enum.sum(Enum.map(final_pop, & &1.lifetime || 0)) / max(1, length(final_pop))
      
      enriched_pop =
        Enum.map(final_pop, fn t ->
          cdr = calculate_cdr(t)
          rt = calculate_reproduction_rate(t, final_pop)
          tli = if mean_lifetime > 0, do: Float.round((t.lifetime || 0) / mean_lifetime, 4), else: 1.0

          %{t |
            cross_domain_resilience: cdr,
            reproduction_rate: rt,
            longevity_index: tli
          }
        end)

      {enriched_pop, trace}
    end)
  end

  # Determine fitness dynamically based on geometric parameters
  def calculate_fitness(t, volatility, complexity) do
    cond do
      volatility >= 0.50 ->
        # Volatile Environment: Transferability dominates
        0.55 * t.transferability + 0.25 * t.convergence_score + 0.20 * t.predictive_power
      complexity >= 0.60 ->
        # Complex Environment: Compression dominates (normalized to 0..1 scale)
        norm_compression = min(1.0, t.compression_ratio / 6.0)
        0.50 * norm_compression + 0.30 * t.predictive_power + 0.20 * t.transferability
      volatility < 0.20 and complexity < 0.30 ->
        # Stable Environment: Predictive Power dominates
        0.60 * t.predictive_power + 0.25 * t.survivability + 0.15 * t.transferability
      true ->
        # Mixed Environment: Convergence dominates
        0.50 * t.convergence_score + 0.30 * t.transferability + 0.20 * t.predictive_power
    end
  end

  def calculate_cdr(theory) do
    domains = DomainCrucible.all_domains()
    successes =
      Enum.count(domains, fn d ->
        validated = DomainCrucible.validate_theory(theory, d)
        validated.failure_history == theory.failure_history
      end)
    Float.round(successes / length(domains), 4)
  end

  def calculate_reproduction_rate(theory, population) do
    descendants = Enum.count(population, fn t -> theory.theory_id in (t.parent_theories || []) end)
    gen = theory.generation || 1
    Float.round(descendants / max(1.0, gen * 1.0), 4)
  end

  def default_theories do
    DomainCrucible.baseline_theories()
    |> Enum.map(fn t ->
      %{t |
        extinction_risk: 0.10,
        reproduction_rate: 0.0,
        cross_domain_resilience: 0.50,
        lifetime: 1,
        longevity_index: 1.0
      }
    end)
  end

  defp deserialize_theory(map) do
    relations =
      Map.get(map, "relations", [])
      |> Enum.map(fn r ->
        relation_map =
          Map.new(r, fn
            {"confidence", v} -> {:confidence, v}
            {k, v} when is_binary(v) -> {String.to_atom(k), String.to_existing_atom(v)}
            {k, v} -> {String.to_atom(k), v}
          end)
        struct(Tiannara.REA.TheoryRelation, relation_map)
      end)

    t = struct(TheoryTensor, Map.new(map, fn {k, v} -> {String.to_atom(k), v} end))
    %{t | relations: relations}
  end

  defp detect_sweep_events(old_pop, new_pop) do
    extinctions =
      Enum.flat_map(new_pop, fn ns ->
        os = Enum.find(old_pop, &(&1.theory_id == ns.theory_id))
        if os.population > 0 and ns.population == 0 do
          [%{type: :extinction, theory_id: ns.theory_id, message: "Theory lineage #{ns.theory_id} went extinct."}]
        else
          []
        end
      end)

    total_new_pop = Enum.sum(Enum.map(new_pop, & &1.population))
    dominance =
      if total_new_pop > 0 do
        Enum.flat_map(new_pop, fn ns ->
          ratio = ns.population / total_new_pop
          if ratio >= 0.40 and ns.population >= 100 do
            [%{type: :dominance, theory_id: ns.theory_id, ratio: Float.round(ratio, 4), message: "Theory #{ns.theory_id} dominates with #{Float.round(ratio * 100, 2)}% population share."}]
          else
            []
          end
        end)
      else
        []
      end

    extinctions ++ dominance
  end
end

defmodule Tiannara.REA.TheoryFitnessAnalyzer do
  @moduledoc """
  Ranks Candidate Selection Variables by correlation, p_survival, and hazard ratios.
  """

  @variables [:transferability, :convergence_score, :generativity, :compression_ratio, :predictive_power, :history_depth, :cross_domain_resilience, :reproduction_rate, :lifetime]

  @doc """
  Ranks variables based on correlation to survival. Calculates Hazard Ratios and P_survival.
  """
  def rank_theory_invariants(population, _volatility \\ 0.0, _complexity \\ 0.0) do
    survivals = Enum.map(population, fn t -> 1.0 - t.extinction_risk end)

    rankings =
      Enum.map(@variables, fn var ->
        var_values = Enum.map(population, fn t -> get_variable_value(t, var) end)
        corr = correlation(var_values, survivals)

        median_val = median(var_values)
        high_group = Enum.filter(population, fn t -> get_variable_value(t, var) >= median_val end)
        low_group = Enum.filter(population, fn t -> get_variable_value(t, var) < median_val end)

        # 1. P(Survival | Variable >= Median)
        p_survival =
          if length(high_group) > 0 do
            survivor_count = Enum.count(high_group, fn t -> t.population > 0 end)
            Float.round(survivor_count / length(high_group), 4)
          else
            0.0
          end

        # 2. Hazard Ratio calculation
        extinct_high = Enum.count(high_group, fn t -> t.population == 0 end)
        extinct_low = Enum.count(low_group, fn t -> t.population == 0 end)

        hazard_high = if length(high_group) > 0, do: extinct_high / length(high_group), else: 0.0
        hazard_low = if length(low_group) > 0, do: extinct_low / length(low_group), else: 0.0

        hazard_ratio =
          cond do
            hazard_high == 0.0 and hazard_low == 0.0 -> 1.0
            true -> Float.round(hazard_high / max(0.01, hazard_low), 4)
          end

        %{
          variable: var,
          correlation: corr,
          p_survival: p_survival,
          hazard_ratio: hazard_ratio
        }
      end)
      |> Enum.sort_by(& &1.correlation, :desc)

    rankings
  end

  defp get_variable_value(t, :history_depth) do
    length(t.validation_history || []) + length(t.adaptation_history || [])
  end
  defp get_variable_value(t, var) do
    Map.get(t, var) || 0.0
  end

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

defmodule Tiannara.REA.TheoryRadiation do
  @moduledoc """
  Detects adaptive radiation branching in theory lineages.
  """

  def detect_theory_radiation(population) do
    # Group by parents
    by_parent =
      Enum.flat_map(population, fn t ->
        Enum.map(t.parent_theories || [], fn p -> {p, t} end)
      end)
      |> Enum.group_by(fn {p, _t} -> p end, fn {_p, t} -> t end)

    radiations =
      Enum.flat_map(by_parent, fn {parent_id, children} ->
        if length(children) >= 2 do
          div_score = calculate_divergence_score(children)
          [%{
            parent_theory: parent_id,
            children: Enum.map(children, & &1.theory_id),
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

  defp calculate_divergence_score(theories) do
    traits = [:transferability, :convergence_score, :generativity, :compression_ratio, :predictive_power]
    n = length(theories)

    std_devs =
      Enum.map(traits, fn trait ->
        vals = Enum.map(theories, & Map.get(&1, trait) || 0.0)
        mean = Enum.sum(vals) / n
        variance = Enum.map(vals, &:math.pow(&1 - mean, 2)) |> Enum.sum() |> Kernel./(n)
        :math.sqrt(variance)
      end)

    Enum.sum(std_devs) / length(traits)
  end
end

defmodule Tiannara.REA.TheoryNiches do
  @moduledoc """
  Categorizes theories into adaptive ecological niches.
  """

  use Tiannara.Stub, subsystem: :rea, phase: "Omega+", priority: :high

  def classify_theories(args) do
    stub_result(:classify_theories, [args], {:ok, []})
  end

  def classify_niches(population) do
    universal = Enum.filter(population, fn t -> (t.convergence_score || 0.0) >= 0.70 or (t.cross_domain_resilience || 0.0) >= 0.75 end)
    domain_specific = Enum.filter(population, fn t -> (t.cross_domain_resilience || 0.0) > 0.0 and (t.cross_domain_resilience || 0.0) < 0.75 end)
    refuted = Enum.filter(population, fn t -> t.population <= 0 end)
    endangered = Enum.filter(population, fn t -> t.population > 0 and (t.population < 30 or (t.extinction_risk || 0.0) >= 0.50) end)

    %{
      universal: universal,
      domain_specific: domain_specific,
      refuted: refuted,
      endangered: endangered
    }
  end
end
