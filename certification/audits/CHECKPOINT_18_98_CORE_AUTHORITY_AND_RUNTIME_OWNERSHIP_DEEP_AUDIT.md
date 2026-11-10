# Checkpoint 18.98 — Core Authority and Runtime Ownership Deep Audit

**Disposition:** OPEN — static ownership analysis completed for Core, CIS, CTL, OCM, OED, Sentinel, and selected OS lifecycle/accounting paths. Deployment topology and runtime behavior remain unverified.

**Source baseline:** `b829254d032f9e0b5cf4c44725c8cf451800dad0`  
**Repository:** `Kimiti4/Tiannara`  
**Audit branch:** `audit/consolidated-findings-r0a-2026-10-31`  
**Method:** Read-only source inspection and repository search. No production code, tests, builds, or runtime processes were changed or executed.

## 1. Executive determination

The source tree does not establish one unified authority graph across the root Mix application and `tiannara_runtime`. They define distinct application entry points and supervisor trees, and several module identities overlap across the project boundaries. Both projects define `Tiannara.OED.Supervisor` and `Tiannara.Sentinel.Supervisor`; their child sets and restart strategies differ. The root and runtime CIS supervisors are not the same module identity.

This is not proof that all definitions are loaded into one BEAM at once. Separate Mix projects/releases can isolate them. The actual release/build composition and deployment topology are missing. Until those are supplied, these are project-level duplicate authority definitions, not confirmed runtime module collisions.

Highest-impact confirmed source defects:
- runtime CIS execution silently treats a missing CIS safety process as `:normal`; its emergency shutdown cast is a no-op;
- CTL's production-looking branch registry is an empty supervisor with mock APIs, while the consumer resolves to a separate stub returning zero stress;
- Sentinel's shadow-graph approval score uses stubbed empty causal data/fixed latent state and placeholder simulation mathematics;
- OED is described in WiringEngine but omitted from the actual `subsystem_specs/0` list, and neither inspected application root starts OED directly;
- lifecycle and generation-history facades return successful results without proving durable event/history writes.

## 2. Authority and startup map

| Area | Root application | Runtime application | Audit status |
|---|---|---|---|
| Core | `Tiannara.Application` starts `Tiannara.Core.Supervisor` | `TiannaraRuntime.RootSupervisor` starts infrastructure, execution, ecology, constraint and meta layers; execution requires `Tiannara.OPC.CoreSupervisor` | Separate authority trees; canonical cross-tree ownership UNKNOWN |
| CIS | `Tiannara.CIS.Supervisor` is a direct root child | `TiannaraRuntime.CIS.Supervisor` is not a child of inspected runtime startup layers | Root implementation resident; runtime CIS process unconnected |
| CTL | Stub `Tiannara.Ctl.CausalRegistry` is consumed by `Tiannara.Ctl.BranchValidator`; alternate `Tiannara.CTL.CausalRegistry` exists | No runtime CTL owner established | Active stub + mock candidate |
| OCM | `Tiannara.Stabilization.Supervisor` starts `Tiannara.Stabilization.OCM.Supervisor` | Runtime Ecology optionally starts `TiannaraRuntime.OCM.Supervisor` | Two distinct consensus implementations |
| OED | Root `Tiannara.OED.Supervisor` definition exists; not a direct root child | Runtime project defines same module identity differently; not a RootSupervisor child | Duplicate module identity across projects; startup unproven |
| Sentinel | Root `Tiannara.Sentinel.Supervisor` is a direct root child | Runtime project defines another `Tiannara.Sentinel.Supervisor` with different children | Duplicate module identity across projects |
| OS | Root Stage-6 runner calls global `GenerationHistory` and `TiannaraOS.ScientificCapitalLedger` | No runtime OS authority for these calls established | Facades and candidate kernel implementations diverge |

### Core

`lib/tiannara/core/supervisor.ex` owns only `Tiannara.Core.Ontology.Cache` and `Tiannara.Core.Ontology.Index`. It does not, by itself, establish ownership of the full foundational ontology, causality, or constitutional state. The root application starts it directly. Runtime Execution instead calls `required_child(Tiannara.OPC.CoreSupervisor)`; runtime Infrastructure and Ecology are separately started beneath `TiannaraRuntime.RootSupervisor`.

Runtime boot policy uses `Code.ensure_loaded?/1` to decide whether a child is available. That proves a module can be loaded, not that it is the canonical authority, has healthy dependencies, or owns the relevant state. Runtime OPC Core is not interchangeable with root `Tiannara.Core.Supervisor` on the evidence inspected.

**Finding:** two application-level startup roots and different Core contracts; release composition determining whether they coexist or are alternatives is absent from this static evidence.

### CIS

Root `Tiannara.CIS.Supervisor` starts `CISRegistry`, `CollapsePredictor`, `ImmuneDecisionEngine`, and `RegulationExecutor`. It is included in `Tiannara.Application.core_children/0`. The predictor has an UNKNOWN path for missing required telemetry fields, but `gather_live_telemetry/0` supplies `memory_pressure: 0.0` and `dets_health: true` as constants after obtaining three service health readings. Those two dimensions are not live measurements in this path. `RegulationExecutor.execute/2` logs an action and stores it in process memory; it is not evidence of an externally enforced action.

The runtime project instead defines `TiannaraRuntime.CIS.Supervisor` as a GenServer containing only `safety_mode: :normal`. The runtime `ExecutionController` checks whether that process exists; if absent it substitutes `:normal`, then authorizes execution. The inspected runtime RootSupervisor layers do not start this CIS process. `execute_emergency_shutdown/1` sends a cast whose handler returns the state unchanged. The method reports `:initiated` without implementing shutdown in the inspected module.

**Finding:** root CIS and runtime CIS are distinct authority designs; runtime safety-mode enforcement is not fail-closed and emergency shutdown is a no-op in the inspected implementation.

### CTL

`lib/tiannara/ctl/branch_validator.ex` aliases `Tiannara.Ctl.CausalRegistry`. That exact module identity is supplied by `lib/tiannara/stubs/causal_registry.ex`, whose `get_branch/1` returns `{:ok, %{stress: 0.0}}` as its default. Branch validation therefore receives synthetic zero-stress records. The stub's ordinary result shape does not communicate UNKNOWN.

A second file, `lib/tiannara/ctl/causal_registry.ex`, defines `Tiannara.CTL.CausalRegistry` (uppercase CTL). It is a supervisor with no children; `register_branch/2` returns `:ok` without storing anything, and `get_active_branches/0` returns the mock constant 10,000. It does not implement the `get_branch/1` contract used by BranchValidator. These are different Elixir module identities.

**Finding:** the apparent non-stub registry is not a drop-in replacement. No branch state owner, durable lineage store, or compatible production implementation is evidenced.

### OCM

Root `Tiannara.Stabilization.OCM.Supervisor` starts the root OCM process, ConsensusManager, VotingSystem, ReconciliationEngine, and ConflictResolver under `:one_for_all`. Runtime `TiannaraRuntime.OCM.Supervisor` starts `TiannaraRuntime.OCM.Registry` and `TiannaraRuntime.OCM.ConsensusEngine` under `:one_for_one`; it is an optional child of runtime Ecology.

These are separate namespaces, different child contracts, and different restart semantics. The inspected sources do not establish whether the runtime engine is an adapter to root consensus, a replacement, or a separate authority. Nor do they establish a shared authoritative ontology store or conflict arbitration protocol.

**Finding:** duplicate functional authority with unresolved ownership and reconciliation boundary. Do not consolidate or route writes between them until state contracts and deployment topology are mapped.

### OED and Sentinel

Both projects define `Tiannara.OED.Supervisor` under the same module name. The root implementation uses `:one_for_one`; the runtime implementation uses `:one_for_all`. Their child sets are similar but not identical, including how BudgetController receives options. If both source trees are compiled into one release, module resolution/build composition must be tested; separate project releases may isolate them.

The root WiringEngine defines a private `oed_spec/0`, but `subsystem_specs/0` returns only REA, P9X, CIS, A10, UCC, MSG, OMCE and SOPL. OED is omitted from the list that `wire_all/0` registers. The root application does not list OED as a direct child. Runtime RootSupervisor also does not include OED. The task `mix phase_omega_scan` explicitly starts the app and calls `Activator.bootstrap/0`, but the ordinary application boot path inspected does not call that task. A declared spec alone is not proof of production activation.

Both projects also define `Tiannara.Sentinel.Supervisor` with different child sets and strategies. Root Sentinel is a broad one-for-all tree and is directly started by the root app. Runtime Sentinel is a separate one-for-one tree and is not part of the inspected runtime RootSupervisor layers. This is another duplicate module identity across project boundaries, not proof of simultaneous loading.

**Finding:** OED activation is not established by either inspected application root; WiringEngine currently excludes its own OED spec. Sentinel has unresolved project-level implementation ownership.

### Sentinel shadow graph

`Tiannara.Sentinel.EpistemicShadowGraph.validate_intervention/3` returns `:approved` when its calculated score crosses 0.85. The inspected implementation:
- reads a fixed latent vector from the `Tiannara.Meta.Epistemics.LongitudinalMemory` stub;
- reads an empty `%{nodes: [], edges: []}` snapshot from the `Tiannara.Meta.CausalDataLayer.Traversal` stub;
- leaves the proposed cure unchanged in `apply_intervention_to_latent_state/2`;
- returns fixed divergence 0.1 in `calculate_ontological_divergence/2`;
- does not require a real causal projection to be available before deciding.

With the stub vector and empty graph, the result can be deterministic without evaluating the actual intervention against a grounded causal model. The fallback path also uses a fixed latent vector / empty graph when modules are not loaded. The approval score is not a proof of safety in this implementation.

**Finding:** shadow-graph approval is placeholder/synthetic evidence and must not authorize a live immune intervention. Unavailable data should produce UNKNOWN / abstain.

### OS lifecycle and scientific capital

The Stage-6 runner calls `TiannaraOS.ScientificCapitalLedger.calculate_delta/2`, which resolves to a stub returning `{:ok, 0}`; the runner treats the result as a numeric delta. A substantive candidate exists at `TiannaraOS.Kernel.ScientificCapitalLedger`, but it is a different module identity and is not what the runner calls in the inspected path. The candidate implements policy-weighted delta calculation and replay/audit functions, but this does not prove it is wired into Stage 6.

The global `GenerationHistory` facade is also a stub. `append_to_file/2` returns `:ok` without writing, while `calculate_cai/1` returns fixed `0.0`. A substantive `TiannaraOS.Kernel.GenerationHistory` candidate exists, but the Stage-6 runner calls the global facade. The runner can report a successful CSV append without a persisted record.

`TiannaraOS.LifecycleRegistry.track_entity/4` returns `{:ok, :tracked}` without maintaining lifecycle state. `TiannaraOS.PrincipleRegistry` invokes this facade for create/evidence/validation events and rescues errors, so principle records can update in the GenServer while their lifecycle trail is not actually persisted or independently queryable.

**Finding:** OS accounting and lifecycle calls have successful-looking facade contracts that do not establish persistence. Kernel candidates require explicit caller rewiring, compatible contracts, and storage/replay verification before being treated as production authorities.

## 3. New finding register

| ID | Severity | Finding | Status |
|---|---|---|---|
| RL-507 | HIGH | Root and runtime startup trees do not establish a single Core authority or verified release composition | UNKNOWN |
| RL-508 | CRITICAL | Runtime ExecutionController defaults to `:normal` when runtime CIS safety process is absent | ACTIVE_FAIL_OPEN |
| RL-509 | CRITICAL | Runtime CIS emergency shutdown handler is a no-op while API returns `:initiated` | ACTIVE_STUB |
| RL-510 | HIGH | Root CIS telemetry path hardcodes memory pressure and DETS health | PARTIAL_IMPLEMENTATION |
| RL-511 | CRITICAL | CTL BranchValidator consumes stubbed zero-stress branch records | ACTIVE_STUB |
| RL-512 | HIGH | Alternate CTL registry is empty/mock and does not satisfy BranchValidator API | ACTIVE_STUB |
| RL-513 | HIGH | Root and runtime OCM supervisors own separate consensus trees without evidenced shared authority | DUPLICATE_AUTHORITY |
| RL-514 | CRITICAL | OED supervisor is omitted from WiringEngine subsystem_specs and neither inspected app root starts it directly | UNCONNECTED |
| RL-515 | HIGH | Root/runtime OED definitions reuse same module identity with different child/restart behavior | DUPLICATE_AUTHORITY |
| RL-516 | HIGH | Root/runtime Sentinel definitions reuse same module identity with different child trees | DUPLICATE_AUTHORITY |
| RL-517 | CRITICAL | Sentinel ESG can approve using fixed latent state, empty causal graph and placeholder simulation metrics | ACTIVE_STUB |
| RL-518 | CRITICAL | Stage-6 scientific capital and history facades report success/default values without performing claimed accounting/persistence | ACTIVE_STUB |
| RL-519 | HIGH | PrincipleRegistry lifecycle calls are acknowledged by a non-persistent LifecycleRegistry stub | ACTIVE_STUB |

## 4. Test and evidence boundary

Repository search found probe/test artifacts for CIS residency and risk behavior, runtime CIS execution, chronogram integration, and ESG handshake behavior. Their existence is not evidence that they pass on this baseline. No tests, probes, Mix tasks, builds, or releases were executed for this checkpoint.

Static source establishes implementation and call relationships only. It does not establish:
- which Mix project(s) are included in each deployable release;
- whether root and runtime source directories are compiled into the same BEAM;
- whether optional children are present in deployed configurations;
- whether storage paths, process restarts, or recovery work under failure;
- whether external effects are enforced by a downstream authority.

## 5. Required next verification

1. Produce a release/build matrix: Mix project, source roots, application modules, dependency graph, release name, and deployment artifact for each supported deployment.
2. Verify whether duplicate `Tiannara.OED.Supervisor` and `Tiannara.Sentinel.Supervisor` definitions can coexist in any release; add a deterministic build-time collision gate.
3. Define the canonical CIS safety authority for each deployment and prove missing authority fails closed; implement and verify emergency-stop effect at the actual execution boundary.
4. Replace CTL's stub and mock registry with one state-owning implementation whose API includes branch lookup, lineage, stress provenance, persistence, and UNKNOWN behavior.
5. Establish OCM's canonical write authority and explicit adapter/replication/conflict semantics.
6. Add OED to the real activation specification or make its omission an explicit disabled state; verify actual boot ancestry and health probes.
7. Make ESG reject/return UNKNOWN when causal graph, latent state, projection, or intervention semantics are synthetic/unavailable. Replace placeholder intervention and divergence functions with independently verifiable model execution.
8. Route Stage-6 calls through intended kernel ledger/history implementations and verify append-only persistence, replay, crash recovery, and numeric contract compatibility.
9. Replace LifecycleRegistry's success stub with an auditable durable event store, or make the API return UNKNOWN/unavailable until one exists.

## 6. Final disposition

**OPEN — 13 new findings (RL-507–RL-519); static source ownership and consumer paths inspected; runtime topology, deployment composition, and test execution NOT VERIFIED.**

No production code was changed. This checkpoint adds an audit report only.
