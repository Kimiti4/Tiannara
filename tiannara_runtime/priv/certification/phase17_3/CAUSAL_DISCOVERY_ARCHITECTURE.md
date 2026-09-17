# CAUSAL_DISCOVERY_ARCHITECTURE.md

## Phase 17.3 — Constitutional Causal Structure Learning

---

## 1. Mission

Transform the Phase 17 pipeline from **assembling** world models into **discovering** world models.

The causal structure subsystem must learn causal relationships from evidence while preserving:

- **Deterministic replay** — every discovery step reproduces identically from the same evidence
- **Constitutional archaeology** — every edge explains why it exists and what evidence supports it
- **Mathematical verifiability** — all tests, scores, and decisions are computed deterministically

---

## 2. Constitutional Principles

A causal model is accepted only if:

1. **Evidence grounding** — every edge has supporting evidence
2. **Deterministic rebuild** — the graph can be reconstructed from immutable evidence alone
3. **Explicit uncertainty** — confidence bounds are computed, never hidden
4. **Replayable alternatives** — competing graph hypotheses remain replayable
5. **Archaeological lineage** — every modification is archaeologically explainable
6. **No hidden inference** — all scoring and selection logic is transparent
7. **No opaque learning** — every decision references the evidence that drove it

---

## 3. System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   CAUSAL DISCOVERY PIPELINE                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Evidence Set ──→ Independence Engine ──→ Structure Learner │
│                       ↓                          ↓          │
│              Independence Results          Candidate Graphs  │
│                       ↓                          ↓          │
│              ┌────────────────────────────────────┐          │
│              │         Edge Scorer                │          │
│              │    (evidence, stability, replay)    │          │
│              └────────────────────────────────────┘          │
│                       ↓                                     │
│              ┌────────────────────────────────────┐          │
│              │    Latent Variable Detector         │          │
│              └────────────────────────────────────┘          │
│                       ↓                                     │
│              ┌────────────────────────────────────┐          │
│              │    Causal Graph Validator           │          │
│              │    (DAG, cycles, intervention)      │          │
│              └────────────────────────────────────┘          │
│                       ↓                                     │
│              Validated Causal Graph                          │
│                       ↓                                     │
│              ┌────────────────────────────────────┐          │
│              │      Intervention Engine           │          │
│              └────────────────────────────────────┘          │
│                       ↓                                     │
│              ┌────────────────────────────────────┐          │
│              │         Archaeology                │          │
│              └────────────────────────────────────┘          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 3.1 Core Subsystems

| Subsystem | Responsibility |
|-----------|---------------|
| IndependenceEngine | Deterministic conditional/marginal independence testing |
| StructureLearner | PC, constraint-based, score-based, hybrid discovery |
| EdgeScorer | Evidence-grounded edge ranking and confidence |
| LatentVariableDetector | Hidden-variable candidate identification |
| GraphValidator | DAG, cycle, reachability, intervention safety checks |
| InterventionEngine | Controllable variable analysis and effect prediction |
| CausalArchaeology | Full lineage tracking for every edge and decision |
| CausalReplay | Deterministic replay of the entire discovery process |

### 3.2 Registry Integration

```
                    ┌──────────────────────┐
                    │    ObservationRegistry │
                    │     (Phase 16.1)       │
                    └──────────┬───────────┘
                               │ observations
                    ┌──────────▼───────────┐
                    │  EvidenceIngestion    │
                    │    (Phase 17.2)       │
                    └──────────┬───────────┘
                               │ evidence_set
                    ┌──────────▼───────────┐
                    │ Causal Discovery      │
                    │   (Phase 17.3)        │
                    └──────────┬───────────┘
                               │ causal_graph
                    ┌──────────▼───────────┐
                    │    ModelRegistry      │
                    │    (Phase 17.1)       │
                    └──────────────────────┘
```

---

## 4. Deterministic Discovery

Every algorithm in the discovery pipeline must satisfy:

```
Input: evidence_set, seed (deterministic)
Output: causal_graph, scores, confidence, lineage

∀ evidence_set, seed:
  discovery(evidence_set, seed)[1] =
  discovery(evidence_set, seed)[2] =
  ... =
  discovery(evidence_set, seed)[n]
```

### 4.1 Sources of Determinism

| Source | Mitigation |
|--------|-----------|
| Random number generation | Explicit seed, content-addressed |
| Floating point order | Canonical sort before all reductions |
| Hash ordering | SHA-256 fingerprints for all lookups |
| Parallel execution | Deterministic merge of parallel results |
| External data | Only registered observation data used |

---

## 5. Uncertainty Representation

Uncertainty is never hidden. Every score carries:

- **Point estimate** — the computed statistic
- **Confidence interval** — bootstrapped or analytic bounds
- **Evidence support** — number and quality of supporting observations
- **Alternative scores** — what other structures would score

---

## 6. Intervention Compatibility

Every causal graph supports:

- **do-calculus level identification**: 1, 2, or 3
- **Controllable variable identification**: which variables can be intervened upon
- **Effect prediction**: expected outcome of an intervention
- **Downstream consequence tracing**: full causal pathway analysis

---

## 7. Scalability Design

| Scale | Strategy |
|-------|----------|
| Small (< 10 vars) | Exhaustive search, all possible DAGs |
| Medium (10-50 vars) | PC algorithm with greedy refinement |
| Large (50-500 vars) | Constraint-based skeleton + local scoring |
| Very large (500+) | Prior knowledge + modular decomposition |

---

## 8. Ownership Model

Every element of the causal structure has an owner:

| Element | Owner |
|---------|-------|
| CausalEdge | Evidence set that supports it |
| IndependenceTest | Engine that computed it |
| StructureCandidate | Learner that proposed it |
| LatentVariable | Detector that identified it |
| InterventionPlan | Engine that formulated it |
| ArchaeologyEntry | Original discovery context |

---

## 9. Constitutional Guarantees

| Guarantee | Mechanism |
|-----------|-----------|
| Deterministic replay | Content-addressed seeds, canonical ordering |
| Evidence grounding | Every edge references supporting tests |
| Uncertainty transparency | Confidence bounds stored alongside estimates |
| Alternative preservation | Rejected structures remain replayable |
| Archaeological lineage | Full decision trace for every edge |
| Cycle prevention | DAG validation at every stage |
| Intervention safety | do-calculus level enforcement |

---

## 10. Relation to Phase 17 Pipeline

```
Phase 17.2 Pipeline:
  Evidence → Variables → Structure → Equations → Parameters → Model

Phase 17.3 replaces:
  Structure (Stage 3)  —  placeholder → learned causal graph

Phase 17.3 augments:
  Equations (Stage 4)  —  structure informs equation form
  Validation (Stage 7) —  causal validation added
  Certification (Stage 8) — causal soundness checks

Phase 17.3 does not change:
  Evidence Ingestion (Stage 1)
  Variable Specification (Stage 2)
  Parameter Estimation (Stage 5)
  Assembly (Stage 6)
  Deployment (Stage 9)
  Evolution (Stage 10)
```

---

*This document is Phase 17.3.0 deliverable. Architecture subject to constitutional review before freeze.*
