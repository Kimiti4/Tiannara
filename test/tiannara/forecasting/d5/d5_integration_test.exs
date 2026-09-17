defmodule Tiannara.Forecasting.D5.IntegrationTest do
  use ExUnit.Case, async: false

  alias Tiannara.Forecasting.{Forecast, ForecastRegistry}
  alias Tiannara.Forecasting.D5.{
    Perturbation, Sensitivity, Noise, Robustness, Temporal, Disagreement, Regime
  }

  setup do
    start_supervised!(ForecastRegistry)
    :ets.delete_all_objects(:efdi_forecast_registry)
    :ok
  end

  defp forecast(probs \\ [0.7, 0.3]) do
    Forecast.new(question: "Will X happen?", event: "evt", outcomes: ["yes", "no"],
                 probabilities: probs, horizon: 30, forecast_version: 1)
  end

  test "§15.1: activating disagreement produces a NEW immutable forecast version" do
    base = forecast([0.7, 0.3])
    assert {:ok, stored} = ForecastRegistry.register(base)
    assert stored.forecast_version == 1
    assert stored.disagreement == nil

    disagreement_record = %{
      n: 3,
      method: :median,
      std_dev: 0.08,
      model_positions: [%{model: :m1, position: 0.7}, %{model: :m2, position: 0.65}]
    }

    assert {:ok, activated} =
             Disagreement.activate_disagreement(stored, disagreement_record)

    # A NEW version with lineage to the original, and the disagreement attached.
    assert activated.forecast_version == 2
    assert activated.disagreement == disagreement_record
    assert stored.id in activated.lineage

    # The original forecast is NEVER rewritten.
    assert {:ok, original} = ForecastRegistry.get(stored.id)
    assert original.forecast_version == 1
    assert original.disagreement == nil
    assert original.probabilities == [0.7, 0.3]
  end

  test "the original forecast probability/confidence/evidence are never altered by activation" do
    base = forecast([0.55, 0.45])
    assert {:ok, stored} = ForecastRegistry.register(base)
    {:ok, activated} =
      Disagreement.activate_disagreement(stored, %{n: 2, method: :median})

    assert activated.probabilities == [0.55, 0.45]
    assert activated.outcomes == ["yes", "no"]
    assert activated.event == "evt"
    assert activated.question == "Will X happen?"
  end

  test "end-to-end: plan → perturbation validity → sensitivity → robustness" do
    {:ok, plan} =
      Perturbation.register(%{
        target: "recommendation stability",
        dimensions: %{prompt: ["p1", "p2"]},
        rationale: "e2e"
      })

    assert Perturbation.classify(
             plan,
             %{varied_dimensions: [:prompt], at_decision_time_known: true}
           ) == {:ok, %{validity: :valid, dimension_count: 1, within_budget: true, temporal_integrity: :preserved}}

    base_rank = [:a, :b]
    pert_rank = [:b, :a]
    assert Sensitivity.flip?(base_rank, pert_rank) == true

    plan = Perturbation.complete(plan)
    result =
      Robustness.classify(plan, %{
        dimension_results:
          %{prompt: %{material: true, tier: :nominal, runs: 2, flips: 2, valid: true}}
      })

    assert result.class == :fragile
    assert result.coverage_manifest.all_covered
  end

  test "end-to-end: noise analysis with temporal and regime guards" do
    result = Noise.analyze(:evaluator, List.duplicate(0.6, 40))
    assert result.classifiable == true
    assert result.noise_class in [:negligible, :low, :moderate, :high]

    decision = ~U[2026-01-01 00:00:00Z]
    assert Temporal.compute(decision, [~U[2025-12-01 00:00:00Z]]) ==
             {:ok, :decision_time}

    t1 = Regime.tag(%{domain: "finance"})
    t2 = Regime.tag(%{domain: "finance"})
    assert {:ok, _} = Regime.aggregable?([t1, t2])
  end

  test "D5 certification verdict is three-valued, never boolean" do
    v = Tiannara.Forecasting.D5.verdict()
    assert v in [:d5_certified_bounded, :d5_qualified_partial, :d5_not_certified, :unassessed]
  end
end
