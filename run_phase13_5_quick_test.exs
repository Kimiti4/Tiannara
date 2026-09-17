# Phase 13.5 - Quick Statistical Validation Test
# Executes 10 trials (5 adaptive + 5 static) to verify framework

alias TiannaraOS.StatisticalValidation

IO.puts("=" |> String.duplicate(80))
IO.puts("Phase 13.5 - Quick Statistical Validation TEST")
IO.puts("=" |> String.duplicate(80))
IO.puts("")
IO.puts("This is a QUICK TEST with reduced trials:")
IO.puts("  • 5 Adaptive Civilization trials")
IO.puts("  • 5 Static Civilization trials")
IO.puts("  • 20 generations per trial (reduced from 100)")
IO.puts("  • Total: 10 executions")
IO.puts("")
IO.puts("Expected duration: ~10 minutes")
IO.puts("")

# Execute statistical validation with reduced parameters
case StatisticalValidation.execute_statistical_validation(%{
  num_trials: 5,
  generations_per_trial: 20,
  output_dir: "data/phase13_5/statistical_test"
}) do
  {:ok, validation_report} ->
    IO.puts("\n" <> ("=" |> String.duplicate(80)))
    IO.puts("✅ Quick Test Complete!")
    IO.puts("=" |> String.duplicate(80))
    IO.puts("")
    IO.puts("📊 Results Summary:")
    IO.puts("  Conclusion: #{validation_report.conclusion}")
    IO.puts("  Trials executed: 10 (5 adaptive + 5 static)")
    IO.puts("  Generations per trial: 20")
    IO.puts("")
    
    # Display key statistical findings
    stat_analysis = validation_report.statistical_analysis
    
    IO.puts("\n📈 Key Metrics (Adaptive vs Static):")
    Enum.each(stat_analysis.metrics, fn metric_data ->
      if metric_data.metric in [:research_debt_reduction, :replication_success_rate, :prediction_calibration] do
        sig_marker = if metric_data.significant, do: " ✅", else: ""
        IO.puts("  #{metric_data.metric}:")
        IO.puts("    Adaptive: #{metric_data.adaptive.mean} ± #{metric_data.adaptive.std_error} [#{metric_data.adaptive.ci_lower}, #{metric_data.adaptive.ci_upper}]")
        IO.puts("    Static:   #{metric_data.static.mean} ± #{metric_data.static.std_error} [#{metric_data.static.ci_lower}, #{metric_data.static.ci_upper}]")
        IO.puts("    Effect Size (Cohen's d): #{metric_data.effect_size}#{sig_marker}")
        IO.puts("    p-value: #{metric_data.p_value}")
        IO.puts("")
      end
    end)
    
    IO.puts("🔍 Robustness:")
    IO.puts("  Adaptive Win Rate: #{stat_analysis.robustness.win_rate}%")
    IO.puts("  Wins: #{stat_analysis.robustness.adaptive_wins}/#{stat_analysis.robustness.total_comparisons}")
    IO.puts("")
    
    case validation_report.conclusion do
      :strongly_supported ->
        IO.puts("🎉 TEST PASSED - Framework working correctly!")
        IO.puts("Ready to execute full 60-trial validation.")
        
      :supported ->
        IO.puts("✅ TEST PASSED - Framework working with minor limitations")
        IO.puts("Ready to execute full 60-trial validation.")
        
      _ ->
        IO.puts("⚠️  Test shows mixed results - review framework before full execution")
    end
    
    IO.puts("\n")

  {:error, reason} ->
    IO.puts("\n❌ Quick test failed: #{inspect(reason)}")
end
