# MC-003-A0 — Real Execution Bottleneck Analysis

**Gate:** MC-003-A0 (Observational; every bottleneck carries repository evidence)
**Status:** COMPLETE
**Date:** 2026-08-29

Priorities: CRITICAL / HIGH / MEDIUM / LOW. Ranked by impact on the goal of a
truthful, real, supervised, reusable execution capability.

---

## CRITICAL

**B1. Fabricated-execution theater is live in the runtime (epistemic integrity).**
The only runtime-supervised sandbox fabricates outcomes
(`Tiannara.Sandbox` sandbox.ex:217-218, 226-228; wired sentinel/supervisor.ex:40);
`ExecutiveCycle` posts `status: :executed` to a blackboard (executive_cycle.ex:145-159);
CEL constant steps persist fake science to knowledge paths (experiment.ex:49-57 →
knowledge_coordinator.ex:194, knowledge_flow_pipeline.ex:144,157);
`VerificationAuthority` hardcodes PASS (verification_authority.ex:75-91);
`CertificationServer` pre-opens gates (certification_server.ex:41-46).
**Consequence:** claims of verified/executed/certified work exist in the system
today with no real work behind them → R0 fabricated-evidence loop still OPEN
(TIANNARA_REMEDIATION_MATRIX.md:9; P16-AT(e) unmet).

**B2. Execution boundary broken — no supervised path from authorized intent to real work.**
`Approval.decide` has no caller (activation/approval.ex:44-49; only propose at
activation/engine.ex:72); the P16 gateway `Phase4.ExperimentOrchestrator.submit_experiment`
has zero production callers and is not supervised (service_registry.ex:287-301);
`SelfImprovement.Pipeline.request_deployment` authorizes but nothing executes
(pipeline.ex:46-52). **Consequence:** even with real authorization + real
harness machinery, nothing connects them → the chain breaks at EXECUTION.

**B3. Autonomous loops report success from fabricated data (harm to decision-making).**
`ConstitutionalAutonomy` (constitutional_autonomy.ex:105-136) gates on
fabricated `SimulationManager` baselines (`:rand.uniform` memory/throughput,
simulation_manager.ex:76,63-70), deploys via status flip
(deployment_pipeline.ex:112-120), rollback is `:timer.sleep(10)`
(rollback_engine.ex:67-72); `ASC.Repair` claims canary/rollout with no work
(pipeline.ex:34,40,46). **Consequence:** the system can log `deployed: N`,
`:deployment_monitoring`, and Phase-H success for events that never happened.

## HIGH

**B4. Independent execution-outcome verification is unavailable in the runtime.**
No module independently confirms an executed side effect: runtime verifiers are
theatrical (B1), external HTTP is a stub (stubs/httpoison.ex:4-6), CI provider
unwired (`:ci_not_configured`, live_pipeline.ex:106-115). **Consequence:**
ATTEMPTED/COMPLETED/VERIFIED are indistinguishable (VERIFICATION artifact);
P16-AT(c) cannot be met while fabricating ancestors remain.

**B5. The one real execution engine is disconnected.**
`SelfImprovement.Sandbox` real backends + `RealHarness` — the only genuine
build/test/benchmark verification with timeouts and teardown (backend/local.ex:20-137;
real_harness.ex:13-54) — are reachable only from dry-run utilities
(self_improvement/dry_run.ex:47; omega/dry_run.ex:102).
**Consequence:** real capability exists but is comatose; safety-by-disconnection.

**B6. Uncertainty is not evidence-derived.**
`confidence_delta: if(outcome == :supported, do: 0.1, else: 0.0)`
(discovery_scheduler.ex:178) — fixed constant, not derived from evidence
distributions → P16-AT(d) unmet; discovery loop's measurements are not used to
calibrate its own uncertainty.

**B7. Dead orchestrator with adoption cost.**
`ExperimentOrchestrator` (phase4/experiment_orchestrator.ex) and
`AutonomousResearchEngine` are fully built, registered as ExecutiveServices
(service_registry.ex:287-301), but unsupervised and uncalled.
**Consequence:** P16-AT(b) ("≥1 experiment executed exclusively via
submit_experiment") cannot be demonstrated; builds dead weight.

## MEDIUM

**B8. External reality sensing is self-referential.**
`ProductionObservatory` (production_observatory.ex:46,67,92) reads a repo-local
HTTPoison stub (stubs/httpoison.ex:4-6). **Consequence:** "external reality"
claims are internal fiction; any consumer of these readings is deceived.

**B9. Reliability gaps in the execution plane.**
- Stale-execution detection: **MISSING** (heartbeats are cycle clocks,
  sentinel/heartbeat/server.ex:54-88; research/heartbeat.ex reports untruth
  `:awaiting_experiment` with no staleness supervision).
- Cancellation/rollback theatrical in autonomy (rollback_engine.ex:67-72);
- Deterministic replay **NO** (multi_world seeds via `:crypto.strong_rand_bytes`,
  domain.ex:20; sandbox :rand :227);
- Idempotency primitives exist (deployment_registry.ex:11-37; workflow
  `:idempotent_retries`) but none guard the runtime deploy paths.

**B10. ToolForge / SOPL / REA seeds claim execution without it.**
`ToolBuilder.do_execute` returns `{:implemented, input}` (tool_builder.ex:123-126,
`tools_deployed: 0`); `SOPL.EvolutionEngine.deploy` logs only
(evolution_engine.ex:65-70); REA intervention seeds pre-baked
`status: :completed` + `actual_effect` (intervention.ex:79-80).
**Consequence:** consumers of ToolForge "implementations", evolved laws, and
intervention effects read fabricated completion.

## LOW

**B11. RuntimeAtlas/tooling doc strings** for non-existent subsystem supervisors
(documented follow-up, no runtime impact — carried from MC-002-M
`TD-MC002-M-RUNTIME_ATLAS`).

**B12. `CEL.Scheduler` stub** (cel/scheduler.ex:12-23) — no scheduling occurs in
a component named Scheduler; `healthy?` always true. Documented here as low
because scheduling is dispatched by the discovery timer / boot loop today.

## Ranking summary

| Rank | ID | Bottleneck |
|------|----|-----------|
| 1 | B1 | Fabricated-execution theater live (integrity) |
| 2 | B2 | Execution boundary broken (no authorized→real path) |
| 3 | B3 | Autonomous loops report success from fabricated data |
| 4 | B4 | Independent outcome verification unavailable |
| 5 | B5 | Real execution engine disconnected |
| 6 | B6 | Uncertainty fixed, not evidence-derived |
| 7 | B7 | Dead orchestrator (P16-AT(b) unmet) |
| 8 | B8 | External sensing self-referential |
| 9 | B9 | Reliability gaps (staleness/cancel/replay/idempotency) |
| 10 | B10 | ToolForge/SOPL/REA claim execution without it |