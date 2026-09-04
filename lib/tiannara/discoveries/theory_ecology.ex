defmodule Tiannara.REA.TheoryRelation do
  @derive Jason.Encoder
  defstruct [
    :lhs,          # e.g., :functor_retention | :mpp | :optionality | :history | :generalists
    :operator,     # e.g., :dominates | :outperforms | :equals | :exceeds | :is_causal_variable
    :rhs,          # e.g., :mpp | :correctness | :specialists | :state | :state_alone
    :context,      # e.g., :high_volatility | :high_complexity | :low_volatility | :all
    :confidence    # float (0.0 to 1.0)
  ]
end

defmodule Tiannara.REA.TheoryTensor do
  @derive Jason.Encoder
  defstruct [
    :theory_id,             # string (e.g. "theory_alpha_v7")
    :parent_theories,       # list of strings (parent IDs)
    :generation,            # integer (e.g. 7)
    :species_id,            # string/atom (e.g. "adaptation_species_gamma")
    :relations,             # list of %Tiannara.REA.TheoryRelation{}
    :origin_phase,          # atom (e.g., :orbit_selection_physics)
    :supporting_discoveries,# list of atoms (e.g., [:orbit_memory_ecology, :orbit_selection_physics, :meta_memory_physics])
    
    # Theory metrics
    :predictive_power,      # float (0.0 to 1.0)
    :transferability,       # float (0.0 to 1.0)
    :compression_ratio,     # float
    :survivability,         # float (0.0 to 1.0)
    :generativity,          # float (0.0 to 1.0)
    :convergence_score,     # float (0.0 to 1.0)
    :population,            # integer (number of active worlds adopting this theory)
    
    # Theory Memory
    :validation_history,    # list of maps: %{domain: atom, result: :success | :failure | :partial}
    :failure_history,       # list of maps: %{domain: atom, reason: string}
    :adaptation_history,    # list of maps: %{generation: integer, event: string}
    
    :domains_discovered,    # list of strings
    
    # Selection Physics metrics
    :extinction_risk,          # float (0.0 to 1.0)
    :reproduction_rate,        # float
    :cross_domain_resilience,  # float (0.0 to 1.0)
    :lifetime,                 # integer
    :longevity_index           # float
  ]
end

defmodule Tiannara.REA.TheoryEcology do
  @moduledoc """
  Ecosystem selection and evolutionary sweeps over structured relational theories.
  """

  alias Tiannara.REA.TheoryTensor

  @doc """
  Runs selection sweep on theories using dynamically computed Operational Fitness.
  """
  def run_theory_selection(theories, generations \\ 10, volatility \\ 0.0) do
    Enum.reduce(1..generations, {theories, []}, fn gen_idx, {pop_acc, trace_acc} ->
      # Calculate Operational Fitness dynamically for each theory
      # Operational fitness depends on mpp, transferability, and survivability
      with_fitness =
        Enum.map(pop_acc, fn t ->
          # Volatility adds noise to execution outcomes
          noise = if volatility > 0.0, do: (:rand.uniform() * 2.0 - 1.0) * volatility, else: 0.0
          op_fitness = Float.round(max(0.01, min(0.99, 0.40 * t.predictive_power + 0.35 * t.transferability + 0.25 * t.survivability + noise)), 4)
          {t, op_fitness}
        end)

      total_pop = Enum.sum(Enum.map(pop_acc, & &1.population))
      avg_op_fitness =
        if total_pop > 0 do
          Enum.sum(Enum.map(with_fitness, fn {t, fit} -> fit * t.population end)) / total_pop
        else
          0.50
        end

      # Update populations using replicator dynamics
      updated_pop =
        Enum.map(with_fitness, fn {t, fit} ->
          growth_factor =
            if avg_op_fitness > 0.0 do
              1.0 + 0.25 * (fit - avg_op_fitness)
            else
              1.0
            end

          new_pop = round(t.population * growth_factor)
          final_pop = if new_pop < 2, do: 0, else: new_pop

          # Record adaptation history if population shifts significantly
          history =
            cond do
              final_pop == 0 and t.population > 0 ->
                t.adaptation_history ++ [%{generation: gen_idx, event: "Theory went extinct"}]
              final_pop > t.population * 1.5 ->
                t.adaptation_history ++ [%{generation: gen_idx, event: "Lineage population surged"}]
              true ->
                t.adaptation_history
            end

          # Update survivability based on whether population is maintained
          survivability = Float.round(max(0.01, min(0.99, t.survivability + (final_pop - t.population) / 1000.0)), 4)

          %{t |
            population: final_pop,
            survivability: survivability,
            adaptation_history: history
          }
        end)

      trace_step = %{
        generation: gen_idx,
        populations: Map.new(updated_pop, & {&1.theory_id, &1.population})
      }

      {updated_pop, trace_acc ++ [trace_step]}
    end)
  end

  @doc """
  Selection Analysis: Pearson correlation coefficient to discover what predicts survival.
  """
  def rank_theory_predictors(population) do
    survivals = Enum.map(population, fn t -> t.population / 200.0 end)
    variables = [:predictive_power, :transferability, :compression_ratio, :convergence_score, :generativity]

    rankings =
      Enum.map(variables, fn var ->
        var_values = Enum.map(population, fn t -> Map.get(t, var) end)
        corr = correlation(var_values, survivals)

        %{
          variable: var,
          correlation: corr
        }
      end)
      |> Enum.sort_by(& &1.correlation, :desc)

    rankings
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
end

defmodule Tiannara.REA.TheoryMutator do
  @moduledoc """
  Performs genetic mutation and recombination of Theory relations to construct child genomes.
  """

  alias Tiannara.REA.TheoryTensor
  alias Tiannara.REA.TheoryRelation

  @doc """
  Mutates single relation attributes or parameters.
  """
  def mutate(%TheoryTensor{} = theory) do
    mutated_relations =
      Enum.map(theory.relations, fn rel ->
        if :rand.uniform() > 0.7 do
          # Mutate logic operator
          new_op = Enum.random([:dominates, :outperforms, :equals, :exceeds])
          %{rel | operator: new_op, confidence: Float.round(min(1.0, max(0.0, rel.confidence + (:rand.uniform() * 0.2 - 0.1))), 4)}
        else
          rel
        end
      end)

    %{theory |
      theory_id: theory.theory_id <> "_mut",
      relations: mutated_relations,
      adaptation_history: theory.adaptation_history ++ [%{generation: theory.generation + 1, event: "Mutation occurred"}]
    }
  end

  @doc """
  Recombines logic relations from Parent A and Parent B to build descendant genomes.
  """
  def recombine(%TheoryTensor{} = parent_a, %TheoryTensor{} = parent_b) do
    # Take a blend of clauses from both parents
    clauses_a = parent_a.relations
    clauses_b = parent_b.relations

    child_relations =
      (Enum.take_random(clauses_a, div(length(clauses_a), 2) + 1) ++
       Enum.take_random(clauses_b, div(length(clauses_b), 2) + 1))
      |> Enum.uniq_by(fn r -> {r.lhs, r.operator, r.rhs, r.context} end)

    child_gen = max(parent_a.generation, parent_b.generation) + 1

    %TheoryTensor{
      theory_id: "theory_recomb_#{:rand.uniform(10000)}",
      parent_theories: [parent_a.theory_id, parent_b.theory_id],
      generation: child_gen,
      species_id: parent_a.species_id, # inherits parent A family grouping
      relations: child_relations,
      origin_phase: :theory_ecology,
      supporting_discoveries: Enum.uniq(parent_a.supporting_discoveries ++ parent_b.supporting_discoveries),
      
      # Child derives blended starting metrics
      predictive_power: Float.round((parent_a.predictive_power + parent_b.predictive_power) / 2.0, 4),
      transferability: Float.round((parent_a.transferability + parent_b.transferability) / 2.0, 4),
      compression_ratio: Float.round((parent_a.compression_ratio + parent_b.compression_ratio) / 2.0, 2),
      survivability: Float.round((parent_a.survivability + parent_b.survivability) / 2.0, 4),
      generativity: Float.round(min(0.99, max(parent_a.generativity, parent_b.generativity) + 0.05), 4),
      convergence_score: 0.0,
      population: 50,
      
      # Inherit blended history
      validation_history: Enum.uniq_by(parent_a.validation_history ++ parent_b.validation_history, & &1.domain),
      failure_history: Enum.uniq_by(parent_a.failure_history ++ parent_b.failure_history, & &1.domain),
      adaptation_history: [%{generation: child_gen, event: "Recombined from #{parent_a.theory_id} and #{parent_b.theory_id}"}],
      domains_discovered: []
    }
  end
end

defmodule Tiannara.REA.DomainCrucible do
  @moduledoc """
  Crucible system validating theories and running parallel domain laboratories to evaluate convergence.
  """

  alias Tiannara.REA.TheoryTensor
  alias Tiannara.REA.TheoryRelation

  @domains [
    :economics, :energy, :climate, :healthcare, :education, 
    :supply_chains, :security, :governance, :metabolism, :agriculture, 
    :transportation, :communication, :manufacturing, :demographics, :technology, 
    :finance, :geopolitics, :ecology, :informatics, :cybernetics
  ]

  def all_domains, do: @domains

  @doc """
  Runs validation for a theory against a single domain.
  Evaluates logic relations in the context of the domain profile.
  """
  def validate_theory(%TheoryTensor{} = theory, domain) do
    # Deterministic domain parameters
    seed = :erlang.phash2(domain)
    volatility = rem(seed, 100) / 100.0
    _complexity = rem(seed, 200) / 200.0

    # A theory fails/gets refuted if it has specialized relations that conflict with domain parameters
    refutations =
      Enum.flat_map(theory.relations || [], fn rel ->
        cond do
          rel.context == :high_volatility and volatility < 0.30 and rel.lhs == :functor_retention ->
            [%{domain: domain, reason: "Functor retention dominates fails in low-volatility domain."}]
          rel.context == :low_volatility and volatility >= 0.35 and rel.lhs == :mpp ->
            [%{domain: domain, reason: "Local mpp predictive power fails under high environmental volatility."}]
          true ->
            []
        end
      end)

    if refutations == [] do
      # Success validation
      updated_val = [%{domain: domain, result: :success} | theory.validation_history || []] |> Enum.uniq_by(& &1.domain)
      
      %{theory |
        validation_history: updated_val,
        survivability: Float.round(min(0.99, theory.survivability + 0.02), 4)
      }
    else
      # Failure refutation
      updated_fail = ((theory.failure_history || []) ++ refutations) |> Enum.uniq_by(& &1.domain)
      updated_val = [%{domain: domain, result: :failure} | theory.validation_history || []] |> Enum.uniq_by(& &1.domain)
      
      %{theory |
        failure_history: updated_fail,
        validation_history: updated_val,
        survivability: Float.round(max(0.01, theory.survivability - 0.10), 4)
      }
    end
  end

  @doc """
  Independently evolves theories in parallel domain laboratories.
  """
  def evolve_theories_in_domain(domain, generations) do
    seed = :erlang.phash2(domain)
    volatility = rem(seed, 100) / 100.0
    complexity = rem(seed, 200) / 200.0

    # Initial candidate theories
    candidates = baseline_theories()

    # Apply genetic selection inside the domain parameters for the given generations
    Enum.reduce(1..generations, candidates, fn gen_idx, acc ->
      # Score candidates
      scored =
        Enum.map(acc, fn t ->
          score = evaluate_theory_fit(t, volatility, complexity)
          {t, score}
        end)

      # Sort and survive top 50%
      sorted = Enum.sort_by(scored, &elem(&1, 1), :desc)
      survivors = Enum.take(sorted, 3) |> Enum.map(&elem(&1, 0))

      # Mutate and reproduce
      children =
        Enum.map(survivors, fn parent ->
          # Slight mutation
          mutated = Tiannara.REA.TheoryMutator.mutate(parent)
          
          # Mark discovery provenance
          %{mutated |
            generation: gen_idx,
            domains_discovered: Enum.uniq([to_string(domain) | parent.domains_discovered])
          }
        end)

      survivors ++ children
    end)
  end

  @doc """
  Measures independent convergence (H3) across evolved domain outputs.
  """
  def measure_convergence(domain_theory_maps) do
    # Group all evolved theories by base theory statements
    all_evolved = List.flatten(Map.values(domain_theory_maps))

    # Match based on relations structure similarity
    Enum.reduce(all_evolved, [], fn t, acc ->
      existing_idx =
        Enum.find_index(acc, fn existing ->
          relations_match?(t.relations, existing.relations)
        end)

      if existing_idx do
        List.update_at(acc, existing_idx, fn existing ->
          updated_domains = Enum.uniq(existing.domains_discovered ++ t.domains_discovered)
          # Convergence score is ratio of independent domains discovered
          conv_score = Float.round(length(updated_domains) / length(@domains), 4)

          %{existing |
            domains_discovered: updated_domains,
            convergence_score: conv_score,
            population: existing.population + 15
          }
        end)
      else
        conv_score = Float.round(length(t.domains_discovered) / length(@domains), 4)
        acc ++ [%{t | convergence_score: conv_score, population: 40}]
      end
    end)
  end

  # Helpers
  defp evaluate_theory_fit(theory, volatility, complexity) do
    # Score based on how correct the relations are for the volatility/complexity context
    fit_scores =
      Enum.map(theory.relations, fn rel ->
        cond do
          rel.context == :high_volatility and volatility >= 0.25 and rel.lhs == :functor_retention -> 0.90
          rel.context == :low_volatility and volatility < 0.25 and rel.lhs == :mpp -> 0.85
          rel.context == :high_complexity and complexity >= 0.60 and rel.lhs == :specialists -> 0.80
          rel.context == :all -> 0.70
          true -> 0.30
        end
      end)

    if fit_scores == [], do: 0.10, else: Enum.sum(fit_scores) / length(fit_scores)
  end

  defp relations_match?(rel_a, rel_b) do
    # Match if they share key relations
    keys_a = Enum.map(rel_a, fn r -> {r.lhs, r.operator, r.rhs} end) |> MapSet.new()
    keys_b = Enum.map(rel_b, fn r -> {r.lhs, r.operator, r.rhs} end) |> MapSet.new()

    MapSet.intersection(keys_a, keys_b) |> MapSet.size() > 0
  end

  def baseline_theories do
    [
      %TheoryTensor{
        theory_id: "theory_alpha",
        parent_theories: [],
        generation: 1,
        species_id: "transferability_family",
        relations: [
          %TheoryRelation{lhs: :functor_retention, operator: :dominates, rhs: :mpp, context: :high_volatility, confidence: 0.88}
        ],
        origin_phase: :orbit_selection_physics,
        supporting_discoveries: [:orbit_selection_physics],
        predictive_power: 0.75,
        transferability: 0.92,
        compression_ratio: 3.5,
        survivability: 0.85,
        generativity: 0.60,
        convergence_score: 0.10,
        population: 120,
        validation_history: [],
        failure_history: [],
        adaptation_history: [%{generation: 1, event: "Discovered in Selection Physics"}],
        domains_discovered: ["energy", "climate"]
      },
      %TheoryTensor{
        theory_id: "theory_beta",
        parent_theories: [],
        generation: 1,
        species_id: "optionality_family",
        relations: [
          %TheoryRelation{lhs: :generalists, operator: :outperforms, rhs: :specialists, context: :high_volatility, confidence: 0.82}
        ],
        origin_phase: :meta_memory_physics,
        supporting_discoveries: [:meta_memory_physics],
        predictive_power: 0.68,
        transferability: 0.85,
        compression_ratio: 2.8,
        survivability: 0.78,
        generativity: 0.50,
        convergence_score: 0.05,
        population: 80,
        validation_history: [],
        failure_history: [],
        adaptation_history: [%{generation: 1, event: "Discovered in Meta-Memory"}],
        domains_discovered: ["governance"]
      },
      %TheoryTensor{
        theory_id: "theory_gamma",
        parent_theories: [],
        generation: 1,
        species_id: "memory_family",
        relations: [
          %TheoryRelation{lhs: :memory, operator: :is_causal_variable, rhs: :state, context: :all, confidence: 0.90}
        ],
        origin_phase: :orbit_memory_ecology,
        supporting_discoveries: [:orbit_memory_ecology, :meta_memory_physics],
        predictive_power: 0.82,
        transferability: 0.75,
        compression_ratio: 4.1,
        survivability: 0.88,
        generativity: 0.75,
        convergence_score: 0.15,
        population: 100,
        validation_history: [],
        failure_history: [],
        adaptation_history: [%{generation: 1, event: "Discovered in Ecology"}],
        domains_discovered: ["economics", "finance"]
      },
      %TheoryTensor{
        theory_id: "theory_delta",
        parent_theories: [],
        generation: 1,
        species_id: "history_family",
        relations: [
          %TheoryRelation{lhs: :history, operator: :exceeds, rhs: :state_alone, context: :all, confidence: 0.86}
        ],
        origin_phase: :orbit_genesis,
        supporting_discoveries: [:orbit_genesis, :orbit_memory_ecology],
        predictive_power: 0.85,
        transferability: 0.80,
        compression_ratio: 5.2,
        survivability: 0.92,
        generativity: 0.80,
        convergence_score: 0.20,
        population: 150,
        validation_history: [],
        failure_history: [],
        adaptation_history: [%{generation: 1, event: "Discovered in Orbit Genesis"}],
        domains_discovered: ["technology", "informatics"]
      }
    ]
  end
end
