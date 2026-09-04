# Phase 13.5 - Empirical Validation Execution Script
# Executes A/B testing, saturation analysis, diversity validation, and robustness tests

alias TiannaraOS.RecursiveEvolutionValidator

IO.puts("=" |> String.duplicate(80))
IO.puts("Phase 13.5 - Empirical Validation of Recursive Constitutional Evolution")
IO.puts("=" |> String.duplicate(80))
IO.puts("")
IO.puts("This validation suite will:")
IO.puts("  1. Execute A/B testing (Adaptive vs Static civilizations)")
IO.puts("  2. Analyze improvement saturation patterns")
IO.puts("  3. Validate institutional diversity preservation")
IO.puts("  4. Test civilization robustness to perturbations")
IO.puts("")
IO.puts("Expected duration: 5-10 minutes (200 total generations)")
IO.puts("")

# Execute full validation suite
case RecursiveEvolutionValidator.execute_full_validation(%{
  generations_per_experiment: 100,
  output_dir: "data/phase13_5"
}) do
  {:ok, validation_report} ->
    IO.puts("\n" <> ("=" |> String.duplicate(80)))
    IO.puts("✅ Phase 13.5 Validation Complete!")
    IO.puts("=" |> String.duplicate(80))
    IO.puts("")
    
    if validation_report.all_pass do
      IO.puts("🎉 ALL VALIDATIONS PASSED")
      IO.puts("")
      IO.puts("Phase 13 is ready to freeze as Version 1.0")
      IO.puts("Proceed to Phase 14 - Constitutional Meta-Governance")
    else
      IO.puts("⚠️  SOME VALIDATIONS FAILED")
      IO.puts("")
      IO.puts("Review reports in data/phase13_5/ for details")
      IO.puts("Address failing validations before freezing Phase 13")
    end
    
    IO.puts("")
    IO.puts("Validation Results:")
    IO.puts("  Causal Validation: #{if validation_report.causal_pass, do: "✅ PASSED", else: "❌ FAILED"}")
    IO.puts("  Saturation Analysis: #{if validation_report.saturation_pass, do: "✅ PASSED", else: "❌ FAILED"}")
    IO.puts("  Diversity Validation: #{if validation_report.diversity_pass, do: "✅ PASSED", else: "❌ FAILED"}")
    IO.puts("  Robustness Tests: #{if validation_report.robustness_pass, do: "✅ PASSED", else: "❌ FAILED"}")
    IO.puts("")

  {:error, reason} ->
    IO.puts("\n❌ Phase 13.5 validation failed: #{inspect(reason)}")
end
