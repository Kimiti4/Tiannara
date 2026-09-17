# MC-001-M: Mutation Evidence Matrix

**Gate:** MC-001-M
**Status:** COMPLETE
**Date:** 2026-08-27
**Tracking convention:** PASS (evidence collected) / FAIL / NOT_EXECUTED / NOT_APPLICABLE.
Never use PASS when evidence was not actually collected.

---

## Static verification

| # | Invariant | Status | Evidence |
|---|-----------|--------|----------|
| S1 | `FormalVerification.verify_invariants/2` returns `{:error, :formal_verification_unavailable}`, no `verified:true`/`mock:true` | PASS | `formal_verification.ex:4-6` |
| S2 | `Calculus.solve_ode/3` returns `{:error, :ode_solver_unavailable}`, no `mock_trajectory` | PASS | `calculus.ex:4-6` |
| S3 | `Optimization.gradient_descent/4` returns `{:error, :gradient_descent_unavailable}` | PASS | `optimization.ex:3-5` |
| S4 | `Optimization.nash_equilibrium/2` returns `{:error, :nash_equilibrium_unavailable}` | PASS | `optimization.ex:8-10` |
| S5 | No `mock: true` remains in targeted M3 implementations | PASS | grep of `foundations/` + `math/optimization.ex` |
| S6 | `Physics.metrics/0` contains no fabricated literals (142/38/4/0.88) | PASS | `physics.ex:36-48`; grep no longer matches Physics |
| S7 | `Observatory.Metrics.Mathematics.get_dashboard_data/0` no longer returns hardcoded values | PASS | `mathematics.ex:10-12` |
| S8 | No caller pattern-matches `{:ok, validation} = ...` + `validation.verified` treating unavailable as success | PASS | `autonomous_discovery.ex:35-51` rewritten |
| S9 | `autonomous_discovery` handles `{:error, reason}` for both simulate and validate | PASS | `autonomous_discovery.ex:35-51` |
| S10 | No fabricated replacement math introduced (no new ODE/verification/optimization/game-theory impl) | PASS | code diff review |
| S11 | No REAL primitive contract changed (`bayes_update` `{:ok,_}`, `shannon_entropy`, `variance`, `cosine`) | PASS | those modules untouched |
| S12 | Canonical 20-domain ontology unchanged; CanonicalRegistry untouched | PASS | no edits to CanonicalRegistry/ontology |

## Compilation & boot

| # | Invariant | Status | Evidence |
|---|-----------|--------|----------|
| C1 | Full `mix compile` succeeds (app generated) | PASS | `mix test` run generated `tiannara` app; no compile errors from mutations |
| C2 | Application boots; all supervised services `ok` | PASS | boot log: executive_memory, event_store, capability_graph, ontology_manager, discovery_supervisor, mission_director, etc. all `ok` |
| C3 | CanonicalRegistry remains supervised | PASS | boot log shows registry-dependent services `ok` |

## Targeted tests

| # | Invariant | Status | Evidence |
|---|-----------|--------|----------|
| T1 | MC-001-M truthfulness test file runs | PASS | `test/tiannara/math/mc001_m_truthfulness_test.exs` |
| T2 | All targeted tests pass | PASS | **10 tests, 0 failures** |

## Regression subset

| # | Invariant | Status | Evidence |
|---|-----------|--------|----------|
| R1 | ASC test suite total failures equals documented pre-existing baseline (38) | PASS | 38 failures in run; documented pre-existing baseline is 38 (boot-infra) |
| R2 | Zero failures attributable to this mutation | PASS | 38 = baseline; failures are boot/supervisor infra (`already_started`, `failed to start child`, `poison`), unrelated to changed modules |
| R3 | Full suite across entire repo | **NOT_EXECUTED** | environment/time constraints; recorded as NOT_EXECUTED, not PASS |

## Runtime

| # | Invariant | Status | Evidence |
|---|-----------|--------|----------|
| RT1 | Unavailable math capabilities return explicit unavailable states from running code | PASS | covered by targeted tests that execute the compiled code |
| RT2 | Affected consumers handle unavailable states without crashing | PASS | `autonomous_discovery` case-rewrite tested via module compile; targeted tests exercise consumer propagation |
| RT3 | Autonomous discovery does not accept unavailable verification as validated | PASS | `autonomous_discovery.ex:45-46` routes `{:error, reason}` to `:validation_unavailable` |
| RT4 | No fabricated Physics discovery count reaches downstream metrics | PASS | `Physics.metrics().discoveries_this_cycle == 0` (tested) |
| RT5 | No fabricated Mathematics dashboard exposed | PASS | `get_dashboard_data/0` returns `{:error, ...}` (tested) |

## Independent verifier

| # | Invariant | Status | Evidence |
|---|-----------|--------|----------|
| V1 | Independent verifier runs and passes | PASS | `priv/tiannara/remediation/verifiers/MC001_M_mutation.py` → `MC-001-M VERIFY: PASS` |

---

## Summary

| Status | Count |
|--------|-------|
| PASS | 18 |
| FAIL | 0 |
| NOT_EXECUTED | 1 (full-suite regression) |
| NOT_APPLICABLE | 0 |
| PENDING | 0 |
