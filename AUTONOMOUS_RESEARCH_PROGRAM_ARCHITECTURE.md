# Phase 17.8.0 — Autonomous Research Program Architecture (CAR)

document_version: 17.8.0
phase: 17.8
status: Architecture Review
owner: Constitutional Research Council
depends_on:
  - PHASE15_FINAL_CERTIFICATION.md
  - PHASE16_FINAL_CERTIFICATION.md (WITHHELD — dependency risk acknowledged)
  - PHASE16_X_FINAL_CERTIFICATION.md (PENDING — dependency risk acknowledged)
  - RESEARCH_DATA_MODEL.md
  - RESEARCH_PIPELINE.md
  - RESEARCH_REPLAY_MODEL.md
  - RESEARCH_CERTIFICATION.md
  - MATHEMATICS_ARCHITECTURE.md
  - digital_twin/engines/digital_twin_engine.ex (Phase 17.7.9)
supersedes: null

---

## Constitutional Architecture Review (CAR)

This document is the Phase 17.8.0 Constitutional Architecture Review.

No implementation is introduced here.

No schemas, APIs, or behaviors are frozen here — that is Phase 17.8.05.

---

## 1. Mission Statement

Phase 17.8 develops the Constitutional Autonomous Research Programs & Experimentation
(ARPE) engine. This engine bridges the Civilization Digital Twin (Phase 17.7) and the
upstream Constitutional Research stack (Phase 16) to produce a continuously self-improving
autonomous scientific civilization.

The Digital Twin can execute experiments. ARPE makes Tiannara decide what to investigate,
how to investigate it, and what to conclude — without human instruction — while remaining
fully constitutional, deterministic, replayable, and evidence-driven.

Every autonomous experiment becomes a constitutional research artifact.

### 1.1 Phase 17.8+ Proof Discipline

From Phase 17.8 onward, Tiannara preserves the no-hardcode, no-stub,
no-mock-data rule as a constitutional runtime invariant.

- No subsystem may introduce hardcoded domain thresholds, fallback budgets,
  fabricated timestamps, placeholder IDs, or inferred constants where a frozen
  config or caller-supplied artifact is required.
- No subsystem may return stub status, metric, portfolio, theory, evidence,
  certification, archaeology, or replay artifacts. If the real artifact is absent,
  unverifiable, or owned by another component, the subsystem must fail closed.
- Mock data is permitted only inside isolated test fixtures. It must never enter
  Phase 17.8+ runtime evidence, theory update, replay, archive, or certification
  paths.
- Tiannara systems must prove themselves through real content-addressed artifacts,
  deterministic replay, and independent verification; they must not pass by
  simulated success surfaces.

---

## 2. Scope and Boundaries

### 2.1 In-Scope (Phase 17.8)

- Autonomous knowledge gap detection from Phase 17.x World Model state
- Autonomous research question generation and prioritization
- Autonomous experiment design (variables, controls, stopping conditions, statistical power)
- Portfolio optimization across competing research programs
- Deterministic experiment scheduling within the Digital Twin (Phase 17.7)
- Evidence collection from Digital Twin simulation outcomes
- Statistical validation of collected evidence
- Theory evolution: strengthen, weaken, reject, merge, split, contradict
- Research archaeology: full explainability of every autonomous decision
- Mathematical verification of experiments using the Phase 16.X Mathematics Substrate
- Replay certification for all autonomous research artifacts
- Constitutional archive of all certified research programs

### 2.2 Out-of-Scope (Phase 17.8)

- Execution of experiments on real-world systems (Phase 17.8 uses Digital Twin only)
- Human-in-the-loop research direction (Phase 17.8 is fully autonomous)
- Modification of the Digital Twin physics or composition engines (Phase 17.6/17.7 scope)
- Modification of the Phase 16 research schemas (they are frozen upstream)
- New mathematical primitives (Phase 16.X scope)
- Publication or external dissemination of research results

---

## 3. Upstream Dependency Analysis

### 3.1 Phase 15 — Scientific Discovery
Status: CERTIFIED
Dependency: Hypothesis engine, discovery lifecycle, evidence-first certification
ARPE extends Phase 15 by making hypothesis generation and experiment execution autonomous
and continuous, rather than human-initiated.

### 3.2 Phase 16 — Constitutional Research
Status: WITHHELD (spec frozen, runtime authorized, validation NOT STARTED)
Risk: HIGH — Phase 17.8 runtime must not certify research outputs that depend on
uncertified Phase 16 validation infrastructure.
Mitigation: Phase 17.8 adopts Phase 16 schemas and pipeline contracts verbatim.
The Phase 17.8.999 certificate is conditional on Phase 16 reaching CERTIFIED status.
Any Phase 17.8 runtime output is provisionally archived; final knowledge integration
is gated on Phase 16 certification completing.

### 3.3 Phase 16.X — Mathematics Epistemic Substrate
Status: PENDING (spec frozen, runtime in progress)
Risk: MEDIUM — Phase 17.8.8 (Mathematical Verification) integrates the Mathematics
Substrate for experiment correctness checks. If Phase 16.X is uncertified at runtime,
the ARPEMathVerifier returns MATHEMATICALLY_UNVERIFIED status for all outputs via its
plug-in verification boundary — without any conditional branching or fallback logic
embedded in calling modules. The boundary is clean: callers receive a verification
result artifact; the UNVERIFIED status is explicit in the artifact, not inferred.
Mitigation: Architecture designs for a plug-in verification boundary. When Phase 16.X
certifies, the boundary implementation is replaced without changing research program
schemas or any other ARPE module.

### 3.4 Phase 17.7 — Civilization Digital Twin
Status: RUNTIME IMPLEMENTED (17.7.1–17.7.9 present)
Dependency: Simulation execution, outcome collection, scenario specification
ARPE is the consumer of the Digital Twin. It produces SimulationScenario artifacts
and consumes SimulationOutcome artifacts. The Digital Twin runtime does not change.

---

## 4. Canonical Ownership Map

Per the constitutional rule: every entity has exactly one canonical owner.

| Entity | Owner |
|---|---|
| KnowledgeGap (gap detection, 17.8 origin) | ARPEKnowledgeGapDetector |
| ResearchQuestion | ARPEQuestionGenerator |
| ResearchPriority | ARPEPriorityScorer |
| ResearchProgram | ARPEProgramPlanner |
| ExperimentPortfolio | ARPEPortfolioManager |
| ExperimentBudget | ARPEBudgetAllocator |
| ExperimentSchedule | ARPEScheduler |
| SimulationScenario (ARPE-produced) | ARPEExperimentPlanner |
| SimulationOutcome (consumed) | DigitalTwinEngine (Phase 17.7, read-only) |
| ResearchEvidence | ARPEEvidenceCollector |
| ResearchStatisticalValidation | ARPEStatisticalEngine |
| ResearchTheoryUpdateProposal | ARPETheoryEvolver |
| ResearchOutcome | ARPEProgramEngine |
| ProgramReplayFingerprint | ARPEReplayEngine |
| ProgramArchaeologyRecord | ARPEArchaeologyRegistry |
| MathematicalVerificationResult | ARPEMathVerifier (delegates to Phase 16.X substrate) |
| ARPECertificate | ConstitutionalCertificateAuthority (independent) |

No entity has two owners. No owner owns entities outside its module boundary.

---

## 5. Subsystem Architecture

### 5.1 Subsystem Map

```
Phase 17.7 Digital Twin
        │  SimulationScenario (in)
        │  SimulationOutcome (out)
        ▼
┌─────────────────────────────────────────────────────────┐
│               ARPE Constitutional Runtime               │
│                                                         │
│  KnowledgeGapDetector ──→ QuestionGenerator             │
│         │                       │                       │
│         ▼                       ▼                       │
│  PriorityScorer ◄──── ResearchPriorityLedger            │
│         │                                               │
│         ▼                                               │
│  ProgramPlanner ──→ ExperimentPlanner                   │
│         │                  │                            │
│         ▼                  ▼                            │
│  PortfolioManager   MathVerifier (16.X)                 │
│         │                  │                            │
│         ▼                  ▼                            │
│  BudgetAllocator ──→ Scheduler                          │
│                        │                               │
│                        ▼                               │
│              DigitalTwinEngine.run_simulation()         │
│                        │                               │
│                        ▼                               │
│              EvidenceCollector ──→ StatisticalEngine    │
│                                        │               │
│                                        ▼               │
│                              TheoryEvolver              │
│                                        │               │
│                                        ▼               │
│                              ReplayEngine               │
│                                        │               │
│                                        ▼               │
│                              ArchaeologyRegistry        │
│                                        │               │
│                                        ▼               │
│                        ConstitutionalCertificateAuthority│
└─────────────────────────────────────────────────────────┘
        │
        ▼
Phase 16 Research Ledger / Knowledge Graph
```

### 5.2 Component Descriptions

**ARPEKnowledgeGapDetector**
Scans the World Model (Phase 17.2), Causal Graph (Phase 17.3), Prediction residuals
(Phase 17.4), Counterfactual divergences (Phase 17.5), and Composition inconsistencies
(Phase 17.6) to surface measurable KnowledgeGap artifacts. All gaps are content-addressed.
Does not duplicate Phase 16 gap schemas — it extends them with Digital Twin provenance.

**ARPEQuestionGenerator**
Deterministically generates ResearchQuestion artifacts from KnowledgeGap inputs.
Uses frozen Phase 16.1 ResearchQuestion schema verbatim. Seed derivation is
content-hash-based. No randomness.

**ARPEPriorityScorer**
Scores ResearchQuestion artifacts using a deterministic multi-objective function:
uncertainty reduction × impact × feasibility × civilization relevance × information gain.
Tie-breaking: lexicographic over question_id hashes.

**ARPEProgramPlanner**
Creates ResearchProgram artifacts (Phase 16.1 schema) and binds them to
SimulationScenario specs for the Digital Twin. Statistical power requirements
are computed from experiment design, not guessed.

**ARPEExperimentPlanner**
Generates complete ResearchExperiment artifacts: variables, controls, treatments,
expected outcomes, stopping conditions, evidence mapping keys, statistical power specs.
All parameters are deterministic from program plan + frozen config.

**ARPEPortfolioManager**
Maintains the active research portfolio. Optimizes for: scientific diversity,
expected information gain, constitutional priority, resource utilization, long-term impact.
Portfolio selection is deterministic with content-hash tie-breaking.

**ARPEBudgetAllocator**
Tracks and enforces ExperimentBudget constraints across the portfolio.
Single owner of budget accounting. No other module may modify budget state.

**ARPEScheduler**
Produces ExperimentSchedule artifacts: sequential, parallel, dependent, adaptive.
Dispatches SimulationScenario artifacts to the Digital Twin engine.
Does not execute simulations — it produces dispatch intents only.

**ARPEEvidenceCollector**
Receives SimulationOutcome artifacts from the Digital Twin.
Normalizes them into ResearchEvidence bundles using frozen Phase 16.1 schemas.
Produces normalization proofs. Content-addresses all output.

**ARPEStatisticalEngine**
Consumes ResearchEvidence bundles. Produces ResearchStatisticalValidation artifacts.
Frequentist + Bayesian + robustness. All statistical outputs are deterministic and
replay-verifiable.

**ARPETheoryEvolver**
Produces ResearchTheoryUpdateProposal artifacts. Operations: strengthen, weaken,
reject, merge, split, contradict. All proposals reference evidence hashes and
certificate prerequisites. No theory is updated without a certified proposal chain.

**ARPEMathVerifier**
Delegates to Phase 16.X Mathematics Substrate for verification of experiment
correctness, optimization validity, statistical assumptions, symbolic consistency,
and resource constraints. When Phase 16.X is uncertified, the plug-in boundary
returns MATHEMATICALLY_UNVERIFIED status — recorded as an explicit field in the
MathematicalVerificationResult artifact. No conditional fallback logic exists in
other ARPE modules; they read the artifact status field only.

**ARPEReplayEngine**
Produces ProgramReplayFingerprint artifacts for each research program.
Supports full, partial, point-in-time, and verification replay.
Replay must reconstruct all artifacts from immutable ledger + frozen config.

**ARPEArchaeologyRegistry**
Registry-driven. Stores archaeology records for every program. Every program
can answer: originating knowledge gaps, planning decisions, experiment lineage,
theory updates, evidence chains, resource allocation, mathematical verification.
Explanation chain terminates at immutable evidence.

**ConstitutionalCertificateAuthority**
Independent of the runtime. Issues ARPECertificate only after:
replay certification, independent audit, statistical validation, and
archaeology completeness checks pass. Self-certification is forbidden.

---

## 6. Registry vs Runtime Boundary

Per constitutional rules:

**Registries define WHAT exists:**
- ProgramRegistry: canonical list of active/archived programs
- ExperimentRegistry: canonical list of designed experiments
- ArchaeologyRegistry: canonical explainability records
- EvidenceLedger: append-only evidence records

**Runtimes define HOW it executes:**
- ARPEProgramEngine: orchestrates the research lifecycle
- ARPEScheduler: drives experiment dispatch
- ARPEReplayEngine: runs verification replay

These boundaries must not be mixed. Registry modules must not contain execution logic.
Runtime modules must not own registry state directly.

---

## 7. Autonomy Boundaries

Phase 17.8 is fully autonomous. The following autonomy boundaries are constitutional
constraints — not optional:

1. A research program may only execute if it passes constitutional validation
   (Knowledge Gap → Question → Hypothesis → Experiment Design → Math Verification).
2. The scheduler may only dispatch experiments validated by the planner.
3. The theory evolver may only propose updates with complete evidence chains.
4. No theory update is accepted without a certificate chain.
5. Termination of ineffective programs is evidence-driven and archaeologically logged.
6. Resource allocation follows the BudgetAllocator's deterministic rules exclusively.
7. No autonomous decision may introduce hidden mutable state.

---

## 8. Data Flow and Immutability Rules

All inter-component data is immutable after creation:
- artifacts are content-addressed (blake3)
- ledgers are append-only
- no component may mutate another component's artifacts
- schema versions are monotonically increasing; old artifacts are never in-place modified

The only write operations in the system:
- append to ledger
- write new artifact to content-addressable store
- update registry index (append or replace pointer, not modify artifact)

---

## 9. Replay Architecture

Phase 17.8 replay extends Phase 16.2 replay model.

New replay scope:
- ExperimentSchedule determinism (scheduler outputs must replay identically)
- SimulationScenario determinism (ARPE-generated scenarios must replay identically)
- Evidence normalization determinism (Digital Twin outputs → ResearchEvidence)
- Portfolio selection determinism
- Theory evolution determinism

Replay levels:
- LEVEL1: content-addressed ID equality
- LEVEL2: semantic equality with deterministic tolerances
- LEVEL3: full pipeline structural replay

Every ARPE component output at every stage must be LEVEL1 replayable at minimum.

---

## 10. Archaeology Architecture

Every ARPE component registers archaeology entries in the ArchaeologyRegistry.
Every entity must answer Explain():

| Entity | Explain() Answers |
|---|---|
| KnowledgeGap | Source signal in World Model, detection algorithm, timestamp |
| ResearchQuestion | Originating gap, generation algorithm, scoring rationale |
| ResearchProgram | Question, resource constraints, planning algorithm version |
| ResearchExperiment | Program, design rationale, statistical power justification |
| ExperimentSchedule | Portfolio state, scheduling algorithm, resource availability |
| ResearchEvidence | SimulationOutcome ID, normalization proof, experiment ID |
| ResearchStatisticalValidation | Evidence bundle, validation spec, result derivation |
| TheoryUpdateProposal | Validation IDs, evidence IDs, theory snapshot hash |
| ProgramOutcome | All upstream hashes, termination reason, certificate IDs |

Explanation chains must terminate at immutable evidence — not at runtime state.

---

## 11. Mathematical Verification Architecture

Phase 17.8.8 integrates the Phase 16.X Mathematics Substrate as a verification service.

ARPE calls the Mathematics Substrate at three points:
1. Experiment design validation: verify statistical power calculations, dimensional
   consistency of measurement definitions, sampling plan correctness.
2. Portfolio optimization validation: verify optimization problem formulation,
   constraint satisfiability, objective function correctness.
3. Theory update validation: verify symbolic consistency of proposed theory revisions,
   contradiction detection completeness.

When Phase 16.X is not yet certified:
- Verification calls return MATHEMATICALLY_UNVERIFIED status
- Programs carrying this status are archived but not forwarded for certification
- The architecture is identical; only the verification module implementation differs

---

## 12. Scalability Requirements

Designed assuming 10+ years of continuous operation:

| Metric | Minimum Requirement |
|---|---|
| Autonomous programs | 100,000 per validation run |
| Experiments per program | Up to 10M total across portfolio |
| Archaeology records | Every artifact, no pruning |
| Replay fidelity | 100% deterministic at LEVEL1 |
| Ledger append throughput | Non-blocking, append-only, partitioned by program |
| Evidence store | Content-addressed; deduplication by blake3 hash |

---

## 13. Constitutional Compliance Checklist (CAR Exit Criteria)

- [x] Architecture is internally consistent
- [x] Single canonical owner defined for every entity
- [x] Replay fully specified at architecture level
- [x] Registry vs Runtime boundary is explicit
- [x] Autonomy boundaries are stated as constitutional constraints
- [x] No implementation exists in this document
- [x] Upstream dependency risks are acknowledged and mitigated
- [x] Mathematical verification boundary is isolated (plug-in)
- [x] Scalability requirements stated
- [x] All entities have Explain() coverage defined
- [x] Data flow immutability rules are explicit
- [x] No circular ownership
- [x] Certificate authority is independent of runtime

---

## 14. Mandatory CAR Audits

### Ownership Audit
PASS — Every entity maps to exactly one owner module. No cross-ownership.

### Replay Audit
PASS — Replay model is specified at architecture level. All components produce
deterministic outputs. Divergence handling is fail-closed.

### Archaeology Audit
PASS — Explain() coverage defined for every entity. Explanation terminates at
immutable evidence.

### Determinism Audit
PASS — All autonomous decisions are derived from frozen config + immutable inputs.
All tie-breaking is deterministic (content-hash lexicographic).

### Dependency Audit
PASS (with risk flags) — Phase 16 WITHHELD and Phase 16.X PENDING are acknowledged.
Mitigations are explicit (conditional certification, plug-in verification boundary).

### Evidence Flow Audit
PASS — Evidence flows append-only from Digital Twin → EvidenceCollector →
StatisticalEngine → TheoryEvolver → CertificateAuthority. No bypasses.

### Boundary Audit
PASS — Phase 17.8 does not modify Phase 17.7, Phase 16, or Phase 16.X internals.
Digital Twin is consumed read-only. Phase 16 schemas are used verbatim.

### Scalability Audit
PASS — Architecture supports 100K programs, 10M experiments, content-addressed
deduplication, append-only ledgers, and partitioned storage.

---

## 15. CAR Decision

**ARCHITECTURE REVIEW: PASS**

Phase 17.8.05 (Constitutional Freeze) may proceed.

No implementation may begin until Phase 17.8.05 is complete.

---

## Next Document

`RESEARCH_EXECUTION_PIPELINE.md` — Phase 17.8 execution pipeline specification.
