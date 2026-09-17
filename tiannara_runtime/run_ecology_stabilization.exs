alias Tiannara.Core.WorldModel.EntityRegistry
alias Tiannara.REL.EconomyEngine
alias Tiannara.ROS.EvolutionEngine
alias Tiannara.Sentinel.D2.AnalyticsEngine
require Logger

defmodule EcologyStabilization do
  @moduledoc "Phase 9.8 Simulation Script for empirical epistemic landscape discovery."

  @operators [
    "causal", "empirical", "counterfactual",
    "recursive", "analogical", "adversarial",
    "symbolic", "formal", "abductive"
  ]

  def run_stage(stage, civ_count, shard_count, epochs) do
    Logger.info("\n=== INITIATING PHASE 9.8 CONSTITUTIONAL CERTIFICATION (STAGE #{stage}) ===")
    Logger.info("🔒 CONSTITUTIONAL FREEZE: Meta-Operators, Mutations, Synthesis, and Pruning DISABLED.")
    Logger.info("Parameters: #{civ_count} Civs, #{shard_count} Shards, #{epochs} Epochs")

    shards = Enum.map(1..shard_count, &"shard_#{stage}_#{&1}")

    Logger.info("1. Spawning Shards...")
    Enum.each(shards, fn shard ->
      Tiannara.ROS.ShardManager.spawn_shard(shard)
    end)

    Logger.info("2. Seeding Civilizations...")
    seed_civilizations(civ_count, shards)

    Logger.info("3. Simulating Epochs (This will take time)...")
    simulate_epochs(civ_count, shards, epochs)

    Logger.info("4. Generating D.2 Empirical Report...")
    generate_report(stage)
  end

  defp seed_civilizations(count, shards) do
    Enum.each(1..count, fn i ->
      civ_id = "civ_#{i}"
      shard_id = Enum.random(shards)
      
      # Select a random subset of 2-4 operators to form the baseline genome
      genome = Enum.take_random(@operators, Enum.random(2..4))
      
      # Mock the entity registration
      EntityRegistry.register_entity(%{
        id: civ_id,
        type: :civilization,
        name: "Civilization #{i}",
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

  defp simulate_epochs(civ_count, shards, epochs) do
    # For performance in the mock run, we batch process
    # We will simulate the ticking of the economy engine
    # In reality, this would just be calling EconomyEngine.tick for every civ
    Enum.each(1..epochs, fn epoch ->
      if rem(epoch, 1000) == 0 do
        Logger.info("... Simulated #{epoch} Epochs")
      end

      Enum.each(1..civ_count, fn i ->
        civ_id = "civ_#{i}"
        
        # Pull current state
        shard_id = Enum.random(shards)
        ops = case EntityRegistry.get_entity(civ_id, shard_id) do
          {:ok, ent} -> Map.get(ent.attributes, :active_operators, [])
          _ -> []
        end
        
        if ops != [] do
          Tiannara.Sentinel.D2.EpistemologySpecies.evaluate_species(civ_id, ops, epoch)
          
          # Simulate outcomes
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
                epoch: epoch
             }
             Tiannara.Sentinel.D2.BreakthroughAnalyzer.record_breakthrough("disc_#{epoch}_#{i}", 10.0, civ_id, context)
          end
        end

        # We tick the economy which inherently triggers Speciation/Extinction checks under the hood
        EconomyEngine.tick(civ_id)
      end)
    end)
  end

  defp generate_report(stage) do
    Logger.info("\n==============================================")
    Logger.info("   D.2 CONSTITUTIONAL CERTIFICATION REPORT (STAGE #{stage})")
    Logger.info("==============================================\n")
    
    # Run the comprehensive analytics engine
    report = AnalyticsEngine.evaluate_graduation_gate()
    
    atlas = report.atlas
    ecology = report.ecology
    health = report.health
    readiness = report.readiness
    
    # 1. Species Atlas
    Logger.info("--- 1. SPECIES ATLAS ---")
    Logger.info("Dominant Species: #{length(atlas.dominant_species)}")
    Enum.each(atlas.dominant_species, fn sp -> 
       Logger.info("  #{sp.id}: Ops: #{inspect(sp.operators)} (Persistence: #{sp.metrics.active_duration} epochs)")
    end)
    Logger.info("Extinct Species: #{length(atlas.extinct_species)}")
    
    # 2. Operator Ecology Matrix
    Logger.info("\n--- 2. OPERATOR ECOLOGY MATRIX ---")
    Logger.info("Total Synergistic Pairs: #{map_size(ecology.synergies)}")
    ecology.synergies
      |> Enum.sort_by(fn {_p, s} -> s.synergy end, :desc)
      |> Enum.take(3)
      |> Enum.each(fn {{a, b}, score} -> Logger.info("  Synergy: #{a} ↔ #{b} (#{score.synergy})") end)
      
    Logger.info("Total Antagonistic Pairs: #{map_size(ecology.antagonisms)}")
    ecology.antagonisms
      |> Enum.sort_by(fn {_p, s} -> s.antagonism end, :asc)
      |> Enum.take(3)
      |> Enum.each(fn {{a, b}, score} -> Logger.info("  Antagonism: #{a} ✕ #{b} (#{score.antagonism})") end)
      
    # 3. Epistemic Attractor Registry
    Logger.info("\n--- 3. EPISTEMIC ATTRACTOR REGISTRY ---")
    Enum.each(atlas.attractors, fn att ->
      Logger.info("  Attractor: #{inspect(att.operators)} | Emergence: #{att.emergence_count} | Breakthrough Rate: #{Float.round(att.breakthrough_rate, 3)}")
    end)
    
    # 4. Ecosystem Health Certification
    Logger.info("\n--- 4. ECOSYSTEM HEALTH CERTIFICATION ---")
    Logger.info("  Species Diversity: #{Float.round(health.species_diversity, 3)}")
    Logger.info("  Operator Entropy: #{Float.round(health.operator_entropy, 3)}")
    Logger.info("  Breakthrough Velocity: #{health.breakthrough_velocity}")
    Logger.info("  Extinction Velocity: #{health.extinction_velocity}")
    if health.species_diversity > 0.1 and health.breakthrough_velocity > 0 do
      Logger.info("  ✅ ECOSYSTEM DIVERSITY THRESHOLDS MET")
    else
      Logger.info("  ❌ ECOSYSTEM DIVERSITY THRESHOLDS FAILED (Stagnation Detected)")
    end
    
    # 5. Meta-Cognition Readiness Score
    Logger.info("\n--- 5. PHASE 10 READINESS SCORE ---")
    Logger.info("  Operator Landscape:     #{Float.round(readiness.operator_landscape_confidence, 2)}")
    Logger.info("  Species Stability:      #{Float.round(readiness.species_stability_confidence, 2)}")
    Logger.info("  Attractor Detection:    #{Float.round(readiness.attractor_confidence, 2)}")
    Logger.info("  Ecology Diversity:      #{Float.round(readiness.ecology_diversity_confidence, 2)}")
    Logger.info("  -----------------------------------")
    Logger.info("  OVERALL READINESS:      #{Float.round(readiness.overall_score, 2)}")
    
    if readiness.overall_score >= 0.85 do
      Logger.info("\n🏆 CERTIFICATION GRANTED. TIANNARA IS READY FOR PHASE 10 META-COGNITION.")
    else
      Logger.info("\n⚠️ CERTIFICATION FAILED. ECOSYSTEM REQUIRES MORE OBSERVATION.")
    end
    
    Logger.info("\n==============================================\n")
  end
end

# We need to start the application before running
Application.ensure_all_started(:tiannara)

# Run Stage 1 (Shrunk slightly for faster interactive simulation, user can scale up in production)
EcologyStabilization.run_stage(1, 100, 5, 2000)
