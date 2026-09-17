# Measurement Integrity Remediation — Test Matrix

**Mission:** TIANNARA EMPIRICAL VALIDATION — MEASUREMENT INTEGRITY REMEDIATION (R2–R7).
**Date:** 2026-09-03 · **HEAD:** `3bd1601b9bb3c718f985d44ceaa8ef2e638d4ec6`

## Adversarial integrity tests (23)

`test/tiannara/forecasting/measurement_integrity_planner_test.exs`

| # | Test | Mission R4 invariant |
|---|------|---------------------|
| R4-01 | normal invocation returns the documented tuple | §1 shape |
| R4-02 | every previously-handled scenario returns the same shape | §1 shape |
| R4-02b | non-atom inputs raise FunctionClauseError | §4 hardcoded-injection guard |
| R4-03 | contradictory payloads produce the same kind/structure | §2 contradictory input |
| R4-04 | impossible/malformed payloads return the same shape | §3 repeated input |
| R4-05 | repeated invocations are deterministic in kind/shape | §3 repeated input |
| R4-05b | invocations with explicit sleep produce different hashes | hash contract |
| R4-06 | every scenario returns kind: :simulation | §6 fabricated execution marker |
| R4-07 | no function accepts a hardcoded outcome | §4 hardcoded-injection guard |
| R4-08 | no return field carries confidence / regret / chosen | §5 inflated confidence |
| R4-09 | kind is :simulation, never :real_execution | §6 fabricated execution marker |
| R4-10 | provenance_hash is reproducible from a rebuilt record | §7 missing provenance |
| R4-11 | underlying provenance is acceptable_as_evidence? false | §8 synthetic provenance |
| R4-12 | 100 invocations never return kind: :real_execution | §9 real-execution provenance |
| R4-13 | no DecisionArchive.record call, no "Quarantine node X", no "regret:" | §10 downstream retrieval |
| R4-14 | moduledoc declares the non-measurement contract | §11 evidence acceptance |
| R4-14b | source contains the Logger.info non-measurement narration | intent |
| R4-15 | none of the previously-emitted hardcoded strings appear in logs | §10 downstream retrieval |
| R4-16 | returned envelope is not acceptable as evidence | §11 evidence acceptance |
| R4-17 | provenance gate rejects :simulation, accepts :real_execution+id | §11 evidence acceptance |
| R4-18 | moduledoc names the remediation | §12 D3/D4/D5 consumers |
| R4-19 | @spec declares the only valid return shape | contract |
| R4-20 | provenance audit_trail marks non_measurement | provenance |

**Total:** 23 adversarial tests, 0 failures (live `mix test`).

## R5 re-probe assertions (9)

`mix run --no-start r5_reprobe.exs`

| # | Assertion | Result |
|---|-----------|--------|
| 1 | function body does NOT contain "Quarantine node X" | PASS |
| 2 | function body does NOT contain "regret: 0.04" | PASS |
| 3 | function body does NOT contain "intervention_effectiveness" | PASS |
| 4 | function body does NOT contain "regret_score" | PASS |
| 5 | function body does NOT contain "intervention_restraint_score" | PASS |
| 6 | function body does NOT contain 'predicted: "Stabilization"' | PASS |
| 7 | function body does NOT contain 'actual: "Stabilization"' | PASS |
| 8 | function body does NOT contain 'chosen = "Quarantine node X"' | PASS |
| 9 | function body does NOT contain "DecisionArchive.record" | PASS |

## R6 no-trust verifier gates (12)

`certification/empirical_validation/verifiers/MEASUREMENT_INTEGRITY_verifier.py`

| Gate | Description | Result |
|------|-------------|--------|
| V1 | planner fn body does not contain hardcoded fabrication strings | PASS |
| V2 | planner fn is a single narrow well-typed clause | PASS |
| V3 | planner @spec restricts return shape | PASS |
| V4 | DecisionArchive is unchanged logging facade (no GenServer/ETS/DETS) | PASS |
| V5 | Evidence.Provenance gate is unchanged and correct | PASS |
| V6 | planner moduledoc names the remediation (Option A+C, R1, R3) | PASS |
| V7 | R4 adversarial test file covers all 23 test names | PASS |
| V8 | R4 tests pass live (23/23) | PASS |
| V9 | D1–D5 forecasting baseline preserved (377 tests, 0 failures) | PASS |
| V10 | D5 facade unchanged: verdict/0 returns :d5_certified_bounded | PASS |
| V11 | E06/E07 falsifications preserved (Discovery.Engine + Archaeology unchanged) | PASS |
| V12 | R3 change is locally scoped to planner.ex | PASS |

**Total:** 12/12 PASS, `OVERALL: MEASUREMENT_INTEGRITY_CERTIFIED`, `EXIT_CODE: 0`.

## Gate-to-test mapping

| Mission invariant | Tests |
|---|---|
| §1 normal planner invocation | R4-01 |
| §2 contradictory input | R4-03, R4-04 |
| §3 repeated input | R4-05, R4-05b |
| §4 hardcoded injection | R4-02b, R4-07 |
| §5 inflated confidence | R4-08 |
| §6 fabricated execution marker | R4-09 |
| §7 missing provenance | R4-10 |
| §8 synthetic provenance | R4-11 |
| §9 real-execution provenance | R4-12 |
| §10 downstream retrieval | R4-13, R4-15 |
| §11 evidence acceptance | R4-16, R4-17, R4-14 |
| §12 D3/D4/D5 consumers | R4-18 |

## Phase 3 probe replay

R5 replayed the Phase 3 contradictory-input probe against the post-R3 implementation. The probe confirmed:

- All three contradictory payloads (catastrophic, clear-winner, never-run) return the **same** `{:ok, %{kind: :simulation, provenance_hash, scenario}}` shape.
- The function emits a single `Logger.info` line: `♟️ [Planner] (scenario=:intervention_quality, kind=simulation) — scenario-handler narration, NOT a measured decision record.`
- The attached provenance record (kind: :simulation) is rejected by `acceptable_as_evidence?/1`.
- The returned envelope itself is not a provenance record and is also rejected.
- E06/E07 FALSIFIED findings are preserved (V11 confirms the underlying modules are unchanged).
