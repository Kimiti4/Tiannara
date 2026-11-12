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
| **S5** | Observatory | `tiannara_observatory/` | 965 `.ex`, 157 `.exs`, 101 `.tsx` | Elixir/Phoenix/LiveView | `:tiannara_observatory` |
| **S5b** | Cognitive interface companion | `tiannara_pros/`, `tiannara_gui/`, `tiannara_mobile/`, `tiannara_saas/`, `tiannara-desktop/`, `tiannara_internal_dashboard/` | 38 `.py` (pros) + UI stacks | Python + UI | — |

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

**Missing:** a single cross-domain traversal test; a statement of which stack
owns reasoning.

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

**Missing:** one autonomous research task executed end-to-end with a traceable
report artefact.

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

**Missing:** a knowledge lifecycle with an explicit epistemic-status field and
a single authority for it.

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
model's confidence. The `behaviours/` sub-packages that would do this
(prediction 4, counterfactual 3) are hollow.

**Missing:** the prediction→observation→update loop.

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

**Missing:** (a) a decision to consolidate on one interface; (b) a rendering
contract for decision provenance and authority requests.

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

**Missing:** the authority hand-off from an approved proposal to its
implementation.

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

All assertions are exact: no `{:error, _}` or `match?({:error, _})` appears in
the new suites.

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

**Why W1 precedes everything.** Every capability is currently measured across
two stacks that can diverge. Consolidating first prevents every subsequent
work item from being implemented twice. **Why W2 precedes W3.** The
epistemic-status vocabulary is what lets research, memory, simulation and
awareness agree on what a datum *is*; retrofitting it later would require
rewriting every trace.

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
| Capability acceptance tests defined | 0 | 22 (AT-C1.1 … AT-C8.3) |
| Registered blockers | 0 | 22 (see the Completion Register) |

**Disposition:** `IMPLEMENTED_WITH_PARTIAL_EVIDENCE` / `VERIFICATION_BLOCKED`.
Self-attested; no independent verifier. RL-565 `HIGH / OPEN`; RL-564 and
`F-ARC-018` `OPEN`.
