defmodule EvolutionPhase5C5 do
  @moduledoc """
  Phase 5C.5 — Failure Species Expansion Campaign

  Goal: Increase ecological diversity until transfer ecology becomes fully populated.

  Exit Criteria:
  - Classification Entropy > 1.5
  - Domain Entropy > 1.5
  - Unique Domains >= 8
  - Matrix Cells >= 20
  - Cross-Class Transfer >= 15%
  - Cross-Class Success >= 5%

  This campaign uses the new FailureSpecies module to guarantee diverse failure generation
  across all ecological niches, replacing keyword-based inference with explicit species budgets.
  """

  alias Tiannara.ASC.Crucible.{
    Builder,
    Validator,
    Breaker,
    Attacker,
    Repairer,
    Observatory,
    RepairLibrary,
    RepairReuseEngine,
    TransferEcology,
    FailureSpecies
  }

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

  def run do
    IO.puts("\n🧬 PHASE 5C.5 VALIDATION CAMPAIGN - FAILURE SPECIES EXPANSION")
    IO.puts("================================================================================\n")

    # Start required services
    {:ok, _obs_pid} = Tiannara.ASC.Crucible.Observatory.start_link()
    IO.puts("✅ Observatory started\n")

    {:ok, _library_pid} = Tiannara.ASC.Crucible.RepairLibrary.start_link()
    IO.puts("✅ Repair Library started\n")

    {:ok, _reuse_pid} = Tiannara.ASC.Crucible.RepairReuseEngine.start_link()
    IO.puts("✅ Repair Reuse Engine started\n")

    # Start Transfer Ecology Observer (Phase 5C)
    {:ok, _ecology_pid} = TransferEcology.start_link(name: TransferEcology)
    IO.puts("✅ Transfer Ecology observer started (Phase 5C)\n")

    # Display species configuration
    display_species_configuration()

    # Run evolution campaign
    project_results = Enum.map(@project_configs, fn config ->
      run_project_evolution(config)
    end)

    # Print final results
    print_phase5c5_summary(project_results)
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

  defp run_project_evolution(config) do
    %{genome_id: genome_id, project_id: project_id, deployment_target: deployment_target} = config

    IO.puts("\n🔬 Evolving Project: #{project_id} (#{genome_id})")
    IO.puts(String.duplicate("-", 80))

    # Create initial genome
    genome = %Tiannara.ASC.Interface.Genome{
      genome_id: genome_id,
      generation: 0,
      fitness: 0.5,
      contracts: [],
      events: [],
      protocols: [],
      schemas: [],
      interfaces: [],
      deployment_target: deployment_target
    }

    # Run evolution for specified generations
    Enum.reduce(1..@generations, genome, fn gen, current_genome ->
      evolved_genome = evolve_generation(current_genome, project_id, gen)
      %{evolved_genome | generation: gen}
    end)

    %{project_id: project_id, final_generation: @generations}
  end

  defp evolve_generation(genome, project_id, generation) do
    artifact_path = "/tmp/#{project_id}_gen_#{generation}"

    # Step 1: Build
    {:ok, build_result} = Builder.build(genome, project_id)

    # Record build observation
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

    # Step 3: Break (Phase 5C.5 - Species-driven failure generation)
    break_result = case Breaker.break_system(genome, artifact_path, project_id: project_id) do
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

    # Return evolved genome (simplified - in real system would use selection/mutation)
    %{genome | generation: generation}
  end

  defp calculate_fitness(build, validation, _break_result, _attack, repair) do
    # Simple fitness calculation
    build_score = if build.success?, do: 1.0, else: 0.0
    validation_score = if validation.valid?, do: 1.0, else: 0.0
    repair_score = if repair.repair_successful?, do: 0.8, else: 0.2

    (build_score + validation_score + repair_score) / 3.0
  end

  defp print_phase5c5_summary(_project_results) do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("📊 PHASE 5C.5 VALIDATION RESULTS - FAILURE SPECIES EXPANSION")
    IO.puts(String.duplicate("=", 80) <> "\n")

    # Get Transfer Ecology metrics
    ecology_metrics = TransferEcology.get_metrics()
    transfer_matrix = TransferEcology.get_transfer_matrix()
    classification_transferability = TransferEcology.get_classification_transferability()
    distance_distribution = TransferEcology.get_semantic_distance_distribution()
    law_candidates = TransferEcology.generate_law_candidates()

    success_rate = if ecology_metrics.total_attempts > 0, do: Float.round(ecology_metrics.total_successes / ecology_metrics.total_attempts * 100, 1), else: 0.0
    diffusion_rate = if ecology_metrics.total_attempts > 0, do: Float.round(ecology_metrics.knowledge_diffusion_rate * 100, 1), else: 0.0

    IO.puts("🌍 Transfer Ecology Metrics:")
    IO.puts("   Total Transfer Attempts: #{ecology_metrics.total_attempts}")
    IO.puts("   Total Transfer Successes: #{ecology_metrics.total_successes}")
    IO.puts("   Transfer Success Rate: #{success_rate}%")
    IO.puts("   Knowledge Diffusion Rate: #{diffusion_rate}%\n")

    IO.puts("🎯 Ecological Diversity Metrics:")
    IO.puts("   Unique Source Classes: #{ecology_metrics.unique_source_classes}")
    IO.puts("   Unique Target Classes: #{ecology_metrics.unique_target_classes}")
    IO.puts("   Source Entropy: #{ecology_metrics.source_entropy}")
    IO.puts("   Target Entropy: #{ecology_metrics.target_entropy}\n")

    IO.puts("🌿 Domain Ecology (Phase 5C.5):")
    IO.puts("   Unique Domains: #{ecology_metrics.unique_domains}")
    IO.puts("   Domain Entropy: #{ecology_metrics.domain_entropy}")
    IO.puts("   Domain Distribution:")
    ecology_metrics.domain_distribution
    |> Enum.sort_by(fn {_domain, count} -> count end, :desc)
    |> Enum.each(fn {domain, count} ->
      pct = if ecology_metrics.total_attempts > 0, do: Float.round(count / ecology_metrics.total_attempts * 100, 1), else: 0.0
      IO.puts("     - #{domain}: #{count} (#{pct}%)")
    end)
    IO.puts("")

    IO.puts("📊 Transfer Matrix Analysis:")
    IO.puts("   Occupied Cells: #{ecology_metrics.matrix_cells_populated}")
    IO.puts("   Matrix Density: #{ecology_metrics.matrix_density}%\n")

    IO.puts("🔄 Cross-Class Transfer Analysis:")
    IO.puts("   Same-Class Transfers: #{ecology_metrics.same_class_transfers} (#{ecology_metrics.same_class_rate}%)")
    IO.puts("   Cross-Class Transfers: #{ecology_metrics.cross_class_transfers} (#{ecology_metrics.cross_class_rate}%)")
    IO.puts("   Cross-Class Success Rate: #{ecology_metrics.cross_class_success_rate}%\n")

    IO.puts("📊 Transfer Success Matrix (Top 15):")
    transfer_matrix
    |> Enum.sort_by(fn {_key, data} -> data.attempts end, :desc)
    |> Enum.take(15)
    |> Enum.each(fn {matrix_key, data} ->
      rate = if data.attempts > 0, do: Float.round(data.successes / data.attempts * 100, 1), else: 0.0
      IO.puts("   #{matrix_key}: #{rate}% (#{data.successes}/#{data.attempts})")
    end)
    IO.puts("")

    IO.puts("🎯 Classification Transferability:")
    classification_transferability
    |> Enum.sort_by(fn {_class, data} -> (data.successes / max(data.attempts, 1)) end, :desc)
    |> Enum.each(fn {class_name, data} ->
      rate = if data.attempts > 0, do: Float.round(data.successes / data.attempts * 100, 1), else: 0.0
      IO.puts("   #{class_name}: #{rate}% (#{data.successes}/#{data.attempts})")
    end)
    IO.puts("")

    IO.puts("📏 Semantic Distance Distribution:")
    distance_distribution
    |> Enum.sort_by(fn {bucket, _data} -> bucket end)
    |> Enum.each(fn {bucket, data} ->
      rate = if data.attempts > 0, do: Float.round(data.successes / data.attempts * 100, 1), else: 0.0
      IO.puts("   Distance #{bucket}: #{rate}% success (#{data.successes}/#{data.attempts})")
    end)
    IO.puts("")

    # Calculate correlation
    correlation_result = TransferEcology.calculate_semantic_distance_correlation()
    correlation = correlation_result.correlation
    IO.puts("📈 Distance-Transfer Correlation: r = #{Float.round(correlation, 2)}\n")

    IO.puts(String.duplicate("-", 80))
    IO.puts("✅ EXIT CRITERIA ASSESSMENT (Phase 5C.5):")
    IO.puts(String.duplicate("-", 80))

    gate1 = ecology_metrics.source_entropy > 1.5
    gate2 = ecology_metrics.domain_entropy > 1.5
    gate3 = ecology_metrics.unique_domains >= 8
    gate4 = ecology_metrics.matrix_cells_populated >= 20
    gate5 = ecology_metrics.cross_class_rate >= 15
    gate6 = ecology_metrics.cross_class_success_rate >= 5

    IO.puts("   1. Classification Entropy > 1.5: #{if gate1, do: "✅ PASS (#{ecology_metrics.source_entropy})", else: "❌ FAIL (#{ecology_metrics.source_entropy})"}")
    IO.puts("   2. Domain Entropy > 1.5: #{if gate2, do: "✅ PASS (#{ecology_metrics.domain_entropy})", else: "❌ FAIL (#{ecology_metrics.domain_entropy})"}")
    IO.puts("   3. Unique Domains >= 8: #{if gate3, do: "✅ PASS (#{ecology_metrics.unique_domains})", else: "❌ FAIL (#{ecology_metrics.unique_domains})"}")
    IO.puts("   4. Occupied Matrix Cells >= 20: #{if gate4, do: "✅ PASS (#{ecology_metrics.matrix_cells_populated})", else: "❌ FAIL (#{ecology_metrics.matrix_cells_populated})"}")
    IO.puts("   5. Cross-Class Transfer Rate >= 15%: #{if gate5, do: "✅ PASS (#{Float.round(ecology_metrics.cross_class_rate, 1)}%)", else: "❌ FAIL (#{Float.round(ecology_metrics.cross_class_rate, 1)}%)"}")
    IO.puts("   6. Cross-Class Success Rate >= 5%: #{if gate6, do: "✅ PASS (#{Float.round(ecology_metrics.cross_class_success_rate, 1)}%)", else: "❌ FAIL (#{Float.round(ecology_metrics.cross_class_success_rate, 1)}%)"}")
    IO.puts("")

    all_passed = gate1 and gate2 and gate3 and gate4 and gate5 and gate6

    if all_passed do
      IO.puts(String.duplicate("-", 80))
      IO.puts("🎉 ALL EXIT CRITERIA MET - Phase 5C.5 SUCCESSFUL!")
      IO.puts("   Ready to advance to Phase 5D - Knowledge Fitness & Adaptive Selection")
      IO.puts(String.duplicate("-", 80))
    else
      IO.puts(String.duplicate("-", 80))
      IO.puts("⚠️  SOME CRITERIA NOT MET - Further refinement needed")
      IO.puts(String.duplicate("-", 80))
    end

    IO.puts("\n💡 CANDIDATE LAWS DISCOVERED:")
    law_candidates
    |> Enum.each(fn law ->
      IO.puts("   • #{law.name}")
      IO.puts("     Evidence: #{law.evidence}")
      IO.puts("     Confidence: #{Float.round(law.confidence * 100, 1)}%\n")
    end)

    IO.puts("📚 Repair Library Status:")
    library_stats = RepairLibrary.get_stats()
    IO.puts("   Total Patterns: #{Map.get(library_stats, :total_patterns, 0)}\n")

    IO.puts(String.duplicate("=", 80) <> "\n")
  end
end

# Run the campaign
EvolutionPhase5C5.run()
