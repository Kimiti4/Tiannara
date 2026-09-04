# Deterministic Seed Independence Audit
# Tests 5 seeds to verify they produce different civilizations

alias TiannaraOS.RecursiveCivilizationRunner

IO.puts("=" |> String.duplicate(80))
IO.puts("Phase 13.5A.1 - Deterministic Seed Independence Audit")
IO.puts("=" |> String.duplicate(80))
IO.puts("")

seeds = [1, 2, 3, 4, 5]
output_dir = "data/phase13_5/seed_audit"

File.mkdir_p!(output_dir)

results = Enum.map(seeds, fn seed ->
  IO.puts("\n🔍 Testing seed #{seed}...")
  
  # Set seed for deterministic execution
  :rand.seed(:exsplus, {seed, seed, seed})
  
  # Run short trial (10 generations)
  case RecursiveCivilizationRunner.execute(10, %{
    output_dir: Path.join(output_dir, "seed_#{seed}"),
    episodes_per_generation: 200,
    checkpoint_interval: 10,
    enable_adaptation: true
  }) do
    {:ok, histories} ->
      final_gen = List.last(histories)
      
      # Calculate helpers inline
      avg_discoveries = if length(histories) > 0 do
        Float.round(Enum.sum(Enum.map(histories, & &1.discoveries_made)) / length(histories), 2)
      else
        0.0
      end
      
      theories = Enum.map(histories, & &1.theories_formed)
      theory_variance = if length(theories) >= 2 do
        mean = Enum.sum(theories) / length(theories)
        variance = Enum.sum(Enum.map(theories, fn x -> (x - mean) ** 2 end)) / (length(theories) - 1)
        Float.round(variance, 2)
      else
        0.0
      end
      
      # Extract key metrics
      %{
        seed: seed,
        institution_diversity: final_gen.institution_diversity,
        unknown_distribution_hash: :crypto.hash(:md5, "#{final_gen.unknowns_resolved}") |> Base.encode16(),
        budget_allocation_hash: :crypto.hash(:md5, "#{final_gen.budget_remaining}") |> Base.encode16(),
        collaboration_graph_hash: :crypto.hash(:md5, "#{final_gen.collaboration_density}") |> Base.encode16(),
        scientific_capital: Float.round(final_gen.scientific_capital, 2),
        total_discoveries: Enum.sum(Enum.map(histories, & &1.discoveries_made)),
        total_theories: Enum.sum(Enum.map(histories, & &1.theories_formed)),
        avg_discoveries_per_gen: avg_discoveries,
        theory_count_variance: theory_variance,
        discovery_rate: Float.round(final_gen.discoveries_made / final_gen.episodes_created, 4)
      }
      
    {:error, reason} ->
      IO.puts("  ❌ Failed: #{inspect(reason)}")
      nil
  end
end)
|> Enum.filter(& &1)

IO.puts("\n" <> ("=" |> String.duplicate(80)))
IO.puts("Seed Independence Audit Results")
IO.puts("=" |> String.duplicate(80))
IO.puts("")

# Check for duplicates
institution_hashes = Enum.map(results, & &1.institution_diversity) |> Enum.uniq()
unknown_hashes = Enum.map(results, & &1.unknown_distribution_hash) |> Enum.uniq()
budget_hashes = Enum.map(results, & &1.budget_allocation_hash) |> Enum.uniq()
collaboration_hashes = Enum.map(results, & &1.collaboration_graph_hash) |> Enum.uniq()
capital_values = Enum.map(results, & &1.scientific_capital) |> Enum.uniq()
discovery_counts = Enum.map(results, & &1.total_discoveries) |> Enum.uniq()
theory_counts = Enum.map(results, & &1.total_theories) |> Enum.uniq()

IO.puts("Uniqueness Check:")
IO.puts("  Institution Diversity:     #{length(institution_hashes)}/#{length(results)} unique")
IO.puts("  Unknown Distribution:      #{length(unknown_hashes)}/#{length(results)} unique")
IO.puts("  Budget Allocation:         #{length(budget_hashes)}/#{length(results)} unique")
IO.puts("  Collaboration Graph:       #{length(collaboration_hashes)}/#{length(results)} unique")
IO.puts("  Scientific Capital:        #{length(capital_values)}/#{length(results)} unique")
IO.puts("  Total Discoveries:         #{length(discovery_counts)}/#{length(results)} unique")
IO.puts("  Total Theories:            #{length(theory_counts)}/#{length(results)} unique")
IO.puts("")

# Display detailed results
IO.puts("Detailed Results:")
Enum.each(results, fn r ->
  IO.puts("\n  Seed #{r.seed}:")
  IO.puts("    Scientific Capital:    #{r.scientific_capital}")
  IO.puts("    Total Discoveries:     #{r.total_discoveries}")
  IO.puts("    Total Theories:        #{r.total_theories}")
  IO.puts("    Discovery Rate:        #{r.discovery_rate}")
  IO.puts("    Institution Diversity: #{r.institution_diversity}")
end)

IO.puts("\n")

# Determine pass/fail
all_unique = length(institution_hashes) == length(results) and
             length(unknown_hashes) == length(results) and
             length(budget_hashes) == length(results) and
             length(collaboration_hashes) == length(results) and
             length(capital_values) == length(results) and
             length(discovery_counts) == length(results) and
             length(theory_counts) == length(results)

if all_unique do
  IO.puts("✅ SEED INDEPENDENCE VERIFIED")
  IO.puts("")
  IO.puts("All #{length(results)} seeds produced materially different civilizations.")
  IO.puts("Proceed to Phase 13.5A.2 - Causal Audit")
else
  IO.puts("❌ SEED INDEPENDENCE FAILED")
  IO.puts("")
  IO.puts("Some seeds produced identical or near-identical results.")
  IO.puts("Root cause analysis required before proceeding.")
end

IO.puts("\n")
