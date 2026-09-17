# Measurement Integrity Remediation — Certification

**Mission:** TIANNARA EMPIRICAL VALIDATION — MEASUREMENT INTEGRITY REMEDIATION (R2–R7)
**Date:** 2026-09-03 · **HEAD:** `3bd1601b9bb3c718f985d44ceaa8ef2e638d4ec6`
**Scope:** `Tiannara.Forecasting.StrategicPlanner.evaluate_and_act/2` only.

## Verdict

```
MEASUREMENT_INTEGRITY_CERTIFIED
```

The measurement-integrity boundary is now closed. The fabrication documented in `FALSE_EMERGENCE_TEST_PLAN.md` (Phase 3) and `MEASUREMENT_INTEGRITY_RECONNAISSANCE.md` (R1) has been removed at its source (R3) and verified closed by adversarial tests (R4), re-probe (R5), and a no-trust independent verifier (R6). The R7 certification gate (10 conditions) is fully satisfied.

**This verdict does NOT grant authorization for E03 or any further phase.** A separate Council authorization is required for the Stabilizer-Only Emergence Campaign.

## What was certified

The single function `Tiannara.Forecasting.StrategicPlanner.evaluate_and_act/2` was remediated with Option A+C:

- **A. Remove / quarantine the theatrical path.** The hardcoded `DecisionArchive.record(%{predicted: "Stabilization", chosen: "Quarantine node X", actual: "Stabilization", regret: 0.04})` call and the three hardcoded `Aggregator.push_event(_, hardcoded)` calls were deleted. The function no longer emits any measured-record-shaped data and no longer pushes hardcoded metrics.
- **C. Explicitly mark remaining records as `:simulation` provenance.** The function now builds a `Tiannara.Evidence.Provenance` record of kind `:simulation` via the existing `Provenance.build/1` mechanism. The provenance hash is returned to the caller so any downstream consumer can verify the response is simulation, not real_execution.

The function is now a single, narrow, well-typed clause (`when is_atom(scenario)`) that returns `{:ok, %{scenario, kind: :simulation, provenance_hash}}` and emits one `Logger.info` line that explicitly declares the response as a non-measurement scenario-handler narration.

## Verification

### R4 adversarial tests — 23/23 PASS

23 ExUnit tests in `test/tiannara/forecasting/measurement_integrity_planner_test.exs` cover the 12 mission R4 invariants. All pass live under `mix test`.

### R5 re-probe — 9/9 PASS

`mix run --no-start r5_reprobe.exs` replays the Phase 3 contradictory-input probe against the remediated function. All three contradictory payloads return the same shape; the function body contains none of the 9 pre-R3 hardcoded strings; `Provenance.acceptable_as_evidence?(:simulation) = false`.

### R6 no-trust verifier — 12/12 PASS, EXIT 0

`certification/empirical_validation/verifiers/MEASUREMENT_INTEGRITY_verifier.py` does not trust internal PASS flags, self-declared provenance, or certification fields. It independently inspects the planner function body (not the whole file), the DecisionArchive (must remain a logger-only stub), the Evidence.Provenance gate (must be unchanged), the R4 test file (all 23 test names present), and runs the live test suite.

### D1–D5 baseline — 377/0

`mix test test/tiannara/forecasting` = 377 tests, 0 failures = 354 D1–D5 (preserved) + 23 R4 adversarial (new). The D1–D5 baseline of 300 tests is preserved with 54 additional D5 tests + 23 R4 tests = 377 total.

### D5 facade unchanged

`Tiannara.Forecasting.D5.verdict/0` still returns `:d5_certified_bounded`. D5 is frozen.

### E06/E07 falsifications preserved

`Discovery.Engine.discover/2` and `Archaeology.*` are unchanged. The Phase 3 FALSIFIED findings stand.

## Bounds (what certification does NOT claim)

- **No E03 authorization.** This certification closes the measurement-integrity boundary. It does not authorize the Stabilizer-Only Emergence Campaign or any other phase.
- **No D1–D5 modification.** D1, D2, D3, D4, and D5 modules are unchanged (except the R3 edit scoped to `StrategicPlanner.evaluate_and_act/2`). D5 remains `CERTIFIED_BOUNDED`.
- **No new architecture.** No new subsystem, no new persistence, no new experiment registry, no new evidence ledger. The remediation uses only existing mechanisms (`Provenance.build/1`).
- **No planner redesign.** Only the single function `evaluate_and_act/2` was modified. The `DecisionArchive` module was not redesigned (it remains a logger-only stub). The `FutureSimulator` in the same file was not touched.
- **The other simulated subsystems remain simulated.** `Archaeology.*`, `Discovery.Engine`, `EpistemicMirror.*`, `Forecasting.FutureSimulator`, and `Ecology.RegimeLadder` are unchanged. The R3 remediation closes only the `DecisionArchive` fabrication path. E06/E07 are still FALSIFIED.
- **Provenance gate is unchanged.** `Tiannara.Evidence.Provenance.acceptable_as_evidence?/1` is the original implementation. The remediation relies on the existing gate, not on a new one.

## Interface evolution

The R3 edit is additive-only with respect to the D1–D5 contract:

- `Tiannara.Forecasting.StrategicPlanner.evaluate_and_act/2` now returns `{:ok, %{scenario, kind: :simulation, provenance_hash}}` instead of `:ok` or an unstructured log. This is a **narrower** return type than before (the function previously returned `:ok` for unknown scenarios and emitted log lines / metrics for known ones). Callers that previously ignored the return value are unaffected.
- The function's `@spec` is new and explicit.
- The moduledoc is updated to declare the non-measurement contract.
- No struct, no field, no type in the D1–D5 contract surface is changed.

## Artefacts

| Artefact | Path |
|----------|------|
| R1 reconnaissance | `certification/empirical_validation/MEASUREMENT_INTEGRITY_RECONNAISSANCE.md` |
| R3 implementation | `lib/tiannara/forecasting/planner.ex` (R3 edit) |
| R4 adversarial tests | `test/tiannara/forecasting/measurement_integrity_planner_test.exs` |
| R5 re-probe | `r5_reprobe.exs` (run via `mix run --no-start`) |
| R6 verifier | `certification/empirical_validation/verifiers/MEASUREMENT_INTEGRITY_verifier.py` |
| R6 verifier output | `certification/empirical_validation/verifiers/MEASUREMENT_INTEGRITY_verifier_output.json` |
| Remediation record | `certification/empirical_validation/MEASUREMENT_INTEGRITY_REMEDIATION.md` |
| Test matrix | `certification/empirical_validation/MEASUREMENT_INTEGRITY_TEST_MATRIX.md` |
| Evidence | `certification/empirical_validation/MEASUREMENT_INTEGRITY_EVIDENCE.json` |
| Certification (this file) | `certification/empirical_validation/MEASUREMENT_INTEGRITY_CERTIFICATION.md` |
