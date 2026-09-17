# MC-004-P Certification — Domain-Physics Pilot Execution (BOUNDED)

**Gate:** MC-004-P
**Campaign:** Tiannara Remediation + Substrate Integration
**Verdict:** CERTIFIED_BOUNDED
**Authorization:** GRANTED — operator `c14_ac` (ASC-MC-004-P-DOMAIN-PHYSICS-PILOT.human.yaml)
**Date:** 2026-08-31

## Certification basis

This gate certifies the execution of the authorized physics pilot as a **real,
human-authorized experiment with durable evidence**, to the bounded boundary defined in
the MC-004-P contract. It is **NOT** a certification of the pilot's physical correctness
beyond the analytic pins exercised in the MC-004-M gate — it certifies that an execution
happened, was gated on a human grant, and left honest, verifiable evidence.

1. **Authorization:** operator `c14_ac` granted `ASC-MC-004-P` (status GRANTED,
   `authorization_kind: BOUNDED_EXECUTION`). The pilot required a human-minted
   `Authorization` grant; there is no autonomous path to execution.

2. **Independent static verification + probe (verifier, own scan):** PASS.
   `priv/tiannara/remediation/verifiers/MC004_P_pilot_execution.py` scans the live
   repository: presence of `PhysicsPilotExecution`, the grant/flag routing in
   `Physics.execute_experiment/1`, provenance `kind: :real_execution`, the JSONL ledger
   contract, the preserved MC-001 pins, zero `:rand.uniform` in the physics tree, and the
   result-JSON truthfulness flags. It also inspects the executions.jsonl ledger for a real
   physics_pilot entry.

3. **Compile:** `mix compile` succeeds (pre-existing warnings unchanged).

4. **Regression evidence:** `test/tiannara/math` + `test/tiannara/domains` +
   `test/tiannara/physics` = **80 tests, 0 failures**, including the 7 new MC-004-P tests
   (real execution evidence, provenance `:real_execution`, JSONL ledger persistence, refusal
   paths, MC-001 pins preserved). Corpus-wide pre-existing failures (rec. MC-003-M matrix)
   untouched by this gate.

5. **Real evidence produced:** the pilot executed and recorded `kind: :real_execution`
   provenance and append-only JSONL ledger entries (`harness: real_simulation`,
   `method: rk4`); the trajectory is a genuine RK4 integration of the damped oscillator.

6. **Truthfulness invariants upheld:** MC-001 pins intact; formal verification not revived;
   no deployment/sandbox-patch/production mutation from the pilot; `:real_execution_enabled`
   default false, restored false after this gate; zero `:rand.uniform` in the physics tree; no
   fabricated provenance/ledger/verifier/signature.

## BOUNDED verdict — what is and is not certified

| Claim | Status |
| --- | --- |
| The authorized physics pilot executed as a real, human-granted experiment | CERTIFIED (tests + ledger) |
| Execution recorded `:real_execution` provenance and append-only JSONL evidence | CERTIFIED (tests + probe) |
| Execution was GATED on a human-minted grant and the `:real_execution_enabled` flag | CERTIFIED (tests) |
| MC-001 pins and prior gated behavior preserved (MC-003-M/ MC-004-M suites green) | CERTIFIED |
| The integrator's damped-oscillator result matches analytic behavior | CERTIFIED (MC-004-M envelope test) |
| The pilot is *formally* verified as globally correct physics | **NOT CERTIFIED** — structural checks only (TD-MC004-M-FORMAL_VERIFICATION) |
| The pilot was forecast/benchmarked or deployed | **NOT CERTIFIED — did not happen** (out of scope, forbidden) |

## Final architectural question

> Did this gate increase the ability to distinguish *computed facts* from *claimed facts*?

**Yes.** The pilot's result is no longer a claim: it is a computed trajectory from a real,
bounded RK4 solver, executed only under a human-minted grant, carrying `:real_execution`
provenance and persisted in an append-only JSONL ledger alongside best-effort event-store
records. The gate keeps every prior truthfulness boundary intact — no deployment, no formal
verification revival, no fabrication — while upgrading the physics pilot from "simulation
provenance" (MC-004-M) to "real authorized execution provenance" (MC-004-P).

## Certificate close-out
- Certification boundary honored: single pilot; no deployment; flag restored to false after this gate.
- Result JSON: `priv/tiannara/remediation/results/MC004_P_result.json` — verdict `CERTIFIED_BOUNDED`, `pilot_executed: true`, `real_execution_enabled_flag: true` (gate scope).
- Independent verifier: PASS.
- Forward path: MC-004-P → HUMAN_REVIEW → INDEPENDENT_VERIFICATION → MC-004-CERTIFICATION.