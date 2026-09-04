# scripts/rea_5_2_ecology.exs
defmodule Tiannara.REA.EpistemologyEcologyTest do
  @moduledoc """
  Phase REA-5.2: Epistemology Ecology Test (Corrected).
  """
  require Logger

  @epochs 3_000
  @population_size 100
  @mutation_rate 0.05
  @snapshot_interval 500

  @environments [
    %{
      name: "Env_A_Exploration_Boost",
      description: "Moderately rewards novel discovery",
      multipliers: %{exploration: 1.5, compression: 1.0, prediction: 1.0, generalist: 1.0}
    },
    %{
      name: "Env_B_Compression_Boost",
      description: "Moderately rewards efficient, compressed theories",
      multipliers: %{exploration: 1.0, compression: 1.5, prediction: 1.0, generalist: 1.0}
    },
    %{
      name: "Env_C_Prediction_Boost",
      description: "Moderately rewards causal consistency",
      multipliers: %{exploration: 1.0, compression: 1.0, prediction: 1.5, generalist: 1.0}
    },
    %{
      name: "Env_D_Balanced_Control",
      description: "Baseline environment with no artificial bias",
      multipliers: %{exploration: 1.0, compression: 1.0, prediction: 1.0, generalist: 1.0}
    },
    %{
      name: "Env_E_Recovery_Test",
      description: "Boosts Exploration for 1500 epochs, then reverts to baseline",
      is_recovery: true,
      multipliers_phase_1: %{exploration: 1.5, compression: 1.0, prediction: 1.0, generalist: 1.0},
      multipliers_phase_2: %{exploration: 1.0, compression: 1.0, prediction: 1.0, generalist: 1.0}
    }
  ]

  def run_perturbation_battery() do
    Logger.info("🧪 [REA-5.2] Initiating Epistemology Ecology Perturbation Battery (Corrected)...")
    kg = generate_knowledge_graph(1_000)
    
    results = Enum.map(@environments, fn env ->
      Logger.info("🌍 Running #{env.name}: #{env.description}")
      run_speciation_with_pressure(kg, env)
    end)
    
    generate_ecology_verdict(results)
  end

  defp run_speciation_with_pressure(kg, env) do
    base_pop = generate_diverse_initial_population()
    lineage_registry = %{"root" => %{parent: nil, generation: 0}}
    
    {_final_pop, _lineage, telemetry} = evolve_with_pressure(
      base_pop, kg, @epochs, lineage_registry, env, []
    )
    
    %{
      environment: env.name,
      is_recovery: Map.get(env, :is_recovery, false),
      final_telemetry: List.first(telemetry),
      full_telemetry: telemetry
    }
  end

  defp evolve_with_pressure(pop, _kg, 0, lineage, _env, telemetry), do: {pop, lineage, telemetry}
  
  defp evolve_with_pressure(pop, kg, epochs_remaining, lineage, env, telemetry) do
    current_epoch = @epochs - epochs_remaining + 1
    
    multipliers = if Map.get(env, :is_recovery, false) && current_epoch > 1500 do
      env.multipliers_phase_2
    else
      Map.get(env, :multipliers, env[:multipliers_phase_1] || %{exploration: 1.0, compression: 1.0, prediction: 1.0, generalist: 1.0})
    end

    # 1. Evaluate Fitness & ATTACH METRICS
    evaluated_pop = Enum.map(pop, fn agent ->
      traversal = simulate_weighted_walk(agent.heuristic_weights, kg, 50)
      
      metrics = %{
        predictive_compression_ratio: traversal.compression_score,
        novelty_yield: traversal.novelty_score,
        prediction_accuracy: traversal.prediction_score
      }
      
      base_fitness = (metrics.predictive_compression_ratio * 0.4) + 
                     (metrics.novelty_yield * 0.4) + 
                     (metrics.prediction_accuracy * 0.2)
                     
      niche = classify_niche_by_behavior(metrics)
      multiplier = Map.get(multipliers, niche, 1.0)
      final_fitness = base_fitness * multiplier
                
      %{agent | fitness: final_fitness, metrics: metrics}
    end)
    
    # 2. Tournament Selection
    survivors = Enum.map(1..@population_size, fn _ ->
      contenders = Enum.take_random(evaluated_pop, 3)
      Enum.max_by(contenders, & &1.fitness)
    end)
    
    # 3. Mutation & Lineage Tracking (CRITICAL FIX: Preserve lineage_id)
    {next_gen, new_lineage} = Enum.map_reduce(survivors, lineage, fn parent, current_lineage ->
      child_id = System.unique_integer([:positive])
      
      child = if :rand.uniform() < @mutation_rate do
        new_weights = Enum.map(parent.heuristic_weights, fn w ->
          max(0.0, min(1.0, w + (:rand.uniform() - 0.5) * 0.2))
        end)
        %{parent | id: child_id, lineage_id: parent.lineage_id, heuristic_weights: new_weights, fitness: 0.0, metrics: parent.metrics}
      else
        %{parent | id: child_id, lineage_id: parent.lineage_id, fitness: 0.0, metrics: parent.metrics}
      end
      
      updated_lineage = Map.put(current_lineage, child_id, %{
        parent: parent.id,
        lineage_id: parent.lineage_id,
        generation: (current_lineage[parent.id][:generation] || 0) + 1
      })
      
      {child, updated_lineage}
    end)
    
    # 4. Record Epoch Telemetry & Transitions (Using lineage_id)
    previous_snapshot = List.first(telemetry)
    new_telemetry = if rem(current_epoch, @snapshot_interval) == 0 do
      [record_niche_snapshot(next_gen, previous_snapshot, current_epoch) | telemetry]
    else
      telemetry
    end
    
    evolve_with_pressure(next_gen, kg, epochs_remaining - 1, new_lineage, env, new_telemetry)
  end

  defp classify_niche_by_behavior(metrics) do
    # CALIBRATED THRESHOLDS based on actual P75 distribution
    cond do
      metrics.predictive_compression_ratio >= 0.844 -> :compression
      metrics.novelty_yield >= 0.718 -> :exploration
      metrics.prediction_accuracy >= 0.725 -> :prediction
      true -> :generalist
    end
  end

  defp record_niche_snapshot(pop, previous_snapshot, epoch) do
    niches = Enum.group_by(pop, fn agent -> classify_niche_by_behavior(agent.metrics) end)
    
    # CRITICAL FIX: Track transitions by persistent lineage_id, not ephemeral agent.id
    # Option A (Lineage Adaptation): One entry per lineage.
    transitions = if previous_snapshot do
      calculate_transitions(pop, previous_snapshot.agent_lineage_niches)
    else
      %{}
    end
    
    # Map.new naturally deduplicates by lineage_id, ensuring 1 state per phylogenetic line
    agent_lineage_niches = Map.new(pop, fn agent -> 
      {agent.lineage_id, classify_niche_by_behavior(agent.metrics)} 
    end)
    
    %{
      epoch: epoch,
      compression: length(niches[:compression] || []),
      exploration: length(niches[:exploration] || []),
      prediction: length(niches[:prediction] || []),
      generalist: length(niches[:generalist] || []),
      transitions: transitions,
      agent_lineage_niches: agent_lineage_niches
    }
  end

  defp calculate_transitions(current_pop, previous_agent_lineage_niches) do
    # Deduplicate the current pop to track Lineage state, not Population Expansion
    unique_lineages = Enum.uniq_by(current_pop, & &1.lineage_id)
    
    Enum.reduce(unique_lineages, %{}, fn agent, acc ->
      prev_niche = Map.get(previous_agent_lineage_niches, agent.lineage_id, :unknown)
      curr_niche = classify_niche_by_behavior(agent.metrics)
      
      if prev_niche != :unknown do
        Map.update(acc, {prev_niche, curr_niche}, 1, &(&1 + 1))
      else
        acc
      end
    end)
  end

  defp generate_diverse_initial_population do
    Enum.map(1..@population_size, fn i ->
      weights = case rem(i, 4) do
        0 -> [0.8, 0.3, 0.3, 0.3]
        1 -> [0.3, 0.8, 0.3, 0.3]
        2 -> [0.3, 0.3, 0.8, 0.3]
        3 -> [0.5, 0.5, 0.5, 0.5]
      end
      %{
        id: "init_#{i}", 
        lineage_id: "lineage_#{i}", # Persistent across all descendants
        heuristic_weights: weights, 
        fitness: 0.0, 
        metrics: %{}
      }
    end)
  end

  defp generate_ecology_verdict(results) do
    Logger.info("\n==================================================")
    Logger.info("📊 REA-5.2 EPISTEMOLOGY ECOLOGY VERDICT (3-LEVEL)")
    Logger.info("==================================================")
    
    # Extract baselines
    control = Enum.find(results, &(&1.environment == "Env_D_Balanced_Control")).final_telemetry
    env_a = Enum.find(results, &(&1.environment == "Env_A_Exploration_Boost")).final_telemetry
    recovery = Enum.find(results, &(&1.environment == "Env_E_Recovery_Test"))
    
    # Calculate relative survival (CRITICAL FIX: No arbitrary >= 5 thresholds)
    control_comp_share = control.compression / @population_size
    env_a_comp_share = env_a.compression / @population_size
    relative_comp_survival = env_a_comp_share / max(control_comp_share, 0.01)
    
    # Calculate transition stability (diagonal / total)
    total_transitions = Enum.sum(Map.values(env_a.transitions))
    diagonal_stays = Enum.sum(for {{n, n2}, count} <- env_a.transitions, n == n2, do: count)
    stability_ratio = diagonal_stays / max(total_transitions, 1)
    
    # Calculate Recovery Metric (CRITICAL FIX: final_telemery -> final_telemetry)
    recovery_final = recovery.final_telemetry
    recovery_mid = Enum.find(recovery.full_telemetry, &(&1.epoch == 1500))
    
    recovery_score = if recovery_mid && recovery_final do
      # How much did Compression recover from epoch 1500 to 3000 after boost was removed?
      # Wait, in the recovery test Exploration was boosted, so Compression dropped.
      # We measure if Compression returned to the Control baseline.
      comp_1500 = recovery_mid.compression
      comp_3000 = recovery_final.compression
      comp_control = control.compression
      
      diff_mid = abs(comp_1500 - comp_control)
      diff_final = abs(comp_3000 - comp_control)
      
      # 1.0 = perfectly returned to control baseline, 0.0 = stayed stuck in boosted state
      abs_val = diff_final / max(diff_mid, 0.01)
      max(0.0, 1.0 - abs_val)
    else
      0.0
    end

    Logger.info("\n🔍 ECOLOGICAL VALIDATION METRICS:")
    Logger.info("   [Relative Survival] Compression retains #{Float.round(relative_comp_survival * 100, 1)}% of its control share under Exploration pressure.")
    Logger.info("   [Lineage Stability] #{Float.round(stability_ratio * 100, 1)}% of lineages maintained their niche identity (no chaotic relabeling).")
    Logger.info("   [Recovery Score]    #{Float.round(recovery_score * 100, 1)}% return to baseline attractor after pressure removal.")

    # 3-LEVEL VERDICT LOGIC
    level_1_achieved = stability_ratio > 0.5
    level_2_achieved = relative_comp_survival > 0.3
    level_3_achieved = recovery_score > 0.6

    Logger.info("\n🏆 FINAL VERDICT:")
    cond do
      level_3_achieved ->
        Logger.info("   ✅ LEVEL 3: SYMBIOTIC ECOLOGY CONFIRMED.")
        Logger.info("      Niches dynamically reorganize, persist relatively, and the system actively")
        Logger.info("      recovers to its baseline attractor state, proving deep interdependence.")
      level_2_achieved ->
        Logger.info("   ⚠️ LEVEL 2: STABLE NICHES OBSERVED.")
        Logger.info("      Niches persist under pressure, but recovery to baseline is incomplete.")
        Logger.info("      Suggests path dependence rather than true symbiotic attractors.")
      level_1_achieved ->
        Logger.info("   ⚠️ LEVEL 1: ADAPTIVE REORGANIZATION ONLY.")
        Logger.info("      Populations shift under pressure, but fail to maintain relative stability.")
        Logger.info("      May indicate winner-take-all dynamics rather than a true ecology.")
      true ->
        Logger.info("   ❌ ECOLOGY INCONCLUSIVE.")
        Logger.info("      High chaotic relabeling or total niche collapse detected.")
    end
    Logger.info("==================================================")
  end

  # --- Simplified Walk Helpers ---
  defp generate_knowledge_graph(size) do
    :rand.seed(:exsss, {1, 2, 3})
    nodes = Enum.reduce(0..(size-1), %{}, fn i, acc ->
      Map.put(acc, i, %{
        id: i, shortcut_potential: :rand.uniform(), novelty_value: :rand.uniform(), consistency: :rand.uniform(),
        neighbors: Enum.map(1..10, fn _ -> :rand.uniform(size) - 1 end) |> Enum.uniq() |> List.delete(i)
      })
    end)
    %{nodes: nodes, total_active_nodes: size}
  end

  defp simulate_weighted_walk([w_comp, w_expl, w_pred, w_gen], kg, steps) do
    start_node = :rand.uniform(kg.total_active_nodes) - 1
    {visited, comp_acc, nov_acc, pred_acc} = Enum.reduce(1..steps, {MapSet.new([start_node]), 0.0, 0.0, 0.0}, fn _, {visited_set, c, n, p} ->
      current_node = kg.nodes[Enum.random(MapSet.to_list(visited_set))]
      best_neighbor_id = current_node.neighbors |> Enum.max_by(fn n_id -> 
        neighbor = kg.nodes[n_id]
        score = (w_comp * neighbor.shortcut_potential) + (w_expl * neighbor.novelty_value) + (w_pred * neighbor.consistency) + (w_gen * :rand.uniform())
        score - (if MapSet.member?(visited_set, n_id), do: w_expl * 0.5, else: 0.0)
      end, fn -> Enum.random(current_node.neighbors) end)
      
      chosen = kg.nodes[best_neighbor_id]
      {MapSet.put(visited_set, best_neighbor_id), c + chosen.shortcut_potential, n + chosen.novelty_value, p + chosen.consistency}
    end)
    %{compression_score: comp_acc / steps, novelty_score: nov_acc / steps, prediction_score: pred_acc / steps}
  end
end

Tiannara.REA.EpistemologyEcologyTest.run_perturbation_battery()
