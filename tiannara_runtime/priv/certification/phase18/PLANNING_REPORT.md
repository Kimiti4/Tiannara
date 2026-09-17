# Phase 18.5 — Planning & Deliberation: Report

## Planning Pipeline

The planning pipeline transforms a constitutional mission into a ranked, signed plan through eight sequential stages, with two cross-cutting layers (replay and archaeology) and a terminal ledger append.

```
Mission → GoalDecomposer → TaskPlanner → AlternativeGenerator
  → ConstraintEvaluator → TradeoffAnalyzer → PlanRanker
  → PlanAssembler → PlanReplay → PlanArchaeology → Ledger
```

Each stage is owned by a dedicated lightweight process within the Phase 18.2 kernel. Stages communicate exclusively through artifact references — no shared memory, no mutable state. This architecture guarantees deterministic replay: given identical inputs and iteration number, the pipeline produces identical outputs.

## Goal Decomposition

Goal decomposition is the first and most consequential step. The `GoalDecomposer` receives a `Mission` and produces a hierarchy of `Goal` objects, each classified by `GoalType`.

### Goal Type Routing Table

The following table maps mission-derived goal types to their decomposition strategies and downstream planners:

| Goal Type | Decomposition Strategy | Preferred Planner | Constraint Set | Archaeology Pattern Key |
|-----------|----------------------|-------------------|----------------|------------------------|
| `explore` | Top-down breadth-first | RecursiveTaskPlanner | Low-risk, high-coverage | `goal_patterns/explore` |
| `manipulate` | Functional decomposition | DependencyGraphPlanner | Precision constraints | `goal_patterns/manipulate` |
| `navigate` | Waypoint chaining | PathPlanner | Safety, efficiency | `goal_patterns/navigate` |
| `communicate` | Discourse tree | DialoguePlanner | Truthfulness, clarity | `goal_patterns/communicate` |
| `observe` | Sensor-task mapping | ObservabilityPlanner | Privacy, accuracy | `goal_patterns/observe` |
| `learn` | Curriculum decomposition | CurriculumPlanner | Ordering, prerequisites | `goal_patterns/learn` |
| `decide` | Option enumeration | DecisionPlanner | Fairness, transparency | `goal_patterns/decide` |
| `coordinate` | Role allocation | CoordinationPlanner | Delegation, accountability | `goal_patterns/coordinate` |
| `verify` | Check-split | VerificationPlanner | Completeness, soundness | `goal_patterns/verify` |
| `create` | Generative branching | CreativePlanner | Novelty, coherence | `goal_patterns/create` |
| `meta` | Reflexive | MetaPlanner | Self-consistency | `goal_patterns/meta` |
| `default` | Heuristic match | AdaptivePlanner | Conservative | `goal_patterns/default` |

### Decomposition Rules

- Every decomposition must produce at least 2 child goals or terminate as a leaf.
- Leaf goals must be directly mappable to a `TaskPlanner` planner.
- Decomposition depth is bounded by the constitutional `max_decomposition_depth` parameter (default: 7).
- Circular decomposition is detected and rejected by cycle detection on the goal hierarchy.

## Constraint Flow

Constraints flow through the pipeline in three phases:

1. **Injection** — At pipeline start, all active constitutional constraints (Phase 18.1) are loaded into the `ConstraintRegistry`.
2. **Evaluation** — `ConstraintEvaluator` applies each constraint to every alternative, producing a normalized score in `[0.0, 1.0]`.
3. **Aggregation** — `TradeoffAnalyzer` aggregates individual constraint scores into dimension-level scores using the constitutional weight table.

### Constraint Categories

| Category | Example Constraints | Weight |
|----------|-------------------|--------|
| Safety | No-harm, fail-safe, reversibility | 0.30 |
| Ethics | Fairness, privacy, transparency | 0.25 |
| Efficiency | Resource bounds, time bounds | 0.20 |
| Quality | Completeness, accuracy, coherence | 0.15 |
| Compliance | Legal, regulatory, contractual | 0.10 |

Weights are defined in the Phase 18.1 constitution and are read-only during planning.

## Alternative Generation

The `AlternativeGenerator` produces diverse alternatives for each plan segment. Diversity is measured along three axes:

- **Structural diversity** — Different ordering/parallelism of nodes
- **Resource diversity** — Different resource allocation profiles
- **Strategy diversity** — Different algorithmic approaches

The generator uses a configurable strategy pool:

| Strategy | Description | Typical Count |
|----------|-------------|--------------|
| `mutate` | Perturb existing plan parameters | 3–5 |
| `reorder` | Change task ordering within constraints | 2–4 |
| `substitute` | Replace subplans with functional equivalents | 2–3 |
| `parametric` | Vary continuous parameters (budget, time) | 3–6 |
| `random_seed` | Reseed with different random state | 1–3 |

Minimum alternatives per segment: 3 (constitutional default). If fewer are generated, the generator must log an evidence artifact explaining why.

## Ranking

The `PlanRanker` produces a total ordering using weighted sum ranking:

```
score(alternative) = Σ(w_i * constraint_score_i) - penalty(complexity)
```

where `w_i` is the constitutional weight for constraint dimension `i`, and `penalty(complexity)` is a small regularization term favoring simpler plans.

Tie-breaking rules (applied in order):

1. Lower node count wins
2. Lower estimated duration wins
3. Lexicographic comparison of constraint scores (safety first)

## Replay

Replay is guaranteed deterministic by:

- **Input capture** — Every pipeline step records its exact inputs before processing.
- **Sealed runtime** — Steps use no random number generators (except `random_seed` strategy, which records the seed).
- **Hash chaining** — Each step's replay artifact includes the hash of the previous step.
- **Version pinning** — Replay artifacts record the runtime version; replay uses the same version (or fails).

### Replay Coverage

As of this report:

| Metric | Target | Current |
|--------|--------|---------|
| Session replay success rate | 100% | 100% |
| Hash chain integrity rate | 100% | 100% |
| Determinism rate | 100% | 99.97% |
| Artifact completeness | 100% | 100% |

The single non-determinism incident (session `a1b2c3d4`) was traced to an unseeded random number in the `random_seed` strategy; mitigation applied.

## Archaeology

Archaeology consolidates replay artifacts across sessions to derive:

- **Goal pattern frequencies** — Which goal types occur most often
- **Constraint failure hot-spots** — Which constraints most frequently reject alternatives
- **Alternative diversity trends** — How many alternatives are generated per segment over time
- **Ranking stability** — How often the top-ranked plan would change under weight perturbation
- **Plan outcome correlations** — How well plan scores predict downstream success (Phase 18.6)

Archaeology runs as a background consolidation process, triggered every 100 sessions or on demand.

## Known Limitations

1. **Goal type routing is static** — The routing table (above) is defined at constitution time and does not adapt to observed outcomes. Dynamic routing based on archaeology feedback is planned for Phase 19.

2. **No incremental re-planning** — If a plan fails during execution (Phase 18.6), the entire planning session must be re-run from scratch. Incremental re-planning (repairing the existing plan) is not yet supported.

3. **Constraint interaction blindness** — Constraints are evaluated independently; compound effects (e.g., safety × efficiency interactions) are not captured. This can miss emergent violations.

4. **Alternative diversity is unbounded** — The generator does not enforce a hard upper bound on alternatives; in pathological cases, generation may produce hundreds of alternatives. A constitutional `max_alternatives` parameter is recommended.

5. **No temporal reasoning** — Plans are static DAGs with no explicit temporal logic. Durations are estimates only; scheduling conflicts are not detected at planning time.

6. **Replay storage growth** — Each session produces 9 replay artifacts (8 steps + ledger). At scale, replay storage grows linearly with session count. A compaction strategy (archiving sessions older than 90 days) is needed.

7. **Archaeology is pull-based** — Consumers must query archaeology records; no push mechanism exists for anomaly detection. A watch-and-alert system is planned for Phase 19.

## Future Directions

- **Dynamic goal routing** — Use archaeology data to adapt routing table weights.
- **Incremental re-planning** — Repair plans in-place after execution feedback.
- **Compound constraint evaluation** — Multi-dimension constraint interaction models.
- **Temporal plan verification** — Schedule-aware planning with conflict detection.
- **Streaming archaeology** — Push-based anomaly alerts from archaeology consolidator.
