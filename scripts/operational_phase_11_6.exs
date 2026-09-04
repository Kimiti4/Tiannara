# Operational Phase 11.6 Simulation
# Usage: mix run scripts/operational_phase_11_6.exs

Code.require_file("lib/tiannara/sentinel/operational_observatory.ex")
Code.require_file("lib/tiannara/rea/phase_11_6/operational.ex")
Code.require_file("lib/tiannara/audit/phase_11_6.ex")
Code.require_file("lib/tiannara/specialists/architect.ex")
Code.require_file("lib/tiannara/specialists/engineer.ex")
Code.require_file("lib/tiannara/specialists/researcher.ex")

IO.puts("\n🚀 STARTING OPERATIONAL PHASE 11.6: INVERTED-U HYPOTHESIS\n")

# Mock historical data (100 cycles)
historical_data = Enum.map(1..100, fn i ->
  %{
    cycle: i,
    metrics: %{
      immediate_gain: 0.3 + (:rand.uniform() * 0.4),
      long_term_gain: 0.2 + (:rand.uniform() * 0.6),
      regression_cost: 0.05,
      reuse_count: if(:rand.uniform() > 0.8, do: 5, else: 1)
    },
    is_novel_discovery: :rand.uniform() > 0.9
  }
end)

# Run the analysis
IO.puts("\n📊 Phase 11.6B Subsystem-Specific Targets:")
memory_classes = [:experiment_logs, :failures, :architecture, :telemetry, :specialist_context]
Enum.each(memory_classes, fn class ->
  target = Tiannara.REA.Phase11_6.Operational.dynamic_estimate(class)
  IO.puts("   #{String.pad_trailing("#{class}", 20)} | Target Retention: #{round(target * 100)}%")
end)

Tiannara.Audit.Phase11_6.run_analysis(historical_data)

IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("🏁 OPERATIONAL PHASE 11.6 VERIFICATION COMPLETE")
IO.puts(String.duplicate("=", 80) <> "\n")
