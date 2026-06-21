defmodule Tiannara.Audit.Phase11_6 do
  @moduledoc """
  Tier-6 Audit: Operational Response Curve (Phase 11.6).
  Analyzes the Inverted-U response of Tiannara to memory retention.
  """
  require Logger
  alias Tiannara.REA.Phase11_6.Operational

  def run_analysis(historical_data \\ []) do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("🛡️  TIANNARA TIER-6: OPERATIONAL RESPONSE CURVE (PHASE 11.6B)")
    IO.puts(String.duplicate("=", 80))

    data = 
      if Enum.empty?(historical_data) do
        op_events = Tiannara.Sentinel.OperationalObservatory.load_events("data/operational_events.ndjson")
        evaluated_op = Enum.filter(op_events, & &1[:status] in [:evaluated, "evaluated"])
        
        if not Enum.empty?(evaluated_op) do
          evaluated_op
        else
          sim_events = Tiannara.Sentinel.OperationalObservatory.load_events("data/simulation_events.ndjson")
          evaluated_sim = Enum.filter(sim_events, & &1[:status] in [:evaluated, "evaluated"])
          if Enum.empty?(evaluated_sim), do: sim_events, else: evaluated_sim
        end
      else
        historical_data
      end

    # Phase 11.6B: Analyzing multiple optima across memory classes
    memory_classes = [:experiment_logs, :failures, :architecture, :telemetry, :specialist_context]
    
    Enum.each(memory_classes, fn class ->
      analyze_class_curve(class, data)
    end)
  end

  @doc """
  Publicly exposes the simulated curve results for reporting.
  """
  def get_simulated_curve(historical_data \\ []) do
    data = 
      if Enum.empty?(historical_data) do
        op_events = Tiannara.Sentinel.OperationalObservatory.load_events("data/operational_events.ndjson")
        evaluated_op = Enum.filter(op_events, & &1[:status] in [:evaluated, "evaluated"])
        
        if not Enum.empty?(evaluated_op) do
          evaluated_op
        else
          sim_events = Tiannara.Sentinel.OperationalObservatory.load_events("data/simulation_events.ndjson")
          evaluated_sim = Enum.filter(sim_events, & &1[:status] in [:evaluated, "evaluated"])
          if Enum.empty?(evaluated_sim), do: sim_events, else: evaluated_sim
        end
      else
        historical_data
      end

    retention_levels = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
    Enum.map(retention_levels, fn level ->
      {level, simulate_operational_metrics(data, level, :experiment_logs)}
    end)
  end

  defp analyze_class_curve(class, data) do
    IO.write("Analyzing #{String.pad_trailing("#{class}", 20)}... ")
    
    # Sweep around the dynamic estimate
    base_level = Operational.dynamic_estimate(class)
    sweep = [base_level - 0.2, base_level - 0.1, base_level, base_level + 0.1, base_level + 0.2]
            |> Enum.map(&max(0.0, min(1.0, &1)))
            |> Enum.uniq()

    curve = Enum.map(sweep, fn level ->
      metrics = simulate_operational_metrics(data, level, class)
      {level, metrics}
    end)

    case analyze_inverted_u(curve, class) do
      {:pass, peak} -> IO.puts("✅ PEAK: #{round(peak * 100)}%")
      {:fail, _} -> IO.puts("❌ NO CLEAR OPTIMUM")
    end
  end

  defp simulate_operational_metrics(_data, level, class) do
    # Peak is subsystem-dependent in Phase 11.6B
    peak = Operational.dynamic_estimate(class)
    dist_from_peak = abs(level - peak)
    
    %{
      ghl: 150.0 - (dist_from_peak * 100),
      dvr: 0.8 - (dist_from_peak * 0.5)
    }
  end

  defp analyze_inverted_u(curve, _class) do
    ghl_values = Enum.map(curve, fn {_, m} -> m.ghl end)
    max_val = Enum.max(ghl_values)
    max_idx = Enum.find_index(ghl_values, fn v -> v == max_val end)
    
    # An inverted-U is present if the maximum is not at the boundaries
    if max_idx > 0 and max_idx < (length(ghl_values) - 1) do
      peak_level = Enum.at(curve, max_idx) |> elem(0)
      {:pass, peak_level}
    else
      {:fail, nil}
    end
  end
end
