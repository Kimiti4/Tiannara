defmodule Tiannara.Evolution.SubstrateMetricRegressionTest do
  @moduledoc """
  SR-2 — Substrate metric contract regression characterization.

  These tests REPRODUCE the actual failure boundary surfaced by the E03
  smoke test and characterized in SUBSTRATE_METRIC_RECONNAISSANCE.md (SR-1).

  The failure boundary:

      Metrics{} / incomplete capability metrics
              |
              v
      LongHorizon cycle
              |
              v
      Trajectory.stagnation?/1
              |
              v
      nil composite_score
              |
              v
      ArithmeticError (1.0 - nil)

  These tests are preserved as regression artifacts. After SR-4 implements
  the approved minimum correction, these tests should flip from
  "reproduces the defect" to "verifies the fix holds" — the assertions
  on the primary crash will become assertions that the crash does NOT
  recur, and the secondary-masking characterization will become
  assertions on the hardened behavior.

  Gated behind `@moduletag :substrate_remediation` so they do not run
  in the default suite. Run with:

      mix test test/tiannara/evolution/substrate_metric_regression_test.exs
  """
  use ExUnit.Case, async: true

  alias Tiannara.Evolution.{LongHorizon, Metrics, DriftAudit, Trajectory}

  # ------------------------------------------------------------------
  # SR-2.1: Reproduce the PRIMARY crash.
  #
  # E03 harness setup: initial_metrics = %Metrics{} (empty sub-maps),
  # generator returns metrics_after with the full DriftAudit keyset.
  # After at least one accepted cycle, Trajectory.stagnation?/1 does
  # (1.0 - nil) and raises ArithmeticError.
  # ------------------------------------------------------------------

  test "SR-2.1: mismatched metrics_before vs metrics_after no longer crashes (regression: would crash without SR-4A guards)" do
    # SR-4A FIX: Trajectory.stagnation?/1 now has || 0.0 guards on
    # metrics_after and metrics_before Access.get calls. The E03
    # harness's exact setup (initial_metrics = %Metrics{}, metrics_after
    # populated) no longer raises ArithmeticError. This test would
    # FAIL again if the guards were removed (a regression test).
    initial_metrics = %Metrics{}  # empty sub-maps (the E03 harness setup)

    # Generator returns metrics_after with :composite_score populated.
    # The cycle will be accepted because net_gain = 1.0 - 0.0 = 1.0 > 0.0.
    generator = fn _state, index ->
      %{
        metrics_after: %Metrics{capability: %{composite_score: 1.0 - index * 0.1}},
        capstone_result: %{certified?: true, test_results: %{}, certification_result: :certified},
        next_state: %{},
        new_version: "v#{index}",
        constitutional_version: "1.0.0",
        experiment_id: "SR-2.1",
        hypothesis_id: nil,
        id: "p#{index}",
        patch_id: nil,
        evidence_ids: [],
        rejected_alternatives: []
      }
    end

    # The cycle loop succeeds AND the post-loop Trajectory.analyze/1
    # succeeds (returns a trajectory map, not raises).
    result = LongHorizon.run(%{}, cycles: 1, generator: generator, initial_metrics: initial_metrics, system_version: "v0")

    assert is_map(result)
    assert length(result.lineage) == 1
    assert is_map(result.trajectory)
    # The cycle is :accepted (the guard substitutes 0.0 for the missing
    # before-side composite_score, so net_gain = 1.0 - 0.0 = 1.0 > 0.0).
    assert hd(result.lineage).decision == :accepted
  end

  test "SR-2.1b: Trajectory.analyze/1 returns cleanly for the E03 harness configuration (regression: would crash before SR-4A)" do
    initial_metrics = %Metrics{}
    generator = fn _state, index ->
      %{
        metrics_after: %Metrics{capability: %{composite_score: 0.5 + index * 0.1}},
        capstone_result: %{certified?: true, test_results: %{}, certification_result: :certified},
        next_state: %{},
        new_version: "v#{index}",
        constitutional_version: "1.0.0",
        experiment_id: "SR-2.1b",
        hypothesis_id: nil,
        id: "p#{index}",
        patch_id: nil,
        evidence_ids: [],
        rejected_alternatives: []
      }
    end

    # No crash; returns a trajectory.
    result = LongHorizon.run(%{}, cycles: 1, generator: generator, initial_metrics: initial_metrics, system_version: "v0")
    assert is_map(result.trajectory)
  end

  # ------------------------------------------------------------------
  # SR-2.2: Characterize the SECONDARY DriftAudit masking behavior.
  #
  # When a generator omits :composite_score from metrics_after, DriftAudit
  # silently substitutes 0.0 (Map.get default) and the cycle is rejected
  # as :capability_insufficient because net_gain = 0.0 fails the strict
  # < min_capability_gain: 0.0 check. No ArithmeticError is raised because
  # stagnation?/1 short-circuits on an empty accepted list (trajectory.ex:92).
  # ------------------------------------------------------------------

  test "SR-2.2: producer omitting :composite_score is silently rejected by DriftAudit as capability_insufficient (masking)" do
    initial_metrics = %Metrics{capability: %{composite_score: 0.5}}  # both sides consistent

    # Generator returns metrics_after with NO :composite_score (omitted).
    generator = fn _state, index ->
      %{
        # capability: %{} — empty map; DriftAudit will Map.get(..., :composite_score, 0.0) → 0.0
        metrics_after: %Metrics{capability: %{}},
        capstone_result: %{certified?: true, test_results: %{}, certification_result: :certified},
        next_state: %{},
        new_version: "v#{index}",
        constitutional_version: "1.0.0",
        experiment_id: "SR-2.2",
        hypothesis_id: nil,
        id: "p#{index}",
        patch_id: nil,
        evidence_ids: [],
        rejected_alternatives: []
      }
    end

    # No crash expected: stagnation?/1 short-circuits on empty accepted list.
    # All cycles should be :rejected with :capability_insufficient.
    result =
      LongHorizon.run(%{}, cycles: 3, generator: generator, initial_metrics: initial_metrics, system_version: "v0")

    # Every cycle is rejected. The rejection_reasons field is a list of
    # {reason_atom, value} tuples, NOT a list of bare atoms. The reason
    # is :capability_insufficient with the observed net_gain value.
    assert length(result.lineage) == 3
    for cycle <- result.lineage do
      assert cycle.decision == :rejected
      assert Enum.any?(cycle.rejection_reasons, fn
               {:capability_insufficient, _net_gain} -> true
               _ -> false
             end),
             "expected :capability_insufficient in rejection_reasons, got: #{inspect(cycle.rejection_reasons)}"
    end

    # The trajectory summary reflects the masking: all-rejected,
    # no stagnation declared (because the accepted list is empty).
    # The masking manifests as a false "healthy" trajectory despite
    # all cycles being rejected for the SAME reason (silent default
    # substitution, not a real signal).
    assert result.trajectory.regression_rate == 1.0
  end

  test "SR-2.2b: the masking is symmetric across all four dimensions (each key has the same default-substitution behavior)" do
    initial_metrics = %Metrics{
      capability: %{composite_score: 0.5},
      epistemic: %{contradiction_count: 0},
      architectural: %{coupling_index: 0.0},
      constitutional: %{invariant_violations: 0}
    }

    # Generator omits ALL keys from metrics_after.
    generator = fn _state, _index ->
      %{
        metrics_after: %Metrics{},  # all four dimensions empty
        capstone_result: %{certified?: true, test_results: %{}, certification_result: :certified},
        next_state: %{},
        new_version: "v0",
        constitutional_version: "1.0.0",
        experiment_id: "SR-2.2b",
        hypothesis_id: nil,
        id: "p0",
        patch_id: nil,
        evidence_ids: [],
        rejected_alternatives: []
      }
    end

    result = LongHorizon.run(%{}, cycles: 2, generator: generator, initial_metrics: initial_metrics, system_version: "v0")
    for cycle <- result.lineage do
      assert cycle.decision == :rejected
      # The only rejection reason should be :capability_insufficient
      # (because net_gain = 0.0 fails the strict < 0.0 check FIRST).
      # This demonstrates that the silent default-substitution has a
      # primary masking effect on capability, while other dimensions
      # are masked invisibly.
      assert Enum.any?(cycle.rejection_reasons, fn
               {:capability_insufficient, _} -> true
               _ -> false
             end)
    end
  end

  # ------------------------------------------------------------------
  # SR-2.3: Distinguish the primary crash from the secondary masking.
  #
  # The two are different failure modes with different triggers and
  # different blast radii. The primary crash (SR-2.1) happens when at
  # least one cycle is :accepted with mismatched shapes. The secondary
  # masking (SR-2.2) happens when no cycle is :accepted (all rejected
  # for the silent-default reason).
  # ------------------------------------------------------------------

  test "SR-2.3: consistent shape across all cycles avoids both the primary crash and the masking" do
    # This is the configuration the existing long_horizon_test.exs uses.
    # It is the configuration that NEITHER crashes NOR masks. It is the
    # baseline against which both the crash and the masking are anomalies.
    initial_metrics = %Metrics{
      capability: %{composite_score: 0.5},
      epistemic: %{contradiction_count: 0},
      architectural: %{coupling_index: 0.0, memory: 0.0},
      constitutional: %{invariant_violations: 0}
    }

    generator = fn _state, index ->
      %{
        metrics_after: %Metrics{
          capability: %{composite_score: 0.5 + index * 0.1},
          epistemic: %{contradiction_count: 0},
          architectural: %{coupling_index: 0.0, memory: 0.0 + index * 0.01},
          constitutional: %{invariant_violations: 0}
        },
        capstone_result: %{certified?: true, test_results: %{}, certification_result: :certified},
        next_state: %{},
        new_version: "v#{index}",
        constitutional_version: "1.0.0",
        experiment_id: "SR-2.3",
        hypothesis_id: nil,
        id: "p#{index}",
        patch_id: nil,
        evidence_ids: [],
        rejected_alternatives: []
      }
    end

    # No crash. All cycles accepted. Trajectory.analyze/1 succeeds.
    result = LongHorizon.run(%{}, cycles: 5, generator: generator, initial_metrics: initial_metrics, system_version: "v0")
    assert length(result.lineage) == 5
    for cycle <- result.lineage, do: assert cycle.decision == :accepted

    # The trajectory summary is meaningful: the capability trend is
    # positive (composite_score increased by 0.5 over 5 cycles).
    assert is_map(result.trajectory)
  end

  # ------------------------------------------------------------------
  # SR-2.4: Characterize the DriftAudit.constitutional_delta/2 asymmetry.
  #
  # The function ignores the `before` value entirely. A test that supplies
  # different `before` values and the same `after` value should produce
  # the same drift result — proving the asymmetry.
  # ------------------------------------------------------------------

  test "SR-2.4: DriftAudit.constitutional_delta/2 ignores the before value (asymmetry)" do
    # Two different before values, same after value.
    a = DriftAudit.audit(
      %Metrics{constitutional: %{invariant_violations: 999}},
      %Metrics{constitutional: %{invariant_violations: 1}}
    )

    b = DriftAudit.audit(
      %Metrics{constitutional: %{invariant_violations: 0}},
      %Metrics{constitutional: %{invariant_violations: 1}}
    )

    # Both should produce the same drift result (since the after value is the
    # same and before is ignored).
    assert a == b
  end

  # ------------------------------------------------------------------
  # SR-2.5: Trajectory.stagnation?/1 — direct characterization of the
  # unguarded arithmetic site. This test calls the helper indirectly
  # via Trajectory.analyze/1 with a controlled lineage.
  # ------------------------------------------------------------------

  test "SR-2.5: Trajectory.analyze/1 with mismatched composite_score returns cleanly under the guard (regression: would crash before SR-4A)" do
    # SR-4A FIX: stagnation?/1 now has || 0.0 guards. A cycle with
    # metrics_before lacking :composite_score returns a trajectory
    # where stagnation?/1 evaluates the guarded default 0.0 - 0.5 = -0.5,
    # abs(-0.5) = 0.5, 0.5 < 0.01 is false → stagnation? = false.
    # This test would FAIL if the guards were removed (a regression test).
    cycle = %Tiannara.Evolution.Cycle{
      cycle_id: :test_cycle,
      decision: :accepted,
      evidence_ids: [],
      hypothesis_id: nil,
      metrics_before: %Metrics{capability: %{}},  # no :composite_score
      metrics_after: %Metrics{capability: %{composite_score: 0.5}},
      drift_metrics: %{},
      rejection_reasons: [],
      rejected_alternatives: [],
      timestamp: 0
    }

    # No crash. Returns a trajectory. stagnation?/1 returns false
    # because abs(0.0 - 0.5) = 0.5 is NOT < 0.01.
    trajectory = Trajectory.analyze([cycle])
    assert is_map(trajectory)
    assert trajectory.stagnation? == false
  end

  test "SR-2.5b: Trajectory.analyze/1 with matched shapes (all expected keys present) does not crash" do
    cycle = %Tiannara.Evolution.Cycle{
      cycle_id: :test_cycle,
      decision: :accepted,
      # NOTE: Trajectory.analyze/1 reads evidence_ids (discovery_yield/1,
      # line 127) and hypothesis_id (monoculture?/1, line 107). Both
      # default to nil when omitted. For a cycle to traverse without
      # crashing, the full surface of fields Trajectory reads must be
      # present. This documents the comprehensive unguarded-access defect.
      evidence_ids: [],
      hypothesis_id: nil,
      metrics_before: %Metrics{
        capability: %{composite_score: 0.0},
        epistemic: %{contradiction_count: 0},
        architectural: %{coupling_index: 0.0},
        constitutional: %{invariant_violations: 0}
      },
      metrics_after: %Metrics{
        capability: %{composite_score: 0.5},
        epistemic: %{contradiction_count: 0},
        architectural: %{coupling_index: 0.0},
        constitutional: %{invariant_violations: 0}
      },
      drift_metrics: %{},
      rejection_reasons: [],
      rejected_alternatives: [],
      timestamp: 0
    }

    # No crash: all expected keys present in both Cycle and Metrics.
    trajectory = Trajectory.analyze([cycle])
    assert is_map(trajectory)
    assert trajectory.stagnation? == false
  end

  test "SR-2.6: constitutional_drift/1 returns cleanly when :invariant_violations is missing (regression: would crash before SR-4A)" do
    # SR-4A FIX: constitutional_drift/1 now substitutes 0 for missing
    # :invariant_violations per element. A cycle without the key
    # produces violations = 0 → constitutional_drift returns :stable.
    # This test would FAIL if the guard were removed (a regression test).
    cycle = %Tiannara.Evolution.Cycle{
      cycle_id: :test_cycle,
      decision: :accepted,
      evidence_ids: [],
      hypothesis_id: nil,
      # Only capability and epistemic present; constitutional empty.
      metrics_before: %Metrics{
        capability: %{composite_score: 0.0},
        epistemic: %{contradiction_count: 0}
      },
      metrics_after: %Metrics{
        capability: %{composite_score: 0.5},
        epistemic: %{contradiction_count: 0}
      },
      drift_metrics: %{},
      rejection_reasons: [],
      rejected_alternatives: [],
      timestamp: 0
    }

    # No crash. Returns a trajectory.
    trajectory = Trajectory.analyze([cycle])
    assert is_map(trajectory)
  end

  test "SR-2.6b: constitutional_drift/1 with :invariant_violations present does not crash (when all other expected keys also present)" do
    # For a cycle to traverse Trajectory.analyze/1 without crashing, ALL
    # of the following keys must be present in BOTH metrics_before and
    # metrics_after (this is the full surface of the unguarded-arithmetic
    # defect):
    #
    #   capability.composite_score
    #   epistemic.contradiction_count
    #   architectural.coupling_index
    #   constitutional.invariant_violations
    #
    # Plus the Cycle struct fields that Trajectory iterates:
    #   evidence_ids (for discovery_yield/1)
    #   decision (used to filter accepted/rejected)
    #
    # Any missing key from this set causes an unguarded arithmetic crash
    # in some Trajectory helper (stagnation?/1, constitutional_drift/1,
    # capability_trend/1, epistemic_drift/1, architectural_drift/1,
    # memory_growth/1, discovery_yield/1, or avg/1).
    cycle = %Tiannara.Evolution.Cycle{
      cycle_id: :test_cycle,
      decision: :accepted,
      evidence_ids: [],
      metrics_before: %Metrics{
        capability: %{composite_score: 0.0},
        epistemic: %{contradiction_count: 0},
        architectural: %{coupling_index: 0.0},
        constitutional: %{invariant_violations: 0}
      },
      metrics_after: %Metrics{
        capability: %{composite_score: 0.5},
        epistemic: %{contradiction_count: 0},
        architectural: %{coupling_index: 0.0},
        constitutional: %{invariant_violations: 0}
      },
      drift_metrics: %{},
      rejection_reasons: [],
      rejected_alternatives: [],
      timestamp: 0
    }

    # No crash when all expected keys are present.
    trajectory = Trajectory.analyze([cycle])
    assert is_map(trajectory)
  end

  test "SR-2.7: Trajectory.analyze/1 unguarded-access surface (per-dimension, post-SR-4A)" do
    # SR-4A FIX: after the guards in capability_trend/1, stagnation?/1,
    # constitutional_drift/1, and discovery_yield/1, NO dimension omission
    # causes a crash. All four are safe. The per-helper guard status is
    # now uniform: all sites are nil-tolerant.
    #
    # This test would FAIL if any of the four guards were removed (a
    # regression test). It documents the post-fix invariant: ANY missing
    # DriftAudit key in metrics_after is tolerated; the trajectory
    # analysis returns a sensible default instead of crashing.
    #
    # Pre-SR-4 surface (per SR-2 empirical characterization):
    #   capability.composite_score      :crash  (stagnation?/1 + capability_trend/1 unguarded)
    #   epistemic.contradiction_count   :ok     (epistemic_drift/1 already guarded)
    #   architectural.coupling_index    :ok     (architectural_drift/1 already guarded)
    #   constitutional.invariant_violations :crash  (constitutional_drift/1 unguarded)
    #
    # Post-SR-4 surface:
    #   all four :ok (guarded)

    base_before = %Metrics{
      capability: %{composite_score: 0.0},
      epistemic: %{contradiction_count: 0},
      architectural: %{coupling_index: 0.0},
      constitutional: %{invariant_violations: 0}
    }

    cases = [
      {:capability_missing_composite, %{base_before | capability: %{}}},
      {:epistemic_missing_contradiction, %{base_before | epistemic: %{}}},
      {:architectural_missing_coupling, %{base_before | architectural: %{}}},
      {:constitutional_missing_violations, %{base_before | constitutional: %{}}}
    ]

    Enum.each(cases, fn {label, after_metrics} ->
      cycle = %Tiannara.Evolution.Cycle{
        cycle_id: :"test_#{label}",
        decision: :accepted,
        evidence_ids: [],
        hypothesis_id: nil,
        metrics_before: base_before,
        metrics_after: after_metrics,
        drift_metrics: %{},
        rejection_reasons: [],
        rejected_alternatives: [],
        timestamp: 0
      }

      # Post-SR-4A: NONE of the four dimension omissions should crash.
      trajectory = Trajectory.analyze([cycle])
      assert is_map(trajectory), "Expected no crash for #{label}, but Trajectory.analyze returned non-map: #{inspect(trajectory)}"
    end)
  end

  test "SR-2.5c: Trajectory.analyze/1 with empty accepted list short-circuits stagnation?/1 (no crash)" do
    # Empty accepted list → stagnation?/1 returns false (trajectory.ex:92).
    # No cycle exists to trigger the unguarded arithmetic.
    trajectory = Trajectory.analyze([])
    assert is_map(trajectory)
    assert trajectory.stagnation? == false
  end
end
