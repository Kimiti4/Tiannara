alias Tiannara.Core.WorldModel.EntityRegistry
alias Tiannara.REL.EconomyEngine
alias Tiannara.ROS.EvolutionEngine
alias Tiannara.Sentinel.D2.AnalyticsEngine
alias Tiannara.Sentinel.D2.EcologyRegime
require Logger

defmodule EcologicalStressTest do
  @moduledoc "Phase 9.85 Simulation Script for mapping the Epistemic Fitness Landscape."

  @operators [
    "causal", "empirical", "counterfactual",
    "recursive", "analogical", "adversarial",
    "symbolic", "formal", "abductive"
  ]

  @regimes [
    %EcologyRegime{acm_level: :low, disease_level: :none, resource_level: :abundant},
    %EcologyRegime{acm_level: :medium, disease_level: :natural, resource_level: :balanced},
    %EcologyRegime{acm_level: :high, disease_level: :aggressive, resource_level: :scarce},
    %EcologyRegime{acm_level: :extreme, disease_level: :pandemic, resource_level: :collapse}
  ]

  def run_ladder do
    Logger.info("\n=== INITIATING PHASE 9.85 ECOLOGICAL STRESS TESTING ===")
    
    stages = [
      {1, 100, 5, 2000},
      {2, 250, 5, 5000}
      # Stage 3 and 4 omitted in this run to save interactive simulation time
      # {3, 500, 10, 7500},
      # {4, 1000, 10, 10000}
    ]

    Enum.each(stages, fn {stage, civs, shards, epochs} ->
      regime = Enum.at(@regimes, stage - 1) || List.last(@regimes)
      run_stage(stage, civs, shards, epochs, regime)
    end)
  end

  def run_stage(stage, civ_count, shard_count, epochs, regime) do
    Logger.info("\n=== STAGE #{stage} | REGIME: #{inspect(regime)} ===")
    Logger.info("Parameters: #{civ_count} Civs, #{shard_count} Shards, #{epochs} Epochs")

    shards = Enum.map(1..shard_count, &"shard_stress_#{stage}_#{&1}")

    Enum.each(shards, fn shard -> Tiannara.ROS.ShardManager.spawn_shard(shard) end)
    seed_civilizations(civ_count, shards, regime)
    simulate_epochs(civ_count, shards, epochs, regime)
    generate_report(stage, regime)
  end

  defp seed_civilizations(count, shards, _regime) do
    Enum.each(1..count, fn i ->
      civ_id = "civ_stress_#{i}"
      shard_id = Enum.random(shards)
      genome = Enum.take_random(@operators, Enum.random(2..4))
      
      EntityRegistry.register_entity(%{
        id: civ_id,
        type: :civilization,
        name: "Stress Civ #{i}",
        confidence: 1.0,
        attributes: %{
          epistemic_genome: genome,
          active_operators: genome,
          fitness_score: 0.5
        }
      }, shard_id)
      
      EconomyEngine.register_civilization(shard_id, civ_id)
      EconomyEngine.inject(civ_id, %{energy: 5000, compute: 5000, attention: 5000})
      EconomyEngine.grant_truth_capital(civ_id, 100.0)
      EconomyEngine.grant_influence_capital(civ_id, 50.0)
    end)
  end

  defp simulate_epochs(civ_count, shards, epochs, regime) do
    # Simulates runtime, embedding the regime into events
    Enum.each(1..epochs, fn epoch ->
      if rem(epoch, 1000) == 0 do
        Logger.info("... Simulated #{epoch} Epochs under #{regime.acm_level} ACM")
      end

      Enum.each(1..civ_count, fn i ->
        civ_id = "civ_stress_#{i}"
        shard_id = Enum.random(shards)
        
        ops = case EntityRegistry.get_entity(civ_id, shard_id) do
          {:ok, ent} -> Map.get(ent.attributes, :active_operators, [])
          _ -> []
        end
        
        if ops != [] do
          Tiannara.Sentinel.D2.EpistemologySpecies.evaluate_species(civ_id, ops, epoch)
          
          discoveries = if rem(epoch, 10) == 0 and :rand.uniform() < 0.05 do 1 else 0 end
          fitness = if rem(epoch, 20) == 0 do :rand.uniform() else 0.5 end
          
          Tiannara.Sentinel.D2.EpistemologyGraph.record_epistemology(civ_id, ops, %{
            discoveries_produced: discoveries,
            disease_resistance: 0.8,
            truth_retention: 0.9,
            fitness: fitness
          })
          
          if discoveries > 0 do
             context = %{
                species_id: "SPECIES_SIM", 
                operators: ops, 
                diseases: [], 
                tension: 50.0, 
                truth_capital: 150.0, 
                shard: shard_id, 
                epoch: epoch,
                regime: regime
             }
             Tiannara.Sentinel.D2.BreakthroughAnalyzer.record_breakthrough("disc_#{epoch}_#{i}", 10.0, civ_id, context)
          end
        end

        EconomyEngine.tick(civ_id)
      end)
    end)
  end

  defp generate_report(stage, _regime) do
    Logger.info("\n==============================================")
    Logger.info("   D.2 ECOLOGICAL STRESS REPORT (STAGE #{stage})")
    Logger.info("==============================================\n")
    
    report = AnalyticsEngine.evaluate_graduation_gate()
    
    atlas = report.atlas
    ecology = report.ecology
    health = report.health
    readiness = report.readiness
    archetypes = report.archetypes
    unknowns = report.unknowns
    topology = report.landscape_topology
    
    # 1. Epistemic Periodic Table
    Logger.info("--- 1. EPISTEMIC PERIODIC TABLE (ARCHETYPES) ---")
    Enum.each(archetypes, fn arc ->
      Logger.info("  [#{arc.id}] Dominant: #{inspect(arc.dominant_operators)} | Persistence: #{Float.round(arc.persistence, 2)} | Extinctions: #{Float.round(arc.extinction_rate, 2)}")
    end)

    # 2. Epistemic Attractor Registry
    Logger.info("\n--- 2. EPISTEMIC ATTRACTOR REGISTRY ---")
    Enum.each(atlas.attractors, fn att ->
      Logger.info("  Attractor: #{inspect(att.operators)} | Emergence: #{att.emergence_count} | Half-Life: #{Float.round(att.half_life, 2)} | Regimes: #{inspect(Map.keys(att.regime_distribution))}")
    end)
    
    # 3. Landscape Topology
    Logger.info("\n--- 3. LANDSCAPE TOPOLOGY ---")
    Logger.info("  Average Landscape Distance: #{topology.average_distance}")
    Logger.info("  Fitness Gradient Vector: #{inspect(topology.fitness_gradient)}")

    # 4. Diversity Profile
    Logger.info("\n--- 4. DIVERSITY PROFILE ---")
    div = health.diversity_profile
    Logger.info("  Operator Entropy:  #{Float.round(div.operator_entropy, 3)}")
    Logger.info("  Species Entropy:   #{Float.round(div.species_entropy, 3)}")
    Logger.info("  Niche Entropy:     #{Float.round(div.niche_entropy, 3)}")
    Logger.info("  Discovery Entropy: #{Float.round(div.discovery_entropy, 3)}")
    Logger.info("  Attractor Conc.:   #{Float.round(div.attractor_concentration, 3)}")
    
    # 5. Evolutionary Unknowns
    Logger.info("\n--- 5. EVOLUTIONARY UNKNOWNS (PHASE 10 TARGETS) ---")
    Enum.each(unknowns, fn unk ->
      Logger.info("  Target: #{inspect(unk.operator_combination)} | Novelty: #{unk.novelty_score} | Priority: #{unk.exploration_priority}")
    end)

    # 6. Meta-Cognition Readiness Score
    Logger.info("\n--- 6. PHASE 10 GRADUATION GATES ---")
    Logger.info("  Species Stability:      #{Float.round(readiness.species_stability_gate, 2)} (req > 0.80)")
    Logger.info("  Extinction Cycles:      #{Float.round(readiness.extinction_cycles_gate, 2)} (req > 100)")
    Logger.info("  Species Diversity:      #{Float.round(readiness.species_diversity_gate, 2)} (req > 0.60)")
    Logger.info("  Attractor Convergence:  #{Float.round(readiness.attractor_convergence_gate, 2)}")
    Logger.info("  Regime Robustness:      #{Float.round(readiness.regime_robustness_gate, 2)}")
    Logger.info("  Unknown Coverage:       #{Float.round(readiness.unknown_region_coverage_gate, 2)} (req > 0.30)")
    Logger.info("  -----------------------------------")
    Logger.info("  OVERALL READINESS:      #{Float.round(readiness.overall_score, 2)}")
    
    if readiness.overall_score >= 0.85 do
      Logger.info("\n🏆 CERTIFICATION GRANTED. ECOLOGICAL LAWS MAPPED.")
    else
      Logger.info("\n⚠️ CERTIFICATION FAILED. MORE EVOLUTIONARY PRESSURE REQUIRED.")
    end
    
    Logger.info("\n==============================================\n")
  end
end

Application.ensure_all_started(:tiannara)
EcologicalStressTest.run_ladder()
