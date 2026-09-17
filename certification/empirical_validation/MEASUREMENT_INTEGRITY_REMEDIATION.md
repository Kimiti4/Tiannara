# Measurement Integrity Remediation — R2–R7 Record

**Mission:** TIANNARA EMPIRICAL VALIDATION — MEASUREMENT INTEGRITY REMEDIATION (R2–R7).
**Posture:** R3 implementation + R4 adversarial tests + R5 re-probe + R6 no-trust verifier + R7 certification gate.
**D1–D5 remain frozen `CERTIFIED_BOUNDED`. No E03. No Phase 4. No D6. No new persistence architecture.**
**Date:** 2026-09-03 · **HEAD:** `3bd1601b9bb3c718f985d44ceaa8ef2e638d4ec6` · **App:** `:tiannara` v0.3.5

## R2 — Remediation selection (Option A+C, scoped)

R1 traced the live code path and concluded: the `Tiannara.Forecasting.DecisionArchive` is a **logging facade**, not a persistent archive. The defect is **a misleading log-line format**, not database poisoning. The minimum remediation is therefore Option A+C, scoped to `Tiannara.Forecasting.StrategicPlanner.evaluate_and_act/2` only.

| Option | Decision |
|---|---|
| **A. Remove / quarantine the theatrical path** | **ADOPTED** — the `DecisionArchive.record(...)` call and the hardcoded `Aggregator.push_event(_, hardcoded)` calls are deleted. The function no longer emits any measured-record-shaped data. |
| **C. Explicitly mark remaining records as `:simulation` provenance** | **ADOPTED** — the function now builds a `Tiannara.Evidence.Provenance` record of kind `:simulation` via the existing `Provenance.build/1` mechanism. The provenance hash is returned to the caller so any downstream consumer can verify the response is simulation, not real_execution. |
| **B. Route through `:fabrication_path_disabled`** | **REJECTED** — that mechanism is for *persisted* experiment results (`ResearchDirector` Pipeline), not log-line writes. The principle (do not persist / do not claim fabrication as measurement) is applied via Option A. |

The R2 decision matches what the Council authorized.

## R3 — Implementation

**File modified:** `lib/tiannara/forecasting/planner.ex` — **only the `Tiannara.Forecasting.StrategicPlanner` module's `evaluate_and_act/2` function and its moduledoc**. No other files were modified. `Tiannara.Forecasting.FutureSimulator` (in the same file) was **not touched** because the R1 scope was `StrategicPlanner.evaluate_and_act/2` only and the Council explicitly said "scoped to that function" and "do not redesign the planner."

**Pre-R3 function (3 branches, all fabricated):**
```elixir
def evaluate_and_act(scenario, _payload) do
  case scenario do
    :intervention_quality ->
      ... DecisionArchive.record(%{predicted: "Stabilization", chosen: "Quarantine node X",
                                    actual: "Stabilization", regret: 0.04}) ...
    :goodhart_resistance ->
      ... Aggregator.push_event(_, 0.92) ...
    :intervention_overreach ->
      ... Aggregator.push_event(_, 1.0) ...
    _ -> :ok
  end
end
```

**Post-R3 function (single narrow clause, scenario-handler narration only):**
```elixir
@spec evaluate_and_act(atom(), map()) ::
        {:ok, %{scenario: atom(), kind: :simulation, provenance_hash: binary()}}
def evaluate_and_act(scenario, _payload) when is_atom(scenario) do
  {:ok, provenance} = Provenance.build(
    kind: @scenario_kind,  # :simulation
    source: "StrategicPlanner.scenario_handler",
    audit_trail: ["non_measurement: scenario handler response"]
  )

  Logger.info("♟️ [Planner] (scenario=#{inspect(scenario)}, kind=#{@scenario_kind}) — \
              scenario-handler narration, NOT a measured decision record.")

  {:ok, %{scenario: scenario, kind: @scenario_kind, provenance_hash: Provenance.hash(provenance)}}
end
```

**Invariants enforced by the post-R3 function:**

1. No measured record is emitted. The return shape is a metadata envelope: `%{scenario, kind: :simulation, provenance_hash}`. There is no `chosen`, `predicted`, `actual`, `regret`, `confidence`, `effectiveness`, `score`, or `restraint` field.
2. The attached provenance record has `kind: :simulation`, so `Provenance.acceptable_as_evidence?/1` returns `false`. It can never satisfy the evidence gate.
3. No `Aggregator.push_event(_, hardcoded)` call exists in the function. No hardcoded metrics are pushed.
4. The function does not call `DecisionArchive.record` (the logging facade is no longer called from this scenario handler).
5. The moduledoc names the remediation and declares the non-measurement contract.
6. The function guard `when is_atom(scenario)` rejects non-atom inputs (strings, integers, maps, lists, etc.) with `FunctionClauseError`, preventing hardcoded "scenario" injection of arbitrary terms.
7. The function's `@spec` restricts the return shape to the documented envelope.

## R4 — Adversarial integrity tests (23 tests, 0 failures)

**File:** `test/tiannara/forecasting/measurement_integrity_planner_test.exs` (new).

23 ExUnit tests cover the 12 mission invariants plus the structural-contract tests. All pass live under `mix test` (V8 confirmed). Test highlights:

| # | Test | Invariant |
|---|---|---|
| R4-01 | Normal invocation returns `{:ok, %{scenario, kind: :simulation, provenance_hash}}` | shape |
| R4-02 | Every previously-handled scenario returns the same shape | shape |
| R4-02b | Non-atom inputs raise `FunctionClauseError` | input restriction |
| R4-03 | Contradictory payloads produce the same kind/structure | no measured record |
| R4-04 | Impossible / malformed payloads all return the same shape | payload-agnostic |
| R4-05/05b | Repeated invocations are deterministic in shape; hashes differ when `produced_at` differs | hash provenance |
| R4-06 | Every scenario returns `kind: :simulation` | kind |
| R4-07 | No function accepts a hardcoded outcome injection | API surface |
| R4-08 | No return field carries confidence / effectiveness / regret / chosen / predicted / actual | no fabricated fields |
| R4-09 | Returned kind is `:simulation`, never `:real_execution` | kind |
| R4-10 | Provenance hash is reproducible from a rebuilt `Provenance.build/1` record | hash contract |
| R4-11 | Underlying provenance is `acceptable_as_evidence? false` | evidence gate |
| R4-12 | 100 invocations never return `kind: :real_execution` | kind |
| R4-13 | Log does not contain "Persisting strategic decision record" / "Quarantine node X" / "regret:" | log format |
| R4-14 | Moduledoc declares the non-measurement contract (structural) | contract |
| R4-14b | Source contains the `Logger.info` with the non-measurement narration (structural) | intent |
| R4-15 | None of the previously-emitted hardcoded strings appear in any log line | log format |
| R4-16 | Returned envelope is not acceptable as evidence | evidence gate |
| R4-17 | Provenance gate works bidirectionally (rejects `:simulation`, accepts `:real_execution`+id) | gate |
| R4-18 | Moduledoc names the remediation | documentation |
| R4-19 | `@spec` declares the only valid return shape | contract |
| R4-20 | Provenance `audit_trail` marks the response as `non_measurement` | provenance |

## R5 — Phase 3 contradictory-input re-probe (9/9 PASS)

`mix run --no-start r5_reprobe.exs` confirmed:

- Three contradictory payloads all return the same `{:ok, %{kind: :simulation, provenance_hash, scenario}}` shape.
- The function body contains **none** of the 9 hardcoded strings from the pre-R3 implementation.
- The function emits a single `Logger.info` line: `♟️ [Planner] (scenario=:intervention_quality, kind=simulation) — scenario-handler narration, NOT a measured decision record.`
- `Provenance.acceptable_as_evidence?(%{kind: :simulation, ...})` returns `false`.
- `Provenance.acceptable_as_evidence?(%{kind: :real_execution, execution_id: "exec-1"})` returns `true`.
- The returned envelope is not acceptable as evidence (no `:execution_id`, no `:imported_evidence` source).

**E06/E07 are preserved:** the R3 remediation touched only `StrategicPlanner.evaluate_and_act/2`. The `Discovery.Engine`, `Archaeology.*`, and all other modules probed in Phase 3 are unchanged. The Phase 3 FALSIFIED findings stand.

## R6 — No-trust independent verification (12/12 PASS, EXIT 0)

**File:** `certification/empirical_validation/verifiers/MEASUREMENT_INTEGRITY_verifier.py` (new).

The verifier does **not trust**:
- internal PASS flags
- self-declared provenance
- certification fields
- moduledoc self-declarations (V2 checks the function body, not the moduledoc)

It independently inspects:
- the planner function body (V1, V2) — not the whole file
- the DecisionArchive (V4) — confirms it remains a logging facade (no GenServer, no ETS, no DETS)
- the Evidence.Provenance gate (V5) — confirms the gate is unchanged
- the R4 test file (V7) — confirms all 23 test names are present
- the live test runs (V8, V9) — runs `mix test` independently

Latest run: **12/12 PASS, OVERALL: MEASUREMENT_INTEGRITY_CERTIFIED, EXIT_CODE: 0**.
Live empirical: **377 tests, 0 failures** (354 D1–D5 + 23 R4). One earlier run reported a transient flake; the suite is stable on re-run.

## R7 — Certification gate (10 conditions, ALL PASS)

| # | Condition | Result |
|---|---|---|
| 1 | fabricated planner records cannot masquerade as real evidence | **PASS** (R5, V1, V5, R4-08, R4-16) |
| 2 | synthetic records remain explicitly identifiable | **PASS** (V2, R4-11) |
| 3 | missing provenance does not become real evidence | **PASS** (V5, R4-16, R4-17) |
| 4 | downstream evidence consumers reject/quarantine fabricated records | **PASS** (V4, V5) |
| 5 | original Phase 3 findings remain unchanged | **PASS** (V11) |
| 6 | D1–D5 remain frozen | **PASS** (V10, D5 facade unchanged) |
| 7 | no unauthorized architecture was introduced | **PASS** (V12, only `planner.ex` modified) |
| 8 | adversarial tests pass | **PASS** (V8, 23/23) |
| 9 | independent verifier passes | **PASS** (12/12, EXIT 0) |
| 10 | Phase 3 probes reproduce the expected integrity behavior | **PASS** (R5, 9/9) |

## R8 — Artifacts (this mission, R2–R7)

| Artefact | Path |
|---|---|
| Implementation | `lib/tiannara/forecasting/planner.ex` (R3 edit) |
| Adversarial tests | `test/tiannara/forecasting/measurement_integrity_planner_test.exs` (new, 23 tests) |
| No-trust verifier | `certification/empirical_validation/verifiers/MEASUREMENT_INTEGRITY_verifier.py` (new) |
| Verifier output | `certification/empirical_validation/verifiers/MEASUREMENT_INTEGRITY_verifier_output.json` (written by verifier) |
| Remediation record | `certification/empirical_validation/MEASUREMENT_INTEGRITY_REMEDIATION.md` (this file) |
| Test matrix | `certification/empirical_validation/MEASUREMENT_INTEGRITY_TEST_MATRIX.md` |
| Evidence | `certification/empirical_validation/MEASUREMENT_INTEGRITY_EVIDENCE.json` |
| Certification | `certification/empirical_validation/MEASUREMENT_INTEGRITY_CERTIFICATION.md` |

## Non-goals honored

- D1–D5 frozen: `Tiannara.Forecasting.d5.verdict/0` still returns `:d5_certified_bounded`.
- No D1/D2/D3/D4/D5 module was modified.
- No E03 stabilizer campaign.
- No Phase 4.
- No D6.
- No new experiment registry, no new evidence ledger, no new persistence architecture.
- The `DecisionArchive` module was **not** redesigned (V4 confirms it remains a logger-only stub).
- The `Evidence.Provenance` gate was **not** modified (V5 confirms the original `acceptable_as_evidence?/1` is unchanged).
- E06/E07 falsifications are **preserved** (V11 confirms Discovery.Engine and Archaeology are unchanged).

## Final verdict (R7)

```
MEASUREMENT_INTEGRITY_CERTIFIED
```

The measurement boundary is trustworthy enough for the next Council decision. A successful R7 establishes that the integrity gate is now closed; it does **not** grant automatic authorization for E03 or any further phase.

**STOP.**
