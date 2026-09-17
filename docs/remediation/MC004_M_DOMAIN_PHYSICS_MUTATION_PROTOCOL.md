# MC-004-M — Domain/Physics Pilot Mutation Protocol

**Gate:** MC-004-M (Mutation — Bounded)
**Campaign:** Tiannara Remediation + Substrate Integration
**Predecessors:** MC-004-A0 CERTIFIED (RECONCILIATION) — human review COMPLETE; MC-003-M CERTIFIED (BOUNDED); MC-003-A0; MC-002-M; MC-001-M
**Mode:** AUTHORIZED MUTATION (separate human authorization; NO execution)
**Date:** 2026-08-31

## Authorization

- Operator: `c14_ac`; status: GRANTED via `priv/tiannara/authorization/ASC-MC-004-M-DOMAIN-PHYSICS-MUTATION.human.yaml`.
- MC-004-M authorizes the A0 MUTATION-PLAN units MU-1…MU-4. It does NOT authorize execution (MC-004-P) and does NOT enable `:real_execution_enabled`.

## Governing Principles

- Truth > apparent capability; Verification > autonomy; Reuse > duplication; bounded scope > broad rewrite.
- A solver is real only when its computation genuinely reduces and is tested against analytic truth. Capability stays bounded: the RK4 integrator supports ONE spec shape; everything else remains truthful `{:error, :ode_solver_unavailable}`.
- Theatrical physics output must not be producible or consumable (MU-3). NDE/TWP broken paths become STAGED (quarantined), not crash-prone.
- Provenance attaches to every computed physics result (kind `:simulation`; never `:real_execution` unless separately authorized and executed).
- No mock, no fabricated success, no revived formal-verification theater. MC-003 execution vocabulary (proposed/scheduled/simulated/attempted/completed/observed/verified) applies.

## Scope (bounded)

| Unit | Change | Artifacts |
|---|---|---|
| MU-1 | REAL bounded RK4 `solve_ode/2,3` in `Tiannara.Foundations.Mathematics.Calculus` for `:first_order_system` specs; all other specs → `{:error, :ode_solver_unavailable}` (MC-001 pin preserved) | calculus.ex; tests against analytic solutions |
| MU-2 | `Tiannara.Domains.Physics`: `simulate/2` real for supported specs; `validate/1` structural checks (energy-bounded + finiteness, explicit `:structural_checks`; never `verified: true`); provenance attachment; `pilot_experiment/0` (damped oscillator) | domains/physics.ex; tests |
| MU-3 | Quarantine `Tiannara.Physics.OPC/NDE/IRD/TWP` client surfaces → `{:error, :physics_substrate_unavailable}`; remove `:rand.uniform` from opc/ird; supervisors + ETS retained (boot-safe) | opc/nde/ird/twp .ex |
| MU-4 | Physics→Phase4 bridge `execute_experiment/1` (returns `{:error, :real_execution_not_enabled}` while flag false); ADE placeholder replaced by pilot model | domains/physics.ex; autonomous_discovery.ex |

## Forbidden

- `:real_execution_enabled` → true; ANY live experiment; NDE/TWP/OPC/IRD rewrites beyond quarantine; formal-verification revival; new ODE library dependency; all-20-domain work; linear algebra module; modifying MC-001/MC-002/MC-003/AC-001/MC-004-A0 artifacts; fabricating c14 signature; removing supervisors (boot must stay green).

## Truthfulness invariants (verifier-enforced)

1. `Calculus.solve_ode(%{}, %{}, 1.0)` → `{:error, :ode_solver_unavailable}` (MC-001 pin intact).
2. `Physics.simulate(%{equations: []}, %{boundary_conditions: []})` → `{:error, :ode_solver_unavailable}`.
3. `Physics.validate(%{model: %{}})` → `{:error, :formal_verification_unavailable}`.
4. Zero `:rand.uniform` in `lib/tiannara/physics/`.
5. Physics simulated results carry provenance `kind: :simulation` via `Evidence.Provenance.build`.
6. No error-code regression: compile green; targeted suites green.

## Deliverables (7)

1. This protocol (`docs/remediation/MC004_M_DOMAIN_PHYSICS_MUTATION_PROTOCOL.md`)
2. `priv/tiannara/remediation/contracts/MC004_M_domain_physics_mutation.contract.yaml`
3. `priv/tiannara/authorization/ASC-MC-004-M-DOMAIN-PHYSICS-MUTATION.human.yaml`
4. `certification/remediation/MC004-M-EVIDENCE-MATRIX.md`
5. `certification/remediation/MC004-M-CERTIFICATION.md`
6. `priv/tiannara/remediation/results/MC004_M_result.json`
7. `priv/tiannara/remediation/verifiers/MC004_M_domain_physics_mutation.py`

## Settlement

MC-004-A0 → HUMAN REVIEW → **MC-004-M (this gate)** → MC-004-P (bounded pilot execution, FURTHER authorization required; `:real_execution_enabled` may only be enabled there) → independent verification → MC-004 certification.