defmodule Tiannara.Simulation.HorizonPlanner do
  alias Tiannara.Simulation.Domain.{SimulationScenario, HorizonForecast}

  @spec plan(SimulationScenario.t(), [HorizonForecast.t()]) :: map()
  def plan(%SimulationScenario{} = scenario, forecasts) when is_list(forecasts) do
    %{scenario_id: scenario.id, design_id: scenario.design_id,
      horizons: Enum.map(forecasts, fn forecast -> plan_horizon(scenario, forecast) end),
      phase_gates: build_phase_gates(forecasts),
      rollback_criteria: build_rollback_criteria(forecasts),
      review_schedule: build_review_schedule(),
      created_at: DateTime.utc_now()}
  end

  @spec optimal_deployment_window([HorizonForecast.t()]) :: non_neg_integer()
  def optimal_deployment_window(forecasts) when is_list(forecasts) do
    if forecasts == [] do
      10
    else
      forecasts
      |> Enum.map(fn f ->
        state = f.predicted_state
        benefit = (Map.get(state, :scientific, 0.0) + Map.get(state, :engineering, 0.0)) / 2.0
        risk = 1.0 - Map.get(state, :safety, 0.5)
        {f.horizon_years, benefit * (1.0 - risk)}
      end)
      |> Enum.max_by(fn {_horizon, score} -> score end)
      |> elem(0)
    end
  end

  defp plan_horizon(%SimulationScenario{} = scenario, %HorizonForecast{} = forecast) do
    %{horizon_years: forecast.horizon_years,
      objectives: build_objectives(scenario, forecast),
      milestones: build_milestones(forecast),
      review_criteria: build_review_criteria(forecast),
      predicted_state: forecast.predicted_state,
      confidence: forecast.confidence,
      risks: forecast.risks,
      opportunities: forecast.opportunities}
  end

  defp build_objectives(scenario, forecast) do
    base = ["Deploy and validate #{scenario.design_id} components",
            "Measure actual impact against predicted: #{inspect(forecast.predicted_state)}"]
    case forecast.horizon_years do
      10 -> base ++ ["Establish baseline metrics", "Identify early failure modes"]
      50 -> base ++ ["Scale to full deployment", "Integrate with adjacent systems"]
      100 -> base ++ ["Evaluate civilizational-scale impact", "Plan next-generation replacement"]
      _ -> base
    end
  end

  defp build_milestones(forecast) do
    [%{name: "Initial deployment", at_years: 1, criteria: "All components operational"},
     %{name: "First review", at_years: round(forecast.horizon_years * 0.25), criteria: "Metrics within 20% of forecast"},
     %{name: "Mid-point review", at_years: round(forecast.horizon_years * 0.5), criteria: "Safety score maintained"},
     %{name: "Horizon review", at_years: forecast.horizon_years, criteria: "Impact assessment updated"}]
  end

  defp build_review_criteria(forecast) do
    ["Actual scientific impact within 30% of predicted (#{Float.round(Map.get(forecast.predicted_state, :scientific, 0.0), 2)})",
     "Safety score remains above 0.5",
     "No unanticipated failure modes",
     "Resource usage within 50% of estimated"]
  end

  defp build_phase_gates(forecasts) do
    Enum.map(forecasts, fn f ->
      %{at_horizon: f.horizon_years,
        gate_criteria: ["Safety score >= 0.5 (actual: #{Float.round(Map.get(f.predicted_state, :safety, 0.0), 2)})",
                        "Composite impact >= 0.3",
                        "No critical risks materialized"],
        action_if_failed: :rollback_to_previous_stable_state}
    end)
  end

  defp build_rollback_criteria(_forecasts) do
    ["Safety score drops below 0.3 at any horizon",
     "Composite impact drops below 0.2",
     "Resource usage exceeds 200% of estimated",
     "Critical failure mode discovered with no mitigation",
     "Constitutional violation detected"]
  end

  defp build_review_schedule do
    [%{at_years: 1, type: :operational_review},
     %{at_years: 5, type: :impact_review},
     %{at_years: 10, type: :strategic_review},
     %{at_years: 25, type: :civilizational_review},
     %{at_years: 50, type: :paradigm_review},
     %{at_years: 100, type: :legacy_review}]
  end
end
