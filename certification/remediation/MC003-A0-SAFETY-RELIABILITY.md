# MC-003-A0 — Real Execution Safety & Reliability Assessment

**Gate:** MC-003-A0 (Observational)
**Status:** COMPLETE
**Date:** 2026-08-29

Every control is classified REAL/PARTIAL/THEATRICAL/UNKNOWN/MISSING with
file:line. "Enforced vs documented" is the deciding test.

---

## 1. Safety / authorization around execution

| Control | Class | Evidence |
|---------|-------|----------|
| Deploy gateway (certification + lineage + constitutional gates + matching unexpired grant) | **REAL enforcement** — but no production caller routes a real deploy through it | omega/deployment_gateway.ex:1-45 |
| Human authorization grant state machine (`:prepared → :pending_authorization → granted/denied/expired`, TTL, explicit human mint) | **REAL** — but nothing mints grants today | omega/human_delivery/authorization.ex:10-43; human_augmentation_delivery.ex:17-23 |
| Governance gate holding improvements pending human auth | **REAL** | omega/governance_gate_server.ex:1-45 |
| Council authorization for kernel operations | **REAL** — check-then-execute inside kernel | council/kernel.ex:87,99 |
| KnowledgeCoordinator human approval for high-impact promotion | **REAL** | knowledge_coordinator.ex:173-178 |
| Sentinel Activation human-decision execution step (`Approval.decide`) | **UNWIRED** — propose called (activation/engine.ex:72), decide has **no caller** | sentinel/activation/approval.ex:44-49 |
| ASC two-key adoption (machine evidence + human artifact) | **REAL** — Mix-task-exposed only | asc/adoption/gate.ex:8-52; adopter.ex |
| DeploymentPipeline / autonomy "approval" | THEATRICAL — status fields only, no exec behind approval | autonomy/deployment_pipeline.ex:24,55-81 |
| Sandboxing (runtime) | THEATRICAL — `Tiannara.Sandbox` simulates outcomes, no isolation | sandbox.ex:216-245 |
| Sandboxing (real, unwired) | REAL — throwaway workdir + container `--network none`, nothing reachable | sandbox/backend/local.ex:20-37; container.ex:25-35 |
| Resource limits | REAL where they exist — RealityDirector `max_concurrency 50`/kill-on-timeout (:38-56); `Tiannara.Sandbox @max_concurrent 5` (:18); supervisor restart bound | reality_director.ex:38-56; sandbox.ex:18; omega_runtime.ex:76 |
| Audit trail / provenance of execution | REAL infrastructure (append-only event_store, deployment_registry log, adoption .eterm, resilient_dets); content often simulated | executive/event_store.ex; deployment_gateway/deployment_registry.ex:11-37; adopter.ex:268-295 |
| Human approval where required for real deployments | PARTIAL — hard gates exist but live equ bridge never calls them (auto-`:artifact_only` mode) | config/config.exs:133-134 |

**Bottom line (section 1):** The authorization machinery is unusually real and
well-placed — but it is disconnected from any live execution path. No approved
proposal reaches real work through the supervised runtime today.

## 2. Reliability feature table

| Feature | Rating | Evidence |
|---------|--------|----------|
| Timeout | REAL | reality_director.ex:24-35 (`Task.yield`/`shutdown(:brutal)`, @60s); adopter.ex:219-225 (compile/test/boot timeouts + watchdog `System.halt(1)` :236-239); sandbox tick cycle cap (sandbox.ex:18-19); simulation_engine.ex:55,59 (30s call) |
| Process-crash handling | REAL | supervisor restart bounds (omega_runtime.ex:76 max 3; executive/supervisor.ex max 10/60s; simulation_supervisor.ex max 5/60s); event_bus retry DLQ (event_bus.ex:230-238) |
| Partial execution | PARTIAL | workflow compensation + compensation_log (workflow_engine.ex:713-761); sandbox rollback is no-op (sandbox.ex:247-251) |
| Retries | PARTIAL | workflow step retry with backoff (workflow_engine.ex:614-676,786-789); world_state_synchronizer retry/backoff/DLQ (:112-138); event_bus retries (:230-238); deployment_gateway lock retry (:130) |
| Idempotency | PARTIAL | DeploymentRegistry replay protection REAL (deployment_registry.ex:11-37); workflow `:idempotent_retries` (workflow_engine.ex:61); DedupLedger (constitution/registry.ex:149) — none on runtime deploy paths |
| Duplicate-execution prevention | PARTIAL | as idempotency; no global execution-id tie-breaker in runtime loops |
| Cancellation | PARTIAL | Task brutal kill (reality_director.ex:27); sandbox cancel (rollback theatrical) (sandbox.ex:62-64,136-150); no cancel propagation in autonomy loops |
| Stale execution detection | **MISSING** | heartbeats are cycle clocks only (sentinel/heartbeat/server.ex:54-88; executive/cognitive/heartbeat_engine.ex:44-57); `research/heartbeat.ex` reports `:awaiting_experiment`/`:not_executed` truthfully; **no detector monitors a running execution's liveness** |
| Result persistence | REAL | DETS (resilient_dets.ex), event_store.ex:1-55, workflow DETS persist (workflow_engine.ex:765-789), discovery result store |
| Provenance | REAL vessel | evidence/provenance.ex; event_store lineage; deployment_registry log |
| Recovery | PARTIAL | interrupted-workflow recovery (workflow_engine.ex:791-809); resilient_dets quarantine; adoption file+git-tag rollback REAL (adopter.ex:297-305); autonomy rollback THEATRICAL (rollback_engine.ex:67-72) |
| Deterministic replay | **NO** | no replay store for executions; seeds non-deterministic (multi_world domain.ex:20 `:crypto.strong_rand_bytes`; sandbox :rand :227; statistical_benchmark no fixed seed) |

## 3. Config / env toggles gating real execution

| Toggle | Value | Effect | Evidence |
|--------|-------|--------|----------|
| `:asc enabled` | true | boots ASC reality/repair trees into artifact-only mode | config/config.exs:133-134 |
| `:deployment_mode` | `:artifact_only` | deployment managers run simulated (DigitalDeploymentManager all-`:completed`), hardcoded stub in asc/deployment/civilization.ex:39 | config/config.exs:134; civilization.ex:39 |
| `:dets_lazy_init` / dets_base_path | per env | real DETS I/O; default true | config/config.exs:9,12-19 |
| NATS/JetStream | configured | messaging substrate (not examined for reachability here) | config/config.exs:38-63 |
| `deployment_enabled` (SelfImprovement) | **false by default** | `request_deployment` explicit never-authorizes by default; only DryRun/constitution self-tests set true | pipeline.ex:47; dry_run.ex:97 |
| CI provider | absent | `:ci_not_configured` | live_pipeline.ex:106-115 |
| `audit_log_enabled` | true (dev) | real DETS audit writes | config/dev.exs:65 |

## 4. Safety verdict

The system is safe from accidental external harm largely **because no real
execution is wired**: the side-effecting bridges are either disabled
(`deployment_enabled: false`), manual (adoption Mix task), or dry-run scoped.
Yet that same property means the advertised autonomous self-improvement/deploy/
repair capabilities are simulated — the CRITICAL truth problem. Safety-by-
disconnection is not capability; correctness demands either a real, gated,
supervised execution stage (P16) or a truthful unavailable state everywhere a
simulated success is today.