# MC-004 Independent Evidence Matrix

**Gate:** MC-004 SETTLEMENT / Phase 2 — INDEPENDENT VERIFICATION
**Campaign:** Tiannara Remediation + Substrate Integration
**Date:** 2026-08-31

This matrix records the disposition of every required evidence area as independently
established by the no-trust verifier (`MC004_independent_verification.py`) and the human
reconciliation — not by trusting the certification records.

| Area | Required disposition | Independently established |
| --- | --- | --- |
| MC-004-M source mutation | Independently verified | VERIFIED (V1, V3, V4, V7) |
| MC-004-P source mutation | Independently verified | VERIFIED (V5, V7) |
| Authorization | Human-granted / valid | VERIFIED (c14_ac, GRANTED) |
| RK4 solver | Real + bounded | VERIFIED (V1) |
| Physics simulation | Real | VERIFIED (V3) |
| Structural validation | Real | VERIFIED (V4) |
| Formal verification | **Unavailable** | VERIFIED UNAVAILABLE (V2) |
| Pilot execution | **Actually executed** | VERIFIED (V6 + ledger) |
| Provenance | Verified (`:real_execution`) | VERIFIED |
| Execution ledger | Verified | VERIFIED (V6) |
| Real-execution flag | Restored `false` | VERIFIED (config scan + V5) |
| Deployment | None | VERIFIED (V7, V9) |
| Sandbox bypass | None | VERIFIED (V7) |
| MC-001 pins | Preserved | VERIFIED (V2) |
| Canonical ontology | Preserved (20 domains; no `:science/:mathematics/:logic/:cs`) | VERIFIED (V9) |
| Targeted tests | Reproduced | VERIFIED (V8) |
| Full regression | Explicit PASS / NOT_EXECUTED / BLOCKED | RECORDED (below) |
| Independent verifier | PASS/FAIL | PASS (exit 0) |
| Residual risks | Explicitly recorded | RECORDED (`MC004-RESIDUAL-RISKS.md`) |

## V1–V9 dispositions (detailed)

| Claim | Result | Evidence source (independent) |
| --- | --- | --- |
| V1 Real solver (RK4, bounded, real computation, no mock) | PASS | source of `calculus.ex`; tests |
| V2 MC-001 pin (unavailable ODE + formal verification, no `verified: true`) | PASS | source + tests |
| V3 Physics simulation (real RK4 substrate; `:simulation` provenance; evidence hash) | PASS | source of `physics.ex` |
| V4 Structural validation (real, distinct from formal proof) | PASS | source of `physics.ex` |
| V5 Pilot (module exists; human grant gate; `:real_execution_enabled` gate; flag false) | PASS | source of `physics_pilot_execution.ex` |
| V6 Live execution evidence (ledger: `real_simulation`, `rk4`, `:real_execution`) | PASS | ledger file read directly |
| V7 Gateway boundary (pilot path only under conditions; gated path intact; DeploymentGateway only; no bypass) | PASS | source of `physics.ex`, `real_execution.ex` |
| V8 Regression (targeted suite reproduced) | PASS | actual `mix test` run (below) |
| V9 Scope integrity (ontology, no theatrical verification, no unrestricted execution, no deployment) | PASS | ontology registry + source scan |

## V8 regression detail

Targeted suite reproduced on this machine:

```
test/tiannara/math      + test/tiannara/domains
test/tiannara/physics   + test/tiannara/phase4/real_execution_test.exs
Result: 85 tests, 0 failures   (real run, not claimed)
```

Full one-shot repository `mix test` is **ENVIRONMENT_BLOCKED** on this machine (>30 min),
consistent with every prior gate. Per-directory targeted suites are the standard; the
touched/adjacent directories above are green. Pre-existing corpus failures (activation_engine
`:already_started`, cognition `:already_started`, dead constitutional probes, ASC supervisor/port
races) are recorded in the MC-003-M matrix and are not touched by MC-004.

Disposition legend: PASS / NOT_EXECUTED / ENVIRONMENT_BLOCKED. No blocked test was upgraded to PASS.
