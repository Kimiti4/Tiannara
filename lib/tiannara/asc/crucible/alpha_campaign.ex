defmodule Tiannara.ASC.Crucible.AlphaCampaign do
  @moduledoc """
  Alpha Campaign — full-scale scientific experiment to discover engineering laws.

  Scale:
  - 25 Projects (5x pilot)
  - Target: 500+ Failures
  - Target: 100+ Exploits
  - Target: 50+ Repairs
  - Expected: 1,250-3,000 Observations

  Objectives:
  1. Generate sufficient observations for law discovery
  2. Validate Breaker failure diversity (>50% discovery rate)
  3. Extract 10-20 candidate laws
  4. Establish 3-6 established laws
  5. Falsify 2-8 laws (scientific rigor!)
  6. Measure Knowledge Reuse Rate (key metric)

  Success Criteria:
  - All 5 modules emit observations
  - Epoch finalization produces complete metrics
  - Law candidates generated from patterns
  - Falsification ledger updated
  - No pipeline crashes at scale
  """

  alias Tiannara.ASC.Crucible.{Builder, Validator, Breaker, Attacker, Repairer, Observatory}
  alias Tiannara.ASC.Interface.Genome

  # Test genome configurations for 25 diverse projects
  @project_configs [
    # Web Applications (5)
    %{genome_id: "web_app_001", project_id: "simple_web_app", deployment_target: "docker-compose"},
    %{genome_id: "web_app_002", project_id: "react_frontend", deployment_target: "kubernetes"},
    %{genome_id: "web_app_003", project_id: "vue_dashboard", deployment_target: "docker-compose"},
    %{genome_id: "web_app_004", project_id: "angular_admin", deployment_target: "kubernetes"},
    %{genome_id: "web_app_005", project_id: "svelte_blog", deployment_target: "docker-compose"},

    # API Services (5)
    %{genome_id: "api_001", project_id: "rest_api", deployment_target: "kubernetes"},
    %{genome_id: "api_002", project_id: "graphql_gateway", deployment_target: "kubernetes"},
    %{genome_id: "api_003", project_id: "grpc_service", deployment_target: "beam_cluster"},
    %{genome_id: "api_004", project_id: "websocket_server", deployment_target: "docker-compose"},
    %{genome_id: "api_005", project_id: "event_bus", deployment_target: "distributed"},

    # Data Stores (5)
    %{genome_id: "store_001", project_id: "kv_store", deployment_target: "distributed"},
    %{genome_id: "store_002", project_id: "document_db", deployment_target: "kubernetes"},
    %{genome_id: "store_003", project_id: "time_series_db", deployment_target: "beam_cluster"},
    %{genome_id: "store_004", project_id: "graph_db", deployment_target: "distributed"},
    %{genome_id: "store_005", project_id: "cache_layer", deployment_target: "docker-compose"},

    # Auth & Security (5)
    %{genome_id: "auth_001", project_id: "oauth_provider", deployment_target: "kubernetes"},
    %{genome_id: "auth_002", project_id: "jwt_validator", deployment_target: "docker-compose"},
    %{genome_id: "auth_003", project_id: "rbac_engine", deployment_target: "kubernetes"},
    %{genome_id: "auth_004", project_id: "session_manager", deployment_target: "beam_cluster"},
    %{genome_id: "auth_005", project_id: "api_key_service", deployment_target: "docker-compose"},

    # Workers & Background Jobs (5)
    %{genome_id: "worker_001", project_id: "background_worker", deployment_target: "beam_cluster"},
    %{genome_id: "worker_002", project_id: "task_scheduler", deployment_target: "kubernetes"},
    %{genome_id: "worker_003", project_id: "email_processor", deployment_target: "docker-compose"},
    %{genome_id: "worker_004", project_id: "data_pipeline", deployment_target: "distributed"},
    %{genome_id: "worker_005", project_id: "notification_service", deployment_target: "kubernetes"}
  ]

  @doc """
  Run the complete Alpha Campaign.

  ## Returns
  - {:ok, epoch} with campaign results
  """
  def run do
    IO.puts("\n🚀🚀🚀 Starting ALPHA CAMPAIGN 🚀🚀🚀")
    IO.puts("Scale: 25 projects, targeting 500+ failures, 100+ exploits, 50+ repairs")
    IO.puts("Expected: 1,250-3,000 observations\n")

    # Bootstrap full ASC Runtime (Phase 5C.7)
    Tiannara.ASC.Runtime.bootstrap()

    # Generate test genomes
    genomes = generate_test_genomes()

    IO.puts("📊 Processing #{length(genomes)} projects...\n")

    # Process each project through the full Crucible loop
    results = @project_configs
      |> Enum.with_index(1)
      |> Enum.map(fn {config, idx} ->
        IO.puts("📦 [#{idx}/#{length(@project_configs)}] Processing: #{config.genome_id} (#{config.project_id})")

        result = process_project(config)

        IO.puts("")
        result
      end)

    # Finalize epoch
    IO.puts("\n📊 Finalizing epoch...")
    {:ok, epoch} = Observatory.finalize_epoch("alpha_001", length(genomes))

    # Print comprehensive summary
    print_alpha_summary(epoch, results)

    {:ok, epoch}
  end

  # Removed ensure_observatory_started in favor of Tiannara.ASC.Runtime.bootstrap()

  defp generate_test_genomes do
    Enum.map(@project_configs, fn config ->
      %Genome{
        genome_id: config.genome_id,
        generation: 1,
        deployment_target: config.deployment_target
      }
    end)
  end

  defp process_project(config) do
    genome = %Genome{
      genome_id: config.genome_id,
      generation: 1,
      deployment_target: config.deployment_target
    }

    project_id = config.project_id

    # Step 1: Build
    IO.puts("  🔨 Building...")
    build_result = case Builder.build(genome, project_id) do
      {:ok, result} ->
        IO.puts("     ✅ Build: #{if result.success?, do: "SUCCESS", else: "FAILED"}")
        result
      {:error, error} ->
        IO.puts("     ❌ Build Error: #{inspect(error)}")
        nil
    end

    # Step 2: Validate
    IO.puts("  🔍 Validating...")
    validation_result = case Validator.validate(genome, project_id) do
      {:ok, result} ->
        IO.puts("     ✅ Validation: #{if result.valid?, do: "PASS", else: "FAIL"}")
        result
      {:error, error} ->
        IO.puts("     ❌ Validation Error: #{inspect(error)}")
        nil
    end

    # Step 3: Break (with artifact path)
    IO.puts("  💥 Breaking...")
    artifact_path = "/tmp/#{project_id}"
    break_result = case Breaker.break_system(genome, artifact_path, project_id: project_id) do
      {:ok, result} ->
        status = if result.failure_discovered?, do: "FAILURE FOUND", else: "NO FAILURE"
        IO.puts("     ✅ Break: #{status}")
        result
      {:error, error} ->
        IO.puts("     ❌ Break Error: #{inspect(error)}")
        nil
    end

    # Step 4: Attack
    IO.puts("  ⚔️  Attacking...")
    attack_result = case Attacker.attack_system(genome, artifact_path, project_id: project_id) do
      {:ok, result} ->
        status = if result.exploit_found?, do: "EXPLOIT FOUND", else: "NO EXPLOIT"
        IO.puts("     ✅ Attack: #{status}")
        result
      {:error, error} ->
        IO.puts("     ❌ Attack Error: #{inspect(error)}")
        nil
    end

    # Step 5: Repair (attempt repair on first failure found)
    repair_result = if break_result && break_result.failure_discovered? do
      IO.puts("  🩹 Repairing failure...")
      # Create a mock failure observation for repair
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
        generation: genome.generation
      }

      case Repairer.repair(failure_obs, artifact_path) do
        {:ok, result} ->
          status = if result.repair_successful?, do: "SUCCESS", else: "FAILED"
          IO.puts("     ✅ Repair: #{status}")
          result
        {:error, error} ->
          IO.puts("     ❌ Repair Error: #{inspect(error)}")
          nil
      end
    else
      IO.puts("  🩹 Skipping repair (no failure to repair)")
      nil
    end

    %{
      project_id: project_id,
      genome_id: genome.genome_id,
      build: build_result,
      validation: validation_result,
      break: break_result,
      attack: attack_result,
      repair: repair_result
    }
  end

  defp print_alpha_summary(epoch, results) do
    IO.puts("\n" <> String.duplicate("=", 70))
    IO.puts("📈 ALPHA CAMPAIGN SUMMARY")
    IO.puts(String.duplicate("=", 70))

    # Project statistics
    IO.puts("\nProjects Tested: #{epoch.projects_tested}")
    IO.puts("Total Observations: #{epoch.total_observations}")

    # Observation breakdown by source
    obs_by_source = Enum.group_by(epoch.observations || [], & &1.source)
    IO.puts("\nObservation by Source:")
    for {source, obs_list} <- Enum.sort(obs_by_source) do
      IO.puts("  - #{source}: #{length(obs_list)}")
    end

    # Failure and exploit statistics
    failures = Enum.count(results, fn r -> r.break && r.break.failure_discovered? end)
    exploits = Enum.count(results, fn r -> r.attack && r.attack.exploit_found? end)
    repairs_attempted = Enum.count(results, fn r -> r.repair != nil end)
    repairs_successful = Enum.count(results, fn r -> r.repair && r.repair.repair_successful? end)

    IO.puts("\nFailures Discovered: #{failures}")
    IO.puts("Exploits Discovered: #{exploits}")
    IO.puts("Repairs Attempted: #{repairs_attempted}")
    IO.puts("Repairs Successful: #{repairs_successful}")

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

    # Alpha success assessment
    IO.puts("\n" <> String.duplicate("-", 70))
    if Tiannara.ASC.Crucible.Epoch.meets_alpha_criteria?(epoch) do
      IO.puts("✅ ALPHA CAMPAIGN SUCCESS - Criteria met!")
    else
      IO.puts("⚠️  ALPHA CAMPAIGN PARTIAL - Some criteria not met")
      IO.puts("   This is expected for first Alpha run")
      IO.puts("   Key achievement: Pipeline validated at scale")
    end
    IO.puts(String.duplicate("=", 70))
  end
end
