# Mutation Testing Framework - Phase 14 RC3
IO.puts("\n🧬 Running Mutation Testing Suite...\n")

# Start required GenServers
{:ok, _pid} = TiannaraOS.Governance.GovernanceLedger.start_link([])
{:ok, _pid} = TiannaraOS.Governance.GovernanceCostLedger.start_link([])

# Run mutation tests
case TiannaraOS.Governance.MutationTesting.full_suite() do
  {:ok, report} ->
    IO.puts("\n✅ Mutation testing complete - system is adversarially robust!")
    
    # Save report to evidence package
    report_path = "phase14/certification/replay/mutation_testing.json"
    File.mkdir_p!(Path.dirname(report_path))
    report_json = Jason.encode!(report, pretty: true)
    File.write!(report_path, report_json)
    IO.puts("💾 Report saved to: #{report_path}")
    
  {:error, reason} ->
    IO.puts("\n❌ Mutation testing failed!")
    IO.puts("Reason: #{reason}")
    System.halt(1)
end
