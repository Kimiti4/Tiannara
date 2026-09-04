defmodule Tiannara.ASC.Crucible.EvolutionCampaign do
  @moduledoc """
  Phase 4.6 — Longitudinal Evolution Campaign

  Runs evolutionary cycles to generate adaptation trajectories for law discovery.

  Scale:
  - 5 Projects × 20 Generations = 100 Project-Generations
  - Target: 1,000+ Observations
  - Target: 300+ Failures
  - Target: 100+ Repairs
  - Target: 50+ Exploits

  Key Innovation:
  Instead of measuring static artifacts (what breaks), measures software adaptation
  (what survives and how it evolves). This provides the longitudinal data needed
  for scientific law discovery.

  Evolutionary Loop per Project:
    Build → Validate → Break → Attack → Repair → Update Genome → Generation +1

  New Metrics Tracked:
  - Adaptation Velocity: Fitness(t+1) - Fitness(t)
  - Recovery Half-Life: Time to recover 50% of lost fitness
  - Failure Recurrence Rate: Same failure reappears after repair
  - Repair Transferability: Repair from Project A works in Project B

  Expected First Laws:
  - "Explicit invariants reduce failure recurrence"
  - "Knowledge reuse improves repair success"
  - "High interface complexity predicts exploit density"
  - "Recovery capability predicts survivability"

  Success Criteria:
  - Generate sufficient generational data for pattern detection
  - Track adaptation trajectories across 20 generations
  - Discover 10-20 candidate laws from temporal patterns
  - Establish 3-6 established laws with supporting evidence
  - Falsify 2-8 laws (scientific rigor!)
  """

  alias Tiannara.ASC.Crucible.{Builder, Validator, Breaker, Attacker, Observatory, RepairReuseEngine}
  alias Tiannara.ASC.Interface.Genome

  # Test genome configurations for 5 diverse projects
  @project_configs [
    %{genome_id: "web_app_001", project_id: "simple_web_app", deployment_target: "docker-compose"},
    %{genome_id: "api_001", project_id: "rest_api", deployment_target: "kubernetes"},
    %{genome_id: "store_001", project_id: "kv_store", deployment_target: "distributed"},
    %{genome_id: "auth_001", project_id: "oauth_provider", deployment_target: "kubernetes"},
    %{genome_id: "worker_001", project_id: "background_worker", deployment_target: "beam_cluster"}
  ]

  @max_generations 20

  @doc """
  Run the complete Evolution Alpha Campaign.

  ## Returns
  - {:ok, epoch} with campaign results
  """
  def run do
    IO.puts("\n🧬🧬🧬 Starting EVOLUTION ALPHA CAMPAIGN 🧬🧬🧬")
    IO.puts("Scale: 5 projects × #{@max_generations} generations = #{length(@project_configs) * @max_generations} project-generations")
    IO.puts("Target: 1,000+ observations, 300+ failures, 100+ repairs, 50+ exploits")
    IO.puts("Focus: Longitudinal adaptation trajectories for law discovery\n")

    # Bootstrap full ASC Runtime (Phase 5C.7)
    Tiannara.ASC.Runtime.bootstrap()

    # Start Repair Ecology Engine (Phase 4.8)
    {:ok, _ecology_pid} = Tiannara.ASC.Crucible.RepairEcology.RepairEcologyEngine.start_link()
    IO.puts("✅ Repair Ecology Engine started (Phase 4.8)\n")

    # Start Repair Phylogeny Engine (Phase 4.9)
    {:ok, _phylogeny_pid} = Tiannara.ASC.Crucible.RepairPhylogeny.RepairPhylogenyEngine.start_link()
    IO.puts("🌳 Repair Phylogeny Engine started (Phase 4.9)\n")

    # Generate initial genomes
    initial_genomes = generate_initial_genomes()

    IO.puts("📊 Processing #{length(initial_genomes)} projects through #{@max_generations} generations...\n")

    # Process each project through evolutionary cycles
    all_results = @project_configs
      |> Enum.with_index(1)
      |> Enum.map(fn {config, project_idx} ->
      IO.puts("\n" <> String.duplicate("=", 70))
      IO.puts("🧬 Project #{project_idx + 1}/#{length(initial_genomes)}: #{config.genome_id}")
      IO.puts(String.duplicate("=", 70))

      evolve_project(config)
    end)

    # Flatten all generation results
    all_generations = Enum.flat_map(all_results, fn {_project_id, generations} -> generations end)

    # Phase 4.8 - Run Repair Ecology Engine
    # TODO: Fix RepairEcology/RepairPhylogeny GenServer lifecycle issues
    # These are Phase 4.8/4.9 features, not Phase 5 Core
    # IO.puts("\n🌱 Running Repair Ecology Engine (Phase 4.8)...")
    # all_patterns = Tiannara.ASC.Crucible.RepairLibrary.list_all_patterns()
    # all_project_ids = Enum.map(@project_configs, & &1.project_id)
    # 
    # case Tiannara.ASC.Crucible.RepairEcology.RepairEcologyEngine.run_epoch(
    #   "evolution_alpha_001",
    #   @max_generations,
    #   all_patterns,
    #   all_project_ids
    # ) do
    #   {:ok, ecology_results} ->
    #     IO.puts("✅ Repair Ecology completed")
    #     IO.inspect(ecology_results, label: "Ecology Results")
    #     
    #     # Phase 4.9 - Run Repair Phylogeny Engine
    #     IO.puts("\n🌳 Running Repair Phylogeny Engine (Phase 4.9)...")
    #     species_map = get_species_map_from_ecology(ecology_results)
    #     
    #     case Tiannara.ASC.Crucible.RepairPhylogeny.RepairPhylogenyEngine.run_epoch(
    #       "evolution_alpha_001",
    #       @max_generations,
    #       all_patterns,
    #       all_project_ids,
    #       species_map
    #     ) do
    #       {:ok, phylogeny_results} ->
    #         IO.puts("✅ Repair Phylogeny completed")
    #         IO.inspect(phylogeny_results, label: "Phylogeny Results")
    #       {:error, error} ->
    #         IO.puts("⚠️  Repair Phylogeny failed: #{inspect(error)}")
    #     end
    #   {:error, error} ->
    #     IO.puts("⚠️  Repair Ecology failed: #{inspect(error)}")
    # end

    # Finalize epoch with all observations
    IO.puts("\n📊 Finalizing epoch...")
    total_generations = length(all_generations)
    {:ok, epoch} = Observatory.finalize_epoch("evolution_alpha_001", total_generations)

    IO.puts("\n🌍 Phase 5E: Minting Transfer Ecology Laws...")
    Tiannara.ASC.Laws.Discoverer.discover_transfer_ecology_laws()

    # Print comprehensive summary
    print_evolution_summary(epoch, all_results)

    {:ok, epoch}
  end

  # Removed ensure_observatory_started in favor of Tiannara.ASC.Runtime.bootstrap()

  defp generate_initial_genomes do
    Enum.map(@project_configs, fn config ->
      %Genome{
        genome_id: config.genome_id,
        generation: 1,
        deployment_target: config.deployment_target
      }
    end)
  end

  @doc """
  Evolve a single project through multiple generations.

  For each generation:
  1. Run full Crucible loop (Build → Validate → Break → Attack → Repair)
  2. Calculate fitness from results
  3. Update genome based on adaptations
  4. Increment generation counter
  5. Repeat until max_generations reached

  ## Returns
  - {project_id, [generation_results]}
  """
  def evolve_project(config) do
    current_genome = %Genome{
      genome_id: config.genome_id,
      generation: 1,
      deployment_target: config.deployment_target
    }

    project_id = config.project_id

    # Track adaptation trajectory
    adaptation_trajectory = Enum.reduce(1..@max_generations, [], fn generation, acc ->
      IO.puts("\n  🔄 Generation #{generation}/#{@max_generations}")

      # Run full Crucible loop for this generation
      result = run_generation(current_genome, project_id, generation)

      # Calculate fitness from results
      fitness = calculate_fitness(result)

      # Log fitness trend
      IO.puts("     📈 Fitness: #{Float.round(fitness * 100, 1)}%")

      # Record adaptation velocity metrics (Phase 5.3)
      reuse_metrics = RepairReuseEngine.get_reuse_metrics()
      
      # Extract repair success rate from result map
      repair_success_rate = 
        case Map.get(result, :repair) do
          %RepairReuseEngine{repair_successful?: success} -> if success, do: 1.0, else: 0.0
          _ -> 0.0
        end
      
      Tiannara.ASC.Crucible.AdaptationVelocity.record_generation(generation, %{
        avg_success_rate: repair_success_rate,
        knowledge_reuse_rate: reuse_metrics.knowledge_reuse_rate,
        transfer_success_rate: reuse_metrics.transfer_success_rate || 0.0
      })

      # Update genome for next generation (simulate evolution)
      current_genome = evolve_genome(current_genome, result, generation)

      # Store generation result
      gen_result = Map.merge(result, %{
        generation: generation,
        fitness: fitness,
        genome_id: current_genome.genome_id
      })

      [gen_result | acc]
    end)

    {project_id, Enum.reverse(adaptation_trajectory)}
  end

  @doc """
  Run one generation of the Crucible loop.

  Executes: Build → Validate → Break → Attack → Repair
  Returns comprehensive results for fitness calculation.
  """
  def run_generation(genome, project_id, generation) do
    artifact_path = "/tmp/#{project_id}_gen_#{generation}"

    # Step 1: Build
    build_result = case Builder.build(genome, project_id) do
      {:ok, result} -> result
    end

    # Step 2: Validate
    validation_result = case Validator.validate(genome, project_id) do
      {:ok, result} -> result
    end

    # Step 3: Break
    break_result = case Breaker.break_system(genome, artifact_path, project_id: project_id) do
      {:ok, result} -> result
    end

    # Step 4: Attack
    attack_result = case Attacker.attack_system(genome, artifact_path, project_id: project_id) do
      {:ok, result} -> result
    end

    # Step 5: Repair (use Repair Reuse Engine for knowledge-based repair)
    repair_result = if break_result && break_result.failure_discovered? do
      failure_obs = %Tiannara.ASC.Crucible.Observation{
        id: "failure_#{break_result.break_id}",
        project_id: project_id,
        genome_id: genome.genome_id,
        source: :breaker,
        observation_type: :failure,
        severity: break_result.failure_severity || :medium,
        origin: :implementation,
        reproducible: true,
        confidence: 0.8,
        evidence: [break_result.failure_description || "Breaker discovered failure"],
        timestamp: DateTime.utc_now(),
        generation: generation
      }

      case RepairReuseEngine.repair_failure(failure_obs, artifact_path) do
        {:ok, result} -> result
      end
    else
      nil
    end

    %{
      project_id: project_id,
      genome_id: genome.genome_id,
      generation: generation,
      build: build_result,
      validation: validation_result,
      break: break_result,
      attack: attack_result,
      repair: repair_result
    }
  end

  @doc """
  Calculate fitness score from generation results.

  Fitness is multi-objective:
  - Build success contributes positively
  - Validation pass contributes positively
  - Fewer failures is better (survival pressure)
  - Fewer exploits is better (security)
  - Successful repairs contribute positively (adaptation)

  Returns: 0.0 to 1.0 fitness score
  """
  def calculate_fitness(result) do
    weights = %{
      build_success: 0.2,
      validation_pass: 0.2,
      no_failures: 0.2,
      no_exploits: 0.2,
      repair_success: 0.2
    }

    # Build success (0 or 1)
    build_score = if result.build && result.build.success?, do: 1.0, else: 0.0

    # Validation pass (0 or 1)
    validation_score = if result.validation && result.validation.valid?, do: 1.0, else: 0.0

    # No failures (0 or 1)
    failure_score = if result.break && !result.break.failure_discovered?, do: 1.0, else: 0.0

    # No exploits (0 or 1)
    exploit_score = if result.attack && !result.attack.exploit_found?, do: 1.0, else: 0.0

    # Repair success (0, 0.5, or 1)
    repair_score = cond do
      result.repair == nil -> 0.5  # No repair needed = neutral
      result.repair.repair_successful? -> 1.0
      true -> 0.0
    end

    weighted_sum = (
      weights.build_success * build_score +
      weights.validation_pass * validation_score +
      weights.no_failures * failure_score +
      weights.no_exploits * exploit_score +
      weights.repair_success * repair_score
    )

    Float.round(weighted_sum, 3)
  end

  @doc """
  Evolve genome based on generation results.

  Simulates genetic algorithm evolution:
  - If repair succeeded, incorporate repair knowledge into genome
  - If failures/exploits found, increase mutation rate
  - Increment generation counter
  - Update genome ID to reflect new generation

  In future, this will use actual genetic operators (crossover, mutation).
  For now, simulates evolution by updating metadata.
  """
  def evolve_genome(current_genome, result, generation) do
    # Calculate mutation pressure based on failures and exploits
    _mutation_pressure = calculate_mutation_pressure(result)

    # Create evolved genome
    %Genome{
      current_genome
      | genome_id: "#{current_genome.genome_id}_g#{generation + 1}",
        generation: generation + 1,
        blueprints_used: add_blueprint_if_repaired(current_genome.blueprints_used, result),
        policies_applied: add_policy_if_vulnerable(current_genome.policies_applied, result)
    }
  end

  defp calculate_mutation_pressure(result) do
    pressure = 0.0

    pressure = if result.break && result.break.failure_discovered? do
      pressure + 0.3
    else
      pressure
    end

    pressure = if result.attack && result.attack.exploit_found? do
      pressure + 0.3
    else
      pressure
    end

    pressure = if result.repair && result.repair.repair_successful? do
      pressure - 0.2
    else
      pressure
    end

    max(0.0, min(1.0, pressure))
  end

  defp add_blueprint_if_repaired(blueprints, result) do
    if result.repair && result.repair.repair_successful? do
      ["repair_pattern_#{:rand.uniform(100)}" | blueprints]
    else
      blueprints
    end
  end

  defp add_policy_if_vulnerable(policies, result) do
    policies = if result.attack && result.attack.exploit_found? do
      ["security_hardening_#{:rand.uniform(100)}" | policies]
    else
      policies
    end

    if result.break && result.break.failure_discovered? do
      ["robustness_improvement_#{:rand.uniform(100)}" | policies]
    else
      policies
    end
  end

  defp print_evolution_summary(epoch, all_results) do
    IO.puts("\n" <> String.duplicate("=", 70))
    IO.puts("📈 EVOLUTION ALPHA CAMPAIGN SUMMARY")
    IO.puts(String.duplicate("=", 70))

    # Project statistics
    IO.puts("\nProjects Tested: #{length(all_results)}")
    IO.puts("Total Generations: #{epoch.projects_tested}")
    IO.puts("Total Observations: #{epoch.total_observations}")

    # Observation breakdown by source (not available in epoch struct, skip for now)
    # TODO: Add observations field to Epoch struct
    IO.puts("\nObservations by Source: (data not available in epoch struct)")

    # Aggregate statistics across all generations
    all_generations = Enum.flat_map(all_results, fn {_project_id, generations} -> generations end)

    failures = Enum.count(all_generations, fn r -> r.break && r.break.failure_discovered? end)
    exploits = Enum.count(all_generations, fn r -> r.attack && r.attack.exploit_found? end)
    repairs_attempted = Enum.count(all_generations, fn r -> r.repair != nil end)
    repairs_successful = Enum.count(all_generations, fn r -> r.repair && r.repair.repair_successful? end)

    IO.puts("\nFailures Discovered: #{failures}")
    IO.puts("Exploits Discovered: #{exploits}")
    IO.puts("Repairs Attempted: #{repairs_attempted}")
    IO.puts("Repairs Successful: #{repairs_successful}")

    # Repair Reuse metrics (Phase 4.7)
    reuse_metrics = RepairReuseEngine.get_reuse_metrics()
    IO.puts("\n🔄 Repair Reuse Metrics (Phase 4.7):")
    IO.puts("  Reuse Attempts: #{reuse_metrics.reuse_attempts}")
    IO.puts("  Reuse Successes: #{reuse_metrics.reuse_successes}")
    IO.puts("  Reuse Failures: #{reuse_metrics.reuse_failures}")
    IO.puts("  Knowledge Reuse Rate: #{Float.round(reuse_metrics.knowledge_reuse_rate * 100, 1)}%")

    # Repair Library stats
    pattern_count = Tiannara.ASC.Crucible.RepairLibrary.pattern_count()
    high_conf_patterns = length(Tiannara.ASC.Crucible.RepairLibrary.high_confidence_patterns())
    transferable_patterns = length(Tiannara.ASC.Crucible.RepairLibrary.transferable_patterns())
    IO.puts("\n📚 Repair Library:")
    IO.puts("  Total Patterns: #{pattern_count}")
    IO.puts("  High Confidence (>0.7): #{high_conf_patterns}")
    IO.puts("  Transferable (>0.5): #{transferable_patterns}")

    # Repair Transfer stats
    transfer_count = Tiannara.ASC.Crucible.RepairTransfer.transfer_count()
    transfer_rate = Tiannara.ASC.Crucible.RepairTransfer.transfer_success_rate()
    IO.puts("\n📤 Repair Transfers:")
    IO.puts("  Total Transfers: #{transfer_count}")
    IO.puts("  Transfer Success Rate: #{Float.round(transfer_rate * 100, 1)}%")

    # Law discovery results
    IO.puts("\nLaw Candidates Generated: #{length(epoch.candidate_laws)}")
    IO.puts("Established Laws: #{length(epoch.established_laws)}")
    IO.puts("Falsified Laws: #{length(Map.get(epoch, :falsified_laws, []))}")

    # Survival metrics
    IO.puts("\nSurvival Rate: #{Float.round(epoch.survival_rate * 100, 1)}%")
    IO.puts("Failure Rate: #{Float.round(epoch.failure_rate * 100, 1)}%")
    IO.puts("Exploit Rate: #{Float.round(epoch.exploit_rate * 100, 1)}%")
    IO.puts("Repair Success Rate: #{Float.round(epoch.repair_success_rate * 100, 1)}%")

    # Knowledge metrics
    IO.puts("\nLearning Yield: #{Float.round(epoch.learning_yield, 3)}")
    IO.puts("Knowledge Compression Ratio: #{Float.round(epoch.knowledge_compression_ratio, 1)}")
    IO.puts("Principle Stability: #{Float.round(epoch.principle_stability, 3)}")

    # Adaptation metrics
    IO.puts("\nAdaptation Velocity: #{Float.round(epoch.adaptation_velocity, 3)}")
    IO.puts("Exploit Recurrence Rate: #{Float.round(epoch.exploit_recurrence_rate * 100, 1)}%")
    IO.puts("Knowledge Reuse Rate: #{Float.round(epoch.knowledge_reuse_rate * 100, 1)}%")

    # Print adaptation trajectories for each project
    IO.puts("\n" <> String.duplicate("-", 70))
    IO.puts("ADAPTATION TRAJECTORIES")
    IO.puts(String.duplicate("-", 70))

    for {project_id, generations} <- all_results do
      IO.puts("\n🧬 #{project_id}:")
      print_adaptation_trajectory(generations)
    end

    # Campaign success assessment
    IO.puts("\n" <> String.duplicate("-", 70))
    
    # Phase 5 Core Metrics Summary
    IO.puts("\n📊 PHASE 5 CORE METRICS SUMMARY")
    IO.puts(String.duplicate("-", 70))
    
    # Get adaptation velocity summary
    velocity_summary = Tiannara.ASC.Crucible.AdaptationVelocity.get_summary()
    
    IO.puts("\n📈 Adaptation Velocity:")
    case velocity_summary do
      %{adaptation_velocity: velocity, trend: trend} when is_number(velocity) ->
        IO.puts("   Velocity: #{Float.round(velocity * 100, 3)}% per generation")
        IO.puts("   Trend: #{Atom.to_string(trend) |> String.upcase()}")
        
        if velocity > 0 do
          IO.puts("   ✅ EXIT CRITERION MET - System is adapting!")
        else
          IO.puts("   ⚠️  Exit criterion not met - velocity ≤ 0")
        end
      _ ->
        IO.puts("   Insufficient data for velocity calculation")
    end
    
    # Get reuse metrics
    reuse_metrics = RepairReuseEngine.get_reuse_metrics()
    IO.puts("\n🔄 Knowledge Reuse:")
    IO.puts("   Reuse Rate: #{Float.round(reuse_metrics.knowledge_reuse_rate * 100, 2)}%")
    IO.puts("   Total Attempts: #{reuse_metrics.reuse_attempts}")
    IO.puts("   Total Successes: #{reuse_metrics.reuse_successes}")
    
    if reuse_metrics.knowledge_reuse_rate > 0.10 do
      IO.puts("   ✅ EXIT CRITERION MET (>10%)")
    else
      IO.puts("   ⚠️  Exit criterion not met (target: >10%)")
    end
    
    IO.puts("\n🌍 Knowledge Transfer:")
    IO.puts("   Transfer Count: #{reuse_metrics.transfer_count}")
    IO.puts("   Transfer Success Rate: #{Float.round(reuse_metrics.transfer_success_rate * 100, 2)}%")
    
    if reuse_metrics.transfer_count > 0 and reuse_metrics.transfer_success_rate > 0.05 do
      IO.puts("   ✅ EXIT CRITERION MET (>5% success rate)")
    else
      IO.puts("   ⚠️  Exit criterion not met (target: >5%)")
    end
    
    IO.puts("\n" <> String.duplicate("-", 70))
    if length(epoch.candidate_laws) > 0 do
      IO.puts("✅ EVOLUTION ALPHA SUCCESS - Candidate laws discovered!")
      IO.puts("   Longitudinal data enabled pattern detection")
    else
      IO.puts("⚠️  EVOLUTION ALPHA PARTIAL - Infrastructure validated")
      IO.puts("   Need more generations or different thresholds for law discovery")
    end
    IO.puts(String.duplicate("=", 70))
  end

  defp print_adaptation_trajectory(generations) do
    # Print fitness over time
    fitness_values = Enum.map(generations, & &1.fitness)
    IO.puts("  Fitness trajectory: #{Enum.join(Enum.map(fitness_values, &Float.round(&1 * 100, 1)), " → ")}%")

    # Calculate adaptation velocity (average change per generation)
    if length(fitness_values) >= 2 do
      changes = Enum.chunk_every(fitness_values, 2, 1, :discard)
        |> Enum.map(fn [prev, curr] -> curr - prev end)

      avg_velocity = Enum.sum(changes) / length(changes)
      IO.puts("  Adaptation velocity: #{Float.round(avg_velocity * 100, 2)}%/gen")

      # Calculate recovery half-life (if applicable)
      low_points = Enum.filter(Enum.with_index(fitness_values), fn {fitness, _idx} -> fitness < 0.5 end)
      if length(low_points) > 0 do
        IO.puts("  Low fitness events: #{length(low_points)}")
      end
    end

    # Count failures, exploits, repairs
    failures = Enum.count(generations, fn r -> r.break && r.break.failure_discovered? end)
    exploits = Enum.count(generations, fn r -> r.attack && r.attack.exploit_found? end)
    repairs = Enum.count(generations, fn r -> r.repair && r.repair.repair_successful? end)

    IO.puts("  Summary: #{failures} failures, #{exploits} exploits, #{repairs} successful repairs")
  end

end
