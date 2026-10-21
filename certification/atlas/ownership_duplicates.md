# Register 4 — Canonical Ownership & Duplication (Phase R0)

**Date:** 2026-10-20 · **Branch:** `local/pr4` @ `521cb7fe` · **Mode:** read-only.
Machine-readable table: `ownership_duplicates.csv` (28 concepts).
Method: static defmodule/class inventory of both Elixir trees + Python packages,
cross-referenced with boot trees, reuse of the Phase 5F audits, GenServer
ownership inventories, and directory audit. Every claim carries `path:line` or a
named prior-audit reference. `decision_option` in the CSV is a *recommendation*
only — R0 decides nothing.

Reused evidence (not rediscovered): `PHASE_5F_WIRING_AUDIT.md`,
`PHASE_5F_STATUS_CORRECTION.md` (C-01..C-14), `GENSERVER_OWNERSHIP_INVENTORY.*`,
`GENSERVER_RECONCILIATION.*` (35 zero-evidence modules), `DIRECTORY_AUDIT_2026-10-19.md`,
`TIANNARA_RUNTIME_TEST_INVENTORY.md`, `certification/atlas/baseline.md`.

---

## 1. Top duplicate clusters

### 1.1 Dual Elixir projects — 28 identical fully-qualified modules (CONFIRMED, highest structural risk)

Root Mix project (`mix.exs`, app `:tiannara`, 1,971 modules in `lib/`) and
`tiannara_runtime/` (`mix.exs`, app `:tiannara_runtime`, 1,375 modules in its
`lib/`) each define **28 identical `defmodule` names**, including whole
subsystem supervisors:

| Duplicate module | Root definition | Runtime definition |
|---|---|---|
| `Tiannara.CIS.Supervisor` (+CollapsePredictor/ImmuneDecisionEngine/RegulationExecutor) | `lib/tiannara/cis/supervisor.ex:1` (4 modules packed in one file) | `tiannara_runtime/lib/tiannara/supervisors.ex:114` + 3 separate files under `tiannara_runtime/lib/tiannara/cis/` |
| `Tiannara.OED.Supervisor` (+10 OED modules) | `lib/tiannara/oed/supervisor.ex` (packed) | `tiannara_runtime/lib/tiannara/oed/*.ex` (33 files) |
| `Tiannara.Sentinel.Supervisor`, `Sentinel.AnomalyDetector`, `Sentinel.TelemetryHub` | `lib/tiannara/sentinel/*` (65 files) | `tiannara_runtime/lib/tiannara/sentinel/*` (89 files) |
| `Tiannara.A10.Supervisor` (+5 A10 modules) | `lib/tiannara/a10/supervisor.ex` (packed) | `tiannara_runtime/lib/tiannara/a10/*.ex` |
| `Tiannara.P9XEcosystem.Supervisor`, `Tiannara.P9X.Supervisor` | `lib/tiannara/p9x_ecosystem/supervisor.ex` | `tiannara_runtime/lib/tiannara/supervisors.ex:127,164` |
| `Tiannara.Meta.CausalTensegrityEngine` | `lib/tiannara/meta/causal_tensegrity_engine.ex` | `tiannara_runtime/lib/tiannara_runtime/meta/causal_tensegrity_engine.ex` |
| `Tiannara.Core.Ontology.Index` | `lib/tiannara/core/ontology/index.ex` | `tiannara_runtime/lib/tiannara/core/ontology/index.ex` |
| `CivilizationState` (bare name!) | `lib/tiannara/cci/models.ex` | `tiannara_runtime/lib/tiannara_runtime/civilization/kernel.ex` |

Full list captured during R0 (28 names) — pattern: **root packs multiple
modules into `*supervisor.ex` files; runtime split them into per-module files**
under a copied `lib/tiannara/` subtree (254 files share the `Tiannara.*`
namespace inside the runtime project).

**Which is canonical?** UNKNOWN. These are two separate OTP applications that
never share a code path today (`_build/` at root contains only `tiannara` +
`forward_provenance`; runtime builds into `tiannara_runtime/_build`). The hazard
is latent, not active: any future co-deployment, umbrella merge, or
`Code.append_path` mixing makes one definition silently shadow the other, and
neither project's tests can catch it. Some runtime copies are *newer* (runtime
OED tree is 33 files vs root's packed file; runtime sentinel is larger), so
"root is canonical by age" is false.

**Recommendation (CSV):** undecided at concept level — needs an explicit
operator decision of which OTP app owns the immune/observatory/sentinel
namespaces. Individual sub-decisions (e.g., KillSwitch → merge) below are
stronger.

### 1.2 KillSwitch triplication (reuse C-11; CONFIRMED)

Three world-kill implementations coexist in `tiannara_runtime`:

- `TiannaraRuntime.MultiWorld.KillSwitch` — `multi_world/kill_switch.ex:1`, 205 LOC (the "unified" one per C-11)
- `TiannaraRuntime.MultiWorld.HardenedKillSwitch` — `hardened_kill_switch.ex:1`, 270 LOC
- `Tiannara.MultiWorld.KillSwitchCausal` — `kill_switch_causal.ex:1`, 170 LOC — **wrong root namespace** (`Tiannara.*` inside the runtime tree)

Consumers: `multi_world/world_supervisor.ex:111-144` calls
`KillSwitch.get_killed_worlds/0`/`request_kill/2`/`confirm_kill/2` which **do not
exist** on the unified KillSwitch (dead API, `PHASE_5F_STATUS_CORRECTION.md:188-195`);
`cis/execution_controller.ex` and `cortex/safety_cortex.ex` reference the
MultiWorld kill modules.

**Canonical:** `TiannaraRuntime.MultiWorld.KillSwitch` (strongest: named the
unified target in C-11 and referenced by the safety cortex).
**Recommendation:** **merge** (high confidence) — consolidate Hardened +
Causal features into the unified module, fix the dead world_supervisor API in
the same change, then retire the copies. Deferred historically because
deletions need operator approval.

### 1.3 Event bus proliferation (CONFIRMED)

**Runtime canonical:** `Tiannara.EventBus` (`tiannara_runtime/lib/tiannara/event_bus.ex:1`)
backed by duplicate-key Registry `Tiannara.EventRegistry` (`:9`), boot-wired in
the Infrastructure layer since W3 `9307d6ed` (wiring audit:21). Real publishers:
OLEF PressureSolver, MetaEvolutionStreamManager, OMRL.

**Root project has ≥7 bus modules with no single owner:**
`Tiannara.CEL.Services.EventBus` (211 LOC, actually used by
`control_center.ex`, the four ASC directors, and the CEL Kernel service
registry), `Tiannara.CEL.EventBus` (68 LOC, **zero external references — dead
copy**, GENSERVER_RECONCILIATION.md:50), `Tiannara.ASC.Core.EventBus` (18),
`Tiannara.Executive.EventBus` (79), `Tiannara.Runtime.EventBus` (36),
`Tiannara.CEL.Services.EventBusSafe`, `Tiannara.Crav.EventBusAudit`.
Plus `TiannaraRuntime.Omega.SentinelEventBus` (runtime, omega-local) and the
umbrella `tiannara_observatory` **observation_bus** app.

**Canonical:** `Tiannara.EventBus` for the runtime deployment;
`Tiannara.CEL.Services.EventBus` for the root deployment (only root bus with a
real consumer set). **Recommendation:** `retire` the dead `Tiannara.CEL.EventBus`
(zero-evidence) and `preserve_independent` the two per-project buses until a
cross-project topic contract (UEP?) exists. Concept-level decision: undecided.

### 1.4 Constitutional authority scatter (CONFIRMED)

Four "constitution" modules: `Tiannara.Council.Constitution`
(`lib/tiannara/council/constitution.ex:1`, 146 LOC, `v1` principles — **the
only one with a persistence/commit path**, via `ConstitutionRepository`
DETS `./constitution_repository.dets`, `constitution_repository.ex:8,24-29`),
`Tiannara.ASC.Constitution` (53 LOC), `Tiannara.Civics.Constitution` (10 LOC),
and `TiannaraRuntime.Shared.ConstitutionalLaws` (55 LOC — **zero references
anywhere**, dead). Two modules both named `…ConstitutionalGovernanceEngine`
(`lib/tiannara/asc/civilization/` and `lib/tiannara/cci/`). Two competing
principle registries: `Tiannara.Council.PrincipleRegistry` (used by
`council/rule_engine.ex`) vs `TiannaraOS.PrincipleRegistry` (used by
`eos/executive/value_function.ex`, `os/civilization_atlas.ex`,
`os/institution_self_model.ex`) — **disjoint consumer sets**.

**Canonical (document):** the Council stack (only boot-wired constitution
authority: `lib/tiannara/application.ex:108` Tier 0). Runtime side has no
constitution-document owner at all (its ConstitutionalLaws is dead).
**Recommendation:** undecided at concept level — but retire
`ConstitutionalLaws` (dead) and decide the principle-registry split **together
with** the constitution decision (principles are the constitution's payload).

### 1.5 Knowledge graph, four namespaces (CONFIRMED)

- Root `Tiannara.Graph.*` — `graph/{server,in_memory,postgres,persistent,behaviour,unified_reality_graph,world_model,audit}.ex`; **`Tiannara.Graph.Persistent` is zero-evidence** (reconciliation:61).
- Root `Tiannara.KnowledgeGraph.{Node,Registry}` + `os/governance/rfc_knowledge_graph.ex`.
- Runtime: `autonomous_research/phase16_1/knowledge_graph.ex`, `cognitive/civilization/knowledge_graph_manager.ex`, `mathematics/mathematics_knowledge_graph.ex`, `independent_audit/phase16_95/knowledge_graph_audit.ex`.
- Python: `tiannara_core/autonomy/knowledge_graph.py`, `transfer/knowledge_graph.py`, `memory/knowledge_store.py`, `ecm/graph_engine.py`.

**Canonical: UNKNOWN.** ≥20 graph-related modules across 3 languages.
**Recommendation:** undecided — choosing a canonical requires Register 2
capability mapping; merging by file similarity is exactly the failure mode
Register 4 exists to prevent (R0_SOURCE_PLAN.txt:585).

### 1.6 RRG, four meanings (reuse C-09/C-13 + NEW root finding)

1. `Tiannara.RRG` — Rate-limiting Ontological Graph (`tiannara_runtime/lib/tiannara_runtime/rrg/rrg.ex:1-3`, booted, 15-module dir, many consumers: ccr_bridge, civilization kernel, 5× omce, babel, audit). **Canonical for the name "RRG" (C-13).**
2. `Tiannara.Runtime.RRG.Governor` — Runtime Revelation Governor (`rrg/governor.ex:1`, 51 LOC, unsupervised, only `rrg.ex` + 1 test reference) — note the *third* namespace variant (`Tiannara.Runtime.RRG.*` vs `Tiannara.RRG.*` inside the same directory).
3. **NEW:** `Tiannara.Topology.RRG` — root project (`lib/tiannara/topology/rrg.ex:1` + 5 submodules incl. RateLimiter/ComplianceEnforcer, supervised via `topology/supervisor.ex`, booted by root `application.ex:178` Topology.Supervisor). A distinct rate-limiting system that **also** uses the acronym.
4. "Recursive Reality Governor" — retired documentation name (C-13).

**Recommendation:** `keep_canonical` runtime `Tiannara.RRG` for the acronym;
`preserve_independent` root `Tiannara.Topology.RRG` (different system, different
project); rename both eventually to end the collision.

### 1.7 Observatory, three implementations (CONFIRMED)

Root `Tiannara.Observatory` (8 modules; ValidationSupervisor + LiveProjection
boot-wired, `application.ex:148-149`) vs runtime `TiannaraRuntime.OS.Observatory`
(4 modules + Phoenix `tiannara_runtime_web/observatory_controller.ex`) vs the
`tiannara_observatory` umbrella (10 apps, Postgres, **zero CI**, committed dev
secrets, dev auth bypass that grants administrator,
`DIRECTORY_AUDIT:210-215`). Consumer:
`tiannara_api/routes/observatory.py:38` → HTTP `:4000` **with simulation
fallback on failure** (fabricated data on outage).

**Canonical: UNKNOWN.** Recommendation: undecided; first gate the umbrella dev
auth bypass and remove the API simulation fallback (those are security/honesty
fixes independent of the ownership decision).

### 1.8 Executive state split (CONFIRMED)

Root: DETS-backed "Executive Memory" + `Tiannara.Executive.Supervisor` +
`ExecutiveCognitiveRuntime` (`application.ex:220-230`) with
`Tiannara.CEL.Services.ExecutiveStateManager` registered in the CEL Kernel
service registry (`service_registry.ex:351-355`). Runtime:
`TiannaraRuntime.Omega.ExecutiveMemory` (StartupSupervisor stage). Dead
neighbors: `Tiannara.Executive.Cognitive.{AttentionScheduler,ContextManager,
HeartbeatEngine,WorkingMemory}` — all four **zero-evidence**
(reconciliation:54-58). **Canonical: UNKNOWN** (two legitimate per-project
owners + 4 dead modules). Recommendation: undecided; retire the four
zero-evidence modules after Register 2 confirms no dynamic callers.

### 1.9 Safety-chain module namespace contamination (CONFIRMED, NEW detail)

The real kill-authorization chain is `TiannaraRuntime.CIS.Supervisor`
(`tiannara_runtime/lib/tiannara_runtime/cis/supervisor.ex:79 authorize_kill/3`,
boot-wired W1). But the runtime project *also* compiles `Tiannara.CIS.Supervisor`
as an Ecology-layer wrapper (`lib/tiannara/supervisors.ex:114`) starting the
immune trio `Tiannara.CIS.{CollapsePredictor,ImmuneDecisionEngine,
RegulationExecutor}` — **the same fully-qualified names the root project
defines** in `lib/tiannara/cis/supervisor.ex`. Two different systems, same
module names, two OTP apps, plus a third `TiannaraRuntime.Legacy.CIS.Supervisor`.
Anyone reasoning about "CIS" must currently ask *which CIS, in which project*.

---

## 2. Unused / orphaned modules

### 2.1 The 35 confirmed zero-evidence GenServers (reuse `GENSERVER_RECONCILIATION.md:43-81`)

Full list in the reconciliation document. Notable entries feeding Register 4:
`Tiannara.CEL.EventBus` (dead bus copy), `Tiannara.CEL.{Metrics,MissionDirector,
Planner}`, `Tiannara.Certification.Protocol`, the four
`Tiannara.Executive.Cognitive.*`, `Tiannara.Graph.Persistent`,
`TiannaraOS.ConstitutionalWatchdog`, `TiannaraOS.{LawRegistry,ProgramRegistry,
TheoryRegistry,DiscoveryRegistry,ProvenanceTracker}`, five
`TiannaraOS.Governance.*` (incl. `RFCRegistry`, `ProposalLedger`,
`DeploymentOrchestrator`), `Tiannara.World.{ConflictResolver,
WorldConsistencyValidator}`, `Tiannara.Sentinel.ObservationScheduler` (with a
module-name-vs-filename drift warning, reconciliation:83). Caveats in that
document (heuristic alias verification, runtime-only entry points) still apply —
these are *candidates*, not proven-dead.

### 2.2 Wiring-audit orphans (reuse `PHASE_5F_WIRING_AUDIT.md`)

- `Tiannara.Meta.Supervisor` (`meta/supervisor.ex`) — orphan; W2 wired through `TiannaraRuntime.Meta.Supervisor` instead (wiring audit:50).
- `TiannaraRuntime.Interface.Supervisor` — starts `children = []` (`supervisors.ex:180` per dir audit:251-252).
- `Tiannara.P9XEcosystem.Supervisor` (runtime copy) — still unwired, zero-referenced as a start target (wiring audit:43, W3 note).
- 5F.9 RODL supervisor/Choice-A AOE and all of 5F.10 external scope — **absent modules** (wiring audit §2, C-06/C-07).
- Babel `encrypt_causal_payload/4` — zero production callers (wiring audit:48, C-08).
- 5 CRA GenServers (~265 LOC) — run only in tests (wiring audit:80).
- Runtime Revelation Governor (`rrg/governor.ex`) — unsupervised (wiring audit:47).

Note on the "23 orphaned modules" figure: it is cited in
`certification/atlas/baseline.md:68,81` and `capabilities_F_platform.md:33`
against the wiring audit, but the current wiring-audit text does not enumerate a
list of 23. **Register 4 records the discrepancy** — the concrete orphan lists
are (a) the 35 zero-evidence GenServers, (b) §2.2 above, and (c) the new items
in §2.3. No list of exactly 23 was located (unknown).

### 2.3 New orphan/namespace findings from R0

- `tiannara_runtime/lib/tiarnara/` — **misspelled root namespace** `Tiarnara.Phase18.RRM.*` (7 modules: AdaptationController, EquivalenceVerifier, FallbackRouter, MetaIRGenerator, Metrics, NativeBridge, RuleEvolution). k8s KEDA target `tiarnara-rrm` shares the typo (dir audit:288).
- `TiannaraRuntime.Shared.ConstitutionalLaws` — zero references.
- `Tiannara.CEL.EventBus` — zero external references (self only).
- `rust_core/ffi_bindings` (Rust cdylib, untracked) — `{:rustler, "~> 0.36.0"}` is declared (`tiannara_runtime/mix.exs:67`) but **no `use Rustler`/`crate:` wiring exists**; the six `native_bridge.ex` modules call `:erlang.load_nif` against `Application.app_dir(:tiannara_phase14, ...)` — an OTP app (`:tiannara_phase14`) that **does not exist as a project** in this checkout (`phase14/reg/native_bridge.ex:23`). Rust substrate = unlinkable as-is.
- Root `lib/tiannara/observatory` vs root `Tiannara.Telemetry` vs runtime layer `Tiannara.Telemetry.Supervisor` (`lib/tiannara/supervisors.ex:153` in runtime) — telemetry namespace also split across projects with partial name overlap.

---

## 3. Typo-dir inventory

| Path | Contents | Modules | Status |
|---|---|---|---|
| `tiannara_runtime/lib/tiarnara/` | 7 `.ex` files, Phase 18 RRM | `Tiarnara.Phase18.RRM.{AdaptationController,EquivalenceVerifier,FallbackRouter,MetaIRGenerator,Metrics,NativeBridge,RuleEvolution}` | Tracked; compiled into `:tiannara_runtime` under a misspelled root namespace. Rename = destructive, needs approval (dir audit P3). |

Related typo surfaces: k8s KEDA ScaledObject target `tiarnara-rrm`
(`tiannara_runtime/k8s`, dir audit:288); `Tiannara.MultiWorld.KillSwitchCausal`
uses root namespace inside the runtime tree (namespace typo, §1.2).

---

## 4. Flattened-path directories (path-concatenation garbage at repo root)

Three **empty** directories + one empty file produced by a known
path-join bug (documented as an ignore list in
`certification/reconnaissance/collectors/_common.py:47-50`):

| Entry | Type | Files | Git-tracked |
|---|---|---|---|
| `cUsersuserTiannaraTiannara-MindCache-Prosthetictiannara_coremetacognition` | dir | 0 | yes (empty dir not tracked by git — untracked on disk) |
| `cUsersuserTiannaraTiannara-MindCache-Prosthetictiannara_corereasoning` | dir | 0 | same |
| `cUsersuserTiannaraTiannara-SaaS` | dir | 0 | same |
| `cUsersuserTiannaraTiannara-MindCache-Prosthetictiannara_corereasoning__init__.py` | file | 0 bytes | on disk |

Plus sibling garbage from the same era: `-p/` directory,
`tmp_6A0FF061…CFDE/` (4 files). All are excluded from the recon scanner by
policy. Recommendation: delete after R4 confirmation (destructive; needs
approval). They are inert (0 files) — no capability depends on them.

---

## 5. Root-vs-runtime dual project overlap summary

| Dimension | Root `:tiannara` | `:tiannara_runtime` | Overlap verdict |
|---|---|---|---|
| Modules | 1,971 `defmodule`s in `lib/` (1,655 `.ex`) | 1,375 in `lib/` | **28 identical fully-qualified names** (§1.1) |
| Shared path dep | `forward_provenance` (`mix.exs:67`) | `forward_provenance` (`mix.exs:32`) | genuine shared library — the only one |
| Cross-references | 4 files probe `TiannaraRuntime.*` process names (`crav/runtime_atlas.ex:582`, `crav/runtime_census.ex:246`, `phase_omega/runtime_auditor.ex:252`, `phase_omega/runtime_discoverer.ex:151`) — all defensively guarded (`Code.ensure_loaded?`/`Process.whereis`) | none found back toward root | hidden coupling (F-ARC-013): implies co-VM expectation that no deployment actually provides |
| Boot | `Tiannara.Application` (core+loop+asc, `application.ex:15-27`) | `TiannaraRuntime.Application` → StartupSupervisor → RootSupervisor layers | two independent supervision roots; **co-deployment relationship undocumented (UNKNOWN)** |
| CI | required `Elixir CI` suite (387 tests) + required `tiannara-runtime-suite` job | same workflows | only branch-spanning gate on `local/pr4` |
| Persistence | DETS (council audit, constitution, executive memory, cel_memory) | JSON journal (CPL), Mnesia, ETS, Omega snapshots | no shared store, no ownership map |
| Web | `tiannara_web` (Phoenix, in-tree) | `tiannara_runtime_web` (Phoenix :8004) | separate surfaces, no shared router |
| Namespace | `Tiannara.*`, `TiannaraOS.*` | `TiannaraRuntime.*` **plus a copied `Tiannara.*` subtree (254 files)** and a misspelled `Tiarnara.*` (7 files) | the copied `Tiannara.*` subtree is the root cause of the 28 duplicates |

**Working hypothesis (HYPOTHESIS, not confirmed):** the runtime's
`lib/tiannara/` subtree began as a copy of root modules to allow the runtime
project to boot independently, and has since diverged (different file packing,
different sizes). Any unification program must first *name the owner* of the
`Tiannara.*` namespace per subsystem before moving files.
