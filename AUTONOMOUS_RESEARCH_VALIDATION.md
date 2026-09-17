# Phase 16.95 — Autonomous Research Validation (Spec)

document_version: 16.06.0

phase: 16

status: Frozen

owner: Constitutional Research Council

depends_on:
  - RESEARCH_RUNTIME_FREEZE.md

supersedes: null

## Purpose
Specify the **autonomous research validation campaigns** required to prove that Phase 16's autonomous constitutional research engine can:

- generate valid research questions from explicit knowledge gaps
- plan and design research programs deterministically
- execute the planned statistical/evidence pipelines (later implementation)
- reduce uncertainty in a measurable way
- resolve contradictions / identify evidence needed
- produce replay-verifiable outputs
- produce lineage + evidence bundles that independent auditors can reconstruct

This document defines **validation campaigns as deterministic specifications**, not implementation.

---

## Frozen Interfaces Appendix

### Frozen Schemas

Observation, Question, Hypothesis, Experiment, Theory, Research Portfolio, Knowledge Gap, Research Certificate

### Frozen APIs

ObservationRegistry, QuestionGenerator, HypothesisEngine, ExperimentPlanner, TheoryEngine, ReplayEngine, KnowledgeGraph, ScientificCapital

### Frozen Behaviors

ObservationBehaviour, HypothesisBehaviour, ExperimentBehaviour, TheoryBehaviour, ReplayBehaviour, CertificateBehaviour

---

## Validation Principle
Validation must prove properties of *autonomous behavior* under frozen contracts, including:

1. determinism under replay
2. evidence closure (no knowledge integration without evidence gates)
3. statistical validity (frequentist + Bayesian + robustness)
4. archaeological explainability (lineage reconstructs every decision)
5. portfolio behavior (optimization respects frozen contracts)
6. failure handling (spec defines fail-closed artifacts on uncertainty/evidence failures)

---

## Campaign Structure
Each campaign consists of:

- Input corpus (immutable ledgers / frozen config)
- Autonomous research workload:
  - question generation load
  - planning load
  - experiment design load
  - evidence bundling load (simulated in Phase 16.95 implementation, later)
  - statistical validation load (deterministic)
  - theory update proposals load
- Replay workload:
  - repeat derivations from identical immutable artifacts
  - compare outputs by content-addressed hashes
- Archaeology workload:
  - reconstruct lineage and explain every derived artifact’s provenance
- Audit-readiness workload:
  - produce evidence bundles suitable for evidence-only independent audit

---

## Campaign Matrix (Deterministic Scale Targets)

### C1 — Question Storm (100K)
- Objective:
  - prove autonomous question generation is:
    - deterministic
    - knowledge-gap grounded
    - priority-scored transparently
- Outputs:
  - `KnowledgeGap` artifacts
  - `ResearchQuestion` artifacts
  - `ResearchPriority` artifacts
  - lineage records for each derivation

### C2 — Program Synthesis (10K)
- Objective:
  - prove autonomous planning is:
    - contract-valid
    - evidence-closure aware
    - stop-criteria and sampling plans defined
- Outputs:
  - `ResearchProgram`
  - `ResearchExperiment` design artifacts
  - evidence requirements mapping
  - lineage chain

### C3 — Contradiction Resolution Trials
- Objective:
  - prove the system can detect contradictory hypotheses/states and generate
    - targeted experiments/simulations
    - uncertainty-reduction objectives
- Outputs:
  - contradiction-triggered `KnowledgeGap`s
  - priority re-ranking artifacts
  - evidence-required experiments

### C4 — Uncertainty Reduction Campaign
- Objective:
  - prove measurable reduction in uncertainty metrics under validation gates
- Outputs:
  - statistical validation artifacts per program
  - theory update proposal artifacts referencing evidence hashes
  - “delta uncertainty” reports (spec-defined metric outputs)

### C5 — Portfolio Optimization & Diversity
- Objective:
  - prove portfolio optimization:
    - respects resource constraints
    - optimizes deterministically for:
      - expected scientific capital
      - uncertainty reduction
      - engineering impact
      - feasibility and cost
    - maintains healthy diversity over long runs
- Outputs:
  - portfolio selection ledger
  - portfolio composition metrics
  - lineage proofs of program inclusion/exclusion

### C6 — Replay Verification (100% Replays)
- Objective:
  - prove determinism and archaeologically explainable reconstruction
- Outputs:
  - replay divergence reports (fail-closed)
  - replay verification results (hash equality checks)

### C7 — Research Archaeology (100% Explainability)
- Objective:
  - prove every autonomous decision can be explained through lineage
- Outputs:
  - archaeology reconstruction artifacts (spec-defined expectations)
  - audit readiness bundles

---

## Validation Gates (Spec Contracts)
Validation is considered successful only if all of the following gates pass:

1. **Knowledge-gap grounding gate**
   - Every research question must reference a measurable knowledge gap.
2. **Deterministic planning gate**
   - Replaying planning from identical inputs yields identical content-addressed artifacts.
3. **Evidence closure gate**
   - Knowledge integration steps (later implementation) must be conditional on:
     - statistical validation outputs
     - evidence bundles referenced by hash
4. **Statistical validity gate**
   - Statistical outputs must include:
     - confidence intervals
     - effect sizes / uncertainty metrics
     - robustness/sensitivity checks
5. **Replay certification gate**
   - Replay outputs must produce deterministic “match” results with divergence reports.
6. **Archaeology gate**
   - For each derived artifact, lineage must reconstruct provenance and explain decision context.
7. **Fail-closed gate**
   - Any missing evidence/mapping ambiguity must produce explicit failure artifacts, not silent continuation.

---

## Outputs (Spec-level Expected Artifacts)
During Phase 16.95 implementation (later), validation campaigns must produce immutable outputs whose schemas are expected to be:

- Validation campaign manifests
- research lineage entries
- statistical validation outputs (content-addressed)
- evidence bundle schemas
- replay verification results / divergence reports
- audit readiness bundles

(Concrete filenames and issued certificate outputs remain a later certification stage concern.)

---

## Relationship to Acceptance Criteria (Mapping)
This campaign directly supports Phase 16 acceptance criteria by validating:

- autonomous question generation from knowledge gaps
- prioritized deterministic research decisions
- research planning with experiments, evidence requirements, stopping conditions
- portfolio optimization for scientific/engineering/uncertainty/cost metrics
- deterministic replay and archaeologically explainable lineage
- preparation for independent evidence-only audit

---

## Status
**Spec-only**: no implementation is introduced here.
