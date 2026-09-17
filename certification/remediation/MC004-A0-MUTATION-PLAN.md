# MC-004-A0 — Preliminary Mutation Plan (MC-004-M)

**Gate:** MC-004-A0 (Reconciliation) — **Date:** 2026-08-31 — **Mode:** READ-ONLY.
This plan is a **recommendation only**. NO mutation occurred in A0. MC-004-M requires a SEPARATE human authorization (see authorization file) and must NOT be executed from this gate.

## Scope guard (unchanged)
- Only canonical `:physics`. No all-20-domains remediation, no generalized physics engine, no new ODE library dependency, no reintroduction of mocks, no formal-verification revival, `:real_execution_enabled` stays FALSE, M5/os untouched.

## Mutations (candidate units, ordered)

### MU-1 — REAL bounded RK4 integrator (prerequisite, CRITICAL)
- Re-back `Tiannara.Foundations.Mathematics.Calculus.solve_ode/3` (or add `Tiannara.Math.Numerical.integrate_ode`) with a REAL bounded 4th-order Runge–Kutta implementation, pure Elixir.
- Required tests: unit tests against analytic solutions (exponential decay; damped harmonic oscillator under/over/critical damping); determinism (fixed seed/params); error modes via `Tiannara.Numerics.error_mode/1`.
- Rollback: revert to `{:error, :ode_solver_unavailable}` stub.
- Risk: LOW-MEDIUM (pure math, no I/O, no supervision changes).

### MU-2 — Physics workflow truthfulness (DOMAIN)
- `Tiannara.Domains.Physics.simulate/2` → real integration for supported model payloads; structural validation on `validate/1` (bounds, energy monotonicity, analytic-reference tolerance) — NOT SMT, formal verification remains unavailable.
- Attach provenance to simulated outcomes via `Evidence.Provenance` (kind `:computed`).
- Keep `discover`/`generate_hypotheses`/`design_experiments` honest-empty until a real discovery mechanism is scoped.
- Rollback: return domain to honest-error behavior.
- Risk: MEDIUM (domain contract shape preserved; consumers are dead so blast radius ~0).

### MU-3 — Quarantine theatrical subsystem (SAFETY)
- Quarantine/decommission the theatrical OPC/NDE/IRD/TWP output paths so `:rand.uniform`-shaped physics numbers cannot be produced or consumed (MC-003-M precedent: honest `:unavailable`/`:not_available` surfaces; supervisors retained but internals staged).
- Repair or stage the broken NDE/TWP KeyError paths (nde.ex:336-345, twp.ex:337-340) so no crash + no theater.
- Rollback: restore prior internals.
- Risk: MEDIUM (OTP supervisor wiring must remain bootable).

### MU-4 — Physics ↔ Phase4 bridge + placeholder replacement (INTEGRATION)
- Add a physics experiment-spec adapter so `Phase4.ExperimentOrchestrator.submit_experiment/1` can accept the pilot spec while `:real_execution_enabled` is FALSE → returns `{:error, :real_execution_not_enabled}` (existing MC-003-M behavior).
- Replace ADE's canned gravity/time_dilation placeholder (autonomous_discovery.ex:68) with the pilot experiment spec (or remove it) so no wiring can ever emit a fake experiment.
- Rollback: remove adapter; restore placeholder policy.
- Risk: LOW (dead code today).

## Explicitly NOT in MC-004-M
- All-20-domain metrics de-fabrication (TD-MC001-M5-DOMAINS) — defer to a domain-wide gate.
- Linear algebra module — defer.
- General physics engine, ML/physics-integrated solvers, multi-world simulations — defer.
- Any real experiment execution or `:real_execution_enabled` enablement — MC-004-P only.

## After MC-004-M
MC-004-P runs the bounded pilot per PILOT-DEFINITION under fresh authorization, recording execution vocabulary, verification, and provenance; then independent verification; then MC-004 certification.

## Careful caveat
MU-1 discipline: the RK4 integrator is real math, but it is still only as trustworthy as its tests against analytic truth. The pilot definition's verification (energy bound + analytic reference + reproducibility) is what grants the result its truth claims — the solver alone must not be treated as truth-generating.