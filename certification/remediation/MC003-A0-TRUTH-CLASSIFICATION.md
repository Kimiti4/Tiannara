# MC-003-A0 — Real Execution Truth Classification

**Gate:** MC-003-A0 (Observational)
**Status:** COMPLETE
**Date:** 2026-08-29

Taxonomy: REAL / PARTIAL / THEATRICAL / FABRICATED / UNKNOWN / NO.

- **REAL** = observable side effect (filesystem/subprocess/container/network/
  durable store) or genuine measurement with provenance.
- **PARTIAL** = some honest component exists but is unwired, input-seeded,
  incomplete, or mixed with fabricated content.
- **THEATRICAL** = returns success/status as if executing without performing the work.
- **FABRICATED** = invents data/metrics/results that were never observed.
- **UNKNOWN** = insufficient source evidence.
- **NO** = capability absent.

## Capability matrix

| Capability | Classification | Evidence (file:line) | Consumer | Risk |
|---|---|---|---|---|
| `SelfImprovement.Sandbox.Backend.Local` real subprocess build/test/bench | REAL | backend/local.ex:20-137 (System.cmd + Task.async/yield + brutal kill + teardown) | only DryRun (self_improvement/dry_run.ex:47; omega/dry_run.ex:102) | HIGH (unwired real capability) |
| `SelfImprovement.Sandbox.Backend.Container` real isolated execution | REAL | backend/container.ex:25-35 (`--network none`, limits, kill) | same dry-runs | HIGH (unwired) |
| `SelfImprovement.Sandbox.RealHarness` real eval loop | REAL | real_harness.ex:13-54 | same dry-runs; sandbox_* tests | HIGH (unwired) |
| `ASC.Adoption.Adopter` real git+compile+snapshot+record | REAL | asc/adoption/adopter.ex:140-305; gate.ex:8-52 | Mix.Tasks.Asc.Adopt (manual) | MEDIUM (manual, two-key) |
| `ASC.Reality.RealityBridge` / `RealityAnchoredCampaign` real subprocess | REAL (intelligence fabricated) | reality_bridge.ex:23-103; reality_anchored_campaign.ex:38-111 | one-shot phase, manual-role | MEDIUM |
| `ASC.CMissions.runner*` real git/mix subprocess | REAL | asc/c_missions/runner.ex:44,276 | mission tooling | LOW |
| `Discovery.Steps.ExperimentStep` genuine world-model measurement | REAL (inputs seeded) | steps/experiment_step.ex:54-108 | Discovery Loop B via WorkflowEngine | MEDIUM (seed provenance explicit) |
| `Discovery.Steps.ValidationStep` genuine validation | REAL | steps/validation_step.ex:38-63 | Discovery Loop B | MEDIUM |
| `Sentinel.ObservationScheduler` BEAM introspection | REAL (internal only) | sentinel/observation_scheduler.ex:101-130 | sentinel health | LOW |
| `CEL.WorkflowEngine` saga plumbing (retry/compensation/persist/event) | REAL (plumbing) — dispatches T9 constant steps | cel/services/workflow_engine.ex:463-809 | discovery/governance workflows | HIGH (content fed is fabricated) |
| `WorldStateSynchronizer` integration of discovery into world model | REAL | world/world_state_synchronizer.ex:84,216,245-277 | world model | MEDIUM |
| `Research.KnowledgeIntegrator` :real_execution gate | REAL (gate) | research/knowledge_integrator.ex:88-89,118 | no real feed today | MEDIUM |
| `Research.ResearchDirector.Pipeline` plan pipeline | REAL (execution quarantined) | research/research_director.ex:126,146-159 | discovery/research | LOW (R0-safe) |
| `Evidence.Provenance`+`CertificationGate` provenance enforcement | REAL | evidence/provenance.ex:16,34,89,116-117; certification_gate.ex:27-49 | evidence acceptance | LOW**
| `Tiannara.Sandbox` runtime sandbox | THEATRICAL** | sandbox.ex:217-218,226-228,247-251; wired sentinel/supervisor.ex:40 | Sentinel Activation (propose-only) | **CRITICAL** (fabricated outcomes from trusted step) |
| `Autonomy.ConstitutionalAutonomy` self-improvement loop | THEATRICAL (randomness-driven) | autonomy/constitutional_autonomy.ex:105-136; simulation_manager.ex:76,63-70 | — | **CRITICAL** (believes it improved/deployed) |
| `Autonomy.SimulationManager.measure_baseline` | FABRICATED | simulation_manager.ex:75-77 (`:rand.uniform(200)` latency, `:rand.uniform(2000)` throughput) | ConstitutionalAutonomy verdict | **CRITICAL** |
| `Autonomy.DeploymentPipeline` deploy/checkpoint | THEATRICAL | deployment_pipeline.ex:112-120 (stage flip + fake checkpoint), :66-68 | ConstitutionalAutonomy | **CRITICAL** |
| `Autonomy.RollbackEngine.execute_rollback` | THEATRICAL | rollback_engine.ex:67-72 (`sleep(10)` → `{true, fake}`) | rollback flows | HIGH |
| `ASC.Repair.Pipeline` (SandboxValidator/CanaryReleaser/ProductionRollout) | THEATRICAL (false success) | asc/repair/pipeline.ex:34,40,46 | Phase H repair | **CRITICAL** (claims live traffic changes) |
| `ASC.Reality.DigitalDeploymentManager` | THEATRICAL | digital_deployment_manager.ex:26-40 (all steps :completed) | ASC reality phases | HIGH |
| `ASC.Reality.PhysicalDeploymentManager` + `SimulatedAdapter` | THEATRICAL (default simulated) | physical_deployment_manager.ex:36,260-283; simulated_adapter.ex:57-71 | ASC reality | HIGH |
| `ExecutiveCycle` execute/validate | THEATRICAL | executive/cognitive/executive_cycle.ex:145-159 (status :executed to blackboard; all valid) | Executive Cognitive Runtime (Loop A) | **CRITICAL** (Loop A live) |
| `CEL.Workflow.Steps.{Observation,Experiment,Validation}` | FABRICATED (constant/hardcoded) | steps/experiment.ex:49-57; observation.ex:55-57; validation.ex:46-53 | knowledge_coordinator.ex:194; knowledge_flow_pipeline.ex:144,157; phase4 dead engines | **CRITICAL** (persists fake science) |
| `Phase4.ExperimentOrchestrator.submit_experiment` | NO (zero callers; registered only) | phase4/experiment_orchestrator.ex; service_registry.ex:287-301 | — | HIGH (P16-AT(b) unmet) |
| `Omega.DeploymentGateway.deploy` | THEATRICAL (status flip) | omega/patch_generator/candidate.ex:103-108 | only test scenarios.ex | HIGH |
| `VerificationAuthority` independent verification | THEATRICAL | verification_authority.ex:75-91 (reproduction 0.95, regression all passing, compliance 14 clauses hardcoded) | engineering proposal workflow | **CRITICAL** (no proposal can fail) |
| `Omega.CertificationServer` certification | THEATRICAL | omega/certification_server.ex:41-46 (gates pre-set :gate_open) | EventBus subscribers | **CRITICAL** (decorative certification) |
| `Agency.Sandbox` | FABRICATED | agency/sandbox.ex:13-19 (`0.6+:rand*0.3` success) | research director path | HIGH |
| `SOPL.EvolutionEngine.deploy` | THEATRICAL (log-only) | sopl/evolution_engine.ex:65-70 | none external | LOW |
| `ToolForge` tool execution | NO | tool_forge/tool_builder.ex:123-126 (`{:implemented, input}` stub); tool_forge_engine.ex (`tools_deployed: 0`) | none | MEDIUM |
| `OS.Governance.DeploymentOrchestrator` RFC deployment | THEATRICAL | os/governance/deployment_orchestrator.ex:482-498,479,521,411 | TiannaraOS governance (unbooted) | MEDIUM |
| External reality sensing (ProductionObservatory) | PARTIAL→THEATRICAL (self-referential) | reality/production_observatory.ex:46,67,92 + stubs/httpoison.ex:4-6 | reality anchoring | HIGH |
| `ASC.Agency.Orchestrator` mocked cycle | THEATRICAL | asc/agency/orchestrator.ex:27-35 | dyn dispatcher | MEDIUM |
| REA Intervention pre-baked completed seeds | FABRICATED | rea/intervention.ex:79-80 | intervention ledger | MEDIUM |
| Human-approval→execution connection (`Approval.decide`) | NO (never called) | sentinel/activation/approval.ex:44-49; only propose at activation/engine.ex:72 | Sentinel Activation | **CRITICAL** (gate unwired) |
| Independent verification of executed outcomes (runtime) | NO | see VERIFICATION artifact | all | **CRITICAL** |
| Execution-scheduler with real queue/scheduling | UNKNOWN→NO (CEL.Scheduler stub) | cel/scheduler.ex:12-23 (stub, healthy? true) | executive bus | MEDIUM |
| Stale-execution detection | NO | no execution staleness monitor (heartbeats are cycle clocks) | — | MEDIUM |
| Determinism/replay of executions | NO | simulation/multiworld/domain.ex:20 (`:crypto.strong_rand_bytes` seed); no exec replay store | — | MEDIUM |
| P16 orchestrator wiring (submit_experiment as sole gateway) | NO | P16-AT: certification/TIANNARA_PHASE16_EXECUTION_AUDIT.md:77 | P16 gate | **CRITICAL** (P16-AT(b) unmet) |
| Uncertainty from evidence distributions | NO (fixed ±0.1) | discovery_scheduler.ex:178 (`confidence_delta: if(outcome==:supported, 0.1, 0.0)`) | discovery results | HIGH (P16-AT(d) unmet) |
| Loop A unreachability (P16-AT(e)) | THEATRICAL (Loop A still live) | executive_cognitive_runtime.ex:82; executive_cycle.ex:145-159; sandbox.ex:226-228 | Loop A | **CRITICAL** |

## Counts (production classifications)

- REAL: 14 (B1..B9 subset 7 + M1..M8 subset 7)
- PARTIAL: 1 (external sensing)
- THEATRICAL: 16
- FABRICATED: 6
- UNKNOWN: 0 (source evidence suffices for the judgments reached)
- NO: 9

## Inflation checks (execution reality vs claim)

- **`deployed: N` / `stage: :monitoring`** (DeploymentPipeline, Reality DeploymentPipeline deployments) is a status field, not a deployment.
- **`status: :executed` / `success: true`** (ExecutiveCycle, ASC reality macrories) is a blackboard write, not execution.
- **`{:ok, :pass}`, `:canary_deployed`, `:rolled_out`, `:completed` steps** (ASC.Repair, DigitalDeploymentManager) carry no side effect.
- **A certificate with all gates `:gate_open`** (CertificationServer) is decoration, not certification.
- **`{:ok, 200, ""}` from a repo-local HTTPoison stub** is not external observation.
- **`:rand.uniform` success probabilities** (Tiannara.Sandbox, Agency.Sandbox, SimulationManager) are fabrication, not execution or verification.
- **`Research.ResearchDirector` quarantine** is the ONE honest boundary: it executes nothing and records that (R0-safe, LOW risk).

## Critical-safety interpretation (protocol §12)

The autonomous paths that claim success without execution feed discovery/self-
improvement/repair/autonomic decision-making → classified THEATRICAL with
proven consumers documented in the CONSUMER-MAP and MUTATION-PLAN artifacts.
Per protocol, a false success response is NOT preserved merely for
compatibility; the mutation candidates convert these to explicit unavailable/
error boundaries with consumer impact documented.