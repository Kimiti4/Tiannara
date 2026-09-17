defmodule Tiannara.Forecasting.CalibrationTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.{Forecast, Calibration}

  defp forecast(probs) do
    Forecast.new(question: "Q", event: "evt", outcomes: ["yes", "no"], probabilities: probs)
  end

  describe "score/3 brier" do
    test "scores a well-calibrated binary forecast" do
      # p=0.7 for the observed outcome → brier (0.7-1)^2 = 0.09
      %{method: :brier, value: v, sample_size: 1} = Calibration.score(forecast([0.7, 0.3]), 0)
      assert_in_delta(v, 0.09, 1.0e-9)
    end

    test "accepts outcome value instead of index" do
      %{method: :brier, value: v} = Calibration.score(forecast([0.7, 0.3]), "yes")
      assert_in_delta(v, 0.09, 1.0e-9)
    end
  end

  describe "score/3 log_loss" do
    test "log loss grows as confidence is misplaced" do
      perfect = Calibration.score(forecast([0.9, 0.1]), 0)
      bad = Calibration.score(forecast([0.1, 0.9]), 0)
      assert perfect.value < bad.value
    end

    test "returns :unknown log loss when probability is 0 (cannot be scored)" do
      assert %{value: :unknown, sample_size: 0} = Calibration.score(forecast([0.0, 1.0]), 0, :log_loss)
    end
  end

  describe "brier/2 and log_loss/2" do
    test "brier = (p-observed)^2" do
      assert_in_delta(Calibration.brier(0.5, 1), 0.25, 1.0e-9)
      assert_in_delta(Calibration.brier(0.9, 0), 0.81, 1.0e-9)
    end

    test "log loss matches -ln(p)" do
      assert_in_delta(Calibration.log_loss(0.5, 1), 0.693147, 1.0e-6)
      assert Calibration.log_loss(0.0, 1) == :unknown
    end
  end

  describe "mean_brier/1 and mean_log_loss/1" do
    test "averages over a list of pairs" do
      pairs = [{forecast([0.9, 0.1]), 0}, {forecast([0.9, 0.1]), 0}]
      assert_in_delta(Calibration.mean_brier(pairs), 0.01, 1.0e-9)
      assert Calibration.mean_log_loss(pairs) > 0
    end

    test "handles empty/discarded lists as :unknown" do
      assert Calibration.mean_brier([]) == :unknown
      assert Calibration.mean_log_loss([{forecast([0.0, 1.0]), 0}]) == :unknown
    end
  end

  describe "calibration_error/1 and resolution/1" do
    test "measures mean |p - observed_freq|" do
      # p=0.8 observed=1 → diff 0.2 ; p=0.6 observed=0 → diff 0.6 ; mean 0.4
      assert_in_delta(Calibration.calibration_error([{0.8, 1}, {0.6, 0}]), 0.4, 1.0e-9)
    end

    test "resolution of constant frequencies is 0" do
      assert_in_delta(Calibration.resolution([{0.5, 1}, {0.5, 1}]), 0.0, 1.0e-9)
    end

    test "empty data is :unknown" do
      assert Calibration.calibration_error([]) == :unknown
      assert Calibration.resolution([]) == :unknown
    end
  end

  describe "reliability_level/1 and reliability/1 (INSUFFICIENT_DATA semantics)" do
    test "explicitly distinguishes insufficient data from poor calibration" do
      assert Calibration.reliability_level(0) == :insufficient
      assert Calibration.reliability_level(4) == :insufficient
      assert Calibration.reliability_level(5) == :adequate
      # Reliability report carries the level; a 1-point "calibration" is NOT poor, it is insufficient.
      r = Calibration.reliability([{0.8, 1}])
      assert r.level == :insufficient
    end
  end

  describe "sharpness/1" do
    test "is negative entropy: sharper than uniform" do
      sharp = Calibration.sharpness(forecast([0.99, 0.01]))
      flat = Calibration.sharpness(forecast([0.5, 0.5]))
      assert sharp > flat
    end

    test "returns :unknown for an unknown distribution" do
      assert Calibration.sharpness(Forecast.new(question: "Q", outcomes: ["a", "b"], probabilities: :unknown)) == :unknown
    end
  end
end