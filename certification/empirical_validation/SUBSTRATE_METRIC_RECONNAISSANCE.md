# Substrate Metric Reconnaissance (SR-1)

**Mission:** TIANNARA EMPIRICAL VALIDATION — Substrate Remediation Investigation (SR-1 through SR-4)
**Date:** 2026-09-03 · **HEAD:** `3bd1601b9bb3c718f985d44ceaa8ef2e638d4ec6` · **App:** `:tiannara` v0.3.5
**Origin:** E03 smoke test (`E03_SMOKE_TEST.exs`) crashed at `Tiannara.Evolution.Trajectory.analyze/1` during the post-loop trajectory analysis of a `cycles: 1` CONTROL A run. Council HOLD decision requires substrate-level diagnosis before E03 may proceed.
**Posture:** read-only reconnaissance. No code modified. D1–D5, R7, E03 preregistration, E03 verifier, E03 harness, E06/E07 all unchanged.

## 0. Method

Source inspection of the live repository. Reconnaissance is read-only. Every claim cites a file and line. The original bug report (which characterized the defect as "DriftAudit expects map, Trajectory expects numeric") is **re-examined against the source** rather than accepted at face value — source evidence is authoritative.

## 1. The original report's premise, re-examined

The E03 smoke test reported:
- `Tiannara.Evolution.DriftAudit.audit/2` requires **map-shaped metric dimensions**.
- `Tiannara.Evolution.Trajectory.analyze/1` requires **numeric metric dimensions**.

**Source re-examination: this premise is WRONG.** Both consumers are uniformly MAP-EXPECTING. See §2 and §3. The E03 smoke test crash had a different (smaller) root cause, identified in §4.

This is an important honest correction: the substrate is consistent in shape. The defect is in defensive handling and test gating, not in a fundamental shape contradiction.

## 2. Canonical shape of `%Tiannara.Evolution.Metrics{}`

`lib/tiannara/evolution/metrics.ex` (15 lines, the entire module):

```elixir
defmodule Tiannara.Evolution.Metrics do
  defstruct capability: %{},
            epistemic: %{},
            architectural: %{},
            constitutional: %{}
  @type t :: %__MODULE__{}
end
```

- **Shape: MAP.** Every dimension's default is `%{}`.
- No `@type` spec on field contents. No `enforce_keys`. No `@moduledoc` documenting the inner keyset.
- The struct accepts any value for the four fields, including `nil`, numbers, or maps. The defaults are maps.

## 3. Producer / consumer trace (whole repo)

### 3.1 Producers of `%Metrics{}`

Every active producer in the repo constructs MAP-shaped dimensions. **No producer anywhere constructs numeric dimensions.** The struct's default plus every explicit construction are map-shaped.

| File:Line | Producer | Dimension shape |
|---|---|---|
| `lib/tiannara/evolution/metrics.ex` | struct defaults | map (`%{}`) |
| `lib/tiannara/evolution/long_horizon.ex:32` | `initial_metrics` fallback | map (struct default) |
| `lib/tiannara/evolution/harness.ex:22` | `initial_metrics` fallback | map (struct default) |
| `lib/tiannara/empirical_validation/e03/harness.ex:69` | `initial_metrics = %Metrics{}` | **map (bare — empty sub-maps)** |
| `lib/tiannara/empirical_validation/e03/harness.ex:269` | `metrics_from_ecology/1` | map (`%{composite_score: 1.0 - dominance}`, etc.) |
| `lib/tiannara/empirical_validation/e03/harness.ex:282` | `default_metrics/0` | map (full DriftAudit keyset) |
| `test/tiannara/evolution/long_horizon_test.exs:9, 12` | `base_metrics/1` | map (INCLUDES `:memory`) |
| `test/tiannara/evolution/horizon_harness_test.exs:9` | `base_metrics/0` | map (omits `:memory`) |

### 3.2 Consumers of `%Metrics{}` fields

`DriftAudit._delta/2` helpers all use `Map.get(dim, :key, default)` (drift_audit.ex:90, 91, 96, 97, 102, 103, 109). **MAP-EXPECTING** — works on maps, crashes on numbers.

`Trajectory.*` helpers use `Access.get` (bracket syntax `field[:key]`) — also **MAP-EXPECTING** (trajectory.ex:44, 61, 62, 74, 75, 84, 99, 100, 133, 146, 147). Works on maps, returns `nil` for missing keys.

Both consumers agree on map shape. The original report's "Trajectory expects numeric" claim is **not supported by the source**.

### 3.3 Cross-module references to `%Tiannara.Evolution.Metrics{}`

Only in `lib/tiannara/evolution/*` and `lib/tiannara/empirical_validation/e03/harness.ex`. No other module in `lib/` or `test/` constructs or consumes it. The substrate boundary is clean.

## 4. The actual E03 crash: root cause

The E03 smoke test (`cycles: 1`, CONTROL A) crashed with:

```
** (ArithmeticError) bad argument in arithmetic expression: 1.0 - nil
  lib/tiannara/evolution/trajectory.ex:99:
    c.metrics_after.capability[:composite_score] - c.metrics_before.capability[:composite_score]
```

### Why `nil` appeared

The E03 harness's `LongHorizon.run/2` call constructs `initial_metrics = %Metrics{}` (bare defaults — all four dimensions are empty maps). For `cycles: 1`:

1. Cycle 1 is built. `evaluate_cycle/5` sets `metrics_before: cur.metrics` (= `%Metrics{}` with empty sub-maps) and `metrics_after: proposal.metrics_after` (= `metrics_from_ecology(...)` which DOES contain `%{composite_score: 1.0 - dominance}`, etc.).
2. The cycle is `:accepted` (net_gain = 0.0 with the E03 generator's first proposal; with `min_capability_gain: 0.0` this is borderline). After the loop, `Trajectory.analyze/1` is called.
3. `Trajectory.analyze/1` → `stagnation?/1` → line 99: `c.metrics_after.capability[:composite_score] - c.metrics_before.capability[:composite_score]` = `1.0 - nil` → **ArithmeticError**.

**Root cause: `stagnation?/1` at trajectory.ex:99-100 has no nil guard on the `Access.get` result, while other Trajectory helpers (epistemic_drift:61-62, architectural_drift:74-75, memory_growth:146-147) DO have `|| 0` / `|| 0.0` guards.** This is an inconsistency in defensive handling within the same module.

### Why the existing tests did not catch this

`test/tiannara/evolution/long_horizon_test.exs:12` constructs `base_metrics/1` which **does** include `:memory` and **all four DriftAudit keys**. So in the existing tests, both `metrics_before` and `metrics_after` for every cycle have the same shape, and the unguarded `stagnation?/1` accesses return matching non-nil values.

The E03 harness's `initial_metrics = %Metrics{}` (empty sub-maps) and the E03 generator's `metrics_from_ecology/1` (populated sub-maps) produce **shape-inconsistent `metrics_before` vs `metrics_after`** in cycle 1. This inconsistency was never tested.

**Additionally**, `long_horizon_test.exs:6` carries `@moduletag :long_horizon_evolution`, which excludes it from the default test suite. The tag name does not appear in any `mix test --include` invocation in the repo. So even if the shape-inconsistency test were added, it would not run by default.

## 5. Contributing factors (defect amplifier)

Two additional substrate behaviors amplify the primary defect:

### 5.1 DriftAudit's silent default substitution

`DriftAudit._delta/2` helpers (drift_audit.ex:90, 96, 102, 109) use `Map.get(dim, :key, default)`. When the key is missing, the default (`0.0` or `0`) is silently substituted. This means a generator that omits `:composite_score` produces `net_gain = 0.0`, which at drift_audit.ex:64 fails the strict `< min_capability_gain: 0.0` check. The cycle is **silently rejected as `capability_insufficient`** rather than flagged as a missing-key error. This masks producer-side contract violations during the loop.

### 5.2 DriftAudit's asymmetric `constitutional_delta/2`

`DriftAudit.constitutional_delta/2` (drift_audit.ex:108-111) ignores `before` entirely and only reads `after_m`. This asymmetry is undocumented and inconsistent with the other three delta helpers.

## 6. Defect classification

**Primary classification: STALE CONSUMER (Trajectory) + SILENT PRODUCER MASK (DriftAudit), combined with TEST GATING (long_horizon_test.exs excluded by moduletag).**

NOT a dual-representation defect. NOT a "DriftAudit wants map / Trajectory wants numeric" defect (the original E03 report's framing was wrong on the source).

The substrate's canonical shape is map. Both consumers agree on map. The failure is:
1. `Trajectory.stagnation?/1` (and its nil-guard inconsistency) crashes on `nil - nil` when `metrics_before.capability[:composite_score]` is missing.
2. `DriftAudit` silently substitutes defaults for missing keys, masking the producer-side contract violation during the loop.
3. The existing tests that exercise the DriftAudit→Trajectory pipeline are gated out of the default suite, so this class of defect was never caught.

## 7. Minimum substrate correction options (design only — NOT implemented)

For the Council's review at the SR-3 gate. Per the HOLD discipline, no code is modified in SR-1.

### Option A: Targeted nil guards in Trajectory (cheapest, most targeted)

Add `|| 0.0` guards to the two unguarded arithmetic sites in `Trajectory`:

```elixir
# trajectory.ex:99-100 (stagnation?/1)
gains = Enum.map(recent, fn c ->
  (c.metrics_after.capability[:composite_score] || 0.0) -
  (c.metrics_before.capability[:composite_score] || 0.0)
end)
```

This is a **4-character patch** in one function, matching the defensive pattern already used at lines 61-62, 74-75, 146-147. Total substrate change: one file, one function, two lines. No new types, no new tests, no new architecture.

This fixes the E03 crash without altering the substrate's canonical map shape or any of its public contracts. `Metrics` remains map-shaped; `DriftAudit` continues to read maps; `Trajectory` continues to read maps.

### Option B: Tighten DriftAudit's missing-key handling

When `Map.get` substitutes a default because the key was missing, DriftAudit could add a `{:metric_incomplete, :capability}` reason to the rejection list. This surfaces producer-side contract violations during the loop instead of masking them. Combined with Option A, this would prevent the E03 crash AND prevent the silent-brick behavior.

Substrate change: `drift_audit.ex` only. Two functions, ~6 lines. No type changes, no new tests beyond what SR-2 adds.

### Option C: Un-gate the long_horizon test

Remove `@moduletag :long_horizon_evolution` from `test/tiannara/evolution/long_horizon_test.exs:6` (or wire `--include long_horizon_evolution` into CI). This ensures the DriftAudit→Trajectory pipeline is exercised in every test run, so this class of defect is caught before it reaches production.

This is a test-infrastructure change only. It does not alter the substrate's behavior, but it changes what the test suite covers.

### Recommended combination (for Council review)

**Option A (required, 1 file, ~4 lines) + Option C (test gating, 1 line removed).** Option B is valuable but secondary; A alone is sufficient to unblock E03.

## 8. Bounds the correction MUST respect (per HOLD decision)

- D1–D5 must remain frozen `CERTIFIED_BOUNDED`. No D1/D2/D3/D4/D5 module is modified.
- The R7 measurement-integrity boundary must remain closed. No modification to `DecisionArchive`, `StrategicPlanner`, or `Evidence.Provenance`.
- E06/E07 FALSIFIED findings must remain preserved. The `Discovery.Engine` and `Archaeology.*` modules are not touched.
- E03 preregistration and parameter manifest remain frozen. The correction does **not** alter any preregistered measurement, metric semantics, trajectory calculation, or success criterion. If it did, E03 would require a new protocol revision and fresh independent verification per the Council's HOLD ruling.
- The correction is the **minimum** substrate change. No redesign, no new architecture, no new test infrastructure beyond what's needed.

## 9. What was NOT done (SR-1)

- No code modified.
- No tests added.
- No correction implemented.
- E03 preregistration, parameter manifest, verifier, and harness all unchanged.
- D1–D5, R7, E06/E07 all unchanged.
- The substrate defect is now properly classified (stale consumer + silent producer mask + test gating), distinct from the original "map vs numeric" framing.
