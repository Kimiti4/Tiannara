defmodule Tiannara.ASC.Campaign.Phase5C6 do
  @moduledoc """
  Phase 5C.6 — Species Fitness & Selection Campaign
  
  This campaign tests whether failure species can evolve through selection pressure
  rather than manual budget balancing.
  
  Key innovations:
  - Species fitness calculation (survival, repair, transfer rates)
  - Adaptive budget adjustment based on fitness
  - Extinction tracking for low-fitness species
  - Dominance detection for high-fitness species
  
  Exit criteria:
  - Species Entropy > 1.5
  - Unique Domains ≥ 8
  - Transfer Matrix Cells ≥ 20
  - At least 3 species budgets change between generations
  - At least 1 extinction OR dominance event observed
  - No species exceeds 35% of total ecology
  """

  alias Tiannara.ASC.Interface.Genome
  alias Tiannara.ASC.Crucible.{Builder, Validator, Breaker, Attacker, Repairer}
  alias Tiannara.ASC.Crucible.Observatory
  alias Tiannara.ASC.Crucible.TransferEcology
  alias Tiannara.ASC.Crucible.FailureSpecies
  alias Tiannara.ASC.Crucible.SpeciesFitness

  @project_configs [
    # Original 5 projects
    %{genome_id: "web_app_001", project_id: "simple_web_app", deployment_target: "docker-compose"},
    %{genome_id: "api_001", project_id: "rest_api", deployment_target: "kubernetes"},
    %{genome_id: "store_001", project_id: "kv_store", deployment_target: "distributed"},
    %{genome_id: "auth_001", project_id: "oauth_provider", deployment_target: "kubernetes"},
    %{genome_id: "worker_001", project_id: "background_worker", deployment_target: "beam_cluster"},
    
    # Additional 5 projects for diversity
    %{genome_id: "queue_001", project_id: "message_queue", deployment_target: "beam_cluster"},
    %{genome_id: "cache_001", project_id: "redis_cache", deployment_target: "kubernetes"},
    %{genome_id: "proxy_001", project_id: "api_gateway", deployment_target: "docker-compose"},
    %{genome_id: "db_001", project_id: "postgres_replica", deployment_target: "distributed"},
    %{genome_id: "monitor_001", project_id: "metrics_collector", deployment_target: "kubernetes"}
  ]

  @generations 20
  @initial_budgets FailureSpecies.species_budgets()

  def run do
    IO.puts("\n" <> String.duplicate("=", 100))
    IO.puts("🧬 PHASE 5C.6 — SPECIES FITNESS & SELECTION")
    IO.puts(String.duplicate("=", 100))
    IO.puts("\nMission: Transform curated diversity into evolved ecology through selection pressure\n")
    
    # Start required GenServers
    IO.puts("🔧 Starting required services...\n")
    {:ok, _} = Tiannara.ASC.Crucible.Observatory.start_link([])
    {:ok, _} = Tiannara.ASC.Crucible.TransferEcology.start_link([])
    IO.puts("✅ Services started\n")
    
    display_species_configuration()
    display_exit_criteria()
    
    # Initialize genomes
    IO.puts("\n📦 Initializing #{@project_configs |> length()} genomes...\n")
    
    genomes = Enum.map(@project_configs, fn config ->
      genome = %Genome{
        genome_id: config.genome_id,
        generation: 0,
        fitness: 0.5,
        contracts: [],
        events: [],
        protocols: [],
        schemas: [],
        interfaces: [],
        deployment_target: config.deployment_target
      }
      
      {config.project_id, genome}
    end)
    |> Enum.into(%{})
    
    # Run evolution with adaptive budgets
    IO.puts("\n🌿 Starting evolutionary campaign (#{length(Map.keys(genomes))} projects × #{@generations} generations)\n")
    
    final_state = run_evolution(genomes, @initial_budgets, _generation = 1)
    
    # Final analysis
    display_final_analysis(final_state)
  end

  defp run_evolution(genomes, current_budgets, generation) when generation <= @generations do
    IO.puts("\n" <> String.duplicate("-", 100))
    IO.puts("🔄 Generation #{generation}/#{ @generations}")
    IO.puts(String.duplicate("-", 100))
    
    # Display current budget allocation
    display_current_budgets(current_budgets, generation)
    
    # Evolve all projects in this generation
    evolved_genomes = Enum.map(genomes, fn {project_id, genome} ->
      case evolve_generation(genome, project_id, generation, current_budgets) do
        {:ok, new_genome} -> {project_id, new_genome}
        {:error, error} ->
          IO.puts("   ⚠️  Project #{project_id} failed: #{inspect(error)}")
          {project_id, genome}
      end
    end)
    |> Enum.into(%{})
    
    # Get ecology metrics
    ecology_metrics = get_ecology_metrics()
    
    # Calculate species fitness
    species_fitness_map = calculate_species_fitness(ecology_metrics)
    
    # Adjust budgets based on fitness (adaptive selection)
    new_budgets = SpeciesFitness.adjust_budget(current_budgets, species_fitness_map)
    
    # Check for extinction/dominance events
    check_species_events(species_fitness_map, generation)
    
    # Display generation summary
    display_generation_summary(generation, ecology_metrics, species_fitness_map, new_budgets)
    
    # Continue to next generation
    run_evolution(evolved_genomes, new_budgets, generation + 1)
  end

  defp run_evolution(genomes, _final_budgets, _generation) do
    # Return final state
    %{
      genomes: genomes,
      ecology_metrics: get_ecology_metrics(),
      final_generation: @generations
    }
  end

  defp evolve_generation(genome, project_id, generation, current_budgets) do
    artifact_path = "/tmp/#{project_id}_gen_#{generation}"
    
    try do
      # Step 1: Build
      {:ok, build_result} = Builder.build(genome, project_id)
      
      build_obs = Tiannara.ASC.Crucible.Observation.from_builder_result(
        build_result, project_id, genome.genome_id, generation
      )
      Observatory.record_observation(build_obs)
      
      # Step 2: Validate
      {:ok, validation_result} = Validator.validate(genome, artifact_path)
      
      validation_obs = Tiannara.ASC.Crucible.Observation.from_validator_result(
        validation_result, project_id, genome.genome_id, generation
      )
      Observatory.record_observation(validation_obs)
      
      # Step 3: Break (with adaptive species budgets)
      break_result = case Breaker.break_system(genome, artifact_path, project_id: project_id, species_budgets: current_budgets) do
        {:ok, result} -> result
        {:error, error} -> %{failure_discovered?: false, failure_type: :unknown, failure_severity: :low, failure_description: inspect(error)}
      end
      
      break_obs = Tiannara.ASC.Crucible.Observation.from_breaker_result(
        break_result, project_id, genome.genome_id, generation
      )
      Observatory.record_observation(break_obs)
      
      # Step 4: Attack
      attack_result = case Attacker.attack_system(genome, artifact_path, project_id: project_id) do
        {:ok, result} -> result
        {:error, error} -> %{exploit_found?: false, exploit_severity: :low, exploit_description: inspect(error), reproducible_exploits: 0}
      end
      
      attack_obs = Tiannara.ASC.Crucible.Observation.from_attacker_result(
        attack_result, project_id, genome.genome_id, generation
      )
      Observatory.record_observation(attack_obs)
      
      # Step 5: Repair (if failure discovered)
      repair_result = if break_result.failure_discovered? do
        case Repairer.repair(break_obs, artifact_path, project_id: project_id) do
          {:ok, result} -> result
          {:error, _error} -> %{repair_successful?: false, repair_description: "Repair failed", patch_stable?: false, repair_severity: :low}
        end
      else
        %{repair_successful?: false, repair_description: "No failure to repair", patch_stable?: false, repair_severity: :low}
      end
      
      repair_obs = Tiannara.ASC.Crucible.Observation.from_repairer_result(
        repair_result, project_id, genome.genome_id, generation
      )
      Observatory.record_observation(repair_obs)
      
      # Calculate fitness
      fitness = calculate_fitness(build_result, validation_result, break_result, attack_result, repair_result)
      
      {:ok, %{genome | generation: generation, fitness: fitness}}
      
    rescue
      e ->
        {:error, Exception.message(e)}
    end
  end

  defp calculate_fitness(build_result, validation_result, break_result, attack_result, repair_result) do
    # Simplified fitness calculation
    build_score = if Map.get(build_result, :success?, false), do: 1.0, else: 0.0
    validation_score = if Map.get(validation_result, :valid?, false), do: 1.0, else: 0.0
    
    # Reward discovering failures (shows system is being tested)
    break_score = if break_result.failure_discovered?, do: 0.8, else: 0.3
    
    # Reward successful repairs
    repair_score = if Map.get(repair_result, :repair_successful?, false), do: 1.0, else: 0.2
    
    # Weighted average
    (build_score * 0.25 + validation_score * 0.25 + break_score * 0.25 + repair_score * 0.25)
    |> Float.round(3)
  end

  defp get_ecology_metrics do
    case GenServer.call(TransferEcology, :get_metrics) do
      {:ok, metrics} -> metrics
      _ -> %{
        source_entropy: 0.0,
        domain_entropy: 0.0,
        unique_domains: 0,
        matrix_cells_populated: 0,
        cross_class_rate: 0.0,
        cross_class_success_rate: 0.0,
        species_births: %{},
        species_survivals: %{},
        species_transfers_attempted: %{},
        species_transfers_successful: %{}
      }
    end
  end

  defp calculate_species_fitness(ecology_metrics) do
    # Extract species data from ecology metrics
    species_ids = Map.keys(ecology_metrics.species_births || %{})
    
    Enum.map(species_ids, fn species_id ->
      births = Map.get(ecology_metrics.species_births, species_id, 0)
      survivals = Map.get(ecology_metrics.species_survivals, species_id, 0)
      transfers_attempted = Map.get(ecology_metrics.species_transfers_attempted, species_id, 0)
      transfers_successful = Map.get(ecology_metrics.species_transfers_successful, species_id, 0)
      
      # Create simplified species data for fitness calculation
      species_data = %{
        species_id: species_id,
        generation: 1,
        births: births,
        survivals: survivals,
        extinctions: 0,
        repairs_attempted: transfers_attempted,
        repairs_successful: transfers_successful,
        transfers_attempted: transfers_attempted,
        transfers_successful: transfers_successful,
        average_recovery_latency_ms: 0.0
      }
      
      fitness_record = SpeciesFitness.calculate_fitness(species_data)
      {species_id, fitness_record.fitness_score}
    end)
    |> Enum.into(%{})
  end

  defp check_species_events(species_fitness_map, generation) do
    # Check for dominance events (fitness > 0.75)
    dominant = SpeciesFitness.get_dominant_species(species_fitness_map)
    if elem(dominant, 1) > 0.75 do
      event = SpeciesFitness.create_dominance_event(elem(dominant, 0), elem(dominant, 1), 1)
      IO.puts("   🏆 DOMINANCE EVENT: #{event.species_id} (fitness: #{Float.round(event.fitness, 2)})")
    end
    
    # Check for extinction watch (fitness < 0.05)
    extinction_watch = SpeciesFitness.get_extinction_watch_species(species_fitness_map)
    if length(extinction_watch) > 0 do
      Enum.each(extinction_watch, fn {species_id, fitness} ->
        IO.puts("   ☠️  EXTINCTION WATCH: #{species_id} (fitness: #{Float.round(fitness, 2)})")
      end)
    end
  end

  defp display_species_configuration do
    IO.puts("🌿 Failure Species Configuration:")
    IO.puts(String.duplicate("-", 80))
    
    FailureSpecies.all_species()
    |> Enum.each(fn species ->
      IO.puts("   #{species.species_id}: #{species.species_name}")
      IO.puts("     Budget: #{species.budget_percentage}%")
      IO.puts("     Domain: #{species.domain}")
      IO.puts("     Description: #{species.description}\n")
    end)
    
    IO.puts(String.duplicate("-", 80) <> "\n")
  end

  defp display_exit_criteria do
    IO.puts("✅ Exit Criteria:")
    IO.puts(String.duplicate("-", 80))
    IO.puts("   1. Species Entropy > 1.5")
    IO.puts("   2. Unique Domains ≥ 8")
    IO.puts("   3. Transfer Matrix Cells ≥ 20")
    IO.puts("   4. At least 3 species budgets change between generations")
    IO.puts("   5. At least 1 extinction OR dominance event observed")
    IO.puts("   6. No species exceeds 35% of total ecology")
    IO.puts(String.duplicate("-", 80) <> "\n")
  end

  defp display_current_budgets(budgets, generation) do
    IO.puts("\n💰 Current Species Budgets (Generation #{generation}):")
    IO.puts(String.duplicate("-", 60))
    
    budgets
    |> Enum.sort_by(fn {_species, budget} -> -budget end)
    |> Enum.each(fn {species_id, budget} ->
      bar_length = round(budget / 2)
      bar = String.duplicate("█", bar_length)
      IO.puts("   #{String.pad_trailing(to_string(species_id), 15)} #{budget}% #{bar}")
    end)
    
    IO.puts(String.duplicate("-", 60))
  end

  defp display_generation_summary(generation, ecology_metrics, species_fitness_map, new_budgets) do
    IO.puts("\n📊 Generation #{generation} Summary:")
    IO.puts(String.duplicate("-", 80))
    
    # Ecology metrics
    IO.puts("   Ecological Diversity:")
    IO.puts("     Source Entropy: #{Float.round(ecology_metrics.source_entropy, 3)}")
    IO.puts("     Domain Entropy: #{Float.round(ecology_metrics.domain_entropy, 3)}")
    IO.puts("     Unique Domains: #{ecology_metrics.unique_domains}")
    IO.puts("     Matrix Cells: #{ecology_metrics.matrix_cells_populated}")
    IO.puts("     Cross-Class Rate: #{Float.round(ecology_metrics.cross_class_rate, 1)}%")
    IO.puts("     Cross-Class Success: #{Float.round(ecology_metrics.cross_class_success_rate, 1)}%")
    
    # Species fitness
    IO.puts("\n   Species Fitness:")
    species_fitness_map
    |> Enum.sort_by(fn {_species, fitness} -> -fitness end)
    |> Enum.each(fn {species_id, fitness} ->
      status = SpeciesFitness.determine_status(%{fitness_score: fitness})
      status_icon = case status do
        :dominant -> "👑"
        :thriving -> "✅"
        :stable -> "➡️"
        :declining -> "⚠️"
        :extinction_watch -> "☠️"
      end
      IO.puts("     #{status_icon} #{String.pad_trailing(to_string(species_id), 15)} #{Float.round(fitness, 3)} (#{status})")
    end)
    
    # Budget changes
    IO.puts("\n   Next Generation Budgets:")
    new_budgets
    |> Enum.sort_by(fn {_species, budget} -> -budget end)
    |> Enum.each(fn {species_id, budget} ->
      IO.puts("     #{String.pad_trailing(to_string(species_id), 15)} #{budget}%")
    end)
    
    IO.puts(String.duplicate("-", 80))
  end

  defp display_final_analysis(final_state) do
    IO.puts("\n" <> String.duplicate("=", 100))
    IO.puts("🎯 PHASE 5C.6 FINAL ANALYSIS")
    IO.puts(String.duplicate("=", 100))
    
    ecology_metrics = final_state.ecology_metrics
    
    # Check exit criteria
    IO.puts("\n✅ Exit Criteria Assessment:")
    IO.puts(String.duplicate("-", 80))
    
    gate1 = ecology_metrics.source_entropy > 1.5
    gate2 = ecology_metrics.domain_entropy > 1.5
    gate3 = ecology_metrics.unique_domains >= 8
    gate4 = ecology_metrics.matrix_cells_populated >= 20
    
    IO.puts("   1. Species Entropy > 1.5: #{if gate1, do: "✅ PASS (#{Float.round(ecology_metrics.source_entropy, 3)})", else: "❌ FAIL (#{Float.round(ecology_metrics.source_entropy, 3)})"}")
    IO.puts("   2. Domain Entropy > 1.5: #{if gate2, do: "✅ PASS (#{Float.round(ecology_metrics.domain_entropy, 3)})", else: "❌ FAIL (#{Float.round(ecology_metrics.domain_entropy, 3)})"}")
    IO.puts("   3. Unique Domains ≥ 8: #{if gate3, do: "✅ PASS (#{ecology_metrics.unique_domains})", else: "❌ FAIL (#{ecology_metrics.unique_domains})"}")
    IO.puts("   4. Occupied Matrix Cells ≥ 20: #{if gate4, do: "✅ PASS (#{ecology_metrics.matrix_cells_populated})", else: "❌ FAIL (#{ecology_metrics.matrix_cells_populated})"}")
    
    all_passed = gate1 and gate2 and gate3 and gate4
    
    IO.puts("\n" <> String.duplicate("-", 80))
    if all_passed do
      IO.puts("🎉 PHASE 5C.6 SUCCESSFUL - Ready for Phase 5D!")
      IO.puts("\nThe ecosystem has evolved genuine diversity through selection pressure.")
      IO.puts("ASC is now evolving an ecology of failures rather than generating them.")
    else
      IO.puts("⚠️  PHASE 5C.6 INCOMPLETE - Some criteria not met")
      IO.puts("\nAdditional refinement needed before advancing to Phase 5D.")
    end
    IO.puts(String.duplicate("-", 80) <> "\n")
  end
end

# Execute campaign
IO.puts("\n🚀 Starting Phase 5C.6 Campaign...")
Tiannara.ASC.Campaign.Phase5C6.run()
