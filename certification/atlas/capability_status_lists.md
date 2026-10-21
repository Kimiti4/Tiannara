# Capability status lists (Phase R0 deliverable 7)

Generated: 2026-10-21T08:39:16Z — source `capability_register.csv` (117 capabilities)

Operator evidence rule (§1 of the R0 program): a capability counts as VERIFIED only when implementation AND real
execution evidence exist. Module existence, documentation, and isolated passing tests are not evidence.
Reconciliation: MATCHED / PARTIAL / CONTRADICTED / UNKNOWN — UNKNOWN is never counted as a pass.

## Summary

| Evidence state | Count |
|---|---|
| DISCONNECTED / PARTIALLY CONNECTED (components exist; end-to-end flow incomplete) | 47 |
| PARTIALLY VERIFIED (code exists; production/failure paths unproven) | 43 |
| MISSING OR UNRESOLVED | 17 |
| PLANNED / SPECIFIED ONLY (documented, not proven implemented) | 5 |
| VERIFIED (implementation + execution evidence exist) | 5 |

| Reconciliation | Count |
|---|---|
| PARTIAL | 60 |
| CONTRADICTED | 38 |
| UNKNOWN | 13 |
| MATCHED | 6 |

| Section | Count |
|---|---|
| A-COGNITIVE | 19 |
| B-EPISTEMICS | 16 |
| C-GOVERNANCE | 32 |
| D-WORLDMODEL | 20 |
| E-ESAP | 16 |
| F-PLATFORM | 14 |

## VERIFIED (implementation + execution evidence exist)

| Capability | Section | Reconciliation | Owner | Implementation | Confidence |
|---|---|---|---|---|---|
| CAP-GOV-102 Durable one-shot grant registry (MintRegistry) | C-GOVERNANCE | MATCHED | Tiannara.Omega | Tiannara.Omega.MintRegistry (omega/mint_registry.ex:73-309) - the single durable authorisation registry | high |
| CAP-GOV-103 Canonical effect identity | C-GOVERNANCE | MATCHED | Tiannara.Omega | Tiannara.Omega.EffectIdentity (omega/effect_identity.ex) producing effect-v1-<sha256> | high |
| CAP-GOV-104 Negative authorization / attack test suite | C-GOVERNANCE | MATCHED | Tiannara test suite | test/tiannara/omega/d127_authorization_attack_test.exs (10), test/tiannara/omega/governed_effect_sink_test.exs (8), test | high |
| CAP-GOV-107 CIS safety authorisation chain (kill / resource / world suspension) | C-GOVERNANCE | PARTIAL | Tiannara.CIS | TiannaraRuntime.CIS.Supervisor.authorize_kill/3, authorize_resource_termination/3, authorize_world_suspension/3 (cis/sup | medium |
| CAP-WRD-101 Forecasting evaluation (EFDI FA-001 track) | D-WORLDMODEL | MATCHED | certification/forecasting + tiannara_runtime Forecast* modul | EFDI stack: preregistration -> authorization -> frozen forecast -> post-window resolution -> Brier/log-loss scoring -> h | high |

## PARTIALLY VERIFIED (code exists; production/failure paths unproven)

| Capability | Section | Reconciliation | Owner | Implementation | Confidence |
|---|---|---|---|---|---|
| CAP-COG-002 Tiannara Runtime (supervision/lifecycle/recovery) | A-COGNITIVE | PARTIAL | tiannara_runtime OTP app | tiannara_runtime/lib/tiannara_runtime/application.ex:28-37; startup_supervisor.ex:29-42 (:rest_for_one CPL->Omega->Obser | high |
| CAP-COG-011 Lexical Tensegrity | A-COGNITIVE | PARTIAL | root app (lib/tiannara/aal) | lib/tiannara/aal/lexical_tensegrity_field.ex (LTF) | medium |
| CAP-COG-102 OED (Ontological Escape Dynamics) - discovered | A-COGNITIVE | PARTIAL | tiannara_runtime lib/tiannara/oed/* + runtime/oed/* (5 modul | oed/{oed,csi,elf,isrd,entropic_load_balancer}.ex; Tiannara.OED.Supervisor is unrelated to the claimed Tiannara.Runtime.O | medium |
| CAP-COG-105 CRA (Causal Redundancy Autogenesis) - discovered | A-COGNITIVE | CONTRADICTED | tiannara_runtime runtime/cra/* (5 GenServers ~265 LOC) | cra/{cluster_stress_monitor,ontological_forking_reflex,pressure_mesh,redundancy_mesh,shutdown_intent_detector}.ex | high |
| CAP-EPI-002 Blackboard | B-EPISTEMICS | PARTIAL | Tiannara.Executive.Cognitive (root lib/ app) | lib/tiannara/executive/cognitive/executive_blackboard.ex | medium |
| CAP-EPI-003 Knowledge Graph | B-EPISTEMICS | PARTIAL | root lib/tiannara/knowledge_graph | lib/tiannara/knowledge_graph/registry.ex (NDJSON file store) | medium |
| CAP-EPI-004 Evidence Assessment | B-EPISTEMICS | PARTIAL | root lib/ (research + evidence) | lib/tiannara/research/evidence_assessment.ex; lib/tiannara/evidence/provenance.ex; lib/tiannara/evidence/certification_g | medium |
| CAP-EPI-005 Confidence Calibration | B-EPISTEMICS | PARTIAL | root lib/tiannara/forecasting | lib/tiannara/forecasting/calibration.ex | medium |
| CAP-EPI-008 Contradiction Registry | B-EPISTEMICS | PARTIAL | root lib/tiannara/contradiction | lib/tiannara/contradiction/engine.ex + record.ex | medium |
| CAP-EPI-009 Bayesian Confidence | B-EPISTEMICS | UNKNOWN | root lib/tiannara/discovery/adaptive | lib/tiannara/discovery/adaptive/bayesian_prioritizer.ex | low |
| CAP-EPI-011 Replay Packages | B-EPISTEMICS | PARTIAL | multi (root lib/ + tiannara_runtime + observatory) | lib/tiannara/world/replay_engine.ex (fail-closed); tiannara_runtime/lib/tiannara_runtime/multi_world/deterministic_repla | medium |
| CAP-EPI-012 Provenance and Lineage | B-EPISTEMICS | PARTIAL | multi | forward_provenance/ (TiannaraOS.Provenance.*, path dep) + lib/tiannara/provenance/discovery_ledger.ex | medium |
| CAP-EPI-014 Active Learning | B-EPISTEMICS | PARTIAL | tiannara_runtime world_model/autonomous_research | tiannara_runtime/lib/tiannara_runtime/world_model/autonomous_research/engines/knowledge_gap_prioritizer.ex + experiment_ | medium |
| CAP-EPI-101 Epistemic Mirror stack (discovered extra) | B-EPISTEMICS | UNKNOWN | root lib/tiannara/epistemic_mirror | lib/tiannara/epistemic_mirror/{mirror_registry,accuracy_auditor,risk_detector,collapse_predictor,topology_lineage_tracke | low |
| CAP-ESP-002 ISR | E-ESAP | PARTIAL | isr/; constitutional_architecture/isr; tiannara/domain/model | isr/core/graph.py + isr/core/invariants.py (graph ISR); constitutional_architecture/isr/model/* (typed ISR) | high |
| CAP-ESP-003 Source-bound intent projection | E-ESAP | PARTIAL | autonomous-api/app/engine; constitutional_architecture/compi | autonomous-api/app/engine/source_bound_full_stack.py (project_source_bound_full_stack; SourceBoundSemanticCorrespondence | high |
| CAP-ESP-006 Multi-stack compiler orchestration | E-ESAP | PARTIAL | tiannara/application/compiler; tiannara/application/campaign | tiannara/application/compiler/registry.py; tiannara/application/campaign/backend_matrix.py; tiannara/application/campaig | high |
| CAP-ESP-009 Backend generation | E-ESAP | PARTIAL | tiannara/application/compiler; compiler/backends/production | tiannara/application/compiler/fastapi_hexagonal_backend.py; rust_axum_backend.py; go_hexagonal_backend.py; spring_boot/n | high |
| CAP-ESP-013 Independent verification | E-ESAP | PARTIAL | certification/; compiler/sdk; autonomous-api/app/engine | certification/stages/independent_verify.py; compiler/sdk/testing.py; autonomous-api/app/engine/verification_executor.py | F-ESP-009 |
| CAP-GOV-007 Audit Certificates | C-GOVERNANCE | CONTRADICTED | multiple | Tiannara.Certification.Certificate (certification/certificate.ex:1-65) is the only certification authority in the root a | medium |
| CAP-GOV-012 Hash-chain audit infrastructure | C-GOVERNANCE | PARTIAL | Tiannara.Council | Tiannara.Council.AuditLog (council/audit_log.ex, 559 LOC: single-writer lock, strict DETS open, SHA-256 chain, Merkle ro | medium |
| CAP-GOV-014 Rollback and stable-state preservation | C-GOVERNANCE | CONTRADICTED | Tiannara.World + Tiannara.Autonomy + Tiannara.OPC | no authoritative implementation - every engine either denies, no-ops, or is unwired | high |
| CAP-GOV-101 Bounded governed terminal sink (N1-N9) | C-GOVERNANCE | PARTIAL | Tiannara.Omega | Tiannara.Omega.GovernedEffectSink.execute/3 (omega/governed_effect_sink.ex:139-165) with the gate order documented at :3 | medium |
| CAP-GOV-105 forward_provenance certificate lifecycle and identity authority (separ | C-GOVERNANCE | UNKNOWN | forward_provenance (path dependency, root mix.exs:67) | TiannaraOS.Provenance.Certificate, CertificateLifecycle, CertificateIssuance, CertificateAuthorityBridge, IdentityAuthor | medium |
| CAP-GOV-106 Production certification campaign and gate framework (runtime) | C-GOVERNANCE | UNKNOWN | TiannaraRuntime.OS.Governance.Certification | production_gate_framework.ex, production_certification_framework.ex, campaign_orchestrator.ex, all_production_gates.ex,  | low |
| CAP-GOV-112 Constitutional persistence layer and SafeCPL (checkpointing) | C-GOVERNANCE | PARTIAL | TiannaraRuntime.OS.Persistence | TiannaraRuntime.OS.Persistence.ConstitutionalPersistenceLayer (os/persistence/constitutional_persistence_layer.ex) plus  | medium |
| CAP-GOV-113 Council RuleEngine constitutional scoring | C-GOVERNANCE | CONTRADICTED | Tiannara.Council | Tiannara.Council.RuleEngine.evaluate/3 (council/rule_engine.ex:22-74) with three hard invariants (:12) and eleven built- | high |
| CAP-GOV-117 Parallel CEL runtime policy evaluator | C-GOVERNANCE | PARTIAL | Tiannara.CEL | Tiannara.CEL.Services.RuntimePolicyEngine (cel/services/runtime_policy_engine.ex, 6.7 KB) and Tiannara.CEL.Policy.Runtim | medium |
| CAP-PLT-002 Event infrastructure | F-PLATFORM | PARTIAL | root CEL event stack; tiannara_runtime (Tiannara.EventBus +  | CEL Services.EventBus v2 (DETS DLQ + EventStore offsets) lib/tiannara/cel/services/event_bus.ex:1-108; Tiannara.EventBus | medium |
| CAP-PLT-003 Runtime supervision | F-PLATFORM | MATCHED | tiannara_runtime (OTP) | TiannaraRuntime.Application -> StartupSupervisor (:rest_for_one) -> CPL -> Omega -> Observatory -> Phoenix -> RootSuperv | high |
| CAP-PLT-007 Observability | F-PLATFORM | PARTIAL | tiannara_core/telemetry; tiannara_api middleware/metrics; ti | CognitiveTelemetryCollector tiannara_core/telemetry/cognitive_telemetry.py:94 (SQLite); Prometheus init tiannara_api/mai | medium |
| CAP-PLT-008 Storage | F-PLATFORM | PARTIAL | root Elixir (DETS/ETS); tiannara_runtime (CPL JSON; Omega sn | DETS+ETS in root app (Storage.DetsLifecycle application.ex:126; cel event store); CPL journal tiannara_runtime/lib/tiann | medium |
| CAP-PLT-011 Resource management | F-PLATFORM | UNKNOWN | tiannara_runtime (IRD/MSCL/SafetyCortex budgets); tiannara_a | IRD BudgetController (ird/budget_controller.ex:11-59 max_budget 1000/per-observer 250); SafetyCortex stability_budget (c | low |
| CAP-PLT-012 Documentation and developer tooling | F-PLATFORM | CONTRADICTED | repo root docs/ + markdown/ + AGENT.md + certification/ | no single authoritative doc — AGENT.md + README.md + docs/capability_ledger.md (True) + 461 files under docs/ | medium |
| CAP-PLT-013 (extra) Electron desktop shell tiannara-desktop | F-PLATFORM | UNKNOWN | tiannara-desktop (10 tracked files) | Electron main.js + preload.js + renderer/ (app.js/index.html/splash.html); productName 'Tiannara Observatory' (package.j | low |
| CAP-WRD-002 Autonomous Simulation (ASC) | D-WORLDMODEL | PARTIAL | root tiannara ASC (feature-flagged); tiannara_runtime simula | Tiannara.ASC.* (root lib/tiannara/asc/, Phases 6-10) - NOTE acronym collision: plan says 'Autonomous Simulation', code s | medium |
| CAP-WRD-007 Theory generation | D-WORLDMODEL | PARTIAL | tiannara_runtime theory engines (UNBOOTED); root ASC laws (f | TiannaraRuntime.AutonomousResearch.Phase16_1.TheoryEngine + TiannaraRuntime.WorldModel.AutonomousResearch.Engines.Theory | medium |
| CAP-WRD-008 Discovery tracking | D-WORLDMODEL | PARTIAL | root tiannara discovery (booted post-CEL); tiannara_runtime  | Tiannara.Discovery.{DiscoveryEngine,DiscoveryScheduler,Tracking,Certificate,ConstitutionalValidation} (lib/tiannara/disc | medium |
| CAP-WRD-011 Optimization and numerical methods | D-WORLDMODEL | MATCHED | root tiannara math/foundations | Tiannara.Math.Optimization - genuine bounded gradient descent with line search, finite checks, convergence diagnostics,  | high |
| CAP-WRD-012 Scientific evaluation | D-WORLDMODEL | PARTIAL | certification/forecasting EFDI track (independently verified | EFDI D1-D5 forecasting evaluation stack is the only independently verified prediction-vs-outcome surface (no-trust verif | high |
| CAP-WRD-102 Digital twin stack (world_model/digital_twin) | D-WORLDMODEL | UNKNOWN | tiannara_runtime world_model/digital_twin | TiannaraRuntime.WorldModel.DigitalTwin.Engines.DigitalTwinEngine (159 loc) + emergence/intervention/metrics engines - UN | medium |
| CAP-WRD-106 Layer 6.5D institutional evolution ecology (fixture campaign) | D-WORLDMODEL | PARTIAL | root lib/tiannara/os/civilization_scheduler.ex + campaign sc | TiannaraOS.CivilizationScheduler (100k-tick fixture simulation); ESR/AFG values are PLACEHOLDER constants (calculate_esr | medium |
| CAP-WRD-107 ASC Laws registry and discovery marketplace | D-WORLDMODEL | PARTIAL | root lib/tiannara/asc/laws + data/asc_archive | Tiannara.ASC.Laws.{Registry,Discoverer,ExperimentDesigner,CanonicalPromotionEngine,UtilityTracker} + discovery_marketpla | medium |

## DISCONNECTED / PARTIALLY CONNECTED (components exist; end-to-end flow incomplete)

| Capability | Section | Reconciliation | Owner | Implementation | Confidence |
|---|---|---|---|---|---|
| CAP-COG-001 Cognitive orchestration | A-COGNITIVE | PARTIAL | root app (Executive.Cognitive + Sentinel.Cognition); tiannar | AMBIGUOUS: lib/tiannara/executive/cognitive/executive_cognitive_runtime.ex (booted ECR); tiannara_runtime/lib/tiannara_r | medium |
| CAP-COG-003 Cognitive Information System (CIS) | A-COGNITIVE | CONTRADICTED | split: tiannara_runtime (TiannaraRuntime.CIS) + root (Tianna | tiannara_runtime/lib/tiannara_runtime/cis/{supervisor,execution_controller}.ex (boot-wired W1 3690efbd); root lib/tianna | medium |
| CAP-COG-004 Adaptive Executive Orchestrator (AEO) | A-COGNITIVE | PARTIAL | root app | lib/tiannara/aeo.ex (moduledoc: Adaptive EXECUTION Orchestrator - name differs from spec) | medium |
| CAP-COG-008 Ontological Bridge | A-COGNITIVE | PARTIAL | root app (discovery/advanced) | lib/tiannara/discovery/advanced/cross_domain_discovery.ex; lib/tiannara/discovery/advanced/analogical_reasoner.ex | medium |
| CAP-COG-010 Proactive Monitor | A-COGNITIVE | PARTIAL | root app (lib/tiannara/interface) | lib/tiannara/interface/proactive_notifier.ex | medium |
| CAP-COG-012 Executive Memory | A-COGNITIVE | CONTRADICTED | unresolved - 4 owners across 2 apps | (1) lib/tiannara/executive/executive_memory.ex DETS+ETS self-described canonical store via Executive.Supervisor (applica | high |
| CAP-COG-101 OPC (Observer Physics Compiler) - discovered | A-COGNITIVE | CONTRADICTED | tiannara_runtime opc/ (~8.9k LOC) | tiannara_runtime/lib/tiannara_runtime/opc/*; facade lib/tiannara/physics/opc.ex fail-closes :physics_substrate_unavailab | high |
| CAP-COG-106 Omega robustness stack - discovered | A-COGNITIVE | PARTIAL | tiannara_runtime runtime/omega/* (14 modules) | omega/{supervisor,executive_memory,checkpoint_reliability,constitutional_scheduler,dependency_isolation,event_store_audi | medium |
| CAP-EPI-006 Detector Trust Scoring | B-EPISTEMICS | CONTRADICTED | root lib/tiannara/ecl | lib/tiannara/ecl/trust_engine.ex | high |
| CAP-EPI-010 Uncertainty Disclosure | B-EPISTEMICS | CONTRADICTED | root lib/tiannara/os | lib/tiannara/os/unknown_registry.ex (+ lib/tiannara/evidence/provenance.ex unknown/1)" | medium |
| CAP-EPI-013 Ontology Management | B-EPISTEMICS | CONTRADICTED | multi (fragmented, no authority) | lib/tiannara/world/ontology_manager.ex; lib/tiannara/core/ontology/supervisor.ex (boot-reachable); tiannara_runtime/lib/ | medium |
| CAP-ESP-001 Intent ingestion and compilation | E-ESAP | PARTIAL | tiannara/application/intent; constitutional_architecture/com | tiannara/application/intent/compiler.py; constitutional_architecture/compiler/intent_entrypoint.py | high |
| CAP-ESP-004 Architecture selection | E-ESAP | CONTRADICTED | vertical_slice/; autonomous-api/app/engine; tiannara/applica | vertical_slice/architecture_selection_d24.py; autonomous-api/app/engine/architecture_selection.py:authorize_selection; t | medium |
| CAP-ESP-005 Autonomous code generation | E-ESAP | PARTIAL | compiler/backends; tiannara/application/compiler | compiler/backends/python_fastapi.py; compiler/backends/rust_axum.py; tiannara/application/compiler/*_backend.py (14 back | high |
| CAP-ESP-007 Frontend generation | E-ESAP | CONTRADICTED | tiannara/application/compiler; autonomous-api/app/engine; co | tiannara/application/compiler/react_frontend.py; autonomous-api/app/engine/react_typescript_compiler.py; constitutional_ | F-ESP-004; F-ESP-005 |
| CAP-ESP-008 API generation | E-ESAP | PARTIAL | compiler/backends/production; autonomous-api/app/engine | compiler/backends/production/openapi_backend.py; autonomous-api/app/engine/api_ir.py; api_contract_bindings.py | high |
| CAP-ESP-010 Events and asynchronous processing | E-ESAP | CONTRADICTED | tiannara/application/compiler; compiler/backends | tiannara/application/compiler/fastapi_hexagonal_backend.py:async_resolution_module (R2.4.0b); constitutional_architectur | high |
| CAP-ESP-011 Security and authorization | E-ESAP | CONTRADICTED |  but generated routes enforce API-key auth only | tiannara/application/enterprise; tiannara/application/security; compiler/governance | high |
| CAP-ESP-012 Full-stack integration | E-ESAP | CONTRADICTED | autonomous-api/app/engine; tiannara/application/hardening | autonomous-api/app/engine/source_bound_full_stack.py; full_stack_verification.py; tiannara/application/hardening/fullsta | high |
| CAP-ESP-014 Deployment and operations | E-ESAP | CONTRADICTED | vertical_slice/; constitutional_architecture/deployment; tia | vertical_slice/deployment_d26.py; constitutional_architecture/deployment/targets/kubernetes_target.py; tiannara/applicat | high |
| CAP-ESP-015 Legacy repair and evolution | E-ESAP | CONTRADICTED | autonomous-api/app/engine; tiannara/application/factory | autonomous-api/app/engine/existing_codebase_workflow.py; repository_code_scan.py; repair_closure.py; tiannara/applicatio | F-ESP-007 |
| CAP-ESP-016 Autonomous improvement | E-ESAP | PARTIAL | evolution/; learning/; tiannara/application/evolution; tiann | tiannara/application/evolution/*; tiannara/application/self_improvement/compiler_evolution.py; evolutionary feedback via | F-ESP-009 |
| CAP-GOV-004 Constitutional Invariant Monitor (CIM) | C-GOVERNANCE | PARTIAL | Tiannara.Council | Tiannara.Council.ConstitutionalMonitor (council/constitutional_monitor.ex:1-109, 30s cycle) - the only continuously-runn | medium |
| CAP-GOV-005 Constitutional Audit Pipeline (CAP) | C-GOVERNANCE | PARTIAL | Tiannara.Council + Tiannara.Omega + Tiannara.Phase4 | composite, no single module: Council.authorize/3 (council.ex:12-50) -> Council.MachineAuthorization.mint/2 + bind_effect | medium |
| CAP-GOV-008 Constitutional Executive / State Machine | C-GOVERNANCE | PARTIAL | Tiannara.CEL | Tiannara.CEL.Kernel (cel/kernel.ex:1-209) + Tiannara.CEL.Kernel.RuntimeStates (cel/kernel/runtime_states.ex:14-25, 10 st | medium |
| CAP-GOV-009 Human Authority / approval controls | C-GOVERNANCE | PARTIAL | Tiannara.Council + Tiannara.Omega.HumanDelivery | Council.PolicyRegistry :require_human action -> Council.HumanApprovalQueue (council/human_approval_queue.ex); Tiannara.O | medium |
| CAP-GOV-010 Access Control / OAVL / ACL | C-GOVERNANCE | PARTIAL | Tiannara.Council + Tiannara.Omega | Tiannara.Council.Authorization.permitted?/1 (authorization.ex:112-114); Tiannara.Omega.MintRegistry status/bind/consume  | medium |
| CAP-GOV-011 CEL / Constitutional Council | C-GOVERNANCE | PARTIAL | Tiannara.CEL + Tiannara.Council | CEL: Tiannara.CEL.Kernel + Tiannara.CEL.Kernel.ServiceRegistry + Tiannara.CEL.Kernel.BootSequencer (cel/kernel/*); Counc | medium |
| CAP-GOV-013 Kill switch / Safe Mode | C-GOVERNANCE | CONTRADICTED | TiannaraRuntime.CIS + Tiannara.Council | authorisation side: TiannaraRuntime.CIS.Supervisor.authorize_kill/3 (cis/supervisor.ex:79,131-149, restored in f64785df, | high |
| CAP-GOV-108 GCK chronogram gate and constitutional invariant gate (runtime) | C-GOVERNANCE | PARTIAL | Tiannara.GCK | Tiannara.GCK.ChronogramGate (gck/chronogram_gate.ex, thresholds 0.92 and 0.75 at :60 and :63); Tiannara.Constitution.Inv | medium |
| CAP-GOV-109 Constitutional amendment engine | C-GOVERNANCE | PARTIAL | Tiannara.Council | Tiannara.Council.AmendmentEngine (council/amendment_engine.ex:1-270): propose / simulate / evaluate / request_human_appr | medium |
| CAP-GOV-110 Declarative governance policy registry | C-GOVERNANCE | PARTIAL | Tiannara.Council | Tiannara.Council.PolicyRegistry (council/policy_registry.ex:1-145) with six default policies (architectural_change, self | high |
| CAP-PLT-001 API and communication layer | F-PLATFORM | PARTIAL | tiannara_api + root Elixir web layer | FastAPI app tiannara_api/main.py:92 (v1.3.0-phase5); protobuf-backed Phoenix channels lib/tiannara/web/ | high |
| CAP-PLT-004 Python services | F-PLATFORM | PARTIAL | tiannara_api; tiannara_core; tiannara_pros (tiannara_saas is | tiannara_api/main.py FastAPI (~45 routers main.py:212-255); tiannara_core is a library (no entrypoint); tiannara_pros or | high |
| CAP-PLT-005 Frontend platform | F-PLATFORM | CONTRADICTED | multiple (gui; internal_dashboard; saas; observatory_ui; des | tiannara_saas (Next.js 16 | gui (Vite+React+WebGL) vs observatory_ui (Next.js) vs desktop (Electron shell named 'Tiannara Observatory') vs saas (Next.js monetization) |
| CAP-PLT-009 Security | F-PLATFORM | CONTRADICTED | tiannara_api middleware/security; tiannara_observatory rbac; | ProductionAuthMiddleware+JWTContext+SecurityHeaders+InputValidation+EnhancedRateLimiter stack (main.py:97-102) — BUT enf | high |
| CAP-PLT-010 Deployment and CI/CD | F-PLATFORM | PARTIAL | repo root workflows + docker/ + tiannara_runtime/k8s | Elixir CI (elixir_ci.yml — all branches; includes required tiannara_runtime suite) is the only pipeline proven on this b | no rollout/rollback automation found beyond kustomize overlay (which cannot build — missing base kustomization) |
| CAP-PLT-014 (extra) tiannara_observatory umbrella platform | F-PLATFORM | PARTIAL | tiannara_observatory (10-app Elixir umbrella + Next.js UI) | TiannaraObservatory.MixProject apps: shared; observatory_core; telemetry_gateway; event_store; metrics_engine; replay_st | medium |
| CAP-WRD-001 World Model | D-WORLDMODEL | PARTIAL | root tiannara (Tiannara.World + Tiannara.Core.WorldModel); t | NO single owner. Root Tiannara.World.UnifiedWorldModel (booted via ControlCenter) is the de-facto live store; Tiannara.C | high |
| CAP-WRD-003 Civilizations and agent simulation | D-WORLDMODEL | PARTIAL | tiannara_runtime ecology+civilization (partially booted); ro | Tiannara.UniverseServer (ecology, booted via Ecology layer) + TiannaraOS.CivilizationKernel (booted in core_children) fo | medium |
| CAP-WRD-004 Multi-world experimentation | D-WORLDMODEL | CONTRADICTED | tiannara_runtime multi_world (UNBOOTED; spawn path broken) | TiannaraRuntime.MultiWorld.WorldSupervisor intended owner, but its child {TiannaraRuntime.MultiWorld.WorldProcess, id} h | high |
| CAP-WRD-005 Generational evolution | D-WORLDMODEL | PARTIAL | root Tiannara.Evolution.EvolutionEngine (booted via ControlC | Tiannara.Evolution.EvolutionEngine + Tiannara.ROS.EvolutionEngine (both booted) for live lineage; TiannaraRuntime.Evolut | medium |
| CAP-WRD-006 Research orchestration | D-WORLDMODEL | PARTIAL | root tiannara research (booted); tiannara_runtime autonomous | Tiannara.Research.ResearchDirector (booted) + Tiannara.Domains.ResearchDirector (booted) jointly own the live loop; Tian | medium |
| CAP-WRD-010 Engineering and materials research | D-WORLDMODEL | PARTIAL | root tiannara engineering (booted via ControlCenter); ASC En | Tiannara.Engineering.EngineeringSynthesisEngine (booted) + design_evaluator/proposal pipeline for DESIGNS; NO materials- | medium |
| CAP-WRD-103 Causal discovery and causal world registry | D-WORLDMODEL | PARTIAL | tiannara_runtime causal_discovery (UNBOOTED) + Causal.GCK (B | TiannaraRuntime.Causal.GCK (wired in application.ex children, uses WorldRegistry) for live causal queries; TiannaraRunti | medium |
| CAP-WRD-104 Observatory calibration worlds (API) | D-WORLDMODEL | CONTRADICTED | tiannara_api routes/observatory.py | NO real implementation verified. get_calibration_worlds() tries runtime /calibration/worlds then falls back to MOCK_WORL | high |
| CAP-WRD-108 Python research/evaluation/evolution stack (tiannara_core) | D-WORLDMODEL | PARTIAL | tiannara_core python library | tiannara_core/{evaluation,evolution,discovery,research,sim,causal,prediction} - library code consumed by tiannara_api (1 | medium |

## PLANNED / SPECIFIED ONLY (documented, not proven implemented)

| Capability | Section | Reconciliation | Owner | Implementation | Confidence |
|---|---|---|---|---|---|
| CAP-EPI-102 Observatory Epistemic CIL (discovered extra) | B-EPISTEMICS | UNKNOWN | tiannara_observatory (separate umbrella) | apps/observation_bus/lib/observation_bus/cil/epistemic/{contradiction_detector,trust_propagator,unknown_registry,..}.ex  | low |
| CAP-GOV-015 Distributed constitutional verification | C-GOVERNANCE | UNKNOWN | Tiannara.Phase14 | Tiannara.Phase14.FederationGateway (tiannara_runtime/lib/tiannara/phase14/federation_gateway.ex:1-72) - the only cross-n | low |
| CAP-GOV-116 Phase14 federation gateway (cross-instance consensus) | C-GOVERNANCE | CONTRADICTED | Tiannara.Phase14 | Tiannara.Phase14.FederationGateway (tiannara_runtime/lib/tiannara/phase14/federation_gateway.ex:1-72) | medium |
| CAP-WRD-009 Cross-domain reasoning (planned 20 domains) | D-WORLDMODEL | CONTRADICTED | root tiannara domains (registry booted; modules stubs) | Tiannara.Domains.CanonicalRegistry (booted in core_children) is the single 20-domain ontology owner; domain BEHAVIOUR is | high |
| CAP-WRD-105 TiannaraOS Stage3/4/5 civilization-adaptation layers | D-WORLDMODEL | CONTRADICTED | root lib/tiannara/os (TiannaraOS.*) | NONE authoritative: Stage3MethodEvolution/Stage4InstitutionAdaptation/Stage5CivilizationAdaptation are pure functions wi | high |

## MISSING OR UNRESOLVED

| Capability | Section | Reconciliation | Owner | Implementation | Confidence |
|---|---|---|---|---|---|
| CAP-COG-005 Context Graph | A-COGNITIVE | CONTRADICTED | none canonical (fragments in root executive/sentinel + runti | NONE - no ContextGraph module (grep ContextGraph/context_graph over *.ex/*.exs = 0 hits). Adjacent: lib/tiannara/executi | high |
| CAP-COG-006 Anticipation engine | A-COGNITIVE | CONTRADICTED | none | NONE. Adjacent stub lib/tiannara/sentinel/cognition/predictive_engine.ex:18-25 (constant forecast + confidence 0.79 + 60 | high |
| CAP-COG-007 Completion Evaluator | A-COGNITIVE | CONTRADICTED | none | NONE for general objectives. Adjacent: lib/tiannara/discovery/optimization/early_stopping_evaluator.ex (research-experim | high |
| CAP-COG-009 Dialogue State / POMDP | A-COGNITIVE | CONTRADICTED | root app (Interface) - dialogue tracking only | NONE for POMDP/belief-state. Adjacent: lib/tiannara/interface/conversation_manager.ex (booted GenServer); lib/tiannara/i | high |
| CAP-COG-013 MindCache / MindCache-Prosthetic | A-COGNITIVE | CONTRADICTED | none - name is branding only | NONE. mindcache/orchestrator.py is a demo driver over tiannara_core.memory.memory_engine.MemoryEngine (in-memory Python  | high |
| CAP-COG-103 RODL - discovered | A-COGNITIVE | CONTRADICTED | none of the claimed modules | Tiannara.Runtime.RODL.Supervisor: no defmodule anywhere; Tiannara.Runtime.OLEF.GradientSolver: markdown-only; opc/v3/ole | high |
| CAP-COG-104 EPC (control-law/PID/jacobian stack) - discovered | A-COGNITIVE | UNKNOWN | tiannara_runtime lib/tiannara_runtime/epc/ (9 modules) | epc/{control_law,coupling_matrix,governor,mode_selector,objective,pid_controller,smoothed_jacobian,stability_monitor,sta | medium |
| CAP-EPI-001 Universal Epistemic Payload (UEP) | B-EPISTEMICS | CONTRADICTED | none (no owner found) | none | high |
| CAP-EPI-007 Evidence Ageing | B-EPISTEMICS | CONTRADICTED | none (dead code) | lib/tiannara/temporal_decay/history_manager.ex (stores history; never decays) | high |
| CAP-GOV-001 Constitutional Engineering Instructions (rules.md) | C-GOVERNANCE | CONTRADICTED | none (document only) | none - rules.md is not read by any code (225-line root document) | high |
| CAP-GOV-002 Constitutional Arbitration Engine (CAE) | C-GOVERNANCE | UNKNOWN | none | not found - no defmodule/class contains CAE or ConstitutionalArbitrationEngine in either Elixir project or the Python tr | high |
| CAP-GOV-003 CAE calibration feedback | C-GOVERNANCE | UNKNOWN | none | not found | medium |
| CAP-GOV-006 Seven CAP gates | C-GOVERNANCE | UNKNOWN | none | not found - no module implements Gate1 capability alignment, Gate2 uncertainty, Gate3 adversarial robustness, Gate4 expl | high |
| CAP-GOV-111 Institutional CBAC gate (CapabilityChecker) | C-GOVERNANCE | CONTRADICTED | TiannaraOS.Governance | TiannaraOS.Governance.CapabilityChecker (os/governance/capability_checker.ex:1-180) - a real CBAC implementation with th | high |
| CAP-GOV-114 Dynamic constitutional principle plugin path | C-GOVERNANCE | PARTIAL | Tiannara.Council | Tiannara.Council.PrincipleRegistry (council/principle_registry.ex:1-85) with two default plugins (council/principles/ver | high |
| CAP-GOV-115 tiannara_audit independent verification tool | C-GOVERNANCE | CONTRADICTED | tiannara_audit (separate Mix project) | TiannaraAudit.GraphVerifier (tiannara_audit/lib/tiannara_audit/graph_verifier.ex:1-46), TiannaraAudit.ProofVerifier (pro | high |
| CAP-PLT-006 Mobile platform | F-PLATFORM | CONTRADICTED | tiannara_mobile (stubs) | none — app.py self-describes auto-generated stub (DIRECTORY_AUDIT:190-191) | high |

## CONTRADICTED / UNKNOWN — explicit gaps (never counted as pass)

| Capability | Name | Section | Evidence / note |
|---|---|---|---|
| CAP-COG-003 | Cognitive Information System (CIS) | A-COGNITIVE | Spec responsibility (monitoring/anomaly detection) is actually Sentinel.AnomalyDetector; both codebases implement a Cognitive IMMUNE System; 6 duplicate locations; kill-s |
| CAP-COG-005 | Context Graph | A-COGNITIVE | Spec requires a graph of concepts/events/goals; nothing represents relationships - consumers use isolated records; booted ContextEngine fabricates values yet tests assert |
| CAP-COG-006 | Anticipation engine | A-COGNITIVE | No predictive model; no next-action proposal module; no held-out accuracy evaluation; only booted predictive component returns a fixed string |
| CAP-COG-007 | Completion Evaluator | A-COGNITIVE | Dispatch/simulation/log presence not distinguishable from completion; no independent postcondition evidence path |
| CAP-COG-009 | Dialogue State / POMDP | A-COGNITIVE | Turn-tracking exists (booted+tested) but no uncertainty/belief representation; no action-space policy; no restart-persistence proof; POMDP claim unsupported |
| CAP-COG-012 | Executive Memory | A-COGNITIVE | No canonical owner; three booted stores use three formats (DETS /tmp path, DETS CWD, ETF); (1) default dets_dir=/tmp/tiannara/executive_memory (:156) non-portable on Wind |
| CAP-COG-013 | MindCache / MindCache-Prosthetic | A-COGNITIVE | Known suspicion CONFIRMED: no canonical MindCache owner; >=10 distinct memory stores across Python/Elixir/DETS/ETF/JSON; nothing named MindCache runs |
| CAP-COG-101 | OPC (Observer Physics Compiler) - discovered | A-COGNITIVE | Parsers/validators/OIR real and tested; execution simulated and fail-closed; production-ready claim false |
| CAP-COG-103 | RODL - discovered | A-COGNITIVE | Half the claimed phase is absent; completion doc supervision claims disproven |
| CAP-COG-104 | EPC (control-law/PID/jacobian stack) - discovered | A-COGNITIVE | Completely orphaned 9-module stack: no wiring; no tests; no verified docs claims - candidate retirement or explicit adoption |
| CAP-COG-105 | CRA (Causal Redundancy Autogenesis) - discovered | A-COGNITIVE | Code real-ish; wiring claim false; external scope absent; no in-repo deferral decision |
| CAP-EPI-001 | Universal Epistemic Payload (UEP) | B-EPISTEMICS | No schema, validator, producer or consumer enforcement for a UEP exists; the plan treats it as canonical -> CONTRADICTED. Nearest payload-like structures are fragmented a |
| CAP-EPI-006 | Detector Trust Scoring | B-EPISTEMICS | Score is computed and gates real exchanges, but the ground-truth term is a constant: no ground-truth validation and no independent scoring -> spec audit focus CONTRADICTE |
| CAP-EPI-007 | Evidence Ageing | B-EPISTEMICS | No code path anywhere applies time decay to evidence weight/confidence; the one module named for it is unwired and inert -> capability absent, spec CONTRADICTED |
| CAP-EPI-009 | Bayesian Confidence | B-EPISTEMICS | Mathematical correctness unaudited (no test, no caller); learn/3 stores counts but no Bayesian posterior update with priors is demonstrably used in any decision path; rec |
| CAP-EPI-010 | Uncertainty Disclosure | B-EPISTEMICS | Disclosure vocabulary and honest 'unknown' provenance exist, but the central registry has no boot start path while six modules call it (GenServer.call would exit unless s |
| CAP-EPI-013 | Ontology Management | B-EPISTEMICS | Versioning/migration/compatibility/rollback only partially evidenced (OED OntologySnapshots + Campaign09OntologyEvolution exist; no compatibility/migration tests found);  |
| CAP-EPI-101 | Epistemic Mirror stack (discovered extra) | B-EPISTEMICS | Likely overlaps calibration/uncertainty capabilities (AccuracyAuditor, RiskDetector); wiring and test evidence not established in R0 - candidate for Phase R follow-up |
| CAP-EPI-102 | Observatory Epistemic CIL (discovered extra) | B-EPISTEMICS | Separate umbrella outside declared main-code scope (tiannara_runtime/lib + root lib/); presence recorded so Section B does not double-count; full assessment deferred |
| CAP-ESP-004 | Architecture selection | E-ESAP | W04: scores remain analyst-assigned; comparative evidence is JSON snapshots, not derived measurements |
| CAP-ESP-007 | Frontend generation | E-ESAP | certification/atlas/R0_SOURCE_PLAN.txt:331 |
| CAP-ESP-010 | Events and asynchronous processing | E-ESAP | W10 limitation verbatim: retries, dead-letter queues and ordering are not generated; no e2e asynchronous delivery tests |
| CAP-ESP-011 | Security and authorization | E-ESAP | W11: RBAC/ABAC engine not yet wired into generated enforcement points; W17: no real DAST scanner adapter ships (fails closed); denial-path tests exist at policy-engine le |
| CAP-ESP-012 | Full-stack integration | E-ESAP | W14: union draft #140 fails Campaign A and React certification; taskflow golden is committed-not-regenerated in CI |
| CAP-ESP-014 | Deployment and operations | E-ESAP | W18: targets fail closed without injected TargetExecutor; generated CI and deploy workflows are not executed by the system itself |
| CAP-ESP-015 | Legacy repair and evolution | E-ESAP | certification/atlas/R0_SOURCE_PLAN.txt:347 |
| CAP-GOV-001 | Constitutional Engineering Instructions (rules.md) | C-GOVERNANCE | CORRECTION to prior attempt: rules.md is 225 lines, not 473. The runtime policy authority is the hardcoded Council.Constitution struct plus PolicyRegistry; no versioning, |
| CAP-GOV-002 | Constitutional Arbitration Engine (CAE) | C-GOVERNANCE | Neither the CAE v1.1 specification text nor any implementation is present in this checkout. The epistemic-justify vs authorize separation required by R0_SOURCE_PLAN.txt:2 |
| CAP-GOV-003 | CAE calibration feedback | C-GOVERNANCE | Wholly dependent on CAP-GOV-002, which is missing. There is no path by which later evidence updates an arbitration outcome, and therefore no bias-protection or reproducib |
| CAP-GOV-006 | Seven CAP gates | C-GOVERNANCE | No implementation exists to reconcile against. Three unrelated gate families share the word gate and none maps to the seven CAP gates; no PASS / CONDITIONAL / FAIL verdic |
| CAP-GOV-007 | Audit Certificates | C-GOVERNANCE | CONTRADICTED against the audit focus: no certificate in the root app carries a cryptographic signature, a validity period, or an explicit subject-version binding. The sin |
| CAP-GOV-013 | Kill switch / Safe Mode | C-GOVERNANCE | CONTRADICTED. The CIS chain is boot-wired and contract-tested, but no kill switch module is ever started: KillSwitch.request_termination/3 casts to a GenServer that no su |
| CAP-GOV-014 | Rollback and stable-state preservation | C-GOVERNANCE | CONTRADICTED: no engine restores a previously validated state and no test demonstrates restoration or data integrity after restoration. Stable-state preservation in this  |
| CAP-GOV-015 | Distributed constitutional verification | C-GOVERNANCE | The quorum computation contradicts its own documented guarantee (floor instead of ceil), votes are anonymous and replayable, and the published consensus result has no loc |
| CAP-GOV-105 | forward_provenance certificate lifecycle and identity authority (separate projec | C-GOVERNANCE | The only implementation in the repository with a real certificate state machine, closed forbidden verbs and a signature over the transition request. It is a separate Mix  |
| CAP-GOV-106 | Production certification campaign and gate framework (runtime) | C-GOVERNANCE | A second, unrelated 13-gate production framework plus 30 campaigns, with no documented mapping to the seven CAP gates and no located test coverage. It must not be reconci |
| CAP-GOV-111 | Institutional CBAC gate (CapabilityChecker) | C-GOVERNANCE | CONTRADICTED against 'Enforce authority and permissions': the only genuine capability-based access-control implementation in the repository is completely unreachable at r |
| CAP-GOV-113 | Council RuleEngine constitutional scoring | C-GOVERNANCE | CONTRADICTED. With the built-in assessor the maximum attainable compliance is 0.70 (all eleven principles neutral), which is below the 0.80 threshold for :approved, so Ru |
| CAP-GOV-115 | tiannara_audit independent verification tool | C-GOVERNANCE | CONTRADICTED. Both verifiers are structurally incapable of failing, so any PASS report they produce - including the committed 220/220 INDEPENDENT_AUDIT_REPORT.md - establ |
| CAP-GOV-116 | Phase14 federation gateway (cross-instance consensus) | C-GOVERNANCE | The implementation contradicts the guarantee its own moduledoc claims: floor instead of ceil means a two-node cluster needs only one vote, and a one-node cluster needs ze |
| CAP-PLT-005 | Frontend platform | F-PLATFORM | F-PLT-003;F-PLT-010;F-PLT-014;F-PLT-015 |
| CAP-PLT-006 | Mobile platform | F-PLATFORM | Zero API connectivity code; generated by tiannara_core/tests/generate_all_remaining.py:33-38 (test-harness artifact). No mobile capability claim can be made from this che |
| CAP-PLT-009 | Security | F-PLATFORM | Dependency security: NO dependabot.yml, no safety/pip-audit/npm audit/codeql/trivy in any workflow (grep of .github/workflows = 0 hits); key-shaped pem*.txt files exist a |
| CAP-PLT-011 | Resource management | F-PLATFORM | No system-level memory/CPU governor found (Optimize-WindowsBEAM.ps1 is a local helper script); backpressure exists only as CEL EventBus option flag and API rate limits; d |
| CAP-PLT-012 | Documentation and developer tooling | F-PLATFORM | Code ownership: no CODEOWNERS file found; achievement-style docs (e.g. tiannara_core/tests 100% COMPLETE markdown) are non-evidence per DIRECTORY_AUDIT:140-141; developer |
| CAP-PLT-013 | (extra) Electron desktop shell tiannara-desktop | F-PLATFORM | Discovered via filesystem+git; no CI, no docs; whether it consumes runtime/API endpoints is UNKNOWN without deeper renderer analysis |
| CAP-WRD-004 | Multi-world experimentation | D-WORLDMODEL | basis=statically_inferred; controlled-comparison primitives (deterministic_replay 354 loc) exist but no booted world population, no cross-world experiment runner, and cor |
| CAP-WRD-009 | Cross-domain reasoning (planned 20 domains) | D-WORLDMODEL | ANSWER to audit question: 20 domain modules EXIST in code and are registered; ~1 (physics) is substantive; 19 are stubs whose discover/validate/simulate/metrics return em |
| CAP-WRD-102 | Digital twin stack (world_model/digital_twin) | D-WORLDMODEL | basis=statically_inferred; two unrelated 'digital twin' concepts exist; runtime stack has no boot parent and no confirmed runtime evidence |
| CAP-WRD-104 | Observatory calibration worlds (API) | D-WORLDMODEL | basis=dynamically_observed (source read); this is the GENERATING SOURCE of the historical 12-world claim (range(12) hard-coded; civilizations=random.randint(4,12); agents |
| CAP-WRD-105 | TiannaraOS Stage3/4/5 civilization-adaptation layers | D-WORLDMODEL | basis=documented+statically_inferred (prior audit, reused); must not be wired into any runner without data-layer un-stubbing (STAGE6 'smallest proposed integration sequen |
