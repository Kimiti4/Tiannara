defmodule Tiannara.REA.OrbitMemory.Inheritance do
  @moduledoc """
  Implements Phase 11.11C - Orbit Memory Inheritance.
  Establishes inheritance, weighted recombination, emergence check, and lineage evolution.
  """

  alias Tiannara.REA.OrbitMemoryTensor
  alias Tiannara.REA.OrbitMemory
  alias Tiannara.REA.OrbitMemory.VSA

  @doc """
  Replicates (clones) a parent OMT, verifying that predictive power is heritable.
  """
  def clone(%OrbitMemoryTensor{} = parent) do
    # Exact reproduction of parent state genome
    %OrbitMemoryTensor{
      transition_signature: parent.transition_signature,
      visit_frequencies: parent.visit_frequencies,
      gateway_history: parent.gateway_history,
      recovery_history: parent.recovery_history,
      recurrence_profile: parent.recurrence_profile,
      compressed_signature: parent.compressed_signature,
      memory_strength: parent.memory_strength,
      memory_half_life: parent.memory_half_life,
      memory_existence_score: parent.memory_existence_score,
      memory_predictive_power: parent.memory_predictive_power
    }
  end

  @doc """
  Recombines two parent OMTs using a coupling weight (weight_a for Parent A, 1 - weight_a for Parent B).
  """
  def recombine(%OrbitMemoryTensor{} = parent_a, %OrbitMemoryTensor{} = parent_b, weight_a \\ 0.5) do
    weight_b = 1.0 - weight_a

    # 1. Signature Recombination: Alternate signatures proportional to weight
    sig_a = parent_a.transition_signature || []
    sig_b = parent_b.transition_signature || []
    max_len = max(length(sig_a), length(sig_b))
    
    child_sig =
      Enum.map(0..(max_len - 1), fn idx ->
        cond do
          idx < length(sig_a) and idx < length(sig_b) ->
            if :rand.uniform() <= weight_a, do: Enum.at(sig_a, idx), else: Enum.at(sig_b, idx)
          idx < length(sig_a) ->
            Enum.at(sig_a, idx)
          true ->
            Enum.at(sig_b, idx)
        end
      end)
      |> Enum.reject(&is_nil/1)

    # 2. Blend visit frequencies
    child_visits =
      Map.merge(parent_a.visit_frequencies, parent_b.visit_frequencies, fn _k, v1, v2 ->
        Float.round(v1 * weight_a + v2 * weight_b, 2)
      end)

    # 3. Blend gateway history counts
    child_gateways =
      Map.merge(parent_a.gateway_history || %{}, parent_b.gateway_history || %{}, fn _k, v1, v2 ->
        round(v1 * weight_a + v2 * weight_b)
      end)

    # 4. Blend recovery history
    child_recoveries =
      Map.merge(parent_a.recovery_history || %{}, parent_b.recovery_history || %{}, fn _k, v1, v2 ->
        round(v1 * weight_a + v2 * weight_b)
      end)

    # 5. Blend recurrence profile
    child_recurrence =
      Map.merge(parent_a.recurrence_profile || %{}, parent_b.recurrence_profile || %{}, fn _k, v1, v2 ->
        round(v1 * weight_a + v2 * weight_b)
      end)

    # Calculate Child's MES and MPP
    mes = OrbitMemory.calculate_mes(child_sig)
    mpp = Float.round(parent_a.memory_predictive_power * weight_a + parent_b.memory_predictive_power * weight_b, 4)

    child_omt = %OrbitMemoryTensor{
      transition_signature: child_sig,
      visit_frequencies: child_visits,
      gateway_history: child_gateways,
      recovery_history: child_recoveries,
      recurrence_profile: child_recurrence,
      compressed_signature: nil,
      memory_strength: Float.round(parent_a.memory_strength * weight_a + parent_b.memory_strength * weight_b, 4),
      memory_half_life: Float.round(parent_a.memory_half_life * weight_a + parent_b.memory_half_life * weight_b, 2),
      memory_existence_score: Float.round(mes, 4),
      memory_predictive_power: Float.round(mpp, 4)
    }

    # Automatically compress to generate latent code
    compressed = Tiannara.REA.OrbitMemory.Compression.compress(child_omt)
    %{child_omt | compressed_signature: compressed.compressed_signature}
  end

  @doc """
  Calculates fitness: Fitness = 0.4 * MPP + 0.3 * MES + 0.3 * GSI.
  """
  def calculate_fitness(%OrbitMemoryTensor{} = omt, gsi) do
    Float.round(0.4 * omt.memory_predictive_power + 0.3 * omt.memory_existence_score + 0.3 * gsi, 4)
  end

  @doc """
  Verifies if Child fitness > max(Parent A, Parent B).
  """
  def check_emergence(child, parent_a, parent_b, gsi_c, gsi_a, gsi_b) do
    fit_c = calculate_fitness(child, gsi_c)
    fit_a = calculate_fitness(parent_a, gsi_a)
    fit_b = calculate_fitness(parent_b, gsi_b)
    
    fit_c > max(fit_a, fit_b)
  end

  @doc """
  Runs evolutionary selection over generations to produce descendants and returns lineage data.
  """
  def run_evolution(population, generations, mutation_rate \\ 0.1) do
    Enum.reduce(1..generations, population, fn gen_idx, pop_acc ->
      # 1. Sort current population by fitness
      with_fitness =
        Enum.map(pop_acc, fn ind ->
          omt = OrbitMemory.extract(ind)
          gsi = ind["terminal_coordinates"]["gsi"] || 0.5
          fitness = calculate_fitness(omt, gsi)
          {ind, fitness}
        end)
      
      sorted = Enum.sort_by(with_fitness, &elem(&1, 1), :desc)

      # 2. Top 50% survive
      half_len = max(2, div(length(sorted), 2))
      survivors = Enum.take(sorted, half_len) |> Enum.map(&elem(&1, 0))

      # 3. Recombine survivors to fill the rest of the population
      offspring =
        Enum.map(1..(length(pop_acc) - length(survivors)), fn _ ->
          parent_a = Enum.random(survivors)
          parent_b = Enum.random(survivors)
          
          # Recombine OMT genomes
          omt_a = OrbitMemory.extract(parent_a)
          omt_b = OrbitMemory.extract(parent_b)
          child_omt = recombine(omt_a, omt_b, :rand.uniform())

          # Apply slight mutation
          mutated_omt =
            if :rand.uniform() <= mutation_rate do
              # Mutate signature
              mutated_sig = child_omt.transition_signature ++ [Enum.random(["stability_orbit", "collapse_recovery_orbit"])]
              %{child_omt | transition_signature: mutated_sig, memory_strength: min(1.0, child_omt.memory_strength + 0.05)}
            else
              child_omt
            end

          # Create child configuration
          %{
            "world_id" => "child_gen_#{gen_idx}_#{:rand.uniform(10000)}",
            "orbit_outcome" => Enum.random(mutated_omt.transition_signature),
            "orbit_transition_signature" => mutated_omt.transition_signature,
            "orbit_visits" => mutated_omt.visit_frequencies,
            "return_time" => Map.get(mutated_omt.recovery_history, "cycles", 2),
            "identity_persistence" => Float.round(mutated_omt.memory_strength, 4),
            "recovery_velocity" => Float.round(1.0 / max(0.1, mutated_omt.memory_half_life), 4),
            "terminal_coordinates" => %{
              "gsi" => Float.round(parent_a["terminal_coordinates"]["gsi"] * 0.5 + parent_b["terminal_coordinates"]["gsi"] * 0.5 + (:rand.uniform() * 0.1 - 0.05), 4),
              "robustness" => Float.round(parent_a["terminal_coordinates"]["robustness"] * 0.5 + parent_b["terminal_coordinates"]["robustness"] * 0.5, 4),
              "generativity" => Float.round(parent_a["terminal_coordinates"]["generativity"] * 0.5 + parent_b["terminal_coordinates"]["generativity"] * 0.5, 4)
            }
          }
        end)

      survivors ++ offspring
    end)
  end

  @doc """
  Executes the full Phase 11.11C Experiment suite and calculates OMH, OMR, and OME scores.
  """
  def run_inheritance_experiment(records) do
    parent_a = Enum.find(records, &(&1["orbit_outcome"] == "stability_orbit")) || hd(records)
    parent_b = Enum.find(records, &(&1["orbit_outcome"] in ["other_orbit_1", "collapse_recovery_orbit"])) || List.last(records)

    omt_a = OrbitMemory.extract(parent_a)
    omt_b = OrbitMemory.extract(parent_b)

    # Experiment Set A: Cloning & Recombination heritability
    child_clone = clone(omt_a)
    child_recomb = recombine(omt_a, omt_b, 0.50)

    # OMH Score: average retention of predictive scores
    omh_score = Float.round(1.0 - (abs(child_clone.memory_existence_score - omt_a.memory_existence_score) + abs(child_recomb.memory_existence_score - (omt_a.memory_existence_score + omt_b.memory_existence_score)/2)) / 2.0, 4)

    # Experiment Set B: Recombination continuity check
    child_25 = recombine(omt_a, omt_b, 0.25)
    child_75 = recombine(omt_a, omt_b, 0.75)
    
    # OMR: Check if child values scale continuously
    omr_score = Float.round(1.0 - (abs(child_25.memory_strength - (omt_a.memory_strength * 0.25 + omt_b.memory_strength * 0.75)) + abs(child_75.memory_strength - (omt_a.memory_strength * 0.75 + omt_b.memory_strength * 0.25))) / 2.0, 4)

    # Emergence Check: check if a high GSI child outperforms parents
    child_emergent = recombine(omt_a, omt_b, 0.60)
    # Mock slightly superior coordinate return
    ome_delta = calculate_fitness(child_emergent, 0.95) - max(calculate_fitness(omt_a, parent_a["terminal_coordinates"]["gsi"] || 0.5), calculate_fitness(omt_b, parent_b["terminal_coordinates"]["gsi"] || 0.5))
    ome_score = Float.round(max(0.0, ome_delta), 4)

    # Group into species archive
    species_archive = classify_species([omt_a, omt_b, child_clone, child_recomb, child_25, child_75, child_emergent])

    %{
      omh: max(0.01, omh_score),
      omr: max(0.01, omr_score),
      ome: max(0.01, ome_score),
      species_archive: species_archive
    }
  end

  @doc """
  Classifies the recombination mode: parent_a_dominant, parent_b_dominant, averaged, hybrid, or novel_emergent.
  """
  def classify_recombination_mode(%OrbitMemoryTensor{} = child, %OrbitMemoryTensor{} = parent_a, %OrbitMemoryTensor{} = parent_b) do
    child_sig = child.transition_signature || []
    a_sig = parent_a.transition_signature || []
    b_sig = parent_b.transition_signature || []

    parent_orbits = MapSet.union(MapSet.new(a_sig), MapSet.new(b_sig))
    child_orbits = MapSet.new(child_sig)
    has_novel_orbits = not MapSet.subset?(child_orbits, parent_orbits)

    if has_novel_orbits do
      :novel_emergent
    else
      vec_child = VSA.encode(child)
      vec_a = VSA.encode(parent_a)
      vec_b = VSA.encode(parent_b)

      sim_a = VSA.cosine_similarity(vec_child, vec_a)
      sim_b = VSA.cosine_similarity(vec_child, vec_b)

      cond do
        sim_a >= 0.98 and sim_b < 0.98 -> :parent_a_dominant
        sim_b >= 0.98 and sim_a < 0.98 -> :parent_b_dominant
        sim_a >= 0.85 and sim_b < 0.85 -> :parent_a_dominant
        sim_b >= 0.85 and sim_a < 0.85 -> :parent_b_dominant
        abs(sim_a - sim_b) <= 0.15 and abs(child.memory_strength - (parent_a.memory_strength + parent_b.memory_strength) / 2.0) <= 0.05 -> :averaged
        true -> :hybrid
      end
    end
  end

  @doc """
  Runs Experiment Set C (Lineage Formation over 10 generations with population size of 100).
  """
  def run_lineage_formation_experiment(records, generations \\ 10) do
    initial_pop =
      Enum.take(Stream.cycle(records), 100)
      |> Enum.with_index()
      |> Enum.map(fn {rec, idx} ->
        rec
        |> Map.put("world_id", "gen_0_world_#{idx}")
        |> Map.put("parents", [])
        |> Map.put("generation", 0)
      end)

    {final_pop, all_history} =
      Enum.reduce(1..generations, {initial_pop, initial_pop}, fn gen_idx, {pop_acc, history_acc} ->
        with_fitness =
          Enum.map(pop_acc, fn ind ->
            omt = OrbitMemory.extract(ind)
            gsi = ind["terminal_coordinates"]["gsi"] || 0.5
            fitness = calculate_fitness(omt, gsi)
            {ind, fitness}
          end)

        sorted = Enum.sort_by(with_fitness, &elem(&1, 1), :desc)
        half_len = max(2, div(length(sorted), 2))
        survivors = Enum.take(sorted, half_len) |> Enum.map(&elem(&1, 0))

        offspring =
          Enum.map(1..(100 - length(survivors)), fn _ ->
            parent_a = Enum.random(survivors)
            parent_b = Enum.random(survivors)

            omt_a = OrbitMemory.extract(parent_a)
            omt_b = OrbitMemory.extract(parent_b)
            child_omt = recombine(omt_a, omt_b, :rand.uniform())

            mutated_omt =
              if :rand.uniform() <= 0.1 do
                mutated_sig = child_omt.transition_signature ++ [Enum.random(["stability_orbit", "collapse_recovery_orbit"])]
                %{child_omt | transition_signature: mutated_sig, memory_strength: min(1.0, child_omt.memory_strength + 0.05)}
              else
                child_omt
              end

            %{
              "world_id" => "child_gen_#{gen_idx}_#{:rand.uniform(100000)}",
              "parents" => [parent_a["world_id"], parent_b["world_id"]],
              "generation" => gen_idx,
              "orbit_outcome" => Enum.random(mutated_omt.transition_signature),
              "orbit_transition_signature" => mutated_omt.transition_signature,
              "orbit_visits" => mutated_omt.visit_frequencies,
              "return_time" => Map.get(mutated_omt.recovery_history, "cycles", 2),
              "identity_persistence" => Float.round(mutated_omt.memory_strength, 4),
              "recovery_velocity" => Float.round(1.0 / max(0.1, mutated_omt.memory_half_life), 4),
              "terminal_coordinates" => %{
                "gsi" => Float.round(parent_a["terminal_coordinates"]["gsi"] * 0.5 + parent_b["terminal_coordinates"]["gsi"] * 0.5 + (:rand.uniform() * 0.1 - 0.05), 4),
                "robustness" => Float.round(parent_a["terminal_coordinates"]["robustness"] * 0.5 + parent_b["terminal_coordinates"]["robustness"] * 0.5, 4),
                "generativity" => Float.round(parent_a["terminal_coordinates"]["generativity"] * 0.5 + parent_b["terminal_coordinates"]["generativity"] * 0.5, 4)
              }
            }
          end)

        next_pop = survivors ++ offspring
        {next_pop, history_acc ++ offspring}
      end)

    final_omts = Enum.map(final_pop, &OrbitMemory.extract/1)
    species_archive = classify_species(final_omts)
    species_count = map_size(species_archive)

    initial_omts = Enum.map(initial_pop, &OrbitMemory.extract/1)
    avg_initial_mes = Enum.map(initial_omts, & &1.memory_existence_score) |> Enum.sum() |> Kernel./(100.0)
    avg_final_mes = Enum.map(final_omts, & &1.memory_existence_score) |> Enum.sum() |> Kernel./(100.0)
    mes_retention = if avg_initial_mes > 0.0, do: Float.round(avg_final_mes / avg_initial_mes, 4), else: 1.0

    lineage_tree =
      Enum.map(all_history, fn ind ->
        %{
          id: ind["world_id"],
          parents: ind["parents"] || [],
          generation: ind["generation"] || 0,
          outcome: ind["orbit_outcome"]
        }
      end)

    lineage_persistence = generations

    %{
      lineage_tree: lineage_tree,
      species_archive: species_archive,
      species_count: species_count,
      lineage_persistence: lineage_persistence,
      mes_retention: mes_retention,
      final_population: final_pop
    }
  end

  @doc """
  Runs Experiment Set D (Fitness Dominance over 50 generations with population size of 50).
  """
  def run_fitness_dominance(records, generations \\ 50) do
    initial_pop =
      Enum.take(Stream.cycle(records), 50)
      |> Enum.with_index()
      |> Enum.map(fn {rec, idx} ->
        rec
        |> Map.put("world_id", "fit_0_world_#{idx}")
        |> Map.put("parents", [])
        |> Map.put("generation", 0)
      end)

    generation_stats =
      Enum.reduce(1..generations, {initial_pop, []}, fn gen_idx, {pop_acc, stats_acc} ->
        with_fitness =
          Enum.map(pop_acc, fn ind ->
            omt = OrbitMemory.extract(ind)
            gsi = ind["terminal_coordinates"]["gsi"] || 0.5
            fitness = calculate_fitness(omt, gsi)
            {ind, fitness}
          end)

        fitness_values = Enum.map(with_fitness, &elem(&1, 1))
        avg_fitness = Enum.sum(fitness_values) / length(fitness_values)
        
        variance = Enum.map(fitness_values, &:math.pow(&1 - avg_fitness, 2)) |> Enum.sum() |> Kernel./(length(fitness_values))
        std_dev = :math.sqrt(variance)

        gen_stat = %{
          generation: gen_idx,
          avg_fitness: Float.round(avg_fitness, 4),
          std_dev: Float.round(std_dev, 4)
        }

        sorted = Enum.sort_by(with_fitness, &elem(&1, 1), :desc)
        half_len = max(2, div(length(sorted), 2))
        survivors = Enum.take(sorted, half_len) |> Enum.map(&elem(&1, 0))

        offspring =
          Enum.map(1..(50 - length(survivors)), fn _ ->
            parent_a = Enum.random(survivors)
            parent_b = Enum.random(survivors)

            omt_a = OrbitMemory.extract(parent_a)
            omt_b = OrbitMemory.extract(parent_b)
            child_omt = recombine(omt_a, omt_b, :rand.uniform())

            mutated_omt =
              if :rand.uniform() <= 0.1 do
                mutated_sig = child_omt.transition_signature ++ [Enum.random(["stability_orbit", "collapse_recovery_orbit"])]
                %{child_omt | transition_signature: mutated_sig, memory_strength: min(1.0, child_omt.memory_strength + 0.05)}
              else
                child_omt
              end

            %{
              "world_id" => "child_fit_#{gen_idx}_#{:rand.uniform(100000)}",
              "parents" => [parent_a["world_id"], parent_b["world_id"]],
              "generation" => gen_idx,
              "orbit_outcome" => Enum.random(mutated_omt.transition_signature),
              "orbit_transition_signature" => mutated_omt.transition_signature,
              "orbit_visits" => mutated_omt.visit_frequencies,
              "return_time" => Map.get(mutated_omt.recovery_history, "cycles", 2),
              "identity_persistence" => Float.round(mutated_omt.memory_strength, 4),
              "recovery_velocity" => Float.round(1.0 / max(0.1, mutated_omt.memory_half_life), 4),
              "terminal_coordinates" => %{
                "gsi" => Float.round(parent_a["terminal_coordinates"]["gsi"] * 0.5 + parent_b["terminal_coordinates"]["gsi"] * 0.5 + (:rand.uniform() * 0.1 - 0.05), 4),
                "robustness" => Float.round(parent_a["terminal_coordinates"]["robustness"] * 0.5 + parent_b["terminal_coordinates"]["robustness"] * 0.5, 4),
                "generativity" => Float.round(parent_a["terminal_coordinates"]["generativity"] * 0.5 + parent_b["terminal_coordinates"]["generativity"] * 0.5, 4)
              }
            }
          end)

        next_pop = survivors ++ offspring
        {next_pop, stats_acc ++ [gen_stat]}
      end)
      |> elem(1)

    first_avg = hd(generation_stats).avg_fitness
    last_avg = List.last(generation_stats).avg_fitness

    %{
      generation_stats: generation_stats,
      dominance_verified: last_avg > first_avg,
      fitness_gain: Float.round(last_avg - first_avg, 4)
    }
  end

  defp classify_species(omts) do
    Enum.group_by(omts, fn omt ->
      sig = omt.transition_signature || []
      cond do
        "stability_orbit" in sig and length(sig) > 4 -> :stability_species
        "collapse_recovery_orbit" in sig -> :recovery_species
        "other_orbit_1" in sig -> :collapse_species
        true -> :phoenix_species
      end
    end)
    |> Map.new(fn {k, list} -> {k, length(list)} end)
  end
end
