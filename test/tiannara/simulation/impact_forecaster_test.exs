defmodule Tiannara.Simulation.ImpactForecasterTest do
  use ExUnit.Case, async: true

  alias Tiannara.Simulation.{ScenarioBuilder, ImpactForecaster, HorizonPlanner}
  alias Tiannara.Simulation.Domain.ImpactAssessment
  alias Tiannara.Engineering.Domain.EngineeringInsight
  alias Tiannara.Engineering.DesignTranslator

  defp test_scenario do
    insight = EngineeringInsight.new(%{
      source_discovery_id: "disc_1",
      principle_statement: "Test principle",
      domain: :test_domain,
      confidence: 0.8,
      evidence_count: 3
    })
    [design | _] = DesignTranslator.translate(insight)
    ScenarioBuilder.build(design)
  end

  describe "forecast/1" do
    test "produces a valid impact assessment" do
      scenario = test_scenario()
      assessment = ImpactForecaster.forecast(scenario)

      assert is_struct(assessment, ImpactAssessment)
      assert assessment.scenario_id == scenario.id
      assert assessment.composite_score >= 0.0
      assert assessment.composite_score <= 1.0
      assert assessment.confidence >= 0.0
      assert assessment.confidence <= 1.0
      assert_in_delta assessment.confidence + assessment.uncertainty, 1.0, 0.01
    end

    test "produces forecasts for all horizons" do
      scenario = test_scenario()
      assessment = ImpactForecaster.forecast(scenario)

      assert length(assessment.horizon_forecasts) == 3
      horizons = Enum.map(assessment.horizon_forecasts, & &1.horizon_years)
      assert horizons == [10, 50, 100]
    end

    test "recommendation is a valid atom" do
      scenario = test_scenario()
      assessment = ImpactForecaster.forecast(scenario)
      assert assessment.recommendation in [:approve, :conditional_approve, :revise, :reject]
    end

    test "all dimension scores are in [0.0, 1.0]" do
      scenario = test_scenario()
      assessment = ImpactForecaster.forecast(scenario)

      ImpactAssessment.dimensions()
      |> Enum.each(fn dim ->
        val = Map.get(assessment, dim)
        assert val >= 0.0, "#{dim} = #{val} < 0.0"
        assert val <= 1.0, "#{dim} = #{val} > 1.0"
      end)
    end
  end

  describe "compare/2" do
    test "produces a valid comparison" do
      scenario = test_scenario()
      assessment_a = ImpactForecaster.forecast(scenario)
      assessment_b = ImpactForecaster.forecast(scenario)

      comparison = ImpactForecaster.compare(assessment_a, assessment_b)

      assert comparison.overall_winner in [:a, :b]
      assert is_map(comparison.dimension_comparisons)
    end
  end
end
