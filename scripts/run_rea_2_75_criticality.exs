# scripts/run_rea_2_75_criticality.exs
# Run with: `elixir --erl "+sbwt none" -S mix run scripts/run_rea_2_75_criticality.exs`

alias Tiannara.REA.{SimulationRunner, LineageRegistry, ArchaeologyRegistry}
alias Tiannara.REA.Causal.{Graph, Topology, CriticalityTester, CausalConstitution}

IO.puts("🔬 REA-2.75: Causal Criticality Mapping\n")

# Start supervision tree
children = [
  {Tiannara.REA.LineageRegistry, []},
  {Tiannara.REA.ArchaeologyRegistry, []},
  {Tiannara.REA.Causal.Graph, []},
  {Tiannara.REA.Causal.ChannelMonitor, []},
  {Tiannara.REA.Causal.CausalConstitution, []}
]

{:ok, _sup} = Supervisor.start_link(children, strategy: :one_for_one)

# Load default topology
Graph.load_topology(Topology.default())
channels = Graph.all()

IO.puts("📊 Testing criticality of #{length(channels)} channels...")
IO.puts("   (This will run ~30 simulations per channel)\n")

config = %{
  epochs: 50, # Scaled down for script execution
  snapshot_interval: 10,
  population_sizes: %{civilization: 15, epistemology: 10, law_species: 10, meta_genome: 5}
}

{time_ms, profiles} = :timer.tc(fn ->
  CriticalityTester.analyze_all(channels, config)
end)

IO.puts("\n✅ Criticality analysis complete in #{time_ms / 1_000_000}s\n")

# Display results
IO.puts("📋 Criticality Profiles:\n")
IO.puts("| Channel | Criticality | Bottleneck | Replaceability | Classification | Optimal Wt | Optimal Dly |")
IO.puts("|---------|-------------|------------|----------------|----------------|------------|-------------|")

Enum.each(profiles, fn p ->
  class_icon = case p.classification do
    :constitutional -> "🔒 CONSTITUTIONAL"
    :structural -> "🏗️ STRUCTURAL"
    :adaptive -> "🔧 ADAPTIVE"
    :experimental -> "🧪 EXPERIMENTAL"
  end
  
  IO.puts("| `#{p.channel_name}` | #{:io_lib.format('~.3f', [p.criticality_score])} | #{:io_lib.format('~.3f', [p.bottleneck_score])} | #{:io_lib.format('~.3f', [p.replaceability])} | #{class_icon} | #{:io_lib.format('~.2f', [p.optimal_weight])} | #{p.optimal_delay} |")
end)

# Enact constitution
protected_count = Enum.count(profiles, &(&1.classification in [:constitutional, :structural]))
IO.puts("\n🏛️  Enacting Causal Constitution (#{protected_count} protected channels)...")
CausalConstitution.enact(profiles)

IO.puts("\n✅ Constitution enacted. Constitutional channels are now protected from deletion.")
IO.puts("✅ Structural channels are protected by bounding constraints.\n")

# Display constitutional channels
IO.puts("🔒 Protected Channels:")
CausalConstitution.all_protected()
|> Enum.each(fn c ->
  IO.puts("  • #{c.channel_name} [#{c.classification |> to_string() |> String.upcase()}]")
  IO.puts("    Protected For: #{inspect(c.protected_for)}")
  IO.puts("    Criticality: #{:io_lib.format('~.3f', [c.criticality_score])}")
  IO.puts("    Weight bounds: [#{:io_lib.format('~.2f', [c.min_weight])}, #{:io_lib.format('~.2f', [c.max_weight])}]")
  IO.puts("    Delay bounds: [#{c.min_delay}, #{c.max_delay}]")
end)

IO.puts("\n✅ REA-2.75 complete. System is ready for REA-3: Constrained Topological Evolution.")

# Output artifacts
report = "# REA-2.75 Criticality Map\n\n" <>
"| Channel | Criticality | Bottleneck | Replaceability | Classification | Optimal Wt | Optimal Dly |\n" <>
"|---------|-------------|------------|----------------|----------------|------------|-------------|\n" <>
(Enum.map(profiles, fn p ->
  class_icon = case p.classification do
    :constitutional -> "🔒 CONSTITUTIONAL"
    :structural -> "🏗️ STRUCTURAL"
    :adaptive -> "🔧 ADAPTIVE"
    :experimental -> "🧪 EXPERIMENTAL"
  end
  "| `#{p.channel_name}` | #{:io_lib.format('~.3f', [p.criticality_score])} | #{:io_lib.format('~.3f', [p.bottleneck_score])} | #{:io_lib.format('~.3f', [p.replaceability])} | #{class_icon} | #{:io_lib.format('~.2f', [p.optimal_weight])} | #{p.optimal_delay} |"
end) |> Enum.join("\n"))

File.write!("criticality_map.md", report)
