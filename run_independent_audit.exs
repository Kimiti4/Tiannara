# Run Independent Governance Audit
IO.puts("\n🔍 Starting Phase 14.0.997 Independent Audit...\n")

# Start required GenServers for audit
IO.puts("Starting GovernanceLedger...")
{:ok, _pid} = TiannaraOS.Governance.GovernanceLedger.start_link([])
IO.puts("✅ GovernanceLedger started")

IO.puts("Starting GovernanceCostLedger...")
{:ok, _pid} = TiannaraOS.Governance.GovernanceCostLedger.start_link([])
IO.puts("✅ GovernanceCostLedger started")

# Run independent audit
case TiannaraOS.Governance.Certification.IndependentAuditor.full_audit() do
  {:ok, audit_report} ->
    IO.puts("\n✅ AUDIT COMPLETE")
    IO.puts("Overall Verdict: #{audit_report.overall_verdict}")
    IO.puts("Confidence Score: #{Float.round(audit_report.confidence_score * 100, 2)}%")
    IO.puts("Discrepancies Found: #{length(audit_report.discrepancies_found)}")
    
    # Save audit report to file
    audit_json = Jason.encode!(audit_report, pretty: true)
    File.write!("PHASE14_INDEPENDENT_AUDIT_REPORT.json", audit_json)
    IO.puts("\n💾 Audit report saved to PHASE14_INDEPENDENT_AUDIT_REPORT.json")
    
  {:error, reason} ->
    IO.puts("\n❌ AUDIT FAILED")
    IO.puts("Reason: #{reason}")
end
