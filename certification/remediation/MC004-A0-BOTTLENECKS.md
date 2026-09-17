# MC-004-A0 — Bottlenecks

**Gate:** MC-004-A0 (Reconciliation) — **Date:** 2026-08-31 — **Mode:** READ-ONLY
Ranked by impact on producing ONE truthful, provenance-bearing, verifiable physics result (the constitutional criterion).

## B-1 — No real ODE/integrator substrate (CRITICAL)
- `lib/tiannara/foundations/mathematics/calculus.ex:4-5` — `solve_ode/3` returns `{:error, :ode_solver_unavailable}` (decommissioned MC-001-M).
- No RK4/Euler/integrator primitive anywhere in `lib/` (grep `rk4|ode45|numeric.*integrat|integrate_ode` → single hit: the stub itself via physics.ex:18).
- `Tiannara.Numerics` (numerics.ex) provides error modes/interpolation — genuinely real but **no ODE steps**.
- Impact: the canonical domain *cannot compute dynamics at all*. This is the **#1 blocker** for the pilot.

## B-2 — No real verification substrate (CRITICAL)
- `lib/tiannara/foundations/formal_verification.ex:4-5` — `verify_invariants/2` → `{:error, :formal_verification_unavailable}`.
- Physics contract wants conservation-of-energy / thermodynamics checks (physics.ex:28), with no solver available.
- Impact: no result can be verified independently; verification is the second element of the constitutional criterion.

## B-3 — Theatrical supervised subsystem (HIGH)
- `physics/opc.ex:472-475` (rand coin flips), `:576-577` (canned 0.98 determinism, random compile time), `physics/ird.ex:483` (`:rand.uniform() * 0.5 + 0.3`), `:595` (coin flip), `physics/nde.ex:344-345` (aggregates theatrical ETS), `physics/twp.ex:411` (canned 0.5 probability).
- NDE/TWP broken KeyError paths (`nde.ex:336-345`, `twp.ex:337-340`) can crash on absent state.
- Impact: a large supervised surface *makes physics-shaped numbers* that must never be mistaken for capability; must be quarantined before any pilot so provenance stays clean.

## B-4 — No provenance path (HIGH)
- Zero `Provenance` references across `lib/tiannara/physics/**` and `lib/tiannara/domains/**`; `Evidence.Provenance` is real but disconnected.
- Impact: even a computed result could not today carry the provenance that the constitutional criterion requires.

## B-5 — Real-execution integration disconnected (HIGH)
- Zero `RealExecution`/`Phase4` references in physics/domains dirs; the MC-003-M gateway exists but physics has no producer/bridge.
- Impact: observation/execution element of the criterion is absent.

## B-6 — Dead consumer path with placeholder experiment (MEDIUM)
- `autonomous_discovery.ex:15` `run_discovery_cycle` has zero callers; its only physics experiment is a hardcoded gravity/time_dilation placeholder (`:68`).
- Impact: no decision impact today (protective), but wiring it now without a real model would misroute; the placeholder must be replaced by the pilot spec before any wiring.

## B-7 — Domain-wide metrics fabrication debt (MEDIUM, deferred)
- `TD-MC001-M5-DOMAINS`: 19/20 canonical domains may fabricate nonzero metrics. Physics itself is truthful-zero (physics.ex:37-49). Out of MC-004 scope; needs a domain-wide gate.

## B-8 — No linear algebra (MEDIUM, deferred)
- No linear algebra module exists in `lib/`. Not strictly required for the damped-oscillator pilot (scalar RK4), but a general-physics prerequisite. Keep deferred; do not build here.

## B-9 — Protection/audit absent on physics surfaces (MEDIUM, latent HIGH)
- simulate/validate are ungated, unsandboxed, timeout-less, un-audited (see SAFETY-EXECUTION). Safe today only because dead/disconnected.

## Ordering for MC-004-M
B-1 (real RK4) and B-2 (structural verification, NOT SMT) are the hard prerequisites for the pilot. B-3 quarantine precedes pilot so output is untarnished. B-4 provenance attach and B-5 bridge adapter are publishability prerequisites. B-6 placeholder replacement is needed before any live wiring. B-7/B-8 deferred.