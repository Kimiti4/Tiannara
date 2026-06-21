defmodule Tiannara.ASC.MetaScience.MetaScienceCampaign do
  @moduledoc """
  Phase 7: The Meta-Science Campaign.
  
  Runs the complete evolutionary loop on research methodologies:
  1. Execute each genome's research epoch
  2. Measure real telemetry deltas
  3. Calculate fitness from empirical results
  4. Evolve the population (reproduce, mutate, speciate, extinct)
  5. Repeat
  """
  
  alias Tiannara.ASC.MetaScience.{ResearchGenome, GenomeDrivenExecutor, ProgramEvolutionEngine}
  alias Tiannara.ASC.Runtime
  require Logger

  @epochs 8
  @total_budget_per_epoch 5000

  def run do
    Logger.info("🔬🔬🔬 [Phase 7] INITIATING META-SCIENCE CAMPAIGN 🔬🔬🔬")
    Logger.info("Epochs: #{@epochs} | Budget/Epoch: #{@total_budget_per_epoch}")
    :ok = Runtime.bootstrap()
    
    # 1. Seed the initial population with pure methodology genomes
    initial_population = [
      ResearchGenome.seed("Transfer Physics", :transfer_physics, :targeted_experimentation),
      ResearchGenome.seed("Repair Ecology", :repair_ecology, :brute_force_mutation),
      ResearchGenome.seed("Architecture Evolution", :architecture, :meta_learning)
    ]
    
    # 2. Run the evolutionary loop
    final_population = Enum.reduce(1..@epochs, initial_population, fn epoch, population ->
      Logger.info("\n#{String.duplicate("=", 70)}")
      Logger.info("🧬 [Phase 7] META-SCIENCE EPOCH #{epoch}")
      Logger.info(String.duplicate("=", 70))
      
      # Execute each genome's epoch and calculate fitness
      evaluated_population = Enum.map(population, fn genome ->
        execute_and_evaluate(genome, @total_budget_per_epoch, length(population))
      end)
      
      # Report epoch results
      report_epoch_results(epoch, evaluated_population)
      
      # Evolve the population
      ProgramEvolutionEngine.evolve_population(evaluated_population)
    end)
    
    # 3. Final report
    generate_final_report(final_population)
    
    # 4. Store surviving genomes for Phase 8A Engineering
    active = Enum.filter(final_population, &(&1.status == :active))
    Tiannara.ASC.Research.ResearchRegistry.store_surviving_genomes(active)
  end

  defp execute_and_evaluate(%ResearchGenome{} = genome, budget, total_population) do
    # Allocate budget proportional to current fitness (with minimum)
    effective_budget = max(trunc(budget / max(total_population, 1)), trunc(budget * 0.1))
    
    # Execute the genome-driven research epoch
    delta = GenomeDrivenExecutor.execute_epoch(genome, effective_budget)
    
    # Calculate fitness from real telemetry using advanced Phase 7 equation
    fitness = calculate_fitness(genome, delta)
    
    # Track starvation
    is_starving = delta.laws_generated == 0 and delta.utility_generated == 0.0 and Map.get(delta, :information_gain, 0.0) == 0.0
    
    %{genome |
      fitness: fitness,
      epochs_starving: if(is_starving, do: genome.epochs_starving + 1, else: 0),
      total_utility_generated: genome.total_utility_generated + delta.utility_generated
    }
  end

  defp calculate_fitness(_genome, delta) do
    # Extract components
    utility = delta.utility_generated
    information_gain = Map.get(delta, :information_gain, 0.0)
    law_impact = Map.get(delta, :law_impact_gain, 0.0)
    survival = delta.canonical_generated * 100.0 # Base metric for law survival
    novelty = delta.patterns_discovered * 10.0
    
    # The new user-provided fitness equation
    fitness = (0.35 * utility) + 
              (0.25 * information_gain) + 
              (0.20 * law_impact) + 
              (0.10 * survival) + 
              (0.10 * novelty)
    
    # Penalize compute waste slightly
    compute_penalty = if delta.compute_consumed > 0 do
      fitness / delta.compute_consumed
    else
      0.0
    end
    
    Float.round(fitness + compute_penalty, 2)
  end

  defp report_epoch_results(epoch, population) do
    sorted = Enum.sort_by(population, & &1.fitness, :desc)
    
    Logger.info("📊 [Phase 7] Epoch #{epoch} Fitness Rankings:")
    Enum.with_index(sorted, 1) |> Enum.each(fn {genome, rank} ->
      status_icon = case genome.status do
        :active -> "🟢"
        :dormant -> "🟡"
        :extinct -> "💀"
      end
      
      Logger.info("  #{status_icon} ##{rank} #{genome.name} (Gen #{genome.generation})")
      Logger.info("      Fitness: #{genome.fitness} | Utility: #{Float.round(genome.total_utility_generated, 1)}")
      Logger.info("      Starvation: #{genome.epochs_starving} epochs | Alive: #{genome.epochs_alive}")
      Logger.info("      Domains: #{inspect(genome.domain_weights)}")
      Logger.info("      Methods: #{inspect(genome.methodology_blend)}")
    end)
  end

  defp generate_final_report(population) do
    active = Enum.filter(population, & &1.status == :active)
    extinct = Enum.filter(population, & &1.status == :extinct)
    
    Logger.info("""
    
    #{String.duplicate("=", 70)}
    🔬🔬🔬 PHASE 7: META-SCIENCE FINAL REPORT 🔬🔬🔬
    #{String.duplicate("=", 70)}
    
    POPULATION SUMMARY
    ----------------------------------------------------------------------
    Active Genomes: #{length(active)}
    Extinct Genomes: #{length(extinct)}
    Max Generation: #{Enum.max_by(population, & &1.generation).generation}
    
    SURVIVING METHODOLOGIES
    ----------------------------------------------------------------------
    """)
    
    active
    |> Enum.sort_by(& &1.fitness, :desc)
    |> Enum.each(fn genome ->
      Logger.info("""
      🧬 #{genome.name} (Generation #{genome.generation})
         Lineage: #{inspect(genome.lineage)}
         Fitness: #{genome.fitness}
         Total Utility: #{Float.round(genome.total_utility_generated, 1)}
         Total Compute: #{genome.total_compute_consumed}
         ROI: #{safe_roi(genome)}
         
         Domain Weights: #{format_map(genome.domain_weights)}
         Methodology Blend: #{format_map(genome.methodology_blend)}
         Exploration: #{Float.round(genome.exploration_bias, 2)} | Risk: #{Float.round(genome.risk_tolerance, 2)}
      """)
    end)
    
    Logger.info("""
    
    META-SCIENTIFIC DISCOVERIES
    ----------------------------------------------------------------------
    """)
    
    # Identify emergent patterns
    if length(active) > 0 do
      winner = Enum.max_by(active, & &1.fitness)
      Logger.info("🏆 Most Fit Methodology: '#{winner.name}' (Gen #{winner.generation})")
      Logger.info("   This methodology blend produced the highest empirical utility:")
      Logger.info("   Domains: #{format_map(winner.domain_weights)}")
      Logger.info("   Methods: #{format_map(winner.methodology_blend)}")
    end
    
    # Check for speciation events
    hybrids = Enum.filter(active, fn g -> g.name =~ "Hybrid" end)
    if length(hybrids) > 0 do
      Logger.info("\n🌟 SPECIATION EVENTS: #{length(hybrids)} hybrid methodologies emerged")
      Enum.each(hybrids, fn h ->
        Logger.info("   - #{h.name} (Gen #{h.generation})")
      end)
    end
    
    # Check for extinctions
    if length(extinct) > 0 do
      Logger.info("\n💀 EXTINCTIONS: #{length(extinct)} methodologies died")
      Enum.each(extinct, fn e ->
        Logger.info("   - #{e.name} (survived #{e.epochs_alive} epochs)")
      end)
    end
    
    Logger.info(String.duplicate("=", 70))
  end

  defp safe_roi(genome) do
    if genome.total_compute_consumed > 0 do
      Float.round(genome.total_utility_generated / genome.total_compute_consumed, 3)
    else
      0.0
    end
  end

  defp format_map(map) do
    map
    |> Enum.map(fn {k, v} -> "#{k}: #{Float.round(v, 2)}" end)
    |> Enum.join(", ")
  end
end
