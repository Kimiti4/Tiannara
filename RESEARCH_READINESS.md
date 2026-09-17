# Phase 16.98 — Research Readiness Index (RRI) (Spec)

document_version: 16.06.0

phase: 16

status: Frozen

owner: Constitutional Research Council

depends_on:
  - RESEARCH_RUNTIME_FREEZE.md
  - AUTONOMOUS_RESEARCH_VALIDATION.md
  - INDEPENDENT_RESEARCH_AUDIT.md
  - LONG_HORIZON_RESEARCH.md

supersedes: null

## Purpose
Define the **Research Readiness Index (RRI)** used to determine when Phase 16’s autonomous constitutional research engine is ready to advance into Phase 17 (World Modeling).

RRI is a **specification** for scoring and gate evaluation—no runtime execution is introduced here.

---

## Constitutional Rule
RRI is computed only from:

- deterministic/replayable specification-defined artifacts (later produced during validation phases)
- immutable evidence bundles
- replay verification outcomes
- lineage completeness metrics
- independent audit outcomes

RRI must be **fail-closed**:
- if any required artifact category is missing, readiness cannot be inflated.

---

## RRI Levels
RRI ranges from `RRI-0` to `RRI-6`.

| Level | Name | Meaning |
|---|---|---|
| RRI-0 | Unspecified | Core contracts missing or ambiguous |
| RRI-1 | Contracts Frozen | Architecture, schemas, freeze specs exist (Phase 16 spec stage) |
| RRI-2 | Deterministic Replay Defined | Replay model and divergence semantics exist (contract-level readiness) |
| RRI-3 | Validation Campaigns Passed | Validation campaigns executed per spec; replayable outputs exist |
| RRI-4 | Evidence Closure Verified | Evidence closure and statistical validation gates pass |
| RRI-5 | Independent Evidence-Only Audit Passed | Independent auditor reconstructs outputs and artifacts |
| RRI-6 | Fully Certified | All gates pass; readiness confidence reaches constitutional threshold |

---

## Scoring Dimensions (Required Metrics)

RRI computation must use these dimensions:

1. **Autonomy**
   - percentage of pipeline stages completed without external user specification
   - determinism of autonomous decision outputs

2. **Productivity**
   - discovery throughput: validated programs per unit step/campaign window
   - success ratio: programs reaching evidence + statistical validation

3. **Diversity**
   - portfolio diversity measures:
     - domain entropy
     - program category entropy
     - evidence source diversity
   - detects research collapse modes

4. **Reproducibility**
   - replay verification pass rate:
     - hash equality rate
     - divergence handling consistency
   - reconstruction determinism for pipeline outputs

5. **Scientific Value**
   - statistically validated discovery contributions:
     - confidence interval quality
     - effect size distribution
     - contradiction resolution coverage

6. **Engineering Impact**
   - engineering opportunity discovery proxy:
     - count of research outcomes with engineering constraint implications
     - feasibility improvements over baseline proxies
   - (Phase 16 proxy definition is sourced from `LONG_HORIZON_RESEARCH.md`)

---

## Gate Mapping (How RRI Determines Phase Transition)

Phase advancement to Phase 17 requires:

- `RRI >= RRI-5` AND
- successful validation campaigns and replay certification (later produced) AND
- independent evidence-only audit reconstruction success AND
- evidence closure completeness AND
- archaeology coverage completeness

---

## Output Contract (Spec)
The RRI evaluation outputs:

- `ResearchReadinessIndex` object (later in runtime/validation phases)
  - `level` (RRI-0..RRI-6)
  - dimension scores (autonomy/productivity/diversity/reproducibility/scientific_value/engineering_impact)
  - pass/fail per gate category
  - deterministic explanation trace (via lineage proofs)

This file only specifies the **scoring model**; it does not define issued certification artifacts.

---

## Relationship to Phase 16 Acceptance Criteria
RRI operationalizes:
- sustained knowledge growth potential (via validation + long horizon metrics)
- deterministic replayability
- evidence closure and independent audit readiness
- portfolio health and contradiction resolution

---

## Frozen Interfaces Appendix

### Frozen Schemas

Observation, Question, Hypothesis, Experiment, Theory, Research Portfolio, Knowledge Gap, Research Certificate

### Frozen APIs

ObservationRegistry, QuestionGenerator, HypothesisEngine, ExperimentPlanner, TheoryEngine, ReplayEngine, KnowledgeGraph, ScientificCapital

### Frozen Behaviors

ObservationBehaviour, HypothesisBehaviour, ExperimentBehaviour, TheoryBehaviour, ReplayBehaviour, CertificateBehaviour

---

## Status
Spec-only: readiness scoring contracts for Phase 16 validation outputs.
