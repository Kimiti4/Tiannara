# Long-Horizon Replay Test - 1 Million Iterations - Phase 14 RC3
IO.puts("\n🔄 Running Long-Horizon Replay Test (1,000,000 iterations)...\n")
IO.puts("⚠️  This will take several minutes. Please be patient.\n")

# Start required GenServers
{:ok, _pid} = TiannaraOS.Governance.GovernanceLedger.start_link([])
{:ok, _pid} = TiannaraOS.Governance.GovernanceCostLedger.start_link([])

# Run long-horizon replay with 1M iterations
# Sample every 10,000 iterations to collect 100 data points
case TiannaraOS.Governance.LongHorizonReplay.test(iterations: 1_000_000, sample_interval: 10_000) do
  {:ok, report} ->
    IO.puts("\n✅ 1M iteration long-horizon replay stable!")
    
    # Save report to evidence package
    report_path = "phase14/certification/replay/long_horizon_replay_1m.json"
    File.mkdir_p!(Path.dirname(report_path))
    report_json = Jason.encode!(report, pretty: true)
    File.write!(report_path, report_json)
    IO.puts("💾 Report saved to: #{report_path}")
    
  {:error, reason} ->
    IO.puts("\n❌ 1M iteration long-horizon replay failed!")
    IO.puts("Reason: #{reason}")
    System.halt(1)
end
