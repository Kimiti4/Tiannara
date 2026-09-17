# MC-003-A0 — Real Execution Architecture Assessment

**Gate:** MC-003-A0 (Observational, evidence-first: document what exists, not the desired future)
**Status:** COMPLETE
**Date:** 2026-08-29

## Provenance of the "P16" notion

- `certification/TIANNARA_PHASE16_EXECUTION_AUDIT.md` — MC-003 = "Phase 16:
  autonomous research execution"; defines acceptance P16-AT(a)-(e) (:77).
- `certification/TIANNARA_PHASE_15_20_CERTIFICATION.md:27` — **P16.5 Autonomous
  Research Execution = `MISSING`** ("the loop breaks at execution due to domain
  stubs").
- `certification/TIANNARA_REMEDIATION_MATRIX.md:13` — MC-003 = "Break at Stage 7;
  three executor tiers (fabricated-live / real-narrow / built-dead)".
- Reconciliation confirms all three executor tiers exist in the current tree.

## What actually executes (current runtime)

The only OTP app that boots is `Tiannara.Application`:
- `cel/kernel.ex` boot (CEL boot order, service_registry.ex:322-330) — includes
  `WorkflowEngine` (real saga) and service registration of the built-dead
  Phase4 engines (service_registry.ex:287-301).
- `sentinel/supervisor.ex:40` — **`Tiannara.Sandbox`** (simulated) + Activation
  Engine (propose-only) + SentinelRuntime.
- ASC reality tree gated by `config/config.exs` `:asc enabled: true`,
  `deployment_mode: :artifact_only` (config.exs:133-134) — campaigns run in
  artifact-generation mode; deploys are simulated (DigitalDeploymentManager).
- `executive_cognitive_runtime.ex:82` — ExecutiveCycle blackboard theater.
- `operations/operations_supervisor.ex:11-12` — ControlCenter + AutonomousLoop.

The REAL end-to-end frame today is:

```
DiscoveryScheduler (timer/loop)
  └─ plan → CEL.WorkflowEngine (real saga)
       └─ Discovery.Steps.ExperimentStep  (REAL measurement over world model)
       └─ Discovery.Steps.ValidationStep  (REAL validation)
       └─ outcome_evidence → DiscoveryResult → :discovery.completed
            └─ WorldStateSynchronizer.create_entity (world model write)
```

This is earned internal computation with explicit seed provenance. There is NO
supervised path that performs an external side effect.

## Side-effect inventory by kind

| Side-effect kind | Present? | Where (REAL) | Where (fake) |
|------------------|----------|--------------|--------------|
| filesystem changes | partial | sandbox backends (local.ex:20-137), adoption (adopter.ex:140-305), CMissions, reality_bridge | DigitalDeploymentManager claims steps, ToolForge writes stubs |
| process execution | partial | sandbox backends System.cmd; adoption; CMissions; mix start task | AutonomousLoop claims deployments |
| HTTP/API calls | NO (stub) | — | HTTPoison stub (stubs/httpoison.ex:4-6) |
| database mutations | partial | DETS (resilient_dets.ex), event_store.ex, world model in-memory | — |
| message publication | partial | EventBus (real), telemetry | — |
| container execution | partial | sandbox/backend/container.ex (real, unwired) | — |
| code execution | partial | sandbox build/test; Code.eval in asc/c_missions/ledger.ex:39 (ASC-gated) | verbatim stub ToolForge |
| simulation execution | partial | multiworld/simulation engines compute over models | `:rand` fabrication (sandbox.ex:226-228) |
| hardware/robotics | NO | — | SimulatedAdapter (simulated_adapter.ex:57-71) |

## Execution-boundary chain (the p16 core question)

```
Intent → Plan → Authorization → Execution → Observation → Result → Verification → Knowledge integration
```

| Stage | Exists? | Evidence |
|-------|---------|----------|
| Intent | YES (mock, no consumer) | intent/teleological_engine.ex:22-23 |
| Plan | YES | research/director.ex:341-366; research_director.ex:131-155; discovery generators :295-348; WorkflowEngine step planning |
| Authorization | YES (enforced, but majority unwired to execution) | Omega.DeploymentGateway (deployment_gateway.ex:1-45); Omega.HumanDelivery.Authorization (authorization.ex:10-43); GovernanceGateServer (holds pending); Council kernel gates (kernel.ex:87,99); KnowledgeCoordinator promotion approval (knowledge_coordinator.ex:173-178); **Approval.decide never called** |
| Execution | **BREAK** — real-narrow (Discovery loop) is internal-only; runtime "execution" (Sandbox/ASC/autonomy/Omega gateway) is simulated/status-flip; orchestrator (submit_experiment) dead | §above + phase4/experiment_orchestrator.ex (unbooted, zero callers) |
| Observation | PARTIAL — internal (Sentinel.ObservationScheduler real; world model reads real) | observation_scheduler.ex:101-130; experiment_step.ex:58-60 |
| Result | PARTIAL — DiscoveryResult + outcome_evidence real; others fabricated | workflow_engine.ex:556-569; discovery_scheduler.ex:169-194 |
| Verification | **BREAK** — runtime verification theatrical (VerificationAuthority hardcoded PASS; CertificationServer gates pre-open); real verification (sandbox RealHarness+t-tests) unwired; independent external outcome verification absent | verification_authority.ex:75-91; certification_server.ex:41-46; real_harness.ex:13-54 |
| Knowledge integration | PARTIAL — WorldStateSynchronizer real; KnowledgeIntegrator gated `:real_execution` (no real feed); CEL knowledge_integration writes UnifiedRealityGraph fed by fabricated steps | world_state_synchronizer.ex:245-277; knowledge_integrator.ex:88-89 |

**The chain breaks at Execution and at Verification.** Planning, authorization
(enforcement), and persistence exist; a real execution stage and an independent
outcome-verification stage are missing from the supervised runtime.

## Executor tiers (remediation-register terms, confirmed)

1. **Fabricated-live:** `Tiannara.Sandbox` (probabilistic), ExecutiveCycle,
   ConstitutionalAutonomy/SimulationManager/DeploymentPipeline/RollbackEngine,
   ASC.Repair, DigitalDeploymentManager, VerificationAuthority, CertificationServer,
   Agency.Sandbox.
2. **Real-narrow:** Discovery Loop B (earned internal measurement), Research
   Director (quarantined), Sentinel observation, provenance gates.
3. **Built-dead:** Phase4 orchestrator engines, Omega DeploymentGateway
   (test-only), real sandbox backends (dry-run only), ASC Adoption (Mix task only).

## Component inventory (execution-relevant)

| Component | Kind | Booted/Reached | Evidence |
|-----------|------|----------------|----------|
| CEL WorkflowEngine | execution orchestrator (saga) | booted (CEL kernel) | cel/services/workflow_engine.ex |
| DiscoveryScheduler + Supervisor | scheduler | booted (own timer/Loop B) | discovery/discovery_supervisor.ex:13 |
| Tiannara.Sandbox | sandbox (simulated) | booted via sentinel/supervisor.ex:40 | sandbox.ex |
| Sentinel Activation Engine | gate/propose | booted | activation/engine.ex:72 |
| Executive Cognitive Runtime + ExecutiveCycle | Loop A theater | booted | executive_cognitive_runtime.ex:82; executive_cycle.ex:145-159 |
| ASC Reality tree | deployment managers | booted (artifact-only mode) | asc/reality/* |
| CEL.Scheduler | scheduler | stub (healthy? always true) | cel/scheduler.ex:12-23 |
| Phase4 Orcherstrator/ARE | orchestrator (built-dead) | NOT supervised; registered only | service_registry.ex:287-301 |
| Real sandbox backends + RealHarness | real execution engine | NOT booted (dry-run only) | self_improvement/sandbox/* |
| Omega DeploymentGateway | deploy gate | NOT booted (test-only) | omega/deployment_gateway.ex |
| ASC Adoption | real two-key exec | Mix task only | mix/tasks/asc.adopt.ex |
| EventBus (Safe) | message bus | booted | cel/services/event_bus.ex |
| Executed event store / DETS | persistence | booted/live | executive/event_store.ex; resilient_dets.ex |
| Evidence.Provenance/CertificationGate | provenance gate | library (used by evidence paths) | evidence/provenance.ex; certification_gate.ex |
| TiannaraOS subsystem (os/, unknown_registry, deployment_orchestrator) | separate subsystem | NOT in main boot | os/unknown_registry.ex |

## Observations for mutation planning (NOT design)

- Reuse > duplication: the REAL build/test/benchmark harness exists
  (`SelfImprovement.Sandbox` real backends + `RealHarness`); a mutation would
  wire an existing real capability into a supervised, gated runtime execution
  stage rather than build a new engine.
- Provenance enforcement already exists (`Evidence.Provenance` +
  `CertificationGate`); extending P16 requires routing every persisted record
  through it (P16-AT(c)).
- The Authorization stage is real and enforceable today; the missing link is
  calling an execution step from an approved, human-gated proposal
  (`Approval.decide` has no caller) and the dead orchestrator gateway.