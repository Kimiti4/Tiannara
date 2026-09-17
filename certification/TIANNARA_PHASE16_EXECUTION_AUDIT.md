# Tiannara Phase 16 Execution Audit

Campaign: Remediation Architecture & Epistemic Foundation Certification (READ-ONLY)
Baseline commit: `3bd1601b9bb3c718f985d44ceaa8ef2e638d4ec6`
Scope: resolve **MC-003** — "Phase 16: autonomous research execution" (prior register MC-004)
Only one OTP app boots: `Tiannara.Application` (`mix.exs:58`). `Omega.Application` and `tiannara_runtime` are separate, unbooted entry points.

---

## 1. Lifecycle stage map

| # | Stage | Status | Evidence |
|---|---|---|---|
| 1 | Research Question | PARTIAL | Live: `GapAnalyzer.analyze/1` over world-model integrity report (`discovery/discovery_scheduler.ex:262-271`, fetch at :437-469). Canonical `TiannaraOS.UnknownRegistry` exists but **never started, init empty** (`os/unknown_registry.ex:223-233`) |
| 2 | Unknown | PARTIAL / canonical MISSING | `Discovery.Domain.KnowledgeGap` + `ContradictionAnalyzer` (scheduler :274-280); `TiannaraOS.UnknownDependencyGraph` has exactly one consumer — an orphaned director |
| 3 | Hypothesis | IMPLEMENTED/INTEGRATED | `Discovery.HypothesisGenerator.generate/2` (template engine); `Research.HypothesisRanker.generate_from_priorities` (`research/hypothesis_ranker.ex:100-131`) |
| 4 | Prediction | INTEGRATED (one path) | `PredictionEngine.generate/1` in discovery cycle only (scheduler :297-315) |
| 5 | Experiment Design | INTEGRATED | `ExperimentPlanner.plan/2` both trees; `Research.Director.design_experiment` w/ rollback plans (`research/director.ex:341-366`) |
| 6 | Resource Validation | PARTIAL | Only real impl: `Phase4.ExperimentOrchestrator` `estimate_resources/2` (:330-350), `ResourceManager.allocate` (:157), concurrency cap (:267-270). **`submit_experiment` has ZERO callers repo-wide** — fully built, never exercised |
| 7 | Experiment Execution | **BREAK POINT** | Three tiers — see §2 |
| 8 | Observation | OPERATIONAL | `SentinelRuntime` + `ObservationScheduler` 10s (`sentinel/sentinel_runtime.ex:83-99`, started application.ex:172); outcome evidence harvested scheduler :196-210 |
| 9 | Evidence | MIXED | Real provenance-carrying records (`discovery/steps/experiment_step.ex:71-90`) vs `EvidenceScorer.score/2` fed `:rand.uniform()` inputs (`research/evidence_scorer.ex:42+`) |
| 10 | Analysis | INTEGRATED (partial) | `DiscoveryQualityAssessor.assess/1` gate (scheduler :443-456); ECR path analyzes noise |
| 11 | Verdict | INTEGRATED (mixed) | Real confirmed/refuted/inconclusive from divergence vs tolerance (`experiment_step.ex:62-67`); coin-flip verdicts elsewhere (`sandbox.ex:227`) |
| 12 | Knowledge Integration | INTEGRATED | `KnowledgeIntegrator.integrate/2` → `Executive.ExecutiveMemory.put(memory_class: :persistent)` (`research/knowledge_integrator.ex:34,109-116`); world-model closure via `WorldStateSynchronizer` subscribed to `discovery.completed` (`world/world_state_synchronizer.ex:84`) |
| 13 | Uncertainty Update | PARTIAL | Fixed `confidence_delta: ±0.1` on finalize (scheduler :200-204). No Bayesian uncertainty propagation anywhere live |
| 14 | RD Reprioritization | WEAK | Canonical `TiannaraOS.ResearchDirector.calculate_priorities/0` (`os/research_director.ex:96-267`) never started; implicit re-scan each discovery cycle instead; ASC director timer merely re-sorts its own empty list (`asc/research/research_director.ex:123-148`) |
| 15 | Next Action | OPERATIONAL (narrow) | `DiscoveryPrioritizer.select_for_execution(ranked, 3)` autonomous per-cycle selection (scheduler :355,:396-400) |

## 2. The exact break point — Stage 7, three executor tiers

**Tier 1 — FABRICATED (live, heartbeat-driven):**
- `lib/tiannara/research/research_director.ex:173-185`: executor returns `%{status: :completed, observations: [%{metric: :latency_p99, value: :rand.uniform(100)...}]}`. Verified by direct read.
- Pipeline gate `evidence.confidence >= 0.7` (:156) then writes this noise-derived "knowledge" into **persistent Executive Memory** via `KnowledgeIntegrator` (:157). Verified by direct read.
- CEL workflow steps are the same class of fakery: `cel/workflow/steps/experiment.ex:49-57` returns constants `sample_size: 1000, confidence: 0.88, p_value: 0.01, supported: true` regardless of input. Verified by direct read. Same pattern in `observation.ex`, `validation.ex`, `hypothesis.ex`.
- `sandbox.ex:216-218` self-documents: *"In production, this would actually run the experiment's procedure. For now, we simulate with a probabilistic outcome"* (coin flip).

**Tier 2 — REAL but narrow (live):**
- `Discovery.Steps.ExperimentStep.execute/2` (`discovery/steps/experiment_step.ex:54-108`): measures genuine divergence between stored `UnifiedWorldModel` observation entities, dispatched through `WorkflowEngine.start_workflow` (scheduler :520-560), validated by `ValidationStep`, promoted lineage-preserving.

**Tier 3 — BUILT but DEAD:**
- `Phase4.ExperimentOrchestrator`: Council gating (:271-289), resource estimation, retries — registered as CEL service (`cel/kernel/service_registry.ex:295`) yet no code path calls `submit_experiment`. Idle.

## 3. Duplicate directors / orchestrators inventory

| Module | Booted? | Doing research? |
|---|---|---|
| `TiannaraOS.ResearchDirector` (`os/research_director.ex`) | NO — zero refs repo-wide | No; also contains latent self-call deadlock: `calculate_resource_allocation` → public `calculate_priorities/0` → `GenServer.call(__MODULE__)` while already inside handle_call (:377-381 vs :96-98) |
| `Domains.ResearchDirector` | YES (application.ex:163) | No — dispatch shim; sole caller is observatory metrics |
| `Research.ResearchDirector(.Pipeline)` | YES (application.ex:175) | Yes — full pipeline executing **random-data experiments** |
| `Research.Director` (+EvidenceDriven) | YES via Sentinel.Supervisor (sentinel/supervisor.ex:37 ← app:132) | Designs from Sentinel events; stops at approval gate; target = coin-flip Sandbox |
| `Omega.ResearchDirector(Server)` / `Agency.*` | NO (Omega.Supervisor unbooted) | Proposes-only by design; dormant |
| `ASC.Research.Director` | Flag-gated off (default false) | Timer re-sorts empty program list |

## 4. Stub call sites inside LIVE runners (provenance theater)

- `os/recursive_civilization_runner.ex:352` → stub `ScientificCapitalLedger` always returns `{:ok, 0}` (4-line stub verified); runner's ledger identity hash (:725-728) hashes the literal string `"ScientificCapitalLedger"` — **provenance theater**. A *second*, real ledger exists at `os/kernel/scientific_capital_ledger.ex` (used by constitutional invariant registry :484,:515) → two competing ledgers.
- `LifecycleRegistry` consumers (`os/research_economy.ex:235,284`, `provenance_tracker.ex:230`, `principle_registry.ex:217,243,270`, `domain_registry.ex:260,287`, `institution_kernel.ex:3578,4143,4234,4337`) hit a stub or log "would have been called".
- `discoveries/theory_selection.ex:378` embeds `use Tiannara.Stub` inside a live module.
- ASC hardcode: `asc/autonomous_discovery.ex:55-61` hardcoded Physics-gravity + Chemistry-catalyst experiment list; zero callers.

## 5. Do autonomous closed loops exist today?

**Yes — two, of very different integrity:**

- **Loop A (structurally complete, epistemically fake):** HeartbeatEngine 5s (`heartbeat_engine.ex:77`) → ECR/Agency advance → Research.ResearchDirector dequeues → plans → **fabricates results** → scores → integrates into persistent memory at confidence ≥ 0.7 (`research/research_director.ex:142-171`). Runs forever without humans. **Every measurement is random.**
- **Loop B (real but narrow):** `Operations.AutonomousLoop` 5-min (`autonomous_loop.ex:131`, supervised app:160) triggers DiscoveryScheduler every 30 min → reads live world model → contradictions/gaps → templated hypotheses/predictions/experiments → ranks, selects 3 → real workflows (divergence measurement over seeded observations) → outcome evidence → `WorldStateSynchronizer` writes back into world model (:84) → next cycle re-scans the mutated world. Genuinely closed; restricted to divergence measurement.

**Human gates today:** Sentinel approval before Sandbox execution (`sentinel/activation/approval.ex:18-49`); `approve_experiment/1` status gate (`research/director.ex:202-211`); Council `:high_risk_experiment` authorization inside idle orchestrator; Ω.4 deployment gates and ASC adoption gates (unbooted/off).

## 6. New critical finding (this campaign)

**F-NEW-1 (CRITICAL): Fabricated-evidence loop is LIVE in the supervision tree.** Loop A persists random-data-derived conclusions into persistent memory every heartbeat window, violating the system's own "Evidence Before Confidence" constitution. Any remediation built atop current persistent memory inherits poisoned priors. Remediation prerequisite R0 (quarantine) is defined in the master report §6.

## 7. Acceptance test for MC-003 (proposed)

P16-AT: With supervision booted and no human action for ≥2h: (a) UnknownRegistry non-empty and growing from kernel-detected contradictions; (b) ≥1 experiment executed exclusively via `Phase4.ExperimentOrchestrator.submit_experiment`; (c) every persisted knowledge record carries experiment_id + provenance chain resolving to Tier-2-or-better execution (no `:rand.uniform` in ancestry); (d) uncertainty updates computed from evidence distributions, not fixed ±0.1; (e) Loop A path provably unreachable (compile-time removal or feature-flag default-off).
