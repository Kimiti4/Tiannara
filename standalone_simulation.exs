# Standalone Simulation Script
# Run with: elixir --erl "-pa _build/dev/lib/tiannara/ebin" standalone_simulation.exs

Code.require_file("_build/dev/lib/tiannara/ebin/Elixir.TiannaraOS.CivilizationRuntime.beam")
Code.require_file("_build/dev/lib/tiannara/ebin/Elixir.TiannaraOS.ExecutiveDashboard.beam")

IO.puts("Starting civilization simulation...")
IO.puts("This will generate 10,000 episodes across 20 institutions over 10 generations.")
IO.puts("")

# Execute simulation
{:ok, stats} = TiannaraOS.SimulationRunner.run_simulation(%{
  institution_count: 20,
  generations: 10,
  cycles_per_institution: 50,
  output_dir: "simulation_output"
})

IO.puts("")
IO.puts("Simulation complete!")
IO.inspect(stats, label: "Final Statistics")
