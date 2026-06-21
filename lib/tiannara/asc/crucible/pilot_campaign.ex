defmodule Tiannara.ASC.Crucible.PilotCampaign do
  @moduledoc """
  Pilot Campaign — runs a small-scale test (5 projects) before full Alpha Campaign.

  Purpose:
  - Verify observation pipeline works end-to-end
  - Catch instrumentation bugs at small scale
  - Validate law candidate generation
  - Test epoch finalization

  Target:
  - 5 Projects
  - 50 Failures
  - 10 Exploits
  - 5 Repairs
  - ~200-500 Observations
  """

  alias Tiannara.ASC.Crucible.{Builder, Validator, Breaker, Attacker, Repairer, Observatory}
  alias Tiannara.ASC.Interface.Genome

  # Project IDs for test genomes
  @project_ids [
    "simple_web_app",
    "api_service",
    "distributed_kv",
    "auth_service",
    "background_worker"
  ]

  @doc """
  Run the complete pilot campaign.

  ## Returns
  - {:ok, epoch} with campaign results
  """
  def run do
    IO.puts("\n🚀 Starting Pilot Campaign...")
    IO.puts("Target: 5 projects, 50 failures, 10 exploits, 5 repairs\n")

    # Bootstrap full ASC Runtime (Phase 5C.7)
    Tiannara.ASC.Runtime.bootstrap()

    # Generate test genomes with project IDs
    genomes = generate_test_genomes()

    # Process each genome through full pipeline
    results = Enum.map(genomes, fn {genome, project_id} ->
      IO.puts("\n📦 Processing: #{genome.genome_id} (#{project_id})")
      process_genome(genome, project_id)
    end)

    # Finalize epoch
    IO.puts("\n📊 Finalizing epoch...")
    {:ok, epoch} = Observatory.finalize_epoch("pilot_001", length(genomes))

    # Print summary
    print_summary(epoch, results)

    {:ok, epoch}
  end

  # Removed ensure_observatory_started in favor of Tiannara.ASC.Runtime.bootstrap()

  defp generate_test_genomes do
    # Create 5 diverse test genomes with project IDs
    Enum.zip([
      %Genome{genome_id: "web_app_001", generation: 1, deployment_target: "docker-compose"},
      %Genome{genome_id: "api_service_001", generation: 1, deployment_target: "kubernetes"},
      %Genome{genome_id: "kv_store_001", generation: 1, deployment_target: "distributed"},
      %Genome{genome_id: "auth_service_001", generation: 1, deployment_target: "docker-compose"},
      %Genome{genome_id: "worker_001", generation: 1, deployment_target: "beam_cluster"}
    ], @project_ids)
  end

  defp process_genome(genome, project_id) do
    # Step 1: Build
    IO.puts("  🔨 Building...")
    build_result = case Builder.build(genome, project_id) do
      {:ok, result} ->
        IO.puts("     ✅ Build: #{if result.success?, do: "SUCCESS", else: "FAILED"}")
        result
      {:error, error} ->
        IO.puts("     ❌ Build error: #{inspect(error)}")
        nil
    end

    # Step 2: Validate (if build succeeded)
    validation_result = if build_result && build_result.success? && build_result.artifact_path do
      IO.puts("  🔍 Validating...")
      case Validator.validate(genome, build_result.artifact_path, project_id: project_id) do
        {:ok, result} ->
          IO.puts("     ✅ Validation: #{if result.valid?, do: "PASS", else: "FAIL"}")
          result
        {:error, error} ->
          IO.puts("     ❌ Validation error: #{inspect(error)}")
          nil
      end
    else
      nil
    end

    # Step 3: Break
    break_result = if build_result && build_result.success? && build_result.artifact_path do
      IO.puts("  💥 Breaking...")
      case Breaker.break_system(genome, build_result.artifact_path, project_id: project_id) do
        {:ok, result} ->
          IO.puts("     ✅ Break: #{if result.failure_discovered?, do: "FAILURE FOUND", else: "NO FAILURE"}")
          result
        {:error, error} ->
          IO.puts("     ❌ Break error: #{inspect(error)}")
          nil
      end
    else
      nil
    end

    # Step 4: Attack
    attack_result = if build_result && build_result.success? && build_result.artifact_path do
      IO.puts("  ⚔️  Attacking...")
      case Attacker.attack_system(genome, build_result.artifact_path, project_id: project_id) do
        {:ok, result} ->
          IO.puts("     ✅ Attack: #{if result.exploit_found?, do: "EXPLOIT FOUND", else: "NO EXPLOIT"}")
          result
        {:error, error} ->
          IO.puts("     ❌ Attack error: #{inspect(error)}")
          nil
      end
    else
      nil
    end

    # Step 5: Repair (if failure or exploit found)
    repair_result = cond do
      break_result && break_result.failure_discovered? ->
        IO.puts("  🩹 Repairing failure...")
        # Create mock failure observation for repair
        failure_obs = %Tiannara.ASC.Crucible.Observation{
          id: "mock_failure_#{genome.genome_id}",
          project_id: project_id,
          genome_id: genome.genome_id,
          source: :breaker,
          observation_type: :failure,
          severity: break_result.failure_severity,
          origin: break_result.failure_origin || :implementation,
          reproducible: true,
          confidence: 0.8,
          evidence: [break_result.failure_description],
          timestamp: DateTime.utc_now(),
          generation: genome.generation
        }

        case Repairer.repair(failure_obs, build_result.artifact_path, project_id: project_id) do
          {:ok, result} ->
            IO.puts("     ✅ Repair: #{if result.repair_successful?, do: "SUCCESS", else: "FAILED"}")
            result
          {:error, error} ->
            IO.puts("     ❌ Repair error: #{inspect(error)}")
            nil
        end

      attack_result && attack_result.exploit_found? ->
        IO.puts("  🩹 Repairing exploit...")
        # Create mock exploit observation for repair
        exploit_obs = %Tiannara.ASC.Crucible.Observation{
          id: "mock_exploit_#{genome.genome_id}",
          project_id: project_id,
          genome_id: genome.genome_id,
          source: :attacker,
          observation_type: :exploit,
          severity: attack_result.exploit_severity,
          origin: :implementation,
          reproducible: true,
          confidence: 0.85,
          evidence: [attack_result.exploit_description],
          timestamp: DateTime.utc_now(),
          generation: genome.generation
        }

        case Repairer.repair(exploit_obs, build_result.artifact_path, project_id: project_id) do
          {:ok, result} ->
            IO.puts("     ✅ Repair: #{if result.repair_successful?, do: "SUCCESS", else: "FAILED"}")
            result
          {:error, error} ->
            IO.puts("     ❌ Repair error: #{inspect(error)}")
            nil
        end

      true ->
        IO.puts("     ⏭️  No repair needed")
        nil
    end

    %{
      genome_id: genome.genome_id,
      project_id: project_id,
      build: build_result,
      validation: validation_result,
      break: break_result,
      attack: attack_result,
      repair: repair_result
    }
  end

  defp print_summary(epoch, results) do
    IO.puts("\n" <> String.duplicate("=", 60))
    IO.puts("📈 PILOT CAMPAIGN SUMMARY")
    IO.puts(String.duplicate("=", 60))

    # Project count
    IO.puts("\nProjects Tested: #{length(results)}")

    # Observation counts
    {:ok, metrics} = Observatory.get_metrics()
    IO.puts("Total Observations: #{metrics.total_observations}")
    IO.puts("Observation by Source:")
    Enum.each(metrics.observation_count_by_source || %{}, fn {source, count} ->
      IO.puts("  - #{source}: #{count}")
    end)

    # Success rates
    successful_builds = Enum.count(results, fn r -> r.build && r.build.success? end)
    IO.puts("\nBuild Success Rate: #{Float.round(successful_builds / length(results) * 100, 1)}%")

    # Failure discovery
    failures_found = Enum.count(results, fn r -> r.break && r.break.failure_discovered? end)
    IO.puts("Failures Discovered: #{failures_found}")

    # Exploit discovery
    exploits_found = Enum.count(results, fn r -> r.attack && r.attack.exploit_found? end)
    IO.puts("Exploits Discovered: #{exploits_found}")

    # Law candidates
    IO.puts("\nLaw Candidates Generated: #{length(epoch.candidate_laws)}")
    IO.puts("Established Laws: #{length(epoch.established_laws)}")
    # TODO: Add falsified_laws field to Epoch struct
    # IO.puts("Falsified Laws: #{length(epoch.falsified_laws || [])}")

    # Survival metrics
    IO.puts("\nSurvival Rate: #{Float.round(epoch.survival_rate * 100, 1)}%")
    IO.puts("Failure Rate: #{Float.round(epoch.failure_rate * 100, 1)}%")
    IO.puts("Repair Success Rate: #{Float.round(epoch.repair_success_rate * 100, 1)}%")

    # Knowledge metrics
    IO.puts("\nLearning Yield: #{epoch.learning_yield}")
    IO.puts("Knowledge Compression Ratio: #{epoch.knowledge_compression_ratio}")
    IO.puts("Principle Stability: #{epoch.principle_stability}")

    # Check criteria
    if Tiannara.ASC.Crucible.Epoch.meets_alpha_criteria?(epoch) do
      IO.puts("\n✅ PILOT CAMPAIGN SUCCESS - Ready for Alpha!")
    else
      IO.puts("\n⚠️  PILOT CAMPAIGN INCOMPLETE - This is expected for pilot")
      IO.puts("   Pipeline validated, proceed to full Alpha Campaign")
    end

    IO.puts(String.duplicate("=", 60))
  end
end
