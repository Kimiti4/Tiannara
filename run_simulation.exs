# Run Civilization Simulation
# This script executes Stage 2 of Phase 13 Operationalization

# Start IEx with the application
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
