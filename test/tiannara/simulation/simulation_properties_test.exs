defmodule Tiannara.Simulation.SimulationPropertiesTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Tiannara.Simulation.{ScenarioBuilder, ImpactForecaster, HorizonPlanner}
  alias Tiannara.Simulation.Domain.ImpactAssessment
  alias Tiannara.Engineering.Domain.EngineeringInsight
  alias Tiannara.Engineering.DesignTranslator

  defp build_scenario(confidence, feasibility, risk, safety) do
    insight = EngineeringInsight.new(%{
      source_discovery_id: "disc_prop",
      principle_statement: "Property test principle",
      domain: :test, confidence: confidence, evidence_count: 3})

    [design | _] = DesignTranslator.translate(insight)
    design = %{design | feasibility: feasibility, risk: risk, safety_score: safety}
    ScenarioBuilder.build(design)
  end

  describe "ImpactForecaster invariants" do
    property "composite score is always in [0.0, 1.0]" do
      check all confidence <- float(min: 0.1, max: 1.0),
                feasibility <- float(min: 0.1, max: 1.0),
                risk <- float(min: 0.0, max: 1.0),
                safety <- float(min: 0.0, max: 1.0) do
        scenario = build_scenario(confidence, feasibility, risk, safety)
        assessment = ImpactForecaster.forecast(scenario)

        assert assessment.composite_score >= 0.0
        assert assessment.composite_score <= 1.0
      end
    end

    property "confidence + uncertainty = 1.0" do
      check all confidence <- float(min: 0.1, max: 1.0) do
        scenario = build_scenario(confidence, 0.5, 0.5, 0.8)
        assessment = ImpactForecaster.forecast(scenario)

        assert_in_delta assessment.confidence + assessment.uncertainty, 1.0, 0.01
      end
    end

    property "all dimension scores are bounded [0.0, 1.0]" do
      check all confidence <- float(min: 0.1, max: 1.0),
                safety <- float(min: 0.0, max: 1.0) do
        scenario = build_scenario(confidence, 0.5, 0.5, safety)
        assessment = ImpactForecaster.forecast(scenario)

        ImpactAssessment.dimensions()
        |> Enum.each(fn dim ->
          val = Map.get(assessment, dim)
          assert val >= 0.0
          assert val <= 1.0
        end)
      end
    end

    property "recommendation is always a valid atom" do
      check all confidence <- float(min: 0.1, max: 1.0),
                safety <- float(min: 0.0, max: 1.0) do
        scenario = build_scenario(confidence, 0.5, 0.5, safety)
        assessment = ImpactForecaster.forecast(scenario)

        assert assessment.recommendation in [:approve, :conditional_approve, :revise, :reject]
      end
    end
  end

  describe "HorizonPlanner invariants" do
    property "optimal deployment window is always a valid horizon" do
      check all confidence <- float(min: 0.1, max: 1.0) do
        scenario = build_scenario(confidence, 0.7, 0.3, 0.9)
        assessment = ImpactForecaster.forecast(scenario)

        window = HorizonPlanner.optimal_deployment_window(assessment.horizon_forecasts)
        assert window in [10, 50, 100]
      end
    end

    property "deployment plan has phase gates for all horizons" do
      check all confidence <- float(min: 0.1, max: 1.0) do
        scenario = build_scenario(confidence, 0.5, 0.5, 0.8)
        assessment = ImpactForecaster.forecast(scenario)

        plan = HorizonPlanner.plan(scenario, assessment.horizon_forecasts)

        assert length(plan.phase_gates) == length(assessment.horizon_forecasts)
        assert length(plan.horizons) == length(assessment.horizon_forecasts)
      end
    end
  end
end
