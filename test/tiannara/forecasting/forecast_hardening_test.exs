defmodule Tiannara.Forecasting.ForecastEngineTest do
  use ExUnit.Case, async: true
  alias Tiannara.Forecasting.{Baseline, Backtest, ReferenceClass}

  test "naive baseline uses only the last observed value" do
    assert {:ok, 3} = Baseline.naive([1, 2, 3])
  end

  test "moving average refuses insufficient history" do
    assert {:error, :insufficient_history} = Baseline.moving_average([1, 2], 3)
  end

  test "rolling evaluation uses past-only training windows" do
    assert {:ok, report} =
      Backtest.rolling([1, 2, 3, 4, 5, 6], fn train -> {:ok, List.last(train)} end,
        min_train: 3, horizon: 1)

    assert report.leakage_check == :past_only
    assert Enum.all?(report.results, fn r -> r.train_size == r.origin end)
  end

  test "reference classes are conditional and expose adequacy" do
    {:ok, cohort} = ReferenceClass.build(
      [%{region: :a, outcome: :success}, %{region: :a, outcome: :failure}],
      %{region: :a}
    )
    assert cohort.sample_size == 2
    assert ReferenceClass.adequacy(cohort) == :insufficient
  end
end
