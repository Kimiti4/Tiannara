# Phase 13.5 - Statistical Validation Execution Script
# Executes 60 independent trials (30 adaptive + 30 static) with proper statistical analysis

alias TiannaraOS.StatisticalValidation

IO.puts("=" |> String.duplicate(80))
IO.puts("Phase 13.5 - Statistical Validation of Recursive Constitutional Evolution")
IO.puts("=" |> String.duplicate(80))
IO.puts("")
IO.puts("This validation suite will execute:")
IO.puts("  • 30 Adaptive Civilization trials (full adaptation enabled)")
IO.puts("  • 30 Static Civilization trials (adaptation disabled)")
IO.puts("  • 100 generations per trial")
IO.puts("  • Total: 60 independent executions")
IO.puts("")
IO.puts("Statistical Analysis:")
IO.puts("  • Mean, variance, standard deviation")
IO.puts("  • 95% confidence intervals")
IO.puts("  • Cohen's d effect size")
IO.puts("  • Welch's t-test p-values")
IO.puts("  • Robustness analysis (pairwise comparisons)")
IO.puts("  • Sensitivity analysis (5 parameter scenarios)")
IO.puts("")
IO.puts("Expected duration: 2-4 hours")
IO.puts("")
IO.puts("⚠️  This is a LONG-RUNNING process. Consider running in background.")
IO.puts("")

# Execute statistical validation
case StatisticalValidation.execute_statistical_validation(%{
  num_trials: 30,
  generations_per_trial: 100,
  output_dir: "data/phase13_5/statistical"
}) do
  {:ok, validation_report} ->
    IO.puts("\n" <> ("=" |> String.duplicate(80)))
    IO.puts("✅ Phase 13.5 Statistical Validation Complete!")
    IO.puts("=" |> String.duplicate(80))
    IO.puts("")
    IO.puts("📊 Results Summary:")
    IO.puts("  Conclusion: #{validation_report.conclusion}")
    IO.puts("  Trials executed: 60 (30 adaptive + 30 static)")
    IO.puts("  Generations per trial: 100")
    IO.puts("  Total generations: 6,000")
    IO.puts("")
    IO.puts("📄 Output files:")
    IO.puts("  data/phase13_5/statistical/Phase13_Statistical_Validation_Report.md")
    IO.puts("  data/phase13_5/statistical/adaptive/trial_*/generation_history.csv")
    IO.puts("  data/phase13_5/statistical/static/trial_*/generation_history.csv")
    IO.puts("")

    case validation_report.conclusion do
      :strongly_supported ->
        IO.puts("🎉 PHASE 13 IS EMPIRICALLY VALIDATED AND READY FOR FREEZE!")
        IO.puts("")
        IO.puts("The evidence overwhelmingly demonstrates that constitutional recursive")
        IO.puts("adaptation produces statistically significant improvements in scientific")
        IO.puts("performance across multiple independent trials.")

      :supported ->
        IO.puts("✅ PHASE 13 IS EMPIRICALLY VALIDATED (with minor caveats)")
        IO.puts("")
        IO.puts("The evidence supports the conclusion that constitutional recursive")
        IO.puts("adaptation improves scientific performance, though some metrics show")
        IO.puts("weaker effects than others.")

      :weakly_supported ->
        IO.puts("⚠️  PHASE 13 SHOWS PROMISE BUT REQUIRES ADDITIONAL VALIDATION")
        IO.puts("")
        IO.puts("Preliminary evidence suggests benefits, but statistical confidence is limited.")
        IO.puts("Consider additional trials before freezing.")

      :not_supported ->
        IO.puts("❌ PHASE 13 NOT YET VALIDATED")
        IO.puts("")
        IO.puts("Current evidence does not support reliable improvement claims.")
        IO.puts("Architectural investigation recommended before proceeding.")
    end

    IO.puts("\n")

  {:error, reason} ->
    IO.puts("\n❌ Phase 13.5 validation failed: #{inspect(reason)}")
end
