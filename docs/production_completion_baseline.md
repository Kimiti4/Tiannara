# Tiannara — Production Completion Baseline (Truth Baseline)

**Purpose:** Establish, from executable evidence only, which capabilities exist and which are
pending, before any implementation work begins. Architecture documents, specifications and
certificates are treated as *claims*, never as evidence of implementation.

**Baseline recorded:** 2026-09-22, `local/pr4` @ `b564fbe97767bf88ac7b54b7c04e8915983b3832`
**Audit method:** static inventory + compile + live OTP boot + ERPC runtime census + focused
source reading. No capability is upgraded on documentation evidence.

---

## 1. Baseline facts (measured)

| Fact | Value | How measured |
|---|---|---|
| Branch / commit | `local/pr4` / `b564fbe9…` | `git log -1` |
| Working tree vs HEAD | **no source files dirty**; 235 entries, all generated state (`dev_data/dets`, `data/test`, `*.dets`, corrupted-log archives) | `git status --porcelain -- lib test config docs priv` → empty |
| Elixir / OTP | Elixir 1.18.4 / OTP 28 (erts 16.4) | `elixir --version` |
| Source size | 1,646 `.ex` files, ~244,484 lines, **1,847 `defmodule` declarations** | recursive count |
| Tests | 332 test files under `test/` | recursive count |
| Compile | **PASS** — `mix compile` → "Generated tiannara app" | `mix compile --no-deps-check` |
| Boot | **PASS** — dev profile boots, endpoint bound | `elixir --sname tiannara_probe -S mix run --no-halt` + ERPC probe |

### 1.1 Live boot probe (direct measurement, dev profile)

```
Tiannara.Application children: %{active: 61, workers: 30, supervisors: 31, specs: 61}
registered names: 473      processes: 773      ETS tables: 199 (196 post-filter)   memory: 102 MB
```

Resident (ALIVE) at boot — verified by `Process.whereis/1` over ERPC:
`Tiannara.Application`, `Council.Supervisor`, `CEL.Kernel`, `CEL.Kernel.ServiceRegistry`,
`Storage.DetsLifecycle`, `PhaseOmega.SubsystemRegistry`, `Sentinel.Supervisor`,
`Sentinel.SentinelRuntime`, `CIS.Supervisor`, `Executive.Supervisor`,
`Research.ResearchDirector`, `Autonomy.ConstitutionalAutonomy`, `Omega.OmegaRuntime`,
`Operations.OperationsSupervisor`, `ToolForge.ToolForgeSupervisor`, `ASC.Core.Supervisor`,
`ASC.Civilization.Supervisor`, `ASC.Reality.Supervisor`, `ASC.Engineering.Supervisor`,
`TiannaraWeb.Endpoint`, `World.ReplayEngine`, `World.KnowledgeEvolutionEngine`.

Absent (declared but not resident under the expected name):
`Tiannara.KnowledgeCoordinator`, `Tiannara.Observatory.Observatory`
(the former runs as a CEL-managed service — see CEL boot report; the latter has no server at all).

### 1.2 CEL Executive Kernel boot report (the organism's own EOS boot)

```
status: :ready     duration_ms: 1874     failed_critical: []
services: 34, all :ok  (executive_memory, priority_engine, runtime_policy_engine, event_store,
  resource_manager, identity_trust_manager, executive_service_bus, unified_reality_graph,
  conflict_resolution_engine, mission_director, autonomous_research_engine, world_mutation_engine,
  capability_graph, workflow_engine, discovery_supervisor, provenance_engine, unified_world_model,
  snapshot_manager, knowledge_evolution_engine, epistemic_integrity_service, replay_engine,
  evidence_validator, knowledge_flow_engine, ontology_manager, constitutional_score_pipeline,
  executive_metrics, executive_scheduler, executive_digital_twin, version_manager,
  experiment_orchestrator, executive_state_manager, decision_predictor, knowledge_coordinator,
  conflict_detector)
gate_results: 5 gates per service (resource/health/capability/constitution/dependency) = :pass
```

**Constitutional caveat (high severity):** `replay_engine` passes all five constitutional
gates at boot (`health: :pass`, `constitution: :pass`) while its implementation is theatrical
(see §4.18). **The gate framework cannot currently detect theatrical behaviour.** A gate that
passes a non-implementation is evidence that gate integrity, not capability, is the blocker.

**Generalised by re-measurement (2026-09-22, same day):** this is not a replay-specific caveat.
`CEL.Kernel.ServiceRegistry` registers a `constitutional_score_check` for each admitted service, and
**27 of the 34 admitted services satisfy that check from a hardcoded literal** — see §3.2. The boot
report `services: 34, all :ok … constitution: :pass` therefore measures *self-reported constants*,
not constitutional compliance. Gate integrity is the **P0 blocker** for the whole completion program:
every other gate-derived claim (including this baseline's own §4 rows) is conditioned on it.

Post-remediation note: `World.ReplayEngine` no longer fabricates execution — it now fails closed with
`{:error, :replay_source_unavailable}` (`lib/tiannara/world/replay_engine.ex:69-72`, regression green in
§5). Its `constitutional_score/0` remains a constant, i.e. the *execution* defect was fixed while the
*self-certification* defect was not.

### 1.3 Ω Runtime Health Aggregator (self-report, live)

```
status: :partial     subsystems_healthy: 5   subsystems_total: 6
agency_loop: current_phase :observe, loops_completed 5,
  recent phases: observe(50 obs) → analyze(2 priorities) → investigate(2 ingested)
                 → communicate(0 surfaced) → improve → learn
vm: processes 771, run_queue 0, atom_count 37,351, uptime 255 s
```

The Ω agency loop is genuinely cycling. The organism reports itself as **5/6 healthy**, i.e. it
fails honestly rather than reporting uniform green.

---

## 2. Runtime census — compiled vs activated

| Measure | Value |
|---|---|
| Modules loaded in the live VM (all apps) | **864** |
| `Tiannara.*` modules loaded | **383** |
| `Tiannara.*` modules declared in source | **1,847** |
| Activation ratio (declared → loaded) | **≈ 21 %** |

Interpretation: ~79 % of the declared Tiannara module surface is compiled but never loaded by
the running organism, and a large part of that is the **unbooted parallel codebases** below.
"Code exists" must never be reported as "Tiannara can do it".

### 2.1 Parallel implementations (single-source-of-truth violations, measured)

| Root | Ecosystem | Notes |
|---|---|---|
| `lib/` (`:tiannara`) | Elixir/OTP | the only app in the main boot tree |
| `forward_provenance/` | Elixir path dep | provenance/certificate substrate (24 modules) — *is* wired |
| `tiannara_runtime/` | **separate Mix app** | contains `TiannaraRuntime.OS.Persistence.ConstitutionalPersistenceLayer`, `ExperimentJournal`, `ResurrectionEngine`; own `_build`, k8s, `Mnesia.*` dirs |
| `tiannara_core/` | **Python** | ~60 subsystem packages (immune, governance, logic, cognition, discovery, ecms, orchestrators …) |
| `tiannara_api/` | **Python (FastAPI)** | auth, payments, marketplace, gateway, security |
| `tiannara_saas/` | **Next.js/TypeScript** | billing, tiers, admin dashboard |
| `tiannara_gui/`, `tiannara_observatory/`, `tiannara_audit/`, `tiannara_pros/` | mixed | `tiannara_pros` = Python `actuators/`, `io/`, `scenarios/` (physical-world interfaces) |

**Finding A:** at least four languages and eight unbooted application roots. They are not in the
main supervision tree, not covered by the main test suite, and not part of the live capability
census. Any capability claimed from these trees is `UNVERIFIED` by construction.

**Finding B:** `mix tiannara.start` (the production/safe launch task) blocks up to 10 s waiting
for `TiannaraRuntime.OS.Persistence.ConstitutionalPersistenceLayer`
(`lib/mix/tasks/tiannara.start.ex:17`), a module that **exists only in the unbooted
`tiannara_runtime/` app** — searching `lib/` for `ConstitutionalPersistenceLayer` returns only
the Mix task itself. The advertised production start path depends on an app the main release
neither builds nor starts.

**Finding C:** **601** `council_audit_log.dets.corrupted.*` archives (2026-08-16 → 2026-09-22,
including one created by this audit's own boot). The Council audit log corrupts and is archived
on nearly every boot. Containment works; the durability defect is unresolved and produces
unbounded artifact growth in the constitutional audit trail.

**Finding D (module duplication):** static scan of 1,847 `defmodule` declarations found exactly
one duplicated module name — `Tiannara.CTL.CausalRegistry` (defined twice). Compile-time
"redefining module" warnings also appear during concurrent builds; they are a build-hygiene
signal, not a capability signal, but the duplicate must be resolved before freeze.

**Finding E (honest stubs):** 13 modules declare `use Tiannara.Stub`, which returns explicit
`{:stub, …}` tuples and records calls in `Tiannara.StubRegistry`
(`lib/tiannara/stubs/`: `causal_registry`, `causal_traversal`, `crucible_supervisor`,
`generation_history`, `graph`, `lifecycle_registry`, `longitudinal_memory`,
`os_scientific_capital_ledger`, `pressure_monitor`, `survivability_estimator`, plus
`asc/interface/protocol.ex`, `discoveries/theory_selection.ex`). This is *good* epistemic
practice — stubs are labelled, not disguised. They are still stubs.

---

## 3. Capability classification (the 39-family capability set)

Status vocabulary: `IMPLEMENTED` · `PARTIAL` · `STUB` · `THEATRICAL` · `UNUSED` · `BROKEN`
· `UNVERIFIED` · `MISSING`. Only the "Executable evidence" and "Pending edge" columns may be
treated as proof.

| # | Capability family | Status | Executable evidence (today) | Pending edge |
|---|---|---|---|---|
| 1 | Constitutional cognitive OS (core) | **PARTIAL** | Live boot: 61 children, `CEL.Kernel.boot_report` `:ready`, 34 services `:ok`, 1,874 ms, 5 gates each; `council/` (18 modules); `os/kernel/{constitutional_invariant_registry,constitutional_executor,constitutional_entropy_tracker,constitutional_drift_journal}.ex`; `test/tiannara/constitution/*` | No machine-readable production certification; 601 audit-log corruptions; subsystems report `:degraded`; per-sink enforcement unproven |
| 2 | Evidence-first reasoning / knowledge validation | **PARTIAL** | `evidence/{provenance,certification_gate}.ex`; `world/epistemic_*`; `rea/epistemic/{constitution_kernel,constitutional_immune_system}.ex` + tests; `epistemic_integrity_service` `:ok`; U8 recovery-honesty; MC-001-M pin implemented (`:formal_verification_unavailable`) | No proof kernel; knowledge-graph durability caveat (graph `:not_found` post-kill per U8); promotion path never exercised in production |
| 3 | Autonomous scientific discovery | **PARTIAL** | `Research.ResearchDirector` + `Sentinel.SentinelRuntime` resident; 8 research test files; `discovery/steps/{experiment_step,validation_step}.ex` perform real measurement + validation; `discovery/{adaptive,advanced,optimization,quality,validation}`; discovery certifier | Domain hypothesis generation returns `{:ok, []}` (`domains/physics.ex:37,40,55`); no autonomous hypothesis→experiment→knowledge closure demonstrated |
| 4 | World modeling | **PARTIAL** | `world/` 12 modules (`unified_world_model`, `world_mutation_engine`, `temporal_world_engine`, `canonical_world_state`, `world_query_engine`, `world_consistency_validator`, `provenance_engine`, `world_state_synchronizer`, adapters); CEL `unified_reality_graph`/`unified_world_model`/`snapshot_manager` `:ok`; immutability/monotonicity property tests | `world/replay_engine.ex` **THEATRICAL** (§4.18); graph state lost across kill; counterfactual worlds only via `simulation/multiworld` forking |
| 5 | Civilization-scale / planetary twin | **PARTIAL / scale UNVERIFIED** | All 13 `ASC.Civilization.*` services resident (Director, Planner, WorldModel, PolicySimulationEngine, LongTermForecastEngine, SustainabilityEngine, IntergenerationalEquityEngine, GlobalRiskEngine, KnowledgePreservationEngine, DecisionEngine, FeedbackAggregator, Metrics, ConstitutionalGovernanceEngine); `cci/` experiment runtime + forecasting; `asc/civilization` tests | The "12 worlds / 84 civilizations / 23,800 agents" figure **is not reproducible from tracked artifacts in this repo** → UNVERIFIED; re-derive or retract |
| 6 | Multi-domain research intelligence | **PARTIAL** | `domains/` 27 modules + booted `Domains.CanonicalRegistry` (20-domain ontology); `asc/research/programs`, `research/{director,memory}`, `meta_science` | Domains are behaviours, not executing laboratories; `metrics/0` return state-derived zeros (honest but empty) |
| 7 | Mathematical / formal substrate | **PARTIAL (thin, honest)** | `foundations/mathematics/calculus.ex` real bounded RK4 (`solve_ode/3`, MC-004-M); `math/probability.ex` `bayes_update/3` real; `math/{statistics,graphs}.ex`; `math/optimization.ex` decommissioned to explicit `:unavailable` | 11–25-line modules; no symbolic maths, no theorem dependency graph, no proof replay (MC-002 P0 still open) |
| 8 | ESAP - autonomous software compiler | **PARTIAL (single backend, artifact-only)** | `asc/implementation/compiler.ex` + `asc/implementation/adapter/elixir.ex` (**sole** backend adapter); `asc/c_missions/*` real subprocess primitives in `compiler.ex`; `repro/manifest.ex` artifact manifests; `asc/adoption/adopter.ex`; `self_improvement/sandbox/backend/{local,container,ci}.ex` | No second backend (Python/Go absent); `deployment_mode: :artifact_only`; CI sandbox backend reports `:ci_not_configured`; no demonstrated architecture -> multi-file project -> build -> execute -> verify closure with deterministic artifact identity |
| 9 | Autonomous software evolution | **PARTIAL** | `asc/evolution/{capability_evolution_engine,reality_anchored_evolution_campaign}.ex`; `crucible/{evolution_campaign,population_expansion_campaign,alpha_campaign,species_fitness,survival_curves}.ex`; `crucible/repair_ecology/*` (6) + `repair_phylogeny/*` (5); **live `RepairLibrary` ETS = 18,016 entries**; AE-001→AE-003 longitudinal lineage | Promotion/deployment disabled (`deployment_enabled: false`); fail-closed fitness gate not proven end-to-end; evolution not driven by the live research loop |
| 10 | Self-monitoring | **IMPLEMENTED** | Resident `Sentinel.Supervisor` + `SentinelRuntime` + `Sentinel.D2.*`; live `Omega.RuntimeHealthAggregator` (`:partial`, 5/6); `PhaseOmega.RuntimeVerifier` with per-subsystem certificates; `crav/{event_bus_audit,observatory_coverage}.ex`; `test/sentinel/*` | Coverage partial: subsystems report `responds: :skip`, `observability: :not_observed`, `running_children: []` |
| 11 | Self-diagnosis / archaeology | **PARTIAL (thin at runtime)** | `PhaseOmega.{Scanner,RuntimeDiscoverer,RuntimeAuditor,EventFlowVerifier,TelemetryCoverageAuditor,DependencyVerifier,WiringEngine}.ex`; `observatory/runtime_atlas.ex` (163 L); `crav/*` | runtime `archaeology/archaeology.ex` = **84 lines**; deep archaeology exists as `certification/reconnaissance/**` (Python + YAML) and `docs/*ARCHAEOLOGY*` — artifacts, not capability |
| 12 | Self-repair | **PARTIAL (ecosystem real)** | `crucible/{repairer,failure_classifier,failure_species,repair_reuse_engine,repair_transfer,transfer_ecology,pattern_mutator}.ex`; `repair_ecology/*`, `repair_phylogeny/*`; `autonomy/rollback_engine.ex`; 18,016 live repair patterns; retention test | No demonstrated repair of the **live** organism under constitutional authorization; repair promotion blocked; never applied to a production code path |
| 13 | Constitutional governance | **PARTIAL (framework real)** | `council/` 18 modules: `constitution_repository`, `rule_engine` (240 L), `policy_registry`, `amendment_engine`, `human_approval_queue`, `audit_log` (327 L), `meta_governor`, `execution_context`; `constitution/runtime/*`; 3 invariant test files | **No universal enforcement at every consequential sink**; audit-log durability defect; POL-CERT-AUTH-001 proven only on tested paths |
| 14 | Authorization as a first-class capability | **PARTIAL** | `council/authorization.ex` (97 L); `council/execution_context.ex`; `omega/human_delivery/authorization.ex` (176 L hard human gate); `omega/governance_gate_server.ex`; `omega/deployment_gateway.ex` (certification+lineage+grant); `phase4/real_execution.ex:41` defaults **false** + `guard_grant/1` requires a `HumanDelivery.Authorization` struct; `omega/authority_verifier.ex` (generation ≠ authority) | **Nothing mints grants** (MC003: "hard human gate, nothing mints grants"); closure verified only in Ω paths; `Council.authorize/2` used in `phase4/experiment_orchestrator.ex:270` — sink coverage unproven |
| 15 | Effect identity / consequential-action integrity | **PARTIAL / GAP** | `authorization_id` + `idempotenc*` appear only in `omega/deployment_gateway*`, `omega/human_delivery*`, `omega/verification/*`, `chaos/blueprint.ex` | No universal *effect identity* binding (authorization → action+parameters → consequence) outside the Ω deployment path. This is the D165 class; no global invariant found |
| 16 | Provenance / lineage | **PARTIAL (strong substrate)** | `forward_provenance` path dep (24 modules: `envelope`, `certificate`, `identity`, `execution`, `graph`, `metric_lineage`, `verifier`) + `world/provenance_engine.ex` (CEL `:ok`) + `os/{provenance_tracker,metric_with_provenance,metric_provenance_resolver}.ex` + `provenance/discovery_ledger.ex` + `executive/lineage.ex` + `repro/manifest.ex` | Completeness at *every* transition unproven; provenance for the CEL replay path is meaningless while replay is theatrical |
| 17 | Evidence & certification system | **IMPLEMENTED (framework) / PARTIAL (production)** | `certification/{pipeline,exercise_runner,certificate,dimension,protocol}.ex` + 6 tiers (cognitive → discovery) + `certification_pipeline_test.exs`; `evidence/certification_gate.ex`; `os/governance/certification/**` campaigns; `soak/{recovery,recovery_gate,recovery_matrix,recovery_certificate}.ex`; `observatory/validation/**`; `validation/{campaign,registry,report,scorecard}` | No single machine-readable production certification artifact covering boot → loop → soak; last master matrix (`certification/TIANNARA_ARCHITECTURE_CERTIFICATION_MATRIX.md`) = **QUALIFIED PARTIAL** |
| 18 | Deterministic replay | **PARTIAL / FAIL-CLOSED** | Governance-side replay is real: `os/governance/{governance_replay_engine,replay_verifier,replay_auditor,rfc_replay_engine,long_horizon_replay}.ex`, `validation/adapters/replay_adapter.ex`, campaign_03_million_step_replay, `world/chaos/replay_determinism_chaos_test.exs`; world replay regression test now proves unavailable source returns an error and does not record success | `world/replay_engine.ex` no longer fabricates mutations or reports `:ok`; it returns `{:error, :replay_source_unavailable}` until a real mutation source and sandbox reducer are wired. `constitutional_score` and CEL gate honesty remain separate open findings |
| 19 | Observation architecture / Observatory | **PARTIAL → THIN** | 39 Phoenix LiveViews (`lib/tiannara/web/live/*`: mission_control, civilizations, discoveries, laws, theories, orbits, unified_immune, worlds, interventions, research_map, domains…); `web/{mission_control,report_channel,telemetry_channel}.ex`; `observatory/{runtime_atlas,classifiers,dashboards,topology,telemetry_sink}.ex`; `omega/observatory.ex` | `Tiannara.Observatory` is a **37-line logging façade** (`push_dialogue/1`, `push_proposal/1`, `push_investigation/1` → `Logger.info`) with **no server process**; no authoritative projection layer |
| 20 | Live state reconstruction (LiveProjection) | **MISSING** | — | No `LiveProjection`, `live_projection`, snapshot-checkpoint, capability-negotiation or gap-recovery module exists anywhere in `lib/` (verified by repository-wide search). The observation-layer contract the architecture requires is not implemented |
| 21 | Runtime orchestration | **IMPLEMENTED** | OTP tree: 31 supervisors / 30 workers under `Tiannara.Application`; `CEL.Kernel` EOS boot with DynamicSupervisor services + health + constitutional gates; `Tiannara.Storage.DetsLifecycle`; `resource_manager`, `executive_scheduler`, `priority_engine`, `workflow_engine`; `runtime/*`, `executive/*` | `PhaseOmega.SubsystemRegistry` shows `:degraded` for several subsystems and `observability: :not_observed`; several `TiannaraOS.*` modules boot while the rest of TiannaraOS does not |
| 22 | Failure containment / fail-closed | **PARTIAL** | 5-gate CEL admission (`resource/health/capability/constitution/dependency`); fail-closed unavailables (MC-001-M) in `math/optimization.ex`, `foundations/mathematics/calculus.ex`, `domains/physics.ex`; `phase4/real_execution.ex` fail-closed; `workflow_engine_degradation_test`; `chaos/{fault,blueprint,runner,epistemic_integrity}.ex`; `CIS.Supervisor` **resident** | Gates cannot detect theatrical behaviour; CIS recovery loop in **production** (vs test topology, F11) still unproven; audit-log corruption recurring = containment without root cause |
| 23 | Recovery & persistence | **PARTIAL** | `executive/{persistence,recovery,snapshot,transaction,migration,dets_store,corruption_detector,ets_cache}.ex`; `storage/{dets_lifecycle,rotator,paths}`; `soak/{recovery,recovery_gate,recovery_matrix,recovery_certificate,checkpoint_store,time_accounting}.ex`; tests `dets_continuity_acceptance`, `rotator_lifecycle`, `rotator_retention`, `soak/recovery`; storage contexts (`test`/`soak`/`production`) | Graph state **not recovered** after kill (U8 caveat); live warning `[ExecutiveMemory] Could not warm ETS cache from DETS`; no demonstrated cold-start reconstruction of the reality model |
| 24 | Execution abstraction | **PARTIAL** | Real subprocess primitives in 19 files (`System.cmd`/`Port.open`): `asc/c_missions/*`, `asc/implementation/compiler.ex`, `asc/reality/reality_bridge.ex`, `asc/adoption/adopter.ex`, `self_improvement/sandbox/backend/{local,container,ci}.ex`, `sandbox/real_harness.ex`, `repro/manifest.ex`; `phase4/{real_execution,experiment_orchestrator,physics_pilot_execution}.ex`; `physics/{ird,opc,twp,de}`; `base_reality/workspace.ex` | No governed terminal consumer wired into production; CI sandbox backend unconfigured (`:ci_not_configured`); ToolForge execution is a stub; `real_execution_enabled` defaults false |
| 25 | External world interface (egress/ingress) | **MISSING (self-referential path removed)** | Previously `reality/production_observatory.ex` "observed" GitHub/Stripe/Datadog through a repo-local `HTTPoison` stub. **That stub no longer exists** (`lib/tiannara/stubs/httpoison.ex` absent; 0 `HTTPoison` callers) and `mix.lock` contains **no HTTP client at all** | Tiannara currently has **no real external-world I/O**. U0's "C11 EGRESS ✗ NOT TESTED" still stands; ingress now has no implementation either. `asc/reality/adapters/` holds only `simulated_adapter.ex` |
| 26 | Engineering intelligence | **PARTIAL** | Resident `asc/engineering/*` (DesignSynthesisEngine, CADGenerationEngine, SystemsEngineeringEngine, OptimizationEngine, DigitalTwin, Validation…); tests `digital_twin`, `optimization`, `validation`; `engineering/optimization/*` | Not coupled to the research loop; no physical/robotic execution (only `simulated_adapter`); deployment posture `:artifact_only` |
| 27 | Multi-domain capability generation | **PARTIAL → NO for multi-backend** | 27 domain modules + `Domains.CanonicalRegistry`; `domains/extruder` (domain extrusion + `ExtrusionTaskSupervisor`); `asc` pipeline phases | Software generation targets **Elixir only** (`asc/implementation/adapter/elixir.ex` is the sole adapter); robotics/control software generation unproven; domains do not execute research |
| 28 | Security intelligence | **PARTIAL** | `red_team.ex`; `chaos/epistemic_integrity.ex`; `crav/*` audits; `omega/authority_verifier.ex`; U5/U6 tamper rejection; `certification/tier3_constitutional.ex`; D-series remediation protocols in `certification/remediation/` | No runtime threat model; no secrets management; authorization-boundary closure across all consequential sinks unproven; no security certification for HEAD |
| 29 | Continuous self-improvement | **PARTIAL (deliberately gated)** | `autonomy/{improvement_engine,proposal_generator,simulation_manager,rollback_engine,constitutional_autonomy,constitutional_validator,deployment_pipeline}.ex` + 6 tests; `self_improvement/{pipeline,dry_run,sandbox/*}` + tests; `os/{method_evolution_pipeline,stage3_method_evolution}.ex`; `asc/meta_learning/*` | `deployment_enabled: false`; production promotion path intentionally closed; improvement never demonstrated end-to-end into production state |
| 30 | Capability discovery / runtime census | **IMPLEMENTED (strength)** | `PhaseOmega.{Scanner,RuntimeDiscoverer,RuntimeAuditor,TelemetryCoverageAuditor,EventFlowVerifier,WiringEngine}.ex`; `SubsystemRegistry` issuing per-subsystem certificate hashes + health + `observability`; `omega/{capability_audit,capability_briefing}.ex`; `observatory/runtime_atlas.ex`; `crav/observatory_coverage.ex`; `mix phase_omega_scan` | Registry tolerates `:degraded` / `:not_observed` without blocking; the 21 % activation ratio is measured but not surfaced as a governed metric |
| 31 | Autonomous mission execution (ASC C-Missions) | **IMPLEMENTED (manual invocation)** | `asc/c_missions/{runner,runner_v2,runner_v3,worktree,verification,infrastructure}.ex` + 4 tests; Mix tasks `asc.c.run`, `asc.c.run2`, `asc.c.run3`, `asc.c.verify`, `asc.observe`; real git/mix subprocesses; sandbox fs/process execution demonstrated | Missions are operator-invoked tooling, not a supervised production mission loop; bounded/safe-mission policy is not enforced by the runtime |
| 32 | AgencyLoop / autonomous agency | **IMPLEMENTED (live)** | Live: `current_phase :observe`, `loops_completed 5`, phases observe(50 obs)→analyze→investigate→communicate→improve→learn; `omega/{agency_loop,agency_orchestrator,loop}.ex`; resident `asc/agency/sentinel.ex`; exposed through `RuntimeHealthAggregator` | `asc/agency/orchestrator.ex` retains a **mock cycle** path (`mock_observations`/`mock_hypotheses`); cognition phases surface 0 items; no promotion of learned state proven |
| 33 | Memory architecture | **PARTIAL** | `cel/services/executive_memory.ex`, `runtime/executive_memory.ex`, `executive/executive_memory.ex` (DETS+ETS, CEL `:ok`); 3 ExecutiveMemory test files; `memory/{memory,ladder}.ex`; `asc/memory/institutional_memory.ex`, `asc/civilization_memory.ex`; discoveries orbit/meta/civilisation memories | `stubs/longitudinal_memory.ex` is an honest **stub**; live ExecutiveMemory DETS warm failure; no longitudinal (years-scale) retention demonstrated |
| 34 | Simulation as laboratory | **PARTIAL** | `simulation/{simulation_engine,simulation_supervisor,impact_forecaster,scenario_builder}.ex` + property tests; `simulation/multiworld/{world_forker,world_comparison_analyzer}.ex` + test; resident ASC `policy_simulation_engine`; `rea/simulation_runner.ex`; `cci/civilization_experiment_runtime.ex`; `base_reality/*` | Not coupled to the governed research loop; no FEA/CFD/domain-physics simulation; `Physics.simulate/2` integrates only a supported ODE spec |
| 35 | Challenge execution / adversarial verification | **PARTIAL** | `chaos/*` + `test/tiannara/chaos/*`; `test/tiannara/world/chaos/*` (concurrent writers, replay determinism, snapshot recovery); `phase4/{adversarial,chaos}` tests; `diagnostics/discovery_adversarial_test`; Crucible `attacker`/`breaker` (504/671 L); `self_improvement/sandbox_statistical_benchmark_test` | Adversarial campaigns are not run against the production loop; the 6 certification tiers exist but are not all executed against HEAD |
| 36 | Constitutional participation graph | **MISSING** | — | No participation-graph module. Nearest: `phase_omega/{dependency_verifier,event_flow_verifier,wiring_engine}.ex` + `crav/event_bus_audit.ex`. The designed artifact (who can act / who constrains / where authority enters) is not implemented |
| 37 | Meta-level self-understanding | **PARTIAL** | `os/{program_self_evaluation,speciation_detector,state_jtms}.ex` + tests; `meta_cognition.ex`; `epistemic_mirror/*`; `sentinel/d2/*` (science of science) + tests; `meta_governor.ex`; `omega/capability_briefing.ex` | No demonstrated self-model answering "what am I capable of / what evidence supports it / is it reachable" as a governed capability |
| 38 | Observatory as operating console | **PARTIAL (UI-first)** | 39 LiveViews + `MissionControl` + channels + controllers; `TiannaraWeb.Endpoint` booted; `Tiannara.Omega.Observatory`; sentinel/ASC observatories | UI is real but sits on a **missing observation layer**; views risk presenting state no authoritative projection owns — must be re-based on a projection contract |
| 39 | Constitutional entropy / drift accounting | **PARTIAL** | `os/kernel/{constitutional_entropy_tracker,constitutional_drift_journal}.ex`; `stabilization/olef/entropy_tracker.ex` (EVID-0003 IMPLEMENTED); live ETS `conservation_laws` (6), `law_history` (6) | No governed entropy accounting (architecture/dependency/runtime/knowledge) at v1 scale; not surfaced in certification |

### 3.1 Net position

- **Genuinely operational today:** runtime orchestration/supervision, CEL executive kernel + 5-gate
  admission, constitutional council framework, provenance substrate, self-monitoring, capability
  discovery/census, ASC engineering+civilization+reality supervision trees, Crucible repair/evolution
  ecosystem, Ω agency loop, and a real bounded RK4 in the mathematics substrate.
- **Pending (highest-value, evidence-backed):** world replay is theatrical yet green; no universal
  authorization-to-effect closure; external world I/O does not exist; observation layer /
  LiveProjection absent; audit-log durability defect; production start path depends on an unbooted
  app; eight parallel unbooted application roots (§2.1) inflate apparent capability.

---

## 4. Pending work queue (ordered by evidence value per unit of effort)

Each item is a *smallest corrective change* that converts an unproven claim into measured capability.
Do not implement a whole architectural layer because a document describes it.

| Order | Blocker | Why it is first | Smallest corrective change |
|---|---|---|---|
| B1 | ~~`world/replay_engine.ex` theatrical **and green under all 5 constitutional gates**~~ **Remediated 2026-09-22** | A passing gate over a non-implementation invalidates every downstream certification claim | Fail closed (`:replay_source_unavailable`) is implemented and covered by `test/tiannara/world/replay_engine_test.exs`; remaining work is real mutation retrieval, sandbox execution, state comparison, and gate-honesty integration |
| B2 | ~~Gate integrity: gates cannot detect stubs/theatrical code~~ **Explicit-stub portion remediated 2026-09-22; fail-closed portion extended 2026-09-23 (third pass)** | Every other status number depends on it (34 services marked `:ok`) | `Tiannara.Stub` exposes a machine-readable marker; `BootSequencer.capability_gate/1` rejects explicit stubs (`boot_sequencer_capability_gate_test.exs`). **Third pass:** constitution gate now also refuses explicit stubs, fails closed on raising/non-struct/uncomputable scores (kernel `ConstitutionalScore.unavailable/1` replaces the catch-to-1.0 default; sequencer catch → named `{:fail, ...}` instead of `:pass`) — this exposed `mission_director`'s boot-time `:badarith` (previously certified 1.0), root-caused and fixed. Evidence: `tools/audit/evidence_2026-09-23_gatefix_*`, `boot_report_diag.exs`; combined 12-file batch → **34 tests, 0 failures**, boot `Status: ready`, 34/34 `:ok`. **Still open:** independent recompute of score *values* (B12/F-A), `{:stub, ...}` return inspection, `mock: true`, theatrical-behavior detection |
| B3 | ~~No universal authorization→effect closure~~ **Deployment sink remediated 2026-09-22** | Intended constitutional invariant; D165 class remains open outside this sink | `Omega.DeploymentGateway` now computes and records a deterministic effect identity from operation, candidate, proposal, and content hash. The registry rejects same-authorization/different-effect reuse and legacy records without provable effect identity. Focused coverage: `deployment_effect_identity_test.exs`. Remaining work: enumerate and close every other consequential sink |
| B4 | ~~Nothing mints grants~~ **Authenticated grant minting remediated 2026-09-22** | The prior path accepted bare identifiers, so it did not prove human identity | Shared `Authorization.human_grant/2-3` and both delivery APIs now require `AuthenticatedHumanIdentity`; bare identifiers fail closed. Focused coverage: `human_authorization_identity_test.exs`. Credential/session persistence, revocation, and external identity verification remain open |
| B5 | ~~Council audit log durability (601 corruptions)~~ **Path/lifecycle portion remediated 2026-09-22** | The constitutional audit trail is the primary evidence channel | `Council.AuditLog` now uses context-resolved DETS storage and syncs/closes on termination; focused path-isolation and integrity tests pass. Deterministic crash/restart reproduction, rotation, and N-restart zero-corruption proof remain open |
| B6 | ~~Production start path depends on unbooted `tiannara_runtime` CPL~~ **Remediated 2026-09-22** | The launcher previously waited 10 seconds for an app absent from the main release | `Mix.Tasks.Tiannara.Start` now starts only `:telemetry` and `:tiannara` and uses the in-tree CEL kernel as its runtime readiness boundary; focused contract test passes. Full production-profile launch with infrastructure and endpoint verification remains open |
| B7 | ~~Activation ratio 21 % (383/1,847 modules loaded)~~ **Metric surfaced 2026-09-22** | Distinguishes "compiled" from "operable" | `CRAV.RuntimeCensus.activation_metrics/0` now reports declared source modules, loaded `Tiannara.*` modules, ratio, percentage, status, and telemetry. Focused test passes. Per-subsystem reachability and quarantine/relocation of parallel unbooted codebases remain open |
| B8 | ~~Observation layer absent (`LiveProjection`, checkpoints, gap recovery)~~ **Initial projection remediated 2026-09-22** | 39 LiveViews exist without an authoritative projection; UI cannot be evidence | Added supervised `Observatory.LiveProjection` with EventBus subscription, ordered cursor, snapshot, and event retrieval; focused tests pass, including real world-event delivery. Checkpoint persistence, gap recovery, and LiveView rebasing remain open |
| B9 | ~~External-world I/O absent (no HTTP client, simulated adapters only)~~ **Bounded ingress boundary added 2026-09-22** | Blocks C11 egress and the "external consequence" half of the causal loop | Added `Tiannara.External.ReadOnlyHTTP`: GET-only, allowlisted-host, no-redirect, response-size-bounded ingress requiring an authenticated human grant bound to the exact URL. Policy tests pass. A live endpoint/provenance integration proof and any mutating egress remain open |
| B10 | Graph state not recovered after kill; ExecutiveMemory DETS warm failure | Recovery is an explicit production-readiness gate | Reconstruct the reality model from event store/checkpoints on boot and assert equality post-restart |
| B11 | Phase-16 autonomous loop incomplete (domain hypothesis generation returns `{:ok, []}`) | The autonomous-discovery claim needs one honest closure | Make one domain produce a real hypothesis from real state, run it through the bounded RK4 path, validate, record provenance + knowledge |
| B12 | ESAP multi-backend absent; evolution promotion closed | Prevents over-claiming; low immediate value for v1 | Keep closed and label as research extension |

### 4.1 What must NOT be spent tokens on yet
- Implementing historical/speculative phases (recursive evolution, transcendence, multi-language code
  generation, civilization-scale re-runs) before B1–B10 are closed.
- Rewriting working subsystems (CEL kernel, supervision, provenance, Crucible) — they are already real.
- Polishing the 39 LiveViews before the projection contract exists (B8).
- Producing more architecture documents: the repository already contains far more specification text
  than executable capability.

---

## 5. Evidence index (reproduce every claim)

```powershell
# baseline
git log -1 ; git status --porcelain -- lib test config docs priv
# static census
(Get-ChildItem lib -Recurse -File -Filter *.ex | Measure-Object).Count
(Get-ChildItem lib -Recurse -Filter *.ex | Select-String -Pattern '^defmodule' | Measure-Object).Count
# build + boot
mix compile --no-deps-check
elixir --sname tiannara_probe -S mix run --no-halt        # observe "Tiannara started successfully"
# live census / self-report (audit tooling committed at tools/audit/)
elixir --sname probe2 tools/audit/probe_runtime.exs    # critical-process residency
elixir --sname probe3 tools/audit/probe_runtime2.exs   # activation census + CEL boot report + health + ETS
# captured focused-test evidence
Get-Content tools\audit\evidence_2026-09-22_focused_test.out
# tests
mix test
# replay fail-closed regression
mix test test/tiannara/world/replay_engine_test.exs --trace  # 1 test, 0 failures
# explicit-stub capability gate regression
mix test test/tiannara/cel/boot_sequencer_capability_gate_test.exs --trace  # 2 tests, 0 failures
# deployment effect-identity regression
mix test test/tiannara/omega/deployment_effect_identity_test.exs --trace  # 3 tests, 0 failures
# authenticated human grant regression
mix test test/tiannara/omega/human_authorization_identity_test.exs --trace  # 2 tests, 0 failures
# audit-log durability regression
mix test test/tiannara/council/audit_log_durability_test.exs --trace  # 2 tests, 0 failures
# production start boundary regression
mix test test/mix/tasks/tiannara_start_test.exs --trace  # 1 test, 0 failures
# declared-versus-loaded activation regression
mix test test/tiannara/crav/runtime_census_activation_test.exs --trace  # 1 test, 0 failures
# bounded external ingress policy regression
mix test test/tiannara/external/read_only_http_test.exs --trace  # 3 tests, 0 failures
# gate honesty + branch-validator regressions (2026-09-23 third pass)
mix test test/tiannara/ctl_branch_validator_test.exs --trace  # 8 tests, 0 failures
mix test test/tiannara/cel/boot_sequencer_gate_honesty_test.exs --trace  # 7 tests, 0 failures
# combined focused + gate batch (12 files) → 34 tests, 0 failures; boot "Status: ready"; 34/34 :ok
Get-Content tools\audit\evidence_2026-09-23_gatefix_final_34_green.out
# domain-organ quarantine batch (13 files, adds domain_quarantine_test) → 39 tests, 0 failures; boot "Status: ready"
Get-Content tools\audit\evidence_2026-09-23_step3_domain_quarantine_39_green.out
mix test test/tiannara/domains/domain_quarantine_test.exs --trace  # 5 tests, 0 failures
# pre-fix honest-failure + badarith archaeology
Get-Content tools\audit\evidence_2026-09-23_gatefix_boot_failed_pre_fix.out
Get-Content tools\audit\evidence_2026-09-23_gatefix_badarith_diag.out
# reusable boot-report diagnostic
MIX_ENV=test mix run tools\audit\boot_report_diag.exs
# remaining implementation boundary (direct read)
Get-Content lib\tiannara\world\replay_engine.ex   # unavailable until real source + reducer exist
# durability defect
(Get-ChildItem -Filter 'council_audit_log.dets.corrupted.*').Count   # 608 (grew from 601 during this session's runs)
```

### 5.1 Additional live findings recorded during this audit
- `mix test` surfaced a **5,000 ms `GenServer.call` timeout** against
  `Tiannara.Graph.UnifiedRealityGraph` on the `:preserve` path (civilizational memory) — i.e. the
  unified reality graph becomes unresponsive under test load. `Tiannara.Graph.UnifiedRealityGraph`
  is a hot dependency of knowledge/CCI paths.
- Boot log shows `[ExecutiveMemory] Could not warm ETS cache from DETS` and
  `AuditLog: DETS file requires repair. Archiving corrupted file.` on a clean start.
- The running organism reports `PhaseOmega` subsystem records with `responds: :skip`,
  `observability: :not_observed`, `running_children: []` — supervision is real, observability of it
  is declared-but-absent.

### 5.2 Regression-suite state at HEAD (measured)
- A full `mix test` run at `b564fbe9` produced **≥ 99 ExUnit failures** and **204 crash/exit
  markers** before being terminated for time (the suite includes long-horizon runs of 25,000–50,000+
  ticks).
- **Root cause characterised by focused isolation run** (`mix test test/tiannara/asc/core/boot_test.exs
  test/tiannara/sentinel/priority_engine_test.exs` → `2 tests, 2 failures`):
  ```
  ** (RuntimeError) failed to start child with the spec Tiannara.ASC.Core.Supervisor.
     Reason: bad child specification, got: {:already_started, #PID<0.819.0>}
     code: start_supervised!(Supervisor)
  ```
  The tests call `start_supervised!/1` for subsystems that `Tiannara.Application` **already starts**
  (config `asc.enabled: true`). This is an **application-gating / test-topology conflict**, i.e. the
  suite encodes a topology in which ASC was not globally booted. The same class explains
  `SupervisorTopologyTest`, `SupervisorResilienceTest`, `RepairLibraryRetentionTest`,
  `Reality.LoadSpikeContractTest`, `Reality.DeploymentTest`, `Research.R0QuarantineTest`,
  `Sentinel.PriorityEngineTest`.
- Classification: **REGRESSION SUITE NOT GREEN — root cause is test/topology conflict, not proven
  runtime failure**, but it is not yet fully characterised for every failing file (5,000 ms
  `GenServer.call` timeouts against `Tiannara.Graph.UnifiedRealityGraph` under load remain a
  separate, potentially genuine defect).
- **Resolution rule:** fix by aligning test expectations with the global boot topology (assert on
  app-owned processes, or explicitly boot in an isolated topology), never by disabling ASC globally,
  never by weakening assertions.
- Consequence: **no capability may be promoted on test evidence alone** until the suite is honestly
  green.

### 5.3 Persistence-layer defects observed on clean runs
- Fresh test runs immediately repair several stores:
  `AuditLog: DETS file requires repair. Archiving corrupted file.`,
  `ResilientDETS: …cel_event_store.dets needs repair`, `…world_mutations.dets needs repair`,
  `[ExecutiveMemory] Could not warm ETS cache from DETS`.
- Contributing defect: the per-run isolation path uses
  `System.unique_integer([:positive])` (`config/test.exs`), whose values **repeat in every new VM**,
  so a killed or failed run leaves dirty DETS state that the next run inherits and repairs. Test
  isolation is therefore not actually per-run.
- With 608 archived `council_audit_log` corruptions (2026-08-16 → 2026-09-22; the count grew from 601
  during this session's probe/test runs, so recurrence is current, not historical), the constitutional
  audit trail's durability is a first-order production blocker.



## 6. Limitations of this baseline
- Every status above is a **live capture on 2026-09-22**, not a projection. Anything not measured is
  labelled UNVERIFIED rather than assumed.
- The full `mix test` suite is long-running (long-horizon ticks of 25,000+ steps); its final summary
  is recorded separately. No capability above is marked IMPLEMENTED on a passing test alone.
- `tiannara_core/`, `tiannara_api/`, `tiannara_saas/`, `tiannara_runtime/`, `tiannara_pros/`,
  `tiannara_gui/`, `tiannara_observatory/`, `tiannara_audit/` were **not** executed or audited;
  capabilities claimed there are `UNVERIFIED` by construction.
- The "12 worlds / 84 civilizations / 23,800 agents" scale claim was **not reproduced** → UNVERIFIED.
- Prior audit lineage (`docs/audit/U0_*`, `certification/remediation/MC00*-*`,
  `certification/reconnaissance/**`) was treated as *claims*. Where it conflicts with measurement,
  measurement wins. Those artifacts remain historical evidence and must not be rewritten.
- Nothing in this document authorizes a fix. B1–B11 require explicit authorization before
  implementation, per the constitutional rule that generation ≠ authority.

---

## 7. Second-pass revision (2026-09-22, verification of the B-series remediations)

The rows in §3 are preserved unchanged (lineage). This section supersedes them where remediation landed
in the working tree and where new measurement contradicts a classification.

### 7.1 Revised classifications

| # | Family | §3 status | Revised status | Evidence for the change |
|---|---|---|---|---|
| 14 | Authorization as a first-class capability | "not fully achieved" | **PARTIAL — verified at two consequential sinks** | `Omega.HumanDelivery.Authorization.valid_for?/2` binds a grant to the effect/explanation id (`authorization.ex:145`, fail-closed default `false`); `Authorization.human_grant/2-3` mints only for `AuthenticatedHumanIdentity`; `External.ReadOnlyHTTP.validate_grant/2` matches `{:external_read, url}` and derives `effect_identity/1` = `sha256({:read_only_get, url})`; `Omega.DeploymentGateway` derives effect identity from operation + candidate + proposal + content hash. Tests: `human_authorization_identity_test.exs` (2), `deployment_effect_identity_test.exs` (3), `read_only_http_test.exs` (3). **Not universal:** the other CEL-admitted services and non-Ω mutation paths remain outside this binding |
| 20 | Live state reconstruction (`LiveProjection`) | MISSING | **PARTIAL (initial)** | `lib/tiannara/observatory/live_projection.ex` exists and is booted (`application.ex:102`); ordered snapshot + event cursor, invalid cursors rejected (`live_projection_test.exs`, 3 tests). No checkpoint persistence, hydration or gap recovery yet |
| 25 | External world interface | MISSING (both directions) | **PARTIAL — bounded ingress only** | `lib/tiannara/external/read_only_http.ex` (96 L): GET-only via `:httpc`, host allowlist (loopback by default), `autoredirect: false`, byte cap, requires an authenticated grant bound to the exact normalized URL, records `effect_identity`. Egress still absent; no HTTP client in `mix.lock`; `asc/reality/adapters/` remains simulation-only |
| 29 | Capability discovery | PARTIAL | **IMPLEMENTED — strongest family in the repository** | `crav/`: `activation_matrix` (352 L), `runtime_atlas` (799), `runtime_census` (530, now reporting declared-vs-loaded ratio), `dead_code_detector` (477), `runtime_dependency_graph` (497), `observatory_coverage` (445), `supervisor_integrity` (358), `soak_test` (916) + `soak_checkpointer` |
| 31 | Deterministic replay | THEATRICAL | **STUB — honest, no longer misleading** | `world/replay_engine.ex:69-72` fails closed with `{:error, :replay_source_unavailable}`; `replay_engine_test.exs` asserts it. Real mutation retrieval, sandbox execution and state comparison still absent |
| 36 | Constitutional participation graph | MISSING | **IMPLEMENTED** | `lib/tiannara/crav/participation_graph.ex` (382 L): per-subsystem participation from mailbox statistics, telemetry handler counts, registry heartbeats and ETS sizes; `participation/0`, `active_participants/0` |

### 7.2 New defects found while verifying the remediations

**F-A — The constitutional gate is a self-report. (CRITICAL; blocks every gate-based certification claim.)**
CEL gate 4 (`cel/kernel.ex:136-143`) does `apply(mod, :constitutional_score, [])` — *each service scores
itself* — and the value is recorded without independent recomputation. Live counterexample:
`World.ReplayEngine.constitutional_score/0` (`replay_engine.ex:34-45`) returns literal
`health: 1.0, constitutional_alignment: 1.0, transparency: 1.0, explainability: 1.0, evidence_quality: 1.0,
human_oversight: 1.0`, while the same module's replay path returns `{:error, :replay_source_unavailable}`.
The service is CEL-registered (`cel/kernel/service_registry.ex`, id `:replay_engine`), so it passes all five
gates with an unavailable capability. Therefore "34 services `:ok`" is a **liveness** report, not a
capability report, and the gate currently violates the constitutional rule *validation never trusts
self-reported metrics; generators never certify themselves*. The corrective step is **not** to edit
ReplayEngine's score: it is to compute gate 4 independently, or to demote `constitutional_score/0` to an
*input* that an independent verifier cross-checks against observable behaviour (message throughput, ETS
deltas, telemetry handler counts — data `CRAV.ParticipationGraph` already gathers).

**Partially remediated 2026-09-23 (third pass).** The *mechanics* are now fail-closed: raising,
non-struct, or uncomputable scores become `ConstitutionalScore.unavailable/1` (all zeros → the gate
refuses them), `BootSequencer.check_constitution/2` no longer converts exceptions to `:pass`, and
explicit stubs are refused at the constitution gate itself. The repaired gate immediately caught a
real fabrication in flight — `mission_director`'s `:badarith` scorer, previously certified `1.0`
(capability ledger D-A9/D-A10) — and boot moved `failed → ready` only after its root fix. The
prescription in the paragraph above (**independent recompute; `provides:` cross-checked against
behaviour**) remains **open as B12**: score *values* are still the service's own assertion.

**F-B — A stub occupies an active guard path; the real implementation is dark. (HIGH.)**
`lib/tiannara/stubs/causal_registry.ex` defines `Tiannara.Ctl.CausalRegistry` (mixed-case namespace) as a
`use Tiannara.Stub` module whose `get_branch/1` returns a hardcoded `{:ok, %{stress: 0.0}}`.
`lib/tiannara/ctl/branch_validator.ex:7` aliases exactly that module and calls it inside `validate_merge/2`.
Because `check_causal_stress/2` is `(a.stress + b.stress) / 2 > 0.7`, a constant `0.0` means the branch
validator **can never return `{:error, :invalid_merge}`** — a paradox-prevention guard that structurally
always approves while reporting `{:ok, :valid}`. The genuine `Tiannara.CTL.CausalRegistry`
(`lib/tiannara/ctl/causal_registry.ex`) has **no callers** → dark module. This is simultaneously
(i) duplicate ownership of one concept across two namespaces, (ii) a stub shipped as runtime behaviour,
which MC-001-M forbids, and (iii) a live instance of the "compiled ≠ operable" failure the §2 census exists
to detect.

**Remediated 2026-09-23 (third pass, deeper than B13).** `BranchValidator` was unaliased from the
stub and now fails closed with named reasons (`:registry_unavailable`, `:threshold_configuration_absent`,
`:branch_not_found`, `:branch_evidence_incomplete`, `:invalid_merge`); the real
`Tiannara.CTL.CausalRegistry` was rewritten as a stateful GenServer (stress validated `0..1`,
`{:ok, count}` replacing the `10_000 # Mock`) and added to the application supervision tree — the
previously dark module is now live evidence storage. The stress threshold moved to
`:ctl_causal_stress_threshold` config with fail-closed-when-absent semantics. Investigation then
proved the **root cause behind the mixed-case twin: on case-insensitive filesystems the two beam
files collide, so exactly one of the two modules survived each compile — non-deterministically**
(live evidence: boot crash `module ... does not exist`, surviving beam contained `__tiannara_stub__`;
a scan found this was the only case-twin among 2,193 source modules). The stub file was therefore
**deleted** rather than left as a latent collision. Evidence: `ctl_branch_validator_test.exs` (8
tests), `tools/audit/evidence_2026-09-23_gatefix_*`.

**F-C — The readiness gate is coupled to infrastructure the organism does not use; Wave-5 profiles are incomplete. (HIGH for deployment.)**
`lib/mix/tasks/tiannara.start.ex` declares `@required_services [PostgreSQL:5432, Redis:6379, NATS:4222]`
and gates the `dev`/`production` profiles on them, while Tiannara's persistence here is DETS/ETS and
`mix.lock` contains no such client. The `production` profile therefore cannot pass its own readiness gate
on an ordinary machine, for reasons unrelated to capability. Profiles present: `dev, research, production,
benchmark, safe-mode, distributed`. Required by the program: `DEMO`, `PERSONAL`, `RESEARCH`, `SAFE` — only
`research` and (approximately) `safe-mode` exist; **DEMO and PERSONAL are absent**. B6's fix did correctly
remove the unbooted `TiannaraRuntime…ConstitutionalPersistenceLayer` dependency
(`test/mix/tasks/tiannara_start_test.exs`: "uses only applications owned by the main release").

### 7.3 Revised pending-work queue (continues §4)

| Order | Blocker | Smallest corrective change | Forbidden shortcut |
|---|---|---|---|
| B12 | F-A gate self-certification | Compute the constitutional gate independently; retain `constitutional_score/0` as a cross-checked input | Editing a service's score to be "honest" instead of fixing the gate — **[PARTIAL 2026-09-23: fail-closed mechanics landed (unavailable/1, no silent :pass, stubs refused); independent recompute still to do]** |
| ~~B13~~ **Closed 2026-09-23** | F-B stub in an active guard path | ~~Decommission the stub; point `BranchValidator` at the real `Tiannara.CTL.CausalRegistry`, or fail closed if that has no implementation — one owner per concept~~ Done and exceeded: stub deleted (case-twin collision proved), real registry implemented + booted, validator fails closed, 8 tests green | Writing a second CTL registry (violated by nothing — only one registry exists) |
| B14 | F-C readiness coupling and missing profiles | Replace `@required_services` with the stores actually used; add `DEMO` and `PERSONAL` profiles with their own authority/persistence semantics | Hiding it behind a `--skip-infra` default |
| B5† | B5 residual | Prove zero corruption across N cold starts with real restart reproduction | Declaring durability fixed because archives are written |
| B15 | D-A12 DETS recovery ladder raises on a non-existent `:dets.repair_file/1` (OTP 28 measured) | ExecutiveMemory's advertised open→repair→backup recovery crashes at the repair step, skipping its own backup fallback | `DetsStore.repair/1` → named fail-closed `{:error, :dets_repair_unavailable}` so backup promotion runs; then prove the full ladder with an injected corrupt file | Silencing by deleting the repair call without preserving the ladder order |

### 7.4 Third-pass remediation (2026-09-23): gate honesty + F-B/D-B closure

Authorized scope: §7.3 B13 (closed) and the fail-closed mechanics of B12 (partial). Implementation:

| Change | File | Constitutional effect |
|---|---|---|
| Score failures → `ConstitutionalScore.unavailable/1` (all zeros, never boot-ready); non-struct returns rejected | `cel/kernel/constitutional_score.ex`, `cel/kernel.ex` | catch-to-perfect-default removed |
| Constitution gate: exceptions → named `{:fail, ... — fail closed}`; explicit stubs refused; observed aggregate/health reported in the failure reason; `check_constitution/2` made public for direct testing | `cel/kernel/boot_sequencer.ex` | D-A9 silent `catch → :pass` layer removed |
| Scorer root-caused: `:badarith` on zero missions (was certified 1.0), fabricated process-down stats removed | `cel/services/mission_director.ex` | D-A10 — first honest catch of the repaired gate, fixed at source |
| Validator unaliased; named fail-closed reasons; threshold from config, absent → fail | `ctl/branch_validator.ex`, `config/config.exs` | constant-`{:ok}` authority hole closed |
| Registry rewritten as stateful GenServer (stress validated `0..1`, `{:ok, count}`); booted as application child (+1 this pass; measured dev total now **63** = 61 baseline + LiveProjection (09-22) + this registry — `git diff application.ex` shows exactly those two child additions) | `ctl/causal_registry.ex`, `application.ex` | dark module now live evidence store |
| Case-twin stub **deleted** after its beam-file collision was proved (only case-twin among 2,193 modules) | `stubs/causal_registry.ex` (deleted) | Windows case-collision hazard eliminated |

Evidence (all under `tools/audit/`): `evidence_2026-09-23_gatefix_boot_failed_pre_fix.out`
(honest `failed` boot with the gate naming `:badarith`), `evidence_2026-09-23_gatefix_badarith_diag.out`
(boot-report archaeology), `evidence_2026-09-23_gatefix_final_34_green.out` (`Status: ready`,
34/34 `:ok`, **34 tests, 0 failures** across the 12-file combined batch),
`evidence_2026-09-23_gatefix_compile.out`, `evidence_2026-09-23_gatefix_dev_boot_63_children.out`
(dev boot probe: `asc_enabled=true, 63 top-level children`, `Status: ready`, all services `:ok`), and
the reusable `boot_report_diag.exs`.

Process note (lineage, including own errors): the threshold config key was first written *inside* the
nested `:asc` block — the fail-closed path then refused every validation and the new tests caught the
placement mistake. Fail-closed behaved as designed during development; nothing was weakened to go green.

Residuals deliberately left open: B12 independent recompute (27/34 services still self-report
hardcoded score components — unchanged claim), `{:stub,...}` return-shape inspection, `mock: true`
and theatrical-behavior detection, full-suite topology redness (§2.1) untouched.

### 7.5 Domain-organ quarantine (2026-09-23, ledger §7 step 3)

Authorized scope: the step-3 gate — *no constant-valued `simulate/2`/`validate/1` remains callable.*

- **18 constant `simulate/2` quarantined** (aerospace … sociology) → `{:error, :simulation_unavailable}`;
  the authoritative-sounding verdicts (`:flight_worthy`, `:efficacious`, `:manufacturable`, …) are no
  longer producible.
- **16 constant `validate/1` quarantined** → `{:error, :validation_unavailable}`; unconditional
  `{valid: true}` and the fabricated `trial_phase: :phase_2` / `constitutional_alignment: 0.94` are gone.
- **Real computations deliberately preserved** (verified by reading every non-constant body before
  editing): physics (real RK4 + provenance + structural validation), chemistry (graph shortest-path
  `simulate`), aerospace/architecture/engineering (`FormalVerification.verify_invariants` validates),
  and all 15 real `evaluate/1` (7 `bayes_update` + 8 Shannon-entropy/Nash-equilibrium bodies).
- **Caller compatibility proven before the edit**: the only production consumer,
  `ASC.AutonomousDiscovery.execute_experiment` (`asc/autonomous_discovery.ex:35-51`), already handled
  `{:error, reason}` arms — the research loop now reports `:simulation_unavailable` /
  `:validation_unavailable` instead of integrating fabricated validations. Zero tests referenced the
  constant domains (grep-proven), so no assertion needed weakening.
- Every quarantined function carries a `# D-A3 quarantine (2026-09-23): …` provenance comment;
  post-sweep grep shows **0 live constant patterns remaining** in `lib/tiannara/domains/` (34/34
  literal replacements — 18 simulate + 16 validate — verified, 0 misses; the only remaining grep
  hits are the provenance comments themselves).
- **Residual found and catalogued during the sweep (D-A11, OPEN):** 5 constant `evaluate/1`
  (architecture .93 / chemistry .91 / governance .82 / logistics .91 / robotics .88) and 19 of 20
  hardcoded `metrics/0` (only physics is `metrics_source: :state_derived`) — outside this gate,
  next quarantine candidate.

Evidence: `tools/audit/evidence_2026-09-23_step3_domain_quarantine_39_green.out` — combined
13-file batch: **39 tests, 0 failures**, boot `Status: ready`. Regression:
`test/tiannara/domains/domain_quarantine_test.exs` (5 tests: every quarantined function fails
closed; the specific fabricated measurements are no longer producible; physics and chemistry remain
callable end-to-end).

*Baseline captured 2026-09-22 by live runtime audit. Method: measure, then classify; never classify
from documentation.*




