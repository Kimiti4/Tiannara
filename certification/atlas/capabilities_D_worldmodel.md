# Section D — World Model, Simulations, Research (R0 read-only discovery)

Scope: CAP-WRD-001..012 plus discovered extras CAP-WRD-101..108.
Companion machine-readable artifact: `certification/atlas/capabilities_D_worldmodel.csv` (20 rows).
Method: static source/inventory discovery + reuse of existing audits/CI evidence. No code changes, no git operations, no test runs, no re-run of historical campaigns. Evidence rules applied: Unknown ≠ PASS; docs ≠ implementation; test defined ≠ ran; unit ≠ e2e; simulated ≠ runtime.
Baseline: commit `521cb7fe513a466302ec3bb398940df3814edf2d`, dirty tree 1819 entries (recorded, not cleaned).

## CAP-WRD-001 — World Model

- Spec: persistent world model that owns entities, relations, causal structure, and validity tracking; model must be updateable and observable.
- Code: four-plus competing implementations. `Tiannara.World.*` (~6k LOC root: `unified_world_model.ex`, `version_manager.ex` 350 LOC, `knowledge_coordinator.ex`, `model_evolution.ex`) is the live store, started indirectly: `application.ex` core_children → `Tiannara.Operations.OperationsSupervisor` → `Tiannara.ControlCenter.init/0` → `boot_all_subsystems/1` (`lib/tiannara/control_center.ex:23`). `Tiannara.Core.WorldModel` is the documented canonical layer, booted via `Tiannara.ROS.ShardSupervisor`. `TiannaraRuntime.WorldModel.*` (~175 `.ex`: ontology, pipeline, causal_discovery, prediction, counterfactual, digital_twin, composition) is the richest stack but appears in no boot tree. `Tiannara.WorldModel` = 4 thin registries. Repo-root `world_model/` is data only (`self_profile.json`, `subsystem_beliefs.json`).
- Connected: root world model and ROS Core model are wired; runtime stack unwired; ControlCenter starts its ~29 subsystems from `init/0`, i.e. outside OTP supervision trees (crash-restart semantics unverified — F-WRD-010).
- Tests: root `test/tiannara/world` = 26 files (root CI suite green at baseline); `tiannara_runtime/test/world_model` = 39 files (runtime CI, 1854 green at baseline). Both are unit/property level.
- Runtime: no dynamic observation of model validity, update-correctness, or shard consistency gathered in R0 (read-only, no runs).
- Unknowns: whether `Tiannara.World` and `Tiannara.Core.WorldModel` reconcile state with each other at runtime; whether `TiannaraRuntime.WorldModel` is dead code or a pending migration.
- Competitors: see CSV `competing_impls`. No single authoritative owner — F-WRD-006.

## CAP-WRD-002 — Autonomous Simulation (ASC)

- Spec: autonomous simulation driver that generates and runs scenarios for the world model.
- Code: `lib/tiannara/asc/` (Autonomous Software Civilization, Phases 6–10), flag-gated: `config/config.exs:157` `asc: [enabled: true, deployment_mode: :artifact_only]`, children booted via `asc_children/1` in `application.ex`. Acronym collision with the plan's "Autonomous Simulation" — recorded, not resolved. Scenario generation via `asc/project_world` + `asc/reality/adapters/simulated_adapter.ex`.
- Connected: yes when flag on (it is on in config). `deployment_mode: :artifact_only` limits physical deployment paths.
- Tests: `test/tiannara/asc` = 32 files in the root CI suite (green at baseline); manifest test `test/asc/capability_manifest.exs`.
- Runtime: located result artifacts (`simulation_output/*.csv`, `phase5*_results.txt`) are synthetic/self-labeled per STAGE6 matrix and `docs/production_completion_baseline.md:161` (UNVERIFIED).
- Unknowns: any e2e simulation-to-reality loop actually exercised in production runtime.
- Competitors: unbooted `tiannara_runtime` WorldSimulationLoop; `tiannara_core/sim` python; API `MOCK_WORLDS`.

## CAP-WRD-003 — Civilizations and agent simulation

- Spec: simulate civilizations and agents with behavioral diversity and measurable health.
- Code: four layers. `Tiannara.UniverseServer` (runtime ecology, booted — `universe_supervisor.ex:15` required_child of the Ecology layer) + `TiannaraOS.CivilizationKernel` (booted in core_children) are the live processes; `TiannaraRuntime.Civilization.*` (61 `.ex`) is the detailed model but unbooted; ASC `civilization/` (13 engines) under the flag.
- Connected: partially — process shells boot, detailed runtime model does not.
- Tests: `tiannara_runtime/test/civilization` = 10 files; root ASC civilization tests (chaos/property/forecast/policy). Behavioral-diversity claim CLAIM-E04 is recorded UNTESTED (civics stubbed, metrics synthetic) in `certification/empirical_validation/TIANNARA_CLAIMS.json`.
- Runtime: `reports/world_health_epoch_*.csv` are mock (see F-WRD-001); `data/simulation_output/Civilization_*.csv` synthetic-labeled.
- Unknowns: actual runtime agent counts and population dynamics.
- Competitors: see CSV.

## CAP-WRD-004 — Multi-world experimentation

- Spec: run controlled comparisons across multiple worlds with reproducibility and kill-switch safety.
- Code: `tiannara_runtime/lib/tiannara_runtime/multi_world/` (world_supervisor, resource_quota, memory_manager, deterministic_replay 354 LOC, world_freeze, kill_switches, event_store) + `world_fork_engine.ex` + `world_registry_supervisor.ex` — none of it in any boot tree. Blocking defect: `world_supervisor.ex:58` supervises `{TiannaraRuntime.MultiWorld.WorldProcess, id}` but **`WorldProcess` has no source file in the repo** — spawn path cannot work (F-WRD-004). `mix tasks/cis.validate_phase5e.ex` references 7 nonexistent `MultiWorld.*` modules.
- Connected: no. Worse: consumers message it — `SafetyCortex` (`safety_cortex.ex:393-397`) sends freeze/kill to named processes that are never registered (`:noproc`), and `TiannaraRuntime.Evolution.Supervisor` fork path (`evolution/supervisor.ex:268`) depends on the broken fork chain. Reconciliation = CONTRADICTED.
- Tests: only 3 files touch KillSwitch/WorldSupervisor (`phase_5f3_5_integration_test.exs`, `cis/authorization_contract_test.exs`, `cis/boot_wiring_test.exs`); no dedicated multi_world suite. Not run in R0.
- Runtime: none. `fixes.md` (1111 lines) documents the missing-module error at line 1400.
- Unknowns: whether a fix existed on another branch/commit; whether the API exposes any multi-world surface (Elixir-side calibration endpoint existence unverified).

## CAP-WRD-005 — Generational evolution

- Spec: multi-generation evolution with traceable lineage and explicit selection criteria.
- Code: root `Tiannara.Evolution.EvolutionEngine` (booted via ControlCenter) + `Tiannara.ROS.EvolutionEngine` (booted); `tiannara_runtime/evolution/` (fitness engine, selection orchestrator, speciation, world pruning — supervisor defined, **not started**, fork path depends on broken CAP-WRD-004 chain); `tiannara_core/evolution/` 20 python files (5982 LOC); `TiannaraOS.Stage3/4/5` adaptation layers with **zero callers** (F-WRD-007).
- Connected: root engines only; the richer runtime selection loop never boots.
- Tests: root evolution tests are thin (13–19 LOC each: `law_fitness_evaluator`, `physics_mutator`, `integration_evolution_pipeline`); 5 runtime evolution test files touch related units but not the selection loop. None run in R0.
- Runtime/artifacts: `data/stage6/generation_history.csv` and `data/phase13_5/statistical/*/trial_*/generation_history.csv` exist and are tracked; per STAGE6 matrix the Stage3/4/5 lineage inputs feeding such pipelines are fabricated (hardcoded `evidence_quality: :strong`, `:rand.uniform` pilots, `rollback_confidence: 0.85` constants). Simulation-labeled.
- Unknowns: whether any generation count in circulation (e.g. "hundreds of generations") derives from runtime evolution vs. staged/simulated scripts.

## CAP-WRD-006 — Research orchestration

- Spec: orchestrate research loops from question through experiment to evidence-backed conclusion.
- Code: at least five orchestrators — root `Tiannara.Research.ResearchDirector` (booted), `Tiannara.Domains.ResearchDirector` (booted), `Tiannara.Research.Director` (398 LOC, unbooted), `tiannara_runtime` `Phase16_1.Orchestrator` (296 LOC, richest lifecycle, no supervisor in any boot tree), `world_model/autonomous_research/` engines (experiment_planner 446 LOC, scheduler, portfolio_optimizer, knowledge_gap_prioritizer — unbooted), plus ASC research under flag (F-WRD-006).
- Connected: two root directors only.
- Tests: `test/research` = 7 files (incl. `r0_quarantine_test.exs`); runtime `phase16_1` tests exist. Unit level; not run in R0.
- Runtime: the only disciplined end-to-end question→evidence loop observed anywhere in Section D is the EFDI forecasting track (CAP-WRD-101), which is forecasting-scoped — general research lifecycle not dynamically observed.
- Unknowns: which director is intended to win; whether orchestrator state handoffs (lineage, evidence) were ever exercised end-to-end.

## CAP-WRD-007 — Theory generation

- Spec: generate theories with novelty, falsifiability, and evidence requirements.
- Code: `Phase16_1.TheoryEngine`, `world_model/autonomous_research/engines/theory_updater.ex` (364 LOC, both unbooted), ASC `laws/{discoverer,experiment_designer,canonical_promotion_engine}` (flag-gated), root `tier6_discovery.ex`.
- Connected: ASC path only (flag on); runtime engines unwired.
- Tests: runtime `phase16_1` tests cover `theory_engine`; root meta-science tests. Unit level.
- Runtime/artifacts: `data/asc_archive/laws.ndjson` — 1000+ candidate laws with support/contradiction counts, retained refuted laws (falsifiability bookkeeping works), but most entries show `campaigns_tested=0`, `campaigns_survived=0`, confidence 0.18–0.43 — promotion gates appear not to have fired (CAP-WRD-107).
- Novelty: **FALSIFIED at function level** — CLAIM-E06 (certification `TIANNARA_CLAIMS.json`): discovery payloads recycler-identical to known sets. Any novelty-based theory-quality claim fails (F-WRD-008).
- Unknowns: whether any archived law has cleared independent verification.

## CAP-WRD-008 — Discovery tracking

- Spec: track discoveries with independent verification before promotion; avoid circular self-certification.
- Code: root `lib/tiannara/discovery/` (28 modules: DiscoveryEngine, tracking, certificate, constitutional_validation) with `DiscoverySupervisor` as sole owner, started post-CEL boot in `application.ex` `start_discovery_supervisor/0` (non-test only; the code comment itself records that it "was never started anywhere" historically). Runtime `DiscoveryRunner` **is a boot child** (StartupSupervisor) cycling every 60s.
- Connected: yes — but see defect below.
- Tests: root `test/tiannara/discovery` = 32 files (incl. advanced + integration pipeline + metric properties); runtime discovery tests limited. Unit level; not run in R0.
- Runtime: `DiscoveryRunner` seeds **canned challenges** with domains outside the canonical 20-domain ontology (`:mathematics`, `:cognitive_science`, `:complexity`) — inflates apparent discovery activity and contradicts the frozen ontology (F-WRD-009). CPL journals (`data/cpl/checkpoints/*`) are hash-chained. Promotion gate exists (`certificate` + `constitutional_validation` + `KnowledgeCoordinator` `:promoted` path) but correctness unverified.
- Unknowns: whether any promotion has passed the independent-verification gate on real (non-seeded) input.

## CAP-WRD-009 — Cross-domain reasoning (planned 20 domains)

- Spec: valid transfer of methods across 20 planned domains — transfer must be real, not superficial association.
- Code: `Tiannara.Domains.CanonicalRegistry` (`canonical_registry.ex:32-53`) freezes **exactly 20** domain IDs and is booted in core_children; 20 domain modules exist. **Nineteen are fail-closed quarantined stubs** (D-A3/A5 markers, e.g. `materials.ex:12-46`: `discover/validate → []`, `simulate → :unavailable`, `metrics → nil/:unavailable`). Only `physics.ex` (182–216 LOC) is substantive (ODE solve, Bayes update, provenance). Reconciliation = CONTRADICTED: spec says transfer, code constitutionally forbids it (F-WRD-005).
- Transfer evidence: `transfer_matrix.ex:78-109` **seeds 4 fabricated transfer-success entries (0.75–0.90)** into tracked `data/transfer_matrix.ndjson` — the only transfer-success numbers in the repo are hard-coded.
- Competing ontologies (three): CanonicalRegistry 20-set; API mock 10-domain lattice (`observatory.py:679-701`); `tiannara_core/domains` = vision only; plus `capability_registry.ex` aliasing `materials→materials_science`.
- Tests: `domain_quarantine_test.exs` locks the fail-closed behaviour (so the stubs are intentional, not broken). Not run in R0.
- Answer to the audit question: **20 domain modules exist; ~1 substantive; 19 stubs; zero dynamic evidence of a valid cross-domain transfer.**

## CAP-WRD-010 — Engineering and materials research

- Spec: engineering design plus materials/ancient-technology research with source-quality and physical-constraint checks.
- Code (designs): `lib/tiannara/engineering/` (13 files: synthesis engine booted via ControlCenter, design evaluator, proposal pipeline, `multi_objective_optimizer.ex` 87 LOC) + ASC `Engineering.Supervisor` (Phase 8, flag). **No consumers found beyond definition for the root engineering pipeline's supervisory wiring** (`EngineeringSupervisor` referenced nowhere else — partially confirmed gap).
- Code (materials/ancient tech): **absent.** Only the quarantined `Tiannara.Domains.Materials` stub. `sentinel/epistemic_archaeology.ex` is civ-history rediscovery, not materials research. `tiannara_pros` hardware scenarios (3 JSON) have zero tests.
- Tests: `engineering_optimization_test.exs`, ASC `digital_twin_test.exs`, `review_router_test.exs`. Unit level.
- Unknowns: whether design proposals are ever evaluated by the design evaluator in runtime; no materials experiment path exists to validate at all.

## CAP-WRD-011 — Optimization and numerical methods

- Spec: genuine solver implementations with reference tests.
- Code: `Tiannara.Math.Optimization` (`optimization.ex:15`) — real bounded gradient descent with line search, finite checks, convergence diagnostics, honest fail-closed bounds (`optimality: :local_stationary_candidate`, `certification_eligible: false`, `nash_equilibrium → :unavailable`); `foundations/mathematics/calculus.ex` RK4 ODE (171 LOC); thin shims for statistics (13 LOC), probability, graphs, information_theory (19 LOC); `engineering/optimization/multi_objective_optimizer.ex`.
- Connected: used by `Tiannara.Domains.Physics.evaluate/simulate` and ASC paths.
- Tests: `optimization_truthful_test.exs`, `mc004_m_calculus_rk4_test.exs`, `mc001_m_truthfulness_test.exs`, `probability_contract_test.exs` — in the root CI suite, green at baseline. This is the strongest MATCHED row in Section D: spec asks for genuine solvers + reference tests, and that is what exists, with no overclaiming.
- Unknowns: coverage/accuracy beyond the tested bounds (no global-optimality claims made by code or tests).

## CAP-WRD-102 — Digital twin stack (extra)

- `tiannara_runtime/.../digital_twin/engines/digital_twin_engine.ex` (159 LOC) + emergence/intervention/metrics engines — unbooted (parent tree not in any boot tree). Root ASC `digital_twin_test.exs` exercises a *different* subsystem. No runtime artifacts located. See F-WRD-003.

## CAP-WRD-103 — Causal discovery (extra)

- Runtime `causal_discovery/` (StructureLearner 435 LOC, IndependenceEngine, EdgeScorer, GraphValidator) — 17 test files, unbooted. `TiannaraRuntime.Causal.GCK` **is** wired (application children) and routes through WorldRegistry. Root `Core.CausalEngine` booted via ROS. Python `tiannara_core/causal` = 4118 LOC / 12 files. Caveat: the historical graph-verification path used `tiannara_audit` graph/proof verifiers that cannot fail (DIRECTORY_AUDIT §1.1) — so "verified graph" claims need independent re-checking.

## CAP-WRD-104 — Observatory calibration worlds (extra)

- `tiannara_api/routes/observatory.py:594-605` tries runtime `/calibration/worlds`, then falls back to `MOCK_WORLDS`; `populate_initial_reports()` (`:655-723`) self-describes as "mock historical hourly reports". All 5 committed `reports/world_health_epoch_*.csv` came from this generator (deterministic linear formulas). This is the **generating source of the historical scale claim** (F-WRD-001). Whether the runtime Elixir `/calibration/worlds` endpoint exists was not confirmed in R0 (unknown).

## CAP-WRD-105 — TiannaraOS Stage3/4/5 layers (extra)

- Pure functions with zero callers; the live pipelines they should replace fabricate their critical steps (`institution_adaptation_pipeline.ex`, `civilization_adaptation_pipeline.ex` 818 LOC with `:rand.uniform` improvements). Full prior audit reused: `STAGE6_ENGINE_CONTRACT_MATRIX.md`, `STAGE5_OUTCOME_VOCABULARY.md` (vocabulary is DESIGN ONLY). State = specified_not_proven. Must not be wired into any runner without data-layer un-stubbing.

## CAP-WRD-106 — Layer 6.5D institutional evolution ecology (extra)

- `civilization_scheduler.ex` + `run_layer6_5d_campaign.exs`: real long-running fixture execution (1.43h reported), but ESR/AFG headline metrics are **placeholder constants** (`calculate_esr → 1.2`, `calculate_afg → 0.05` at `:2000-2012`). `LAYER_6.5D_FINAL_VALIDATION_REPORT.md` carries an explicit SIMULATION-ONLY DISCLAIMER (2026-10-13). Do not cite as scientific evidence.

## CAP-WRD-107 — ASC Laws registry / discovery marketplace (extra)

- Flag-gated; real runtime artifact `data/asc_archive/laws.ndjson` (1000+ entries, support/contradiction bookkeeping, refuted laws retained). Quality caveat: most entries `campaigns_tested=0`, low confidence — the canonical promotion gate appears not to have fired (link to F-WRD-008).

## CAP-WRD-108 — Python research/evaluation/evolution stack (extra)

- `tiannara_core/{evaluation,evolution,discovery,research,sim,causal,prediction}` consumed by `tiannara_api/main.py:69-81` and root `tests/` pytest (CI `ci-cd.yml:49`; `tests/evaluation` = 14 files). Directory audit §4 verdict: "wired+tested (library; docs overclaim)"; achievement-markdown under `tiannara_core/tests` must be treated as non-evidence. R0 did **not** re-run pytest. ESAP/Python vs Elixir stacks never reconciled (no merged competitor).

## CAP-WRD-012 — Scientific evaluation

- Spec: scientific evaluation on held-out data with reproducibility.
- Code/evidence: three tiers.
  1. **Independently verified (bounded):** the EFDI forecasting track — see CAP-WRD-101 below. Preregistration, authorization chain, frozen forecasts, real BTC resolution, hash-chained `FORECAST_LEDGER.jsonl`, no-trust independent verifiers `EFDI_D{1..5}_independent_verification.py`, 354 runtime tests 0 failures at D5 certification, 25/25 D5 gates, with explicit §3 bounds.
  2. **Wired + CI-tested:** `tiannara_core/evaluation` (106 py files, 25918 LOC) with pytest in CI; `TiannaraRuntime.OS.Observatory.ValidationCampaigns` booted; 16 root forecasting tests.
  3. **Synthetic (must not be cited as runtime):** `SCIENTIFIC_VALIDATION_REPORT.md` + `LONG_HORIZON_REPORT.md` self-labeled SYNTHETIC with final gates FAIL (honest negatives); `run_phase15.exs` deterministic synthetic campaign; `tiannara_audit` graph/proof verifiers defective (cannot fail).
- Runtime: only tier 1 has genuine runtime evidence; the pilot honestly reports predictive information **NOT ESTABLISHED** against the pre-registered minimum sample — harness PASS ≠ predictive skill.
- Unknowns: whether any platform-internal candidate law or readiness claim has ever been certified on held-out, non-synthetic data outside forecasting.

### CAP-WRD-101 — Forecasting evaluation (EFDI FA-001) (extra)

The best-quality evidence in Section D: preregistration → authorization (`certification/forecasting/authorization/*`) → frozen forecast → post-window resolution → Brier/log-score → hash-chained append-only ledger → independent verification, with a single sanctioned register path (`Forecast.version/2 → ForecastRegistry.register/1`) as anti-laundering. Verdict: `verified_operational / MATCHED` **within its stated bounds**; Q2 (predictive skill) not established. None of this generalizes to non-forecasting research without new preregistered tracks.

## Draft findings

- **F-WRD-001 (HIGH)** — The historical scale claim (12 worlds / 84 civilizations / 23800 agents) traces **only** to `tiannara_api/routes/observatory.py` `MOCK_WORLDS` (`:554-567` hard-coded 12 biases; `range(12)`; civilizations `random.randint(4,12)`; agents `random.randint(500,3500)` at `:824-826`) and its mock CSV writer (`populate_initial_reports`, self-described "mock historical"). Committed `reports/world_health_epoch_*.csv` (5 files) are mock interpolations with no civ/agent columns. Prior audits already mark it UNVERIFIED (`docs/closureaudit.md:~1232`, `docs/production_completion_baseline.md:161`). Classification: `historical_claim_unreproducible` (traced to mock generator; not a runtime result). Affects CAP-WRD-002/003/004/104.
- **F-WRD-002 (HIGH)** — **GRCC 74.8% and MSCL 88.5% are untraceable**: no generating code, dataset, result artifact, or metric definition exists anywhere in the repo (searched .py/.ex/.exs/.md/.txt/.json/.yaml/.csv); their sole occurrence is `R0_SOURCE_PLAN.txt:153` (the plan text itself). Classification: `historical_claim_unreproducible`. Contradicting evidence: `certification/audit/TIANNARA_RUNTIME_TEST_INVENTORY.md:101` shows the MSCL metric staying 0.0 across perturbation, and `certification/atlas/baseline.md:80` records MSCL metric 0.0 open. Neither figure may appear in any acceptance criterion. Affects CAP-WRD-003/005 and Section D gates.
- **F-WRD-003 (HIGH)** — The `tiannara_runtime` research/simulation stacks (`world_model` ~175 modules, `civilization` 61, `multi_world`, `evolution`, `autonomous_research` ≈ 350+ modules total) are **absent from every boot tree** (`StartupSupervisor` = CPL → Omega → Observatory → Phoenix → RootSupervisor → DiscoveryRunner; RootSupervisor layers = Infrastructure/Execution/Ecology/Constraint/Meta; runtime app adds CIS/ExecutionController/QuotaGovernor/LineageCompression/GCK). They have substantial unit tests (green in runtime CI) but zero runtime wiring: `partially_connected` at best. Affects CAP-WRD-001/003/004/005/006/007/102/103.
- **F-WRD-004 (HIGH)** — `TiannaraRuntime.MultiWorld.WorldProcess` **does not exist** while `world_supervisor.ex:58` supervises it → multi-world spawn is broken; `mix tasks/cis.validate_phase5e.ex` references 7 nonexistent `MultiWorld.*` modules; `SafetyCortex`/`CIS` message named processes that are never registered (`:noproc`); `multi_world/fixes.md:1400` documents the missing module. Reconciliation for CAP-WRD-004 = CONTRADICTED.
- **F-WRD-005 (HIGH)** — Cross-domain capability is specified, registered (exactly 20 domains), **and constitutionally disabled**: 19/20 domain modules are fail-closed quarantined stubs; the only transfer-success numbers in the repo are 4 hard-coded seeds (0.75–0.90) written by `transfer_matrix.ex:78-109`; three divergent domain ontologies coexist (canonical 20 / mock API 10 / vision-only python). `specified_not_proven` / CONTRADICTED. Affects CAP-WRD-009/010.
- **F-WRD-006 (MEDIUM)** — No single authoritative implementation anywhere in Section D: 4+ world models, 4–5 research orchestrators, 3+ discovery systems, 2 research directors booted simultaneously. The one-cap-one-impl closure rule is violated across the section (`partially_connected` rows driven by ownership ambiguity, not just missing code). Affects CAP-WRD-001/006/008/009.
- **F-WRD-007 (MEDIUM)** — Simulation-over-simulation laundering risk: STAGE6/STAGE5 audits show fabricated inputs (`evidence_quality: :strong` constants, `:rand.uniform` improvements, `rollback_confidence: 0.85`, hardcoded pilots) feeding artifacts (`generation_history.csv`) that circulate as results, alongside self-labeled SYNTHETIC reports (`SCIENTIFIC_VALIDATION_REPORT.md`, `LONG_HORIZON_REPORT.md`, `LAYER_6.5D_FINAL_VALIDATION_REPORT.md`) whose disclaimers must be preserved whenever cited. Affects CAP-WRD-002/003/005/012/105/106.
- **F-WRD-008 (MEDIUM)** — Discovery/theory novelty is **FALSIFIED at function level** (CLAIM-E06: recycled payloads identical to novel), and archived laws show `campaigns_tested=0` / low confidence — so theory-generation and discovery-quality claims cannot pass R1+ on current evidence. Affects CAP-WRD-007/008/107.
- **F-WRD-009 (MEDIUM)** — The **booted** `DiscoveryRunner` seeds canned challenges using non-canonical domain atoms (`:mathematics`, `:cognitive_science`, `:complexity`) outside the frozen 20-domain ontology — inflating discovery activity and contradicting the canonical registry. Affects CAP-WRD-008/009.
- **F-WRD-010 (LOW–MEDIUM)** — `ControlCenter.init/0` boots ~29 subsystems (world model, simulation, evolution, engineering, discovery quality/certifier…) from `GenServer.init`, i.e. **outside OTP supervision trees** — they are started but their crash-restart semantics are unverified; this is the actual boot mechanism for most root-side Section D subsystems. Affects CAP-WRD-001/005/006/010.

## Historical claim provenance

| Claim | Occurrences found | Generating code / data | Classification |
|---|---|---|---|
| 12 worlds / 84 civilizations / 23800 agents (scale run) | `R0_SOURCE_PLAN.txt:153`; `docs/closureaudit.md:~1232` (UNVERIFIED); `docs/production_completion_baseline.md:161` (UNVERIFIED) | `tiannara_api/routes/observatory.py` `MOCK_WORLDS` `:554-567` + `:655-723` + `:824-826` (civs `randint(4,12)`, agents `randint(500,3500)`, `range(12)`); output = `reports/world_health_epoch_*.csv` (mock, no civ/agent columns) | `historical_claim_unreproducible` — `partially_traceable` to a mock generator; NOT a runtime result; must not be re-run or cited as evidence |
| GRCC 74.8% | `R0_SOURCE_PLAN.txt:153` only | **None.** No metric definition, no producing script, no dataset, no result file anywhere in the repo | `historical_claim_unreproducible` |
| MSCL 88.5% | `R0_SOURCE_PLAN.txt:153` only | **None** for 88.5%. Counter-evidence: `TIANNARA_RUNTIME_TEST_INVENTORY.md:101` (metric 0.0 under perturbation); `baseline.md:80` (MSCL metric 0.0 open) | `historical_claim_unreproducible`; observed value 0.0 conflicts with the claim |
| "hundreds of generations" (`generation_history.csv`) | tracked CSVs under `data/stage6/` and `data/phase13_5/` | Real file-writing scripts exist, but STAGE6 matrix documents fabricated lineage inputs for Stage3/4/5-derived runs | `simulated`/`partially_traceable` — do not present as runtime evolutionary evidence |

No campaigns were re-run. All rows above are settled from static provenance; reproducibility would require (out of R0 scope) recovering or reconstructing a metric definition that does not exist in-repo for GRCC/MSCL.

## Explicit unknowns (not established by R0)

1. Whether runtime Elixir `/calibration/worlds` endpoint exists (API fallback masks it).
2. Runtime reconciliation between `Tiannara.World` and `Tiannara.Core.WorldModel` state.
3. Whether `TiannaraRuntime.WorldModel` is dead code or pending migration (no dead-code marker found).
4. Root `lib/tiannara/world/` supervision placement beyond ControlCenter boot (confirmed started via ControlCenter; long-term owner ambiguous).
5. Whether root `EngineeringSupervisor` has any consumer beyond definition (initial grep: none; not exhaustively proven).
6. Whether any promotion has passed independent verification on non-seeded discovery input.
7. Python-side test/pytest results (not re-run; CI config claims coverage only).
8. Whether `fixes.md`-documented multi-world defects were fixed on any other branch (not checked; no branch operations permitted).
