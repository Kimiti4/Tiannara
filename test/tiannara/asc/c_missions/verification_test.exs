defmodule Tiannara.ASC.CMissions.VerificationTest do
  use ExUnit.Case, async: false

  alias Tiannara.ASC.CMissions.Verification

  defp stats(overrides \\ %{}) do
    Map.merge(
      %{
        ci_95_low: 0.20,
        ci_95_high: 0.35,
        memory_baseline_median_mb: 50.0,
        memory_candidate_median_mb: 50.0
      },
      overrides
    )
  end

  describe "decide/1 (pre-registered decision rule)" do
    test "ROBUST_PASS when CI lower bound >= 15%" do
      assert Verification.decide(stats(%{ci_95_low: 0.15})) == :ROBUST_PASS
    end

    test "INSUFFICIENT_EVIDENCE when CI straddles 15%" do
      assert Verification.decide(stats(%{ci_95_low: 0.10, ci_95_high: 0.20})) ==
               :INSUFFICIENT_EVIDENCE
    end

    test "FAIL_BELOW_GATE when CI upper bound < 15%" do
      assert Verification.decide(stats(%{ci_95_low: 0.02, ci_95_high: 0.12})) ==
               :FAIL_BELOW_GATE
    end

    test "FAIL_MEMORY overrides latency outcomes" do
      assert Verification.decide(
               stats(%{ci_95_low: 0.30, ci_95_high: 0.40, memory_candidate_median_mb: 53.0})
             ) == :FAIL_MEMORY
    end
  end

  describe "bootstrap_ci/1" do
    test "is deterministic under the fixed seed" do
      deltas = [0.16, 0.18, 0.14, 0.21, 0.17, 0.15, 0.19]
      assert Verification.bootstrap_ci(deltas) == Verification.bootstrap_ci(deltas)
    end

    test "degenerate constant data yields a tight interval" do
      {lo, hi} = Verification.bootstrap_ci([0.25, 0.25, 0.25, 0.25])
      assert lo == 0.25 and hi == 0.25
    end
  end
end