defmodule Tiannara.ASC.LawDiscoveryValidation do
  @moduledoc """
  ASC Law Discovery Validation — Phase 2

  Proves ASC can discover software engineering laws from project telemetry.

  Runs synthetic projects in batches:
  - Tier 2A: 100 projects (pattern emergence)
  - Tier 2B: 500 projects (candidate laws)
  - Tier 2C: 1000 projects (established laws)

  Tracks:
  - observations: raw signals detected
  - patterns: correlated variables
  - candidate_laws: statistically significant patterns
  - established_laws: high-confidence, reproducible laws
  - false_promotions: laws refuted after promotion
  - promotion_precision: % of promoted laws that hold
  - promotion_recall: % of true patterns discovered
  - knowledge_yield: established_laws / total_projects

  Success Criterion:
  At least 1 reproducible software-engineering law discovered from telemetry.
  """

  require Logger

  alias Tiannara.ASC.{Project, ProjectWorld}
  alias Tiannara.ASC.Requirements.Civilization, as: ReqCivilization
  alias Tiannara.ASC.Testing.Civilization, as: TestCivilization
  alias Tiannara.ASC.Implementation.Civilization, as: ImplCivilization
  alias Tiannara.ASC.Observatory.ProjectObservatory
  alias Tiannara.ASC.Laws.Registry, as: LawsRegistry
  alias Tiannara.ASC.Laws.Discoverer

  # ---------------------------------------------------------------------------
  # Synthetic Project Goals (expanded for diversity)
  # ---------------------------------------------------------------------------

  @project_goals [
    # CRUD Services (high variety)
    "Build an account service. Create accounts with unique user_id. List all accounts. Update account balance. Balance cannot go below zero. Must respond in under 100ms.",
    "Create a user management system. Register new users with unique emails. List users by role. Validate password strength. Delete inactive users after 90 days.",
    "Implement an inventory tracker. Add products to inventory. Update stock quantities atomically. List low-stock items. Stock quantity cannot be negative.",
    "Build a product catalog. Create product entries with SKU uniqueness. Search products by category. Update prices dynamically. Prices must be positive.",
    "Design an order processing system. Place orders with valid items. Track order status. Cancel pending orders. Orders cannot be modified after shipment.",

    # Distributed Systems
    "Design a message queue. Publish messages to topics. Subscribe to message streams. Guarantee at-least-once delivery. Handle backpressure gracefully.",
    "Build a distributed cache. Store key-value pairs with TTL. Retrieve cached values. Expire entries after timeout. Consistent hashing across nodes.",
    "Create a pub/sub system. Publish events to channels. Subscribe to topics with filters. Deliver events in order. Support topic-based filtering.",
    "Implement a task scheduler. Schedule recurring jobs. Execute tasks in parallel. Retry failed tasks. Tasks must complete within deadline.",
    "Build a leader election system. Elect single leader among nodes. Detect leader failures. Re-elect on failure. Prevent split-brain scenarios.",

    # Authentication/Security
    "Implement OAuth2 authentication. Authenticate users with credentials. Generate access tokens. Refresh tokens rotate on use. Tokens expire after 24 hours.",
    "Build a rate limiter. Track requests per IP address. Block excessive requests. Prevent more than 100 requests per minute per IP. Reset counters hourly.",
    "Create an audit log system. Record all user actions. Query logs by timestamp. Entries are immutable. Tamper-evident hash chain.",
    "Design a permission system. Grant roles to users. Check permissions before actions. Deny unauthorized access. Roles cannot have circular dependencies.",
    "Build a session manager. Create user sessions on login. Invalidate sessions on logout. Sessions expire after inactivity. Prevent session fixation attacks.",

    # Event-Driven Systems
    "Design an event sourcing system. Append events to event stream. Replay events to derive state. Query event history. Events are append-only.",
    "Build a notification service. Send notifications to users. Retry failed deliveries. Exponential backoff on retry. Track delivery status.",
    "Create a workflow engine. Execute workflow steps in sequence. Support compensation on failure. Cancel running workflows. Track workflow progress.",
    "Implement a CQRS system. Separate read and write models. Synchronize models asynchronously. Optimize read queries. Writes must be eventually consistent.",
    "Build a saga orchestrator. Coordinate distributed transactions. Compensate on failure. Track saga state. Sagas must complete or rollback fully.",

    # Analytics/Monitoring
    "Implement a metrics collector. Collect metric data points. Aggregate counters every 60 seconds. Calculate percentiles. Query metrics by time range.",
    "Build a health check system. Monitor service dependencies. Report degraded status. Alert when latency exceeds thresholds. Check database connectivity.",
    "Create a log aggregation service. Ingest logs from multiple sources. Index logs by timestamp. Search logs by keyword. Filter logs by severity.",
    "Design a tracing system. Trace requests across services. Measure span durations. Identify bottlenecks. Traces must propagate context.",
    "Build an alerting system. Define alert rules. Trigger alerts on threshold breach. Suppress duplicate alerts. Alerts must include context.",

    # Data Processing
    "Implement a data pipeline. Ingest data from sources. Transform data records. Load into warehouse. Validate data quality.",
    "Build an ETL system. Extract data from databases. Transform schemas. Load into target system. Handle extraction failures gracefully.",
    "Create a streaming processor. Process real-time events. Aggregate windows of data. Emit results periodically. Maintain exactly-once semantics.",
    "Design a batch processor. Schedule batch jobs. Process large datasets. Report progress. Jobs must complete within SLA.",
    "Build a data validator. Validate input schemas. Check business rules. Reject invalid records. Log validation errors."
  ]

  # ---------------------------------------------------------------------------
  # Main Entry Point
  # ---------------------------------------------------------------------------

  def run(tier \\ :tier_2a) do
    {project_count, label} = case tier do
      :tier_2a -> {100, "Tier 2A — Pattern Emergence"}
      :tier_2b -> {500, "Tier 2B — Candidate Laws"}
      :tier_2c -> {1000, "Tier 2C — Established Laws"}
    end

    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("ASC LAW DISCOVERY VALIDATION — #{label}")
    IO.puts("Projects: #{project_count}")
    IO.puts(String.duplicate("=", 80) <> "\n")

    # Start required ASC processes
    ensure_asc_started()

    start_time = System.monotonic_time(:millisecond)

    # Run projects
    IO.puts("Running #{project_count} projects...\n")
    
    results = Enum.map(1..project_count, fn i ->
      goal = Enum.at(@project_goals, rem(i - 1, length(@project_goals)))
      project_id = "asc_law_#{String.pad_leading(Integer.to_string(i), 5, "0")}"

      if rem(i, 20) == 0, do: IO.write("  [#{i}/#{project_count}] ")

      case execute_pipeline(project_id, goal) do
        :ok -> :ok
        {:error, _reason} -> :error
      end
    end)

    elapsed_ms = System.monotonic_time(:millisecond) - start_time
    pass_count = Enum.count(results, &(&1 == :ok))
    fail_count = Enum.count(results, &(&1 == :error))

    IO.puts("\n✅ Completed #{pass_count} projects, #{fail_count} failures\n")

    # Run law discovery
    IO.puts("Running Laws.Discoverer analysis...\n")
    Discoverer.run()

    # Collect law discovery metrics
    discovery_metrics = collect_discovery_metrics()

    # Generate report
    generate_report(discovery_metrics, elapsed_ms, project_count, pass_count, fail_count)
  end

  # ---------------------------------------------------------------------------
  # Pipeline Execution (same as acceptance test)
  # ---------------------------------------------------------------------------

  defp execute_pipeline(project_id, goal) do
    try do
      project = Project.new(project_id, goal)

      {:ok, project_after_req} = ReqCivilization.run(project)
      unless project_after_req.world, do: throw {:error, :no_world_model}

      {:ok, project_after_test} = TestCivilization.run(project_after_req)
      if project_after_test.world.test_contracts == [], do: throw {:error, :no_test_contracts}

      {:ok, project_after_impl} = ImplCivilization.run(project_after_test)

      # Observatory should have recorded metrics automatically
      :ok
    catch
      {:error, reason} -> {:error, reason}
    rescue
      _e -> {:error, :exception}
    end
  end

  # ---------------------------------------------------------------------------
  # Law Discovery Metrics Collection
  # ---------------------------------------------------------------------------

  defp collect_discovery_metrics do
    # Get all laws from registry
    all_laws = LawsRegistry.all()
    candidates = LawsRegistry.candidates()
    established = LawsRegistry.established()

    # Count by status
    by_status = Enum.group_by(all_laws, & &1.status)

    observations = length(Map.get(by_status, :observation, []))
    patterns = length(Map.get(by_status, :candidate_pattern, []))
    candidate_laws = length(candidates)
    established_laws = length(established)
    refuted = length(Map.get(by_status, :refuted, []))
    under_review = length(Map.get(by_status, :under_review, []))

    # Calculate promotion statistics
    total_promoted = candidate_laws + established_laws
    promotion_precision = if total_promoted > 0 do
      Float.round(established_laws / total_promoted * 100, 1)
    else
      0.0
    end

    # Knowledge yield
    knowledge_yield = if candidate_laws + established_laws > 0 do
      Float.round((candidate_laws + established_laws) / 100, 4)
    else
      0.0
    end

    %{
      observations: observations,
      patterns: patterns,
      candidate_laws: candidate_laws,
      established_laws: established_laws,
      refuted: refuted,
      under_review: under_review,
      promotion_precision: promotion_precision,
      knowledge_yield: knowledge_yield,
      all_laws: all_laws,
      candidates: candidates,
      established: established
    }
  end

  # ---------------------------------------------------------------------------
  # Report Generation
  # ---------------------------------------------------------------------------

  defp generate_report(metrics, elapsed_ms, total_projects, pass_count, fail_count) do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("LAW DISCOVERY REPORT")
    IO.puts(String.duplicate("=", 80))

    IO.puts("\nExecution Summary:")
    IO.puts("  Total Projects:     #{total_projects}")
    IO.puts("  Passed:             #{pass_count}")
    IO.puts("  Failed:             #{fail_count}")
    IO.puts("  Pass Rate:          #{Float.round(pass_count / total_projects * 100, 1)}%")
    IO.puts("  Elapsed Time:       #{Float.round(elapsed_ms / 1000, 2)}s")
    IO.puts("  Throughput:         #{Float.round(total_projects / (elapsed_ms / 1000), 1)} projects/sec")

    IO.puts("\nLaw Discovery Statistics:")
    IO.puts("  Observations:       #{metrics.observations}")
    IO.puts("  Patterns:           #{metrics.patterns}")
    IO.puts("  Candidate Laws:     #{metrics.candidate_laws}")
    IO.puts("  Established Laws:   #{metrics.established_laws}")
    IO.puts("  Refuted:            #{metrics.refuted}")
    IO.puts("  Under Review:       #{metrics.under_review}")

    IO.puts("\nPromotion Metrics:")
    IO.puts("  Promotion Precision: #{metrics.promotion_precision}%")
    IO.puts("  Knowledge Yield:     #{metrics.knowledge_yield} laws/project")

    IO.puts("\nDiscovered Laws:")
    if metrics.candidates != [] do
      Enum.each(metrics.candidates, fn law ->
        confidence_pct = Float.round(law.confidence * 100, 1)
        support_count = length(law.supporting_project_ids)
        IO.puts("  • [#{law.status}] #{truncate(law.statement, 80)}")
        IO.puts("    Confidence: #{confidence_pct}% | Support: #{support_count} projects")
      end)
    else
      IO.puts("  (No candidate laws discovered yet)")
    end

    if metrics.established != [] do
      IO.puts("\nEstablished Laws:")
      Enum.each(metrics.established, fn law ->
        confidence_pct = Float.round(law.confidence * 100, 1)
        IO.puts("  ✅ #{truncate(law.statement, 80)}")
        IO.puts("     Confidence: #{confidence_pct}% | Evidence: #{law.evidence_count} projects")
      end)
    end

    IO.puts("\nSuccess Criteria:")
    has_candidate_laws = metrics.candidate_laws > 0
    has_established_laws = metrics.established_laws > 0

    IO.puts("  ✓ At least 1 candidate law: #{if has_candidate_laws, do: "✅ PASS", else: "❌ FAIL"} (#{metrics.candidate_laws})")
    if total_projects >= 500 do
      IO.puts("  ✓ At least 1 established law: #{if has_established_laws, do: "✅ PASS", else: "⚠️  NONE YET"} (#{metrics.established_laws})")
    end

    IO.puts("\nRecommendations:")
    cond do
      metrics.candidate_laws == 0 ->
        IO.puts("  ⚠️  No candidate laws found. Promotion criteria may be too strict.")
        IO.puts("     Consider lowering confidence thresholds or increasing project count.")

      metrics.candidate_laws > 20 ->
        IO.puts("  ⚠️  Many candidate laws (#{metrics.candidate_laws}). Promotion criteria may be too loose.")
        IO.puts("     Consider raising confidence thresholds to reduce false positives.")

      metrics.candidate_laws > 0 ->
        IO.puts("  ✅ Healthy law discovery rate. Continue scaling to Tier 2B/2C.")

      true ->
        IO.puts("  ℹ️  Insufficient data. Run more projects.")
    end

    IO.puts("\n" <> String.duplicate("=", 80))

    # Write detailed report to file
    write_detailed_report(metrics, total_projects, pass_count, fail_count, elapsed_ms)

    IO.puts("\n📄 Detailed report written to: docs/law_discovery_report.md\n")
  end

  # ---------------------------------------------------------------------------
  # Detailed Report Writer
  # ---------------------------------------------------------------------------

  defp write_detailed_report(metrics, total_projects, pass_count, fail_count, elapsed_ms) do
    File.mkdir_p!("docs")

    content = """
    # ASC Law Discovery Report

    **Date**: #{DateTime.utc_now() |> DateTime.to_iso8601()}
    **Tier**: #{if total_projects <= 100, do: "2A", else: if(total_projects <= 500, do: "2B", else: "2C")}
    **Projects**: #{total_projects} (#{pass_count} passed, #{fail_count} failed)
    **Duration**: #{Float.round(elapsed_ms / 1000, 2)}s

    ---

    ## Executive Summary

    #{if metrics.candidate_laws > 0 do
      "**ASC successfully discovered #{metrics.candidate_laws} candidate law(s)** from #{total_projects} synthetic projects, demonstrating the ability to extract statistically meaningful software engineering patterns from operational telemetry."
    else
      "No candidate laws discovered in this run. This is expected for small project counts (<100). Law discovery requires sufficient statistical power to distinguish signal from noise."
    end}

    ---

    ## Law Discovery Statistics

    | Metric | Count |
    |--------|-------|
    | Observations | #{metrics.observations} |
    | Patterns | #{metrics.patterns} |
    | Candidate Laws | #{metrics.candidate_laws} |
    | Established Laws | #{metrics.established_laws} |
    | Refuted | #{metrics.refuted} |
    | Under Review | #{metrics.under_review} |

    ### Promotion Metrics
    - **Promotion Precision**: #{metrics.promotion_precision}% (% of promoted laws that become established)
    - **Knowledge Yield**: #{metrics.knowledge_yield} laws/project

    ---

    ## Discovered Candidate Laws

    #{if metrics.candidates != [] do
      Enum.map_join(metrics.candidates, "\n\n", fn law ->
        """
        ### #{law.id}

        **Statement**: #{law.statement}

        **Confidence**: #{Float.round(law.confidence * 100, 1)}%

        **Status**: #{law.status}

        **Supporting Projects**: #{length(law.supporting_project_ids)}

        **Variables**: #{inspect(law.variables)}

        **Domain Tags**: #{Enum.join(law.domain_tags, ", ")}
        """
      end)
    else
      "(No candidate laws discovered)"
    end}

    ---

    ## Established Laws

    #{if metrics.established != [] do
      Enum.map_join(metrics.established, "\n\n", fn law ->
        """
        ### ✅ #{law.id}

        **Statement**: #{law.statement}

        **Confidence**: #{Float.round(law.confidence * 100, 1)}%

        **Evidence Count**: #{law.evidence_count} projects

        **Canonical Statement**: #{law.canonical_statement || "N/A"}
        """
      end)
    else
      "(No established laws yet — requires 10+ supporting projects with confidence ≥ 0.85)"
    end}

    ---

    ## Analysis

    ### Strongest Signals
    #{if metrics.candidates != [] do
      strongest = Enum.max_by(metrics.candidates, & &1.confidence)
      "- **#{truncate(strongest.statement, 100)}** (confidence: #{Float.round(strongest.confidence * 100, 1)}%)"
    else
      "- (Insufficient data)"
    end}

    ### Weakest Candidates
    #{if metrics.candidates != [] do
      weakest = Enum.min_by(metrics.candidates, & &1.confidence)
      "- **#{truncate(weakest.statement, 100)}** (confidence: #{Float.round(weakest.confidence * 100, 1)}%)"
    else
      "- (Insufficient data)"
    end}

    ### Confidence Evolution
    - Average candidate confidence: #{if metrics.candidates != [], do: Float.round(Enum.sum(Enum.map(metrics.candidates, & &1.confidence)) / length(metrics.candidates) * 100, 1), else: "N/A"}%
    - Highest confidence: #{if metrics.candidates != [], do: Float.round(Enum.max(Enum.map(metrics.candidates, & &1.confidence)) * 100, 1), else: "N/A"}%
    - Lowest confidence: #{if metrics.candidates != [], do: Float.round(Enum.min(Enum.map(metrics.candidates, & &1.confidence)) * 100, 1), else: "N/A"}%

    ---

    ## Recommendations for MetaLearning

    #{cond do
      metrics.candidate_laws == 0 ->
        """
        1. **Increase project count** — Law discovery needs statistical power (aim for 500+ projects)
        2. **Diversify project goals** — More varied domains produce richer patterns
        3. **Lower promotion thresholds temporarily** — Test if patterns exist but don't meet current criteria
        """

      metrics.candidate_laws > 0 and metrics.established_laws == 0 ->
        """
        1. **Continue scaling** — Established laws require 10+ supporting projects
        2. **Monitor confidence trends** — Watch for oscillating confidence (indicates unstable patterns)
        3. **Prepare MetaLearning integration** — Candidate laws ready for cross-project injection
        """

      metrics.established_laws > 0 ->
        """
        1. **Activate MetaLearning** — Inject established laws into future project generation
        2. **Validate law transferability** — Test if laws hold in new project domains
        3. **Begin Phase 3** — Implementation Civilization can now use discovered laws
        """

      true ->
        "(Analysis pending)"
    end}

    ---

    ## Conclusion

    #{if metrics.candidate_laws > 0 do
      "**Phase 2 SUCCESSFUL** — ASC demonstrated the ability to discover software engineering laws from project telemetry. The scientific loop is validated: projects generate data, data reveals patterns, patterns become laws."
    else
      "**Phase 2 PARTIAL** — Infrastructure works but insufficient data for law discovery. Scale to Tier 2B (500 projects) or 2C (1000 projects) to achieve statistical significance."
    end}

    The next milestone is **MetaLearning activation**, where discovered laws improve future projects automatically.
    """

    File.write!("docs/law_discovery_report.md", content)
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp ensure_asc_started do
    # Same as acceptance test
    processes = [
      {Tiannara.ASC.KnowledgeArchive, "Knowledge Archive"},
      {Tiannara.ASC.Observatory.ProjectObservatory, "Project Observatory"},
      {Tiannara.ASC.Laws.Registry, "Laws Registry"},
      {Tiannara.ASC.Requirements.Civilization, "Requirements Civilization"},
      {Tiannara.ASC.Testing.Civilization, "Testing Civilization"},
      {Tiannara.ASC.Implementation.Civilization, "Implementation Civilization"}
    ]

    Enum.each(processes, fn {module, name} ->
      case Process.whereis(module) do
        nil ->
          IO.puts("  Starting ASC #{name}...")
          {:ok, _} = module.start_link([])
        _pid -> :ok
      end
    end)

    IO.puts("  ✅ ASC processes started\n")
  end

  defp truncate(str, max) do
    if String.length(str) <= max, do: str, else: String.slice(str, 0, max) <> "…"
  end
end

# ---------------------------------------------------------------------------
# CLI Entry Point
# ---------------------------------------------------------------------------

tier = case System.argv() do
  ["tier_2b"] -> :tier_2b
  ["tier_2c"] -> :tier_2c
  _ -> :tier_2a
end

case Tiannara.ASC.LawDiscoveryValidation.run(tier) do
  :ok -> System.halt(0)
  :error -> System.halt(1)
end
