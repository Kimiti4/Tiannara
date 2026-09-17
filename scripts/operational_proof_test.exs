# Operational Proof Simulation
# Usage: mix run scripts/operational_proof_test.exs

Code.require_file("lib/tiannara/sentinel/operational_observatory.ex")
Code.require_file("lib/tiannara/audit/evolution.ex")

IO.puts("\n🚀 STARTING TIER-5 OPERATIONAL PROOF SIMULATION\n")

# Mock historical data with promotion metrics
historical_data = Enum.map(1..20, fn i ->
  progress = i / 20
  is_novel = i == 12 or i == 18
  
  %{
    cycle: i,
    prediction_accuracy: 0.6 + (progress * 0.3),
    ghl: 120.0 + (progress * 50.0),
    result: if(i > 5 and :rand.uniform() > 0.3, do: :positive, else: :neutral),
    is_novel_discovery: is_novel,
    metrics: %{
      immediate_gain: 0.4 + (progress * 0.2),
      long_term_gain: if(is_novel, do: 0.8, else: 0.3), # Novel ones are more valuable
      regression_cost: 0.05,
      reuse_count: if(is_novel, do: 5, else: 1)
    }
  }
end)

case Tiannara.Audit.Evolution.run_all(historical_data) do
  {:pass, _} -> 
    IO.puts("\n✅ Tier-5 Operational Proof: PASSED")
    IO.puts("   Discovery-to-Value Ratio (DVR) verified.")
  {:fail, _} -> 
    IO.puts("\n❌ Tier-5 Operational Proof: FAILED")
    System.halt(1)
end

IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("🏁 OPERATIONAL PROOF VERIFICATION COMPLETE")
IO.puts(String.duplicate("=", 80) <> "\n")
