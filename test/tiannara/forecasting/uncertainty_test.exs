defmodule Tiannara.Forecasting.UncertaintyTest do
  use ExUnit.Case, async: true
  alias Tiannara.Forecasting.Uncertainty

  test "interval score penalizes missed observations" do
    assert {:ok, inside} = Uncertainty.interval_score(0, 10, 5, 0.1)
    assert {:ok, outside} = Uncertainty.interval_score(0, 10, 20, 0.1)
    assert outside > inside
  end

  test "coverage reports empirical rather than guaranteed coverage" do
    intervals = [
      %{lower: 0, upper: 10, actual: 5},
      %{lower: 0, upper: 10, actual: 20}
    ]
    assert {:ok, result} = Uncertainty.coverage(intervals, 0.1)
    assert result.coverage == 0.5
    assert result.nominal_coverage == 0.9
    assert result.status == :empirical_diagnostic
    assert result.certification_eligible == false
  end

  test "risk decomposition is not treated as a probability" do
    assert {:ok, result} =
      Uncertainty.model_risk(%{data: 0.2, distribution_shift: 0.4, unknown: 0.1})
    assert result.total == 0.7
    assert result.interpretation == :risk_decomposition_not_probability
  end
end
