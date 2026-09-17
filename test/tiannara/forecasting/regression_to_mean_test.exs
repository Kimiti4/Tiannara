defmodule Tiannara.Forecasting.RegressionToMeanTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.RegressionToMean

  test "no reference class → plausibility is first-class unknown" do
    r = RegressionToMean.analyze([10, 8, 9, 8.5], nil)
    assert r.rtm_plausibility == :unknown
    assert r.extremity_index == :unknown
  end

  test "extreme first observation with a reference class flags likely reversion" do
    r = RegressionToMean.analyze([10, 6, 7, 6.5], %{mean: 5, std: 1})
    assert r.extremity_index == 5.0
    assert r.rtm_plausibility == :likely
  end

  test "single observation cannot be regressed; unknown, not a false claim" do
    r = RegressionToMean.analyze([7], %{mean: 5, std: 1})
    assert r.rtm_plausibility == :unknown
  end

  test "report schema contains no causal-claim field" do
    r = RegressionToMean.analyze([10, 6], %{mean: 5, std: 1})
    assert RegressionToMean.causal_claim_free?(r)
  end

  test "chronological map input is unwrapped in time order" do
    r = RegressionToMean.analyze(%{t1: 3, t2: 10, t3: 6}, %{mean: 5, std: 1})
    assert List.first(r.observations) == 3
    assert r.initial_value == 3
  end
end