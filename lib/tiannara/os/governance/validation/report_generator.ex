defmodule TiannaraOS.Governance.Validation.ReportGenerator do
  @moduledoc """
  ReportGenerator - Produces human-readable validation reports from aggregated data.
  
  Generates markdown reports, JSON exports, and validation certificates.
  """

  @doc """
  Generate comprehensive markdown validation report.
  """
  @spec generate_report(map(), [map()]) :: :ok
  def generate_report(summary, evidence) do
    report = """
# Governance Validation Report

**Generated**: #{DateTime.to_iso8601(summary.timestamp)}
**Status**: #{summary.overall_status |> Atom.to_string() |> String.upcase()}
**Freeze Recommendation**: #{summary.freeze_recommendation |> Atom.to_string() |> String.upcase()}

---

## Summary

- **Total Campaigns**: #{summary.total_campaigns}
- **Passed**: #{summary.passed_campaigns}
- **Failed**: #{summary.failed_campaigns}

---

## Conclusion

The governance validation campaign has completed with status **#{summary.overall_status |> Atom.to_string() |> String.upcase()}**.

#{if summary.freeze_recommendation == :freeze do
  "**✅ RECOMMENDATION**: Governance layer is ready for freeze."
else
  "**⚠️ RECOMMENDATION**: Governance layer requires fixes before freeze."
end}

---

**Evidence Artifacts**: #{length(evidence)} artifacts generated in `evidence/` directory (content-addressed)
"""

    File.write!("docs/GOVERNANCE_VALIDATION_REPORT.md", report)
    IO.puts("📄 Report generated: docs/GOVERNANCE_VALIDATION_REPORT.md")
    
    :ok
  end
end
