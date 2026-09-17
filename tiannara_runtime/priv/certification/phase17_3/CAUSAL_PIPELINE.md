# CAUSAL_PIPELINE.md

## Phase 17.3 — Causal Discovery Pipeline

---

## 1. Pipeline Overview

The causal discovery pipeline transforms an evidence set into a validated causal graph with full provenance, uncertainty, and replay support.

```
Evidence Set → Independence Tests → Structure Discovery → Edge Scoring
  → Latent Variable Detection → Graph Validation → Intervention Planning
  → Archaeology Logging
```

---

## 2. Pipeline Stages

### Stage 1 — Independence Testing

**Input**: Evidence set with typed variables

**Process**:
1. For each pair of variables, test conditional independence given all subsets of other variables
2. For each pair, test marginal independence
3. Store: statistic, p-value, confidence, conditioning set, evidence root
4. Results are content-addressed by `hash(variable_a || variable_b || conditioning_set)`

**Output**: `IndependenceResults.t` — sorted table of all test results

**Replay key**: `independence_root = hash(sorted test results)`

---

### Stage 2 — Skeleton Discovery

**Input**: Independence results

**Process**:
1. Start with fully connected undirected graph
2. For each pair (X, Y), remove edge if conditionally independent given some Z
3. Apply PC algorithm adjacency phase:
   - Test conditioning sets of increasing size
   - Remove edges when independence found
   - Record the separating set for each removed edge
4. Result is the undirected skeleton

**Output**: `Skeleton.t` with adjacency list and separating sets

**Replay key**: `skeleton_root = hash(sorted adjacency list)`

---

### Stage 3 — Edge Orientation

**Input**: Skeleton, independence results

**Process**:
1. Identify v-structures (colliders): X → Y ← Z where X and Z are not adjacent
   - Y is a collider if X and Z are marginally dependent but conditionally independent given Y
2. Apply Meek orientation rules to orient remaining edges:
   - Rule 1: X → Y — Z → X → Y → Z
   - Rule 2: X → Y → Z and X — Z → X → Z (avoid cycles)
   - Rule 3: X → Y ← Z and X — Z → X → Z
   - Rule 4: X — Y and Y → Z → W and X — Z → X → Y
3. Edges that cannot be oriented remain undirected

**Output**: `CausalGraph.t` with directed and undirected edges

**Replay key**: `orientation_root = hash(sorted oriented edges)`

---

### Stage 4 — Score-Based Refinement

**Input**: Oriented graph, evidence set

**Process**:
1. Score the current graph using BGe score or BIC
2. Propose edge additions, removals, reversals
3. Accept changes that improve score
4. Reject changes that create cycles
5. Return highest-scoring graph

**Output**: Refined `CausalGraph.t` with edge scores

**Replay key**: `refinement_root = hash(sorted edge scores)`

---

### Stage 5 — Hybrid Discovery

**Input**: Independence results, scores

**Process**:
1. Run constraint-based PC skeleton
2. Score the skeleton and all single-edge variations
3. Greedy hill-climbing from PC skeleton:
   - Add best-scoring edge
   - Remove worst-scoring edge
   - Reverse edge if improves score
4. Constraint-based edges are locked (cannot be removed)

**Output**: `CausalGraph.t` with hybrid confidence scores

**Replay key**: `hybrid_root = hash(candidate graph fingerprints)`

---

### Stage 6 — Edge Scoring

**Input**: Causal graph, independence results, evidence set

**Process**:
1. For each edge, compute:
   - **Evidence support**: number of independent observations
   - **Statistical strength**: p-value from independence test
   - **Stability**: bootstrap confidence (proportion of resamples where edge appears)
   - **Replay confidence**: how many replay runs produce the same edge
   - **Intervention compatibility**: whether edge is consistent with known interventions
2. Normalize scores to [0, 1]

**Output**: `EdgeScore.t` per edge with multi-metric breakdown

**Replay key**: `scoring_root = hash(sorted edge scores)`

---

### Stage 7 — Latent Variable Detection

**Input**: Causal graph, edge scores, independence results

**Process**:
1. Detect latent common causes from residual dependencies:
   - If X and Y have high correlation not explained by measured parents
   - Candidates for hidden confounder Z
2. Detect latent mediation:
   - If X → Y effect is not fully mediated by measured intermediate variables
3. Propose latent variable locations with confidence

**Output**: `[LatentVariable.t]` with location, confidence, alternatives

**Replay key**: `latent_root = hash(sorted latent proposals)`

---

### Stage 8 — Graph Validation

**Input**: Causal graph (with optional latent variables)

**Process**:
1. **DAG check**: ensure no directed cycles
2. **Reachability**: every node reachable from at least one exogenous node
3. **do-calculus level**: compute level 1, 2, or 3
4. **Intervention safety**: verify no edges create paradoxical interventions
5. **Replay check**: verify graph matches original discovery from evidence alone
6. **Mathematical consistency**: verify all edge directions respect known laws

**Output**: `ValidationResult.t` with pass/fail per check

**Replay key**: `validation_root = hash(sorted check results)`

---

### Stage 9 — Intervention Planning

**Input**: Validated causal graph

**Process**:
1. Identify controllable variables:
   - Variables that can be directly manipulated
   - Variables reachable through mediation
2. Compute do-operator effects:
   - P(Y | do(X = x)) for each target-outcome pair
3. Compute expected effect size with confidence interval
4. Trace downstream consequences across all causal pathways

**Output**: `[InterventionPlan.t]` with predicted effects

**Replay key**: `intervention_root = hash(sorted intervention plans)`

---

### Stage 10 — Archaeology Logging

**Input**: All previous stage outputs

**Process**:
1. For each edge in the final graph, build a provenance entry:
   - Originating independence test
   - Evidence set root at time of discovery
   - Score at addition
   - Alternatives considered and rejected
   - Graph evolution steps
2. For each rejected alternative, preserve full context
3. For each latent variable, store competing explanations

**Output**: `CausalArchaeology.t` with full decision lineage

**Replay key**: `archaeology_root = hash(sorted archaeology entries)`

---

## 3. Stage Dependencies

```
Independence Testing ──────┐
                           │
                    Skeleton Discovery
                           │
                    Edge Orientation
                           │
                    ┌──────┴──────┐
                    │             │
           Score-Based     Hybrid Discovery
           Refinement           │
                    │             │
                    └──────┬──────┘
                           │
                     Edge Scoring
                           │
                  Latent Detection
                           │
                   Graph Validation
                           │
                 Intervention Planning
                           │
                  Archaeology Logging
```

---

## 4. Determinism Guarantees

| Stage | Determinism Source |
|-------|--------------------|
| Independence | Canonical sort of variable pairs, SHA-256 ordering |
| Skeleton | Fixed conditioning set order, consistent adjacency |
| Orientation | Deterministic v-structure detection, Meek rules |
| Score-Based | Content-addressed seed for all scoring computations |
| Hybrid | Constraint-based edges locked, deterministic tie-breaking |
| Edge Scoring | All inputs computed from canonical evidence ordering |
| Latent Detection | Thresholds are constitutional parameters, not heuristics |
| Validation | All checks are purely structural or replay-comparison |
| Intervention | do-calculus is a deterministic algorithm |
| Archaeology | Full input trace preserved in canonical order |

---

## 5. Failure Recovery

| Failure | Recovery |
|---------|----------|
| Not enough evidence for independence test | Lower test confidence, mark as unknown |
| Skeleton contains disconnected components | Report independent subgraphs separately |
| Edge orientation ambiguous | Leave edge undirected with confidence 0.5 |
| Score tie | Use fingerprint-order tiebreaker |
| Graph contains cycle | Reject and report violating edge set |
| Intervention not identifiable | Report which queries are non-identifiable |

---

*This document is Phase 17.3.0 deliverable. Pipeline subject to constitutional review before freeze.*
