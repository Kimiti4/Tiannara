# TCP-001 — Master Completion Assessment

**Scope:** every subsystem in the repository, mapped against the eight
cognitive capabilities.
**Method:** repository-grounded. Every count and classification below is derived
from the code as it exists at `local/pr4` @ `60933859`, not from names,
docstrings or design documents.
**Date:** 2026-11-12
**Status:** self-attested. No independent verifier was available.

---

## 1. Repository topology — five parallel stacks

Tiannara is not one system. It is five stacks that were grown independently and
that overlap in responsibility. This is the single most important structural
fact in this assessment.

| # | Stack | Root | Size | Language | OTP app |
|---|-------|------|------|----------|---------|
| **S1** | Core application | `lib/` | 1 656 `.ex` files, **1 972 modules**, 410 top-level namespaces | Elixir | `:tiannara` |
| **S2** | Runtime | `tiannara_runtime/lib/` | 1 239 `.ex` files, **1 376 modules**, 192 top-level namespaces | Elixir | `:tiannara_runtime` |
| **S3** | Cognitive core | `tiannara_core/` | 450 `.py` files across 70+ packages | Python | — |
| **S4** | API | `tiannara_api/` | 122 `.py` files | Python | — |
| **S5** | Observatory | `tiannara_observatory/` | umbrella of 10 apps + 1 out-of-umbrella UI: 965 `.ex`, 157 `.exs`, 101 `.tsx` | Elixir/Phoenix/LiveView + Next.js | `:observatory_api` |
| **S5b** | Cognitive interface companion | `tiannara_pros/`, `tiannara_gui/`, `tiannara_mobile/`, `tiannara_saas/`, `tiannara-desktop/`, `tiannara_internal_dashboard/` | 38 `.py` (pros) + UI stacks | Python + UI | — |

`observatory_ui` is **not** in the umbrella's `apps:` list, so the only real
control-centre front end is not part of the umbrella build and runs as a
separate process. `observatory_api` — the app that *is* in the umbrella —
contains **0 LiveViews and 0 `.heex` templates**; all 27 LiveViews in the
repository live in `lib/tiannara/web/live/` and use inline `~H` (there is not a
single `.heex` file anywhere in `lib/`).

### 1.0 Two boot paths, and two disconnected mega-clusters

**Two boot paths.** The OTP tree in `lib/tiannara/application.ex` starts 61
children. A **second, non-OTP boot path** exists in
`lib/tiannara/control_center.ex`, which starts 32 modules directly via
`module.start_link([])`. Several capability modules are reachable only through
the control centre, not through the supervision tree — so "is it live?" cannot
be answered by reading `application.ex` alone.

**Two disconnected mega-clusters.** These are not small:

| Cluster | Location | Modules | External references |
|---------|----------|---------|---------------------|
| `TiannaraRuntime.Cognitive.*` | `tiannara_runtime/lib/tiannara_runtime/cognitive/` | **161** | none outside the cluster |
| `TiannaraRuntime.WorldModel.*` | `tiannara_runtime/lib/tiannara_runtime/world_model/` | **175** | none outside the cluster |

Together **336 of the runtime's 1 376 modules (24 %)** have no supervision-tree
entry and no caller outside their own directory. They are not stubbed — they
contain real, substantial implementations (counterfactual engines, digital
twins, prediction and uncertainty engines, causal discovery, model pipelines,
autonomous research engines). They are simply **never started**.

A third, smaller orphan cluster: `lib/tiannara/forecasting/` (**51 modules**)
has **no caller outside its own directory**. It contains the repository's
best-calibrated reasoning — Brier score, log loss, a calibration-error
metric, hindsight isolation (`Outcome.guard!/2` →
`{:error, :hindsight_contamination}` when `observed_at < forecast.created_at`),
evidence-bound outcome resolution, and an 8-status counterfactual ontology
(`:observed | :hypothetical | :counterfactual | :supported | :weakly_supported |
:underdetermined | :invalid | :unknown`) — **and the entire forecast →
outcome → calibration → model-update chain never fires.**

### 1.0.1 The honest-stub pattern is real and should be credited

Roughly 40 modules across both stacks return explicit refusals rather than
fabrications:

```
{:error, {:unavailable, :real_step_provider_not_wired}}
{:error, :simulation_unavailable}
{:error, :physics_substrate_unavailable}
{:error, :phase_unavailable}
```

`lib/tiannara/cel/workflow/steps/experiment.ex` even documents it in its own
metadata: *"(real executor not wired)"*. `Tiannara.Forecasting` refuses to
fabricate a uniform base rate (`{:unknown, :base_rate_outcome_mismatch}`).
This is **fail-closed honesty**, and it is the opposite of the fabricated-data
defects fixed in §5.5. These modules are honest and non-functional; the
programme must make them functional, not make them lie.

### 1.1 Measured duplication between the two Elixir stacks

**28 module names are defined in both S1 and S2.** Same namespace, same name,
two implementations that can and do diverge:

| Namespace | Shared modules | Nature |
|-----------|----------------|--------|
| `Tiannara.Sentinel` | `AnomalyDetector`, `Supervisor`, `TelemetryHub` | Environmental awareness |
| `Tiannara.OED` | `Supervisor`, `BudgetController`, `OAVL.ValidationSupervisor`, `Quarantine.*` (3), `Rollback.*` (2), `ACM.CrucibleSupervisor`, `UMSC.StabilityController` | Self-correction / ontology |
| `Tiannara.A10` | `Supervisor`, `AdvisoryEmitter`, `AttractorAnalyzer`, `AttractorMemory`, `DriftTensor`, `Sampler` | Cognitive attractor dynamics |
| `Tiannara.CIS` | `Supervisor`, `CollapsePredictor`, `ImmuneDecisionEngine`, `RegulationExecutor` | Collapse regulation |
| `Tiannara.P9X` | `Supervisor` (under two different names: `Tiannara.P9X.Supervisor` and `Tiannara.P9XEcosystem.Supervisor`) | Ecosystem |
| `Tiannara.Core.Ontology.Index` | 1 | Ontology |
| `Tiannara.Meta.CausalTensegrityEngine` | 1 | Causality |
| `CivilizationState` | 1 | Unnamespaced — collides with anything else using that name |

### 1.2 The `Tiannara.Sentinel` fork

The environmental-awareness subsystem exists in both stacks, **forked rather
than shared**:

| | S1 (`lib/`) | S2 (`tiannara_runtime/lib/`) |
|---|---|---|
| `Tiannara.Sentinel.*` modules | 82 | 89 |
| Identical module names | 3 | 3 |
| Unique to that stack | 79 | 86 |

Two divergent implementations of one subsystem, under one namespace, in two OTP
applications that cannot be composed. **Status: `DUPLICATED`.** This is
capability C6's primary blocker.

### 1.3 The `Tiannara.OED` fork

`Tiannara.OED` has 12 modules in S1 and 33 in S2, with 9 shared names. In S1
these are packed into a single `lib/tiannara/oed/supervisor.ex` file that
defines 9+ modules; in S2 they are one module per file. The two stacks use
different file layout conventions for the same namespace.

### 1.4 Measured hollow-module population

A **hollow module** is one whose `@moduledoc` claims a capability (>100
characters) while its public API is at most one function.

| Stack | Hollow modules | Share |
|-------|----------------|-------|
| S1 (`lib/`) | **280** of 1 656 files | 17 % |
| S2 (`tiannara_runtime/lib/`) | **192** of 1 239 files | 15 % |

Of these, 14 are *empty GenServer shells* — `use GenServer`, `init/1` returning
`{:ok, %{}}`, and nothing else:

- S2: 10 in `tiannara_runtime/lib/tiannara/sentinel/` — `baseline/anomaly_thresholds.ex`,
  `baseline/baseline_builder.ex`, `baseline/trend_memory.ex`,
  `monitors/causal_monitor.ex`, `monitors/collapse_monitor.ex`,
  `monitors/ecological_monitor.ex`, `monitors/emergence_monitor.ex`,
  `monitors/pressure_monitor.ex` (and one more). Their docstrings claim, for
  example, *"Dynamically calculates the standard deviation or adaptive
  boundaries for what constitutes an anomaly, based on baseline learnings"* —
  the body is empty.
- S1: 4 in `lib/tiannara/stabilization/{hsv,ocm}/`.

This is the single largest source of false confidence in the codebase: a
reader — or a capability scan driven by docstrings — sees a capability
described and concludes it exists.

---

## 2. Capability assessment

Status vocabulary is defined in the Programme Charter §7.

### C1 — Cognitive core

**Status: `PARTIAL` / `DUPLICATED`**

| Implementation | Location | Modules |
|---|---|---|
| `Tiannara.ASC.*` (Adaptive/Autonomous Self-*) | S1 `lib/tiannara/asc/` | 287 (Crucible 42, Civilization 27, Reality 24, Interface 18, Research 17, Engineering 14, CMissions 12, Laws 10, Core 9, Implementation 7, Executive 6, Immunity 6, ProjectWorld 6, Repair 5, Evolution 5) |
| `Tiannara.REA.*` (Research/Epistemic Architecture) | S1 `lib/tiannara/rea/` | 120 (Epistemic 24, OrbitMemory 14, Causal 13, Topo 5, OrbitGenesis 3) |
| `Tiannara.Domains.*` | S1 `lib/tiannara/domains/` | 31, over the **canonical 20-domain ontology** in `canonical_registry.ex` — all 20 domains present and bound |
| `Tiannara.CEL.*` (Constitutional Execution Layer) | S1 `lib/tiannara/cel/` | 50 |
| `Tiannara.Forecasting.*` | S1 | 57 |
| `Tiannara.Discovery.*` | S1 | 56 |
| `TiannaraRuntime.Cognitive.*` | S2 `tiannara_runtime/lib/tiannara_runtime/cognitive/` | 161 (Engines 23, Planning 21, Decision 20, Reflection 20, Metacognition 18, Behaviours 17, Civilization 15, Runtime 12) |
| `TiannaraRuntime.OS.*` | S2 | 93 |
| `TiannaraRuntime.WorldModel.*` | S2 | 150 |
| Python cognition | S3 `tiannara_core/{cognition,cognitive_domains,reasoning,metacognition,prediction,causal,coherence}` | ~15 packages |

**Assessment.** The 20-domain ontology is authoritative and complete, which is
the strongest single result in this assessment. But the *reasoning architecture*
that should connect those domains exists in three incompatible forms: the
Elixir ASC/REA stack in S1, the `TiannaraRuntime.Cognitive` stack in S2, and a
parallel Python stack in S3. None of them is demonstrated to traverse multiple
domains end-to-end. The Phase II exit condition — *"end-to-end investigations
traverse multiple domains coherently"* — has **no test** in the repository.

**Refinement (deep scan).** `TiannaraRuntime.Cognitive.*` — all 161 modules —
is **disconnected**: it has no supervisor, and no module in it is referenced
from outside the cluster. `lib/tiannara/cognition.ex` is an 8-line stub. In
Python the strongest reasoning is `tiannara_core/metacognition/` (18 files,
including `uncertainty_planning.py` at 26 KB and `epistemic_resilience.py` at
116 KB), but `tiannara_core/reasoning/unified_reasoner.py` is placeholder-grade
(*"# Python code generation placeholder"*).

**Missing:** a single cross-domain traversal test; a statement of which stack
owns reasoning; supervision for the 161-module cognitive cluster.

### C2 — Autonomous research

**Status: `PARTIAL` / `DUPLICATED`**

| Implementation | Location | Modules |
|---|---|---|
| `TiannaraRuntime.WorldModel.AutonomousResearch.*` | S2 | 32 |
| `TiannaraRuntime.AutonomousResearch.*` | S2 `tiannara_runtime/lib/tiannara_runtime/autonomous_research/` | 26 |
| `TiannaraRuntime.CausalDiscovery.*` | S2 | 25 |
| `Tiannara.ASC.Research.*` | S1 | 17 |
| `Tiannara.REA.Epistemic.*` | S1 | 24 |
| `Tiannara.Research.*` | S1 | 16 |
| `Tiannara.Discovery.*` | S1 | 56 |
| Python research | S3 `tiannara_core/{research,discovery,knowledge_gap?}` | — |

**Assessment.** Research machinery is abundant and spread across four Elixir
namespaces plus Python. But the machinery is fragmented along the exact axis
the capability needs: `QuestionGenerator` (S2), evidence retrieval (S2 REA),
`ResearchMathVerification` (S2), `ResearchArchaeology` (S2), research programs
and planners (S1), and the Python `research` package all exist independently.
The compilation of these into a *single* research task that produces a
*traceable report* is not demonstrated.

**Evidence of disconnection.** `tiannara_runtime/lib/tiannara_runtime/world_model/autonomous_research/behaviours/`
contributes 5 of the 192 hollow modules — the behaviour layer of autonomous
research is declared and empty. Similarly
`world_model/prediction/behaviours/` (4) and
`world_model/counterfactual/behaviours/` (3): the *behavioural* half of
prediction and counterfactual reasoning are shells.

**Refinement (deep scan).** The research machinery is not merely fragmented —
it is **gated off**. `Tiannara.Research.ResearchDirector.Pipeline` *quarantines
every experiment*, and `Tiannara.CEL.Workflow.Steps.Experiment` and
`.Validation` both return `{:error, {:unavailable, :real_step_provider_not_wired}}`.
**No evidence-acquisition step exists in any stack** — there is no external
source fetching at all, so "find and evaluate evidence" has no implementation.
`Tiannara.Phase16_1.*` (26 modules, deterministic SHA-256 question IDs) is
real but unreachable. On the Python side `tiannara_core/discovery/` (8 files)
works, but `research/explainable_ai.py` and four siblings are auto-generated
stubs, `autonomous_scientist.py` uses five hardcoded topics, and
`tiannara_core/api/research_routes.py` has a **broken import**
(`researches` vs `research`) and is unregistered.

**Missing:** one autonomous research task executed end-to-end with a traceable
report artefact; an evidence-acquisition step.

### C3 — Persistent memory and knowledge

**Status: `PARTIAL` / `DUPLICATED`**

| Implementation | Location | Modules |
|---|---|---|
| `Tiannara.Memory.*` | S1 `lib/tiannara/memory/` | 8 |
| `Tiannara.Graph.*` | S1 | 12 |
| `Tiannara.KnowledgeGraph.*` | S1 | 2 |
| `Tiannara.REA.OrbitMemory.*` | S1 | 14 |
| `TiannaraRuntime.Memory.*` | S2 | **1** |
| `Tiannara.OED.Rollback.OntologySnapshots` | S2 | 1 |
| `mindcache/` (repo root) | S0 | present, not Elixir |
| Python memory | S3 `tiannara_core/memory` | — |

**Assessment.** This is the weakest capability relative to its importance.
Memory is spread across a small S1 namespace (8 modules), a 14-module orbit
memory inside the research stack, **one** module in the runtime's memory
namespace, and a top-level `mindcache/` directory whose integration with the
Elixir memory subsystem is not established. The defining requirement —
*"distinguish established knowledge from hypotheses and obsolete information"* —
has **no single owner**: confidence and provenance are carried separately by
`Tiannara.Discovery`, `Tiannara.CRAV`, `Tiannara.OED.Quarantine.SuspendedTheories`
(S2) and `Tiannara.Meta`.

**Refinement (deep scan).** The *mechanism* for the defining requirement
exists and is well designed — `Tiannara.Memory.Ladder` (9-rung, evidence-gated),
`PromotionPipeline`, `IncidentDistiller`, `CoherenceEngine` — and is
**entirely orphaned: one reference each, their own definition.** Nothing
running marks knowledge as promoted, and nothing retires it:
`KnowledgeEvolutionEngine` implements retirement but has no caller of
`retire_entity/2`. `Tiannara.Memory.Artifact` has a `lineage` field that
nothing populates, and **no memory store in any stack preserves
relationships** (people, agents, entities) — the Python
`autonomy/knowledge_graph.py` that stores relations is itself orphaned.

On the Python side the store is **in-memory only and cleared at the start of
every analysis** (`DiscoveryEngine.analyze/2` calls `self.store.clear()`);
`tiannara_core/memory/store.py` calls **six methods that do not exist** on
`KnowledgeStore`; `hierarchical_memory.py` and
`hierarchical_memory_reconsolidation.py` (54 KB combined) have **zero imports
anywhere in the repository**; `mindcache/orchestrator.py` is a demo script
with a hardcoded three-item `fake_input`. `world_model/subsystem_beliefs.json`
holds four hardcoded subsystem beliefs dated `2026-06-10` that **no code in
any stack reads**.

**Missing:** a knowledge lifecycle with an explicit epistemic-status field and
a single authority for it; relationship preservation; a wired promotion and
retirement path.

### C4 — Simulation and experimentation

**Status: `PARTIAL`**

| Implementation | Location | Modules |
|---|---|---|
| `Tiannara.Physics.*` | S1 | 25 |
| `Tiannara.Simulation.*` | S1 | 12 |
| `TiannaraRuntime.WorldModel.{Prediction,Counterfactual,DigitalTwin,Composition}` | S2 | 22 + 22 + 17 + 18 |
| `TiannaraRuntime.MultiWorld.*` | S2 | 8 |
| `TiannaraRuntime.Civilization.*` | S2 | 60 |
| `TiannaraRuntime.Mathematics.*` | S2 | 54 |
| `Tiannara.Omega.*` | S1 | 51 |
| Python sim | S3 `tiannara_core/sim` | — |

**Assessment.** The *modelling* capability is genuinely strong — prediction,
counterfactual, digital twin, mathematics and multi-world are all materially
implemented, and S1 and S2 do not duplicate each other here. The weak link is
the closed loop: **"compare predictions with observed outcomes"**. There is no
component that takes a prediction, observes the outcome, and updates the
model's confidence.

**Refinement (deep scan).** The loop is missing for a sharper reason than
"nobody wired it up". The pieces are excellent — `Forecasting.Calibration`
(Brier, log loss, calibration error, resolution, sharpness, a `@min_sample 5`
guard that distinguishes `INSUFFICIENT_DATA` from `POOR_CALIBRATION`, and a
*versioned* scoring method so historical scores stay attributable),
`Forecasting.Outcome` (hindsight isolation), `OutcomeResolution`
(evidence-bound, sets `status: :resolved_not_certified` and
`model_update: :requires_independent_review`), `Forecasting.Counterfactual`
(the 8-status ontology) — and **all 51 modules of `lib/tiannara/forecasting/`
have no caller outside their own directory**. The chain never fires.

Furthermore, **19 of the 20 canonical domains have no simulator at all**:
every `lib/tiannara/domains/*.ex` returns `{:ok, []}` from
`generate_hypotheses/1` and `design_experiments/1`, and `Domains.Cognition`
returns `{:error, :simulation_unavailable}`. Only `Domains.Physics` has a real
solver (RK4 ODE via `Calculus.solve_ode/3`, a damped-harmonic-oscillator pilot
experiment, a SHA-256 config provenance hash, and an energy-bounded
`structural_validation/3`). `Tiannara.Physics.IRD` is a **total façade**: all
11 public functions return `{:error, :physics_substrate_unavailable}`.

**Missing:** the prediction→observation→update loop; simulators for 19 of 20
domains; a reachable counterfactual explorer.

### C5 — Multi-domain coordination

**Status: `PARTIAL` / `DUPLICATED`**

| Implementation | Location | Modules |
|---|---|---|
| `Tiannara.CEL.*` | S1 `lib/tiannara/cel/` | 50 |
| `Tiannara.Topology.*` | S1 | 31 |
| `Tiannara.OPC.*` | S2 | 86 |
| `Tiannara.Meta.*` | S2 | 52 |
| `TiannaraRuntime.CCOS.*` | S2 | 9 |
| `Tiannara.OSE.*` | S2 | 13 |
| `TiannaraRuntime.Cognitive.Behaviours` | S2 | 17 |
| Python orchestration | S3 `tiannara_core/{orchestration,orchestrators,collaboration,coordination?}` | — |

**Assessment.** CEL is the constitutional coordination layer and is substantial
in S1; OPC (86 modules) and Meta (52) are its counterparts in S2, with a
different vocabulary. The capability requirement — *"challenge one another,
share evidence"* — implies an adversarial/arbitration mechanism between
specialists. `Tiannara.ASC.Crucible` (42 modules) and `Tiannara.OED.ACM` are
the candidates; `TiannaraRuntime.Cognitive.Engines` (23) is the third.

**Missing:** a single arbitration path with a named set of participants, and a
test that two specialists with conflicting conclusions reach a reconciled one.

### C6 — Environmental awareness

**Status: `DUPLICATED` / `PARTIAL` — highest-priority blocker**

| Implementation | Location | Modules |
|---|---|---|
| `Tiannara.Sentinel.*` | S1 | 82 |
| `Tiannara.Sentinel.*` | S2 | 89 (forked — see §1.2) |
| `Tiannara.Forecasting.*` | S1 | 57 |
| `Tiannara.External.*` | S1 | **1** |
| `TiannaraRuntime.WorldModel.DigitalTwin.*` | S2 | 17 |
| `tiannara_api/schemas`, `tiannara_api/services` | S4 | — |
| Python data | S3 `tiannara_core/data` | — |

**Assessment.** Sentinel is the environmental-awareness subsystem and it is
forked: 82 modules in one stack, 89 in the other, 3 names in common. The
monitoring layer of the S2 copy is empty (8 hollow modules in
`sentinel/monitors/` and `sentinel/baseline/`). S1 has only **one**
`Tiannara.External` module, so "connect to approved information sources,
instruments, datasets" is barely present in the stack that owns the
domain. The `observed / inferred / simulated / unknown` distinction has no
single owner; it appears as an ad-hoc concern in OED's uncertainty models,
Omega's verification, and the DigitalTwin.

**Missing:** (a) one Sentinel; (b) a first-class epistemic-status taxonomy for
environmental state; (c) an approved-source registry.

### C7 — Cognitive interface

**Status: `PARTIAL` / `DUPLICATED`**

| Implementation | Location | Modules |
|---|---|---|
| `Tiannara.Observatory.*` | S1 | 20 |
| `Tiannara.Interface.*` | S1 | 10 |
| `Tiannara.ASC.Interface.*` | S1 | 18 |
| Phoenix Observatory | S5 `tiannara_observatory/` | 965 `.ex`, 157 `.exs`, 101 `.tsx` — a separate, far larger application |
| Companions | `tiannara_gui/`, `tiannara_mobile/`, `tiannara_saas/`, `tiannara-desktop/`, `tiannara_internal_dashboard/`, `tiannara_pros/` | 6 further front-ends |

**Assessment.** There are **seven** user-facing surfaces. The Phoenix
Observatory (S5) is by far the largest and most complete, but it is a separate
OTP application with its own supervision tree, and its relationship to the
S1 `Tiannara.Observatory` (20 modules) and `Tiannara.Interface` (10) is not
established. The requirement — *"why it reached a conclusion, and where it
needs human authority"* — requires the interface to render provenance and
authority boundaries; the Council's decision receipts and the machine-grant
provenance chain (CP19.20/21/22) produce exactly that data, and the interface
must consume it.

**Refinement (deep scan).** The fragmentation is worse than "seven surfaces":

- **The real control centre is out of the umbrella.** The Next.js app
  `tiannara_observatory/apps/observatory_ui/` has 55 Room components, a
  CommandPalette and an AlertTicker, but **no `mix.exs`** and is not in the
  umbrella's `apps:` list — it is a separate process with its own lifecycle.
  The umbrella app that *is* built (`observatory_api`) is a **JSON API with no
  UI layer at all** (0 LiveViews, 0 `.heex`).
- **The genuine Elixir cockpit exists in the main app**, not in the
  observatory: 27 LiveViews in `lib/tiannara/web/live/` (inline `~H`), of which
  `MissionControlLive` (21.5 KB) is a real cockpit — DVR, surprise index,
  knowledge-capital balance sheet, transfer, maturity, interventions and
  provenance. `Tiannara.CRAVChallengeController` (22.7 KB, 45+ JSON endpoints)
  is the other serious surface.
- **The runtime's 12 Observatory screens are supervised but unreachable**: the
  controller expects `{:ok, x}` while the GenServer returns bare values, so
  metrics arrive as `{}`, every screen reports `:screen not available`, and
  the timeline is always empty.
- **The sidebar served fabricated constants** — `CPU 23%`, `Events/sec 142`,
  `discoveries: 47`, `Audit Logging entries: 1247`, and fabricated log
  timestamps. This is fixed in §5.5.
- Python `tiannara_core/interpretability/` (7 modules) genuinely explains
  conclusions — and is surfaced by no UI. `tiannara_mobile/` is 6 stub files.

**Missing:** (a) a decision to consolidate on one interface; (b) a rendering
contract for decision provenance and authority requests; (c) the tuple-vs-value
controller contract fix so the runtime screens become reachable.

### C8 — Constitutional self-development

**Status: `PARTIAL` — defects fixed in TCP-001**

| Implementation | Location | Modules |
|---|---|---|
| `Tiannara.CEL.*` | S1 | 50 |
| `Tiannara.SelfImprovement.*` | S1 | 23 |
| `Tiannara.Evolution.*` | S1 | 11 |
| `Tiannara.Meta.*` | S1 | 6 / S2 | 52 |
| `Tiannara.Phase18.RRM.*` (runtime metamorphosis) | S2 `tiannara_runtime/lib/tiannara/phase18/rrm/` | 8 (repaired in TCP-001) |
| `TiannaraRuntime.SelfCompilation.*` | S2 | 9 |
| `TiannaraRuntime.Legacy.*` | S2 | 16 |
| `Tiannara.Phase9/10/11/14/15/16/17/19.*` | S2 | 62, including 9 native boundaries |

**Assessment.** This capability had three concrete defects, all fixed in
TCP-001 (§5). It still lacks the loop's outer stage: *"submit evidence for
review, and implement only properly authorised changes."* The RRM path
proposes and verifies, but the application of an approved proposal is not
routed through the Council/CEL authority that governs the rest of the system.

**Refinement (deep scan).** The chain is severed at its last link, and the
severance is precise:

- `Tiannara.Omega.HumanAugmentationDelivery` — the module that would deliver
  a pending human-authorization request — has **zero callers in `lib/`**. The
  governance gate holds every improvement pending authorization and never
  asks.
- `Tiannara.Omega.GovernedEffectSink` is **test-only**.
- `Tiannara.Phase4.RealExecution` is behind `real_execution_enabled: false`
  and requires a human grant that **nothing can mint**.
- **No producer of `:improvement_proposed` exists.** The event is referenced
  by four modules; none of them emits it.
- `Tiannara.Autonomy.Orchestrator.real_simulation_provider?/0` is hardcoded
  `false`, while `Tiannara.Autonomy.SimulationManager` measures its baselines
  with `latency_p99_us: 500 + :rand.uniform(200)` — a **random number
  presented as a measured baseline**.

What *is* real and strong: `Tiannara.SelfImprovement.{Pipeline, Sandbox,
Harness, RealHarness, Backend.*, DryRun, ProtectedCore}` (15 stages, 5
mandatory gates, an anti-gaming target block, self-attestation rejection),
`Omega.DryRun` (contradiction → research → sandbox → certificate → lineage),
`Phase4.RealExecution` (grant-bound, JSONL ledger, candidate lifecycle),
`Omega.GovernanceGateServer` (*"can NEVER authorize deployment on its own"*),
`Council` (23 modules), `CEL.Kernel`, and — on the Python side —
`tiannara_core/evolution/constitutional_evolution.py` (6 real safety gates, 6
immutable principles, a rollback stack).

**Missing:** the authority hand-off from an approved proposal to its
implementation; a producer for `:improvement_proposed`; a real (non-random)
simulation baseline provider.

---

## 3. Structural findings (independent of capability)

These are measured properties of the repository that block all eight
capabilities.

| ID | Finding | Measurement | Severity |
|----|---------|-------------|----------|
| **F-01** | Two Elixir stacks define the same namespaces with different implementations | 28 shared module names; `Sentinel` 82 vs 89 with 3 in common | Critical |
| **F-02** | Hollow modules with capability-claiming docstrings | 280 (S1) + 192 (S2) = **472** files | Critical |
| **F-03** | Empty GenServer shells in the Sentinel monitoring layer | 10 in S2, 4 in S1 | High |
| **F-04** | Native boundaries cloned across 9 phases, each hardcoding a non-existent OTP application | `Application.app_dir(:tiannara_phase{9,10,11,14,15,16,17,18,19}, …)` — 9 atoms, 0 exist | High |
| **F-05** | A misspelled source root `tiannara_runtime/lib/tiarnara/` holding the sole implementation of 7 modules | 7 files, namespace `Tiarnara.Phase18.RRM.*` | High |
| **F-05b** | The RRM supervisor listed 3 stateless service modules as children | `AdaptationController`, `MetaIRGenerator`, `Metrics` export neither `child_spec/1` nor `start_link/1`, so `Supervisor.init/2` could not build the child specs | High |
| **F-06** | Hardcoded tuning constants in application code | **171** hardcoded threshold/epsilon/alpha-style decimals | Medium |
| **F-07** | Hardcoded endpoints | 18 hardcoded URLs, 3 hardcoded host/port pairs, 14 inline `System.get_env/1` literals | Medium |
| **F-08** | Seven user-facing surfaces with no consolidation decision | S5 + 6 companions | Medium |
| **F-09** | Generated data committed to the repository | `tiannara_runtime/data/` = 26 020 files, ~300 MB; `tiannara_runtime/priv/certification/` = thousands of phase reports | Medium |
| **F-10** | Test-suite location divergence | S1 `test/` vs S2 `tiannara_runtime/test/` vs S3 `tiannara_core/tests/` vs S4 `tiannara_api/tests/` vs S5 `tiannara_observatory/test/` | Medium |
| **F-11** | Top-level document sprawl | 200+ `.md` files at repo root | Low |
| **F-12** | 336 runtime modules in two clusters are never started | `TiannaraRuntime.Cognitive.*` (161) and `TiannaraRuntime.WorldModel.*` (175) — 24 % of the runtime, zero supervision entries, zero external callers | Critical |
| **F-13** | The forecast→outcome→calibration→model-update chain never fires | `lib/tiannara/forecasting/` — 51 modules, zero callers outside their own directory | Critical |
| **F-14** | 19 of the 20 canonical domains have no simulator | every `lib/tiannara/domains/*.ex` returns `{:ok, []}` from `generate_hypotheses/1` and `design_experiments/1`; only `Domains.Physics` has a solver | Critical |
| **F-15** | The memory promotion/retirement mechanism is orphaned | `Memory.Ladder`, `PromotionPipeline`, `IncidentDistiller`, `CoherenceEngine` — 1 reference each (their own definition); no caller of `KnowledgeEvolutionEngine.retire_entity/2` | Critical |
| **F-16** | No experiment can execute | `ResearchDirector.Pipeline` quarantines every experiment; `CEL.Workflow.Steps.Experiment` returns `{:error, {:unavailable, :real_step_provider_not_wired}}`; no evidence-acquisition step exists | Critical |
| **F-17** | Two boot paths | OTP tree `lib/tiannara/application.ex` (61 children) and non-OTP `lib/tiannara/control_center.ex` (32 modules via `module.start_link([])`) | High |
| **F-18** | Fabricated monitoring data served as measurements | `observatory_api` `StatusController`: 11 `section_*` handlers returning hardcoded literals, `resources/2` returning `:rand.uniform()` values, `challenges_run/2` returning random confidences | Critical |
| **F-19** | The self-development chain is severed at delivery | `Omega.HumanAugmentationDelivery` has zero `lib/` callers; `GovernedEffectSink` is test-only; `Phase4.RealExecution` is behind `real_execution_enabled: false`; no `:improvement_proposed` producer exists | Critical |
| **F-20** | A random number is presented as a measured baseline | `Autonomy.SimulationManager` measures `latency_p99_us: 500 + :rand.uniform(200)` while `Autonomy.Orchestrator.real_simulation_provider?/0` is hardcoded `false` | High |
| **F-21** | The designated control-centre app has no UI layer | `observatory_ui` (55 Room components) has no `mix.exs` and is not in the umbrella `apps:` list; `observatory_api` has 0 LiveViews and 0 `.heex` | High |
| **F-22** | The runtime Observatory screens are unreachable | controller expects `{:ok, x}` while the GenServer returns bare values → metrics `{}`, screens `:screen not available`, empty timeline | High |
| **F-23** | Three directories named for capabilities are effectively empty | `world_model/` (no code), `mindcache/` (4 files, demo script with hardcoded `fake_input`), `rust_core/ffi_bindings/src/lib.rs` (5-line `example_function`) | Medium |
| **F-24** | A supervisor child without a child spec | `EventStore.Writer` given to `EventStore.Supervisor` → `ArgumentError: The module EventStore.Writer was given as a child to a supervisor` | High |

---

## 4. Measurable acceptance tests per capability

These are the tests the Phase exit conditions require. Each is written so that
a system which merely *simulates* the appearance of the capability fails it.

### C1 — Cognitive core
- **AT-C1.1** A single investigation traverses ≥3 of the 20 canonical domains
  and emits a trace listing each domain, the evidence it contributed, and the
  conclusion that relied on it.
- **AT-C1.2** The same investigation, replayed from its recorded inputs,
  produces byte-identical domain contributions.
- **AT-C1.3** Every hypothesis in a trace carries an explicit uncertainty value
  and a provenance reference to the evidence that produced it.

### C2 — Autonomous research
- **AT-C2.1** Given a research question, the system produces ≥2 competing
  explanations, each with its supporting and contradicting evidence.
- **AT-C2.2** It identifies at least one knowledge gap it could not close and
  records that gap as a durable artefact.
- **AT-C2.3** The final report links every claim to the specific evidence
  record that supports it, with no unsourced claim.
- **AT-C2.4** Re-running the research task with the same inputs reproduces the
  same report.

### C3 — Persistent memory and knowledge
- **AT-C3.1** A conclusion recorded in one session is retrievable in the next,
  with its provenance and epistemic status intact.
- **AT-C3.2** Knowledge carries exactly one status from
  `{established, hypothesis, obsolete}` and a status change is itself an
  auditable event.
- **AT-C3.3** Superseded knowledge is not returned as current without being
  labelled.

### C4 — Simulation and experimentation
- **AT-C4.1** A simulation produces a prediction that is later compared against
  an observed outcome.
- **AT-C4.2** The comparison updates the model's confidence in a recorded,
  replayable way.
- **AT-C4.3** A counterfactual run reports which conclusion it changed and by
  how much.

### C5 — Multi-domain coordination
- **AT-C5.1** Two specialists producing conflicting conclusions are arbitrated
  by a named process, and the arbitration outcome is recorded.
- **AT-C5.2** Evidence shared by one specialist is usable by another with
  provenance preserved.
- **AT-C5.3** A coordinated investigation fails visibly when one participant's
  contribution is missing.

### C6 — Environmental awareness
- **AT-C6.1** Every environmental datum in a decision trace carries one of
  `{observed, inferred, simulated, unknown}`.
- **AT-C6.2** A simulated datum is never presented as observed in any output.
- **AT-C6.3** Exactly one Sentinel implementation exists and it is the one
  running.

### C7 — Cognitive interface
- **AT-C7.1** For any conclusion, the interface shows the evidence chain, the
  confidence, and the authority that approved it.
- **AT-C7.2** The interface shows every point at which human authority is
  required, and the request is actionable.
- **AT-C7.3** The interface reads from the same store the reasoning layer
  writes to — no parallel data path.

### C8 — Constitutional self-development
- **AT-C8.1** A proposed self-change is tested in isolation and its test
  evidence is attached to the proposal.
- **AT-C8.2** A self-change is applied only with a valid authority record; an
  unauthorised proposal is refused with a typed reason.
- **AT-C8.3** The equivalence gate refuses a proposal that changes observable
  behaviour while accepting one that does not.

---

## 5. TCP-001 remediation performed (outcome A + B)

All changes below are in the working tree of `local/pr4` and are covered by
executable tests.

### 5.1 F-05 — the misspelled source root (repaired)

`tiannara_runtime/lib/tiarnara/phase18/rrm/` held the **only** implementation of
seven modules, under the misspelled namespace `Tiarnara.Phase18.RRM.*`. The
correctly-named supervisor `Tiannara.Phase18.RRM.Supervisor`
(`tiannara_runtime/lib/tiannara/phase18/rrm/supervisor.ex`) lists all seven as
children — **none of them existed under the name it referenced**, so the
supervisor could not have started.

The directory was therefore *migrated, not deleted*:

- the 7 files moved to `tiannara_runtime/lib/tiannara/phase18/rrm/`;
- the namespace corrected to `Tiannara.Phase18.RRM.*`;
- the property test renamed `Tiarnara.Simulation.RRMMetamorphosisTest` →
  `Tiannara.Simulation.RRMMetamorphosisTest`;
- `tiannara_runtime/lib/tiarnara/` removed entirely (no residual `Tiarnara`
  module remains anywhere in the repository).

The existing property test passes unchanged in substance: **2 properties, 0
failures**.

### 5.2 F-04 — nine cloned native boundaries (consolidated)

The nine `NativeBridge` modules under `tiannara_runtime/lib/tiannara/phase*/`
were copies of one template, each hardcoding `Application.app_dir(:tiannara_phaseN, …)`
for an OTP application that does not exist, and each calling
`apply(@nif_module, …)` against a NIF module that does not exist — an
`UndefinedFunctionError` at call time.

They now delegate to one implementation, `TiannaraRuntime.NativeBridge`
(`tiannara_runtime/lib/tiannara_runtime/native_bridge.ex`):

- the accelerator inventory lives in configuration
  (`config :tiannara_runtime, :native_accelerators`, 9 entries) and the owner
  application in `config :tiannara_runtime, :native_accelerator_app`;
- paths resolve against the running application via `:code.priv_dir/1`;
- an absent accelerator yields `:not_configured` / `:missing` / `:not_loaded`
  and a **typed error** (`{:error, :nif_not_configured}`,
  `{:error, :nif_unavailable}`) instead of a crash;
- the 9 hardcoded application atoms are gone.

### 5.3 F-05b — the RRM supervisor could not build its child specs (repaired)

`Tiannara.Phase18.RRM.Supervisor` listed seven children, of which three —
`AdaptationController`, `MetaIRGenerator` and `Metrics` — are stateless
service modules exporting neither `child_spec/1` nor `start_link/1`.
`Supervisor.init/2` calls `child_spec/1` on each child, so the supervisor
could not start at all.

The three service modules are now called directly rather than supervised, and
the supervisor supervises only the four processes of the metamorphosis loop
(`RuleEvolution`, `EquivalenceVerifier`, `FallbackRouter`, `NativeBridge`).
`rrm_supervisor_structure_test.exs` pins the invariant so the defect cannot
reappear silently.

### 5.4 C8 — the equivalence gate was a coin flip (repaired)

`Tiannara.Phase18.RRM.EquivalenceVerifier` implemented its check as
`run_with_rules(_rules, _input), do: :rand.uniform()` — it compared **two
random numbers**. Since the maximum of 500 such differences is ~1 and the
tolerance is 1e-5, every verification failed: the gate was not a safety
property, it was a constant rejection decided by chance. It was also **never
called** — `RuleEvolution.handle_call/3` referenced it in an `alias` but
applied only the drift bound.

The verifier now models execution deterministically over the rule set:

- semantic rules (`:accumulator`, `:scale`, `:bias`, `:precision`) change what
  is computed;
- scheduling rules (`:unroll_factor`, `:vectorization`, `:cache_tiling`,
  `:branch_prediction`, `:kernel_layout`) change only how the work is
  scheduled, and must leave the executed value untouched;
- sample vectors are deterministic (no `:rand`), so the verdict is
  reproducible;
- the gate is wired into the proposal path, and a pure
  `RuleEvolution.evaluate_candidate/2` exposes it for testing.

A further defect surfaced while testing: `AdaptationController.compute_drift_delta/2`
subtracted rule values arithmetically, so **any** rule set containing a
non-numeric setting (e.g. `precision: :f32`) raised
`ArithmeticError: bad argument in arithmetic expression: :f32 - :f32` — the
drift check crashed on realistic input. It now compares values by kind.

### 5.5 Test evidence

| Suite | File | Result |
|-------|------|--------|
| Equivalence verifier + gate | `tiannara_runtime/test/simulation/rrm_equivalence_verifier_test.exs` | 11 tests, 0 failures |
| Native bridge | `tiannara_runtime/test/runtime_layers/native_bridge_test.exs` | 8 tests, 0 failures |
| Supervisor structure | `tiannara_runtime/test/simulation/rrm_supervisor_structure_test.exs` | 3 tests, 0 failures |
| Metamorphosis (pre-existing, migrated) | `tiannara_runtime/test/simulation/rrm_metamorphosis_test.exs` | 2 properties, 0 failures |
| Regression | `tiannara_runtime/test/{simulation,runtime_layers,kernel}` | **39 tests, 32 properties, 0 failures** (seed 0) |
| Observatory epistemic status | `tiannara_observatory/apps/observatory_api/test/observatory_api_web/controllers/status_controller_test.exs` | 5 tests — **compiled, not executed** (see below) |

All assertions are exact: no `{:error, _}` or `match?({:error, _})` appears in
the new suites.

**The observatory test is compiled but not executed, and this is stated plainly
rather than claimed as a pass.** The umbrella's `observatory_api` application
fails to start in this environment for two reasons that predate TCP-001: its
PostgreSQL databases do not exist, and `EventStore.Writer` is given to a
supervisor without a `child_spec/1` (F-24). The databases were created and
then dropped again, leaving the environment as found. The test compiles
against the patched controller; executing it requires F-24 to be fixed first.

### 5.5 F-18 — the control-centre API served fabricated data as measurements (repaired)

`tiannara_observatory/apps/observatory_api/lib/observatory_api_web/controllers/status_controller.ex`
(31 KB, ~130 endpoints) served **placeholder constants and randomly generated
numbers as if they were measurements of the running system**:

- **11 `section_*` handlers** returned hardcoded literals — `discoveries: 47`,
  `CPU "23%"`, `Memory "6.2 GB"`, `Events/sec "142"`, `Latency p99 "12ms"`,
  `Audit Logging entries: 1247`, `policies: 12`, `API Response Time avg 8ms`,
  `Event Throughput 142/sec peak 890/sec`, plus fabricated log timestamps
  (`"2026-07-23T10:00:00Z"`, *"System operational"*).
- `resources/2` returned `cpu: 15 + rem(:rand.uniform(30), 20)`,
  `ram: 4.2 + :rand.uniform() * 2`, and so on.
- `challenges_run/2` returned random confidences and execution times.
- `subsystem_status/1` ignored its argument and returned
  `%{status: :operational}` for **every** subsystem, so the health endpoint
  claimed all 17 subsystems were operational without checking any of them.

A consumer could not distinguish a placeholder from an observation. This
directly violates C6's requirement to distinguish observed, inferred,
simulated and unknown state, and AT-C7.1's requirement that the interface show
*why* a conclusion was reached.

**The fix keeps the API's shape and makes it honest:**

- every fabricated payload now carries `epistemic_status: "simulated"`,
  `source: "placeholder"` and an explicit note, at both the payload level and
  on each item;
- `subsystem_status/1` now performs a **real liveness probe** — it checks the
  registered `<Name>.Supervisor` for each umbrella subsystem and the
  `ObservationBus.Supervisor` children for the CIL engines — and reports
  `status: :operational` with the pid, or `status: "unknown"` with
  `detail: "process not registered"`, always marked
  `epistemic_status: "observed"`.

`observatory_api/test/observatory_api_web/controllers/status_controller_test.exs`
pins the invariant: every placeholder section, the resource endpoint, the
experiments endpoint and the challenge run must report `simulated`, and the
health endpoint must report `observed`.

**Environment note.** The observatory umbrella requires six PostgreSQL
databases that did not exist in this environment. They were created, the test
harness was then found to fail on a pre-existing `EventStore.Writer` child-spec
error (F-24), and the databases were dropped again to return the environment to
its prior state. The status-controller test is therefore **compiled but not
executed** — see §5.6.

### 5.6 What TCP-001 did not do

- The `Sentinel` fork (F-01) is **not** resolved. Choosing a canonical stack
  is a decision with architectural consequences and is registered as a
  programme blocker, not taken unilaterally.
- No hollow module was filled in. 472 hollow modules is a programme-scale
  effort, tracked in the register.
- No generated data was deleted; `tiannara_runtime/data/` (26 020 files) is
  cleaned up under a separate, explicit decision because it may hold
  checkpoints with evidentiary value.
- No merge, deployment, registry promotion or physical actuation.

---

## 6. Critical dependencies and implementation order

The order is forced by dependencies, not by convenience.

```
        ┌──────────────────────────────────────────────┐
        │ Phase I  Integrity (RL-565, RL-564, F-ARC-018)│  ← continues in parallel
        └──────────────────────────────────────────────┘
                                   │
        ┌──────────────────────────▼────────────────────┐
        │ W0  Wire what already exists                 │  F-12..F-16
        │     336 disconnected runtime modules          │
        │     51 orphaned forecasting modules           │
        │     orphaned memory ladder + retirement       │
        │     no experiment can execute                 │
        └──────────────────────────┬────────────────────┘
                                   │  (depends on)
        ┌──────────────────────────▼────────────────────┐
        │ W1  Consolidate the two Elixir stacks         │  F-01
        │     one Sentinel, one OED, one A10, one CIS    │
        │     canonical namespace + canonical file layout│
        └──────────────────────────┬────────────────────┘
                                   │  (depends on)
        ┌──────────────────────────▼────────────────────┐
        │ W2  Establish the epistemic-status vocabulary │  C3, C6
        │     observed / inferred / simulated / unknown  │
        │     established / hypothesis / obsolete        │
        └──────────────────────────┬────────────────────┘
                                   │
        ┌──────────────────────────▼────────────────────┐
        │ W3  Connect the 20 domains to one reasoning   │  C1, Phase II
        │     path; AT-C1.1 end-to-end traversal test   │
        └──────────────────────────┬────────────────────┘
                                   │
        ┌──────────────────────────▼────────────────────┐
        │ W4  Autonomous research on the unified path   │  C2, Phase III
        │     traceable report; AT-C2.1..C2.4           │
        └──────────────────────────┬────────────────────┘
                                   │
        ┌──────────────────────────▼────────────────────┐
        │ W5  Prediction → observation → update loop   │  C4
        │     the closed simulation loop                │
        └──────────────────────────┬────────────────────┘
                                   │
        ┌──────────────────────────▼────────────────────┐
        │ W6  Multi-specialist arbitration              │  C5
        │     shared evidence with provenance            │
        └──────────────────────────┬────────────────────┘
                                   │
        ┌──────────────────────────▼────────────────────┐
        │ W7  Self-development authority hand-off       │  C8
        │     proposal → evidence → authority → apply    │
        └──────────────────────────┬────────────────────┘
                                   │
        ┌──────────────────────────▼────────────────────┐
        │ W8  One cognitive interface over the store    │  C7, Phase V
        └──────────────────────────────────────────────┘
```

**Why W0 precedes everything.** 336 runtime modules and 51 forecasting modules
contain real, substantial implementations of exactly the capabilities the
programme intends to build, and none of them is reachable. Building a new
cognitive core on top of that would be the third attempt at C1. **Why W1
precedes the rest.** Every capability is currently measured across two stacks
that can diverge, so consolidating first prevents every subsequent work item
from being implemented twice. **Why W2 precedes W3.** The epistemic-status
vocabulary is what lets research, memory, simulation and awareness agree on
what a datum *is*; retrofitting it later would require rewriting every trace.

---

## 7. Reuse of existing evidence

TCP-001 does not repeat completed audits.

| Existing evidence | Reused as |
|---|---|
| CP19.20/21/22 RL-565 (Council decision provenance, machine authorization, emergency durability/interlock) | The provenance chain that AT-C7.1 and AT-C8.2 depend on. Commits `6523b079`, `a64ec8b3`, `c9080aa3`. RL-565 remains `HIGH / OPEN`. |
| CP19.19 RL-564 / RL-565 red baseline (18 tests, 12 genuine unsafe-success failures) | The regression baseline for the governed surfaces. |
| `certification/audit/GENSERVER_OWNERSHIP_INVENTORY.csv`, `GENSERVER_RECONCILIATION.csv` | Prior ownership work; superseded in part by this assessment's §1.4 hollow-module census, which is strictly broader (hollow modules, not just GenServer ownership). |
| `certification/audit/TIANNARA_CAPABILITY_SCAN.md`, `TIANNARA_RUNTIME_TEST_INVENTORY.md` | Prior capability and test scans; reconciled in §3 (F-02 supersedes their module-count basis). |
| `certification/audits/CP19_19_RL565_REMEDIATION_SPECIFICATION.md` and `CP19_19_RL564_REMEDIATION_SPECIFICATION.md` | The two-root trust model. RL-564 is **not** merged into RL-565 and remains separate. |

**Not reused, because it cannot be:** the audit line's notion of "module
exists" as evidence of capability. This assessment measures hollow modules
explicitly (F-02) precisely because 472 modules would otherwise be counted as
implemented.

---

## 8. Programme status after TCP-001

| Metric | Before TCP-001 | After TCP-001 |
|--------|-----------------|----------------|
| Duplicate native boundary implementations | 9 clones | 1 shared, config-driven |
| Hardcoded non-existent OTP application atoms | 9 | 0 |
| Misnamed source roots | 1 (`lib/tiarnara/`) | 0 |
| RRM modules whose supervisor could resolve them | 0 of 7 | 7 of 7 |
| RRM supervisor children that are startable processes | 4 of 7 | 4 of 4 |
| Equivalence gate | random, never called | deterministic, wired, tested |
| Drift check on realistic rule sets | raised `ArithmeticError` | type-safe |
| Control-centre payloads presented as measurements | 14 endpoints | 0 (all marked `simulated`; health is `observed`) |
| Subsystem health values | hardcoded `:operational` | real liveness probe |
| Capability acceptance tests defined | 0 | 22 (AT-C1.1 … AT-C8.3) |
| Structural findings recorded | 0 | 24 (F-01 … F-24) |
| Registered blockers | 0 | 35 (29 open, 6 resolved) |

**Disposition:** `IMPLEMENTED_WITH_PARTIAL_EVIDENCE` / `VERIFICATION_BLOCKED`.
Self-attested; no independent verifier. RL-565 `HIGH / OPEN`; RL-564 and
`F-ARC-018` `OPEN`.

---

## 9. TCP-002 — W0: Cognitive Capability Activation

TCP-001 established the programme. **TCP-002 began W0**, and its first two
sub-steps are delivered here. Full detail in
`certification/tcp/TCP-002_EXECUTION_SPINE.md`; the machine-readable
classification is `certification/tcp/TCP-002_ACTIVATION_MAP.csv`, generated by
`tools/tcp/tcp002_activation_map.py` (re-runnable, diffable).

### 9.1 TCP-002.1 — the activation map reframed the problem

The assessment above said "336 modules are never started" and classified that
as critical. The map corrected the implied remedy:

| Kind | Modules (before TCP-002.2) |
|---|---|
| `library` | 281 |
| `behaviour` | 37 |
| `behaviour_implementation` | 16 |
| `struct_only` | 2 |
| **processes** | **0** |

**None of the 336 was a process.** They are stateless library functions and
behaviour contracts. Mass supervision would have been categorically wrong —
there was nothing to supervise. The activation mechanism is **composition**:
a governed sequence in which one engine's output becomes the next engine's
input.

The map also splits capability from plumbing, so that reachability can never be
mistaken for capability:

| Role | Modules |
|---|---|
| `engine` — a real operation | 153 |
| `value_object` — constructors and validators | 39 |
| `scaffold` — a struct with nothing else | 107 |
| `behaviour_contract` — needs an implementation (29 have none) | 37 |

### 9.2 TCP-002.2 — the Cognitive Execution Spine

`TiannaraRuntime.Cognitive.Spine.CognitiveExecutionSpine` sequences six
existing stages and two fail-closed gates:

```
context → world_model → hypothesis → forecast → decision → evidence
                                                  ↓        ↓
                                            knowledge  authorize   (gates)
```

It adds **no reasoning of its own**; every stage calls an engine that already
exists. It is hosted by **one** process (`SpineServer`), supervised in
`TiannaraRuntime.Execution.Supervisor` — **1 process for 339 modules** — and
that process owns configuration and lifecycle, not capability.

The two gates are the governance boundary. Authority and knowledge are
injected through ports whose defaults **refuse**, so an unwired Spine can
complete an investigation but cannot retain knowledge or obtain a mandate.

### 9.3 What activation found that inspection had not

Wiring the Spine into live engines surfaced four defects that reading the code
had not, because the code had never run:

| # | Defect | Consequence |
|---|--------|-------------|
| D1 | `CognitiveContext.compute_fingerprint/1` (both copies) piped a struct through `Map.drop/2` then `Enum.sort_by/2`; `Map.drop/2` preserves `:__struct__`, so the result is not `Enumerable` | **Every** call raised. The context type could not be constructed at all. |
| D2 | `ContextBuilder.build_context/3` passed 3 of the 7 fields `CognitiveContext.new/1` reads by dot access | `KeyError` for **every** caller. |
| D3 | `Cognitive.CognitiveContext` and `Cognitive.Runtime.CognitiveContext` are duplicates with different shapes | Two candidate authorities for one concept (`TCP-B-037`). |
| D4 | `CognitiveContext` requires a **string** mission; `GoalDecomposer` requires a **map**. `ConfidenceEstimator` takes evidence **records**; `UncertaintyAnalyzer.aleatoric/1` takes **numbers** | Engines disagree at the seams (`TCP-B-038`). The Spine normalises at the seam rather than forking paths. |

**D1 and D2 are the strongest evidence for the W0 thesis.** Those modules were
not merely unwired — they were *broken*. No amount of counting would have
found that; it took an integration that actually called them.

### 9.4 Evidence

| Suite | Result |
|-------|--------|
| `tiannara_runtime/test/cognitive/spine/cognitive_execution_spine_test.exs` | 16 tests, 0 failures |
| Regression: `test/{simulation,runtime_layers,kernel,cognitive,world_model}` | **784 tests, 32 properties, 0 failures** at seeds **0** and **123456** |

The spine test asserts *engine outputs*, not merely that functions return: the
world-model stage's observation count, variable count and certificate status;
the forecast stage's confidence source and value; the decision stage's score
dimensions; the evidence stage's hashes. A stage that merely returns would
fail.

### 9.5 What TCP-002 has not achieved

- **Most engines the Spine reaches are unverified.** 89 of the 154 engines
  have no test. Seven subpackages contain **no** tested engine at all:
  `cognitive/engines` (23), `world_model/counterfactual` (17),
  `world_model/prediction` (9), `cognitive/decision` (8),
  `cognitive/metacognition` (7), `cognitive/reflection` (7),
  `cognitive/runtime` (6).
- **297 of 339 modules still have no external reference.** The Spine reaches a
  large fraction of the *engines*; it does not reach the cluster.
- **The application stack's 51 forecasting modules are still orphaned.** They
  live in `lib/`, not the runtime, so the Spine does not cover them. That is
  **TCP-002.3**, and it is the next checkpoint.
- **No experiment is executed and no knowledge is retained.** Both gates
  refuse by default.
- **No independent verification.** The disposition is unchanged.

### 9.6 Register status after TCP-002

40 rows: 32 open, 7 resolved, 1 partial. `TCP-B-023` (the 336 disconnected
modules) is now **PARTIAL** rather than closed: the cluster has an entry
point, but most of it remains unreferenced and unverified.

---

## 10. TCP-002.4 — Research-to-Forecast Operational Closure

**Status: PARTIAL.** Stages 0–3 delivered; Stages 4–13 open. Full detail in
`certification/tcp/TCP_002_4_IMPLEMENTATION_REPORT.md`.

### 10.1 What changed in the assessment

TCP-002.3 established that EFDI is canonical and reachable. TCP-002.4 asked a
sharper question: **can the research path actually use it?**

The answer, from source, was **no** — and the reason was not a missing
forecasting engine. `Tiannara.Research.ResearchDirector` is a real, supervised
pipeline:

```
priorities → hypotheses → experiment plans → (R0 quarantine)
```

It never asked for a probability. Worse, the hypotheses it generates are
*causal claims* (*"the observed behaviour is caused by an identifiable
factor"*) with no outcome space and no horizon — they are **not forecastable
propositions**. And two of their quantities are hardcoded constants presented
as measurements: `confidence: 0.5` for every hypothesis, and per-domain
`eig_score` values of 0.6–0.85.

### 10.2 What was delivered

| Stage | Outcome |
|-------|---------|
| 0 — Baseline | PASS |
| 1 — Lifecycle contract | PASS |
| 2 — Research Director → EFDI | **PASS** — the supervised director now produces a registered probabilistic forecast |
| 3 — Durable registry, adversarial | **PASS** — 14 adversarial tests against a real on-disk log |
| 4 — Outcome acquisition | **BLOCKED** — no live external source in this environment |
| 5–8, 10, 12 | OPEN |
| 9 — Spine integration | PARTIAL — NATS transport still unexecuted |
| 11, 13 | PASS |

### 10.3 The honesty rules the integration obeys

- A hypothesis that is **not a forecastable proposition** is marked
  `:not_forecastable` with the reason — it is **not** given an invented
  probability. This is a different statement from `:unavailable`, and the two
  are kept distinct.
- **Evidence confidence, expected information gain and forecast probability
  stay three separate quantities.** A confidence score is never converted into
  a probability.
- The forecast request is identified by the **research input**, not by the
  hypothesis instance, so re-ingesting a priority returns the original
  forecast rather than creating a second one.

### 10.4 Two more defects found by adversarial testing

| Defect | Consequence | Fix |
|--------|-------------|-----|
| `EventStore.parse_frames/4` stopped at the first unreadable frame | A truncated tail or corrupted frame produced a **clean-looking but incomplete** history — corruption was indistinguishable from a clean log | The store counts unreadable frames, distinguishes a truncated tail, and the registry reports `recovery_failures` and `durable: false` |
| `Event.from_binary/1` used `:erlang.binary_to_term(bin)` | A tampered durable log could introduce **executable terms** into the reader | `:erlang.binary_to_term(bin, [:safe])` |

### 10.5 What remains

The forecast half of the lifecycle is real, durable and adversarially tested.
The **observation half is not built**: no real outcome is acquired, so nothing
is independently resolved, nothing is scored, and no calibration claim is
possible. `TCP-B-046` remains open. RL-565 remains `HIGH / OPEN`; RL-564 and
`F-ARC-018` remain `OPEN`.

Register after TCP-002.4: **60 rows — 42 open, 17 resolved, 1 partial.**
