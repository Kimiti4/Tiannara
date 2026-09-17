# MC-003-A0 — Consumer / Execution-Path Map

**Gate:** MC-003-A0 (Observational)
**Status:** COMPLETE
**Date:** 2026-08-29

Every production consumer of P16/execution APIs, whether the supplier really
executes, error handling, and downstream decision impact. HIGH CRITICALITY =
feeds discovery/planning/research/optimization/self-improvement/repair/
autonomous decision-making.

---

## C1. Autonomous self-improvement loop (HIGH CRITICALITY)

**Driver:** `ConstitutionalAutonomy.Orchestrator.execute_cycle`
`lib/tiannara/autonomy/constitutional_autonomy.ex:105-136`

| Hop | Call | Real? | Evidence |
|-----|------|-------|----------|
| identify→propose→validate→simulate→deploy | `SimulationManager.simulate(proposal)` (:122-123) | **NO** — fabricated `:rand` memory/throughput (simulation_manager.ex:76) | outcome gated by `sim[:improvement_ratio] > 1.0` |
| deploy | `DeploymentPipeline.deploy(simulation)` (:128) | **NO** — status flip (deployment_pipeline.ex:112-120) | increments `total_deployed` (:68) |

Error handling: deployment GenServer never errors on the happy path; a random
`improvement_ratio` can never be `< 1.0`+ fabricated. **Downstream effect:**
the system records deployments and telemetry `:deployment_monitoring` as if real
improvement shipped. → **THEATRICAL loop, CRITICAL.**

## C2. Discovery Loop B (REAL-narrow — the only earned-evidence execution path)

**Driver:** `DiscoveryScheduler` (`discovery/discovery_supervisor.ex:13` → scheduler
`lib/tiannara/discovery/discovery_scheduler.ex`), triggered by its own 30-min
timer + `operations/autonomous_loop.ex:124` + feedback listeners.

| Hop | Call | Real? | Evidence |
|-----|------|-------|----------|
| gap→hypothesis→prediction→plan | internal generators (scheduler :295-348) | yes (internal computation) | — |
| dispatch workflow | `Tiannara.CEL.Services.WorkflowEngine` (scheduler :653-702) | yes (saga plumbing) | workflow_engine.ex:518-576 |
| measurement step | `Discovery.Steps.ExperimentStep.execute/2` | **YES** — reads UnifiedWorldModel entities, computes divergence, produces evidence map with provenance | experiment_step.ex:54-108 |
| validation step | `Discovery.Steps.ValidationStep.execute/2` | **YES** — real comparison | validation_step.ex:38-63 |
| evidence→outcome | `outcome_evidence` accumulation (workflow_engine.ex:556-569) → `DiscoveryResult` (scheduler :169-194) | yes | — |
| integrate | `discovery.completed` → `WorldStateSynchronizer` creates world entities (world_state_synchronizer.ex:216,245-277) | yes (in-memory world model) | — |

**Caveats:** step inputs are seeded (`ExperimentStep` moduledoc, :5-11) and the
scheduler's `confidence_delta` is the fixed `0.1/0.0` (discovery_scheduler.ex:178)
— an evidence-distribution defect (P16-AT(d) unrelated). **Downstream effect:**
discoveries persist to the world model and feed the question stream. Internal
computation only; no external side effect. → **REAL (narrow), EARNED measurement.**

## C3. Research pipeline (quarantined)

**Driver:** `Research.ResearchDirector.Pipeline` (`research/research_director.ex`).

- `handle_cast(:advance)` — hypothesis→plan→`ExperimentPlanner.plan` (:150-153)
  REAL planning; experiment branch **quarantines** the experiment (:157-158),
  `total_quarantined+1`. Init note :126 "R0 quarantine active: fabricated
  experiment execution disabled".
- `Research.KnowledgeIntegrator.integrate/3` — refuses unless
  `execution_mode == :real_execution` (knowledge_integrator.ex:88-89,118).
- **Downstream:** nothing fabricated persists. → **REAL boundary, R0 safe.**

## C4. Omega delivery gateway (enforced single path?, test-only execution)

- `Omega.DeploymentGateway.deploy/6` → `PatchGenerator.Candidate.deploy_transition/1`
  flips `:approved → :deployed` (candidate.ex:103-108). **Zero production
  callers** — only adversarial scenarios (omega/verification/scenarios.ex:
  23,49,77,102,128,154,204,238,291,297). The REAL enforcement (certification +
  lineage + grants + replay protection) exists in the gateway (deployment_gateway.ex:1-45)
  but nothing routes a real deploy through it. → **PARTIAL gate, THEATRICAL deploy.**

## C5. Self-improvement pipeline (authorized but never executes)

- `SelfImprovement.Pipeline.request_deployment/3` — gates pass →
  `{:ok, :deployment_authorized}` ONLY when `deployment_enabled: true`
  (pipeline.ex:46-52); **default `false`** (:47). Callers:
  `self_improvement/dry_run.ex:97`, `constitution/registry.ex:72,85,95,104`
  (self-tests). **No executor exists after authorization.** → **the gap: an
  authorization with no executor.**

## C6. ASC Repair / Reality (fabricated success -> campaign status)

- `ASC.Repair.Pipeline` — `SandboxValidator` `{:ok, :pass}` (:34),
  `CanaryReleaser` `{:ok, :canary_deployed}` (:40) claims 5% traffic,
  `ProductionRollout` `{:ok, :rolled_out}` (:46) claims 100%. Nothing deployed.
- `ASC.CivilizationRunner` routes `status: :completed` when campaign returns
  `{:ok,_}` (civilization_runner.ex:33,65) — even if the content was fabricated.
- **Downstream:** repair/science campaigns report success into governance
  telemetry. → **THEATRICAL, HIGH CRITICALITY (repair loop).**

## C7. Verification / certification consumers

- `VerificationAuthority.verify/1` (verification_authority.ex:35-36) — every
  engineering proposal "passes" (hardcoded :75-91). **No proposal can fail.**
- `Omega.CertificationServer` — on `:experiment_completed`, all gates preset
  `:gate_open` (certification_server.ex:41-46) → certificate issued
  unconditionally. → **THEATRICAL; consumers trust certificates that certify nothing.**

## C8. Sentinel Activation loop (propose-only)

- `Activation.Engine` proposes via `Approval.propose/2` (activation/engine.ex:72).
- `Approval.decide/2` (approval.ex:44-49) — the step that would execute the
  proposal in `Tiannara.Sandbox` — **has NO caller in lib/** (grep: define site
  only). Sandbox itself fabricates outcomes (sandbox.ex:226-228). → **gap +
  fabrication; the human→execute link is disconnected.**

## C9. Executive Cognitive Runtime (Loop A)

- Heartbeat every 5s → `ExecutiveCycle` (executive_cognitive_runtime.ex:82):
  `:execute` posts `status: :executed` to in-memory blackboard; `:validate` marks
  all valid (executive_cycle.ex:145-159). → **THEATRICAL; Loop A live
  (P16-AT(e) unmet).** R0 deliberately defangs its substrate but the theater
  remains.

## C10. External world sensors

- `Reality.ProductionObservatory` (production_observatory.ex:46,67,92) calls
  `HTTPoison.get`; the only `HTTPoison` module is the repo-local stub returning
  `{:ok, 200, ""}` (stubs/httpoison.ex:4-6). Readers believe they observed real
  GitHub/Stripe/Datadog state. → **THEATRICAL; self-referential "external".**

## C11. Real-but-unwired capabilities (correctly not fabricated, but dead)

- `SelfImprovement.Sandbox.RealHarness` + real backends — real subprocess
  verification of patched code — reachable only via `SelfImprovement.DryRun` /
  `Omega.DryRun` (dry_run.ex:47,102) and tests (`test/tiannara/self_improvement/
  sandbox_backend_test.exs`). Honest evaluation-only (`omega/dry_run.ex:1-24`
  NEVER deploys). → **REAL, useful, unwired; candidate substrate for MC-003-M.**
- `ASC.Adoption.Adopter` — real two-key adoption via Mix task. → **REAL, manual.**

## Summary of decision-impact

| Path | Claims | Reality | Downstream decisions fed |
|------|--------|---------|--------------------------|
| ConstitutionalAutonomy | improvement + deployment | fabricated metrics → status flip | autonomy records, telemetry |
| Discovery Loop B | evidence from measurements | REAL (seeded inputs, fixed ±0.1 delta) | world model, question stream |
| ASC Repair | canary/rollout | nothing executed | Phase H status |
| VerificationAuthority | verified/reproduced | hardcoded pass | proposal acceptance |
| CertificationServer | certified | gates pre-open | certificates |
| ProductionObservatory | external reality | stub HTTP | reality anchoring |
| Sentinel Activation | propose→(decide missing) | gate unwired; sandbox simulated | (no execution reached) |
| SelfImprovement | deployment authorized | no executor | dry-run only |