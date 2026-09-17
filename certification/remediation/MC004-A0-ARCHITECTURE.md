# MC-004-A0 — Architecture

**Gate:** MC-004-A0 (Reconciliation) — **Date:** 2026-08-31 — **Mode:** READ-ONLY

## 1. Layered view (as-built, evidence-backed)

```
┌─ Consumers
│   • CanonicalRegistry metadata   (LIVE, read-only)            canonical_registry.ex:34,220
│   • AutonomousDiscoveryEngine    (DEAD)                       autonomous_discovery.ex:15
│   • Domains.ResearchDirector     (UNWIRED, empty registry)    research_director.ex:9,21
│   • LiveView dashboards          (metadata only)
├─ Domain layer
│   • Tiannara.Domains.Physics     (honest-empty / NO caps)     domains/physics.ex:9-49
│      behaviour Tiannara.Domains.Domain                        domains/domain.ex:17-24
├─ Substrate layer (consumed by domain)
│   • Probability  REAL           math/probability.ex
│   • Statistics   REAL           math/statistics.ex
│   • Graphs       REAL           math/graphs.ex
│   • Numerics     REAL (bounded) numerics.ex
│   • Calculus     NO             foundations/mathematics/calculus.ex:4-5
│   • FormalFV     NO             foundations/formal_verification.ex:4-5
│   • Optimization NO             math/optimization.ex:9,15
│   • InfoTheory   REAL           foundations/information_theory.ex:8,15
│   • Logic kernel REAL, unused   lib/tiannara/logic/*
│   • Linear alg.  NO             (nonexistent)
├─ Disconnected subsystem (theatrical)
│   • Tiannara.Physics.OPC/NDE/IRD/TWP  physics/opc.ex, nde.ex, ird.ex, twp.ex (+ subdirs)
│   • Supervised by physics/supervisor.ex
│   • NOT referenced by domain module or discovery pipeline
└─ Orthogonal infrastructure (unused by physics)
   • Evidence.Provenance          evidence/provenance.ex   (REAL, no physics reference)
   • Phase4.ExperimentOrchestrator (MC-003-M gated gateway; no physics producer)
   • :real_execution_enabled      FALSE
```

## 2. Data flow reality

1. Registry binds `:physics→Tiannara.Domains.Physics` (snapshot). Nothing passes mutable state into the domain module; all callbacks are pure (`physics.ex`).
2. `simulate→solve_ode` returns honest `{:error, :ode_solver_unavailable}`; `validate→verify_invariants` returns honest `{:error, :formal_verification_unavailable}` (calculus.ex:5, formal_verification.ex:5).
3. The theatrical subsystem holds ETS state (`nde.ex:82-102` chaos stats ETS; TWP temporal ETS) and answers via GenServers (`nde.ex:48-49`, `twp.ex:48-49`). Its numbers are random/hardcoded (opc.ex:472-475, ird.ex:483/595).
4. No edge connects subsystem → domain → real-execution → provenance.

## 3. Architectural findings

| # | Finding | Severity |
|---|---|---|
| A | Pure honest domain module sits atop an incomplete substrate (no ODE, no FV, no linear algebra) — physics is architecturally non-computable today. | CRITICAL |
| B | A fully supervised theatrical twin (`Tiannara.Physics.*`) exists parallel to the real-but-empty domain module; duplication + fabrication risk. | HIGH |
| C | Real-execution + provenance + Phase4 gate are architected orthogonally and were correctly walled off from live use (MC-003-M) — but physics has no adapter to them at all. | HIGH |
| D | The only consumer path (ADE) is dead; wiring it live today would emit honest errors, but its placeholder experiment (`autonomous_discovery.ex:68`) is not a real physics model. | MEDIUM |
| E | The 0.98/0.5/0.8 threshold constants in the subsystem create a misleading "calibrated physics" appearance. | MEDIUM |
| F | `metrics_source: :state_derived` (physics.ex:48) is an honest label but there is no independent re-derivation mechanism for other domains. | MEDIUM |

## 4. Design recommendations (for MC-004-M, NOT executed)

1. Keep the domain module as the single canonical physics surface; decommission or quarantine theatrical subsystem internals so no physics-shaped fabricated number remains supervised (MC-003 pattern).
2. Add the missing substrate primitives the pilot needs (bounded RK4 integrator; structural/analytic-reference checks) as REAL math, tested against analytic solutions.
3. Give physics results a provenance attachment path (reuse `Evidence.Provenance`) and an explicit bridge to the Phase4 gateway when authorized.
4. Replace the canned ADE experiment with the pilot experiment spec before any wiring (MC-004).
5. Do NOT build a generalized physics engine; scope to `:physics` canonical domain only.