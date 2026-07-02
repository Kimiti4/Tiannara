# Archaeological Reconstruction Test - Phase 14 RC3
IO.puts("\n🏛️  Running Archaeological Reconstruction Test...\n")

# Start required GenServers
{:ok, _pid} = TiannaraOS.Governance.GovernanceLedger.start_link([])
{:ok, _pid} = TiannaraOS.Governance.GovernanceCostLedger.start_link([])

# Run reconstruction test
case TiannaraOS.Governance.ArchaeologicalReconstruction.full_test() do
  {:ok, report} ->
    IO.puts("\n✅ Archaeological reconstruction successful!")
    
    # Save report to evidence package
    report_path = "phase14/certification/replay/archaeological_reconstruction.json"
    File.mkdir_p!(Path.dirname(report_path))
    report_json = Jason.encode!(report, pretty: true)
    File.write!(report_path, report_json)
    IO.puts("💾 Report saved to: #{report_path}")
    
  {:error, reason} ->
    IO.puts("\n❌ Archaeological reconstruction failed!")
    IO.puts("Reason: #{reason}")
    System.halt(1)
end
