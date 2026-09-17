# MC-004-P Pilot Execution Evidence Matrix

**Gate:** MC-004-P — Domain-Physics Pilot Execution
**Campaign:** Tiannara Remediation + Substrate Integration
**Scope:** single authorized real execution of the damped-harmonic-oscillator pilot
**Status:** EVIDENCE COMPLETE — verdict CERTIFIED_BOUNDED
**Date:** 2026-08-31

This ledger records WHAT was executed, the verification evidence (compile + targeted
suite results + ledger/provenance), and the honest boundary (what did NOT happen).

---

## New execution layer

| Artifact | Change |
| --- | --- |
| `lib/tiannara/phase4/physics_pilot_execution.ex` (NEW) | `execute/1` — guards a human-minted `Authorization` grant (granted + unexpired; otherwise `:authorization_grant_required` / `:authorization_grant_denied` / `:grant_expired`), runs the pilot via `Physics.simulate/2`, validates via `Physics.validate/1`, builds verification (`harness: :real_simulation`, `method: :rk4`), builds `Provenance` with `kind: :real_execution`, and records an append-only JSONL ledger + best-effort EventStore append |
| `lib/tiannara/domains/physics.ex` | `execute_experiment/1` routes to `PhysicsPilotExecution.execute/1` **only** when `spec.grant` present AND `RealExecution.enabled?()` true; otherwise preserves the gated `submit_experiment/1` path (unchanged MC-003-M/ MC-004-M behavior) |

## Evidence captured

- **Provenance kind:** `:real_execution` (verified in test `produces real execution evidence`).
- **Ledger:** append-only `priv/tiannara/real_execution/executions.jsonl` entries with
  `"subsystem":"physics_pilot"`, `"type":"real_execution"`, `"harness":"real_simulation"`
  (verified in test `records execution to JSONL ledger`).
- **Verification map:** `harness: :real_simulation`, `method: :rk4`, `order`, `steps`, `dt`,
  `trajectory_length`, `initial_state`, `final_state`, `validation` (from `Physics.validate`).
- **Event store:** best-effort `EventStore.append("experiment.real_execution.completed")` when running.

## Refusal paths (unchanged gated behavior preserved)

| Condition | Result |
| --- | --- |
| `:real_execution_enabled` false, no grant | `{:error, :real_execution_not_enabled}` (via submit_experiment) |
| flag true, no grant | `{:error, :authorization_grant_required}` |
| flag true, denied grant | `{:error, :authorization_grant_denied}` |

All three are covered by MC-004-P tests and remain consistent with MC-003-M M2 / MC-004-M.

---

## Regression battery (post-execution, standalone run)

| Suite | Result |
| --- | --- |
| `test/tiannara/math` + `test/tiannara/domains` + `test/tiannara/physics` | **80 tests, 0 failures** |

Includes the 7 new MC-004-P pilot tests, the 3 MC-004-M test files, the MC-001 truthfulness
pins, `canonical_registry_test.exs` (requires app boot — run without `--no-start`), and the
subsystem-quarantine tests. Compile green. Pre-existing corpus-wide failures (activation_engine,
cognition, dead constitutional probes, ASC supervisor/port races) recorded in the MC-003-M
matrix are untouched by this gate.

## Honest boundary (what did NOT happen)

- **No deployment**: the pilot produced a trajectory and evidence only; no candidate was
  deployed, no production code was mutated by the execution, no `DeploymentGateway` involved.
- **No code-patch sandbox**: `RealHarness`/`RealExecution` substrate path was NOT used — the
  simulation IS the experiment (`harness: :real_simulation`).
- **Formal verification was NOT revived**: `Physics.validate` remains structural
  (`:structural_checks`) and returns `{:error, :formal_verification_unavailable}` for
  non-integrated models (MC-001 pin).
- **No other domain/pilot** executed — single damped-harmonic-oscillator experiment only.
- **Flag restored false** after this gate; no autonomous pilot execution authorized without a
  fresh grant.
- No fabricated provenance, ledger entry, verifier output, or c14 signature.
