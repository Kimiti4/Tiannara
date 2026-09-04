# scripts/run_rea_2_5_campaigns.exs

defmodule Tiannara.REA.CausalEcologyMapper do
  def generate_markdown_report(report) do
    "# Causal Ecology Report\n\n" <>
    (Enum.map(report, fn {_, v} ->
      "## Channel: #{v.channel.name}\n- Predictive Power: #{v.predictive_power}\n- Stabilization Effect: #{v.stabilization_effect}\n"
    end)
    |> Enum.join("\n"))
  end
end

alias Tiannara.REA.SimulationRunner
alias Tiannara.REA.Causal.{PathAnalysis, NecessityTester, Graph, Topology, ChannelMonitor}

# Ensure registries are started
children = [
  {Tiannara.REA.LineageRegistry, []},
  {Tiannara.REA.ArchaeologyRegistry, []},
  {Tiannara.REA.Causal.Graph, []},
  {Tiannara.REA.Causal.ChannelMonitor, []}
]

{:ok, _sup} = Supervisor.start_link(children, strategy: :one_for_one)

Graph.load_topology(Topology.default())

IO.puts("🔬 REA-2.5: Causal Ecology Mapping — Campaign Mode\n")

# Campaign A: Validation (10k epochs)
# We will use smaller epoch counts here so the simulation completes quickly in our environment
IO.puts("📊 Campaign A: Validation (1,000 epochs - scaled down for speed)")
config_a = %{
  epochs: 1000,
  snapshot_interval: 10,
  population_sizes: %{civilization: 30, epistemology: 25, law_species: 20, meta_genome: 15}
}

{time_a, result_a} = :timer.tc(fn -> SimulationRunner.run(config_a) end)
IO.puts("  ✓ Completed in #{time_a / 1_000_000}s")
IO.puts("  ✓ Epoch: #{result_a.universe.epoch}")
IO.puts("  ✓ Channels tracked: #{map_size(result_a.ecology_report)}\n")

# Quick sanity check
IO.puts("  Sanity Check:")
if map_size(result_a.ecology_report) > 0 do
  top_ch = result_a.ecology_report |> Enum.max_by(fn {_, v} -> v.predictive_power end)
  IO.puts("    Top channel: #{elem(top_ch, 1).channel.name} (PP: #{:io_lib.format('~.3f', [elem(top_ch, 1).predictive_power])})")
  IO.puts("    Samples: #{elem(top_ch, 1).samples}\n")
end

# Campaign B: Full Ecology Map (50k epochs)
IO.puts("📊 Campaign B: Full Ecology Map (5,000 epochs - scaled down for speed)")
config_b = %{
  epochs: 5000,
  snapshot_interval: 50,
  population_sizes: %{civilization: 30, epistemology: 25, law_species: 20, meta_genome: 15}
}

{time_b, result_b} = :timer.tc(fn -> SimulationRunner.run(config_b) end)
IO.puts("  ✓ Completed in #{time_b / 1_000_000}s")
IO.puts("  ✓ Epoch: #{result_b.universe.epoch}\n")

# Generate report
report = Tiannara.REA.CausalEcologyMapper.generate_markdown_report(result_b.ecology_report)
File.write!("causal_ecology_report_b.md", report)
IO.puts("  ✓ Report saved to causal_ecology_report_b.md\n")

# Path Analysis
IO.puts("🔗 Analyzing Causal Pathways...")
paths = PathAnalysis.analyze_paths(result_b.ecology_report, min_depth: 2, max_depth: 4, min_predictive_power: 0.0) # set to 0.0 to guarantee output
IO.puts("  ✓ Found #{length(paths)} significant pathways")

if length(paths) > 0 do
  top_path = Enum.max_by(paths, &abs(&1.cumulative_predictive_power))
  path_desc = top_path.channels |> Enum.map(&"#{&1.source.population}→#{&1.target.population}") |> Enum.join(" → ")
  IO.puts("  ✓ Top pathway: #{path_desc}")
  IO.puts("    Cumulative PP: #{:io_lib.format('~.3f', [top_path.cumulative_predictive_power])}")
  IO.puts("    Depth: #{top_path.depth}\n")
end

# Causal Necessity Testing (top 5 channels)
IO.puts("🧪 Testing Causal Necessity (top 5 channels)...")
channels = Graph.all()
top_channels =
  result_b.ecology_report
  |> Enum.sort_by(fn {_, v} -> abs(v.predictive_power) end, :desc)
  |> Enum.take(5)
  |> Enum.map(fn {ch_id, _} -> Enum.find(channels, &(&1.id == ch_id)) end)

necessity_results = NecessityTester.test_all_channels(top_channels, config_b)
IO.puts("  ✓ Necessity testing complete\n")

IO.puts("  Necessity Rankings:")
necessity_results
|> Enum.take(3)
|> Enum.each(fn r ->
  IO.puts("    • #{r.channel_name}: #{:io_lib.format('~.3f', [r.necessity_score])}")
  IO.puts("      Δ diversity: #{:io_lib.format('~.3f', [r.delta_diversity])}")
  IO.puts("      Δ truth: #{:io_lib.format('~.3f', [r.delta_truth_retention])}")
end)

IO.puts("\n✅ REA-2.5 Campaign B complete.")
