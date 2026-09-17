defmodule Tiannara.Forecasting.ForecastReplayTest do
  use ExUnit.Case, async: false

  alias Tiannara.Forecasting.{Forecast, ForecastEngine, ForecastRegistry, BaseRateEngine, Outcome, Calibration}

  setup do
    start_supervised!(ForecastRegistry)
    :ets.delete_all_objects(:efdi_forecast_registry)
    :ok
  end

  describe "reproducibility: same inputs → same distribution (deterministic)" do
    test "two forecasts with identical inputs produce identical probabilities" do
      br = BaseRateEngine.new(reference_class: "r", historical_frequency: 0.6)
      {:ok, f1} = ForecastEngine.forecast(question: "Q", event: "e", outcomes: ["yes", "no"],
                                          horizon: 30, base_rate: br)
      {:ok, f2} = ForecastEngine.forecast(question: "Q", event: "e", outcomes: ["yes", "no"],
                                          horizon: 30, base_rate: br)

      # ids differ (new id each time — that is correct: identity is per-entity, not per-value)
      assert f1.id != f2.id
      # but the distribution, evidence, and model are identical (reproducible decision path)
      assert f1.probabilities == f2.probabilities
      assert f1.horizon == f2.horizon
      assert f1.outcomes == f2.outcomes
      assert f1.base_rate_ref == f2.base_rate_ref
    end

    test "unavailable base rates produce the same :unknown pattern" do
      {:ok, f1} = ForecastEngine.forecast(question: "Q", event: "e1", outcomes: ["a", "b", "c"])
      {:ok, f2} = ForecastEngine.forecast(question: "Q", event: "e2", outcomes: ["a", "b", "c"])
      assert f1.probabilities == :unknown
      assert f2.probabilities == :unknown
      assert f1.uncertainty == :no_base_rate
      assert f2.uncertainty == :no_base_rate
    end
  end

  describe "lineage reconstruction: what did Tiannara believe at time T" do
    test "a versioned forecast's full history is reconstructible from lineage" do
      {:ok, v1} = ForecastEngine.forecast(
        question: "Q", event: "e", outcomes: ["a", "b"],
        base_rate: BaseRateEngine.new(reference_class: "r", historical_frequency: 0.7))

      v2 = Forecast.version(v1, probabilities: [0.9, 0.1])
      v3 = Forecast.version(v2, probabilities: [0.95, 0.05], unknowns: [:new_evidence])

      assert v3.lineage == [v2.id, v1.id]
      assert v3.forecast_version == 3

      # Reconstruct the belief chain (round expected floats for IEEE tolerance)
      chain =
        [v3, v2, v1]
        |> Enum.map(&{&1.forecast_version, Enum.map(&1.probabilities, fn p -> round(p * 1.0e9) / 1.0e9 end)})

      assert chain == [
        {3, [0.95, 0.05]},
        {2, [0.9, 0.1]},
        {1, [0.7, 0.3]}
      ]

      # The root's lineage is empty; each child references its parent
      assert v1.lineage == []
      assert v2.lineage == [v1.id]
      assert v3.lineage == [v2.id, v1.id]
    end

    test "registered originals remain retrievable after versioning" do
      {:ok, v1} = ForecastEngine.forecast(
        question: "Q", event: "e", outcomes: ["a", "b"],
        base_rate: BaseRateEngine.new(reference_class: "r", historical_frequency: 0.5))

      {:ok, _} = ForecastRegistry.register(v1)
      v2 = Forecast.version(v1, probabilities: [0.9, 0.1])
      v3 = Forecast.version(v2, probabilities: [0.95, 0.05])

      # v1 is in the registry
      assert {:ok, stored_v1} = ForecastRegistry.get(v1.id)
      assert stored_v1.probabilities == v1.probabilities
      assert stored_v1.forecast_version == 1

      # v2 and v3 were not registered (versioning ≠ registration)
      assert :error = ForecastRegistry.get(v2.id)
      assert :error = ForecastRegistry.get(v3.id)
    end
  end

  describe "replay integrity: scoring is deterministic and attribution-safe" do
    test "scoring the same forecast twice gives identical results" do
      f = Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: [0.8, 0.2])
      s1 = Calibration.score(f, "a")
      s2 = Calibration.score(f, "a")
      assert s1 == s2
    end

    test "Brier and log loss are both single-valued, correct metric (no hidden recalibration)" do
      f = Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: [0.8, 0.2])

      brier = Calibration.score(f, "a", :brier)
      ll = Calibration.score(f, "a", :log_loss)

      # Brier = (0.8 - 1)^2 = 0.04
      assert_in_delta(brier.value, 0.04, 1.0e-9)
      # log loss = -ln(0.8) = 0.2231
      assert_in_delta(ll.value, 0.2231, 1.0e-4)

      # Scoring method recorded (attribution, not arbitrary re-derivation)
      assert brier.method == :brier
      assert ll.method == :log_loss
    end

    test "calibration error is computed the same way cumulatively as individual" do
      f1 = Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: [0.9, 0.1])
      f2 = Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: [0.6, 0.4])

      pairs = [{f1, "a"}, {f2, "a"}]
      mb = Calibration.mean_brier(pairs)

      individual = [Calibration.score(f1, "a", :brier).value, Calibration.score(f2, "a", :brier).value]
      assert_in_delta(mb, Enum.sum(individual) / 2, 1.0e-9)
    end
  end

  describe "outcome replay: full pipeline reproducibility" do
    test "forecast → outcome → score yields the same score on a second observation" do
      f = Forecast.new(question: "Q", outcomes: ["yes", "no"], probabilities: [0.7, 0.3])
      o1 = Outcome.new(f.id, "yes", observed_at: DateTime.add(f.created_at, 1, :hour))
      o2 = Outcome.new(f.id, "yes", observed_at: DateTime.add(f.created_at, 1, :hour))

      assert Outcome.hindsight_clean?(o1, f) == Outcome.hindsight_clean?(o2, f)
      assert Calibration.score(f, o1.observed_outcome) == Calibration.score(f, o2.observed_outcome)
    end
  end
end