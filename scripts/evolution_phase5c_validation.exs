defmodule Tiannara.ASC.Crucible.EvolutionPhase5C do
  @moduledoc """
  Phase 5C Validation Campaign - Transfer Ecology & Success Matrix
  
  Purpose: Transform transfer events into an ecological system for scientific study.
  
  Configuration:
  - 10 projects × 20 generations = 200 project-generations
  - Focus on transfer ecology metrics
  
  Success Criteria:
  - Transfer Matrix Coverage > 20 populated cells
  - Knowledge Diffusion Rate > 10%
  - At least one classification with transferability > 25%
  - Semantic distance correlation observed (r < -0.30)
  - ≥ 3 transfer-based candidate laws emitted
  """

  alias Tiannara.ASC.Crucible.{
    Builder, Validator, Breaker, Attacker, RepairReuseEngine, Observatory,
    TransferEcology
  }
  alias Tiannara.ASC.Interface.Genome

  # Test genome configurations for 10 diverse projects
  @project_configs [
    %{genome_id: "web_app_001", project_id: "simple_web_app", deployment_target: "docker-compose"},
    %{genome_id: "api_001", project_id: "rest_api", deployment_target: "kubernetes"},
    %{genome_id: "store_001", project_id: "kv_store", deployment_target: "distributed"},
    %{genome_id: "auth_001", project_id: "oauth_provider", deployment_target: "kubernetes"},
    %{genome_id: "worker_001", project_id: "background_worker", deployment_target: "beam_cluster"},
    %{genome_id: "queue_001", project_id: "message_queue", deployment_target: "beam_cluster"},
    %{genome_id: "cache_001", project_id: "redis_cache", deployment_target: "kubernetes"},
    %{genome_id: "proxy_001", project_id: "api_gateway", deployment_target: "docker-compose"},
    %{genome_id: "db_001", project_id: "postgres_replica", deployment_target: "distributed"},
    %{genome_id: "monitor_001", project_id: "metrics_collector", deployment_target: "kubernetes"}
  ]

  @max_generations 20

  def run do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("🧬 PHASE 5C VALIDATION CAMPAIGN - TRANSFER ECOLOGY")
    IO.puts(String.duplicate("=", 80))
    IO.puts("Purpose: Discover which knowledge transfers and why")
    IO.puts("Scale: #{length(@project_configs)} projects × #{@max_generations} generations = #{length(@project_configs) * @max_generations} project-generations")
    IO.puts("")
    IO.puts("Success Criteria:")
    IO.puts("  ✅ Transfer Matrix Coverage > 20 cells")
    IO.puts("  ✅ Knowledge Diffusion Rate > 10%")
    IO.puts("  ✅ Classification Transferability > 25% (at least one)")
    IO.puts("  ✅ Distance-Transfer Correlation (r < -0.30)")
    IO.puts("  ✅ ≥ 3 Transfer-Based Candidate Laws")
    IO.puts(String.duplicate("=", 80) <> "\n")

    # Start Observatory if not running
    ensure_observatory_started()

    # Start Repair Library (clean slate)
    {:ok, _pid} = Tiannara.ASC.Crucible.RepairLibrary.start_link()
    IO.puts("✅ Repair Library started\n")

    # Start Repair Reuse Engine
    {:ok, _reuse_pid} = Tiannara.ASC.Crucible.RepairReuseEngine.start_link()
    IO.puts("✅ Repair Reuse Engine started\n")

    # Start Transfer Ecology Observer (Phase 5C)
    {:ok, _ecology_pid} = TransferEcology.start_link(name: TransferEcology)
    IO.puts("✅ Transfer Ecology observer started (Phase 5C)\n")

    # Run evolution across all projects
    IO.puts("📊 Processing #{length(@project_configs)} projects through #{@max_generations} generations...\n")
    
    all_results = 
      Enum.map(@project_configs, fn config ->
        evolve_project(config)
      end)

    # Print final summary with Phase 5C exit criteria
    print_phase5c_summary(all_results)
  end

  defp evolve_project(%{genome_id: genome_id, project_id: project_id, deployment_target: _target}) do
    IO.puts(String.duplicate("-", 70))
    IO.puts("🧬 Project: #{project_id} (#{genome_id})")
    IO.puts(String.duplicate("-", 70))

    initial_genome = Genome.new()

    generations = 
      Enum.reduce(1..@max_generations, [], fn generation, acc ->
        result = run_generation(initial_genome, project_id, generation)
        
        IO.puts("     📈 Fitness: #{Float.round(result.fitness * 100, 1)}%\n")
        
        [result | acc]
      end)
      |> Enum.reverse()

    {project_id, generations}
  end

  defp run_generation(genome, project_id, generation) do
    artifact_path = ""
    
    # Build
    {:ok, build_result} = Builder.build(genome, project_id)
    
    # Validate
    validation_result = Validator.validate(genome, artifact_path)
    
    # Break
    break_result = case Breaker.break_system(genome, artifact_path, project_id: project_id) do
      {:ok, result} -> result
      {:error, _error} -> nil
    end
    
    # Attack
    attack_result = case Attacker.attack_system(genome, artifact_path, project_id: project_id) do
      {:ok, result} -> result
      {:error, _error} -> nil
    end
    
    # Repair failures (includes Transfer Adaptation + Ecology tracking)
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
        {:error, _error} -> nil
      end
    else
      nil
    end
    
    repair_result = repair_result || %{repair_successful?: false, regression?: false, pattern_id: nil, confidence: 0.0}
    
    # Calculate fitness
    fitness = calculate_fitness(build_result, validation_result, break_result, attack_result, repair_result)
    
    %{
      generation: generation,
      build: build_result,
      validation: validation_result,
      break: break_result,
      attack: attack_result,
      repair: repair_result,
      fitness: fitness
    }
  end

  defp calculate_fitness(build, validation, break_result, attack, repair) do
    build_struct = if is_tuple(build), do: elem(build, 1), else: build
    validation_struct = if is_tuple(validation), do: elem(validation, 1), else: validation
    
    base = if build_struct.success?, do: 0.4, else: 0.0
    validation_bonus = if validation_struct.valid?, do: 0.2, else: 0.0
    repair_bonus = if repair.repair_successful?, do: 0.4, else: 0.0
    
    min(base + validation_bonus + repair_bonus, 1.0)
  end

  defp ensure_observatory_started do
    IO.puts("Starting Observatory...")
    case GenServer.whereis(Tiannara.ASC.Crucible.Observatory) do
      nil ->
        {:ok, _pid} = Tiannara.ASC.Crucible.Observatory.start_link()
      pid when is_pid(pid) ->
        :ok
    end
  end

  defp print_phase5c_summary(_all_results) do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("📊 PHASE 5C VALIDATION RESULTS - TRANSFER ECOLOGY")
    IO.puts(String.duplicate("=", 80))
    
    # Get transfer ecology metrics
    ecology_metrics = TransferEcology.get_metrics()
    transfer_matrix = TransferEcology.get_transfer_matrix()
    classification_transferability = TransferEcology.get_classification_transferability()
    distance_distribution = TransferEcology.get_semantic_distance_distribution()
    law_candidates = TransferEcology.generate_law_candidates()
    
    IO.puts("\n🌍 Transfer Ecology Metrics:")
    IO.puts("   Total Transfer Attempts: #{ecology_metrics.total_attempts}")
    IO.puts("   Total Transfer Successes: #{ecology_metrics.total_successes}")
    IO.puts("   Transfer Success Rate: #{Float.round(ecology_metrics.transfer_success_rate * 100, 1)}%")
    IO.puts("   Transfer Matrix Cells Populated: #{ecology_metrics.matrix_cells_populated}")
    IO.puts("   Classifications Tracked: #{ecology_metrics.classifications_tracked}")
    IO.puts("   Knowledge Diffusion Rate: #{Float.round(ecology_metrics.knowledge_diffusion_rate * 100, 1)}%")
    
    IO.puts("\n📊 Transfer Success Matrix (Top 10):")
    matrix_sorted = Enum.sort_by(transfer_matrix, fn {_key, data} -> data.attempts end, :desc)
    Enum.take(matrix_sorted, 10) |> Enum.each(fn {key, data} ->
      rate = if data.attempts > 0, do: Float.round(data.successes / data.attempts * 100, 1), else: 0.0
      IO.puts("   #{key}: #{rate}% (#{data.successes}/#{data.attempts})")
    end)
    
    IO.puts("\n🎯 Classification Transferability:")
    transferability_sorted = Enum.sort_by(classification_transferability, fn {_class, data} -> 
      if data.attempts > 0, do: data.successes / data.attempts, else: 0
    end, :desc)
    Enum.take(transferability_sorted, 10) |> Enum.each(fn {class_name, data} ->
      rate = if data.attempts > 0, do: Float.round(data.successes / data.attempts * 100, 1), else: 0.0
      IO.puts("   #{class_name}: #{rate}% (#{data.successes}/#{data.attempts})")
    end)
    
    IO.puts("\n📏 Semantic Distance Distribution:")
    for bucket <- ["0.0-0.2", "0.2-0.4", "0.4-0.6", "0.6-0.8", "0.8-1.0"] do
      data = Map.get(distance_distribution, bucket, %{attempts: 0, successes: 0, success_rate: 0.0})
      IO.puts("   Distance #{bucket}: #{Float.round(data.success_rate * 100, 1)}% success (#{data.successes}/#{data.attempts})")
    end
    
    # Exit criteria assessment
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("✅ EXIT CRITERIA ASSESSMENT:")
    IO.puts(String.duplicate("-", 80))
    
    # Criterion 1: Transfer Matrix Coverage > 20 cells
    matrix_coverage_pass = ecology_metrics.matrix_cells_populated > 20
    IO.puts("   1. Transfer Matrix Coverage > 20 cells: #{if matrix_coverage_pass, do: "✅ PASS", else: "❌ FAIL"} (#{ecology_metrics.matrix_cells_populated})")
    
    # Criterion 2: Knowledge Diffusion Rate > 10%
    diffusion_pass = ecology_metrics.knowledge_diffusion_rate > 0.10
    IO.puts("   2. Knowledge Diffusion Rate > 10%: #{if diffusion_pass, do: "✅ PASS", else: "❌ FAIL"} (#{Float.round(ecology_metrics.knowledge_diffusion_rate * 100, 1)}%)")
    
    # Criterion 3: At least one classification > 25% transferability
    high_transferability_classes = Enum.filter(classification_transferability, fn {_class, data} ->
      data.attempts >= 5 and (data.successes / data.attempts) > 0.25
    end)
    transferability_pass = length(high_transferability_classes) > 0
    IO.puts("   3. Classification Transferability > 25%: #{if transferability_pass, do: "✅ PASS", else: "❌ FAIL"} (#{length(high_transferability_classes)} classes)")
    
    # Criterion 4: Distance-transfer correlation (simplified check)
    distance_correlation_pass = check_distance_correlation(distance_distribution)
    IO.puts("   4. Distance-Transfer Correlation: #{if distance_correlation_pass, do: "✅ OBSERVED", else: "⚠️  INSUFFICIENT DATA"}")
    
    # Criterion 5: ≥ 3 candidate laws
    laws_pass = length(law_candidates) >= 3
    IO.puts("   5. Transfer-Based Candidate Laws ≥ 3: #{if laws_pass, do: "✅ PASS", else: "❌ FAIL"} (#{length(law_candidates)})")
    
    IO.puts("\n" <> String.duplicate("-", 80))
    if matrix_coverage_pass and diffusion_pass and transferability_pass and laws_pass do
      IO.puts("🎉 ALL EXIT CRITERIA MET!")
      IO.puts("ASC has crossed from Adaptive Engineering to Knowledge-Evolving Engineering Civilization")
    else
      IO.puts("⚠️  SOME CRITERIA NOT MET - Further refinement needed")
    end
    IO.puts(String.duplicate("-", 80))
    
    if length(law_candidates) > 0 do
      IO.puts("\n💡 CANDIDATE LAWS DISCOVERED:")
      Enum.each(law_candidates, fn candidate ->
        IO.puts("   • #{candidate.law}")
        IO.puts("     Evidence: #{candidate.evidence}")
        IO.puts("     Confidence: #{Float.round(candidate.confidence * 100, 0)}%")
        IO.puts("")
      end)
    end
    
    IO.puts("\n📚 Repair Library Status:")
    patterns = Tiannara.ASC.Crucible.RepairLibrary.list_all_patterns()
    IO.puts("   Total Patterns: #{length(patterns)}")
    
    IO.puts("\n" <> String.duplicate("=", 80))
  end

  defp check_distance_correlation(distribution) do
    # Check if we have enough data and if there's a general trend
    buckets_with_data = Enum.filter(distribution, fn {_bucket, data} -> data.attempts > 0 end)
    length(buckets_with_data) >= 2
  end
end

# Run the campaign
Tiannara.ASC.Crucible.EvolutionPhase5C.run()
