defmodule Tiannara.Audit.Evolution do
  @moduledoc """
  Tier-5 Evolutionary Effectiveness Audit.
  Measures whether Tiannara is measurably improving over long horizons
  through its autonomous REA cycles.
  """
  require Logger

  alias Tiannara.Sentinel.OperationalObservatory

  @doc "Analyzes evolutionary metrics based on historical REA experiment data."
  def run_all(historical_data \\ []) do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("🛡️  TIANNARA TIER-5: EVOLUTIONARY EFFECTIVENESS")
    IO.puts(String.duplicate("=", 80))

    data = 
      if Enum.empty?(historical_data) do
        maturity = Tiannara.Sentinel.OperationalObservatory.get_operational_maturity()
        
        if maturity.cycles >= 100 do
          IO.puts("🌐 Dynamic Audit Mode: OPERATIONAL-DOMINATED WEIGHTING (cycles: #{maturity.cycles})")
          Tiannara.Sentinel.OperationalObservatory.load_events("data/operational_events.ndjson")
          |> Enum.filter(& &1[:status] in [:evaluated, "evaluated"])
        else
          IO.puts("🧪 Dynamic Audit Mode: SIMULATION-DOMINATED WEIGHTING (cycles: #{maturity.cycles}/100)")
          events = Tiannara.Sentinel.OperationalObservatory.load_events("data/simulation_events.ndjson")
          evaluated = Enum.filter(events, & &1[:status] in [:evaluated, "evaluated"])
          if Enum.empty?(evaluated), do: events, else: evaluated
        end
      else
        historical_data
      end

    results = [
      audit_architectural_fitness(data),
      audit_improvement_yield(data),
      audit_research_efficiency(data),
      audit_novel_discovery_rate(data),
      # DVR is now the primary evidence for research effectiveness
      audit_discovery_to_value_ratio(data)
    ]

    # Overall pass requires DVR to be healthy
    dvr_passed = match?({:pass, _, _}, Enum.at(results, 4))
    passed_count = Enum.count(results, fn {status, _, _} -> status == :pass end)
    
    status = if(dvr_passed and passed_count >= 3, do: :pass, else: :fail)
    {status, results}
  end

  # --- Evolution A: Architectural Fitness ---
  def audit_architectural_fitness(data) do
    IO.write("Tier-5 A: Architectural Fitness...      ")
    # Compare early vs late metrics (Prediction Accuracy, GHL, Defect Detection)
    if length(data) < 2 do
      report(:pending, "Insufficient historical data for fitness trend.")
    else
      {early, late} = split_history(data)
      
      fitness_improved = late.avg_prediction_accuracy > early.avg_prediction_accuracy and
                         late.avg_ghl >= early.avg_ghl

      if fitness_improved do
        report(:pass, "Fitness metrics improved: Acc ↑#{Float.round((late.avg_prediction_accuracy - early.avg_prediction_accuracy) * 100, 2)}%")
      else
        report(:fail, "Stagnant or degrading architectural fitness.")
      end
    end
  end

  # --- Evolution B: Improvement Yield ---
  def audit_improvement_yield(data) do
    IO.write("Tier-5 B: Improvement Yield...          ")
    # Yield Rate = Positive Results / Total Accepted Proposals
    if Enum.empty?(data) do
      report(:pending, "No proposals to calculate yield.")
    else
      total = Enum.count(data)
      positive = Enum.count(data, & &1.result == :positive)
      yield_rate = positive / total

      if yield_rate >= 0.6 do
        report(:pass, "Improvement Yield Rate: #{Float.round(yield_rate * 100, 2)}% (Target > 60%)")
      else
        report(:fail, "Yield Rate below target: #{Float.round(yield_rate * 100, 2)}%")
      end
    end
  end

  # --- Evolution C: Research Efficiency ---
  def audit_research_efficiency(data) do
    IO.write("Tier-5 C: Research Efficiency...        ")
    # Success per experiment attempt over time
    if length(data) < 10 do
      report(:pending, "Insufficient cycles for efficiency analysis.")
    else
      {early, late} = split_history(data)
      early_eff = early.success_count / early.total_attempts
      late_eff = late.success_count / late.total_attempts

      if late_eff > early_eff do
        report(:pass, "Efficiency improved: #{Float.round(late_eff, 2)} vs #{Float.round(early_eff, 2)}")
      else
        report(:fail, "Research efficiency is stagnant.")
      end
    end
  end

  # --- Evolution D: Novel Discovery Rate ---
  def audit_novel_discovery_rate(data) do
    IO.write("Tier-5 D: Novel Discovery Rate...       ")
    # Count discoveries not previously encoded
    novel_count = Enum.count(data, & &1.is_novel_discovery)
    
    if novel_count > 0 do
      report(:pass, "Detected #{novel_count} novel architectural discoveries.")
    else
      report(:fail, "No novel discoveries detected (only rule-following).")
    end
  end

  # --- Evolution E: Discovery-to-Value Ratio ---
  def audit_discovery_to_value_ratio(data) do
    IO.write("Tier-5 E: Discovery-to-Value Ratio...   ")
    dvr = OperationalObservatory.calculate_dvr(data)
    
    if dvr >= 0.5 do
      report(:pass, "DVR: #{Float.round(dvr, 2)} (Target > 0.5). Genuine research value proven.")
    else
      report(:fail, "Low DVR: #{Float.round(dvr, 2)}. Discoveries are not translating to value.")
    end
  end

  # --- Helpers ---

  defp report(status, msg) do
    case status do
      :pass -> IO.puts("✅ PASS: #{msg}")
      :fail -> IO.puts("❌ FAIL: #{msg}")
      :pending -> IO.puts("⏳ PENDING: #{msg}")
    end
    {status, msg, nil}
  end

  defp split_history(data) do
    mid = div(length(data), 2)
    {early_raw, late_raw} = Enum.split(data, mid)
    
    {summarize(early_raw), summarize(late_raw)}
  end

  defp summarize(batch) do
    %{
      avg_prediction_accuracy: Enum.map(batch, & &1.prediction_accuracy) |> average(),
      avg_ghl: Enum.map(batch, & &1.ghl) |> average(),
      success_count: Enum.count(batch, & &1.result == :positive),
      total_attempts: Enum.count(batch)
    }
  end

  defp average([]), do: 0.0
  defp average(list), do: Enum.sum(list) / length(list)
end
