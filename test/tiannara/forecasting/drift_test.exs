defmodule Tiannara.Forecasting.DriftTest do
  use ExUnit.Case, async: true
  alias Tiannara.Forecasting.Drift

  test "mean shift is an investigation signal, not a causal conclusion" do
    assert {:ok, result} = Drift.mean_shift(List.duplicate(1.0, 10), List.duplicate(10.0, 10))
    assert result.drift_candidate
    assert result.causal_explanation == :not_established
    assert result.certification_eligible == false
  end

  test "forecast degradation detects increased error against a baseline" do
    assert {:ok, result} =
      Drift.forecast_degradation([10, 10, 10, 10, 10], [13, 13, 13, 13, 13],
        baseline_mae: 1.0, relative_mae_increase: 0.2)
    assert result.degradation_candidate
    assert result.relative_degradation == 2.0
  end

  test "invalid drift samples fail closed" do
    assert {:error, :invalid_series} = Drift.mean_shift([1, 2], [:bad])
  end
end
