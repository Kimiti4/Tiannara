# MC-003-A0 — Real Execution Capability Inventory

**Gate:** MC-003-A0 (Observational, read-only)
**Status:** COMPLETE
**Date:** 2026-08-29

Every execution-related component found in `lib/`, grouped by kind. Every claim
carries file:line. Classification (REAL/PARTIAL/THEATRICAL/FABRICATED/UNKNOWN/NO)
is given in the Truth Classification artifact; this file is the raw catalogue.

---

## 1. Real side-effecting execution bridges (reachable)

| # | Component | Side effect | Reachability | Evidence |
|---|-----------|-------------|--------------|----------|
| B1 | `Tiannara.SelfImprovement.Sandbox.Backend.Local` | real `System.cmd` build/tests/benchmark on a throwaway copy in `System.tmp_dir!`, real `patch -p1`, `Task.yield` + `Task.shutdown(:brutal_kill)` timeouts, `:os.rm` teardown | **only** `SelfImprovement.DryRun` / `Omega.DryRun` (library callers); **never from a supervised runtime path** | `lib/tiannara/self_improvement/sandbox/backend/local.ex:20-137`; callers `self_improvement/dry_run.ex:47`, `omega/dry_run.ex:102` |
| B2 | `...Sandbox.Backend.Container` | ephemeral container, `--network none`, CPU/memory limits, wall-clock kill, injectable command runner | only via dry-run callers above | `sandbox/backend/container.ex:25-35` |
| B3 | `...Sandbox.Backend.CI` | delegates to injectable CI client (GitHub Actions REST contract implemented) | **never wired**: no config, no provider; `:ci_not_configured` default | `sandbox/backend/ci.ex:1-28`; `lib/tiannara/omega/ci_wiring.ex:34-112`; `omega/live_pipeline.ex:106-115` |
| B4 | `...Sandbox.RealHarness` | real baseline→patch→build→test→benchmark loop, verdict gate | only dry-run callers (B1 above) and `test/tiannara/self_improvement/sandbox_*_test.exs` | `sandbox/real_harness.ex:13-54` |
| B5 | `ASC.Adoption.Adopter/Gate` | real git checkout, `mix compile/test`, file snapshots, rollback git tag, `System.halt(1)` watchdog, `.eterm` adoption record | **only** `Mix.Tasks.Asc.Adopt` (manual, two-key human+machine gate) | `asc/adoption/adopter.ex:140-305`; `asc/adoption/gate.ex:8-52`; `lib/mix/tasks/asc.adopt.ex` |
| B6 | `ASC.Reality.RealityBridge` + `RealityAnchoredCampaign` | real git clone/commit/push, `mix deps.get/compile/test/run`; campaign = real sandboxed patch→compile→test→benchmark→commit | one-shot named **phase** (`asc/civilization_runner.ex:14`), manual-role; "agentic" patch content is hand-authored (`reality_anchored_campaign.ex:88-111`) | `asc/reality/reality_bridge.ex:23-103`; `asc/reality/reality_anchored_campaign.ex:38-81`; `base_reality/workspace.ex:20-27` |
| B7 | `ASC.Missions.runner{,_v2,_v3}` + worktree/verification/infrastructure | real git/mix subprocesses | mission tooling only | `asc/c_missions/runner.ex:44,276`, `c_missions/*` |
| B8 | `ASC.Implementation.Compiler` | real compile/test | via `asc/implementation/civilization.ex:89` (mission path) | `asc/implementation/compiler.ex:109,132` |
| B9 | `Tiannara.CertificationFramework` (Phase machinery) | real `git rev-parse` and subprocess | certification harness | `certification_framework.ex:321,364` |

## 2. Real internal measurement / observation (no external side effect)

| # | Component | What it genuinely does | Evidence |
|---|-----------|------------------------|----------|
| M1 | `Discovery.Steps.ExperimentStep` | reads two world-model entities, computes divergence with real code, publishes evidence (`outcome/confidence/measurement/provenance` with `produced_by`); inputs seeded, measurement EARNED | `discovery/steps/experiment_step.ex:54-108` (and moduledoc :2-26) |
| M2 | `Discovery.Steps.ValidationStep` | real comparison/validation over the measurement | `discovery/steps/validation_step.ex:38-63` |
| M3 | `Sentinel.ObservationScheduler` | real BEAM introspection: `:erlang.memory`, `:system_info`, `:statistics` | `sentinel/observation_scheduler.ex:101-130` |
| M4 | `CEL WorkflowEngine` (plumbing) | real saga: ResourceManager.allocate, capability-based step delegation, outcome_evidence accumulation, per-5 steps checkpoint, DETS persist, EventBus publish, compensation + recovery, retry-with-backoff | `cel/services/workflow_engine.ex:463,518-576,571-576,695-700,713-809,765-789` — **but the step bodies it dispatches are often constant results (see T9)** |
| M5 | `WorldStateSynchronizer` | subscribes `discovery.completed`, creates entities in UnifiedWorldModel with provenance `origin: :discovery_engine` | `world/world_state_synchronizer.ex:84,216,245-277` |
| M6 | `Research.KnowledgeIntegrator` | gate: only execution_mode `:real_execution` is integrated; filters/fuses/persists | `research/knowledge_integrator.ex:88-89,118` |
| M7 | `Research.ResearchDirector.Pipeline` | real plan pipeline (hypothesis→experiment plan) but R0 quarantine active: at `:advance` examined experiments are quarantined, nothing fabricated persisted | `research/research_director.ex:146-159` (init note :126) |
| M8 | `Evidence.Provenance` + `Evidence.CertificationGate` | real evidence-kind taxonomy (`:real_execution` requires execution_id), rejects/quarantines records missing/unknown provenance | `evidence/provenance.ex:16,34,89,116-117`; `evidence/certification_gate.ex:27-49` |

## 3. Persistence / durable state (real I/O, content quality varies)

| # | Component | Evidence |
|---|-----------|----------|
| P1 | `Executive.EventStore` — append-only framed binary log, replay | `executive/event_store.ex:1-55` |
| P2 | `Executive.Lineage`, `Executive.Auditor` (write-class/lineage/immutability gates) | `executive/lineage.ex:1-48`, `executive/auditor.ex:1-54` |
| P3 | `CEL.Services.ResilientDETS` (real DETS writes + quarantine of corrupt files) | `cel/services/resilient_dets.ex:7,43,52` |
| P4 | `Omega.DeploymentGateway.DeploymentRegistry` — append-only authorization-id log (replay protection) | `omega/deployment_gateway/deployment_registry.ex:11-37` |
| P5 | `ASC.Adoption` finalize — `.eterm` record with auth SHA-256, snapshot SHA-256s, tags | `asc/adoption/adopter.ex:268-295` |
| P6 | `world_model` / `unified_world_model` entity store (in-memory write by design) | `core/world_model/*` |

## 4. Supervised-runtime "execution" that is simulated/theatrical (see Truth Classification for verdicts)

| # | Component | Consumer / wiring | Evidence |
|---|-----------|-------------------|----------|
| T1 | `Tiannara.Sandbox` — probabilistic outcome simulation, self-documented | **wired** child of Sentinel supervisor (`sentinel/supervisor.ex:40`) | `sandbox.ex:217-218,226-228` (simulate), `:247-251` (rollback no-op), `:32-42` (`execute` fabricates `hyp_legacy` experiment) |
| T2 | `Autonomy.SimulationManager.measure_baseline` — `:rand.uniform` fabricated metrics | `ConstitutionalAutonomy` cycle gate | `autonomy/simulation_manager.ex:76,79-82,63-70` |
| T3 | `Autonomy.DeploymentPipeline` — status-flip deploy, fake checkpoint, `total_deployed+1` unconditional | `ConstitutionalAutonomy` | `autonomy/deployment_pipeline.ex:55-69,112-120` |
| T4 | `Autonomy.RollbackEngine.execute_rollback` — `:timer.sleep(10)` → `{true, fake_id}` | autonomous/manual rollback | `autonomy/rollback_engine.ex:67-72` |
| T5 | `ASC.Repair.Pipeline` — SandboxValidator always `{:ok,:pass}`, CanaryReleaser `{:ok,:canary_deployed}`, ProductionRollout `{:ok,:rolled_out}` | Phase H repair campaigns | `asc/repair/pipeline.ex:34,40,46` |
| T6 | `ASC.Reality.DigitalDeploymentManager` — all steps auto-`:completed`, fabricated endpoints | ASC reality phases 8/10 | `asc/reality/digital_deployment_manager.ex:26-40` |
| T7 | `ASC.Reality.PhysicalDeploymentManager` (default `SimulatedAdapter.execute_action` appends to in-memory list) | ASC reality | `asc/reality/physical_deployment_manager.ex:36,260-283`; `adapters/simulated_adapter.ex:57-71` |
| T8 | `ExecutiveCycle` — `:execute` posts `status: :executed` to in-memory blackboard; `:validate` marks all valid | Executive Cognitive Runtime heartbeat (Loop A) | `executive/cognitive/executive_cycle.ex:145-159`; `executive_cognitive_runtime.ex:82` |
| T9 | `CEL.Workflow.Steps.{Observation,Experiment,Validation}` — constant/hardcoded results | still wired into `knowledge_flow_pipeline.ex:144,157`, `knowledge_coordinator.ex:194`, and dead Phase4 engines | `cel/workflow/steps/experiment.ex:49-57`, `observation.ex:55-57`, `validation.ex:46-53` |
| T10 | `Phase4.ExperimentOrchestrator` / `AutonomousResearchEngine` — built-dead (submit_experiment zero callers; registered service only) | none (service_registry.ex:287-301) | `phase4/experiment_orchestrator.ex`; `phase4/autonomous_research_engine.ex` |
| T11 | `Omega.DeploymentGateway.deploy` → `Candidate.deploy_transition` — status flip `:approved → :deployed` | **only** adversarial test scenarios | `omega/patch_generator/candidate.ex:103-108`; `omega/verification/scenarios.ex:23,49,77,...` |
| T12 | `VerificationAuthority` — reproduction/regression/compliance all hardcoded PASS | engineering proposal workflow | `verification_authority.ex:75-91` |
| T13 | `Omega.CertificationServer` — every `:experiment_completed` event gates pre-set `:gate_open`, certificate issued unconditionally | EventBus subscribers | `omega/certification_server.ex:41-46` |
| T14 | `Agency.Sandbox` — `success_probability = 0.6 + :rand.uniform()*0.3` | research director pipeline (sandbox) | `agency/sandbox.ex:13-14` |
| T15 | `SOPL.EvolutionEngine.deploy/1` — logs "Deployed Law" only | none external | `sopl/evolution_engine.ex:65-70` |
| T16 | `ToolForge.ToolBuilder.do_execute` — `{:implemented, input}` stub; `tools_deployed: 0` | none | `tool_forge/tool_builder.ex:123-126`; `tool_forge/tool_forge_engine.ex` |
| T17 | `OS.Governance.DeploymentOrchestrator.apply_rfc_to_ledger` — "simulate event creation"; `perform_rollback` only `IO.puts` | TiannaraOS governance (separate unbooted subsystem) | `os/governance/deployment_orchestrator.ex:482-498,411` |
| T18 | `ASC.Agency.Orchestrator` mock cycle (mock_observations/hypotheses/execute→completed/integrate) | dyn dispatcher paths | `asc/agency/orchestrator.ex:27-35` |
| T19 | `REA Intervention` pre-baked `status: :completed` + `actual_effect` seeds | intervention ledger/UI | `rea/intervention.ex:79-80` |

## 5. Dead / unconsumed execution APIs (proven by define-site vs call-site)

| API | Callers found |
|-----|---------------|
| `SelfImprovement.Sandbox.RealHarness.run/5` | `self_improvement/dry_run.ex:47`, `omega/dry_run.ex:102` (dry-run only) |
| `SelfImprovement.Sandbox.Backend.{Local,Container,CI}` | only via above dry-runs + tests |
| `SelfImprovement.Pipeline.request_deployment/3` | `self_improvement/dry_run.ex:97`, `constitution/registry.ex:72,85,95,104` (self-tests), remains `deployment_enabled: false` by default (`pipeline.ex:47`) |
| `Omega.DeploymentGateway.deploy/6` | `omega/verification/scenarios.ex` (tests only) |
| `Sentinel.Activation.Approval.decide/2` | **no caller in lib/** (only `propose` at `activation/engine.ex:72`) |
| `Phase4.ExperimentOrchestrator.submit_experiment/2` | **no production caller** (comment-only reference in unbooted `tiannara_runtime`) |
| `ASC.Reality.PhysicalAdapter` (real adapters) | absent — only `SimulatedAdapter` |
| `SOPL.EvolutionEngine.run_evolution_epoch/2` | no external callers |
| `ToolForge` tool execution | no execution path |

## 6. External-world sensing (self-referential risk)

| # | Component | Reality | Evidence |
|---|-----------|---------|----------|
| S1 | `Reality.ProductionObservatory` — `HTTPoison.get` against GitHub/Stripe/Datadog | `HTTPoison` is a **repo-local stub** (`lib/tiannara/stubs/httpoison.ex:4-6`) returning `{:ok, %{status_code: 200, body: ""}}`; no httpoison dep in mix.exs → "external reality" is self-referential | `reality/production_observatory.ex:46,67,92`; `stubs/httpoison.ex:1-7` |

## 7. Boundary-chain components (see ARCHITECTURE artifact for the full analysis)

- Intent: `intent/teleological_engine.ex:22-23` (heuristic mock; no downstream consumer).
- Observation: M3/M1 internal; S1 self-referential.
- Planning: `research/director.ex:341-366` (real rollback plans); `research/research_director.ex:131-155`; discovery scheduler generators.
- Authorization: `omega/human_delivery/authorization.ex` (hard human gate, nothing mints grants); `omega/governance_gate_server.ex` (holds pending); `omega/deployment_gateway.ex:1-45` (certification+lineage+grant enforced); `council/kernel.ex:87,99` (kernel-op authorization); `knowledge_coordinator.ex:173-178` (human approval for promotion); `sentinel/activation/approval.ex` (propose only).
- Execution: REAL-narrow Discovery Loop (M1/M4/M5); THEATRICAL runtime sandbox/quors (T1..T18); dead orchestrator (T10).
- Verification: T12/T13 theatrical; real-but-unwired harness (B4); M8 provenance gate.
- Knowledge integration: M5 real; M6 gated on `:real_execution` (no real prober today); CEL `knowledge_integration` step writes UnifiedRealityGraph.

## 8. Inventory completeness note

Inventory covers all files under `lib/tiannara/` and `lib/mix/tasks/`
(1,596 .ex files) plus the separate unbooted `tiannara_runtime/` OTP app and
`lib/tiannara/os/*` (TiannaraOS subsystem, not in main app boot). Test-only
paths are enumerated in §4/§5 but excluded from production classifications.