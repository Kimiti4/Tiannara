defmodule Tiannara.Forecasting.FeaturesTest do
  use ExUnit.Case, async: true
  alias Tiannara.Forecasting.{Features, ModelComparison}

  test "temporal features use only observations before origin" do
    assert {:ok, report} = Features.build([1, 2, 3, 4, 100], 4, lags: [1, 2], windows: [3])
    assert report.features.lag_1 == 4
    assert report.features.lag_2 == 3
    assert report.features.rolling_mean_3 == 3.0
    assert report.provenance.leakage_check == :past_only
    refute Map.has_key?(report.features, :future)
  end

  test "future origin and malformed series fail closed" do
    assert {:error, :invalid_origin} = Features.build([1, 2], 3)
    assert {:error, :non_numeric_series} = Features.build([1, :bad], 1)
  end

  test "model comparison measures against the same actual outcomes" do
    model = [%{prediction: 10, actual: [11]}, %{prediction: 20, actual: [18]}]
    baseline = [%{prediction: 8, actual: [11]}, %{prediction: 21, actual: [18]}]

    assert {:ok, report} = ModelComparison.compare(model, baseline)
    assert report.pairs == 2
    assert report.status == :comparison_only
    assert report.acceptance == :requires_independent_review
  end
end
