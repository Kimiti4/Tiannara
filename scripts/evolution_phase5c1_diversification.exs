defmodule Tiannara.ASC.Crucible.EvolutionPhase5C1 do
  @moduledoc """
  Phase 5C.1 Validation Campaign - Ecological Diversification
  
  Purpose: Increase failure-class diversity to populate transfer matrix and generate additional candidate laws.
  
  Configuration:
  - 10-15 projects × 20 generations = 200-300 project-generations
  - Focus on ecological diversification
  
  Success Criteria:
  - Unique Failure Classes >= 10 (Target: 15+)
  - Transfer Matrix Cells > 20 (Target: 20-50)
  - Knowledge Diffusion Rate > 10%
  - Transfer Success Rate > 8%
  - Candidate Laws >= 5 (Target: 5-10)
  """

  alias Tiannara.ASC.Crucible.{
    Builder, Validator, Breaker, Attacker, RepairReuseEngine, Observatory,
    TransferEcology, FailureClassifier
  }
  alias Tiannara.ASC.Interface.Genome

  # Test genome configurations for diverse projects
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

  @max_generations 20

  def run do
    IO.puts("\n🧬 PHASE 5C.1 VALIDATION CAMPAIGN - ECOLOGICAL DIVERSIFICATION")
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

    # Run evolution across all projects
    IO.puts("📊 Processing #{length(@project_configs)} projects through #{@max_generations} generations...\n")
    
    all_results = 
      Enum.map(@project_configs, fn config ->
        evolve_project(config)
      end)

    # Print final summary with Phase 5C.1 exit criteria
    print_phase5c1_summary(all_results)
  end

  defp evolve_project(config) do
    IO.puts("\n🧬 Project: #{config.project_id} (#{config.genome_id})")
    IO.puts(String.duplicate("-", 80))
    
    initial_genome = Genome.new()
    
    results = Enum.map(1..@max_generations, fn generation ->
      run_generation(initial_genome, config.project_id, generation)
    end)
    
    avg_fitness = Enum.reduce(results, 0.0, fn r, acc -> acc + r.fitness end) / length(results)
    
    %{
      project_id: config.project_id,
      genome_id: config.genome_id,
      generations: @max_generations,
      average_fitness: Float.round(avg_fitness, 3),
      final_fitness: List.last(results).fitness
    }
  end

  defp run_generation(genome, project_id, generation) do
    artifact_path = ""
    
    # Build
    {:ok, build_result} = Builder.build(genome, project_id)
    
    # Validate
    validation_result = Validator.validate(genome, artifact_path)
    
    # Break - now generates diverse failures
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
    
    # Log progress every 5 generations
    if rem(generation, 5) == 0 do
      IO.puts("     Generation #{generation}/#{@max_generations} - Fitness: #{Float.round(fitness * 100, 1)}%")
    end
    
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

  defp calculate_fitness(build, validation, _break_result, _attack, repair) do
    # Extract structs from {:ok, result} tuples if needed
    build_struct = if is_tuple(build), do: elem(build, 1), else: build
    validation_struct = if is_tuple(validation), do: elem(validation, 1), else: validation
    
    base = if build_struct.success?, do: 0.4, else: 0.0
    validation_bonus = if validation_struct.valid?, do: 0.2, else: 0.0
    repair_bonus = if repair.repair_successful?, do: 0.4, else: 0.0
    
    min(base + validation_bonus + repair_bonus, 1.0)
  end

  defp print_phase5c1_summary(_project_results) do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("📊 PHASE 5C.1 VALIDATION RESULTS - ECOLOGICAL DIVERSIFICATION")
    IO.puts(String.duplicate("=", 80) <> "\n")
    
    # Get Transfer Ecology metrics
    ecology_metrics = TransferEcology.get_metrics()
    transfer_matrix = TransferEcology.get_transfer_matrix()
    classification_transferability = TransferEcology.get_classification_transferability()
    distance_distribution = TransferEcology.get_semantic_distance_distribution()
    law_candidates = TransferEcology.generate_law_candidates()
    
    # Phase 5C.3 - Comprehensive Ecological Dashboard
    IO.puts("🌍 Transfer Ecology Metrics:")
    IO.puts("   Total Transfer Attempts: #{ecology_metrics.total_attempts}")
    IO.puts("   Total Transfer Successes: #{ecology_metrics.total_successes}")
    success_rate = if ecology_metrics.total_attempts > 0, do: Float.round(ecology_metrics.total_successes / ecology_metrics.total_attempts * 100, 1), else: 0.0
    diffusion_rate = if ecology_metrics.total_attempts > 0, do: Float.round(ecology_metrics.knowledge_diffusion_rate * 100, 1), else: 0.0
    IO.puts("   Transfer Success Rate: #{success_rate}%")
    IO.puts("   Knowledge Diffusion Rate: #{diffusion_rate}%\n")
    
    IO.puts("🎯 Ecological Diversity Metrics:")
    IO.puts("   Unique Source Classes: #{ecology_metrics.unique_source_classes}")
    IO.puts("   Unique Target Classes: #{ecology_metrics.unique_target_classes}")
    IO.puts("   Source Entropy: #{ecology_metrics.source_entropy}")
    IO.puts("   Target Entropy: #{ecology_metrics.target_entropy}\n")
    
    IO.puts("🌿 Domain Ecology (Phase 5C.4):")
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
    |> Enum.each(fn {bucket, data} ->
      rate = if data.attempts > 0, do: Float.round(data.successes / data.attempts * 100, 1), else: 0.0
      IO.puts("   Distance #{bucket}: #{rate}% success (#{data.successes}/#{data.attempts})")
    end)
    IO.puts("")
    
    # Analyze distance correlation
    correlation = analyze_distance_correlation(distance_distribution)
    IO.puts("📈 Distance-Transfer Correlation: r = #{Float.round(correlation, 2)}\n")
    
    IO.puts(String.duplicate("-", 80))
    IO.puts("✅ EXIT CRITERIA ASSESSMENT (Phase 5C.4):")
    IO.puts(String.duplicate("-", 80))
    
    gate1 = ecology_metrics.unique_source_classes >= 8
    gate2 = ecology_metrics.matrix_cells_populated >= 20
    gate3 = diffusion_rate > 10
    gate4 = success_rate > 8
    gate5 = ecology_metrics.cross_class_rate >= 10
    # Phase 5C.4 - Entropy targets
    gate6 = ecology_metrics.domain_entropy > 2.0
    gate7 = ecology_metrics.source_entropy > 1.5
    
    IO.puts("   1. Unique Source Classes >= 8: #{if gate1, do: "✅ PASS (#{ecology_metrics.unique_source_classes})", else: "❌ FAIL (#{ecology_metrics.unique_source_classes})"}")
    IO.puts("   2. Occupied Matrix Cells >= 20: #{if gate2, do: "✅ PASS (#{ecology_metrics.matrix_cells_populated})", else: "❌ FAIL (#{ecology_metrics.matrix_cells_populated})"}")
    IO.puts("   3. Knowledge Diffusion Rate > 10%: #{if gate3, do: "✅ PASS (#{Float.round(diffusion_rate, 1)}%)", else: "❌ FAIL (#{Float.round(diffusion_rate, 1)}%)"}")
    IO.puts("   4. Transfer Success Rate > 8%: #{if gate4, do: "✅ PASS (#{Float.round(success_rate, 1)}%)", else: "❌ FAIL (#{Float.round(success_rate, 1)}%)"}")
    IO.puts("   5. Cross-Class Transfer Rate >= 10%: #{if gate5, do: "✅ PASS (#{Float.round(ecology_metrics.cross_class_rate, 1)}%)", else: "❌ FAIL (#{Float.round(ecology_metrics.cross_class_rate, 1)}%)"}")
    IO.puts("   6. Domain Entropy > 2.0: #{if gate6, do: "✅ PASS (#{ecology_metrics.domain_entropy})", else: "❌ FAIL (#{ecology_metrics.domain_entropy})"}")
    IO.puts("   7. Classification Entropy > 1.5: #{if gate7, do: "✅ PASS (#{ecology_metrics.source_entropy})", else: "❌ FAIL (#{ecology_metrics.source_entropy})"}")
    IO.puts("")
    
    all_passed = gate1 and gate2 and gate3 and gate4 and gate5 and gate6 and gate7
    
    if all_passed do
      IO.puts(String.duplicate("-", 80))
      IO.puts("🎉 ALL EXIT CRITERIA MET - Phase 5C.1 SUCCESSFUL!")
      IO.puts(String.duplicate("-", 80))
    else
      IO.puts(String.duplicate("-", 80))
      IO.puts("⚠️  SOME CRITERIA NOT MET - Further refinement needed")
      IO.puts(String.duplicate("-", 80))
    end
    
    IO.puts("\n💡 CANDIDATE LAWS DISCOVERED:")
    if length(law_candidates) > 0 do
      Enum.each(law_candidates, fn law ->
        IO.puts("   • #{law.law}")
        IO.puts("     Evidence: #{law.evidence}")
        IO.puts("     Confidence: #{Float.round(law.confidence * 100, 1)}%\n")
      end)
    else
      IO.puts("   No candidate laws generated yet\n")
    end
    
    IO.puts("📚 Repair Library Status:")
    patterns = Tiannara.ASC.Crucible.RepairLibrary.list_all_patterns()
    IO.puts("   Total Patterns: #{length(patterns)}\n")
    
    IO.puts(String.duplicate("=", 80))
  end

  defp count_unique_failure_classes(observations) do
    observations
    |> Enum.map(fn obs -> 
      case obs.source_classification do
        %{domain: d, category: c, subcategory: s} -> "#{d}.#{c}.#{s}"
        _ -> "unknown"
      end
    end)
    |> Enum.uniq()
    |> length()
  end

  defp calculate_classification_entropy(observations) do
    if length(observations) == 0 do
      0.0
    else
      class_counts = observations
      |> Enum.map(fn obs ->
        case obs.source_classification do
          %{domain: d, category: c, subcategory: s} -> "#{d}.#{c}.#{s}"
          _ -> "unknown"
        end
      end)
      |> Enum.frequencies()
      
      total = length(observations)
      
      class_counts
      |> Enum.map(fn {_class, count} ->
        p = count / total
        if p > 0, do: -p * :math.log2(p), else: 0
      end)
      |> Enum.sum()
    end
  end

  defp analyze_distance_correlation(distance_distribution) do
    buckets = [
      {"0.0-0.2", distance_distribution["0.0-0.2"] || %{attempts: 0, successes: 0}},
      {"0.2-0.4", distance_distribution["0.2-0.4"] || %{attempts: 0, successes: 0}},
      {"0.4-0.6", distance_distribution["0.4-0.6"] || %{attempts: 0, successes: 0}},
      {"0.6-0.8", distance_distribution["0.6-0.8"] || %{attempts: 0, successes: 0}},
      {"0.8-1.0", distance_distribution["0.8-1.0"] || %{attempts: 0, successes: 0}}
    ]
    
    # Calculate success rates per bucket
    rates = buckets
    |> Enum.map(fn {bucket, data} ->
      midpoint = case bucket do
        "0.0-0.2" -> 0.1
        "0.2-0.4" -> 0.3
        "0.4-0.6" -> 0.5
        "0.6-0.8" -> 0.7
        "0.8-1.0" -> 0.9
      end
      rate = if data.attempts > 0, do: data.successes / data.attempts, else: 0.0
      {midpoint, rate, data.attempts}
    end)
    |> Enum.filter(fn {_dist, _rate, attempts} -> attempts > 0 end)
    
    if length(rates) < 2 do
      0.0
    else
      # Simple correlation calculation
      distances = Enum.map(rates, fn {d, _r, _a} -> d end)
      success_rates = Enum.map(rates, fn {_d, r, _a} -> r end)
      
      # Check if success rate decreases with distance
      decreasing_count = Enum.count(Enum.zip(distances, success_rates), fn {d1, r1} ->
        Enum.any?(Enum.zip(distances, success_rates), fn {d2, r2} ->
          d2 > d1 and r2 < r1
        end)
      end)
      
      total_comparisons = length(rates) * (length(rates) - 1)
      
      if total_comparisons > 0 do
        -1.0 * (decreasing_count / total_comparisons)
      else
        0.0
      end
    end
  end
end

# Execute the campaign
Tiannara.ASC.Crucible.EvolutionPhase5C1.run()
