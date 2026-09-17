# MC-004-A0 — Consumer Map

**Gate:** MC-004-A0 (Reconciliation) — **Date:** 2026-08-31 — **Mode:** READ-ONLY

## 1. Canonical binding (LIVE)

- `canonical_registry.ex:34` — `:physics` in canonical list (exactly 20 domains).
- `canonical_registry.ex:220` — `domain_module(:physics)` → `Tiannara.Domains.Physics`.
- This is a metadata dependency: dashboards/auditors read the registry; they do not execute physics callbacks.

## 2. AutonomousDiscoveryEngine (DEAD)

`lib/tiannara/asc/autonomous_discovery.ex`:
- `:15` `def run_discovery_cycle/0` — the ONLY occurrence of `run_discovery_cycle` in `lib/` (verifier confirmed). No supervisor, no worker, no GenServer, no test wire invokes it → **dead code**.
- `:16-17` collect metrics → BottleneckDetector pipeline health.
- `:54-62` `collect_domain_metrics/0` calls `module.metrics()` for each registered domain.
- `:65-68` `generate_candidate_experiments/0` HARDCODES a single physics experiment: `%{domain_module: Tiannara.Domains.Physics, hypothesis: %{subject: :gravity, object: :time_dilation, equations: [], boundary_conditions: []}, context: %{}, domain_weight: 1.2}`.
- `:35` `domain_module.simulate(exp.hypothesis, exp.context)` → physics.ex:17 → `{:error, :ode_solver_unavailable}`.
- `:37` `domain_module.validate(%{model: sim_result})` → physics.ex:28 → `{:error, :formal_verification_unavailable}`.
- `:39` `KnowledgeRepresentation.assert_fact` — dead under physics, because the simulate/validate errors short-circuit the `with` before reaching it.

Impact scope: **NONE today** (dead). If ever wired, the gravity/time_dilation "experiment" is a canned placeholder — it must be replaced before any live use, and its firing would currently produce `{:error, :ode_solver_unavailable}` (honest, not fabricated).

## 3. Domain ResearchDirector (UNWIRED)

`lib/tiannara/domains/research_director.ex`:
- `:9` `register_domain/1` — no callers in `lib/` → registry stays empty.
- `:21` `get_all_metrics/0` — returns `%{}` for the empty registry.
- Impact: no aggregated domain metrics flow anywhere from physics (or from the other 19 domains) through this path.

## 4. Real-execution / provenance consumers (ABSENT)

- Zero references to `RealExecution`, `Phase4`, or `Provenance` in `lib/tiannara/physics/**` and `lib/tiannara/domains/**` (verifier check).
- `Phase4.ExperimentOrchestrator.submit_experiment/1` (the MC-003-M gated real-execution gateway) is never called by physics; physics is not a producer to it.
- `Tiannara.Evidence.Provenance` (REAL substrate) has no physics caller; no physics result would be provenance-carrying.

## 5. LiveView / observability (LIVE, metadata-only)

- Dashboard surfaces read registry metadata + elected metrics via the ASC-facing registries; they do not invoke physics callbacks.
- Consequence: dashboards cannot propagate theatrical physics numbers — GOOD isolation, but also means no observational check on physics truth.

## 6. Independent consumers (not consumers of `Domains.Physics`)

- `lib/tiannara/os/world_epistemic_physics.ex` — derived epistemic computations, independent of the domain module.
- `lib/tiannara/desc/research/programs/transfer_physics_program.ex` — research program definition; does not execute physics callbacks.

## 7. Conclusions

1. No LIVE production path consumes physics capability → today's physics truth/falsity has **zero autonomous-decision influence**.
2. The only consuming code is dead (`run_discovery_cycle`) and its experiment is a canned gravity/time_dilation placeholder that must be replaced with the pilot model before any wiring (MC-004-M/MC-004-P).
3. Physics is fully disconnected from real execution and provenance.
4. Therefore the reconciliation verdict for consumers: **LIVE metadata only; capability consumers DEAD/UNWIRED/ABSENT**.