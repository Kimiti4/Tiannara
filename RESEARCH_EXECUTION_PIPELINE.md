# Phase 17.8.0 — Research Execution Pipeline (CAR)

document_version: 17.8.0
phase: 17.8
status: Architecture Review
owner: Constitutional Research Council
depends_on:
  - AUTONOMOUS_RESEARCH_PROGRAM_ARCHITECTURE.md
  - RESEARCH_PIPELINE.md (Phase 16 — extended, not replaced)
  - digital_twin/engines/digital_twin_engine.ex (Phase 17.7.9)
supersedes: null

---

## Purpose

This document specifies the Phase 17.8 autonomous research execution pipeline.

It extends the Phase 16 pipeline specification (Stages A–M) with the Digital Twin
execution bridge, portfolio management, adaptive scheduling, and theory evolution stages.

This is a constitutional architecture document. No implementation is introduced here.

---

## Foundational Rule

The Phase 16 pipeline (Stages A–M) remains the canonical research lifecycle contract.

Phase 17.8 adds:
1. An upstream gap detection stage that feeds the Phase 16 pipeline from World Model state.
2. A Digital Twin execution bridge that realizes Phase 16 Stage G (Schedule and Dispatch)
   and Stage H (Collect Evidence) — both of which were defined as spec-only contracts in
   Phase 16 and are now given full constitutional runtime implementations in Phase 17.8.
3. Portfolio management stages that operate across multiple concurrent research programs.
4. Theory evolution stages that extend Phase 16 Stage J (Theory Update Proposals).

The Phase 16 pipeline stages A–M are not modified — they are preserved and executed
inside the ARPE runtime.

---

## Constitutional Requirement

Every autonomous experiment must traverse this full pipeline without exception:

```
Knowledge Gap
    ↓
Research Question
    ↓
Hypothesis
    ↓
Experiment Design
    ↓
Mathematical Verification
    ↓
Digital Twin Execution
    ↓
Evidence Collection
    ↓
Statistical Validation
    ↓
Theory Update Proposal
    ↓
Knowledge Integration Proposal
    ↓
Replay Certification
    ↓
Constitutional Archive
```

No stage may be skipped. Any skipped stage produces a constitutional violation artifact,
not a silent continuation.

---

## Stage 0 — WORLD_MODEL_GAP_SCAN

**Owner:** ARPEKnowledgeGapDetector
**Inputs:**
- World Model snapshot (Phase 17.2) — immutable hash-stamped
- Causal graph state (Phase 17.3) — immutable hash-stamped
- Prediction residuals (Phase 17.4) — immutable hash-stamped
- Counterfactual divergences (Phase 17.5) — immutable hash-stamped
- Composition inconsistencies (Phase 17.6) — immutable hash-stamped

**Output:**
- `KnowledgeGap` artifacts (Phase 16.1 schema extended with Digital Twin provenance)
  - gap_source: WORLD_MODEL | CAUSAL_GRAPH | PREDICTION_RESIDUAL |
    COUNTERFACTUAL | COMPOSITION_INCONSISTENCY
  - twin_provenance_hash: blake3 of the source snapshot used

**Determinism rule:**
- Identical input snapshot hashes → identical KnowledgeGap outputs
- Gap detection algorithm version is frozen per epoch configuration

**Gate:**
- Every KnowledgeGap must have a measurable closure criterion
- KnowledgeGap must reference the source snapshot hash

---

## Stage 1 — QUESTION_GENERATION
*(Phase 16 Stage C — extended)*

**Owner:** ARPEQuestionGenerator
**Inputs:** KnowledgeGap artifacts from Stage 0

**Output:** ResearchQuestion artifacts (Phase 16.1 schema verbatim)

**Extension over Phase 16:**
- Question generation considers Digital Twin experimental feasibility
  (can this be tested in a simulation scenario?)
- Adds field: `twin_executable: boolean` — whether the Digital Twin can execute
  a corresponding experiment

**Determinism rule:**
- Content-hash-derived seed for all generation
- No wall-clock, no network

---

## Stage 2 — PRIORITIZATION
*(Phase 16 Stage D — extended)*

**Owner:** ARPEPriorityScorer
**Inputs:** ResearchQuestion artifacts

**Output:** ResearchPriority records with deterministic scoring

**Scoring function (frozen per epoch):**

```
score(q) = w_uncertainty   × uncertainty_reduction(q)
         + w_impact        × impact(q)
         + w_feasibility   × feasibility(q)
         + w_civilization  × civilization_relevance(q)
         + w_information   × information_gain(q)
```

All weights (w_uncertainty, w_impact, w_feasibility, w_civilization, w_information)
are read exclusively from the epoch-frozen configuration artifact at scoring time.
No weight has a default value in code. If the configuration artifact is absent,
scoring fails closed and produces a ScoringConfigMissing failure artifact.

**Tie-breaking:** lexicographic over question_id (blake3 hash)

**Gate:**
- Every output priority record references the question_id and gap_id that produced it

---

## Stage 3 — PROGRAM_PLANNING
*(Phase 16 Stage E — extended)*

**Owner:** ARPEProgramPlanner
**Inputs:** Prioritized ResearchQuestion artifacts + resource budget

**Output:** ResearchProgram artifacts (Phase 16.1 schema verbatim)

**Extension over Phase 16:**
- Programs include a `simulation_scenario_template` field binding the program
  to a Digital Twin scenario configuration
- Statistical power is pre-computed from experiment design at planning time,
  not deferred

**Gate:**
- Programs must not exceed BudgetAllocator constraints
- Statistical power requirements must be explicitly stated before experiment design begins

---

## Stage 4 — EXPERIMENT_DESIGN
*(Phase 16 Stage F — extended)*

**Owner:** ARPEExperimentPlanner
**Inputs:** ResearchProgram artifacts

**Output:** ResearchExperiment artifacts + SimulationScenario artifacts

**SimulationScenario extension:**
- Wraps ResearchExperiment into a Digital Twin scenario specification
- Maps experiment variables, controls, treatments to Twin state mutations
- Maps stopping conditions to simulation termination rules
- Maps evidence collection requirements to Twin outcome observables

**Gate:**
- Every SimulationScenario must have an unambiguous evidence mapping
- Ambiguous mappings produce EvidenceCollectionFailure artifacts — not silent continuation

---

## Stage 5 — MATHEMATICAL_VERIFICATION
*(New — Phase 17.8.8 contribution)*

**Owner:** ARPEMathVerifier
**Inputs:** ResearchExperiment + SimulationScenario artifacts

**Output:** MathematicalVerificationResult artifact

**Checks (delegated to Phase 16.X substrate):**
- Statistical power calculations are correct
- Dimensional consistency of measurement definitions
- Sampling plan is well-formed
- Optimization constraints in portfolio are satisfiable
- Symbolic invariants in the scenario are consistent

**When Phase 16.X is uncertified:**
- The ARPEMathVerifier plug-in boundary returns a MathematicalVerificationResult
  with status: MATHEMATICALLY_UNVERIFIED
- No conditional logic in the pipeline switches behaviour; the artifact status is
  read at Stage 14 (Constitutional Archive) to determine certificate eligibility
- UNVERIFIED experiments are archived as PROVISIONAL_ARCHIVE and excluded from
  final CERTIFIED status until Phase 16.X certifies

**Gate:**
- Experiments without a MathematicalVerificationResult are blocked from scheduling

---

## Stage 6 — PORTFOLIO_SELECTION
*(New — Phase 17.8.4 contribution)*

**Owner:** ARPEPortfolioManager
**Inputs:** All verified ResearchProgram + ResearchExperiment artifacts + current portfolio state

**Output:** ExperimentPortfolio artifact — the selected set of experiments to schedule

**Portfolio optimization objectives (deterministic, frozen per epoch):**
1. Maximize expected total information gain
2. Maximize scientific diversity (domain entropy across selected programs)
3. Respect ExperimentBudget constraints
4. Respect constitutional priority ordering
5. Maximize expected long-term impact

**Determinism rule:**
- Optimization algorithm is deterministic for identical inputs
- Tie-breaking: lexicographic over program_id hash

**Gate:**
- Portfolio must not exceed resource budget
- Portfolio must maintain minimum diversity (domain entropy ≥ epoch-frozen threshold)

---

## Stage 7 — BUDGET_ALLOCATION
*(New — Phase 17.8.4 contribution)*

**Owner:** ARPEBudgetAllocator
**Inputs:** ExperimentPortfolio + current resource state

**Output:** ExperimentBudget artifact — per-program resource allocation

**Rule:**
- Single canonical owner of budget state
- All allocations are deterministic given portfolio and resource state
- Budget state is append-only (new budget artifact per allocation cycle)

**Gate:**
- No experiment may be scheduled without an ExperimentBudget allocation artifact

---

## Stage 8 — SCHEDULING
*(Phase 16 Stage G — realized)*

**Owner:** ARPEScheduler
**Inputs:** ExperimentPortfolio + ExperimentBudget + dependency graph

**Output:** ExperimentSchedule artifact — ordered dispatch intents

**Schedule types:**
- Sequential: experiments ordered by dependency
- Parallel: independent experiments dispatched concurrently within budget
- Dependent: experiments blocked until prerequisite experiments complete
- Adaptive: stopping criteria checked after each batch; schedule may be revised

**Interruption handling:**
- If a running experiment exceeds budget or hits a stopping criterion,
  the scheduler emits an InterruptionRecord artifact and revises the schedule
- InterruptionRecords are appended to the experiment's lineage

**Gate:**
- Dispatch intents reference only verified, budget-allocated experiments
- Schedule is deterministic from portfolio + budget + dependency graph

---

## Stage 9 — DIGITAL_TWIN_EXECUTION
*(Phase 16 Stage G/H — realized via Phase 17.7)*

**Owner:** DigitalTwinEngine (Phase 17.7 — read-only from ARPE perspective)
**ARPE interface:** ARPEScheduler dispatches SimulationScenario to DigitalTwinEngine.run_simulation()

**Output consumed by ARPE:** SimulationOutcome artifacts (Phase 17.7.1 schema)

**Constitutional boundary:**
- ARPE does not modify the Digital Twin engine
- ARPE produces inputs to it and consumes outputs from it
- Outcomes are immutable once produced — ARPE writes them to the EvidenceLedger

**Gate:**
- SimulationOutcome must carry the simulation_fingerprint (deterministic hash of
  initial state + events + seed) enabling replay verification

---

## Stage 10 — EVIDENCE_COLLECTION
*(Phase 16 Stage H — realized)*

**Owner:** ARPEEvidenceCollector
**Inputs:** SimulationOutcome + ResearchExperiment (evidence mapping keys)

**Output:** ResearchEvidence bundles (Phase 16.1 schema verbatim + Digital Twin provenance)

**Normalization rule:**
- Each SimulationOutcome observable is mapped to an evidence record using the
  frozen evidence_to_measurement_mapping from the ResearchExperiment artifact
- Normalization proof is content-addressed

**Gate:**
- If any required observable is missing from the SimulationOutcome,
  an EvidenceMappingFailure artifact is produced — not a silently partial bundle

---

## Stage 11 — STATISTICAL_VALIDATION
*(Phase 16 Stage I — realized)*

**Owner:** ARPEStatisticalEngine
**Inputs:** ResearchEvidence bundles + statistical requirements from ResearchProgram

**Output:** ResearchStatisticalValidation artifacts (Phase 16.1 schema verbatim)

**Validation types:** Frequentist + Bayesian + Meta-analysis + Robustness

**Replay requirement:**
- Statistical outputs must be deterministic and replay-verifiable (LEVEL1 + LEVEL2)

**Gate:**
- Outputs must satisfy alpha, power, and confidence interval requirements
  specified in the ResearchProgram before any theory update is proposed

---

## Stage 12 — THEORY_EVOLUTION
*(Phase 16 Stage J — extended)*

**Owner:** ARPETheoryEvolver
**Inputs:** ResearchStatisticalValidation + current theory graph snapshot

**Output:** ResearchTheoryUpdateProposal artifacts (Phase 16.1 schema verbatim)

**Theory operations:**
| Operation | Trigger |
|---|---|
| STRENGTHEN | Validated evidence increases confidence beyond threshold |
| WEAKEN | Validated evidence decreases confidence below threshold |
| REJECT | Validation conclusion = FALSIFIED with sufficient power |
| MERGE | Two theories shown to be equivalent by validated evidence |
| SPLIT | Theory shown to be domain-specific; evidence supports subdivision |
| CONTRADICT | New evidence contradicts accepted theory; opens contradiction gap |

**Gate:**
- Every proposal must reference evidence_ids and validation_ids (no orphaned proposals)
- Certificate prerequisites must be explicitly listed

---

## Stage 13 — REPLAY_CERTIFICATION
*(Phase 16 Stages K — realized)*

**Owner:** ARPEReplayEngine
**Inputs:** All artifacts from Stages 0–12 for a program

**Output:** ProgramReplayFingerprint + ReplayCertificationRequest

**Replay scope:** All stages must be LEVEL1 replayable.
Stages 0, 1, 2, 3, 4, 5, 6, 7, 8 must also be LEVEL3 replayable
(full pipeline structural replay). Replay levels are defined in ARPE_REPLAY_MODEL.md.

**Gate:**
- No program advances to constitutional archive without a successful replay fingerprint

---

## Stage 14 — CONSTITUTIONAL_ARCHIVE
*(Phase 16 Stage M — realized)*

**Owner:** ARPEProgramEngine (coordinates) + ArchaeologyRegistry (stores)
**Inputs:** All program artifacts + replay fingerprint + certificate prerequisites

**Output:**
- ProgramArchaeologyRecord (complete explainability record)
- ResearchOutcome (final program disposition)
- Archive entry in ProgramRegistry

**Certificate path:**
- ConstitutionalCertificateAuthority issues ARPECertificate only after:
  replay passed + independent audit passed + statistical gates passed +
  archaeology completeness confirmed + Phase 16 upstream certification status verified

**Gate:**
- No program is marked CERTIFIED unless all gates pass
- Programs with MATHEMATICALLY_UNVERIFIED status are archived as PROVISIONAL_ARCHIVE
  until Phase 16.X certifies

---

## Pipeline Failure Semantics

Every failure is fail-closed and produces an explicit failure artifact:

| Failure | Artifact Produced |
|---|---|
| Gap detection anomaly | KnowledgeGapAnomaly |
| Evidence mapping ambiguity | EvidenceMappingFailure |
| Mathematical verification fail | MathVerificationFailure |
| Statistical gate fail | StatisticalGateFail |
| Replay divergence | ReplayDivergenceReport |
| Budget exceeded | BudgetViolationRecord |
| Constitutional gate fail | ConstitutionalViolationRecord |

No failure produces silent continuation. Every failure is appended to the program's
archaeological lineage.

---

## Summary

This pipeline extends Phase 16's constitutional research pipeline with:
- World Model gap detection (Stage 0)
- Digital Twin execution bridge (Stages 8–10)
- Portfolio management (Stages 6–7)
- Theory evolution (Stage 12)
- Full replay and constitutional archive (Stages 13–14)

The architecture enforces constitutional discipline at every stage transition.
No autonomous experiment executes without traversing the full pipeline.
