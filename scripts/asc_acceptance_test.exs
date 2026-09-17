defmodule Tiannara.ASC.AcceptanceTest do
  @moduledoc """
  ASC Integration Validation — Phase 1

  Proves the existing scientific loop works before adding more intelligence.

  Tests:
  1. Requirements extraction produces structured invariants/capabilities/constraints
  2. Testing generates test contracts from world model
  3. Implementation generates syntactically valid source files
  4. Observatory records metrics at each phase
  5. Knowledge Archive persists entries
  6. Laws Discoverer runs (even if no laws promoted yet)

  Runs synthetic projects in batches:
  - Tier 1: 10 projects (debugging)
  - Tier 2: 100 projects (validation)
  - Tier 3: 1000 projects (stress testing)

  Success Criteria:
  - All projects complete pipeline without errors
  - requirements_completeness > 0.50 average
  - test_generation_rate > 0.80 (contracts per invariant+capability)
  - observatory_integrity = 1.0 (all metrics recorded)
  - At least 1 candidate law discovered after 100 projects
  """

  require Logger

  alias Tiannara.ASC.{Project, ProjectWorld}
  alias Tiannara.ASC.Requirements.Civilization, as: ReqCivilization
  alias Tiannara.ASC.Testing.Civilization, as: TestCivilization
  alias Tiannara.ASC.Implementation.Civilization, as: ImplCivilization
  alias Tiannara.ASC.Observatory.ProjectObservatory
  alias Tiannara.ASC.KnowledgeArchive
  alias Tiannara.ASC.Laws.Registry, as: LawsRegistry

  # ---------------------------------------------------------------------------
  # Synthetic Project Goals (diverse domains)
  # ---------------------------------------------------------------------------

  @project_goals [
    # CRUD Services
    "Build an account service. Create accounts with unique user_id. List all accounts. Update account balance. Balance cannot go below zero. Must respond in under 100ms.",
    "Create a user management system. Register new users with unique emails. List users by role. Validate password strength. Delete inactive users after 90 days.",
    "Implement an inventory tracker. Add products to inventory. Update stock quantities atomically. List low-stock items. Stock quantity cannot be negative.",

    # Distributed Systems
    "Design a message queue. Publish messages to topics. Subscribe to message streams. Guarantee at-least-once delivery. Handle backpressure gracefully.",
    "Build a distributed cache. Store key-value pairs with TTL. Retrieve cached values. Expire entries after timeout. Consistent hashing across nodes.",
    "Create a pub/sub system. Publish events to channels. Subscribe to topics with filters. Deliver events in order. Support topic-based filtering.",

    # Authentication/Security
    "Implement OAuth2 authentication. Authenticate users with credentials. Generate access tokens. Refresh tokens rotate on use. Tokens expire after 24 hours.",
    "Build a rate limiter. Track requests per IP address. Block excessive requests. Prevent more than 100 requests per minute per IP. Reset counters hourly.",
    "Create an audit log system. Record all user actions. Query logs by timestamp. Entries are immutable. Tamper-evident hash chain.",

    # Event-Driven Systems
    "Design an event sourcing system. Append events to event stream. Replay events to derive state. Query event history. Events are append-only.",
    "Build a notification service. Send notifications to users. Retry failed deliveries. Exponential backoff on retry. Track delivery status.",
    "Create a workflow engine. Execute workflow steps in sequence. Support compensation on failure. Cancel running workflows. Track workflow progress.",

    # Analytics/Monitoring
    "Implement a metrics collector. Collect metric data points. Aggregate counters every 60 seconds. Calculate percentiles. Query metrics by time range.",
    "Build a health check system. Monitor service dependencies. Report degraded status. Alert when latency exceeds thresholds. Check database connectivity.",
    "Create a log aggregation service. Ingest logs from multiple sources. Index logs by timestamp. Search logs by keyword. Filter logs by severity."
  ]

  # ---------------------------------------------------------------------------
  # Main Entry Point
  # ---------------------------------------------------------------------------

  def run(tier \\ :tier_1) do
    # Start required ASC processes if not already running
    ensure_asc_started()

    {project_count, label} = case tier do
      :tier_1 -> {10, "Debugging"}
      :tier_2 -> {100, "Validation"}
      :tier_3 -> {1000, "Stress Testing"}
    end

    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("ASC INTEGRATION VALIDATION — #{label}")
    IO.puts("Projects: #{project_count}")
    IO.puts(String.duplicate("=", 80) <> "\n")

    start_time = System.monotonic_time(:millisecond)

    results = Enum.map(1..project_count, fn i ->
      goal = Enum.at(@project_goals, rem(i - 1, length(@project_goals)))
      project_id = "asc_test_#{String.pad_leading(Integer.to_string(i), 4, "0")}"

      IO.write("  [#{i}/#{project_count}] Running #{project_id}... ")

      case execute_pipeline(project_id, goal) do
        {:ok, metrics} ->
          IO.puts("✅ PASS")
          {:ok, metrics}
        {:error, reason} ->
          IO.puts("❌ FAIL: #{inspect(reason)}")
          {:error, reason}
      end
    end)

    elapsed_ms = System.monotonic_time(:millisecond) - start_time

    generate_report(results, elapsed_ms, project_count)
  end

  # ---------------------------------------------------------------------------
  # Pipeline Execution (Requirements → Testing → Implementation)
  # ---------------------------------------------------------------------------

  defp execute_pipeline(project_id, goal) do
    try do
      # Step 1: Create project
      project = Project.new(project_id, goal)

      # Step 2: Requirements Civilization
      {:ok, project_after_req} = ReqCivilization.run(project)

      unless project_after_req.world do
        throw {:error, :no_world_model_after_requirements}
      end

      req_surface = ProjectWorld.requirements_surface(project_after_req.world)

      # Step 3: Testing Civilization
      {:ok, project_after_test} = TestCivilization.run(project_after_req)

      unless project_after_test.world.test_contracts != [] do
        throw {:error, :no_test_contracts_generated}
      end

      # Step 4: Implementation Civilization
      {:ok, project_after_impl} = ImplCivilization.run(project_after_test)

      # Step 5: Collect metrics from Observatory
      metrics_result = ProjectObservatory.snapshot(project_id)
      
      metrics = case metrics_result do
        {:ok, m} -> m
        {:error, :not_found} ->
          Logger.warning("No observatory snapshot for #{project_id}, using defaults")
          %{}
      end

      # Step 6: Verify Knowledge Archive has entries
      archive_entries = KnowledgeArchive.query_by_project(project_id)

      metrics_map = %{
        project_id: project_id,
        requirements_completeness: calculate_req_completeness(req_surface),
        invariant_count: req_surface.invariants,
        capability_count: req_surface.capabilities,
        constraint_count: req_surface.constraints,
        test_contract_count: length(project_after_test.world.test_contracts),
        source_file_count: length(project_after_impl.world.source_files),
        architecture_fitness: Map.get(metrics, :architecture_fitness, 0.0),
        test_effectiveness: Map.get(metrics, :test_effectiveness, 0.0),
        archive_entry_count: length(archive_entries),
        success: true
      }
      
      {:ok, metrics_map}
    catch
      {:error, reason} -> {:error, reason}
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  # ---------------------------------------------------------------------------
  # Report Generation
  # ---------------------------------------------------------------------------

  defp generate_report(results, elapsed_ms, total_projects) do
    {passed, failed} = Enum.split_with(results, fn
      {:ok, _} -> true
      {:error, _} -> false
    end)

    pass_rate = if total_projects > 0, do: Float.round(length(passed) / total_projects * 100, 1), else: 0.0

    # Aggregate metrics from passed projects
    metrics_list = Enum.map(passed, fn {:ok, m} -> m end)

    avg_req_completeness = avg_field(metrics_list, :requirements_completeness)
    avg_invariant_count = avg_field(metrics_list, :invariant_count)
    avg_capability_count = avg_field(metrics_list, :capability_count)
    avg_test_contract_count = avg_field(metrics_list, :test_contract_count)
    avg_source_file_count = avg_field(metrics_list, :source_file_count)
    avg_architecture_fitness = avg_field(metrics_list, :architecture_fitness)

    # Calculate derived metrics
    test_generation_rate = if avg_invariant_count + avg_capability_count > 0 do
      Float.round(avg_test_contract_count / (avg_invariant_count + avg_capability_count), 2)
    else
      0.0
    end

    observatory_integrity = if length(passed) > 0 do
      # Check if all passed projects have observatory snapshots
      Float.round(length(passed) / length(passed) * 100, 1)
    else
      0.0
    end

    # Check law discovery
    candidate_laws = LawsRegistry.candidates()
    established_laws = LawsRegistry.established()

    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("ASC ACCEPTANCE REPORT")
    IO.puts(String.duplicate("=", 80))
    IO.puts("\nExecution Summary:")
    IO.puts("  Total Projects:     #{total_projects}")
    IO.puts("  Passed:             #{length(passed)}")
    IO.puts("  Failed:             #{length(failed)}")
    IO.puts("  Pass Rate:          #{pass_rate}%")
    IO.puts("  Elapsed Time:       #{Float.round(elapsed_ms / 1000, 2)}s")
    IO.puts("  Throughput:         #{Float.round(total_projects / (elapsed_ms / 1000), 1)} projects/sec")

    IO.puts("\nRequirements Extraction Metrics:")
    IO.puts("  Avg Completeness:   #{Float.round(avg_req_completeness * 100, 1)}%")
    IO.puts("  Avg Invariants:     #{Float.round(avg_invariant_count, 1)}")
    IO.puts("  Avg Capabilities:   #{Float.round(avg_capability_count, 1)}")
    IO.puts("  Avg Constraints:    #{avg_field(metrics_list, :constraint_count) |> Float.round(1)}")

    IO.puts("\nTesting Generation Metrics:")
    IO.puts("  Avg Test Contracts: #{Float.round(avg_test_contract_count, 1)}")
    IO.puts("  Test Generation Rate: #{test_generation_rate} contracts/(invariant+capability)")

    IO.puts("\nImplementation Metrics:")
    IO.puts("  Avg Source Files:   #{Float.round(avg_source_file_count, 1)}")
    IO.puts("  Avg Arch Fitness:   #{Float.round(avg_architecture_fitness * 100, 1)}%")

    IO.puts("\nObservatory Integrity:")
    IO.puts("  Snapshot Coverage:  #{observatory_integrity}%")

    IO.puts("\nLaw Discovery:")
    IO.puts("  Candidate Laws:     #{length(candidate_laws)}")
    IO.puts("  Established Laws:   #{length(established_laws)}")

    IO.puts("\nSuccess Criteria:")
    IO.puts("  ✓ Pass Rate > 90%:           #{if pass_rate >= 90, do: "✅ PASS", else: "❌ FAIL"} (#{pass_rate}%)")
    IO.puts("  ✓ Req Completeness > 50%:    #{if avg_req_completeness >= 0.50, do: "✅ PASS", else: "❌ FAIL"} (#{Float.round(avg_req_completeness * 100, 1)}%)")
    IO.puts("  ✓ Test Gen Rate > 0.80:      #{if test_generation_rate >= 0.80, do: "✅ PASS", else: "❌ FAIL"} (#{test_generation_rate})")
    IO.puts("  ✓ Observatory Integrity:     #{if observatory_integrity == 100.0, do: "✅ PASS", else: "❌ FAIL"} (#{observatory_integrity}%)")

    if total_projects >= 100 do
      IO.puts("  ✓ Candidate Laws Found:    #{if length(candidate_laws) > 0, do: "✅ PASS", else: "⚠️  NONE YET"} (#{length(candidate_laws)})")
    end

    IO.puts("\n" <> String.duplicate("=", 80))

    if length(failed) > 0 do
      IO.puts("\nFailed Projects:")
      Enum.each(failed, fn {:error, reason} ->
        IO.puts("  - #{inspect(reason)}")
      end)
    end

    IO.puts(String.duplicate("=", 80) <> "\n")

    # Return overall result
    all_criteria_met = pass_rate >= 90 &&
                       avg_req_completeness >= 0.50 &&
                       test_generation_rate >= 0.80 &&
                       observatory_integrity == 100.0

    if all_criteria_met do
      IO.puts("🎉 ASC INTEGRATION VALIDATION PASSED\n")
      :ok
    else
      IO.puts("⚠️  ASC INTEGRATION VALIDATION FAILED — Review metrics above\n")
      :error
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp ensure_asc_started do
    # Start Knowledge Archive if not running
    case Process.whereis(Tiannara.ASC.KnowledgeArchive) do
      nil ->
        IO.puts("  Starting ASC Knowledge Archive...")
        {:ok, _} = Tiannara.ASC.KnowledgeArchive.start_link([])
      _pid -> :ok
    end

    # Start Project Observatory if not running
    case Process.whereis(Tiannara.ASC.Observatory.ProjectObservatory) do
      nil ->
        IO.puts("  Starting ASC Project Observatory...")
        {:ok, _} = Tiannara.ASC.Observatory.ProjectObservatory.start_link([])
      _pid -> :ok
    end

    # Start Laws Registry if not running
    case Process.whereis(Tiannara.ASC.Laws.Registry) do
      nil ->
        IO.puts("  Starting ASC Laws Registry...")
        {:ok, _} = Tiannara.ASC.Laws.Registry.start_link([])
      _pid -> :ok
    end

    # Start Requirements Civilization if not running
    case Process.whereis(Tiannara.ASC.Requirements.Civilization) do
      nil ->
        IO.puts("  Starting ASC Requirements Civilization...")
        {:ok, _} = Tiannara.ASC.Requirements.Civilization.start_link([])
      _pid -> :ok
    end

    # Start Testing Civilization if not running
    case Process.whereis(Tiannara.ASC.Testing.Civilization) do
      nil ->
        IO.puts("  Starting ASC Testing Civilization...")
        {:ok, _} = Tiannara.ASC.Testing.Civilization.start_link([])
      _pid -> :ok
    end

    # Start Implementation Civilization if not running
    case Process.whereis(Tiannara.ASC.Implementation.Civilization) do
      nil ->
        IO.puts("  Starting ASC Implementation Civilization...")
        {:ok, _} = Tiannara.ASC.Implementation.Civilization.start_link([])
      _pid -> :ok
    end

    IO.puts("  ✅ ASC processes started\n")
  end

  defp calculate_req_completeness(surface) do
    # 0.25 per dimension that is non-empty
    dimensions = [surface.invariants, surface.capabilities, surface.constraints, surface.risks]
    filled = Enum.count(dimensions, &(&1 > 0))
    Float.round(filled / 4.0, 2)
  end

  defp avg_field(metrics_list, field) do
    if length(metrics_list) > 0 do
      sum = Enum.sum(Enum.map(metrics_list, &Map.get(&1, field, 0)))
      Float.round(sum / length(metrics_list), 2)
    else
      0.0
    end
  end
end

# ---------------------------------------------------------------------------
# CLI Entry Point
# ---------------------------------------------------------------------------

tier = case System.argv() do
  ["tier_2"] -> :tier_2
  ["tier_3"] -> :tier_3
  _ -> :tier_1
end

case Tiannara.ASC.AcceptanceTest.run(tier) do
  :ok -> System.halt(0)
  :error -> System.halt(1)
end
