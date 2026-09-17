# MC-004-P Pilot Execution Protocol — Domain Physics

**Gate:** MC-004-P
**Campaign:** Tiannara Remediation + Substrate Integration
**Authorization:** ASC-MC-004-P-DOMAIN-PHYSICS-PILOT.human.yaml — GRANTED, operator `c14_ac`
**Date:** 2026-08-31
**Verdict target:** CERTIFIED_BOUNDED

This protocol governs the single, human-authorized real execution of the domain-physics
pilot experiment. It follows the MC-004-M mutation gate, which provided the real bounded
RK4 solver and physics-domain wiring. MC-004-P adds an execution layer with real,
durable evidence.

---

## 1. Objective

Execute the damped-harmonic-oscillator pilot (`Tiannara.Domains.Physics.pilot_experiment/0`)
through the real RK4 integrator as a genuinely real, human-authorized experiment, and record
`Evidence.Provenance` with `kind: :real_execution` plus an append-only JSONL ledger.

## 2. Authorization boundary

- Operator **`c14_ac`** explicitly granted `ASC-MC-004-P` (status GRANTED).
- `:real_execution_enabled` may be set **true only for this gate**.
- The pilot requires a **human-minted** `Authorization` grant (`human_grant/2`); there is no
  autonomous path to execution.

## 3. Execution path

```
Physics.execute_experiment(spec)
  └─ if spec.grant AND RealExecution.enabled?()  → PhysicsPilotExecution.execute(spec)
                                                    ├─ guard grant (human-minted, granted, unexpired)
                                                    ├─ Physics.simulate(pilot.hypothesis, pilot.context)
                                                    ├─ Physics.validate(%{model: simulation})
                                                    ├─ build verification (harness :real_simulation, method :rk4)
                                                    ├─ Provenance.build(kind: :real_execution)
                                                    └─ record JSONL ledger + best-effort EventStore append
  └─ else → ExperimentOrchestrator.submit_experiment(to_phase4_spec(spec))
              (preserves MC-003-M/ MC-004-M gated behavior)
```

## 4. Evidence recorded

- **Provenance:** `Evidence.Provenance.build(kind: :real_execution, ...)`.
- **Ledger:** append-only `priv/tiannara/real_execution/executions.jsonl`
  (`type: "real_execution"`, `subsystem: "physics_pilot"`, `harness: :real_simulation`).
- **Event store:** best-effort `Tiannara.Executive.EventStore.append("experiment.real_execution.completed")`
  when the store is running.

## 5. Truthfulness invariants (must hold)

1. `Calculus.solve_ode(%{}, %{}, 1.0)` → `{:error, :ode_solver_unavailable}` (MC-001 pin).
2. `Physics.validate(%{model: %{}})` → `{:error, :formal_verification_unavailable}` (MC-001 pin).
3. No deployment, sandbox patch, or production mutation results from the pilot.
4. Zero `:rand.uniform` in `lib/tiannara/physics/**`.
5. `:real_execution_enabled` default remains **false** everywhere except this gate's test scope.

## 6. Bounded scope

- Single experiment: damped harmonic oscillator only.
- No other canonical domain; no code-patch sandbox (`RealHarness`); no `DeploymentGateway`.

## 7. Acceptance evidence

- `mix compile` green.
- Targeted suites (`test/tiannara/math` + `test/tiannara/domains` + `test/tiannara/physics`) green,
  including the MC-004-P pilot test and the MC-001 pins.
- MC-004-P verifier (`priv/tiannara/remediation/verifiers/MC004_P_pilot_execution.py`) PASS (exit 0).
- Evidence matrix, certification, and result JSON written.

## 8. Forward path

- MC-004-P → HUMAN_REVIEW → INDEPENDENT_VERIFICATION → MC-004-CERTIFICATION.
- After certification, `:real_execution_enabled` is returned to **false**; no autonomous
  pilot execution is authorized without a fresh grant.
