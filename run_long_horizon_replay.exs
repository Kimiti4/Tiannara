# Long-Horizon Replay Test - Phase 14 RC3
IO.puts("\n🔄 Running Long-Horizon Replay Test (10,000 iterations)...\n")

# Start required GenServers
{:ok, _pid} = TiannaraOS.Governance.GovernanceLedger.start_link([])
{:ok, _pid} = TiannaraOS.Governance.GovernanceCostLedger.start_link([])

# Run long-horizon replay with 10k iterations (demonstration)
# For production: use 100k or 1M iterations
case TiannaraOS.Governance.LongHorizonReplay.test(iterations: 10_000, sample_interval: 100) do
  {:ok, report} ->
    IO.puts("\n✅ Long-horizon replay stable!")
    
    # Save report to evidence package
    report_path = "phase14/certification/replay/long_horizon_replay_10k.json"
    File.mkdir_p!(Path.dirname(report_path))
    report_json = Jason.encode!(report, pretty: true)
    File.write!(report_path, report_json)
    IO.puts("💾 Report saved to: #{report_path}")
    
  {:error, reason} ->
    IO.puts("\n❌ Long-horizon replay failed!")
    IO.puts("Reason: #{reason}")
    System.halt(1)
end
