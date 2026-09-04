# Calculate DVR, Surprise, and Law Confidence Scorecard
# Usage: mix run scripts/calculate_dvr_report.exs

Code.require_file("lib/tiannara/sentinel/operational_observatory.ex")
alias Tiannara.Sentinel.OperationalObservatory

IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("🛡️  TIANNARA SCIENTIFIC DISCOVERY & DVR SCORECARD")
IO.puts(String.duplicate("=", 80))

# 1. Centralized Operational Maturity
maturity = OperationalObservatory.get_operational_maturity()
IO.puts("\n📊 Centralized Operational Maturity:")
IO.puts("   Cycles Run:            #{maturity.cycles}")
IO.puts("   Active Days:           #{maturity.days}")
IO.puts("   Total Discoveries:     #{maturity.discoveries}")
IO.puts("   Validated Discoveries: #{maturity.validated_discoveries}")

# 2. Simulation vs Operational Analytics
sim_events = OperationalObservatory.load_events("data/simulation_events.ndjson")
sim_eval = Enum.filter(sim_events, fn ev -> ev[:status] in [:evaluated, "evaluated"] end)

op_events = OperationalObservatory.load_events("data/operational_events.ndjson")
op_eval = Enum.filter(op_events, fn ev -> ev[:status] in [:evaluated, "evaluated"] end)

# Compute DVRs
sim_dvr = OperationalObservatory.calculate_dvr(sim_eval)
op_dvr = OperationalObservatory.calculate_dvr(op_eval)

# Compute Average Surprise
defmodule SurpriseHelper do
  def avg_surprise([]), do: 0.0
  def avg_surprise(events) do
    surprises = Enum.map(events, &OperationalObservatory.calculate_surprise_index/1)
    Enum.sum(surprises) / length(events)
  end
end

sim_surprise = SurpriseHelper.avg_surprise(sim_eval)
op_surprise = SurpriseHelper.avg_surprise(op_eval)

IO.puts("\n🔍 Scientific Metrics Ledger:")
IO.puts("   Simulation/Replay Data:")
IO.puts("     Total Evaluated Cycles: #{length(sim_eval)}")
IO.puts("     Discovery-to-Value Ratio (DVR): #{Float.round(sim_dvr, 4)}")
IO.puts("     Average Surprise Index:         #{Float.round(sim_surprise, 4)}")

IO.puts("   Live Operational Data:")
IO.puts("     Total Evaluated Cycles: #{length(op_eval)}")
IO.puts("     Discovery-to-Value Ratio (DVR): #{Float.round(op_dvr, 4)}")
IO.puts("     Average Surprise Index:         #{Float.round(op_surprise, 4)}")

# 3. Law Confidence Evolution
IO.puts("\n⚖️ Law Confidence Registry:")
Enum.each([:structured_forgetting, :asymmetric_specialization], fn law_id ->
  status = OperationalObservatory.track_law_confidence(law_id)
  IO.puts("   • Law: #{String.pad_trailing("#{status.law}", 25)} | status: #{String.pad_trailing("#{status.status}", 12)} | confidence: #{Float.round(status.confidence, 4)} (Sim #{status.evidence.simulation_cycles} | Op #{status.evidence.operational_cycles})")
end)

IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("🏁 SCORECARD CALCULATION COMPLETE")
IO.puts(String.duplicate("=", 80) <> "\n")
