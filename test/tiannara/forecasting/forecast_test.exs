defmodule Tiannara.Forecasting.ForecastTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.Forecast

  describe "new/1" do
    test "builds a normalized immutable forecast from a map" do
      f = Forecast.new(question: "Will event occur?", event: "event_1",
                       outcomes: ["yes", "no"], probabilities: [0.7, 0.5],
                       horizon: 30, regime: :base)
      assert f.question == "Will event occur?"
      assert f.event == "event_1"
      assert f.outcomes == ["yes", "no"]
      # 0.7 + 0.5 = 1.2 → normalized to sum ~1
      assert_in_delta(Enum.sum(f.probabilities), 1.0, 1.0e-6)
      assert f.forecast_version == 1
      assert f.lineage == []
      assert is_binary(f.id)
    end

    test "keeps :unknown probabilities when no base rate justifies a distribution" do
      f = Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: :unknown)
      assert f.probabilities == :unknown
    end

    test "does not fabricate a distribution for a missing or nil probability" do
      assert Forecast.new(question: "Q", outcomes: ["a", "b"]).probabilities == nil
      assert Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: nil).probabilities == nil
    end
  end

  describe "validate/1" do
    defp valid_forecast do
      Forecast.new(question: "Q", outcomes: ["yes", "no"], probabilities: [0.7, 0.3])
    end

    test "returns {:ok, forecast} for a valid forecast" do
      f = valid_forecast()
      assert {:ok, ^f} = Forecast.validate(f)
    end

    test "rejects a missing question" do
      f = Forecast.new(outcomes: ["yes", "no"], probabilities: [0.7, 0.3])
      assert Forecast.validate(f) == {:error, :missing_question}
    end

    test "rejects missing or empty outcomes" do
      assert Forecast.validate(Forecast.new(question: "Q", probabilities: [0.5, 0.5])) ==
               {:error, :missing_outcomes}
    end

    test "rejects an out-of-bounds probability (no silent clamp)" do
      f = Forecast.new(question: "Q", outcomes: ["yes", "no"], probabilities: [1.2, 0.0])
      # construction does NOT silently repair the violation; validate rejects it
      assert f.probabilities == [1.2, 0.0]
      assert Forecast.validate(f) == {:error, :invalid_probabilities}

      g = Forecast.new(question: "Q", outcomes: ["yes", "no"], probabilities: [-0.1, 0.9])
      assert Forecast.validate(g) == {:error, :invalid_probabilities}
    end

    test "rejects a non-normalizable distribution (all zeros)" do
      f = Forecast.new(question: "Q", outcomes: ["yes", "no"], probabilities: [0.0, 0.0])
      assert Forecast.validate(f) == {:error, :distribution_not_normalized}
    end

    test "normalizes an in-bounds under-summed distribution (documented, deterministic)" do
      f = Forecast.new(question: "Q", outcomes: ["yes", "no"], probabilities: [0.7, 0.7])
      assert_in_delta(Enum.sum(f.probabilities), 1.0, 1.0e-6)
      assert {:ok, ^f} = Forecast.validate(f)
    end

    test "rejects mismatch between probability count and outcome count" do
      f = Forecast.new(question: "Q", outcomes: ["a", "b", "c"], probabilities: [0.4, 0.3])
      assert Forecast.validate(f) == {:error, :outcome_probability_mismatch}
    end

    test "accepts :unknown probabilities (honest abstention)" do
      f = Forecast.new(question: "Q", outcomes: ["yes", "no"], probabilities: :unknown)
      assert {:ok, ^f} = Forecast.validate(f)
    end
  end

  describe "version/2" do
    test "produces a new immutable version without mutating the original" do
      f1 = Forecast.new(question: "Q", outcomes: ["yes", "no"], probabilities: [0.7, 0.3])
      f2 = Forecast.version(f1, probabilities: [0.8, 0.2])

      # original immutable
      assert f1.probabilities == [0.7, 0.3]
      # new version
      assert f2.id != f1.id
      assert f2.forecast_version == 2
      assert f2.lineage == [f1.id]
      assert f2.probabilities == [0.8, 0.2]
      assert {:ok, _} = Forecast.validate(f2)
    end

    test "versioning keeps forecast-time information, never hindsight" do
      f1 = Forecast.new(question: "Q", outcomes: ["yes", "no"], probabilities: [0.5, 0.5])
      f2 = Forecast.version(f1, uncertainties: [:new_info])
      # shouldn't gain unknowns list from update key mismatch
      assert f2.unknowns == []

      # Adding an unknown documents the limit, not the answer.
      f3 = Forecast.version(f1, unknowns: [:external_dependency])
      assert f3.unknowns == [:external_dependency]
    end
  end
end