# MC-003-A0 — Real Execution Verification Assessment

**Gate:** MC-003-A0 (Observational)
**Status:** COMPLETE
**Date:** 2026-08-29

## Question

Can Tiannara distinguish ATTEMPTED → COMPLETED → OBSERVED → VERIFIED, and what
evidence supports each state? A successful function return is NOT evidence that
execution succeeded.

## State machine inventory

| State | Runtime capability | Evidence base that supports it |
|-------|--------------------|--------------------------------|
| PROPOSED | YES | proposal structs, Approval.propose (activation/engine.ex:72); DeploymentProtocol proposal records |
| SCHEDULED | PARTIAL | DiscoveryScheduler timer loop (real dispatch); CEL.Scheduler is a stub (cel/scheduler.ex:12-23); no execution queue |
| SIMULATED | YES (but mislabeled as execution) | Tiannara.Sandbox self-documents simulation (sandbox.ex:217-218); Agency.Sandbox :rand (agency/sandbox.ex:13-19); SimulationManager fabricated baselines (simulation_manager.ex:76) |
| ATTEMPTED | PARTIAL | sandbox submit/status; deployment pipeline stage fields; workflow step dispatch (real saga status) |
| COMPLETED | CONTESTED | status fields everywhere (`status: :executed`, `:completed`, `{:ok,:rolled_out}`) — none imply a side effect occurred |
| OBSERVED | PARTIAL | real: Sentinel ObservationScheduler (memory/system stats), Discovery.Steps.ExperimentStep world-model reads; theatrical: ProductionObservatory (stub HTTP) |
| VERIFIED | NO (runtime) / PARTIAL (dry-run) | independent outcome verification unavailable in runtime |

## Verification components (all found)

| Component | What it verifies | Genuine? | Evidence |
|-----------|------------------|----------|----------|
| `SelfImprovement.Sandbox.RealHarness` + `StatisticalBenchmark` | patched code builds/tests/benchmarks in a real subprocess (baseline vs patched, N samples, t-test, CI95) | **YES — the only real execution verification** | real_harness.ex:13-54; statistical_benchmark.ex:20-48; reachable only via dry-runs/tests |
| `Evidence.Provenance` + `Evidence.CertificationGate` | evidence-kind validity; rejects/quarantines records without real_execution provenance / execution_id | **YES — governance gate over records** (it does not verify execution, it gates the claim) | provenance.ex:16,34,89,116-117; certification_gate.ex:27-49 |
| `Research.KnowledgeIntegrator` | only accepts `:real_execution` mode | **YES — gate** | knowledge_integrator.ex:88-89,118 |
| `VerificationAuthority` | reproduction, regression tests, side effects, constitutional compliance | **NO — hardcoded PASS (reproduced 0.95, all_passing, compliant)** | verification_authority.ex:75-91 |
| `Omega.CertificationServer` | experiments; emits certificate | **NO — gates pre-set `:gate_open`, cert unconditional** | certification_server.ex:41-46 |
| `Omega.AuthorityVerifier` | static capability presence (`__info__(:functions)`) | YES — but liveness/capability only, not outcomes | omega/authority_verifier.ex:21-34 |
| `PhaseOmega.RuntimeVerifier` | `Process.alive?`, ETS existence, module load, GenServer health probes | YES — liveness only | phase_omega/runtime_verifier.ex |
| `CIWiring`/`GitHubActions` | correlation-token dispatch/poll | YES protocol, **never wired** (no config/provider; `:ci_not_configured`) | omega/ci_wiring.ex:34-112; live_pipeline.ex:106-115 |

## Independent execution-outcome verification: UNAVAILABLE (runtime)

No module performs **independent** verification of an executed side effect in
the supervised runtime:
- External HTTP verification is self-referential (repo-local HTTPoison stub,
  stubs/httpoison.ex:4-6).
- The genuine sandbox verification is not reachable from any supervised path
  (dry-run only).
- Certification/verification authorities return hardcoded success.
- `Evidence.CertificationGate` validates provenance claims on records; it does
  not independently confirm that an execution occurred. Records carrying
  `:real_execution` kind do get execution_id validation (provenance.ex:116-117),
  which defends the claim format but not the claim's truth.

**Conclusion:** ATTEMPTED/COMPLETED/VERIFIED states are not truthfully
distinguishable today. Execution claims are self-attested:
- `DeploymentGateway` regression scenario self-attestation is prevented by the
  `source != :self_improvement` rule (pipeline.ex:81-88), but no external
  source exists in the runtime, so no record can honestly be marked
  `:independent_verification`.
- The `external_auditor` tag can even be injected from DryRun config
  (`self_improvement/dry_run.ex:200-202`) — evidence of how easily the 
  verification labels can be fabricated.

## Classification

- Independent verification of executed outcomes: **NO** (runtime) /
  available only outside the runtime in dry-run harness.
- Provenance gating: **REAL** (a necessary-but-not-sufficient control).
- Result-authenticity guardrails: **REAL for Discovery Loop** (ExperimentStep
  produces observable measurement + provenance); **absent elsewhere**.
- Verification-as-theater: **VerificationAuthority + CertificationServer.**

## Required for P16 (from evidence, not design)

- P16-AT(c) requires every persisted knowledge record carry experiment_id +
  provenance chain resolving to Tier-2-or-better execution with **no**
  `:rand.uniform` ancestor. Current state: provenance format validation exists;
  the fabricating ancestors (sandbox :rand, CEL constants, VerificationAuthority
  hardcoded, CertificationServer pre-open) are still live and can mint
  records/claims. Verification layer is the principal bottleneck (see
  BOTTLENECKS).
- Do NOT create a fake verifier during reconciliation. The real verification
  exists (RealHarness); the mutation gate's mandate is to wire it and strip the
  theatrical verifiers, not to invent new claims.