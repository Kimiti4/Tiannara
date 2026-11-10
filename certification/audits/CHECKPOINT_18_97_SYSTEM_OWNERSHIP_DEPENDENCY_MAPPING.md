# Checkpoint 18.97 — System Ownership and Dependency Mapping

**Repository:** `Kimiti4/Tiannara`  
**Audited source ref:** `b829254d032f9e0b5cf4c44725c8cf451800dad0` (`main`)  
**Audit branch:** `audit/consolidated-findings-r0a-2026-10-31`  
**Method:** Static GitHub source inspection, module-definition search, consumer search, and startup-graph tracing  
**Code changes:** None  
**Builds/tests/runtime execution:** Not performed

## 1. Objective and classification rules

This checkpoint expands the ownership audit from the five integrations in 18.96 to the complete 29-name duplicate-directory inventory supplied in the audit specification, and expands the explicit stub audit to all 12 `use Tiannara.Stub` modules found by code search.

The audit separates four questions:

1. **Implementation identity:** Which module and source file implement the capability?
2. **Execution ownership:** Which OTP application and supervisor start it?
3. **Consumer binding:** Which production callers invoke that exact module identity?
4. **Evidence ownership:** Does the consumer receive real state/evidence, or a default, mock, empty result, or synthetic value?

A matching directory name is only a search lead. A matching module identity in separate Mix projects is a much stronger conflict. A supervisor declaration is not proof that its parent supervisor is itself started. A successful return value is not proof that the intended work occurred.

Classification values are used conservatively:
- `CANONICAL_PRODUCTION`: one authoritative implementation with verified startup, consumers, persistence and independent tests.
- `PRODUCTION_CANDIDATE`: substantive implementation exists, but one or more operational proofs remain.
- `ACTIVE_STUB`: a consumer resolves to placeholder behavior.
- `PARTIAL_IMPLEMENTATION`: only part of the capability is substantive.
- `LEGACY_IMPLEMENTATION`: retained implementation whose current production role is not established.
- `DUPLICATE_AUTHORITY`: overlapping implementations or same module identity exist without a proven authority boundary.
- `UNCONNECTED`: source exists but no active startup/consumer path was established.
- `UNKNOWN`: insufficient source evidence to classify safely.

## 2. Confirmed inventory baseline

The source specification records the following current-main baseline:
- 27,948 repository tree entries
- 495 directories across the three audited roots
- 97 repeated directory names (including generic names such as `supervisor`, `validation`, and `runtime`)
- 29 repeated top-level system directory names

The 97 repeated names are not 97 duplicated production systems. This checkpoint preserves that distinction.

## 3. Complete 29-name ownership register — initial status

The locations below reproduce the source inventory. A status of `UNKNOWN` means the directory duplication is reported but the module/API/startup equivalence has not yet been proven. It must not be interpreted as a clean bill of health.

| System | Reported locations | Checkpoint 18.97 classification | Evidence / next proof required |
|---|---|---|---|
| A10 | Root / Runtime | `DUPLICATE_AUTHORITY` | Same `Tiannara.A10.Supervisor` module identity appears in both Mix projects; separate child implementations and restart strategies; actual wiring invocation and deployment topology remain unverified |
| ALES | Root / Runtime namespace | `UNKNOWN` | Compare module identities, APIs, state ownership, startup and callers |
| ACM | Root / Runtime OED | `UNKNOWN` | Establish whether ACM is the same capability or distinct OED crucible components |
| CIS | Four locations | `DUPLICATE_AUTHORITY` | Root `Tiannara.CIS.Supervisor` is a child of root application; runtime `TiannaraRuntime.CIS.Supervisor` is a different, simpler safety-mode GenServer and is absent from current runtime RootSupervisor child graph |
| CTL | Root / Runtime namespace | `UNKNOWN` | Separate CTL, causal registry, validation and execution contracts before choosing authority |
| DFG | Three locations | `UNKNOWN` | Compare module definitions, graph state and supervisor ancestry |
| EUF | Root / Runtime namespace | `UNKNOWN` | Compare module identities, APIs, state ownership, startup and callers |
| IRD | Three locations | `UNKNOWN` | Root Physics supervisor starts root IRD; runtime Constraint supervisor optionally starts runtime IRD. Determine whether they are distinct authority layers or overlapping control authority |
| MSG | Root / Runtime namespace | `UNKNOWN` | Trace meta-stability decisions, policy authority and startup |
| NDE | Root / Physics | `UNKNOWN` | Root Physics supervisor starts root NDE; runtime NDE is research-profile experimental. Verify whether separate engines have explicit boundaries |
| OAVL | Root / Runtime OED | `UNKNOWN` | Inspect validation contract, evidence trust and OED ownership |
| OCM | Root / Stabilization / Runtime namespace | `DUPLICATE_AUTHORITY` | Root stabilization starts `Tiannara.Stabilization.OCM.Supervisor`; runtime Ecology optionally starts `TiannaraRuntime.OCM.Supervisor`. Similar purpose, distinct contracts and storage |
| OED | Three locations | `DUPLICATE_AUTHORITY` | Root and runtime projects each define `Tiannara.OED.Supervisor`; current startup invocation of PhaseΩ wiring remains unproven |
| OMCE | Root / Runtime namespace | `UNKNOWN` | Compare continuity/memory contracts and whether runtime implementation delegates to root |
| OMCS | Root / Runtime namespace | `UNKNOWN` | Establish whether memory continuity and consensus services share authority or are separate |
| OS | Root / Runtime namespace | `UNKNOWN` | Map kernel, persistence, and authority boundary; do not infer equivalence from OS name |
| REA | Root / Runtime Phase 16 | `UNKNOWN` | Compare theory-selection/research pipelines, experiment execution and persistence |
| SOPL | Root / Sentinel | `UNKNOWN` | Establish whether the two paths implement the same law/policy authority |
| TWP | Root / Physics | `UNKNOWN` | Root Physics starts root TWP; runtime research profile can start runtime TWP. Verify distinct model and control boundaries |
| UCC | Root / Runtime Phase 17 | `UNKNOWN` | Map compiler authority, contracts and actual execution consumers |
| Omega | Root / Runtime namespace | `UNKNOWN` | Separate phase/boot coordinator from runtime subsystem; trace who has final activation authority |
| Meta | Root / Runtime namespace | `UNKNOWN` | Establish knowledge, meta-governance and runtime state ownership |
| Meta-science | Root ASC / Root | `UNKNOWN` | Determine whether ASC MetaScienceEngine and root meta-science modules duplicate or compose |
| Interface | Root ASC / Root | `UNKNOWN` | Compare protocol/interface generation and runtime ingress ownership |
| Engineering | Three locations | `UNKNOWN` | Map ASC engineering executor, root engineering services and runtime engineering boundary |
| Core | Four locations | `UNKNOWN` | High-risk authority overlap; trace canonical state, execution and constitutional decision owner |
| Sentinel | Root / Runtime namespace | `UNKNOWN` | Distinguish root sentinel governance/monitoring from runtime telemetry and safety services |
| Telemetry | Three locations | `UNKNOWN` | Map event sources, metric stores, transport and authoritative observability |
| Topology | Root / Runtime namespace | `UNKNOWN` | Compare topological model, graph persistence and compiler/runtime consumers |

**Register status:** 4 systems have a meaningful first-pass classification; 25 remain `UNKNOWN`. This is an explicit partial result, not completion of all 29.

## 4. Exact module identity conflicts and startup findings

### CP18.97-F01 — A10 is duplicated under the same BEAM module identity across two Mix projects

**Classification:** `DUPLICATE_AUTHORITY`  
**Priority:** High

Evidence:
- Root project `mix.exs` defines application `:tiannara`, compiling root `lib/` and starting `Tiannara.Application`.
- Runtime project `tiannara_runtime/mix.exs` defines separate application `:tiannara_runtime`, compiling its own `lib/` and starting `TiannaraRuntime.Application`.
- Both `lib/tiannara/a10/supervisor.ex` and `tiannara_runtime/lib/tiannara/a10/supervisor.ex` define the exact module `Tiannara.A10.Supervisor`.
- Both supervisors name the same five children, but root source defines its own child implementations in the root file, while runtime source contains runtime child modules in its separate source tree.
- Root supervisor uses `:one_for_one`; runtime supervisor uses `:rest_for_one`.
- Root application `core_children/0` does not directly list A10. The root PhaseΩ WiringEngine defines an A10 subsystem specification, but the inspected root application registration list does not itself prove that `Tiannara.PhaseOmega.Activator` runs in the target release.
- A runtime legacy supervisor file references `Tiannara.A10.Supervisor`, but the current `TiannaraRuntime.RootSupervisor` startup graph is constructed from Infrastructure, Execution, Ecology, Constraint and Meta supervisors; the legacy file is not itself proof of active startup.

**Conclusion:** A10 has two competing source authorities with the same module identity and different supervisor semantics. Do not merge or delete either copy until the release topology and exact active code path are established.

### CP18.97-F02 — CIS has two different control APIs and only the root supervisor is in the current declared root startup tree

**Classification:** `DUPLICATE_AUTHORITY`  
**Priority:** Critical

Evidence:
- Root `lib/tiannara/application.ex` includes `Tiannara.CIS.Supervisor` in `core_children/0`.
- Root `Tiannara.CIS.Supervisor` starts a CIS registry, collapse predictor, immune decision engine and regulation executor.
- The root collapse predictor explicitly returns `:unknown` for missing or invalid telemetry rather than manufacturing a risk score.
- Runtime `tiannara_runtime/lib/tiannara_runtime/cis/supervisor.ex` defines `TiannaraRuntime.CIS.Supervisor`, a separate GenServer holding a mutable `safety_mode` field.
- Current runtime `TiannaraRuntime.RootSupervisor` does not include `TiannaraRuntime.CIS.Supervisor` in its child graph. Runtime execution code references this module, so calls that require the named process may fail if no other startup route starts it.
- The two supervisors are not module-name collisions, but both claim CIS/safety responsibilities and expose materially different APIs.

**Conclusion:** Root CIS residency is declared. Runtime CIS residency is not established by the current runtime root graph. The architecture needs a single documented safety authority and a defined runtime adapter, not two independently authoritative safety supervisors.

### CP18.97-F03 — OCM has two independently started consensus systems with overlapping responsibility

**Classification:** `DUPLICATE_AUTHORITY`  
**Priority:** High

Evidence:
- Root application starts `Tiannara.Stabilization.Supervisor`; that supervisor starts `Tiannara.Stabilization.OCM.Supervisor`.
- Root OCM supervisor starts a main OCM process, consensus manager, voting system, reconciliation engine and conflict resolver.
- Runtime RootSupervisor starts Ecology in stable and research profiles; runtime Ecology optionally starts `TiannaraRuntime.OCM.Supervisor` when the module is loaded.
- Runtime OCM starts `TiannaraRuntime.OCM.Registry` and `TiannaraRuntime.OCM.ConsensusEngine`.
- The implementations use different module namespaces and child contracts. They are not exact module collisions, but both claim ontological consensus and convergence.

**Conclusion:** This may be a legitimate split between semantic governance and runtime drift/merge execution, but that boundary is not encoded by the names alone. Define which system owns ontology truth, who may authorize convergence, and which one is a subordinate executor.

### CP18.97-F04 — OED source is duplicated under the same module identity; PhaseΩ specification is not startup proof

**Classification:** `DUPLICATE_AUTHORITY` / `UNCONNECTED`  
**Priority:** Critical

Evidence:
- Root `lib/tiannara/oed/supervisor.ex` and runtime `tiannara_runtime/lib/tiannara/oed/supervisor.ex` both define `Tiannara.OED.Supervisor`.
- The two child lists are almost identical; root uses `:one_for_one`, runtime uses `:one_for_all`.
- The root PhaseΩ WiringEngine declares an OED specification and health probe.
- The root application's explicit subsystem registration list does not include OED.
- The runtime current RootSupervisor graph does not include OED.
- PhaseΩ WiringEngine exposes `wire_all/0`, called from `Tiannara.PhaseOmega.Activator`; the source inspection has not established that this activator is reached during the normal production boot of the target release.

**Conclusion:** OED is implemented twice but its production activation path remains unproven. CRAV/heatmap/activation-matrix references are declarations or observability metadata, not evidence that OED is running.

## 5. Explicit stub inventory — all 12 modules discovered

Repository search for `use Tiannara.Stub` found 12 module definitions, not merely 10 files in the stubs directory. Ten are under `lib/tiannara/stubs/`; two are embedded elsewhere.

| Stub module | Source | Consumer / observed behavior | Classification |
|---|---|---|---|
| `Tiannara.Ctl.CausalRegistry` | `stubs/causal_registry.ex` | CTL BranchValidator receives a fabricated `{:ok, %{stress: 0.0}}` for any ID | `ACTIVE_STUB` |
| `Tiannara.Meta.CausalDataLayer.Traversal` | `stubs/causal_traversal.ex` | Sentinel EpistemicShadowGraph calls it when loaded; receives empty nodes/edges | `ACTIVE_STUB` |
| `Tiannara.ASC.Crucible.Supervisor` | `stubs/crucible_supervisor.ex` | ASC pipeline treats `{:ok, :stub}` as phase success and advances | `ACTIVE_STUB` |
| `GenerationHistory` | `stubs/generation_history.ex` | Stage-6 append reports `:ok` without file writing; CAI returns fixed `0.0` | `ACTIVE_STUB` |
| `Graph` | `stubs/graph.ex` | REL civilization fitness calls `Graph.out_edges/2`; stub returns empty list, forcing zero edge-derived score | `ACTIVE_STUB` |
| `TiannaraOS.LifecycleRegistry` | `stubs/lifecycle_registry.ex` | OS principle registry aliases it; returns `{:ok, :tracked}` without a lifecycle record | `ACTIVE_STUB` |
| `Tiannara.Meta.Epistemics.LongitudinalMemory` | `stubs/longitudinal_memory.ex` | Sentinel EpistemicShadowGraph calls it; receives a fixed latent vector | `ACTIVE_STUB` |
| `TiannaraOS.ScientificCapitalLedger` | `stubs/os_scientific_capital_ledger.ex` | Stage-6 runner receives `{:ok, 0}` and uses it as a number | `ACTIVE_STUB` |
| `Tiannara.Sentinel.PressureMonitor` | `stubs/pressure_monitor.ex` | Telemetry channel only calls it if a process with this name exists; stub defines no process/start_link | `UNCONNECTED` for this guarded consumer |
| `Tiannara.Twp.SurvivabilityEstimator` | `stubs/survivability_estimator.ex` | WavefunctionSolver consumes fixed `0.5` estimate | `ACTIVE_STUB` |
| `Tiannara.ASC.Interface.Protocol` | `asc/interface/protocol.ex` | Protocol data model and several methods are substantive; `hybrid/2` returns a stub-shaped success | `PARTIAL_IMPLEMENTATION` |
| `Tiannara.REA.TheoryNiches` | embedded in `discoveries/theory_selection.ex` | Live theory selection/ecology views import it; classification implementation is a stub | `ACTIVE_STUB` |

### CP18.97-F05 — Stub defaults conceal their placeholder origin

**Classification:** `ACTIVE_STUB` — cross-cutting defect  
**Priority:** Critical

Evidence:
- `lib/tiannara/stubs/stub.ex` only records a call if `Process.whereis(Tiannara.StubRegistry)` returns a PID.
- If the registry is absent, the stub function still returns its configured default.
- For configured defaults such as `{:ok, :tracked}`, `0.5`, `[]`, `%{nodes: [], edges: []}`, or `{:ok, 0}`, the macro returns the ordinary value. The caller is not forced to distinguish stub output from real output.
- The macro documentation says it returns explicit stub markers or configured defaults, but configured defaults are often indistinguishable from legitimate successful results.
- `Tiannara.StubRegistry` itself is not a child in root `core_children/0` or the runtime `StartupSupervisor` child list. No direct `StubRegistry.start_link/1` application call was found.

**Conclusion:** The registry is not a reliable control for detecting stub execution, and the default-return design is fail-open for epistemic provenance. A stub can silently impersonate a valid implementation even when tracking is disabled.

### CP18.97-F06 — Empty causal traversal and fixed memory vectors feed Sentinel as if they were live data

**Classification:** `ACTIVE_STUB`  
**Priority:** Critical

Evidence:
- `lib/tiannara/sentinel/epistemic_shadow_graph.ex` checks `Code.ensure_loaded?/1` for both stub module identities, then invokes their APIs.
- The causal traversal stub returns `%{nodes: [], edges: []}`.
- The longitudinal memory stub returns `%{leoc: [1.0, 0.0, 0.0, 0.0]}`.
- Both modules are loadable because the stub definitions are compiled into the root application. Therefore the caller's module-loaded checks pass and do not distinguish the placeholders.

**Conclusion:** Sentinel can receive empty or fixed epistemic context while treating the providers as present. Availability checks must be capability/evidence checks, not `Code.ensure_loaded?/1`.

### CP18.97-F07 — Lifecycle events can report success without recording lifecycle state

**Classification:** `ACTIVE_STUB`  
**Priority:** High

Evidence:
- `TiannaraOS.LifecycleRegistry` is defined only in the explicit stub path found by exact module search.
- It returns `{:ok, :tracked}` without state, event ID, append-only log, persistence or readback.
- `TiannaraOS.PrincipleRegistry` aliases the module.
- The earlier Phase-16 audit also identifies consumers in research economy, provenance tracker, principle registry, domain registry and institution kernel.

**Conclusion:** Lifecycle/provenance consumers must not treat `:tracked` as durable evidence. No production lifecycle registry has been established in this pass.

### CP18.97-F08 — Graph stub can collapse graph-derived fitness to zero

**Classification:** `ACTIVE_STUB`  
**Priority:** High

Evidence:
- `lib/tiannara/rel/civilization_fitness.ex` reads the OMCS engine's graph and invokes `Graph.out_edges(graph, civ_id)`.
- The global `Graph` module in `lib/tiannara/stubs/graph.ex` returns `[]` for every call.
- The caller derives fitness from the returned edge count.

**Conclusion:** The global graph stub can silently force a legitimate graph-derived fitness term to zero. The module identity is global and should be checked for dependency/module shadowing across the project.

### CP18.97-F09 — Survivability and theory niche classification are synthetic outputs

**Classification:** `ACTIVE_STUB`  
**Priority:** High

Evidence:
- `Tiannara.Twp.WavefunctionSolver` invokes `Tiannara.Twp.SurvivabilityEstimator.estimate/1`; the stub returns fixed `0.5`.
- `Tiannara.REA.TheoryNiches` is defined in the same source file as substantive theory selection and imported by two LiveView modules.
- The presence of substantive neighboring modules does not make the niche classifier substantive.

**Conclusion:** These outputs must be marked `UNKNOWN` or `UNAVAILABLE` until a validated estimator and classifier replace the fixed defaults.

## 6. New cross-cutting audit findings

| ID | Finding | Priority |
|---|---|---|
| RL-497 | Stub macro returns ordinary configured defaults, so stub outputs are not distinguishable from production results | Critical |
| RL-498 | StubRegistry has no established application startup path; stub call telemetry is conditional and can be absent | High |
| RL-499 | A10 and OED define identical module identities in two separate Mix projects with differing supervisor semantics | Critical |
| RL-500 | Runtime CIS supervisor is absent from current runtime RootSupervisor graph while runtime consumers reference it | Critical |
| RL-501 | Root and runtime OCM start overlapping consensus authorities without an explicit authority boundary | High |
| RL-502 | Sentinel accepts compiled empty causal graph and fixed longitudinal memory vector as provider outputs | Critical |
| RL-503 | LifecycleRegistry success result is not backed by a production state store or persistence evidence | High |
| RL-504 | Graph.out_edges stub can silently zero REL graph-derived fitness | High |
| RL-505 | TWP survivability and REA theory niche consumers receive fixed/default outputs | High |
| RL-506 | OED/A10 PhaseΩ declarations and CRAV inventory references are being conflated with verified runtime residency | Critical |

Previous findings RL-493 through RL-496 remain open. This checkpoint adds evidence and precision; it does not close them.

## 7. Required canonical architecture decisions

1. **One authority per responsibility:** choose one authoritative owner for safety decisions, ontology consensus, lifecycle history, scientific capital, graph state and causal branch records. Other systems may be adapters, observers or specialized executors.
2. **Separate simulation from reality:** simulated engines may coexist with real execution engines only when type boundaries, evidence labels and APIs prevent simulation output from being accepted as runtime evidence.
3. **Fail closed on stubs:** stubs must return a typed `{:error, :not_implemented}` or explicit `{:unknown, :stubbed, ...}`; never return a valid business success by default.
4. **Make stub tracking mandatory:** registry startup must be a required supervised child in any release containing stubs, and tracking failure must not silently disable observability.
5. **Do not equate loaded with operational:** replace module-loaded checks with capability contracts, process health, freshness, provenance and readback checks.
6. **Prove startup ancestry:** every claimed active subsystem must have a traceable path from an OTP application entry point through its parent supervisors.
7. **Preserve separate applications:** root and runtime Mix projects remain separate until deployment topology is explicitly documented. Do not merge their modules into one BEAM code path without resolving same-name module collisions.
8. **No bulk deletion:** no duplicate, legacy or stub file should be deleted until callers, tests, runtime owners, migration plan and rollback path are documented.

## 8. Remaining work for 18.97

This checkpoint has not completed the entire 29-system deep audit. The next work is to:
- Resolve the 25 `UNKNOWN` rows using module-definition and consumer searches.
- Enumerate exact source paths and module identities for every occurrence.
- Trace each candidate from root/runtime application startup through its full supervisor ancestry.
- Inspect storage and recovery contracts for stateful systems.
- Search test suites for direct calls, fake-only fixtures, and integration tests that start the actual application.
- Compare safety and governance authority before considering any consolidation.

## 9. Evidence limits and disposition

- Static inspection only. No compile, test, boot, process inspection or production runtime trace was executed.
- Source claims are tied to `b829254d032f9e0b5cf4c44725c8cf451800dad0`.
- The separate Mix project definitions establish separate build roots; they do not establish whether both releases are deployed together or on distinct nodes.
- Startup graph findings establish declared ancestry only. Runtime residency remains unproven until boot-level tests or deployment traces are supplied.
- The directory inventory is copied from the supplied audit specification; 25 entries remain unverified at the module/API/startup level.

**Checkpoint disposition:** `OPEN — 4/29 SYSTEMS CLASSIFIED; 12 STUB MODULES IDENTIFIED; STATIC STARTUP AND CONSUMER FINDINGS RECORDED; RUNTIME VERIFICATION PENDING`.

No production code was changed.
