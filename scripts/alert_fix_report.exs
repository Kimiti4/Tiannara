defmodule Tiannara.Audit.AlertFixReport do
  @audit_dir "docs/audit"

  def run do
    IO.puts("═══ TIANNARA PRODUCTION AUDIT ═══\n")
    findings = [
      check_fix1_topic_alignment(),
      check_fix2_feedback_listener(),
      check_fix3_no_mock_bypass(),
      check_eventbus_dets_health(),
      check_resource_manager(),
      check_phase8b_reality_anchoring(),
      check_compiler_warnings()
    ]
    report = build_report(findings)
    path = write_report(report)
    print_summary(findings, path)
    report
  end

  defp check_fix1_topic_alignment do
    loaded = Code.ensure_loaded?(Tiannara.ASC.Engineering.Director)
    aligned = loaded and source_contains?(Tiannara.ASC.Engineering.Director, "campaign.phase8a.input")
    %{id: "FIX-1", title: "EngineeringDirector subscribes to campaign.phase8a.input", severity: :critical, status: (if aligned, do: :pass, else: :verify), evidence: "module loaded=#{loaded}; source aligned=#{aligned}"}
  end

  defp check_fix2_feedback_listener do
    pid = Process.whereis(Tiannara.Operations.Phase5FeedbackListener)
    %{id: "FIX-2", title: "Phase5FeedbackListener in supervision tree", severity: :critical, status: (if pid != nil, do: :pass, else: :fail), evidence: "pid=#{inspect(pid)}"}
  end

  defp check_fix3_no_mock_bypass do
    no_stub = source_contains?(Tiannara.CRAV.AlphaLaunch, "SoakTest.status") or source_contains?(Tiannara.CRAV.AlphaLaunch, "determine_soak_hours")
    %{id: "FIX-3", title: "Alpha launch gate reads real soak status (no hardcoded stub)", severity: :critical, status: (if no_stub, do: :pass, else: :verify), evidence: "real-status read present=#{no_stub}"}
  end

  defp check_eventbus_dets_health do
    bus = Process.whereis(Tiannara.CEL.Services.EventBus)
    {status, evidence} = cond do
      bus == nil -> {:fail, "EventBus not running — likely DETS cold-boot corruption"}
      true ->
        try do
          Tiannara.CEL.Services.EventBus.publish("audit.probe", %{at: DateTime.utc_now()})
          {:pass, "EventBus alive (#{inspect(bus)}) and accepting publishes"}
        rescue
          e -> {:fail, "EventBus alive but publish raised: #{inspect(e)}"}
        end
    end
    %{id: "RT-EVENTBUS", title: "EventBus + EventStore DETS health", severity: :critical, status: status, evidence: evidence, recommendation: "Apply ResilientDETS wrapper (see hardening note) so cold boot self-heals"}
  end

  defp check_resource_manager do
    pid = Process.whereis(Tiannara.CEL.Services.ResourceManager)
    %{id: "RT-RESOURCEMGR", title: "ResourceManager initialized", severity: :high, status: (if pid != nil, do: :pass, else: :fail), evidence: "pid=#{inspect(pid)}", recommendation: "Add init guard + lazy pool initialization"}
  end

  defp check_phase8b_reality_anchoring do
    loaded = Code.ensure_loaded?(Tiannara.ASC.Reality.Director)
    subscribed = loaded and source_contains?(Tiannara.ASC.Reality.Director, "campaign.phase8b.input")
    %{id: "RT-PHASE8B", title: "RealityDirector wired to phase8b/phase9 topics", severity: :high, status: (if subscribed, do: :pass, else: :verify), evidence: "module loaded=#{loaded}; phase8b subscription=#{subscribed}"}
  end

  defp check_compiler_warnings do
    %{id: "DEBT-WARNINGS", title: "Compiler warnings (unused vars/aliases)", severity: :medium, status: :info, evidence: "Run: mix compile --force 2>&1 | findstr /c:\"warning:\"", recommendation: "Batch cleanup — see hardening note"}
  end

  defp build_report(findings) do
    %{generated_at: DateTime.utc_now() |> DateTime.to_iso8601(), node: to_string(node()), findings: findings, counts: %{critical: count_by(findings, :critical), high: count_by(findings, :high), medium: count_by(findings, :medium), pass: Enum.count(findings, &(&1.status == :pass)), fail: Enum.count(findings, &(&1.status == :fail)), verify: Enum.count(findings, &(&1.status == :verify))}}
  end

  defp write_report(report) do
    File.mkdir_p!(@audit_dir)
    ts = DateTime.utc_now() |> DateTime.to_iso8601() |> String.replace(":", "-")
    md_path = Path.join(@audit_dir, "audit_#{ts}.md")
    json_path = Path.join(@audit_dir, "audit_#{ts}.json")
    File.write!(md_path, render_markdown(report))
    File.write!(json_path, Jason.encode!(report, pretty: true))
    {md_path, json_path}
  end

  defp render_markdown(report) do
    rows = report.findings |> Enum.map(fn f -> "| #{f.id} | #{severity_badge(f.severity)} | #{status_icon(f.status)} | #{f.title} | #{f.evidence} |" end) |> Enum.join("\n")
    recs = report.findings |> Enum.filter(&Map.has_key?(&1, :recommendation)) |> Enum.map(fn f -> "- **#{f.id}**: #{f.recommendation}" end) |> Enum.join("\n")

    """
# Tiannara Production Audit

Generated: #{report.generated_at}
Node: `#{report.node}`

## Summary

| Severity | Count |
| :--- | :---: |
| Critical | #{report.counts.critical} |
| High | #{report.counts.high} |
| Medium | #{report.counts.medium} |

| Status | Count |
| :--- | :---: |
| ✅ Pass | #{report.counts.pass} |
| ❌ Fail | #{report.counts.fail} |
| ⚠ Verify | #{report.counts.verify} |

## Findings

| ID | Severity | Status | Title | Evidence |
| :--- | :---: | :---: | :--- | :--- |
#{rows}

## Recommendations

#{recs}

---
_Reproduce with `mix run scripts/alert_fix_report.exs`_
    """
  end

  defp print_summary(findings, {md_path, json_path}) do
    IO.puts("\n── FINDINGS ──")
    Enum.each(findings, fn f -> IO.puts("  #{status_icon(f.status)} [#{f.severity}] #{f.id}: #{f.title}\n       #{f.evidence}") end)
    fails = Enum.count(findings, &(&1.status == :fail))
    IO.puts("\n── REPORT WRITTEN ──")
    IO.puts("  Markdown: #{md_path}\n  JSON:     #{json_path}")
    if fails > 0 do
      IO.puts("\n⚠  #{fails} finding(s) FAILED — review before declaring production-ready.")
    else
      IO.puts("\n✅ No failed findings. Verify-items need manual confirmation.")
    end
  end

  defp source_contains?(module, needle) do
    case module.module_info(:compile)[:source] do
      nil -> false
      src -> case File.read(to_string(src)) do {:ok, content} -> String.contains?(content, needle); _ -> false end
    end
  rescue _ -> false
  end

  defp count_by(findings, severity), do: Enum.count(findings, &(&1.severity == severity))
  defp severity_badge(:critical), do: "CRITICAL"
  defp severity_badge(:high), do: "HIGH"
  defp severity_badge(:medium), do: "MEDIUM"
  defp severity_badge(:low), do: "LOW"
  defp status_icon(:pass), do: "✅"
  defp status_icon(:fail), do: "❌"
  defp status_icon(:verify), do: "⚠"
  defp status_icon(:info), do: "ℹ"
end

Tiannara.Audit.AlertFixReport.run()
