defmodule Tiannara.AlertRouterTest do
  use ExUnit.Case, async: true

  alias Tiannara.AlertRouter

  test "route/1 routes critical signal and fires neuron" do
    signal = %{
      civilization_id: "world_testing_crit",
      entropy: 0.12,
      collapse_probability: 0.88,
      state: :collapsed,
      severity: :critical,
      detected_issue: :extinction_risk,
      weight: 0.85,
      strength: 1.0
    }

    assert {:ok, :fast_path, amplified} = AlertRouter.route(signal)
    assert amplified.weight > 0.85
    assert :hot_zone in amplified.tags
    assert amplified.fired == true
  end

  test "route/1 routes low-severity signals without firing" do
    signal = %{
      civilization_id: "world_testing_low",
      entropy: 0.72,
      collapse_probability: 0.12,
      state: :stable,
      severity: :low,
      detected_issue: nil,
      weight: 0.85,
      strength: 1.0
    }

    assert {:ok, :background, amplified} = AlertRouter.route(signal)
    assert amplified.fired == false
  end

  test "context multipliers are calculated correctly" do
    # collapse_prob > 0.7 gives 2.5 context multiplier
    signal1 = %{collapse_probability: 0.90, strength: 1.0, weight: 1.0}
    amplified1 = AlertRouter.amplify(signal1)
    # decay_factor is 0.88, context is 2.5, base=1.0, weight=1.5 (because collapse_prob > 0.7)
    # 1.0 * 1.5 * 2.5 * 0.88 = 3.3
    assert amplified1.fired == true

    # state stable gives 0.5 context multiplier
    signal2 = %{state: :stable, strength: 1.0, weight: 0.85}
    amplified2 = AlertRouter.amplify(signal2)
    # 1.0 * 0.85 * 0.5 * 0.88 = 0.374 (< 0.7)
    assert amplified2.fired == false
  end
end
