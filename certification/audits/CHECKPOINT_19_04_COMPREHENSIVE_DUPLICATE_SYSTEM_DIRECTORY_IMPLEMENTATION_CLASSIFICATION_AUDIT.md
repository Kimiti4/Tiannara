# Checkpoint 19.04 — Comprehensive Duplicate System Directory and Implementation Classification Audit

**Audit status:** OPEN — all 29 named directory families re-enumerated and provisionally classified at source/path level; execution ownership and caller proof remain incomplete for selected systems  
**Audit branch:** audit/consolidated-findings-r0a-2026-10-31  
**Source baseline:** e946d7e3b69837177ec74a8425bfa36497f9f99a  
**Previous checkpoint:** 19.03 — Service Integration, Network Reachability and Deployment Gate Audit  
**Finding register continuation:** RL-541 onward

## 1. Objective and audit boundaries

This checkpoint refreshes the duplicate-system inventory from the current audit-branch tree rather than carrying forward the historical 18.97 source baseline. It examines the 29 named system families from the prior ownership register, the root Elixir source tree, runtime project source namespaces, selected embedded system directories, module identities, supervisor definitions, and current callers where found.

The two principal Elixir build roots are separate:
- Root project: root mix.exs, root lib/ and Tiannara.Application.
- Runtime project: tiannara_runtime/mix.exs, tiannara_runtime/lib/ and TiannaraRuntime.Application.

Additional occurrences inside a project are included when a system is nested beneath another owner (for example Physics/IRD, Stabilization/OCM, ASC/Core, or Sentinel/SOPL).

This report does **not** equate a same-named directory with duplicate implementation. The classifications distinguish:
1. Same BEAM module identity in separate Mix projects.
2. Different module identities with overlapping decision or state authority.
3. Subsystems that appear layered or complementary.
4. Legacy/unconnected implementations whose runtime owner is not established.
5. Removed stubs whose consumers still have fallbacks or stale references.

No source code, supervisor, registry, application configuration, Dockerfile, or workflow was modified.

## 2. Method and evidence rules

The current audit-branch Git tree was retrieved at the source baseline above:
- 28,365 tree entries.
- Complete recursive tree response (not truncated).
- Current root lib/tiannara directory tree and runtime project source roots were enumerated.
- The prior 29-name inventory was cross-checked against exact current paths.
- Representative supervisor files, module implementations, root application startup, runtime StartupSupervisor/RootSupervisor, and known stub consumers were inspected.
- The prior 12-module explicit stub list was checked against the current tree and selected current callers.

Classification language:
- **SAME_MODULE_IDENTITY:** two source roots define the same fully qualified module name.
- **OVERLAPPING_AUTHORITY:** separate modules appear to make decisions or own state in the same problem domain without a proven authority boundary.
- **LAYERED_CANDIDATE:** implementations appear to occupy different stages or abstractions, but the interface/authority contract still needs evidence.
- **DISTINCT_SYSTEMS / ACRONYM_OVERLAP:** names overlap but the inspected implementation roles are materially different.
- **LEGACY_OR_UNCONNECTED:** code exists but the current application startup graph does not establish it as active.
- **BOUNDARY_UNPROVEN:** no safe conclusion about equivalence or authority can be made from the inspected evidence.

A supervisor source file is not proof that its parent starts it. A module being compiled is not proof that the module is running. The two Mix applications are not declared as one combined application in the inspected release topology; therefore a same-module-identity conflict is a **project-level collision risk**, not proof that both definitions are currently loaded in one VM.

## 3. Executive result

### 3.1 Duplicate directory classification

**29/29 named system families have been re-enumerated and given a current source-level classification.** This replaces the old statement that only 4/29 were meaningfully classified at the 18.97 baseline.

That is not equivalent to proving that all 29 have a canonical production owner. The current results include:
- **5 system families with confirmed same-module-identity occurrences across the root and runtime source roots:** A10, OED, Core, Sentinel, and Meta.
- **Several additional families with materially overlapping responsibilities but different module namespaces:** CIS, IRD, MSG, OCM, OS, OMCE and OMCS.
- **Other families that appear layered or functionally distinct:** the classification table below records the evidence and remaining boundary question for each.

### 3.2 Same-module-identity collisions

At least **7 exact module identities** were directly confirmed across the five system families:
- A10: Tiannara.A10.Supervisor.
- OED: Tiannara.OED.Supervisor.
- Core: Tiannara.Core.Ontology.Index.
- Meta: Tiannara.Meta.CausalTensegrityEngine.
- Sentinel: Tiannara.Sentinel.Supervisor, Tiannara.Sentinel.TelemetryHub, and Tiannara.Sentinel.AnomalyDetector.

The Sentinel and Core examples have materially different implementations under the same module identity:
- Root Sentinel TelemetryHub exposes broadcast/3; runtime Sentinel TelemetryHub exposes ingest_event/1.
- Root Sentinel AnomalyDetector is a pure detection API; runtime AnomalyDetector is a GenServer with evaluate/1 whose current handler does not perform classification.
- Root Core Ontology Index is a stateful ETS-backed GenServer; the runtime copy returns {:ok, 0} from count_concepts/0 and does not start a process.

The Meta CausalTensegrityEngine implementations also differ substantially: the root file exposes a bounded forward projection function; the runtime file describes a paradox-resolution GenServer. A combined BEAM code path could select the wrong public contract for callers.

### 3.3 Current explicit stub status

The old 18.97 inventory found 12 modules using Tiannara.Stub. On the current branch:
- The stubs directory contains only the shared macro and StubRegistry; the ten old standalone stub implementation files are absent from the current tree.
- Two embedded macro users were confirmed in current source: Tiannara.ASC.Interface.Protocol and Tiannara.REA.TheoryNiches.
- The macro still returns configured defaults as ordinary results, and only attempts to record a call when StubRegistry is already running.
- No StubRegistry child was found in the inspected root application or runtime startup graphs.
- Some former stub files were replaced and their consumers migrated; other former stub identities disappeared while their callers retain fixed fallback data, optional no-provider branches, or a stale module alias.

Thus the old count of 12 is a historical finding count, not the current number of source modules. A full stub-like scan that includes constant-return helpers, fallback branches, mocks, empty supervisors, and synthetic-success code remains necessary before declaring the total stub inventory complete.

## 4. Current 29-system ownership and implementation register

| System | Current occurrences in the inspected tree | Current classification | Evidence and remaining question |
|---|---|---|---|
| A10 | Root lib/tiannara/a10; runtime tiannara_runtime/lib/tiannara/a10 | **SAME_MODULE_IDENTITY / LEGACY OR UNCONNECTED** | Both define Tiannara.A10.Supervisor. Root uses one_for_one and embeds the named child modules in its source; runtime source defines the same supervisor identity with rest_for_one and references the same child identities. Neither current root application child list directly establishes ordinary A10 startup. Verify PhaseΩ activation and the runtime child module set before consolidation. |
| ALES | Root lib/tiannara/ales; runtime tiannara_runtime/lib/tiannara_runtime/ales | **LAYERED CANDIDATE / BOUNDARY UNPROVEN** | Root Tiannara.ALES.Supervisor is an in-memory evolvable-law state manager; runtime ALES occurrence is an EvolutionEngine. No same module identity was established. Determine whether the runtime engine is a successor/consumer or a separate law-evolution capability. |
| ACM | Root lib/tiannara/acm; runtime tiannara_runtime/lib/tiannara/oed/acm | **DISTINCT SYSTEMS / ACRONYM OVERLAP** | Root ACM has epistemic_disease and epistemic_predator modules. Runtime OED.ACM is an adversarial crucible family with generators, discriminators, exploit engines and simulations. Do not merge by acronym; verify how the root ACM capability participates in OED validation. |
| CIS | Root lib/tiannara/cis; runtime tiannara_runtime/lib/tiannara_runtime/cis; runtime legacy cis paths | **OVERLAPPING SAFETY AUTHORITY** | Root Tiannara.CIS.Supervisor owns collapse prediction, immune decision and regulation processes and is a root application child. Runtime TiannaraRuntime.CIS.Supervisor is a separate destructive-operation arbitration kernel; TiannaraRuntime.Application includes it as an optional child. The distinction between ecosystem health regulation and authorization of destructive operations must be constitutional and explicit. |
| CTL | Root lib/tiannara/ctl; runtime tiannara_runtime/lib/tiannara_runtime/ctl | **LAYERED CANDIDATE — ROOT REGISTRY IS SUBSTANTIVE** | Root Tiannara.CTL.CausalRegistry now maintains branch identity/lineage/measured stress and fails closed when unavailable. Root BranchValidator aliases this uppercase production module. Runtime CTL supervisor starts a separate Engine and Reconciler. The former Tiannara.Ctl.CausalRegistry stub is absent from the current tree. Define whether runtime CTL consumes the root branch registry or owns distributed causal reconciliation independently. |
| DFG | Root lib/tiannara/dfg; root lib/tiannara/topology/dfg; runtime tiannara_runtime/lib/tiannara_runtime/dfg | **LAYERED OR PARALLEL IMPLEMENTATIONS** | Root Topology.DFG supervisor coordinates dimensional folding, homology, transformation and integrity validation. Runtime DFG supervisor owns plateau detection, topological folding, meta-reality spawning, portal rendering and latent runtime. Different namespaces and child contracts; prove shared inputs/outputs and canonical graph owner. |
| EUF | Root lib/tiannara/euf; runtime tiannara_runtime/lib/tiannara_runtime/euf | **PARALLEL EPISTEMIC CAPABILITIES / BOUNDARY UNPROVEN** | Root EUF supervisor stores ontology confidence, observer beliefs and theory survival in memory. Runtime occurrence is a ConfidenceTracker. No exact module collision found. Establish whether runtime confidence tracking is a subordinate measurement provider or a second authority. |
| IRD | Root lib/tiannara/ird; root lib/tiannara/physics/ird; runtime tiannara_runtime/lib/tiannara_runtime/ird | **MULTIPLE IMPLEMENTATIONS / OVERLAPPING INTERVENTION AUTHORITY** | Root Tiannara.IRD.Supervisor is a GenServer maintaining intervention budget/quiescence state; root Physics.IRD.Supervisor supervises resonance calculator, dampening engine, coordinator and NATS integration; runtime IRD supervises consumer, interference matrix, phase scheduler, budget controller, quiescence manager and feedback. Root Physics.Supervisor starts Physics.IRD; runtime Constraint.Supervisor starts runtime IRD. Define one intervention policy owner and subordinate executor boundary. |
| MSG | Root lib/tiannara/msg; runtime tiannara_runtime/lib/tiannara_runtime/msg | **OVERLAPPING META-STABILITY GOVERNANCE** | Root Tiannara.MSG.Supervisor is a GenServer computing overregulation and stabilization pressure; runtime TiannaraRuntime.MSG.Supervisor wraps a Governor. No exact module collision. The current runtime RootSupervisor Meta layer does not directly establish that this MSG supervisor is started. Determine whether it is legacy, optional, or authoritative. |
| NDE | Root lib/tiannara/nde; root lib/tiannara/physics/nde; runtime research-profile path | **SPLIT ENGINE / STARTUP PROFILE DEPENDENT** | Root Tiannara.Physics.Supervisor starts Physics.NDE. Root Tiannara.NDE is a separate convergence/novelty package. Runtime NDE is experimental and only included by the research boot profile when its flag is enabled. Specify the boundary between the general NDE package and physical NDE; do not infer equivalence from the acronym. |
| OAVL | Root lib/tiannara/oavl; runtime tiannara_runtime/lib/tiannara/oed/oavl | **NESTED VALIDATION LAYER / BOUNDARY UNPROVEN** | Root OAVL occurrence is DiscoveryVerifier. Runtime OED.OAVL has multiple validation gates and a ValidationSupervisor. These appear to be a single-purpose verifier versus a broader ontological-validation membrane, but consumers, evidence contracts and authority need mapping. |
| OCM | Root lib/tiannara/ocm; root lib/tiannara/stabilization/ocm; runtime tiannara_runtime/lib/tiannara_runtime/ocm | **OVERLAPPING CONSENSUS / ONTOLOGY AUTHORITY** | Root OCM modules implement ontology registry/alignment/drift and translation. Root Stabilization.OCM supervisor starts consensus manager, voting system, reconciliation engine and conflict resolver. Runtime OCM supervisor starts Registry and ConsensusEngine and is optionally started under runtime Ecology. Define which owner controls ontology truth, merge permission and reconciliation effects. |
| OED | Root lib/tiannara/oed; runtime tiannara_runtime/lib/tiannara/oed; runtime OED namespace subtree | **SAME_MODULE_IDENTITY / STARTUP UNPROVEN** | Root and runtime both define Tiannara.OED.Supervisor and near-matching child sets; root strategy is one_for_one, runtime strategy is one_for_all. Runtime has separate source files for the OED child services. Neither ordinary application child list directly proves OED residency; PhaseΩ wiring invocation is still not sufficient proof without a boot trace. |
| OMCE | Root lib/tiannara/omce; runtime tiannara_runtime/lib/tiannara_runtime/omce | **OVERLAPPING CONTINUITY CAPABILITY** | Root OMCE supervisor owns MemoryContinuity and ContinuityIndex. Runtime OMCE contains causal pruning, compression pipeline, engine, identity merger and semantic compressor. No exact module collision found; determine if runtime is the algorithmic substrate for root OMCE or an independent continuity owner. |
| OMCS | Root lib/tiannara/omcs; runtime tiannara_runtime/lib/tiannara_runtime/omcs | **PARTITIONED CONTINUITY / AUTHORITY UNPROVEN** | Root OMCS engine stores identity, lineage, narrative and causal graphs in GenServer state and is started by root application. Runtime contains continuity index and identity hash chain but no corresponding supervisor was found. Define persistence, replay and authority ownership across the two stores. |
| OS | Root lib/tiannara/os; runtime tiannara_runtime/lib/tiannara_runtime/os | **SEPARATE APPLICATION DOMAINS / CROSS-BOUNDARY CONTRACT UNPROVEN** | Root TiannaraOS code contains constitutional kernel, science, principle/domain registries, lifecycle and civilization execution. Runtime OS tree is concentrated on persistence, observatory, governance and certification campaigns. Namespaces differ, but overlapping constitutional/certification claims require a clear authority/adapter contract. |
| REA | Root lib/tiannara/rea and discoveries; runtime tiannara_runtime/lib/tiannara/phase16/rea | **DISTINCT FUNCTIONAL SYSTEMS WITH ACRONYM COLLISION** | Root REA is Research Evolution Architecture with causal, epistemic, lineage and observability components. Phase16 REA is recursive epistemic arbitration/axiom harmonization. Both can coexist as different stages; define explicit interface and evidence handoff. Root TheoryNiches still contains a stubbed method (see stub register). |
| SOPL | Root lib/tiannara/sopl; root lib/tiannara/sentinel/sopl | **GOVERNANCE AND SENTINEL INTEGRATION LAYERS** | Root SOPL supervisor owns law attractor, archaeology and unknown-law registries. Sentinel/SOPL contains a SpeciesTracker. This is not evidence of a second SOPL supervisor; map whether Sentinel tracks or exercises SOPL governance decisions. |
| TWP | Root lib/tiannara/twp; root lib/tiannara/physics/twp | **SPLIT TEMPORAL/WAVEFUNCTION IMPLEMENTATION** | Physics.TWP supervisor runs temporal coherence, pruning, validation and collapse components. Root Tiannara.Twp has branch compression/pruning, timeline registries and WavefunctionSolver. The old SurvivabilityEstimator module is absent, but WavefunctionSolver still falls back to a fixed 0.5. Define estimator authority and evidence requirements. |
| UCC | Root lib/tiannara/ucc; runtime tiannara_runtime/lib/tiannara/phase17/ucc | **LAYERED CANDIDATE — CONTRACT NOT PROVEN** | Root UCC supervisor starts macro-state and constitutional-attractor registries; its own comments say NATS consumer integration is not yet verified. Phase17 UCC compiles harmonized constraint graphs into target execution DAGs. This looks like registry/ontology inputs versus compiler execution, but a verified requirement/IR/effect contract is needed. |
| Omega | Root lib/tiannara/omega; runtime tiannara_runtime/lib/tiannara_runtime/omega | **DISTINCT AGENCY AND ROBUSTNESS LAYERS** | Root Omega supervisor composes event bus, telemetry window, heartbeat, agency orchestration, research, sandbox, certification and terminal governance gate. Root app directly starts OmegaRuntime, not the named Omega.Supervisor in the inspected child list. Runtime Omega supervisor owns soak readiness, failure observatory, executive memory, dependency isolation, checkpoint reliability and health. Runtime StartupSupervisor starts runtime Omega. Do not treat them as duplicate implementations without a cross-layer authority map. |
| Meta | Root lib/tiannara/meta; runtime tiannara_runtime/lib/tiannara_runtime/meta | **SAME MODULE IDENTITY / DIFFERENT CAUSAL MODEL** | Both source roots define Tiannara.Meta.CausalTensegrityEngine. Root version exposes forward projection; runtime version is a paradox-resolution GenServer using Tiannara.Causality.Graph. Runtime Meta.Supervisor starts the runtime meta-governance stack; root application starts Meta.Hardware.Supervisor. This is a concrete project-level module collision and an unproven conceptual integration. |
| Meta-science | Root lib/tiannara/meta_science; root lib/tiannara/asc/meta_science | **COMPOSED SCIENCE-PORTFOLIO AND ASC EVOLUTION LAYERS** | Root MetaScience modules include bottleneck, novelty and portfolio functions; ASC.MetaScience contains genome-driven executor, campaigns, program evolution and research-genome definitions. Different namespaces and purposes; prove shared campaign/portfolio interfaces before consolidation. |
| Interface | Root lib/tiannara/interface; root lib/tiannara/asc/interface | **DISTINCT HUMAN INTERFACE AND ASC INTERFACE-GENOME LAYERS** | Root Interface contains cognitive interface, conversation and human collaboration/presentation services. ASC.Interface contains protocol, contract, event, genome and mutation/evolution models. These should not be merged as one module family. ASC.Interface.Protocol.hybrid/2 is still stubbed. |
| Engineering | Root lib/tiannara/engineering; root lib/tiannara/asc/engineering; runtime world-model engineering | **DISTINCT ENGINEERING AUTHORITY LAYERS / INTEGRATION UNPROVEN** | Root Engineering supervisor owns synthesis, proposal registry, root-cause analysis, proposal generation and verification authority. ASC.Engineering supervisor owns design/CAD/systems/manufacturing/digital-twin/validation engines. Runtime world-model engineering represents a third location. Define proposal-to-design handoff, who approves engineering changes, and who owns verified execution evidence. |
| Core | Root lib/tiannara/core; root lib/tiannara/asc/core; runtime tiannara_runtime/lib/tiannara/core; runtime Sentinel observatory core | **SAME MODULE IDENTITY AND PLACEHOLDER DUPLICATE** | Root Tiannara.Core.Supervisor starts a stateful ontology cache/index. Root ASC.Core is a separate compiler substrate. Runtime source defines the same Tiannara.Core.Ontology.Index identity as a tiny function returning {:ok, 0}; its runtime project copy has no matching GenServer. The root implementation is authoritative in the root app; the runtime copy is a legacy/placeholder duplicate whose active callers/startup remain unproven. |
| Sentinel | Root lib/tiannara/sentinel; runtime tiannara_runtime/lib/tiannara/sentinel; runtime namespace Sentinel tree | **SAME MODULE IDENTITY / DIVERGENT SAFETY AND TELEMETRY IMPLEMENTATIONS** | Root and runtime source both define Tiannara.Sentinel.Supervisor, TelemetryHub and AnomalyDetector. Root TelemetryHub exposes broadcast/3 and routes to Observatory; runtime version ingests TelemetryEvent structs and forwards to EventClassifier/OutcomeTracker. Root AnomalyDetector is a pure detector; runtime version is a GenServer with a no-op event handler. Root app starts root Sentinel.Supervisor; current runtime RootSupervisor does not start the old Tiannara.Sentinel.Supervisor copy. Runtime copy is legacy/unconnected in the declared runtime tree unless another activation route exists. |
| Telemetry | Root lib/tiannara/telemetry; runtime tiannara_runtime/lib/tiannara/telemetry; runtime tiannara_runtime/lib/tiannara_runtime/telemetry; Observatory observation bus | **MULTIPLE OBSERVABILITY ADAPTERS / NO SINGLE CANONICAL EVENT CONTRACT PROVEN** | Root has observation, anomaly detection and Sentinel bridge; runtime old namespace has EventAggregator; runtime namespace has a separate event aggregator; Observatory has its own telemetry gateway/observation bus. These are not all exact module collisions, but their event schemas, retention and authoritative metrics owner need one documented integration contract. |
| Topology | Root lib/tiannara/topology; runtime tiannara_runtime/lib/tiannara_runtime/topology | **DISTINCT TOPOLOGY AND PERSISTENT-HOMOLOGY LAYERS** | Root Topology has ACF/CCR/DFG/OSL/RRG supervisors; runtime Topology occurrence is PersistentHomology. No same module identity found. Establish whether runtime homology consumes root topology graphs or is standalone. |

## 5. Confirmed exact module identity collision register

These are not generic duplicate names; they are module identities that occur in more than one Mix source root.

| Module identity | Root implementation | Runtime project implementation | Divergence | Current startup evidence |
|---|---|---|---|---|
| Tiannara.A10.Supervisor | Root A10 supervisor, one_for_one | Runtime A10 supervisor, rest_for_one | Different failure propagation; root child modules are embedded in root supervisor source while runtime copy is a separate file set | Neither current application child list directly proves the named A10 supervisor is started |
| Tiannara.OED.Supervisor | Root OED supervisor, one_for_one | Runtime OED supervisor, one_for_all | Similar children, different restart semantics | No direct child in the current root application or runtime RootSupervisor; PhaseΩ activation still requires boot proof |
| Tiannara.Core.Ontology.Index | ETS-backed GenServer with search/index APIs | count_concepts/0 returns {:ok, 0}; no stateful server | Same name, incompatible public API and behavior | Root Core.Supervisor starts the real root Index; runtime copy is not shown in current runtime RootSupervisor |
| Tiannara.Meta.CausalTensegrityEngine | Bounded forward projection function | Paradox-resolution GenServer | Same name, materially different public API and semantics | Root ESG calls projection API; runtime Meta supervisor does not directly list this child |
| Tiannara.Sentinel.Supervisor | Root Sentinel supervision tree, one_for_all | Runtime legacy Sentinel supervision tree, one_for_one | Different child topology and responsibility split | Root app starts root Sentinel; legacy runtime copy not present in current runtime RootSupervisor graph |
| Tiannara.Sentinel.TelemetryHub | broadcast/3, forwards to root Observatory | ingest_event/1, forwards to classifier/outcome tracker | Incompatible call contracts | Root supervisor starts root version; runtime old-namespace version not proven active |
| Tiannara.Sentinel.AnomalyDetector | Pure detect/2 analysis | GenServer evaluate/1; current handle_cast does not classify event | Incompatible call contracts and substantive behavior gap | Root supervisor starts root version; runtime old-namespace copy not proven active |

**Important deployment qualification:** the root and runtime Mix projects are separate application builds; the root release does not declare the runtime project as a dependency. The collisions above do not prove that both BEAM definitions are currently loaded into one VM. They are a release-composition and future consolidation hazard, and they make any proposal to merge the projects unsafe until module identity conflicts are resolved. In the current separate-project design, the runtime copies still need classification as legacy, active, or dead code; compile success alone does not establish their use.

## 6. Current stub and stub-like inventory refresh

### 6.1 Status of the 12 modules from Checkpoint 18.97

| Historical stub module | Current branch evidence | Current disposition |
|---|---|---|
| Tiannara.Ctl.CausalRegistry | Old stub file absent. BranchValidator now aliases Tiannara.CTL.CausalRegistry. Production registry validates branch ID/stress and returns registry_unavailable when not running. | **REPLACED / CONSUMER MIGRATED** — verify tests and runtime branch evidence separately |
| Tiannara.Meta.CausalDataLayer.Traversal | Old stub file absent. Sentinel EpistemicShadowGraph still checks whether the module exists and substitutes an empty nodes/edges snapshot when absent. | **STUB REMOVED; SYNTHETIC FALLBACK REMAINS** |
| Tiannara.ASC.Crucible.Supervisor | Old stub file absent. ASC Pipeline.Phases.handler(:crucible) now returns nil with an explicit comment that the stub was removed and no active phase handler exists. SubCiv supervisor keeps Crucible out of its child list. | **HONESTLY DISABLED / NOT IMPLEMENTED** — not an active stub, but no crucible phase capability is established |
| GenerationHistory (global module) | Old stub file absent. RecursiveCivilizationRunner now references TiannaraOS.Kernel.GenerationHistory for append, CAI and construction. | **REPLACED / CONSUMER MIGRATED** — persistence and evidence validity still require separate verification |
| Graph | Old global Graph stub absent. REL CivilizationFitness now computes lineage through Tiannara.OMCS.Engine.get_lineage/1. | **REPLACED / CONSUMER MIGRATED** |
| TiannaraOS.LifecycleRegistry | Old stub file absent. A substantive Tiannara.LifecycleRegistry exists and root Application starts it, but TiannaraOS.PrincipleRegistry still aliases TiannaraOS.LifecycleRegistry and calls track_entity/4. The real root registry has a different module identity and record_created/record_removed-style API. | **PARTIAL MIGRATION / DANGLING LEGACY CALLER** |
| Tiannara.Meta.Epistemics.LongitudinalMemory | Old stub file absent. EpistemicShadowGraph still substitutes a fixed LEOC vector [1.0, 0.0, 0.0, 0.0] if the provider is not loaded. | **STUB REMOVED; FIXED FALLBACK REMAINS** |
| TiannaraOS.ScientificCapitalLedger | Old stub file absent. RecursiveCivilizationRunner now uses TiannaraOS.Kernel.ScientificCapitalLedger. | **REPLACED / CONSUMER MIGRATED** |
| Tiannara.Sentinel.PressureMonitor | Old stub file absent. TelemetryChannel only calls it if a process exists; no active provider/startup owner was established. | **REMOVED / OPTIONAL PROVIDER UNAVAILABLE** |
| Tiannara.Twp.SurvivabilityEstimator | Old stub file absent. WavefunctionSolver still assigns survivability 0.5 when estimate/1 is not exported. | **STUB REMOVED; CONSTANT FALLBACK REMAINS** |
| Tiannara.ASC.Interface.Protocol | Module remains and still uses Tiannara.Stub. Its hybrid/2 method returns a stub-shaped success map; other protocol methods are substantive. | **ACTIVE PARTIAL STUB** |
| Tiannara.REA.TheoryNiches | Module remains embedded in discoveries/theory_selection.ex and still uses Tiannara.Stub. classify_theories/1 returns {:ok, []}; classify_niches/1 has separate classification logic. | **ACTIVE PARTIAL STUB** |

### 6.2 Remaining stub infrastructure defect

The current tree contains:
- lib/tiannara/stubs/stub.ex;
- lib/tiannara/stubs/stub_registry.ex.

The macro records calls only when Process.whereis(Tiannara.StubRegistry) returns a PID. The inspected root Application child list and runtime StartupSupervisor/RootSupervisor graph do not start StubRegistry. Therefore current uses can return configured defaults without a corresponding registry record. The defaults remain ordinary values, not typed UNKNOWN/NOT_IMPLEMENTED results.

### 6.3 Sentinel shadow-graph fallback remains epistemically unsafe

The explicit traversal and longitudinal-memory stub files are absent, but the consumer still fabricates:
- fixed latent vector: LEOC [1.0, 0.0, 0.0, 0.0];
- empty causal snapshot: nodes [], edges [];
- unchanged state when the optional causal engine is not loaded;
- divergence: fixed 0.1 in calculate_ontological_divergence/2;
- unchanged latent state in apply_intervention_to_latent_state/2.

The evaluator then computes a confidence score and may approve when that score reaches 0.85. This is not a real shadow simulation or evidence-backed intervention validation. It is now more accurately classified as **fallback theater / synthetic evidence acceptance**, rather than the original two active stub modules. The existing RL-502/CP18.98 finding remains open and is reclassified by this checkpoint.

## 7. Remediation state: what changed versus what remains

### 7.1 Positively migrated in the current branch

These changes are visible in current source and the previous stub consumer has been redirected:
1. CTL branch validation uses the uppercase production CausalRegistry, not the lowercase stub identity.
2. Stage-6 runner calls the Kernel GenerationHistory module for persistence, CAI and record construction.
3. Stage-6 runner calls the Kernel ScientificCapitalLedger for capital delta.
4. REL lineage fitness uses the OMCS Engine public lineage API instead of the former global Graph stub.
5. ASC crucible stub has been removed and the phase handler explicitly returns nil; this stops the old {:ok, :stub} result from masquerading as successful execution.

These are source-level migration observations, not independent proof that every associated runtime behavior is complete.

### 7.2 Remediation still required

**Must be resolved before structural consolidation:**
- Decide whether root and runtime copies of A10, OED, Sentinel, Core Ontology Index and Meta CausalTensegrityEngine should be unified, adapted, or kept as isolated service boundaries.
- Decide the single authoritative safety-decision path across root CIS and runtime CIS.
- Define OCM/IRD/MSG authority boundaries, including which service may approve and which may execute interventions.
- Map OMCE/OMCS state ownership, persistence, identity lineage and replay semantics across project roots.
- Resolve the OS namespace and the stale TiannaraOS.LifecycleRegistry API reference to the real Tiannara.LifecycleRegistry implementation.
- Replace Sentinel ESG's synthetic fallback inputs and constant divergence with real, versioned evidence providers or make the function return UNKNOWN/ABSTAIN.
- Replace the TWP fixed 0.5 survivability fallback with an actual estimator or explicit unavailable status.
- Replace the two remaining partial Stub macro users with typed unavailable results or independently verified implementations; supervise StubRegistry if it remains part of the architecture.
- Complete caller/test/startup mapping for the other 29-system families, especially the systems classified as layered candidates or overlapping authorities.

## 8. Findings added in Checkpoint 19.04

| ID | Severity | Finding | Status |
|---|---|---|---|
| RL-541 | CRITICAL | Same BEAM module identities are defined across the root and runtime projects for A10, OED, Core Ontology Index, Meta CausalTensegrityEngine and Sentinel modules, with divergent APIs or supervisor strategies | PROJECT_LEVEL_MODULE_IDENTITY_CONFLICT |
| RL-542 | CRITICAL | Runtime Tiannara.Core.Ontology.Index is a constant-return placeholder returning {:ok, 0}, while the root project defines the stateful ETS-backed production index under the same module identity | DUPLICATE_PLACEHOLDER_IMPLEMENTATION |
| RL-543 | CRITICAL | Sentinel EpistemicShadowGraph still accepts fixed latent memory, empty causal graph, identity mutation and fixed divergence as inputs to an approval decision | SYNTHETIC_EVIDENCE_FALLBACK |
| RL-544 | HIGH | OS PrincipleRegistry still calls missing TiannaraOS.LifecycleRegistry.track_entity/4 even though the current substantive registry is Tiannara.LifecycleRegistry with a different module/API contract | DANGLING_LEGACY_CALLER |
| RL-545 | HIGH | Two partial implementations still use Tiannara.Stub and return ordinary success-shaped defaults for protocol hybridization and theory classification | ACTIVE_PARTIAL_STUBS |
| RL-546 | HIGH | StubRegistry has no established supervised startup path; remaining stub calls can return defaults without recording calls | STUB_OBSERVABILITY_NOT_ENFORCED |
| RL-547 | HIGH | TWP WavefunctionSolver continues to substitute constant survivability 0.5 when the estimator is unavailable | FIXED_METRIC_FALLBACK |

RL-497–RL-506 and RL-522–RL-540 remain in the historical register. Their current-branch statuses must be read with the reclassifications in this report; older findings are not automatically still active in the same form.

## 9. Completion status and remediation readiness

### Duplicate directory audit

- **29/29** named system families re-enumerated at the current source baseline.
- **5** families have confirmed same-module-identity conflicts across source roots.
- Additional overlapping authority or data ownership concerns remain in CIS, IRD, MSG, OCM, OS, OMCE and OMCS.
- The directory/path inventory is now materially complete for the 29 named families, but runtime caller completeness, storage equivalence, tests and deployment ownership are not complete.
- No duplicate module should be deleted or merged solely from this classification. The separate Mix project boundary must be preserved until deployment topology and co-loading assumptions are formally decided.

### Stub audit

- The historical 12 explicit stub modules have each been rechecked against current source.
- Four have source-level production replacements with their principal consumers migrated (CTL, GenerationHistory, Graph lineage scoring, ScientificCapitalLedger).
- One stub has been removed with the ASC crucible phase explicitly disabled (not implemented).
- One replacement exists under a different API/module name but the OS PrincipleRegistry caller remains stale (LifecycleRegistry).
- Three old stubs are gone but fixed/empty fallbacks remain (causal traversal, longitudinal memory, survivability estimator).
- One optional provider stub is gone but no active provider is established (PressureMonitor).
- Two partial stub sites remain active (ASC Interface.Protocol and REA TheoryNiches).
- StubRegistry remains unsupervised in the inspected application startup graphs.
- **The full stub-like inventory is not yet complete** because constant-return modules, placeholder supervisors, no-op handlers, development mocks and synthetic evidence paths outside use Tiannara.Stub still require a separate whole-repository scan.

### Remediation readiness

**Bounded remediation can begin** for specific findings with exact source paths and explicit contracts: remove the stale LifecycleRegistry call path, replace the fixed TWP estimator fallback with UNKNOWN, correct the remaining partial stubs, and fail closed in Sentinel ESG when required providers are absent.

**Broad duplicate consolidation is not yet ready.** The architecture still needs an approved decision for the five exact module-identity groups and the overlapping safety/consensus/intervention authorities. Each decision must identify the canonical owner, adapter boundary, data/persistence contract, tests, migration and rollback plan. Do not bulk-delete duplicate directories.

**Current disposition:** 29/29 directory families reclassified at source/path level; same-module conflicts and cross-authority overlaps identified; 7 new findings RL-541–RL-547; full runtime proof and whole-repository stub-like scan remain open. No production code changed.
