# scripts/run_rea_2_5_fast.exs

defmodule Tiannara.REA.CausalEcologyMapper do
  def generate_markdown_report(report) do
    "# Causal Ecology Report\n\n" <>
    (Enum.map(report, fn {_, v} ->
      "## Channel: #{v.channel.name}\n- Predictive Power: #{:io_lib.format('~.3f', [v.predictive_power])}\n- Stabilization Effect: #{:io_lib.format('~.3f', [v.stabilization_effect])}\n"
    end)
    |> Enum.join("\n"))
  end
end

alias Tiannara.REA.SimulationRunner
alias Tiannara.REA.Causal.{PathAnalysis, NecessityTester, Graph, Topology}

children = [
  {Tiannara.REA.LineageRegistry, []},
  {Tiannara.REA.ArchaeologyRegistry, []},
  {Tiannara.REA.Causal.Graph, []},
  {Tiannara.REA.Causal.ChannelMonitor, []}
]

{:ok, _sup} = Supervisor.start_link(children, strategy: :one_for_one)

IO.puts("🔬 REA-2.5: Causal Ecology Mapping — Fast Mode\n")

Graph.load_topology(Topology.default())

IO.puts("📊 Campaign B: Full Ecology Map (50 epochs)")
config_b = %{
  epochs: 50,
  snapshot_interval: 5,
  population_sizes: %{civilization: 15, epistemology: 10, law_species: 10, meta_genome: 5}
}

{time_b, result_b} = :timer.tc(fn -> SimulationRunner.run(config_b) end)
IO.puts("  ✓ Completed in #{time_b / 1_000_000}s")
IO.puts("  ✓ Epoch: #{result_b.universe.epoch}\n")

# Generate report
report = Tiannara.REA.CausalEcologyMapper.generate_markdown_report(result_b.ecology_report)
File.write!("causal_ecology_report_fast.md", report)
IO.puts("  ✓ Report saved to causal_ecology_report_fast.md\n")

# Path Analysis
IO.puts("🔗 Analyzing Causal Pathways...")
paths = PathAnalysis.analyze_paths(result_b.ecology_report, min_depth: 2, max_depth: 4, min_predictive_power: 0.0)
IO.puts("  ✓ Found #{length(paths)} significant pathways")

if length(paths) > 0 do
  top_path = Enum.max_by(paths, &abs(&1.cumulative_predictive_power))
  path_desc = top_path.channels |> Enum.map(&"#{&1.source.population}→#{&1.target.population}") |> Enum.join(" → ")
  IO.puts("  ✓ Top pathway: #{path_desc}")
  IO.puts("    Cumulative PP: #{:io_lib.format('~.3f', [top_path.cumulative_predictive_power])}")
  IO.puts("    Depth: #{top_path.depth}\n")
end

# Causal Necessity Testing (top 2 channels)
IO.puts("🧪 Testing Causal Necessity (top 2 channels)...")
channels = Graph.all()
top_channels =
  result_b.ecology_report
  |> Enum.sort_by(fn {_, v} -> abs(v.predictive_power) end, :desc)
  |> Enum.take(2)
  |> Enum.map(fn {ch_id, _} -> Enum.find(channels, &(&1.id == ch_id)) end)
  |> Enum.reject(&is_nil/1)

if length(top_channels) > 0 do
  necessity_results = NecessityTester.test_all_channels(top_channels, Map.put(config_b, :epochs, 10))
  IO.puts("  ✓ Necessity testing complete\n")

  IO.puts("  Necessity Rankings:")
  necessity_results
  |> Enum.each(fn r ->
    IO.puts("    • #{r.channel_name}: #{:io_lib.format('~.3f', [r.necessity_score])}")
    IO.puts("      Δ diversity: #{:io_lib.format('~.3f', [r.delta_diversity])}")
    IO.puts("      Δ truth: #{:io_lib.format('~.3f', [r.delta_truth_retention])}")
  end)
end

IO.puts("\n✅ REA-2.5 Fast Campaign complete.")
