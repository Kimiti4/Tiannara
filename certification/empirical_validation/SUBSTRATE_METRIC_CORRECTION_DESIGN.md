# Substrate Remediation SR-3 — Minimum-Correction Design (NO IMPLEMENTATION)

**Mission:** TIANNARA EMPIRICAL VALIDATION — Substrate Remediation Investigation
**Date:** 2026-09-03 · **HEAD:** `3bd1601b9bb3c718f985d44ceaa8ef2e638d4ec6`
**Status:** DESIGN ONLY. No code modified. E03 remains BLOCKED at 0 runs.

This document evaluates the three remediation candidates (A, B, C) and establishes whether **A+C** is truly the minimum sufficient correction, rather than assuming it. The evaluation uses the evidence from SR-1 (reconnaissance) and SR-2 (regression characterization) and addresses the 12 properties mandated by the Council.

---

## 0. The defect (recap from SR-1 + SR-2)

The evolution substrate's `Trajectory.analyze/1` has **unguarded nil arithmetic** at multiple sites. `DriftAudit` silently substitutes defaults for missing keys, masking producer-side contract violations during the loop. The crash surface is **per-helper** (not uniform): capability and constitutional are unguarded; epistemic and architectural coupling_index already have `|| 0` guards. The long_horizon test file is gated out of the default suite, so this class of defect was never caught.

**Proven by SR-2 regression tests** (`test/tiannara/evolution/substrate_metric_regression_test.exs`, 12/12 PASS):
- SR-2.1/2.1b: primary crash reproduced end-to-end via `LongHorizon.run/2`.
- SR-2.2/2.2b: secondary masking (all-rejected silent default substitution) reproduced.
- SR-2.3: consistent shape avoids both defects (baseline).
- SR-2.4: `DriftAudit.constitutional_delta/2` ignores `before` (asymmetry).
- SR-2.5/2.5b/2.5c: direct `Trajectory.analyze/1` reproduction with/without key.
- SR-2.6/2.6b: second unguarded site (`constitutional_drift/1`) reproduced.
- SR-2.7: per-dimension crash surface empirically mapped (capability and constitutional crash; epistemic and architectural do not).

---

## 1. Canonical `%Tiannara.Evolution.Metrics{}` contract (Property 1)

**Canonical shape (from `lib/tiannara/evolution/metrics.ex`):**

```elixir
defstruct capability: %{}, epistemic: %{}, architectural: %{}, constitutional: %{}
```

**Canonical keyset (from `lib/tiannara/evolution/drift_audit.ex:89-111` and `lib/tiannara/evolution/trajectory.ex:44,61,62,74,75,84,99,100,133,146,147`):**

| Dimension | Key | Expected type | Producer | Consumer |
|---|---|---|---|---|
| `capability` | `composite_score` | number | DriftAudit `Map.get(_, :composite_score, 0.0)` reads it | Trajectory `stagnation?/1`, `capability_trend/1`, `proposal_quality/1` |
| `epistemic` | `contradiction_count` | integer | DriftAudit `Map.get(_, :contradiction_count, 0)` | Trajectory `epistemic_drift/1` |
| `architectural` | `coupling_index` | number | DriftAudit `Map.get(_, :coupling_index, 0.0)` | Trajectory `architectural_drift/1`, `memory_growth/1` (reads `:memory` separately) |
| `constitutional` | `invariant_violations` | integer | DriftAudit `Map.get(_, :invariant_violations, 0)` | Trajectory `constitutional_drift/1` |

The canonical contract is: **map shape with these four named keys per dimension**. DriftAudit's contract is enforced (via `Map.get` with default); Trajectory's contract is **partially enforced** (two of four dimensions are unguarded). The struct's `defstruct` defaults do not encode the inner keyset; the contract is implicit in the DriftAudit source.

**This document will recommend making the contract explicit** by adding `@type dimension :: %{...}` to `metrics.ex` as part of Option A.

---

## 2. Exact producer/consumer boundary (Property 2)

| Layer | Module | Role | What it reads | What it writes |
|---|---|---|---|---|
| Producer (loop) | `LongHorizon.run/2` (generator) | writes `metrics_after` on each Cycle | DriftAudit consumes | `%Cycle{metrics_after: ...}` |
| Consumer (loop) | `DriftAudit.audit/2` | computes drift, decides accept/reject | `metrics_before`, `metrics_after` (maps) | drift map + accept/reject |
| Consumer (post-loop) | `Trajectory.analyze/1` | aggregates trajectory summary | `metrics_before`, `metrics_after` (maps) + Cycle fields | trajectory map |

**Affected boundary:** `Trajectory.analyze/1` (consumer, post-loop) and `DriftAudit.audit/2` (consumer, in-loop). The producer is the `generator` function injected into `LongHorizon.run/2`. In the E03 harness, the producer is `Tiannara.EmpiricalValidation.E03.Harness.metrics_from_ecology/1`.

**No external module outside `lib/tiannara/evolution/*` and the E03 harness constructs or consumes `%Metrics{}`.** The substrate boundary is clean (SR-1 §3.3).

---

## 3. Candidate A: `Trajectory` nil guards (required candidate)

**Description:** Add `|| 0.0` / `|| 0` / `|| []` guards to the unguarded arithmetic sites in `Trajectory.analyze/1` and its helpers, matching the pattern already used at `epistemic_drift/1:61-62`, `architectural_drift/1:74-75`, and `memory_growth/1:146-147`.

**Property 3: Why A preserves the existing public shape and semantics.**

The public shape of `Trajectory.analyze/1` (input: list of `%Cycle{}`, output: trajectory map) is unchanged. The public shape of `%Metrics{}` and `%Cycle{}` is unchanged. The DriftAudit interface is unchanged. The fix adds defensive handling for missing keys in a way that is **consistent with the existing pattern** in the same module (the other helpers already have `|| 0` / `|| 0.0` guards). The change is **purely a robustness improvement** that makes Trajectory tolerant of partial metrics. It does not change any return value when all keys are present; it only changes behavior when keys are missing (returning a sensible default instead of crashing).

**Property 4: What A does when a metric is absent.**

| Helper | Unguarded access | Guard added | Effect when key missing |
|---|---|---|---|
| `stagnation?/1:99-100` | `c.metrics_after.capability[:composite_score] - c.metrics_before.capability[:composite_score]` | `(... || 0.0) - (... || 0.0)` | gain = 0.0; `abs(0.0) < 0.01` is true (stagnation declared) |
| `constitutional_drift/1:84-85` | `Enum.map(accepted, & &1.metrics_after.constitutional[:invariant_violations]) |> Enum.sum()` | `... || 0` per element | violations sum = 0 |
| `capability_trend/1:50` → `avg/1:186` | `Enum.sum(list) / length(list)` where list contains `nil` from missing `:composite_score` | guard the Access.get in capability_trend (or add a `nil_filter/1` helper) | missing values excluded from average; if list is empty after filtering, avg returns 0.0 (the existing `defp avg([]), do: 0.0`) |
| `discovery_yield/1:127` | `length(c.evidence_ids)` | `length(c.evidence_ids \|\| [])` | length 0 |

For the `:nil` guards specifically, the convention is: a missing key in a `:accepted` cycle is treated as the default (0.0 or 0). A missing key does **not** retroactively reclassify the cycle as `:rejected`; it is treated as an incomplete measurement.

**Is Option A truly the minimum?**

A modifies **only `lib/tiannara/evolution/trajectory.ex`** (and optionally `metrics.ex` for the explicit type). DriftAudit is not touched. The Metrics struct is not touched. The Cycle struct is not touched. The LongHorizon loop is not touched. The producer contract is not changed. Existing tests (which use map shapes with all keys present) continue to pass without modification. The fix is additive (guards) and locally contained.

**Yes — A is the minimum possible correction that closes the crash surface.** Without A, Trajectory continues to crash on missing keys. Without A, no amount of B or C can prevent the crash. A is **necessary** for E03 to run.

**Is A alone sufficient to unblock E03?**

With A applied, the E03 harness's `metrics_from_ecology/1` (which currently provides `capability.composite_score`, `epistemic.contradiction_count`, `architectural.coupling_index`, `constitutional.invariant_violations`) and its `initial_metrics = %Metrics{}` (which provides none of these) will produce:

- **Cycle 1** with `metrics_before = %Metrics{}` (no keys) and `metrics_after = %Metrics{capability: %{composite_score: 1.0 - dominance}, ...}` (all keys). With A's guards, the unguarded arithmetic sites return defaults instead of crashing. The cycle is `:accepted` (net_gain = 1.0 - 0.0 = 1.0). `stagnation?/1` sees 1.0 - 0.0 = 1.0, not 0.0.

So **A alone IS sufficient to unblock the E03 smoke test.** The trajectory analysis will succeed; the summary will be computed.

**Subtotal: A is necessary and sufficient for unblocking E03. It is the minimum unblock.**

---

## 4. Candidate B: `DriftAudit` incomplete-metric rejection (recommended secondary)

**Description:** When `DriftAudit._delta/2` substitutes a default because the key was missing, add a `{:metric_incomplete, :dimension}` reason to the rejection list. This surfaces producer-side contract violations during the loop instead of masking them as silent `net_gain = 0.0 → capability_insufficient` rejections.

**Property 5: Whether B changes behavior for previously tolerated incomplete metrics.**

Today, a generator that omits `:composite_score` produces `net_gain = 0.0` (from defaults), which fails the strict `< min_capability_gain: 0.0` check at `drift_audit.ex:64`. The cycle is rejected with reason `{:capability_insufficient, 0.0}`. This is **already a rejection** — the loop does not silently accept the proposal. The masking is that the rejection is attributed to "capability insufficient" rather than "incomplete metric"; the rejection reason does not distinguish between "capability actually insufficient" and "capability key missing."

B would change the rejection reason from `{:capability_insufficient, 0.0}` to `{:metric_incomplete, :capability}` (or add the latter alongside). For a previously-accepted cycle (none today, because any missing key triggers the strict `< 0.0` rejection), B would not change behavior. For a previously-rejected cycle with missing key, B changes the rejection reason but not the decision (still rejected).

**Therefore B is NOT a behavioral change for any cycle whose decision was previously `:accepted`. It is purely an observability improvement for the rejection reason.** This is bounded and safe.

**Property 6: Whether B is therefore a semantic change rather than merely observability hardening.**

B is **observability hardening**, not a semantic change. The cycle decision logic (accept vs reject) is unchanged. The threshold values are unchanged. The drift computation is unchanged. The only thing that changes is the rejection reason's structure: it now distinguishes "metric was missing" from "metric was present and computed to an insufficient value." This distinction is **information-preserving** — it surfaces a contract violation that was previously silent. It does not change which cycles are accepted or rejected.

**Is B necessary for unblocking E03?**

B does not change the E03 cycle decisions (the E03 harness's `metrics_from_ecology/1` provides all four DriftAudit keys in `metrics_after`; `initial_metrics = %Metrics{}` is empty in `metrics_before`, so `net_gain` uses defaults — but the `net_gain` is positive because `metrics_after.composite_score` is 1.0 - 0.0 = 1.0 > 0.0, and 1.0 > min_capability_gain = 0.0). With B applied, the E03 cycle is still accepted (decision unchanged); the reason is unchanged because the rejection didn't happen.

**B is NOT necessary to unblock E03.** B is a secondary hardening that surfaces the masking behavior. It is valuable for scientific rigor (the E03 preregistration §9.4 records "stabilizer pressure" and "intervention magnitude" — if a generator omits keys, B would record that explicitly) but is not on the unblock path.

**Subtotal: B is valuable but not necessary. It is observability hardening, not a semantic change.**

---

## 5. Candidate C: test-coverage (remove/wire long_horizon_evolution gating)

**Description:** `test/tiannara/evolution/long_horizon_test.exs:6` carries `@moduletag :long_horizon_evolution`, which excludes it from the default `mix test` suite. Option C removes this moduletag (or wires `--include long_horizon_evolution` into CI), so the DriftAudit→Trajectory pipeline is exercised in every test run.

**Property 7: Whether C changes only test coverage or alters CI execution time/behavior.**

C changes **test coverage only**. It does not alter any substrate behavior, any production code, any metric semantics, or any preregistered measurement. The only effect is that `long_horizon_test.exs` runs in the default suite instead of only on demand. This increases CI execution time by however long `long_horizon_test.exs` takes (estimated <1s based on the existing `mix test` outputs). It does not change behavior of any other test or any production code.

Additionally, C should also un-gate `test/tiannara/evolution/horizon_harness_test.exs:6` which carries `@moduletag :omega_horizon`. This test exercises `Harness.run_cycles/3` but does NOT call `Trajectory.analyze/1`, so it would not catch the unguarded-arithmetic defect — but it would catch other Harness-related issues. Both moduletag removals are in scope for C.

**Is C necessary for unblocking E03?**

C is not necessary for the E03 crash itself (A closes the crash). C is necessary for **preventing regression** of the defect. Without C, a future change to Trajectory could re-introduce the unguarded arithmetic, and the default test suite would not catch it. With C, any future regression is caught in the default suite.

**Subtotal: C is necessary for regression prevention but not for unblocking. It is a test-infrastructure change only.**

---

## 6. Is A+C truly the minimum sufficient correction? (Council question)

**Yes, A+C is the minimum sufficient correction, and the Council's framing is correct. Here is the proof:**

**Necessary for unblock:** A is necessary and sufficient to close the crash. Without A, no amount of B or C can prevent `Trajectory.analyze/1` from crashing on missing keys.

**Sufficient for unblock:** A alone is sufficient. The E03 harness's metrics projection (`metrics_from_ecology/1` providing `capability.composite_score`, etc.) means that with A applied, the E03 smoke test will succeed end-to-end.

**Necessary for regression prevention:** C is necessary to prevent future regression. Without C, a future change to `Trajectory` could re-introduce the unguarded arithmetic and the default test suite would not catch it. With C, the existing `long_horizon_test.exs` runs in the default suite and any regression in Trajectory is caught immediately.

**NOT necessary for unblock or regression prevention:** B is not on the unblock path. B is a secondary hardening that surfaces a masking behavior. B can be added later as a separate, scoped change without affecting E03 or the A+C unblock.

**A+C together:**
- A is 1 file modified (optionally 2 if `metrics.ex` gets an explicit `@type`).
- C is test-infrastructure: 2 moduletag removals, no production code change.
- Total substrate change: 1–2 files in `lib/tiannara/evolution/`, 2 moduletag removals in `test/tiannara/evolution/`.
- No new architecture. No new tests beyond what SR-2 already provides. No new types beyond the optional `@type` in `metrics.ex`.

**B is recommended but not bundled:**
- B requires careful design (what does "incomplete metric" mean as a rejection reason; how does it interact with the existing four rejection reasons; does it require a new threshold for "incompleteness"?). The Council's instruction is explicit: "B ... must not be silently bundled into A." So B is a separate future work item, not part of the A+C unblock.
- B can be added as a follow-up after E03 is unblocked and the A+C correction is verified.

**Subtotal: A+C is the minimum sufficient correction. B is recommended as a separate, unbundled follow-up.**

---

## 7. Regression tests required for A, B, C (Property 8)

**For A (Trajectory nil guards):**

The existing `test/tiannara/evolution/substrate_metric_regression_test.exs` (12 tests, SR-2) is **already the regression test for A**. After A is applied:
- SR-2.1/2.1b (primary crash) → assertions should flip from "crashes" to "does not crash; trajectory returned."
- SR-2.5 (direct stagnation reproduction) → assertion should flip from "raises ArithmeticError" to "returns a trajectory with stagnation? correctly computed."
- SR-2.6 (constitutional_drift reproduction) → should flip.
- SR-2.7 (per-dimension surface) → all four should now report `:no_crash` (because the guards make all four safe).
- SR-2.5b/2.6b (matched shapes) → continue to pass (the guards don't change behavior when keys are present).
- SR-2.2/2.2b (DriftAudit masking) → unaffected (B is what would change this; A doesn't change DriftAudit).
- SR-2.3 (baseline) → continues to pass.
- SR-2.4 (constitutional asymmetry) → unaffected (A doesn't change DriftAudit).
- SR-2.5c (empty list) → continues to pass.

A adds **0 new tests** because SR-2 already provides them. The SR-2 tests flip from "reproduces defect" to "verifies fix" post-implementation.

**For B (DriftAudit incomplete-metric rejection):**

New tests in `substrate_metric_regression_test.exs` (or a new test file):
- A generator that omits `:composite_score` produces `{:metric_incomplete, :capability}` (not `{:capability_insufficient, 0.0}`).
- A generator that omits `:contradiction_count` produces `{:metric_incomplete, :epistemic}`.
- A generator that omits `:coupling_index` produces `{:metric_incomplete, :architectural}`.
- A generator that omits `:invariant_violations` produces `{:metric_incomplete, :constitutional}`.
- A generator that provides all keys produces no `{:metric_incomplete, _}` reasons.

These tests can be added as part of the B implementation, not now.

**For C (test-coverage):**

No new regression tests. C is itself the act of exposing existing tests to the default suite. The verification of C is:
- `mix test` (without `--include`) runs the un-gated `long_horizon_test.exs` and `horizon_harness_test.exs` without errors.
- The SR-2 regression tests run in the default suite (if their moduletag is also removed; otherwise they are runnable on demand).

**Subtotal: A requires 0 new tests (SR-2 flips). B requires 4–5 new tests. C requires 0 new tests.**

---

## 8. Compatibility impact (Property 9)

**A:** Changes behavior only when `Trajectory.analyze/1` is called with a Cycle whose `metrics_after` or `metrics_before` lacks a DriftAudit key. For all existing cycles that have all four keys (which is the case in `long_horizon_test.exs`, `horizon_harness_test.exs`, and any other production producer), behavior is **unchanged**. The `avg/1` helper at `trajectory.ex:186` already handles `[]` correctly (`defp avg([]), do: 0.0`); the fix to capability_trend is to filter nils before passing to avg. This preserves the existing semantics for matched-shape inputs.

The E03 harness's `metrics_from_ecology/1` provides all four keys in `metrics_after` and no keys in `initial_metrics` (`%Metrics{}`). With A applied, the E03 smoke test will succeed; the cycle will be `:accepted` (net_gain = 1.0); the trajectory summary will be computed with the guarded defaults. This is **not a behavior change for the E03 harness** — it is a behavior fix for the E03 harness (it currently crashes; with A it produces a trajectory).

**B:** Changes rejection reason structure. For any producer that previously triggered `{:capability_insufficient, 0.0}` due to a missing key, the rejection reason becomes `{:metric_incomplete, :capability}`. For any producer that previously triggered `{:capability_insufficient, actual_net_gain}` due to a present-but-insufficient value, the rejection reason is unchanged. This is **a structural change to rejection reasons** but not a behavioral change (decision logic unchanged).

**C:** No compatibility impact. Test-infrastructure only.

**Subtotal: A is behavior-preserving for all matched-shape inputs. B is reason-structure-changing. C is zero-impact.**

---

## 9. Rollback path (Property 10)

**A rollback:** Revert the single file edit in `lib/tiannara/evolution/trajectory.ex`. The SR-2 regression tests will then fail (the crash reproduces), confirming the rollback. No data migration, no state to roll back, no API changes.

**B rollback:** Revert the single file edit in `lib/tiannara/evolution/drift_audit.ex`. The new tests (if added) will fail. Existing tests continue to pass because they use present keys.

**C rollback:** Restore the `@moduletag :long_horizon_evolution` (and `:omega_horizon`) annotations. The default suite is restored to its pre-C behavior. No production code change.

**Subtotal: all three options are individually reversible with single-file changes. The order A → C → B (or A → B → C) does not matter for rollback; any single option can be reverted without affecting the others.**

---

## 10. Verification matrix (Property 11)

| Verification | Pre-A | Post-A | Post-B | Post-C |
|---|---|---|---|---|
| SR-2.1/2.1b (primary crash via LongHorizon) | FAILS (crash) | PASSES (returns trajectory) | PASSES | PASSES |
| SR-2.2/2.2b (DriftAudit masking) | PASSES (rejection_reason = `{:capability_insufficient, 0.0}`) | unchanged (A does not change DriftAudit) | FAILS new assertion (rejection_reason = `{:metric_incomplete, :capability}`) | unchanged |
| SR-2.3 (baseline matched shape) | PASSES | PASSES | PASSES | PASSES |
| SR-2.4 (constitutional asymmetry) | PASSES (asymmetry is real) | unchanged (A does not change DriftAudit) | may change (B could fix asymmetry) | unchanged |
| SR-2.5/2.5b/2.5c (direct Trajectory reproduction) | mixed (2.5/2.5b fail, 2.5c passes) | all pass | all pass | all pass |
| SR-2.6/2.6b (constitutional_drift) | mixed (2.6 fails, 2.6b fails until evidence_ids added) | all pass | all pass | all pass |
| SR-2.7 (per-dimension surface) | 2/4 dimensions crash | 0/4 dimensions crash (all guarded) | 0/4 | 0/4 |
| `mix test test/tiannara/evolution/long_horizon_test.exs` | requires `--include :long_horizon_evolution` | unchanged | unchanged | runs in default suite |
| `mix test test/tiannara/forecasting` (D1–D5 baseline) | 354/0 | 354/0 (A does not touch forecasting) | 354/0 | 354/0 |
| E03_INDEPENDENT_VERIFIER | 24/24 PASS | 24/24 PASS (A does not change E03 verifier inputs) | 24/24 PASS | 24/24 PASS |
| R6 measurement-integrity verifier | 12/12 CERTIFIED | 12/12 (unchanged) | 12/12 | 12/12 |
| D5 facade verdict | `:d5_certified_bounded` | unchanged | unchanged | unchanged |
| E06/E07 FALSIFIED in claim registry | preserved | preserved | preserved | preserved |

**Subtotal: A is verifiable by the existing SR-2 tests (which flip from "reproduces" to "verifies"). B is verifiable by adding 4–5 new tests. C is verifiable by running `mix test` and observing that `long_horizon_test.exs` now executes in the default suite. All three options preserve the D1–D5 / R7 / E06/E07 baseline.**

---

## 11. Explicit proof: E03 is outside the remediation implementation scope (Property 12)

The substrate remediation (A, B, C) modifies:
- `lib/tiannara/evolution/trajectory.ex` (A)
- optionally `lib/tiannara/evolution/metrics.ex` (A, optional `@type` addition)
- `lib/tiannara/evolution/drift_audit.ex` (B, not part of A+C unblock)
- `test/tiannara/evolution/long_horizon_test.exs` and `test/tiannara/evolution/horizon_harness_test.exs` (C, moduletag removal)

The substrate remediation does **not** modify:
- `certification/empirical_validation/E03/E03_PREREGISTRATION.md` (FROZEN)
- `certification/empirical_validation/E03/E03_PARAMETER_MANIFEST.json` (FROZEN)
- `certification/empirical_validation/E03/E03_INDEPENDENT_VERIFIER.py` (unchanged)
- `certification/empirical_validation/E03/E03_VERIFIER_OUTPUT.json` (unchanged — re-run will produce identical PASS/FAIL pattern)
- `certification/empirical_validation/E03/E03_RUN_LEDGER.schema.md` (unchanged — the schema is shape-agnostic; the ledger records whatever Trajectory produces)
- `lib/tiannara/empirical_validation/e03/harness.ex` (unchanged — the E03 harness does not need to change because the substrate's Trajectory is fixed; the harness's metrics projection is already complete)
- `lib/tiannara/forecasting/d5.ex` (D5 frozen)
- `lib/tiannara/forecasting/planner.ex` (R3 remediation frozen)
- `lib/tiannara/evidence/provenance.ex` (R7 boundary frozen)
- `lib/tiannara/forecasting/auditor.ex` (R7 DecisionArchive frozen)
- `lib/tiannara/discovery/engine.ex` (E06 falsification frozen)
- `lib/tiannara/archaeology/archaeology.ex` (E07 falsification frozen)

**The substrate correction is purely an evolution-substrate hardening. It changes no E03 artifact, no E03 protocol, no E03 measurement, no E03 success criterion, and no E03 success/failure gate.** E03's preregistration remains scientifically meaningful exactly as written. The correction simply makes the underlying execution substrate trustworthy enough to faithfully execute the frozen protocol.

**Per the HOLD discipline:** after SR-4 implements A+C, the E03 preregistration does **not** require re-freezing, re-hashing, or fresh independent verification — the protocol is unchanged. However, the E03 INDEPENDENT VERIFIER should be re-run post-implementation to confirm that the pre-registration hash-binding remains intact (no artifact was modified) and that the harness+ledger still satisfy the verifier. If the verifier's gates all pass unchanged, E03 may proceed to the Council execution-authorization gate. If the verifier surfaces any change, that would indicate a substrate correction that exceeded scope, and E03 would require a new protocol revision.

**Subtotal: E03 is provably outside the SR-4 implementation scope. The substrate correction unblocks E03 execution; it does not modify the E03 protocol or any of its artifacts.**

---

## 12. Summary and Council decision matrix

| Option | Files changed | Substrate behavior change | E03 unblock? | E03 protocol change? | Recommendation |
|---|---|---|---|---|---|
| **A** (Trajectory nil guards) | 1 (optionally 2) | nil-guard fix; matched-shape inputs unchanged | **YES** | NO | **ADOPT for SR-4** |
| B (DriftAudit incomplete-metric rejection) | 1 | rejection reason structure change (still rejection, not acceptance) | NO (does not unblock) | NO | DEFER to separate future work; not bundled with A |
| **C** (remove moduletags) | 2 test files | zero (test-infrastructure only) | NO (does not unblock, but prevents regression) | NO | **ADOPT for SR-4** |
| A+B+C | 3 (4 with B) | A's fix + B's hardening + C's coverage | YES | NO | B is unnecessary for unblock; A+C is the minimum |
| A+B (no C) | 2 (3 with B) | A's fix + B's hardening | YES | NO | C is needed for regression prevention; don't ship without it |
| A only (no C) | 1 (optionally 2) | A's fix only | YES | NO | Lacks regression prevention; a future Trajectory change could re-introduce the defect |
| C only (no A) | 2 test files | test coverage only | NO (Trajectory still crashes) | NO | Does not unblock; not a viable unblock path |
| B only (no A) | 1 | rejection reason change | NO | NO | Does not unblock; not a viable unblock path |

**Recommended for SR-4 implementation: A + C.** B is deferred to a separate, future work item after E03 is unblocked and the A+C correction is verified.

---

## 13. SR-4 implementation proposal (for Council review, NOT executed in SR-3)

If the Council authorizes SR-4, the implementation will be:

1. **Implement A** (1 file, ~10 lines, `lib/tiannara/evolution/trajectory.ex`):
   - Add `|| 0.0` guards in `stagnation?/1:99-100`.
   - Add `|| 0` per element in `constitutional_drift/1:84-85` (or pre-filter nils).
   - Add nil-filter before `avg/1` in `capability_trend/1:50`.
   - Add `|| []` guard in `discovery_yield/1:127` (for `evidence_ids`).
   - Optionally: add `@type dimension :: %{composite_score => number(), ...}` to `metrics.ex` (no behavior change, only documentation).
2. **Implement C** (2 lines removed, 2 test files):
   - Remove `@moduletag :long_horizon_evolution` from `long_horizon_test.exs:6`.
   - Remove `@moduletag :omega_horizon` from `horizon_harness_test.exs:6`.
3. **Run all verifications per the §10 matrix** (SR-2 tests, D1–D5 baseline, R6 verifier, E03 verifier, D5 facade check, E06/E07 check).
4. **Do NOT modify E03 artifacts.** Re-run the E03 independent verifier to confirm hash-binding intact and 24/24 PASS unchanged.
5. **STOP and report to Council.** Request separate authorization for the next execution-start signal.

---

## 14. What was NOT done (SR-3)

- No code modified.
- No implementation.
- No E03 preregistration, parameter manifest, verifier, or harness modified.
- D1–D5, R7, E06/E07 all unchanged.
- E03 remains BLOCKED at 0 runs. 0 stabilizer invocations.
- B is not bundled into A. B is a deferred future work item.
- The recommendation (A+C) is design-only, not authorization.
