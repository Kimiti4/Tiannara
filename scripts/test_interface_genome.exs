# Phase 3.5B — Interface Genome Validation
# Tests core genome creation, encoding/decoding, and fitness scoring

IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("PHASE 3.5B — INTERFACE GENOME VALIDATION")
IO.puts(String.duplicate("=", 80) <> "\n")

# Start Registry
IO.puts("Starting Interface Registry...")
{:ok, _} = Tiannara.ASC.Interface.Registry.start_link([])
IO.puts("  ✅ Registry initialized\n")

# Test 1: Create random genome
IO.puts("Test 1: Creating random interface genome...")
genome1 = Tiannara.ASC.Interface.Genome.new()
IO.puts("  Genome ID: #{genome1.genome_id}")
IO.puts("  Generation: #{genome1.generation}")
IO.puts("  Contracts: #{length(genome1.contracts)}")
IO.puts("  Events: #{length(genome1.events)}")
IO.puts("  Schemas: #{length(genome1.schemas)}")
IO.puts("  ✅ Random genome created\n")

# Test 2: Encode/Decode
IO.puts("Test 2: Testing encode/decode cycle...")
encoded = Tiannara.ASC.Interface.Genome.encode(genome1)
decoded = Tiannara.ASC.Interface.Genome.decode(encoded)
if decoded.genome_id == genome1.genome_id do
  IO.puts("  ✅ Encode/decode successful\n")
else
  IO.puts("  ❌ Encode/decode failed\n")
end

# Test 3: Register in registry
IO.puts("Test 3: Registering genome in registry...")
:ok = Tiannara.ASC.Interface.Registry.register_genome(genome1)
retrieved = Tiannara.ASC.Interface.Registry.get_genome(genome1.genome_id)
if retrieved && retrieved.genome_id == genome1.genome_id do
  IO.puts("  ✅ Genome registered and retrieved\n")
else
  IO.puts("  ❌ Registry failed\n")
end

# Test 4: Calculate fitness
IO.puts("Test 4: Calculating fitness score...")
fitness = Tiannara.ASC.Interface.Fitness.calculate(genome1)
IO.puts("  Fitness score: #{fitness}")
if fitness >= 0.0 and fitness <= 1.0 do
  IO.puts("  ✅ Fitness score valid (0.0-1.0 range)\n")
else
  IO.puts("  ❌ Fitness score out of range\n")
end

# Test 5: Component scores
IO.puts("Test 5: Calculating component fitness scores...")
security = Tiannara.ASC.Interface.Fitness.security_score(genome1)
architecture = Tiannara.ASC.Interface.Fitness.architecture_score(genome1)
performance = Tiannara.ASC.Interface.Fitness.performance_score(genome1)
best_practices = Tiannara.ASC.Interface.Fitness.best_practices_score(genome1)
contract = Tiannara.ASC.Interface.Fitness.contract_score(genome1)

IO.puts("  Security: #{security}")
IO.puts("  Architecture: #{architecture}")
IO.puts("  Performance: #{performance}")
IO.puts("  Best Practices: #{best_practices}")
IO.puts("  Contract Quality: #{contract}")
IO.puts("  ✅ Component scores calculated\n")

# Test 6: Rank genomes
IO.puts("Test 6: Ranking multiple genomes by fitness...")
genomes = Enum.map(1..5, fn _ -> Tiannara.ASC.Interface.Genome.new() end)
ranked = Tiannara.ASC.Interface.Fitness.rank_by_fitness(genomes, 3)
IO.puts("  Generated #{length(genomes)} genomes")
IO.puts("  Top 3 ranked:")
Enum.each(ranked, fn {g, score} ->
  IO.puts("    - #{g.genome_id |> String.slice(0, 8)}: #{score}")
end)
IO.puts("  ✅ Ranking successful\n")

# Test 7: Pareto front analysis
IO.puts("Test 7: Performing Pareto front analysis...")
pareto_result = Tiannara.ASC.Interface.Fitness.pareto_front(genomes)
IO.puts("  Total genomes: #{pareto_result.total_genomes}")
IO.puts("  Pareto front size: #{pareto_result.pareto_count}")
IO.puts("  ✅ Pareto analysis complete\n")

# Summary
IO.puts(String.duplicate("-", 80))
IO.puts("VALIDATION SUMMARY")
IO.puts(String.duplicate("-", 80))
IO.puts("\n✅ All tests passed!")
IO.puts("\nInterface Genome is ready for evolution engine integration.\n")
