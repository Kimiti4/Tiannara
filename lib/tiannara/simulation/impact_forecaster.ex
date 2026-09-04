defmodule Tiannara.Simulation.ImpactForecaster do
  alias Tiannara.Simulation.Domain.{SimulationScenario, ImpactAssessment, HorizonForecast}

  @spec forecast(SimulationScenario.t()) :: ImpactAssessment.t()
  def forecast(%SimulationScenario{} = scenario) do
    horizon_forecasts = Enum.map(scenario.horizons, fn horizon ->
      forecast_horizon(scenario, horizon)
    end)

    weights = [0.2, 0.3, 0.5]
    scientific = weighted_average(horizon_forecasts, :scientific, weights)
    engineering = weighted_average(horizon_forecasts, :engineering, weights)
    civilizational = weighted_average(horizon_forecasts, :civilizational, [0.1, 0.3, 0.6])
    sustainability = weighted_average(horizon_forecasts, :sustainability, [0.1, 0.3, 0.6])
    safety = weighted_average(horizon_forecasts, :safety, [0.3, 0.3, 0.4])
    economic = weighted_average(horizon_forecasts, :economic, [0.3, 0.4, 0.3])

    composite = geometric_mean([scientific, engineering, civilizational, sustainability, safety, economic])
    recommendation = determine_recommendation(composite, safety, horizon_forecasts)

    ImpactAssessment.new(%{
      scenario_id: scenario.id, design_id: scenario.design_id,
      scientific_impact: scientific, engineering_impact: engineering,
      civilizational_impact: civilizational, sustainability_impact: sustainability,
      safety_impact: safety, economic_impact: economic,
      composite_score: composite, recommendation: recommendation,
      confidence: compute_confidence(scenario, horizon_forecasts),
      uncertainty: 1.0 - compute_confidence(scenario, horizon_forecasts),
      horizon_forecasts: horizon_forecasts
    })
  end

  @spec compare(ImpactAssessment.t(), ImpactAssessment.t()) :: map()
  def compare(%ImpactAssessment{} = a, %ImpactAssessment{} = b) do
    dimensions = ImpactAssessment.dimensions()

    comparisons = Map.new(dimensions, fn dim ->
      val_a = Map.get(a, dim, 0.0)
      val_b = Map.get(b, dim, 0.0)
      {dim, %{a: val_a, b: val_b, delta: val_a - val_b, winner: if(val_a >= val_b, do: :a, else: :b)}}
    end)

    %{design_a: a.design_id, design_b: b.design_id,
      composite_a: a.composite_score, composite_b: b.composite_score,
      overall_winner: if(a.composite_score >= b.composite_score, do: :a, else: :b),
      dimension_comparisons: comparisons,
      a_strengths: Enum.filter(dimensions, fn d -> Map.get(a, d, 0.0) > Map.get(b, d, 0.0) end),
      b_strengths: Enum.filter(dimensions, fn d -> Map.get(b, d, 0.0) > Map.get(a, d, 0.0) end)}
  end

  defp forecast_horizon(%SimulationScenario{} = scenario, horizon_years) do
    params = scenario.parameters
    changes = scenario.injected_changes
    growth_factor = logistic_growth(horizon_years, Map.get(params, :feasibility, 0.5))
    risk_factor = Map.get(params, :risk, 0.5) * (horizon_years / 100.0)
    safety_decay = Map.get(params, :safety_score, 0.8) * (1.0 - horizon_years * 0.001)

    scientific = min(1.0, growth_factor * 0.7 * length(changes) / 3.0)
    engineering = min(1.0, growth_factor * 0.8 * Map.get(params, :feasibility, 0.5))
    civilizational = min(1.0, growth_factor * 0.5 * Map.get(params, :feasibility, 0.5))
    sustainability = min(1.0, Map.get(params, :safety_score, 0.8) * (1.0 - risk_factor * 0.3))
    safety = max(0.0, min(1.0, safety_decay - risk_factor * 0.2))
    economic = min(1.0, growth_factor * 0.6 * (1.0 - Map.get(params, :risk, 0.5) * 0.3))

    HorizonForecast.new(%{
      scenario_id: scenario.id, horizon_years: horizon_years,
      predicted_state: %{scientific: scientific, engineering: engineering,
        civilizational: civilizational, sustainability: sustainability,
        safety: safety, economic: economic},
      confidence: max(0.1, 1.0 - horizon_years * 0.007),
      uncertainty: min(0.9, horizon_years * 0.007),
      key_changes: identify_key_changes(changes, horizon_years),
      risks: identify_risks(params, horizon_years),
      opportunities: identify_opportunities(params, horizon_years)
    })
  end

  defp logistic_growth(years, feasibility) do
    k = 0.05
    x0 = 30
    1.0 / (1.0 + :math.exp(-k * (years - x0))) * feasibility
  end

  defp weighted_average(forecasts, dimension, weights) do
    values = Enum.map(forecasts, fn f -> Map.get(f.predicted_state, dimension, 0.0) end)
    effective_weights = Enum.take(weights, length(values))

    if effective_weights == [] do
      0.0
    else
      total_weight = Enum.sum(effective_weights)
      Enum.zip(values, effective_weights)
      |> Enum.reduce(0.0, fn {val, weight}, acc -> acc + val * weight end)
      |> Kernel./(max(0.001, total_weight))
    end
  end

  defp geometric_mean(values) do
    if Enum.any?(values, &(&1 <= 0.0)) do
      0.0
    else
      product = Enum.reduce(values, 1.0, &(&1 * &2))
      :math.pow(product, 1.0 / length(values))
    end
  end

  defp determine_recommendation(composite, safety, forecasts) do
    long_term_safety = List.last(forecasts) |> Map.get(:predicted_state, %{}) |> Map.get(:safety, 0.0)

    cond do
      safety < 0.4 or long_term_safety < 0.3 -> :reject
      composite < 0.3 -> :reject
      composite < 0.5 -> :revise
      composite < 0.7 -> :conditional_approve
      true -> :approve
    end
  end

  defp compute_confidence(scenario, forecasts) do
    avg_confidence = forecasts |> Enum.map(& &1.confidence) |> Enum.sum() |> Kernel./(max(1, length(forecasts)))
    completeness = min(1.0, length(scenario.injected_changes) / 3.0)
    avg_confidence * completeness
  end

  defp identify_key_changes(changes, horizon_years) do
    changes |> Enum.take(3) |> Enum.map(fn change ->
      "Deploy #{change.type}: #{Map.get(change, :description, "unnamed")} (impact at #{horizon_years}y)"
    end)
  end

  defp identify_risks(params, horizon_years) do
    (if Map.get(params, :risk, 0.0) > 0.5,
      do: ["High design risk (#{Map.get(params, :risk)}) may compound over #{horizon_years} years"], else: []) ++
    (if Map.get(params, :safety_score, 1.0) < 0.7,
      do: ["Below-threshold safety score (#{Map.get(params, :safety_score)}) requires monitoring"], else: []) ++
    (if horizon_years > 50,
      do: ["Long-term uncertainty: technological paradigm shifts may invalidate assumptions"], else: [])
  end

  defp identify_opportunities(params, horizon_years) do
    (if Map.get(params, :feasibility, 0.0) > 0.7,
      do: ["High feasibility enables rapid deployment and iteration"], else: []) ++
    (if horizon_years >= 50,
      do: ["Compounding effects: early deployment enables decades of iterative improvement"], else: [])
  end
end
