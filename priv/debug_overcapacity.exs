# Diagnostic Script: Check Overcapacity Mortality Activation
# Run with: mix run priv/debug_overcapacity.exs

alias TiannaraOS.State
alias TiannaraOS.CivilizationScheduler

# Start simulation
IO.puts("Starting simulation for overcapacity diagnostics...")

# Run for 1000 ticks to get initial state
{:ok, pid} = GenServer.start_link(TiannaraOS.SimulationSupervisor, [])

# Wait for initialization
Process.sleep(2000)

# Get current state
state = :sys.get_state(pid)

programs = state.research_programs || %{}
worlds = state.worlds || %{}

IO.puts("\n=== WORLD POPULATION ANALYSIS ===\n")

total_population = 0
total_capacity = 0

Enum.each(worlds, fn {world_id, world} ->
  # Count active programs in this world
  active_in_world = programs
    |> Map.values()
    |> Enum.filter(fn prog -> prog.world_id == world_id && prog.status == :active end)
  
  population = length(active_in_world)
  
  # Calculate dynamic capacity
  base_capacity = 40
  wealth_bonus = trunc(:math.sqrt(world.wealth || 100_000) * 0.0001)
  dynamic_capacity = base_capacity + wealth_bonus
  
  total_population = total_population + population
  total_capacity = total_capacity + dynamic_capacity
  
  pressure = if dynamic_capacity > 0, do: Float.round(population / dynamic_capacity, 2), else: 0
  
  IO.puts("World #{inspect(world_id)}:")
  IO.puts("  Population: #{population}")
  IO.puts("  Wealth: #{world.wealth}")
  IO.puts("  Capacity: #{dynamic_capacity} (base=#{base_capacity}, bonus=#{wealth_bonus})")
  IO.puts("  Pressure: #{pressure}x")
  IO.puts("  Excess: #{max(0, population - dynamic_capacity)}")
  IO.puts("")
end)

IO.puts("\n=== TOTALS ===")
IO.puts("Total Population: #{total_population}")
IO.puts("Total Capacity: #{total_capacity}")
IO.puts("Overall Pressure: #{Float.round(total_population / max(1, total_capacity), 2)}x")

# Check generation distribution
IO.puts("\n=== GENERATION DISTRIBUTION ===")
gen_counts = programs
  |> Map.values()
  |> Enum.filter(fn p -> p.status == :active end)
  |> Enum.group_by(fn p -> p.generation || 1 end)
  |> Enum.map(fn {gen, progs} -> {gen, length(progs)} end)
  |> Enum.sort()

total_active = Enum.sum(Enum.map(gen_counts, fn {_, count} -> count end))

Enum.each(gen_counts, fn {gen, count} ->
  percentage = Float.round(count / total_active * 100, 1)
  bar = String.duplicate("█", trunc(percentage / 2))
  IO.puts("Gen#{gen}: #{count} (#{percentage}%) #{bar}")
end)

# Check death records
graveyard = state.program_graveyard || %{}
IO.puts("\n=== DEATH RECORDS ===")
IO.puts("Total deaths: #{map_size(graveyard)}")

if map_size(graveyard) > 0 do
  death_causes = graveyard
    |> Map.values()
    |> Enum.group_by(fn record -> record.cause_of_death end)
    |> Enum.map(fn {cause, records} -> {cause, length(records)} end)
    |> Enum.sort_by(fn {_, count} -> -count end)
  
  IO.puts("\nDeath causes:")
  Enum.each(death_causes, fn {cause, count} ->
    IO.puts("  #{cause}: #{count}")
  end)
else
  IO.puts("⚠️  NO DEATH RECORDS FOUND!")
  IO.puts("This indicates mortality mechanisms are not firing.")
end

GenServer.stop(pid)
IO.puts("\nDiagnostic complete.")
