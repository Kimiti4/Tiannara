# scripts/run_rea_3_5_parallel.exs
# Run with: `elixir --erl "+sbwt none" -S mix run scripts/run_rea_3_5_parallel.exs`

# Boot services
{:ok, _} = Tiannara.REA.LineageRegistry.start_link()
{:ok, _} = Tiannara.REA.ArchaeologyRegistry.start_link()
{:ok, _} = Tiannara.REA.Causal.ChannelMonitor.start_link()
{:ok, _} = Tiannara.REA.Causal.Graph.start_link()
{:ok, _} = Tiannara.REA.Causal.CausalConstitution.start_link()
{:ok, _} = Tiannara.REA.Topo.ReplacementRegistry.start_link()
{:ok, _} = Tiannara.REA.Epistemic.EcologicalMemory.start_link()
{:ok, _} = Tiannara.REA.Epistemic.ReflexivityObservatory.start_link()

alias Tiannara.REA.Epistemic.ParallelRunner

config = %{
  seed: 42,
  epochs: 500,
  snapshot_interval: 100
}

{time_ms, report} = :timer.tc(fn -> ParallelRunner.run_comparison(config) end)

IO.puts("\n⏱️  Total comparison completed in #{time_ms / 1000}s")
IO.puts(report.analysis)

# Persist report
File.write!("rea_3_5_comparison_report.md", """
# REA-3.5 Epistemic Comparison Report

Generated: #{DateTime.utc_now()}
Seed: #{config.seed}
Epochs: #{config.epochs}

#{report.analysis}

## Winner: #{report.winner}
## Verdicts: #{inspect(report.final_verdicts)}
""")

IO.puts("\n✅ Report saved to rea_3_5_comparison_report.md")
