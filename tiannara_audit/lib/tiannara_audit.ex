defmodule TiannaraAudit do
  @moduledoc """
  Phase 16.X.96 — Independent Constitutional Mathematics Audit

  Standalone auditor that consumes artifacts from the runtime and independently
  verifies hashes, proof fingerprints, graph roots, and runtime fingerprints
  WITHOUT importing the TiannaraRuntime mathematics modules.
  """

  alias TiannaraAudit.{HashVerifier, ProofVerifier, GraphVerifier, RuntimeVerifier}

  @default_artifact "artifact_data.term"
  @report_dir "."
  @report_file "INDEPENDENT_AUDIT_REPORT.md"

  def main(args \\ []) do
    IO.puts("""
    ╔══════════════════════════════════════════════════════════════╗
    ║  Phase 16.X.96 — Independent Constitutional Mathematics     ║
    ║  Audit                                                      ║
    ║                                                              ║
    ║  Consumes artifacts only. No runtime modules imported.      ║
    ╚══════════════════════════════════════════════════════════════╝
    """)

    artifacts_path = resolve_path(List.first(args, @default_artifact))
    unless File.exists?(artifacts_path) do
      IO.puts("❌ Artifact data not found at: #{artifacts_path}")
      IO.puts("   Usage: #{:escript.script_name()} <path/to/artifact_data.term>")
      exit({:shutdown, 1})
    end
    artifacts = load_artifacts(artifacts_path)
    results = run_all_verifications(artifacts)
    report = generate_report(results)
    write_report(report)

    print_summary(results)
    results
  end

  defp resolve_path(path) do
    Path.expand(path)
  end

  defp load_artifacts(path) do
    :erlang.binary_to_term(File.read!(path))
  end

  defp run_all_verifications(artifacts) do
    %{
      hash_verification: HashVerifier.verify(artifacts[:hash_samples] || []),
      proof_verification: ProofVerifier.verify(artifacts[:proof_samples] || []),
      graph_verification: GraphVerifier.verify(artifacts[:graph_samples] || []),
      runtime_verification: RuntimeVerifier.verify(artifacts[:runtime_samples] || [])
    }
  end

  defp generate_report(results) do
    total_checks = count_total_checks(results)
    passed_checks = count_passed_checks(results)
    failed_checks = total_checks - passed_checks
    overall = if failed_checks == 0, do: "✅ PASS", else: "❌ FAIL"

    content = [
      "# Independent Constitutional Mathematics Audit",
      "**Phase 16.X.96**",
      "",
      "## Overview",
      "",
      "| Field | Value |",
      "|-------|-------|",
      "| Audit Version | 1.0.0 |",
      "| Methodology | Artifact-only. No runtime modules imported. |",
      "| Hash Algorithm | SHA-256 via `:crypto.hash/2` |",
      "| Canonical JSON | `Jason.encode!/1` after key-sorted canonicalization |",
      "| Generated | #{DateTime.utc_now() |> DateTime.to_iso8601()} |",
      "| Overall Status | #{overall} |",
      "| Total Checks | #{total_checks} |",
      "| Passed | #{passed_checks} |",
      "| Failed | #{failed_checks} |",
      "",
      "## Verification Results",
      "",
      format_result_table(results),
      "",
      "## Detailed Results",
      "",
      format_detailed_results(results),
      "",
      "---",
      "",
      "_End of Phase 16.X.96 Independent Audit Report_"
    ]

    Enum.join(content, "\n")
  end

  defp format_result_table(results) do
    rows = Enum.map(results, fn {category, result} ->
      status = if result.failures == 0, do: "✅ PASS", else: "❌ FAIL"
      "| #{format_category(category)} | #{result.total} | #{result.failures} | #{status} |"
    end)

    ["| Category | Checks | Failures | Status |",
     "|----------|--------|----------|--------|"] ++ rows
    |> Enum.join("\n")
  end

  defp format_detailed_results(results) do
    Enum.map(results, fn {category, result} ->
      ["### #{format_category(category)}",
       "",
       "**#{result.total} checks, #{result.failures} failures**",
       ""] ++
      if result.details == [] do
        ["  - All checks passed."]
      else
        Enum.map(result.details, fn d -> "  - ❌ #{d}" end)
      end ++
      [""]
    end)
    |> List.flatten()
    |> Enum.join("\n")
  end

  defp format_category(:hash_verification), do: "Hash Verification"
  defp format_category(:proof_verification), do: "Proof Fingerprint Verification"
  defp format_category(:graph_verification), do: "Graph Root Verification"
  defp format_category(:runtime_verification), do: "Runtime Fingerprint Verification"
  defp format_category(_), do: "Unknown"

  defp count_total_checks(results) do
    Enum.reduce(results, 0, fn {_k, r}, acc -> acc + r.total end)
  end

  defp count_passed_checks(results) do
    Enum.reduce(results, 0, fn {_k, r}, acc -> acc + (r.total - r.failures) end)
  end

  defp print_summary(results) do
    total = count_total_checks(results)
    passed = count_passed_checks(results)
    failed = total - passed

    IO.puts("""
    ╔══════════════════════════════════════════════╗
    ║  Phase 16.X.96 — Audit Summary               ║
    ╠══════════════════════════════════════════════╣
    ║  Total checks    : #{String.pad_leading("#{total}", 21)} ║
    ║  Passed          : #{String.pad_leading("#{passed}", 21)} ║
    ║  Failed          : #{String.pad_leading("#{failed}", 21)} ║
    ║  Overall status  : #{String.pad_leading("#{if failed == 0, do: "pass", else: "fail"}", 18)} ║
    ╚══════════════════════════════════════════════╝
    """)

    Enum.each(results, fn {_category, result} ->
      if result.failures > 0 do
        IO.puts("  ❌ #{result.failures} failure(s) in #{format_category(result)}")
        Enum.each(result.details, fn d -> IO.puts("     #{d}") end)
      end
    end)
  end

  defp write_report(content) do
    dir = Path.expand(@report_dir, __DIR__)
    path = Path.join(dir, @report_file)
    File.mkdir_p!(dir)
    File.write!(path, content)
    IO.puts("Report written to #{path}")
  end
end
