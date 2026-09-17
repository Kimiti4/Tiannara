# MC-003-A0 — Mutation Plan (recommendations for MC-003-M)

**Gate:** MC-003-A0 (Observational). This artifact is a *recommendation only*.
**No mutation is authorized here. Execution of any candidate requires a
separate, human-authorized MC-003-M gate, test-first discipline, and
evidence-verified completion.**

The plan prioritizes Truthfulness + Reuse (real building blocks already exist)
and drives every P16 acceptance criterion (P16-AT(a)-(e), TIANNARA_PHASE16_
EXECUTION_AUDIT.md:77).

---

## Strategy

1. **Strip theater before adding wiring** (decommission fabricated success)
   — otherwise real verification gets drowned by fabricated narratives.
2. **Reuse** the real sandbox harness / provenance machinery; **do not
   architect a new engine**.
3. Every candidate removes a bottleneck (BOTTLENECKS) and moves toward P16-AT.

## Candidate mutations (M1–M8)

| ID | Bottleneck(s) | P16-AT | Change | Reuse | Risk |
|----|---------------|--------|--------|-------|------|
| M1 | B1 | (e) | Decommission fabricated-runtime theater: make `VerificationAuthority.verify/1` return explicit `{:unavailable, :independent_verification_not_wired}` instead of hardcoded PASS (verification_authority.ex:75-91); `CertificationServer` no longer auto-emits; `ExecutiveCycle` stop posting `status: :executed` (executive_cycle.ex:145-159); `Agency.Sandbox` surface `:unavailable` (agency/sandbox.ex:13-19); CEL constant `Observation/Experiment/Validation` steps replaced by explicit `:unavailable`/error boundaries (experiment.ex:49-57, observation.ex:55-57, validation.ex:46-53) | error-contract cells in consumer contracts; unchanged `Evidence.*` gates | HIGH (wide blast radius; each changed consumer re-verified) |
| M2 | B2, B5, B7 | (b) | Wire the sole real execution path: `Phase4.ExperimentOrchestrator.submit_experiment` becomes the *only* entry to experiment execution, registered under supervision (service_registry.ex:287-301 today: dead); an execution is run by `SelfImprovement.Sandbox.RealHarness` + real backends (backend/local.ex, backend/container.ex) watched by `Omega.DeploymentGateway` + `Omega.HumanDelivery.Authorization` grant (human_grant only, human_delivery/authorization.ex:10-43); `Approval.decide` (sentinel/activation/approval.ex:44-49) receives its first caller from a real approved proposal (activation/engine.ex:72 proposes today) | real sandbox + real gate + real grant | HIGH (first live side-effecting path; requires deployment_enabled: true + human grant; staged behind config) |
| M3 | B6 | (d) | Derive `confidence_delta` from the evidence distribution collected by `ExperimentStep` (discovery_scheduler.ex:178 today: fixed 0.1/0.0; experiment_step.ex:54-108 produces the evidence) | existing evidence map | MEDIUM |
| M4 | B4 | (c) | Wire the real verifier: `RealHarness` + statistical benchmark runs *within* the experiment lifecycle (not only DryRun); strip `VerificationAuthority`/`CertificationServer` pre-opened gates (M1 handles these); result records carry verifier evidence | real_harness.ex:13-54; statistical_benchmark.ex:20-48 | HIGH |
| M5 | B1 / P16-AT(a) | (a) | Materialize and boot `TiannaraOS.UnknownRegistry`/kernel-contradiction seeding into the real subsystem where it exists (os/unknown_registry.ex) with a live growth path from kernel contradictions | existing os/ subsystem (separate, unbooted) | MEDIUM (outside main app boot) |
| M6 | B8 | — | Remove the global HTTPoison stub self-referential sensing (stubs/httpoison.ex:4-6): real HTTP only when a provider is configured; otherwise `ProductionObservatory` returns `{:unavailable, :no_external_provider}` (production_observatory.ex:46,67,92) | HTTPoison client only if dependency real | MEDIUM |
| M7 | B9 | — | Stale-execution detector over running executions (heartbeats today are cycle clocks only: sentinel/heartbeat/server.ex:54-88); replace theatrical rollback (rollback_engine.ex:67-72) with either real rollback or explicit `:unavailable`; deterministic replay seeds for simulations (multi_world domain.ex:20 `:crypto.strong_rand_bytes`) remove nondeterminism | workflow retry/recovery plumbing | MEDIUM |
| M8 | B1, B3, B10 | (c) | Provenance enforcement at write-time everywhere: every persisted executed/knowledge record requires `experiment_id` + provenance chain resolving to Tier-2+ execution with no ancestor via `:rand.uniform`; `ConstitutionalAutonomy`/`ASC.Repair`/`ToolForge`/`SOPL` surfaces become `:unavailable` until they have a real execution provider (constitutional_autonomy.ex:105-136; asc/repair/pipeline.ex:34,40,46; tool_builder.ex:123-126; evolution_engine.ex:65-70) | existing Provenance/CertificationGate (evidence/provenance.ex:16,34,89,116-117; certification_gate.ex:27-49) | HIGH (touches all fabricating lanes) |

## Sequencing (test-first, gated)

1. **M1 + M8 (truth first)** — makes the system unable to claim fabricated
   success; any previously-certified-but-fabricated artifact now errors
   explicitly. No behavior removed that a human relied on (evidence: consumers
   verified in CONSUMER-MAP).
2. **M6, M7 (stability)** — stops self-invented "external" data; adds staleness
   detection/determinism.
3. **M2 (wire the real path)** — behind `deployment_enabled: true` + human grant;
   the public real execution entry becomes `submit_experiment` only (P16-AT(b)).
4. **M3 (uncertainty) + M4 (verifier-in-loop) + M5 (registry boot)** (P16-AT (d),(c),(a)).
5. **Certify P16** ONLY after: 54-test battery + new tests green; a real
   experiment executed with provenance; M4 verifier evidence in record; no
   `:rand` ancestors in seeded knowledge (P16-AT(c)); Loop A non-boot /
   execution only via orchestrator (P16-AT(e)).

## Evidence gates for MC-003-M (test-first)

- Unit/integration tests exist for each changed module before/with the change.
- Real execution smoke requires `deployment_enabled: true` and a fresh human
  grant (HumanDelivery.Authorization timeout enforced).
- Every newly-performed real side effect appears in `event_store` +
  `executed_event` log with `execution_id` matching the orchestrator's.
- No regression across logic/engine/CEL/graph/metrics/discovery/ros/omcs
  batteries (previous counts: 54 + 174 + 7 green).

## Non-goals (explicit)

- Do NOT build a new execution engine/scheduler (reuse the WorkflowEngine + real
  sandbox). Do NOT add simulated "real" execution. Do NOT fabricate verifier
  output. Do NOT touch `os/` boot wiring without its own gate (separate
  subsystem). Do NOT add HTTP calls without a configured provider.