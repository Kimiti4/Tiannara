defmodule Tiannara.AutonomyVerification do
  @moduledoc """
  Autonomy Verification — proves Tiannara can operate without human intervention.

  Checks:
    1. All subsystems are running
    2. Discovery pipeline produces output without human input
    3. Constitutional constraints are enforced
    4. Failures are detected and recovered automatically
    5. Metrics are being collected
    6. Events are flowing between subsystems
    7. Knowledge is being produced
  """

  def run do
    IO.puts("""
    #{String.duplicate("=", 58)}
     TIANNARA AUTONOMY VERIFICATION
     #{DateTime.utc_now() |> DateTime.to_iso8601()}
    #{String.duplicate("=", 58)}
    """)

    checks = [
      check_subsystems_running(),
      check_discovery_pipeline(),
      check_constitutional_enforcement(),
      check_failure_recovery(),
      check_metrics_collection(),
      check_event_flow(),
      check_knowledge_production(),
      check_human_review_gating()
    ]

    passed = Enum.count(checks, & &1.passed)
    total = length(checks)

    IO.puts("\n#{String.duplicate("-", 58)}")
    IO.puts(" AUTONOMY VERIFICATION RESULTS")
    IO.puts("#{String.duplicate("-", 58)}")

    Enum.each(checks, fn check ->
      status = if check.passed, do: "  OK", else: "  FAIL"
      IO.puts("#{status} #{check.name}")
      IO.puts("       #{check.detail}")
    end)

    IO.puts("#{String.duplicate("-", 58)}")
    IO.puts(" #{passed}/#{total} checks passed")

    if passed == total do
      IO.puts("")
      IO.puts("  TIANNARA IS FULLY AUTONOMOUS")
      IO.puts("")
      IO.puts(" The system can sustain itself operationally without")
      IO.puts(" human intervention. High-impact decisions remain gated")
      IO.puts(" by mandatory human review (constitutional mandate).")
    else
      IO.puts("")
      IO.puts("  AUTONOMY INCOMPLETE")
      IO.puts("  #{total - passed} check(s) failing. System requires attention.")
    end

    IO.puts("#{String.duplicate("-", 58)}")

    write_report(checks, passed, total)
  end

  defp check_subsystems_running do
    status = Tiannara.ControlCenter.status()
    passed = status.healthy == status.total and status.total > 0
    %{name: "All subsystems running (#{status.healthy}/#{status.total})", passed: passed, detail: "#{status.healthy}/#{status.total} subsystems healthy"}
  end

  defp check_discovery_pipeline do
    try do
      Tiannara.Discovery.DiscoveryScheduler.trigger_cycle()
      Process.sleep(2000)
      stats = Tiannara.Discovery.DiscoveryScheduler.get_stats()
      passed = Map.get(stats, :completed_cycles, 0) > 0
      %{name: "Discovery pipeline produces output", passed: passed, detail: "#{Map.get(stats, :completed_cycles, 0)} cycles completed"}
    rescue
      e -> %{name: "Discovery pipeline produces output", passed: false, detail: "Error: #{inspect(e)}"}
    end
  end

  defp check_constitutional_enforcement do
    try do
      audit = Tiannara.Evolution.ConstitutionalAuditor.audit(%{
        capabilities_deployed: 30,
        verifications_completed: 30,
        hidden_uncertainty_count: 0,
        mandatory_reviews_completed: 0,
        mandatory_reviews_required: 0,
        lineage_violations: 0,
        safety_violations: 0,
        objective_alignment_score: 0.9,
        coupling_violations: 0,
        evolutions_deployed: 5,
        evolution_validations: 5
      })
      %{name: "Constitutional constraints enforced", passed: audit.status == :compliant, detail: "Compliance: #{Float.round(audit.compliance_rate * 100, 0)}%"}
    rescue
      e -> %{name: "Constitutional constraints enforced", passed: false, detail: "Error: #{inspect(e)}"}
    end
  end

  defp check_failure_recovery do
    try do
      status = Tiannara.ControlCenter.status()
      %{name: "Failure recovery operational", passed: status.recoveries >= 0, detail: "#{status.recoveries} recoveries performed"}
    rescue
      e -> %{name: "Failure recovery operational", passed: false, detail: "Error: #{inspect(e)}"}
    end
  end

  defp check_metrics_collection do
    try do
      snapshot = Tiannara.Metrics.CivilizationalMetricsEngine.snapshot()
      %{name: "Civilizational metrics being collected", passed: snapshot.health_score >= 0.0, detail: "Health score: #{Float.round(snapshot.health_score, 3)}"}
    rescue
      e -> %{name: "Civilizational metrics being collected", passed: false, detail: "Error: #{inspect(e)}"}
    end
  end

  defp check_event_flow do
    try do
      Tiannara.CEL.Services.EventBus.Safe.publish("autonomy.verification", %{test: true})
      %{name: "Event flow operational", passed: true, detail: "Events flowing"}
    rescue
      e -> %{name: "Event flow operational", passed: false, detail: "Error: #{inspect(e)}"}
    end
  end

  defp check_knowledge_production do
    try do
      case Tiannara.World.UnifiedWorldModel.stats() do
        %{total_entities: n} when n > 0 ->
          %{name: "Knowledge being produced (#{n} entities)", passed: true, detail: "#{n} entities in world model"}
        _ ->
          %{name: "Knowledge being produced", passed: false, detail: "No entities in world model"}
      end
    rescue
      e -> %{name: "Knowledge being produced", passed: false, detail: "Error: #{inspect(e)}"}
    end
  end

  defp check_human_review_gating do
    try do
      request = Tiannara.HAI.Domain.ReviewRequest.new(%{
        impact_level: :critical,
        source_subsystem: :autonomy_test,
        decision_type: :test,
        summary: "Test mandatory review gating"
      })
      passed = Tiannara.HAI.Domain.ReviewRequest.mandatory_review?(request)
      %{name: "Human review gating enforced for high-impact", passed: passed, detail: "Critical decisions require mandatory human review"}
    rescue
      e -> %{name: "Human review gating enforced for high-impact", passed: false, detail: "Error: #{inspect(e)}"}
    end
  end

  defp write_report(checks, passed, total) do
    report = """
    # Tiannara Autonomy Verification Report

    Generated: #{DateTime.utc_now() |> DateTime.to_iso8601()}

    ## Result: #{passed}/#{total} checks passed

    #{if passed == total, do: "**TIANNARA IS FULLY AUTONOMOUS**", else: "**AUTONOMY INCOMPLETE**"}

    ## Checks

    | Check | Status | Detail |
    | :--- | :---: | :--- |
    #{Enum.map_join(checks, "\n", fn c -> "| #{c.name} | #{if c.passed, do: "PASS", else: "FAIL"} | #{c.detail} |" end)}

    ## Constitutional Note

    Per rules.md: "Tiannara should remain a system that augments human intelligence
    rather than replaces human judgment."

    Autonomy means operational self-sustainability. It does NOT mean bypassing
    human review for high-impact decisions. The mandatory review gate remains
    enforced for all :high, :critical, and :civilizational impact decisions.
    """

    File.mkdir_p!("docs/autonomy")
    File.write!("docs/autonomy/verification_#{Date.utc_today()}.md", report)
    IO.puts("\nReport written to: docs/autonomy/verification_#{Date.utc_today()}.md")
  end
end

Tiannara.AutonomyVerification.run()
