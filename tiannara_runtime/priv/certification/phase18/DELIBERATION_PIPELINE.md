# Phase 18.5 — Deliberation Pipeline

## Pipeline Diagram

```
Mission
  │
  ▼
Goal Decomposition (GoalDecomposer)
  │
  ▼
Task Planning (TaskPlanner)
  │
  ▼
Alternative Generation (AlternativeGenerator)
  │
  ▼
Constraint Evaluation (ConstraintEvaluator)
  │
  ▼
Trade-off Analysis (TradeoffAnalyzer)
  │
  ▼
Plan Ranking (PlanRanker)
  │
  ▼
Plan Assembly (PlanAssembler)
  │
  ▼
Replay Recording (PlanReplay)
  │
  ▼
Archaeology (PlanArchaeology)
  │
  ▼
Ledger Append
```

## Step Specifications

### 1. Goal Decomposition (GoalDecomposer)

| Field | Value |
|-------|-------|
| **Inputs** | `Mission` (source: Phase 11/N directive) |
| **Outputs** | `List[Goal]` with parent-child hierarchy |
| **Owner** | GoalDecomposer process (kernel-spawned) |
| **Replay Artifact** | `replay/goal_decomposition/{session_id}/{iteration}.json` — contains mission text, goal hierarchy tree, decomposition strategy used |
| **Evidence Artifact** | `evidence/goal_decomposition/{session_id}/{iteration}.json` — decomposition rationale, alternative decompositions considered |
| **Archaeology Artifact** | `archaeology/goal_patterns/{goal_type}.json` — aggregates decomposition patterns by goal type |

### 2. Task Planning (TaskPlanner)

| Field | Value |
|-------|-------|
| **Inputs** | `List[Goal]` from GoalDecomposer |
| **Outputs** | `TaskGraph` (DAG of PlanNodes and PlanEdges) |
| **Owner** | TaskPlanner process |
| **Replay Artifact** | `replay/task_planning/{session_id}/{iteration}.json` — task graph adjacency list, node metadata |
| **Evidence Artifact** | `evidence/task_planning/{session_id}/{iteration}.json` — task dependency justification, ordering decisions |
| **Archaeology Artifact** | `archaeology/task_patterns/{goal_type}.json` — common task structures per goal type |

### 3. Alternative Generation (AlternativeGenerator)

| Field | Value |
|-------|-------|
| **Inputs** | `TaskGraph` from TaskPlanner |
| **Outputs** | `List[Alternative]` per plan segment |
| **Owner** | AlternativeGenerator process |
| **Replay Artifact** | `replay/alternative_generation/{session_id}/{iteration}.json` — alternatives with parameters, generation strategy |
| **Evidence Artifact** | `evidence/alternative_generation/{session_id}/{iteration}.json` — diversity metrics, coverage analysis |
| **Archaeology Artifact** | `archaeology/alternative_diversity/{goal_type}.json` — histograms of alternative counts, strategy usage |

### 4. Constraint Evaluation (ConstraintEvaluator)

| Field | Value |
|-------|-------|
| **Inputs** | `List[Alternative]`, constitutional constraints from Phase 18.1 |
| **Outputs** | `List[Constraint]` with scores per alternative |
| **Owner** | ConstraintEvaluator process |
| **Replay Artifact** | `replay/constraint_evaluation/{session_id}/{iteration}.json` — constraint scores, violation flags, raw constraint output |
| **Evidence Artifact** | `evidence/constraint_evaluation/{session_id}/{iteration}.json` — constraint provenance, weight justification |
| **Archaeology Artifact** | `archaeology/constraint_failures/{constraint_id}.json` — failure rate trends, common violation patterns |

### 5. Trade-off Analysis (TradeoffAnalyzer)

| Field | Value |
|-------|-------|
| **Inputs** | Constraint scores from ConstraintEvaluator |
| **Outputs** | `List[Tradeoff]` — pairwise alternative comparisons across constraint dimensions |
| **Owner** | TradeoffAnalyzer process |
| **Replay Artifact** | `replay/tradeoff_analysis/{session_id}/{iteration}.json` — tradeoff matrices, Pareto frontiers |
| **Evidence Artifact** | `evidence/tradeoff_analysis/{session_id}/{iteration}.json` — tradeoff rationale, weight sensitivity |
| **Archaeology Artifact** | `archaeology/tradeoff_patterns/{goal_type}.json` — common tradeoff archetypes |

### 6. Plan Ranking (PlanRanker)

| Field | Value |
|-------|-------|
| **Inputs** | `List[Tradeoff]` from TradeoffAnalyzer |
| **Outputs** | `RankedPlanList` — total ordering of alternatives |
| **Owner** | PlanRanker process |
| **Replay Artifact** | `replay/plan_ranking/{session_id}/{iteration}.json` — ranking scores, weight vector, tie-breaking decisions |
| **Evidence Artifact** | `evidence/plan_ranking/{session_id}/{iteration}.json` — ranking methodology justification |
| **Archaeology Artifact** | `archaeology/ranking_stability/{goal_type}.json` — rank stability under weight perturbation |

### 7. Plan Assembly (PlanAssembler)

| Field | Value |
|-------|-------|
| **Inputs** | `RankedPlanList`, top-ranked Alternative |
| **Outputs** | `PlanningSession` — signed, sealed plan artifact |
| **Owner** | PlanAssembler process |
| **Replay Artifact** | `replay/plan_assembly/{session_id}/{iteration}.json` — assembled plan, all metadata, signature |
| **Evidence Artifact** | `evidence/plan_assembly/{session_id}/{iteration}.json` — assembly decisions, inclusion/exclusion rationale |
| **Archaeology Artifact** | `archaeology/plan_outcomes/{goal_type}.json` — historical success rates of assembled plans |

### 8. Replay Recording (PlanReplay)

| Field | Value |
|-------|-------|
| **Inputs** | All per-step replay artifacts |
| **Outputs** | Complete replay log indexed by `(session_id, iteration, step)` |
| **Owner** | PlanReplay store |
| **Replay Artifact** | N/A (this is the store itself) |
| **Evidence Artifact** | `evidence/replay_integrity/{session_id}/{iteration}.json` — hash chain verification |
| **Archaeology Artifact** | `archaeology/replay_coverage/all.json` — replay completeness metrics |

### 9. Archaeology (PlanArchaeology)

| Field | Value |
|-------|-------|
| **Inputs** | Replay artifacts from multiple sessions |
| **Outputs** | Aggregated archaeology records |
| **Owner** | PlanArchaeology consolidator |
| **Replay Artifact** | N/A (archaeology is derived, not replayed) |
| **Evidence Artifact** | `evidence/archaeology_consolidation/{session_id}.json` — consolidation parameters |
| **Archaeology Artifact** | All archaeology records above (final output) |

### 10. Ledger Append

| Field | Value |
|-------|-------|
| **Inputs** | Assembled `PlanningSession`, Archaeology summary |
| **Outputs** | Ledger entry (immutable record) |
| **Owner** | Ledger service (Phase 18.0) |
| **Replay Artifact** | `replay/ledger_append/{session_id}/{iteration}.json` |
| **Evidence Artifact** | `evidence/ledger/{session_id}.json` |
| **Archaeology Artifact** | N/A |

## Data Flow Invariants

- Every pipeline step **must** emit exactly one replay artifact before passing output to the next step.
- If any step fails, the entire session is marked `failed` and a `PlanningReplay` artifact with the error is recorded.
- No step may read from runtime memory of a prior session; all inter-step communication is through artifact references.
- The pipeline is **single-threaded per session** — concurrent planning sessions are isolated by kernel process boundaries.
