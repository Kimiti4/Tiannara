defmodule Tiannara.ASC.CMissions.StatsTest do
  use ExUnit.Case, async: true

  alias Tiannara.ASC.CMissions.Stats

  test "decision tiers follow the pre-registered rule" do
    assert Stats.decide(0.30, {0.20, 0.40}, 0.10) == :eligible
    assert Stats.decide(0.05, {-0.05, 0.15}, 0.10) == :insufficient_evidence
    assert Stats.decide(-0.24, {-0.49, -0.19}, 0.10) == :rejected
    # boundary: lower bound exactly at gate is eligible
    assert Stats.decide(0.15, {0.10, 0.20}, 0.10) == :eligible
  end

  test "bootstrap is deterministic under a fixed seed" do
    deltas = [0.1, 0.2, -0.05, 0.3, 0.15, 0.12, 0.18, 0.22, 0.09, 0.11]
    assert Stats.bootstrap_ci(deltas, seed: {1, 2, 3}) == Stats.bootstrap_ci(deltas, seed: {1, 2, 3})
  end

  test "median handles odd and even lengths" do
    assert Stats.median([3, 1, 2]) == 2
    assert Stats.median([4, 1, 3, 2]) == 2.5
  end

  test "rounds_negative counts correctly" do
    assert Stats.rounds_negative([0.1, -0.2, -0.3, 0.0]) == 2
  end
end