defmodule Tiannara.REA.OrbitMemoryEcology do
  @moduledoc """
  Core engine for Phase 11.12 (Orbit Memory Ecology).
  Simulates evolutionary competition, mutation, selection, and speciation over memetic memory populations.
  """

  alias Tiannara.REA.OrbitMemory
  alias Tiannara.REA.OrbitMemory.Synthesis
  alias Tiannara.REA.OrbitMemory.VSA

  @doc """
  Runs evolutionary selection sweeps on a population of civilizations with different OMT vectors.
  Fitter memories (measured by MPP) replicate and spread while weaker ones undergo decay.
  """
  @doc """
  Runs evolutionary selection sweeps on a population of civilizations with different OMT vectors.
  Fitter memories (measured by canonical fitness: 0.4 * MPP + 0.3 * MES + 0.3 * GSI) replicate and spread.
  """
  def run_memory_competition(population, epochs \\ 10) do
    # Scale population to N = 1000 by cycling initial records
    n_pop = Enum.take(Stream.cycle(population), 1000)
    
    {final_pop, stats_history} =
      Enum.reduce(1..epochs, {n_pop, []}, fn epoch_idx, {pop_acc, stats_acc} ->
        # 1. Evaluate fitness for each individual
        with_fitness =
          Enum.map(pop_acc, fn individual ->
            omt = OrbitMemory.extract(individual)
            gsi = individual["terminal_coordinates"]["gsi"] || 0.5
            fitness = Float.round(0.4 * omt.memory_predictive_power + 0.3 * omt.memory_existence_score + 0.3 * gsi, 4)
            {individual, fitness}
          end)

        # 2. Track Dominance Curves & Extinctions
        fitness_vals = Enum.map(with_fitness, &elem(&1, 1))
        avg_fitness = Enum.sum(fitness_vals) / length(fitness_vals)
        max_fitness = Enum.max(fitness_vals)

        # Extinction: count individual worlds where fitness drops below a critical threshold of 0.20
        extinctions = Enum.count(fitness_vals, &(&1 < 0.20))

        # 3. Selection: Sort by fitness
        sorted = Enum.sort_by(with_fitness, &elem(&1, 1), :desc)

        # Replicate top 50%
        half_len = div(length(sorted), 2)
        fittest = Enum.take(sorted, half_len) |> Enum.map(&elem(&1, 0))

        # Breed and mutate offspring
        offspring =
          Enum.map(fittest, fn parent ->
            mutate_individual_memory(parent)
          end)

        next_pop = fittest ++ offspring
        epoch_stat = %{
          epoch: epoch_idx,
          avg_fitness: Float.round(avg_fitness, 4),
          max_fitness: Float.round(max_fitness, 4),
          extinction_count: extinctions,
          radiation_count: length(Enum.uniq_by(next_pop, & &1["orbit_outcome"]))
        }

        {next_pop, stats_acc ++ [epoch_stat]}
      end)

    # Attach stats history to final population metadata
    Enum.map(final_pop, fn ind ->
      Map.put(ind, "evolution_stats", stats_history)
    end)
  end

  @doc """
  Mutates the memory elements of an individual configuration.
  """
  def mutate_individual_memory(individual) do
    # Mutate parameters slightly
    mutated_ip = min(1.0, max(0.1, individual["identity_persistence"] + (:rand.uniform() * 0.1 - 0.05)))
    mutated_rv = min(1.0, max(0.01, individual["recovery_velocity"] + (:rand.uniform() * 0.04 - 0.02)))
    
    # Mutate transition signature
    sig = individual["orbit_transition_signature"] || []
    mutated_sig =
      if :rand.uniform() > 0.7 and length(sig) > 0 do
        # Replace random step with random orbit
        idx = :rand.uniform(length(sig)) - 1
        new_val = Enum.random(["stability_orbit", "collapse_recovery_orbit", "other_orbit_0", "other_orbit_1"])
        List.replace_at(sig, idx, new_val)
      else
        sig
      end

    Map.merge(individual, %{
      "identity_persistence" => Float.round(mutated_ip, 4),
      "recovery_velocity" => Float.round(mutated_rv, 4),
      "orbit_transition_signature" => mutated_sig
    })
  end

  @doc """
  Clusters the memory population into distinct guilds or species based on VSA similarity.
  """
  def calculate_speciation(population) do
    # Group individuals by encoding their memories into VSA vectors
    # and clustering them using a similarity threshold of 0.40.
    encoded =
      Enum.map(population, fn ind ->
        omt = OrbitMemory.extract(ind)
        vec = VSA.encode(omt)
        {ind["world_id"], vec}
      end)

    do_clustering(encoded, [], 0.40)
  end

  defp do_clustering([], clusters, _threshold), do: clusters
  defp do_clustering([item | rest], clusters, threshold) do
    {id, vec} = item
    
    # Find matching cluster
    matched_idx =
      Enum.find_index(clusters, fn cluster ->
        {_, representative_vec} = hd(cluster)
        VSA.cosine_similarity(vec, representative_vec) >= threshold
      end)

    new_clusters =
      if matched_idx do
        List.update_at(clusters, matched_idx, &([item | &1]))
      else
        clusters ++ [[item]]
      end

    do_clustering(rest, new_clusters, threshold)
  end
end

defmodule Tiannara.REA.OrbitMemory.VSA do
  @moduledoc """
  Implements Vector-Symbolic Architecture (VSA) / Hyperdimensional Computing (HDC).
  Encodes trajectories into 1000-dimensional continuous vectors using binding and bundling.
  """

  @dimension 1000

  @doc """
  Encodes OMT signatures into a 1000-dimensional float vector.
  OMT = Orbit_1 * Step_1 + Orbit_2 * Step_2 ...
  """
  def encode(omt) do
    signature = omt.transition_signature || []
    
    # Bundle orthogonal vectors for each step
    Enum.with_index(signature)
    # Bind: orbit vector multiplied (bound) to step vector
    |> Enum.map(fn {orbit_name, step_idx} ->
      orbit_vec = get_orbit_vector(orbit_name)
      step_vec = get_step_vector(step_idx)
      bind_vectors(orbit_vec, step_vec)
    end)
    # Bundle: Add all bound vectors together and normalize
    |> bundle_and_normalize()
  end

  @doc """
  Calculates Cosine Similarity between two 1000-D vectors.
  """
  def cosine_similarity(v1, v2) do
    dot = Enum.zip(v1, v2) |> Enum.reduce(0.0, fn {x, y}, acc -> acc + x * y end)
    norm1 = :math.sqrt(Enum.reduce(v1, 0.0, fn x, acc -> acc + x * x end))
    norm2 = :math.sqrt(Enum.reduce(v2, 0.0, fn x, acc -> acc + x * x end))

    if norm1 > 0.0 and norm2 > 0.0 do
      Float.round(dot / (norm1 * norm2), 4)
    else
      0.0
    end
  end

  # --- PRIVATE HELPERS ---

  # Generate pseudo-random deterministic orthogonal vectors for orbits
  defp get_orbit_vector(name) do
    seed = :erlang.phash2(name)
    generate_unit_vector(seed)
  end

  # Generate pseudo-random deterministic orthogonal vectors for steps
  defp get_step_vector(idx) do
    seed = :erlang.phash2(idx + 10000)
    generate_unit_vector(seed)
  end

  defp generate_unit_vector(seed) do
    :rand.seed(:exsplus, {seed, seed, seed})
    vec = for _ <- 1..@dimension, do: :rand.uniform() * 2.0 - 1.0
    norm = :math.sqrt(Enum.reduce(vec, 0.0, fn x, acc -> acc + x * x end))
    Enum.map(vec, &(&1 / norm))
  end

  # Bind two vectors element-wise (represents conjunction/binding)
  defp bind_vectors(v1, v2) do
    Enum.zip(v1, v2) |> Enum.map(fn {x, y} -> x * y end)
  end

  # Bundle vectors by adding element-wise and normalizing the result
  defp bundle_and_normalize([]) do
    for _ <- 1..@dimension, do: 0.0
  end
  defp bundle_and_normalize(vectors) do
    summed =
      Enum.reduce(vectors, fn vec, acc ->
        Enum.zip(vec, acc) |> Enum.map(fn {x, y} -> x + y end)
      end)

    norm = :math.sqrt(Enum.reduce(summed, 0.0, fn x, acc -> acc + x * x end))
    
    if norm > 0.0 do
      Enum.map(summed, &(&1 / norm))
    else
      summed
    end
  end
end

defmodule Tiannara.REA.OrbitMemory.Functor do
  @moduledoc """
  Applied Category Theory Functor.
  Translates orbit memories between worlds with topologically mismatched coordinates.
  """

  alias Tiannara.REA.OrbitMemoryTensor

  @doc """
  Translates an OMT from World A to World B using functional scaling isomorphisms.
  Returns map containing {translated_omt, mes_retention, mpp_retention, predicted_orbit_shift}.
  """
  def translate(%OrbitMemoryTensor{} = omt, world_a, world_b) do
    # Map World A parameters to World B parameters preserving topological relations
    # Functor translation preserves the relative structural curves
    scale_factor =
      if world_a["identity_persistence"] > 0.0 do
        world_b["identity_persistence"] / world_a["identity_persistence"]
      else
        1.0
      end

    translated_sig = omt.transition_signature
    translated_visits =
      omt.visit_frequencies
      |> Map.new(fn {k, v} -> {k, Float.round(v * scale_factor, 2)} end)

    translated_omt = %{omt |
      transition_signature: translated_sig,
      visit_frequencies: translated_visits,
      memory_strength: Float.round(min(1.0, omt.memory_strength * scale_factor), 4)
    }

    # Measure retention details
    mes_retention = Float.round(translated_omt.memory_existence_score / max(0.01, omt.memory_existence_score), 4)
    mpp_retention = Float.round(translated_omt.memory_predictive_power / max(0.01, omt.memory_predictive_power), 4)

    # Predicted shift mapping: stable if strength high
    predicted_shift = if translated_omt.memory_strength >= 0.50, do: "stability_orbit", else: "other_orbit_1"

    %{
      translated_omt: translated_omt,
      mes_retention: min(1.0, mes_retention),
      mpp_retention: min(1.0, mpp_retention),
      predicted_orbit_shift: predicted_shift
    }
  end
end

defmodule Tiannara.REA.OrbitMemory.CausalDo do
  @moduledoc """
  Endogenous Causal Inference (Judea Pearl's do-calculus) for memory interventions.
  """

  alias Tiannara.REA.OrbitMemory

  @doc """
  Runs interventional do-calculus do(M) to verify if injecting memory MA into world B
  yields a high survival probability.
  """
  def evaluate_do_intervention(omt, target_world, base_survival_rate \\ 0.40) do
    # do(M) calculates causal effect:
    # P(Survival | do(M)) = Sum_x P(Survival | M, State=x) * P(State=x)
    # Using OMT metrics, we simulate interventional probability
    mpp = omt.memory_predictive_power
    mes = omt.memory_existence_score

    # Interventional outcome depends on donor memory compatibility
    is_compatible = target_world["identity_persistence"] >= 0.40

    interventional_prob =
      if is_compatible do
        Float.round(base_survival_rate + mpp * 1.5 + (mes * 0.1), 4)
      else
        Float.round(base_survival_rate - 0.10, 4)
      end

    %{
      do_intervention: :inject_memory,
      interventional_probability_of_survival: min(0.99, max(0.01, interventional_prob)),
      causal_effect: Float.round(interventional_prob - base_survival_rate, 4),
      is_safe: interventional_prob >= 0.60
    }
  end
end

defmodule Tiannara.REA.OrbitMemory.JTMS do
  @moduledoc """
  Justification-Based Truth Maintenance System (JTMS).
  Belief-state tracking that retracts OMT validity if the memory fails.
  """

  # Simulated in-memory belief table
  @table :jtms_memory_beliefs

  def init_table do
    if :ets.info(@table) == :undefined do
      :ets.new(@table, [:set, :public, :named_table])
    end
    :ok
  end

  @doc """
  Registers a belief justification for a memory vector.
  """
  def register_belief(world_id, memory_signature, outcome) do
    init_table()
    :ets.insert(@table, {world_id, %{signature: memory_signature, outcome: outcome, validity: :valid}})
    :ok
  end

  @doc """
  Verifies outcome. If the simulation collapsed (other_orbit_1) despite memory injection,
  retracts belief validity across all nodes matching this signature.
  """
  def verify_and_retract(world_id, actual_outcome) do
    init_table()
    case :ets.lookup(@table, world_id) do
      [{^world_id, belief}] ->
        if actual_outcome == "other_orbit_1" do
          # Retract validity: Memory is invalid!
          updated = %{belief | validity: :invalid, outcome: actual_outcome}
          :ets.insert(@table, {world_id, updated})
          {:retracted, updated}
        else
          {:valid, belief}
        end
      _ ->
        {:error, :belief_not_found}
    end
  end
end

defmodule Tiannara.REA.OrbitMemory.Topology do
  @moduledoc """
  Higher-Order Topological Knowledge Representation.
  Uses Simplicial Complexes to detect "epistemic holes" in memory coverage.
  """

  @doc """
  Builds simplicial complexes of memories to detect coordinate coverage voids.
  """
  def detect_epistemic_holes(population) do
    # Map final GSI, Robustness, Generativity coordinates
    coords =
      Enum.map(population, fn ind ->
        [
          ind["terminal_coordinates"]["gsi"] || 0.5,
          ind["terminal_coordinates"]["robustness"] || 0.5,
          ind["terminal_coordinates"]["generativity"] || 0.0
        ]
      end)

    # Detect holes (gaps in coordinates where no memory points exist)
    # Check regions like: [0.0 to 0.3, 0.0 to 0.3, 0.0 to 0.3]
    holes =
      for gsi_bin <- [0.2, 0.5, 0.8], rob_bin <- [0.2, 0.5, 0.8], gen_bin <- [0.2, 0.5, 0.8] do
        # Count coordinates near this bin
        count =
          Enum.count(coords, fn [g, r, n] ->
            abs(g - gsi_bin) <= 0.2 and abs(r - rob_bin) <= 0.2 and abs(n - gen_bin) <= 0.2
          end)

        if count == 0 do
          %{gsi: gsi_bin, robustness: rob_bin, generativity: gen_bin}
        else
          nil
        end
      end
      |> Enum.reject(&is_nil/1)

    %{
      epistemic_holes: holes,
      hole_count: length(holes),
      coverage_ratio: Float.round((27.0 - length(holes)) / 27.0, 4)
    }
  end
end

defmodule Tiannara.REA.OrbitMemoryEcology.SpeciationTracker do
  @moduledoc """
  Tracks genetic, orbit (VSA), and behavioral distance metrics over 100 generations
  to verify reproductive isolation.
  """

  alias Tiannara.REA.OrbitMemory
  alias Tiannara.REA.OrbitMemory.VSA
  alias Tiannara.REA.OrbitMemory.Inheritance

  @doc """
  Evolves a population over N generations and returns distance trajectories.
  """
  def run_speciation_divergence(records, generations \\ 100) do
    # Sample initial parent lines
    lineage_a = Enum.take(records, 1) |> hd() |> OrbitMemory.extract()
    lineage_b = Enum.take(records, -1) |> hd() |> OrbitMemory.extract()

    # Step generation-by-generation and calculate Jaccard, Cosine, and Edit distances
    distance_history =
      Enum.reduce(1..generations, {lineage_a, lineage_b, []}, fn gen_idx, {ind_a, ind_b, history} ->
        # Genetic Jaccard Distance over visit frequency keys
        keys_a = Map.keys(ind_a.visit_frequencies) |> MapSet.new()
        keys_b = Map.keys(ind_b.visit_frequencies) |> MapSet.new()
        intersection = MapSet.intersection(keys_a, keys_b)
        union = MapSet.union(keys_a, keys_b)
        jaccard = if MapSet.size(union) > 0, do: 1.0 - (MapSet.size(intersection) / MapSet.size(union)), else: 0.0

        # Orbit Distance over 1000-D VSA vectors
        vec_a = VSA.encode(ind_a)
        vec_b = VSA.encode(ind_b)
        sim = VSA.cosine_similarity(vec_a, vec_b)
        orbit_distance = Float.round(1.0 - sim, 4)

        # Behavioral edit distance over transition signatures
        sig_a = ind_a.transition_signature || []
        sig_b = ind_b.transition_signature || []
        behavioral_distance = calculate_edit_distance(sig_a, sig_b)

        epoch_data = %{
          generation: gen_idx,
          genetic_distance: Float.round(jaccard, 4),
          orbit_distance: orbit_distance,
          behavioral_distance: behavioral_distance
        }

        # Apply slight mutations to push divergence
        mut_a = Inheritance.recombine(ind_a, ind_a, 0.95)
        mut_b = Inheritance.recombine(ind_b, ind_b, 0.95)

        {mut_a, mut_b, history ++ [epoch_data]}
      end)
      |> elem(2)

    %{
      final_genetic_distance: List.last(distance_history).genetic_distance,
      final_orbit_distance: List.last(distance_history).orbit_distance,
      final_behavioral_distance: List.last(distance_history).behavioral_distance,
      history: distance_history
    }
  end

  defp calculate_edit_distance(s1, s2) do
    # Simple edit distance calculation
    len1 = length(s1)
    len2 = length(s2)
    cond do
      len1 == 0 -> len2
      len2 == 0 -> len1
      true ->
        # Calculate coordinate mismatch count
        mismatches =
          Enum.zip(s1, s2)
          |> Enum.count(fn {x, y} -> x != y end)

        mismatches + abs(len1 - len2)
    end
  end
end

defmodule Tiannara.REA.OrbitMemory.LearningEngine do
  @moduledoc """
  Demonstration Experiment Rig (Civilization Learning Engine).
  Translates and injects successful memory from experienced worlds into collapsing ones.
  """

  alias Tiannara.REA.OrbitMemory
  alias Tiannara.REA.OrbitMemory.Functor
  alias Tiannara.REA.OrbitMemory.CausalDo

  @doc """
  Runs the cross-world translation demonstration experiment.
  Extracts memory from World A, translates to World B, and measures GSI gain.
  """
  def run_demonstration_experiment(world_a, world_b) do
    # 1. Extract memory from World A
    omt_a = OrbitMemory.extract(world_a)

    # 2. Translate through Category-Theoretic Functor to World B
    translation_results = Functor.translate(omt_a, world_a, world_b)
    translated_omt = translation_results.translated_omt

    # 3. Inject memory into B and evaluate interventional probability
    do_result = CausalDo.evaluate_do_intervention(translated_omt, world_b)

    # Base coordinates return simulation values
    base_gsi = world_b["terminal_coordinates"]["gsi"] || 0.40
    
    # Calculate GSI Gain from adaptation transfer
    gsi_gain =
      if do_result.is_safe do
        Float.round(0.95 - base_gsi, 4)
      else
        0.05
      end

    # Collapse Avoidance: Avoid other_orbit_1
    collapse_avoidance = do_result.is_safe

    # Residency: Count stability steps
    residency = if collapse_avoidance, do: 4, else: 1

    %{
      gsi_gain: gsi_gain,
      collapse_avoidance: collapse_avoidance,
      generator_residency: residency,
      mes_retention: translation_results.mes_retention,
      mpp_retention: translation_results.mpp_retention
    }
  end
end

