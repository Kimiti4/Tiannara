# R0 Section B — Knowledge, Epistemics, and Evidence (Capability Atlas)

**Phase:** R0 read-only discovery · **Branch:** `local/pr4` · **Date:** 2026-10-20
**Canonical list:** `certification/atlas/R0_SOURCE_PLAN.txt:171-210` (Section B, CAP-EPI-001..014) + discovered extras CAP-EPI-101/102.
**Method:** static greps/reads of `lib/`, `tiannara_runtime/lib/`, `forward_provenance/`, `docs/`, `.github/workflows/`, plus reuse of prior audits (`certification/audit/DIRECTORY_AUDIT_2026-10-19.md`, `PHASE_5F_WIRING_AUDIT.md`, `GENSERVER_OWNERSHIP_INVENTORY.md/.csv`, `GENSERVER_RECONCILIATION.csv`, `PHASE_5F_STATUS_CORRECTION.md`, `PRODUCTION_READINESS_SCAN.md`, `TIANNARA_CAPABILITY_SCAN.md`) and scanner outputs (`audit_output/tiannara_marker_findings.csv`).
**Evidence rules applied:** no test was run in R0 (test definition ≠ test ran); no CI was re-executed (historical CI green ≠ proof); documentation ≠ implementation; Unknown ≠ PASS. Every claim below carries path+line/symbol refs.

**Companion CSV:** `certification/atlas/capabilities_B_epistemics.csv` (16 data rows).

---

## Per-capability assessments

### CAP-EPI-001 · Universal Epistemic Payload (UEP)
- **Spec vs code:** Spec exists only in the source plan (`R0_SOURCE_PLAN.txt:179` — "schema enforcement at every producer and consumer"). Code: repo-wide grep `UEP|universal_epistemic|Universal Epistemic` over `*.ex` returns **0 hits** (sole match is unrelated prose in `markdown/55.md:14292`). The telemetry protos (`lib/tiannara/telemetry/report_slice.proto`, `world_state.proto`) are entropy/world-state schemas with **no** epistemic/uncertainty/lineage fields — they are not a UEP schema.
- **Connected:** no producers, no consumers, no validators.
- **Tests:** none exist.
- **Runtime evidence:** none.
- **Unknowns:** whether an off-repo UEP spec exists (ISD schemas referenced by the plan were not found under `docs/` — `docs/` has no ISD/UEP schema files).
- **Competitors:** `TiannaraOS.Provenance.Envelope` (`forward_provenance/lib/envelope.ex`), `Tiannara.Evidence.Provenance` (`lib/tiannara/evidence/provenance.ex:50,80`), `Tiannara.Sentinel.EpistemicEvent`, `TiannaraRuntime.WorldModel.Ontology.Evidence` — four partial payload vocabularies, none enforced as "UEP".
- **State:** `missing_or_unresolved` / `CONTRADICTED` / confidence **high**.

### CAP-EPI-002 · Blackboard
- **Spec vs code:** Spec `R0_SOURCE_PLAN.txt:181` (atomic updates, ownership, consistency, stale data). Code: `lib/tiannara/executive/cognitive/executive_blackboard.ex` — GenServer, `post/2` = `GenServer.cast` (`:21-23`), per-topic cap 100 (`:14`), single in-memory map (`:51-59`).
- **Connected:** **boot-wired** — `lib/tiannara/application.ex:230` starts `ExecutiveCognitiveRuntime`, whose child map starts `ExecutiveBlackboard` (`executive_cognitive_runtime.ex:75-76`). Producers/consumers: `executive_cycle.ex:63,139,150,161,166`, `reflection_engine.ex:49`, `omega/agency_loop.ex:58,136`, `executive_cognitive_runtime.ex:53`.
- **Tests:** `test/executive/cognitive/ecr_test.exs:10-49` covers post/read/read_latest/topics/clear/status/overflow — defined, not run in R0.
- **Runtime evidence:** none dynamic in R0.
- **Unknowns:** cross-process atomicity beyond single-GenServer serialization; behavior on ECR restart (state lost); no writer ownership or staleness semantics anywhere in the module.
- **Competitors:** none in root app.
- **State:** `implemented_incompletely_verified` / `PARTIAL` (prior audit inventory row 211 "no start path" is **contradicted** by code — see F-EPI-004) / confidence **medium**.

### CAP-EPI-003 · Knowledge Graph
- **Spec vs code:** Spec `R0_SOURCE_PLAN.txt:183` (actual query paths and provenance). Code: `lib/tiannara/knowledge_graph/registry.ex` — NDJSON file at relative path `data/knowledge_graph.ndjson` (`:4-8`), `get/1` = full linear scan (`:41-44`), `save/1` = whole-file rewrite (`:49-72`).
- **Connected:** single production writer found: `lib/tiannara/asc/laws/registry.ex:258` (`KnowledgeGraph.Registry.save`).
- **Tests:** `test/tiannara/domains/domain_projection_test.exs` (aliases KG); `tiannara_runtime/test/tiannara_runtime/mathematics/mathematics_knowledge_graph_test.exs` — defined, not run.
- **Runtime evidence:** file tracked in `audit_output/tiannara_file_inventory.csv`; no dynamic query observed.
- **Unknowns:** whether data/knowledge_graph.ndjson exists in a fresh checkout; provenance verification path for nodes.
- **Competitors:** `TiannaraRuntime.Mathematics.MathematicsKnowledgeGraph`; CPL checkpoint store `tiannara_runtime/data/cpl/checkpoints/knowledge_graph/*.json` (runtime-persisted); root `Tiannara.World.*` graph modules. `TIANNARA_CAPABILITY_SCAN.md:40` still calls `Tiannara.KnowledgeGraph` a namespace placeholder — **stale** (source exists).
- **State:** `implemented_incompletely_verified` / `PARTIAL` / confidence **medium**.

### CAP-EPI-004 · Evidence Assessment
- **Spec vs code:** Spec `R0_SOURCE_PLAN.txt:185` (real evidence checks rather than default scores). Code: `lib/tiannara/evidence/provenance.ex` — `acceptable_as_evidence?/1` kind-gated (`:102-104`), `hash/1` (`:110`), `unknown/1` (`:80`); `lib/tiannara/evidence/certification_gate.ex`; `lib/tiannara/research/evidence_assessment.ex` + `evidence_scorer.ex`.
- **Connected:** `CertificationGate.evaluate/1` wiring remediated per prior audit (`PRODUCTION_READINESS_SCAN.md:287,293` — post-`f267dd31` runner evaluates every persisted evidence artifact and currently records honest `:rejected` verdicts). This is **prior-audit documentation, not re-observed in R0**.
- **Tests:** `test/research/evidence_scorer_test.exs`, `test/tiannara/discovery/evidence_integrator_test.exs`, `test/tiannara/os/stage5_evidence_lineage_test.exs` — defined, not run.
- **Runtime evidence:** none dynamic; the honest-rejection artifact claim rests on the prior audit.
- **Unknowns:** whether the gate runs in current CI; whether any source-quality score changes over time (re-assessment loop).
- **Competitors:** `TiannaraRuntime.WorldModel.Pipeline.EvidenceIngestion` (+ `evidence_ingestion_test.exs`); `Tiannara.World.EvidenceValidator`.
- **State:** `implemented_incompletely_verified` / `PARTIAL` / confidence **medium**.

### CAP-EPI-005 · Confidence Calibration
- **Spec vs code:** Spec `R0_SOURCE_PLAN.txt:187` (calibration data, sample size, drift, feedback). Code: `lib/tiannara/forecasting/calibration.ex` — Brier/log-loss/reliability, `@min_sample 5` → `INSUFFICIENT_DATA`, versioned methodology (`:3-24,46-54`); `TiannaraRuntime.Observability.CalibrationRunner` + `Tiannara.Audit.CalibrationRunner`.
- **Connected:** forecasting pipeline consumes `Calibration.score/3`; **no cross-system consumer found that feeds calibration error back into other components' confidences** (drift/feedback unproven).
- **Tests:** `test/tiannara/forecasting/calibration_test.exs`, `tiannara_runtime/test/observability_calibration_test.exs` — defined, not run.
- **Runtime evidence:** `certification/forecasting/runtime/EFDI_FA_001_FORECAST_LEDGER.jsonl` + boundary snapshots + stop reports exist on disk — **historical artifacts, not re-executed in R0**.
- **Unknowns:** current calibration state of live forecasts; drift monitoring.
- **Competitors:** `Tiannara.Discovery.Adaptive.BayesianPrioritizer.calibration_error/2` (`bayesian_prioritizer.ex:59-70`, heuristic "actual"); `Tiannara.EpistemicMirror.AccuracyAuditor` (CAP-EPI-101).
- **State:** `implemented_incompletely_verified` / `PARTIAL` / confidence **medium**.

### CAP-EPI-006 · Detector Trust Scoring
- **Spec vs code:** Spec `R0_SOURCE_PLAN.txt:189` (ground-truth validation and independent scoring). Code: `lib/tiannara/ecl/trust_engine.ex` — `compute_trust_score/2` (`:16`) with weights (`:7-13`); **`fetch_sentinel_accuracy/1` returns hardcoded `0.7`, comment "mocked for now" (`:51-55`)**.
- **Connected:** yes — `lib/tiannara/ecl/knowledge_exchange.ex:66,133,160` gate exchanges on trust; influence awards `:199,227,251`.
- **Tests:** none found for the trust engine.
- **Runtime evidence:** none.
- **Unknowns:** whether Sentinel ever publishes a real accuracy metric (comment implies not).
- **Competitors:** `ObservationBus.CIL.Federation.TrustPropagation`, `ObservationBus.CIL.Epistemic.TrustPropagator` (observatory umbrella).
- **State:** `partially_connected` / `CONTRADICTED` (spec demands ground truth; a constant stands in) / confidence **high**.

### CAP-EPI-007 · Evidence Ageing
- **Spec vs code:** Spec `R0_SOURCE_PLAN.txt:191` (domain-specific decay, correct application). Code: `lib/tiannara/temporal_decay/history_manager.ex` — declares `decay_rate: 0.95` (`:11`) but **no handler applies decay, no timer exists** (`:15-47`); prior audit `GENSERVER_OWNERSHIP_INVENTORY.csv:424` → `6_no_refs_at_all`.
- **Connected:** zero callers found (re-verified by grep in R0).
- **Tests:** none.
- **Runtime evidence:** none.
- **Unknowns:** none material for the classification (absence is well-evidenced).
- **Competitors:** `Tiannara.REA.OrbitMemory.Decay` (`discoveries/orbit_memory.ex:169`); OLEF entropy tracking (`TIANNARA_EPISTEMIC_SUBSTRATE_AUDIT.md:51`) — neither applies decay to evidence weight/confidence in a way found in R0.
- **State:** `missing_or_unresolved` / `CONTRADICTED` / confidence **high**.

### CAP-EPI-008 · Contradiction Registry
- **Spec vs code:** Spec `R0_SOURCE_PLAN.txt:193` (durable records, integrity, lifecycle). Code: `lib/tiannara/contradiction/engine.ex` — detection (`:46`), lifecycle FSM with illegal-transition rejection (`:24-31,114-141`), lineage append (`:87,121,136`), epistemic event emission (`:146-164`); confidence = evidence-count heuristic (`:104-109`). **No store of any kind** (records are plain structs returned to caller).
- **Connected:** no production callers of `Contradiction.Engine.*` found (grep over `*.ex` matched only the module itself); moduledoc claims Sentinel/Ω.2 consumption (`:4-5`) unverified.
- **Tests:** `test/tiannara/contradiction/engine_test.exs`, `test/tiannara/discovery/contradiction_analyzer_test.exs` — defined, not run.
- **Runtime evidence:** none.
- **Unknowns:** whether any subsystem persists `Record`s after detection (not found).
- **Competitors:** `Tiannara.Logic.Contradiction` (kernel delegate, `engine.ex:22,54`); `Tiannara.OED.Quarantine.ContradictionTracker` (`oed/supervisor.ex:14,25`, also `4_referenced_no_start_path` per inventory row 245); `ObservationBus.CIL.Epistemic.ContradictionDetector`; `tiannara_core/logic/contradiction_detector.py` (scanner flags `empty_return`/`pass_statement` at rows 1-4 of `audit_output/tiannara_marker_findings.csv`).
- **State:** `implemented_incompletely_verified` / `PARTIAL` (integrity/lifecycle real; durability absent) / confidence **medium**.

### CAP-EPI-009 · Bayesian Confidence
- **Spec vs code:** Spec `R0_SOURCE_PLAN.txt:195` (update beliefs using evidence and priors; mathematical correctness). Code: `lib/tiannara/discovery/adaptive/bayesian_prioritizer.ex` — frequency-count `learn/3` (`:21-47`), ranking (`:6-18`); no explicit prior/posterior math demonstrated.
- **Connected:** zero callers (grep matched only its `defmodule`).
- **Tests:** none found.
- **Runtime evidence:** none.
- **Unknowns:** whether `belief_state.ex`/`belief_systems.ex` implement an actual Bayesian update (only cited in `TIANNARA_EPISTEMIC_SUBSTRATE_AUDIT.md:22,36` as distributed math; not line-verified in R0).
- **Competitors:** `Tiannara.World.BeliefState`, `Tiannara.Reasoning.BeliefSystems`, JTMS documentation (`JTMS_PLUS_VERIFICATION_RESULTS.md`, doc-only).
- **State:** `implemented_incompletely_verified` / `UNKNOWN` / confidence **low**.

### CAP-EPI-010 · Uncertainty Disclosure
- **Spec vs code:** Spec `R0_SOURCE_PLAN.txt:197` (missing evidence cannot silently become certainty). Code: `lib/tiannara/os/unknown_registry.ex` — GenServer (`:50,94-108`) with open/priority/domain queries; `lib/tiannara/evidence/provenance.ex:80,102-104` makes `:unknown` provenance explicit and **non-acceptable as evidence**; `world/canonical_world_state.ex:39` declares unknowns vocabulary.
- **Connected:** six consumers call `UnknownRegistry` (`research_director.ex:207-464`, `mission_control.ex:164-426`, `executive_dashboard.ex:108-123`, `civilization_atlas.ex:187-430`, `institution_self_model.ex:596`, `research/director.ex:96`) but `GENSERVER_RECONCILIATION.csv:118` records **no start path** (`confirmed_referenced_no_start_path`) — calls would `exit` unless started elsewhere (not found in R0).
- **Tests:** no registry-named test found.
- **Runtime evidence:** none.
- **Unknowns:** actual process start location (control_center/service_registry hypothesis unverified); whether disclosure surfaces reach operators at runtime.
- **Competitors:** `ObservationBus.CIL.Epistemic.UnknownRegistry`; `Tiannara.SOPL.LawUnknownRegistry` (supervised — inventory row 405).
- **State:** `partially_connected` / `CONTRADICTED` / confidence **medium**.

### CAP-EPI-011 · Replay Packages
- **Spec vs code:** Spec `R0_SOURCE_PLAN.txt:199` (deterministic replay against frozen inputs). Code (multiple): `lib/tiannara/world/replay_engine.ex` — fail-closed `{:error, :replay_source_unavailable}` (`:70-75`), start-only-at-runtime (inventory row 469); `tiannara_runtime/lib/tiannara_runtime/multi_world/deterministic_replay.ex` — **records seeds and non-deterministic inputs** (`:8,24,42,47`); `world_model/autonomous_research/engines/experiment_planner.ex:16,23,104-115` — `deterministic_seed = SHA-256(program_id, gap_id, epoch_id)`; `world_model/pipeline/replay_pipeline.ex`; `TiannaraOS.Governance` replay family; `Tiannara.Sentinel.Shadow.ReplayEngine` family.
- **Connected:** forecasting replay tests + `Campaign03MillionStepReplay` imply callers; `World.ReplayEngine` has 4 callers but runtime-start-only (inventory row 469).
- **Tests:** `world/replay_engine_test.exs`, `world/chaos/replay_determinism_chaos_test.exs`, `forecasting/{replay,d3_replay,forecast_replay,d5_replay}_test.exs`, `tiannara_runtime/test/world_model/pipeline/replay_pipeline_test.exs` — all defined, **not run in R0**.
- **Runtime evidence:** `REPLAY_AUDIT.md` (root) is explicitly **spec-level** ("Evidence (in spec)", `:22-31`) — documentation, not implementation. `tiannara_runtime/REPLAY_AUDIT.md` not re-read in R0 (recorded as unknown).
- **Unknowns:** dynamic determinism of any stack; whether frozen-input replay actually runs in CI; seed handling unification across stacks.
- **Competitors:** `ReplayStore` umbrella (`tiannara_observatory/apps/replay_store` — full Postgres stack, out of main scope); `TiannaraRuntime.Mathematics.Validation.DeterministicReplay`; `TiannaraOS.Governance.{ReplayVerifier,ReplayAuditor,GovernanceReplayEngine,LongHorizonReplay}`.
- **State:** `implemented_incompletely_verified` / `PARTIAL` / confidence **medium**.

### CAP-EPI-012 · Provenance and Lineage
- **Spec vs code:** Spec `R0_SOURCE_PLAN.txt:201` (complete ancestry, verifiable artifact hashes). Code: `forward_provenance/` (path dep, `mix.exs:67`) — content-addressed identities `result_id = sha256(execution_id, attempt, payload_hash, canon-spec, lineage-spec)` and `metric_id = sha256(...)` (`metric_lineage.ex:19-24`), chain `SOURCE -> CONTRACT -> EXECUTION -> RESULT -> METRIC` (`:70`), `verify_lineage/verify_bundle` consumers (`:435,675`); `lib/tiannara/provenance/discovery_ledger.ex:11-15,24-30,46` — chain reconstruction from immutable events with `complete?` gate; `Evidence.Provenance.hash/1`.
- **Connected:** chaos integrity check consumes verdicts (`chaos/epistemic_integrity.ex:105-107`); certificate lifecycle verifies lineage (`certificate_issuance.ex:309,459-466`); CAE-facing `CertificateAuthorityBridge` (`certificate_authority_bridge.ex:26-30`) — note its own line `:222` records `decision policy ABSENT`.
- **Tests:** `discovery_lineage_test.exs` is the target of dedicated CI job **`lineage-regression`** (`.github/workflows/elixir_ci.yml:59,80`); also `evidence_lineage_properties_test.exs`, `chaos/epistemic_integrity_test.exs`, `forecasting/provenance_test.exs` — defined, not run in R0 (historical CI green ≠ current proof).
- **Runtime evidence:** `data/identity_authority_ledger.jsonl` exists untracked (git status) — indicates past runs, not proof.
- **Unknowns:** current pass status of `lineage-regression`; whether CAE consumes the bridge at runtime (Section C scope).
- **Competitors:** `lib/tiannara/lineage/{store,entry}.ex`; `lib/tiannara/os/provenance_tracker.ex` (**zero refs** — inventory row 306); `lib/tiannara/world/provenance_engine.ex` (runtime-start-only — row 467); `ReplayStore.CausalLineage`.
- **State:** `implemented_incompletely_verified` / `PARTIAL` / confidence **medium**.

### CAP-EPI-013 · Ontology Management
- **Spec vs code:** Spec `R0_SOURCE_PLAN.txt:203` (versioning, migration, compatibility, rollback). Code: at least six parallel ontologies — `lib/tiannara/world/ontology_manager.ex` (runtime-start-only, inventory row 466), `lib/tiannara/core/ontology/supervisor.ex:19-28` (Cache/Index/Vector, boot-reachable), `tiannara_runtime/world_model/ontology/*`, `tiannara_runtime/mathematics/ontology/*`, `tiannara_runtime/civilization/ontology/*`, `tiannara_runtime/lib/tiannara/core/ontology/*`.
- **Connected:** `Core.Ontology.Index` has 1 caller (inventory row 162); `World.OntologyManager` starts only via `cel/kernel/service_registry.ex` / `control_center.ex`; rollback exists as `Tiannara.OED.Rollback.OntologySnapshots` (`oed/supervisor.ex:17,103-109` root and `tiannara_runtime/lib/tiannara/oed/supervisor.ex:25-30`).
- **Tests:** `tiannara_runtime/test/world_model/ontology_test.exs`, `test/civilization/ontology/ontology_test.exs`, `test/tiannara_runtime/mathematics/ontology_test.exs` — defined, not run.
- **Runtime evidence:** root artifact `ontology_manager.dets` present (historical).
- **Unknowns:** migration/compatibility testing (none found); whether OED snapshots are populated in practice.
- **Competitors:** see code list above; certification campaign `campaign_09_ontology_evolution.ex` (spec-adjacent).
- **State:** `partially_connected` / `CONTRADICTED` (no single maintainer; spec's four guarantees only partially evidenced) / confidence **medium**.

### CAP-EPI-014 · Active Learning
- **Spec vs code:** Spec `R0_SOURCE_PLAN.txt:205` (evidence-driven experiment selection and validation). Code: `engines/knowledge_gap_prioritizer.ex` — fail-closed (`ScoringConfigMissing :36`, `GapFieldMissing :42`, `GapProvenanceMissing :48`), per `KNOWLEDGE_GAP_PRIORITIZATION.md:34,52` deterministic tie-break and no default weights; `experiment_planner.ex:16,23,104-115` deterministic seeds; `experiment_scheduler.ex:85-128` schedule + interruption handling; `lib/tiannara/research/director.ex:433-455` gap identification.
- **Connected:** Research Director boot-started (`application.ex:227`); the gap→priority→plan→schedule chain is exercised by `validation_campaign_test.exs` (tie-break assertions `:200,223-338`). **`experiment_selection.ex` (planned at `forecast.md:1856`) does not exist** (glob = 0).
- **Tests:** `validation_campaign_test.exs`, `phase16_1_test.exs`, `phase16_1_comprehensive_test.exs` — defined, not run.
- **Runtime evidence:** none dynamic in R0; experiment checkpoints on disk (`tiannara_runtime/data/cpl/checkpoints/experiments/*.json` untracked) hint at past runs without proof.
- **Unknowns:** end-to-end experiment execution + result validation loop; whether prioritizer output is consumed by a booted process.
- **Competitors:** `Tiannara.Discovery.Adaptive.BayesianPrioritizer` (implemented, zero callers); `lib/tiannara/os/research_director.ex` unknown-driven research debt (heuristic, `TIANNARA_EPISTEMIC_SUBSTRATE_AUDIT.md:66`).
- **State:** `implemented_incompletely_verified` / `PARTIAL` / confidence **medium**.

### CAP-EPI-101 · Epistemic Mirror stack (discovered extra)
- Six modules under `lib/tiannara/epistemic_mirror/` (`mirror_registry`, `accuracy_auditor`, `risk_detector`, `collapse_predictor`, `topology_lineage_tracker`, `topology_mapper`) + `lib/tiannara/epistemic/{view,node,debugger}.ex`; root `scripts/run_mirror_gauntlet.exs` present (run status unknown). Overlaps CAP-EPI-005/010. **State:** `implemented_incompletely_verified` / `UNKNOWN` / confidence **low**.

### CAP-EPI-102 · Observatory Epistemic CIL (discovered extra)
- `tiannara_observatory` umbrella holds `ObservationBus.CIL.Epistemic.{ContradictionDetector,TrustPropagator,UnknownRegistry}` (`cil/epistemic/supervisor.ex:17`, `observation_bus.ex:160,166`) and a full `ReplayStore` stack. Outside the declared main-code scope (`tiannara_runtime/lib/`, root `lib/`); presence recorded to avoid double-counting with CAP-EPI-006/008/010/011. **State:** `specified_not_proven` / `UNKNOWN` / confidence **low**.

---

## Draft findings

### F-EPI-001 — UEP does not exist anywhere in the codebase
- **Severity:** critical · **Confidence:** high
- **Evidence:** repo-wide grep `UEP|universal_epistemic|Universal Epistemic` over `*.ex` = 0 hits (only `markdown/55.md:14292` false positive); `lib/tiannara/telemetry/report_slice.proto` and `world_state.proto` contain no epistemic fields; no UEP validator/validator-test file exists.
- **Affected caps:** CAP-EPI-001 (direct); CAP-EPI-003/004/006/008/009/010/012 (all use ad-hoc payload shapes instead of a common schema).
- **Root cause / HYPOTHESIS:** the canonical list was authored against an external architecture doc; the schema was never instantiated in-repo (or exists outside this checkout — unverified).
- **Minimal remediation:** define a single UEP schema artifact (JSON Schema or `.proto`) with `evidence/uncertainty/lineage` fields; inventory which existing payload types map to it (Envelope, Evidence.Provenance, EpistemicEvent); add one producer-side `validate/1` and one consumer-side guard plus contract tests.
- **Acceptance criteria:** schema file committed; ≥1 producer and ≥1 consumer enforce it with failing-on-invalid tests; grep for `UEP`/schema symbol returns non-zero production hits; reconciliation re-classified to MATCHED.

### F-EPI-002 — Evidence Ageing is inert: decay is configured but never applied
- **Severity:** high · **Confidence:** high
- **Evidence:** `lib/tiannara/temporal_decay/history_manager.ex:11` (`decay_rate: 0.95`), handlers `:15-47` apply no decay, no timer/schedule; `GENSERVER_OWNERSHIP_INVENTORY.csv:424` `6_no_refs_at_all`; R0 grep of callers = 0.
- **Affected caps:** CAP-EPI-007 (direct); CAP-EPI-004/006 (stale evidence/trust weights never reduced).
- **Root cause / HYPOTHESIS:** scaffold written with intended config, wiring never completed; module later orphaned.
- **Minimal remediation:** either implement an explicit `apply_decay/2` used by a consumer (e.g., evidence scoring) with domain-specific half-life, or formally retire the module in the capability register (do not delete without approval).
- **Acceptance criteria:** a call path where older evidence measurably lowers weight/confidence, covered by a test asserting two timestamps differ; or a signed deferral recorded and CAP-EPI-007 spec marked deferred.

### F-EPI-003 — Detector trust score feeds a mocked ground truth
- **Severity:** high · **Confidence:** high
- **Evidence:** `lib/tiannara/ecl/trust_engine.ex:51-55` — `fetch_sentinel_accuracy(_civ_id)` returns `0.7`, comment "mocked for now"; 25% weight (`:9`); consumed by `knowledge_exchange.ex:66,133,160` to gate real exchanges.
- **Affected caps:** CAP-EPI-006 (direct); CAP-EPI-005 (calibration never validates this term).
- **Root cause / HYPOTHESIS:** Sentinel accuracy metric never implemented; placeholder survived integration.
- **Minimal remediation:** wire `fetch_sentinel_accuracy` to a computed rolling accuracy from recorded predictions/outcomes (or fail closed with `:insufficient_data` score semantics), and add a test proving the value varies with inputs.
- **Acceptance criteria:** no literal constant in the trust input path; unit test with two different accuracy histories yields different scores; score source documented.

### F-EPI-004 — Process-start truth conflicts: UnknownRegistry has consumers but no start path; Blackboard inventory row is stale
- **Severity:** high · **Confidence:** medium (Blackboard half: high — verified directly)
- **Evidence:** (a) `GENSERVER_RECONCILIATION.csv:118` `TiannaraOS.UnknownRegistry … confirmed_referenced_no_start_path` while six modules call it (`research_director.ex:207`, `mission_control.ex:164`, `executive_dashboard.ex:108`, `civilization_atlas.ex:187`, `institution_self_model.ex:596`, `research/director.ex:96`); (b) `GENSERVER_OWNERSHIP_INVENTORY.csv:211` says `ExecutiveBlackboard … 4_referenced_no_start_path`, but `application.ex:230` boots `ExecutiveCognitiveRuntime` whose child map starts it (`executive_cognitive_runtime.ex:75-76`).
- **Affected caps:** CAP-EPI-010 (disclosure may crash or never serve), CAP-EPI-002 (inventory misclassification → false unwired verdict).
- **Root cause / HYPOTHESIS:** inventory generator did not traverse ECR's hand-written child maps; UnknownRegistry may be started only at runtime by control-center paths not captured as supervision.
- **Minimal remediation:** locate/record the actual start site of `TiannaraOS.UnknownRegistry` (grep `UnknownRegistry,`/`start_link` in control_center/service_registry) and correct the inventory row for both; if none, start it under an approved supervisor.
- **Acceptance criteria:** both inventory rows match code; boot test or `Process.whereis` assertion for UnknownRegistry after app start; CAP-EPI-010 re-assessed.

### F-EPI-005 — Contradiction registry is non-durable and unwired; Bayesian prioritizer is unwired and untested
- **Severity:** medium · **Confidence:** medium
- **Evidence:** `contradiction/engine.ex` has no store (`:69-89` builds in-memory structs); R0 grep: zero production callers of `Contradiction.Engine.*`; `bayesian_prioritizer.ex` grep = only its own `defmodule`; no tests matching bayes/trust.
- **Affected caps:** CAP-EPI-008, CAP-EPI-009.
- **Root cause / HYPOTHESIS:** both implemented as libraries with lifecycle/math but never integrated into a persisted registry or decision loop; spec's durability/mathematical-correctness audit focus unmet.
- **Minimal remediation:** persist `Record` to a GenServer/ETS/DETS registry with lifecycle transitions enforced on write; wire `detect/1` output to a booted consumer; add posterior-update tests for the Bayesian path or mark CAP-EPI-009 specified-not-proven.
- **Acceptance criteria:** contradiction survives process restart (test asserts re-read); ≥1 booted consumer of `to_epistemic_event/1`; Bayesian update tested against a closed-form example or formally reclassified.

### F-EPI-006 — Knowledge Graph: non-atomic full-file persistence, linear-scan queries, single writer
- **Severity:** medium · **Confidence:** medium
- **Evidence:** `knowledge_graph/registry.ex:49-72` (whole-file rewrite, `File.write!` no lock), `:41-44` linear scan; single production caller `asc/laws/registry.ex:258`.
- **Affected caps:** CAP-EPI-003.
- **Root cause / HYPOTHESIS:** prototype storage chosen before query requirements; provenance/path focus never built.
- **Minimal remediation:** atomic replace (`File.rename` temp→target), in-memory index cache, and a dedicated registry test; register the CPL checkpoint store as competitor or authority.
- **Acceptance criteria:** crash-safety test (interrupted write leaves valid file); query complexity test (no full re-read per `get`); ownership decision recorded for competing stores.

### F-EPI-007 — Evidence gate wiring claim rests on prior-audit documentation only
- **Severity:** medium · **Confidence:** medium
- **Evidence:** `PRODUCTION_READINESS_SCAN.md:287-293` documents remediation `f267dd31` (gate called, artifacts honestly `:rejected`); R0 did not re-observe any run.
- **Affected caps:** CAP-EPI-004.
- **Root cause / HYPOTHESIS:** none adverse — documentation is credible but stale-prone per evidence rules.
- **Minimal remediation:** re-run the targeted gate test (Phase R1 dynamic step) or add CI coverage invoking `CertificationGate.evaluate/1`.
- **Acceptance criteria:** a recorded dynamic run (test/CI log, dated post-R0) showing gate verdicts; basis upgraded to `dynamically_observed`.

### F-EPI-008 — Calibration exists but no system-wide drift/feedback loop is evidenced
- **Severity:** medium · **Confidence:** medium
- **Evidence:** `forecasting/calibration.ex:3-24` real metrics; R0 found no consumer applying calibration error to other components; `bayesian_prioritizer.ex:67` "actual" is itself a `confidence > 0.7` heuristic.
- **Affected caps:** CAP-EPI-005, CAP-EPI-009.
- **Root cause / HYPOTHESIS:** calibration built as a reporting tool in the forecasting silo; cross-system feedback designed but not integrated.
- **Minimal remediation:** define one feedback edge (e.g., calibration error adjusts a confidence prior) with a test; document sample-size thresholds for drift alerts.
- **Acceptance criteria:** a code path where measured calibration changes a downstream parameter; drift threshold with sample-size gate tested.

### F-EPI-009 — Replay: spec-level audit only; ≥5 competing stacks; seeds handled in two unconnected places
- **Severity:** medium · **Confidence:** medium
- **Evidence:** `REPLAY_AUDIT.md:22-31` explicitly audits "in spec"; seed capture in `multi_world/deterministic_replay.ex:8,42,47` and `experiment_planner.ex:104-115`; competing stacks listed in CSV row 011; all replay tests defined but not run in R0.
- **Affected caps:** CAP-EPI-011 (also touches CAP-EPI-012 lineage hash).
- **Root cause / HYPOTHESIS:** replay evolved per-subsystem (governance, sentinel, forecasting, multi-world, observatory) without a canonical package format.
- **Minimal remediation:** pick one authoritative replay package format (frozen inputs + seeds + hash), map the others as contributors; run one determinism test end-to-end in R1.
- **Acceptance criteria:** documented authority decision; one dynamic replay test green post-R0; REPLAY_AUDIT re-scoped to implementation evidence.

### F-EPI-010 — Provenance fragmented across ≥4 stores, one with zero references
- **Severity:** medium · **Confidence:** medium
- **Evidence:** `GENSERVER_OWNERSHIP_INVENTORY.csv:306` (`os/provenance_tracker.ex` zero refs), `:467` (`world/provenance_engine.ex` runtime-start-only), `forward_provenance/` (active path dep), `lineage/store.ex` (present, callers not established in R0); CAE bridge self-reports `decision policy ABSENT` (`certificate_authority_bridge.ex:222`).
- **Affected caps:** CAP-EPI-012 (also 002/011 consumers of lineage).
- **Root cause / HYPOTHESIS:** layered accretion (Phase-era stores + forward_provenance program); consolidation deferred as destructive.
- **Minimal remediation:** declare an authority (recommended: `forward_provenance` MetricLineage for artifact lineage; DiscoveryLedger for discovery chains), mark others read-only/legacy in the register — no deletions without approval.
- **Acceptance criteria:** ownership table updated; zero-ref store either wired or formally marked deprecated; lineage-regression CI job run recorded post-R0.

### F-EPI-011 — Ontology management is fragmented; versioning/migration/rollback only partially evidenced
- **Severity:** medium · **Confidence:** medium
- **Evidence:** ≥6 ontology subsystems (CSV row 013); rollback only via `OED.Rollback.OntologySnapshots` (`oed/supervisor.ex:103-109`); no migration/compatibility tests found; `World.OntologyManager` runtime-start-only (inventory row 466).
- **Affected caps:** CAP-EPI-013.
- **Root cause / HYPOTHESIS:** ontologies grew per domain (world/math/civilization) with no registry authority.
- **Minimal remediation:** nominate one canonical ontology owner and one compatibility test (old → new migration), record the others as projections.
- **Acceptance criteria:** authority decision in register; migration test exists and runs in CI; `campaign_09_ontology_evolution` claims mapped to code.

### F-EPI-012 — Active learning loop incomplete: planned `experiment_selection.ex` absent; end-to-end selection→validation unproven
- **Severity:** medium · **Confidence:** medium
- **Evidence:** `glob **/experiment_selection*.ex = 0` vs plan reference `forecast.md:1856`; chain stops at scheduler (`experiment_scheduler.ex:85-128`); no R0 evidence of experiment execution/result validation at runtime (checkpoint files untracked, historical).
- **Affected caps:** CAP-EPI-014 (also CAP-EPI-005/009 downstream).
- **Root cause / HYPOTHESIS:** planner built (with strong fail-closed + deterministic seeds) before the selection/execution stages.
- **Minimal remediation:** implement or explicitly defer `experiment_selection`; record where scheduled experiments actually execute and how results re-enter scoring.
- **Acceptance criteria:** a traced chain gap→prioritizer→planner→scheduler→**execution**→result feedback with a test at the last edge; or documented deferral reclassifying CAP-EPI-014.

---

## Explicit unknowns (R0)
1. **No dynamic evidence:** zero tests were run, zero CI jobs executed, no runtime boot observed — all `tests` fields are *defined-not-run*; historical CI green (incl. `lineage-regression`, `39388434031`) is not current proof.
2. **UnknownRegistry start site:** not located (control-center/runtime-start hypothesis unverified) — CAP-EPI-010 could be worse (crashing) or fine (started dynamically).
3. **ISD schemas:** referenced by the plan as spec; not found under `docs/` or anywhere in-repo — existence outside checkout UNKNOWN.
4. **`tiannara_runtime/REPLAY_AUDIT.md`** (runtime-root copy) not read in R0 — its findings may differ from root `REPLAY_AUDIT.md`.
5. **tiannara_core (Python):** epistemic code present (`metacognition/epistemic_resilience.py`, `logic/contradiction_detector.py` with scanner `empty_return`/`pass` markers) but not line-audited in R0 — contribution to Section B UNKNOWN.
6. **Epistemic Mirror (CAP-EPI-101)** wiring/tests not established; `run_mirror_gauntlet.exs` run status unknown.
7. **Whether Sentinel/Ω consumers actually receive `:contradiction_detected` events** (moduledoc claim, unverified).
8. **EFDI calibration/forecast runtime artifacts** (`certification/forecasting/runtime/*`) provenance — exist on disk, but their generating runs were not re-verified.
