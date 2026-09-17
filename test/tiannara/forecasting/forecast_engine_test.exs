defmodule Tiannara.Forecasting.ForecastEngineTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.{Forecast, ForecastEngine, BaseRateEngine}
  alias Tiannara.Forecasting.Contracts.{ForecastRequest, BaseRate}
  alias Tiannara.Forecasting.Contracts.Forecast, as: FC

  describe "forecast/1" do
    test "produces a probabilistic forecast from a binary request with base rate" do
      br = BaseRateEngine.new(reference_class: "known_rate", historical_frequency: 0.6)
      {:ok, f} =
        ForecastEngine.forecast(
          question: "Will X occur?",
          event: "evt_1",
          outcomes: ["yes", "no"],
          horizon: 30,
          base_rate: br,
          signal_ids: ["sig_1"],
          evidence_ids: ["ev1"],
          regime: :base
        )

      assert Forecast.validate(f) == {:ok, f}
      assert_in_delta(Enum.at(f.probabilities, 0), 0.6, 1.0e-6)
      assert f.base_rate_ref.reference_class == "known_rate"
      assert f.signal_refs == ["sig_1"]
      assert f.evidence_refs == ["ev1"]
      assert f.horizon == 30
      assert f.regime == :base
    end

    test "uses honest :unknown prior when no base rate available" do
      {:ok, f} =
        ForecastEngine.forecast(question: "Q", event: "e", outcomes: ["a", "b"], horizon: 10)

      assert f.probabilities == :unknown
      assert f.uncertainty == :no_base_rate
      # still a valid, honest forecast
      assert Forecast.validate(f) == {:ok, f}
    end

    test "rejects missing outcomes" do
      assert {:error, :missing_outcomes} =
               ForecastEngine.forecast(question: "Q", event: "e")
    end

    test "rejects an invalid base rate" do
      bad = %BaseRate{reference_class: nil, historical_frequency: 0.5}
      assert {:error, :missing_reference_class} =
               ForecastEngine.forecast(question: "Q", event: "e", outcomes: ["a", "b"],
                                       base_rate: bad)
    end

    test "accepts a ForecastRequest struct directly" do
      req = %ForecastRequest{question: "Q", event: "e", outcomes: ["a", "b"]}
      assert {:ok, %FC{} = _} = ForecastEngine.forecast(req)
    end
  end

  describe "base_rate_prior/2" do
    test "maps a binary base rate onto a two-outcome distribution" do
      br = BaseRateEngine.new(reference_class: "r", historical_frequency: 0.7)
      {prior, :base_rate} = ForecastEngine.base_rate_prior(br, ["a", "b"])
      assert_in_delta(Enum.at(prior, 0), 0.7, 1.0e-9)
      assert_in_delta(Enum.sum(prior), 1.0, 1.0e-9)
    end

    test "does not apply a binary base rate to a non-binary outcome set" do
      br = BaseRateEngine.new(reference_class: "r", historical_frequency: 0.7)
      assert {prior, :base_rate_outcome_mismatch} = ForecastEngine.base_rate_prior(br, ["a", "b", "c"])
      assert prior == :unknown
    end

    test "returns :unknown prior when base rate is unavailable" do
      assert {:unknown, :base_rate_unavailable} =
               ForecastEngine.base_rate_prior(%BaseRate{reference_class: "r"}, ["a", "b"])
      assert {:unknown, :no_base_rate} = ForecastEngine.base_rate_prior(nil, ["a", "b"])
    end
  end

  describe "update_with_bayes/3" do
    test "composes existing Math.Probability.bayes_update" do
      assert {:ok, posterior} = ForecastEngine.update_with_bayes(0.5, 0.9, 0.5)
      assert is_number(posterior)
      assert posterior > 0.5
    end

    test "never fabricates a posterior from :unknown prior" do
      assert {:error, :unknown_prior} = ForecastEngine.update_with_bayes(:unknown, 0.9, 0.5)
      assert {:error, :unknown_evidence} = ForecastEngine.update_with_bayes(0.5, :unknown, 0.5)
    end
  end
end