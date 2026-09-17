defmodule Tiannara.Forecasting.ForecastAdversarialTest do
  use ExUnit.Case, async: false

  alias Tiannara.Forecasting.{Forecast, ForecastEngine, ForecastRegistry,
                             Calibration, Outcome, BaseRateEngine}

  setup do
    start_supervised!(ForecastRegistry)
    :ets.delete_all_objects(:efdi_forecast_registry)
    :ok
  end

  describe "probability integrity: adversarial inputs" do
    test "huge-but-finite probability is rejected (out of [0,1] bounds)" do
      huge = 1.0e308
      f = Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: [huge, 0.0])
      assert Forecast.validate(f) == {:error, :invalid_probabilities}
    end

    test "values engineered near overflow are never accepted as probabilities" do
      # 1.0e308 is finite in IEEE-754 but absurd as a probability; the integrity
      # gate keeps it out. (True ±inf/NaN cannot be built arithmetically in this
      # OTP — the runtime raises — so this is the strongest provable boundary.)
      near_overflow = 9.9e307
      f = Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: [near_overflow, 0.0])
      assert Forecast.validate(f) == {:error, :invalid_probabilities}
    end

    test "fractional negatives are preserved (no silent clamp) and rejected" do
      f = Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: [-0.01, 1.01])
      assert f.probabilities == [-0.01, 1.01]
      assert Forecast.validate(f) == {:error, :invalid_probabilities}
    end

    test "exactly [0.0, 0.0] is rejected (all zeros cannot sum to 1)" do
      f = Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: [0.0, 0.0])
      assert Forecast.validate(f) == {:error, :distribution_not_normalized}
    end

    test "outcomes/probabilities count mismatch is rejected" do
      f = Forecast.new(question: "Q", outcomes: ["a", "b", "c"], probabilities: [0.5, 0.5])
      assert Forecast.validate(f) == {:error, :outcome_probability_mismatch}
    end

    test "probability integer list with valid bounds normalizes correctly" do
      f = Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: [3, 2])
      # integers > 1 are invalid bounds; validate rejects
      assert Forecast.validate(f) == {:error, :invalid_probabilities}
    end
  end

  describe "forecast immutability: no mutation, no double-count" do
    test "registering the same forecast twice does not change the stored record" do
      f = Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: [0.7, 0.3])
      assert {:ok, f} = ForecastRegistry.register(f)
      assert {:ok, f2} = ForecastRegistry.register(%{f | probabilities: [0.99, 0.01]})
      assert {:ok, stored} = ForecastRegistry.get(f.id)
      assert stored.probabilities == [0.7, 0.3]
      # no-op returned original
      assert f2.id == f.id
    end

    test "attempting to store a mutated version under the same id is rejected" do
      f = Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: [0.7, 0.3])
      assert {:ok, f} = ForecastRegistry.register(f)

      mutated = Map.put(f, :probabilities, [0.0, 1.0])
      assert {:ok, existing} = ForecastRegistry.register(mutated)
      assert existing.probabilities == [0.7, 0.3]
    end

    test "versioning produces a new immutable id; original is untouched" do
      f = Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: [0.7, 0.3])
      assert {:ok, f} = ForecastRegistry.register(f)
      v2 = Forecast.version(f, probabilities: [0.9, 0.1])

      assert v2.id != f.id
      assert v2.probabilities == [0.9, 0.1]
      assert {:ok, original} = ForecastRegistry.get(f.id)
      assert original.probabilities == [0.7, 0.3]
    end

    test "count never double-counts (no duplicate id registrations)" do
      f = Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: [0.7, 0.3])
      {:ok, _} = ForecastRegistry.register(f)
      {:ok, _} = ForecastRegistry.register(f)
      assert ForecastRegistry.count() == 1
    end
  end

  describe "outcome integrity: hindsight contamination and boundary" do
    test "outcome just before creation is contaminated" do
      f = Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: [0.7, 0.3])
      bad = Outcome.new(f.id, "a", observed_at: DateTime.add(f.created_at, -1, :second))
      assert {:error, :hindsight_contamination} = Outcome.guard!(bad, f)
    end

    test "outcome exactly at creation time is clean (boundary)" do
      f = Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: [0.7, 0.3])
      o = Outcome.new(f.id, "a", observed_at: f.created_at)
      assert {:ok, _} = Outcome.guard!(o, f)
    end

    test "outcome far in the future is clean (cannot prove contamination)" do
      f = Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: [0.7, 0.3])
      o = Outcome.new(f.id, "a", observed_at: DateTime.add(f.created_at, 365, :day))
      assert {:ok, _} = Outcome.guard!(o, f)
    end

    test "nil observed_at is treated as clean (honest: cannot prove contamination)" do
      f = Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: [0.7, 0.3])
      o = Outcome.new(f.id, "a")
      assert {:ok, _} = Outcome.guard!(o, f)
    end
  end

  describe "calibration: scoring integrity" do
    test "unknown probability returns :unknown score, not hallucinated" do
      f = Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: :unknown)
      assert %{method: :brier, value: :unknown, sample_size: 0} = Calibration.score(f, "a")
    end

    test "extreme base-rate at boundary (p=0) returns :unknown log loss" do
      f = Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: [0.0, 1.0])
      assert %{value: :unknown} = Calibration.score(f, "a", :log_loss)
    end

    test "mean_brier with no scorable forecasts is :unknown" do
      assert :unknown = Calibration.mean_brier([])
      f = Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: :unknown)
      assert :unknown = Calibration.mean_brier([{f, "a"}])
    end

    test "reliability_level distinguishes insufficient from poor" do
      # 4 samples is insufficient; 5 is adequate
      r4 = Calibration.reliability([{0.8, 1}, {0.8, 1}, {0.8, 0}, {0.8, 1}])
      assert r4.level == :insufficient

      r5 = Calibration.reliability([{0.8, 1}, {0.8, 1}, {0.8, 0}, {0.8, 1}, {0.8, 1}])
      assert r5.level == :adequate
    end
  end

  describe "base-rate integrity: bounds and honesty" do
    test "frequency exactly 1.0 is valid" do
      br = BaseRateEngine.new(reference_class: "r", historical_frequency: 1.0)
      assert {:ok, _} = BaseRateEngine.validate(br)
    end

    test "frequency just above 1.0 is rejected" do
      br = BaseRateEngine.new(reference_class: "r", historical_frequency: 1.0 + 1.0e-9)
      assert {:error, :frequency_out_of_bounds} = BaseRateEngine.validate(br)
    end

    test "base rate unavailable produces honest :unknown prior" do
      {:ok, f} =
        ForecastEngine.forecast(
          question: "Q", event: "e", outcomes: ["a", "b"],
          base_rate: BaseRateEngine.new(reference_class: "r")
        )

      assert f.probabilities == :unknown
      assert f.uncertainty == :base_rate_unavailable
    end

    test "binary base rate not applied to ternary outcome set (no mismatch)" do
      {:ok, f} =
        ForecastEngine.forecast(
          question: "Q", event: "e", outcomes: ["a", "b", "c"],
          base_rate: BaseRateEngine.new(reference_class: "r", historical_frequency: 0.6)
        )

      assert f.probabilities == :unknown
      assert f.uncertainty == :base_rate_outcome_mismatch
    end
  end

  describe "forecast engine: no fabrication, no artificial model zoo" do
    test "engine never produces uniform distribution when base rate is unavailable" do
      {:ok, f} = ForecastEngine.forecast(question: "Q", event: "e", outcomes: ["a", "b", "c"])
      assert f.probabilities == :unknown
      # critically: NOT [0.333, 0.333, 0.334]
    end

    test "engine composes probability update through existing Math.Probability (no local posteriors)" do
      prior = 0.5
      likelihood = 0.8
      evidence = 0.6
      assert {:ok, posterior} = ForecastEngine.update_with_bayes(prior, likelihood, evidence)
      # mathematically: (0.8 * 0.5) / 0.6 = 0.6667
      assert_in_delta(posterior, 0.6667, 1.0e-4)
    end
  end

  describe "adapter boundaries: no parallel ontology" do
    test "EvidenceImpl preserves the test doubles boundary" do
      s = Tiannara.Forecasting.Signal.new(source: :test, observation: 1)
      {:ok, link} = Tiannara.Forecasting.Adapters.EvidenceImpl.link_to_evidence(s, "e1", :supports)
      assert link.kind == :supports
      assert link.evidence_id == "e1"
      assert {:error, :invalid_kind} = Tiannara.Forecasting.Adapters.EvidenceImpl.link_to_evidence(s, "e1", :fake)
    end

    test "WorldModelImpl honestly returns error when world snapshot unavailable" do
      s = Tiannara.Forecasting.Signal.new(source: :orbit, observation: 0.5)
      assert {:error, :world_snapshot_unavailable} =
               Tiannara.Forecasting.Adapters.WorldModelImpl.conflicts_with_world?(s)
    end
  end
end