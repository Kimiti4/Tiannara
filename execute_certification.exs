# Execute Governance Certification Campaigns
IO.puts("\n🔬 Starting Phase 14.0.99 Campaign Execution...\n")

# Start required GenServers for certification
IO.puts("Starting GovernanceLedger...")
{:ok, _pid} = TiannaraOS.Governance.GovernanceLedger.start_link([])
IO.puts("✅ GovernanceLedger started")

IO.puts("Starting GovernanceCostLedger...")
{:ok, _pid} = TiannaraOS.Governance.GovernanceCostLedger.start_link([])
IO.puts("✅ GovernanceCostLedger started")

# Run certification
case TiannaraOS.Governance.Certification.Laboratory.execute_certification() do
  {:ok, certificate} ->
    IO.puts("\n✅ CERTIFICATION COMPLETE")
    IO.puts("Campaigns Executed: #{certificate.campaigns_executed}")
    IO.puts("Campaigns Passed: #{certificate.campaigns_passed}")
    IO.puts("Campaigns Failed: #{certificate.campaigns_failed}")
    IO.puts("Governance Version: #{certificate.governance_version}")
    IO.puts("Certification Status: #{certificate.certification_status}")
    
    # Save certificate to file (encode just the certificate map, not the tuple)
    cert_json = Jason.encode!(certificate, pretty: true)
    File.write!("PHASE14_GOVERNANCE_CERTIFICATE.json", cert_json)
    IO.puts("\n💾 Certificate saved to PHASE14_GOVERNANCE_CERTIFICATE.json")
    
  {:error, failed_campaigns} ->
    IO.puts("\n❌ CERTIFICATION FAILED")
    IO.puts("Failed campaigns: #{inspect(failed_campaigns)}")
end
