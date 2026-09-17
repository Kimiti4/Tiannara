# Phase 18.5 — Plan Data Model

## Abstract Data Types

### Goal

| Field | Type | Description |
|-------|------|-------------|
| `id` | `GoalId` | Unique identifier |
| `mission_id` | `MissionId` | Parent mission |
| `parent_goal_id` | `Option<GoalId>` | Parent goal (None for root) |
| `type` | `GoalType` | Classification (see routing table in PLANNING_REPORT.md) |
| `description` | `String` | Human-readable goal statement |
| `priority` | `Rational` | Constitutional priority weight |
| `status` | `GoalStatus` | `decomposed`, `planned`, `evaluated`, `selected` |
| `decomposition_strategy` | `DecompositionStrategy` | How this goal was decomposed |

**Purpose:** Hierarchical breakdown of mission intent into tractable units.

**Ownership:** GoalDecomposer creates; TaskPlanner reads; PlanAssembler finalizes.

**Replay Requirements:** Full goal hierarchy must be reconstructable from replay artifacts. Each goal must record its parent, decomposition strategy, and the alternative decompositions considered.

---

### Objective

| Field | Type | Description |
|-------|------|-------------|
| `id` | `ObjectiveId` | Unique identifier |
| `goal_id` | `GoalId` | Owning goal |
| `measure` | `String` | Measurable criterion |
| `target` | `Rational` | Target value |
| `weight` | `Rational` | Relative importance within goal |

**Purpose:** Quantifiable success criteria within a goal.

**Ownership:** GoalDecomposer creates; ConstraintEvaluator reads.

**Replay Requirements:** Objective set must be reproducible from goal decomposition replay.

---

### PlanNode

| Field | Type | Description |
|-------|------|-------------|
| `id` | `NodeId` | Unique identifier |
| `label` | `String` | Human-readable label |
| `node_type` | `NodeType` | `action`, `decision`, `subplan`, `wait`, `observe` |
| `estimated_cost` | `Rational` | Resource cost estimate |
| `estimated_duration` | `Duration` | Time estimate |
| `parameters` | `Map<String, Value>` | Node-specific parameters |

**Purpose:** Atomic step within a task graph.

**Ownership:** TaskPlanner creates; AlternativeGenerator copies and mutates.

**Replay Requirements:** Node identity and parameters must be stable across replay.

---

### PlanEdge

| Field | Type | Description |
|-------|------|-------------|
| `id` | `EdgeId` | Unique identifier |
| `source_id` | `NodeId` | Predecessor node |
| `target_id` | `NodeId` | Successor node |
| `edge_type` | `EdgeType` | `sequence`, `parallel`, `conditional`, `loop` |
| `condition` | `Option<Expression>` | Condition (for conditional/loop edges) |

**Purpose:** Dependency and flow relationships between PlanNodes.

**Ownership:** TaskPlanner creates.

**Replay Requirements:** Edge structure must be deterministically reconstructable.

---

### Constraint

| Field | Type | Description |
|-------|------|-------------|
| `id` | `ConstraintId` | Unique identifier |
| `constraint_type` | `ConstraintType` | Constitutional constraint category |
| `source` | `String` | Origin (constitutional article, derived, imposed) |
| `score` | `Rational` | Evaluation score (0.0 = violation, 1.0 = perfect) |
| `threshold` | `Rational` | Minimum acceptable score |
| `details` | `Map<String, Value>` | Evaluation details |

**Purpose:** Quantitative evaluation of an alternative against a constitutional rule.

**Ownership:** ConstraintEvaluator creates.

**Replay Requirements:** Constraint evaluation must be reproducible from alternative + constraint definition alone.

---

### Alternative

| Field | Type | Description |
|-------|------|-------------|
| `id` | `AlternativeId` | Unique identifier |
| `plan_segment_id` | `String` | Which plan segment this alternative covers |
| `nodes` | `List<PlanNode>` | Alternative node set |
| `edges` | `List<PlanEdge>` | Alternative edge set |
| `generation_strategy` | `String` | How this alternative was generated |
| `constraint_scores` | `Map<ConstraintId, Rational>` | Cached constraint scores |

**Purpose:** A different way to achieve a plan segment.

**Ownership:** AlternativeGenerator creates; ConstraintEvaluator and TradeoffAnalyzer read.

**Replay Requirements:** Alternative generation strategy and parameters must be recorded.

---

### Tradeoff

| Field | Type | Description |
|-------|------|-------------|
| `id` | `TradeoffId` | Unique identifier |
| `alternative_a_id` | `AlternativeId` | First alternative |
| `alternative_b_id` | `AlternativeId` | Second alternative |
| `dimensions` | `Map<ConstraintId, Diff>` | Score differences across dimensions |
| `pareto_optimal` | `Boolean` | Whether A dominates B in any dimension |

**Purpose:** Pairwise comparison of alternatives across constraint dimensions.

**Ownership:** TradeoffAnalyzer creates.

**Replay Requirements:** Tradeoff matrix must be derivable from constraint scores.

---

### PlanningSession

| Field | Type | Description |
|-------|------|-------------|
| `id` | `SessionId` | Unique planning session identifier |
| `mission_id` | `MissionId` | Source mission |
| `iteration_number` | `UInt` | Iteration counter (for replay) |
| `goals` | `List<Goal>` | Goal decomposition |
| `task_graph` | `TaskGraph` | Complete task graph |
| `alternatives` | `List<Alternative>` | All generated alternatives |
| `constraints` | `List<Constraint>` | All constraint evaluations |
| `tradeoffs` | `List<Tradeoff>` | All tradeoff analyses |
| `ranking` | `RankedPlanList` | Final ranking |
| `chosen_plan` | `Alternative` | Selected alternative |
| `signature` | `Signature` | Cryptographic signature |
| `status` | `SessionStatus` | `active`, `completed`, `failed`, `frozen` |

**Purpose:** The complete output of a planning session — the canonical artifact.

**Ownership:** PlanAssembler creates; Ledger persists.

**Replay Requirements:** Full session must be reconstructable from replay artifacts indexed by `(session_id, iteration_number)`.

---

### PlanningEvidence

| Field | Type | Description |
|-------|------|-------------|
| `id` | `EvidenceId` | Unique identifier |
| `session_id` | `SessionId` | Owning session |
| `step` | `String` | Pipeline step that produced this evidence |
| `evidence_type` | `String` | Classification |
| `content` | `Map<String, Value>` | Evidence payload |
| `timestamp` | `Instant` | When produced |

**Purpose:** Supporting justification for planning decisions — not needed for replay, but required for audit.

**Ownership:** Each pipeline step creates its own evidence; PlanAssembler consolidates.

**Replay Requirements:** None (evidence is not replayed).

---

### PlanningReplay

| Field | Type | Description |
|-------|------|-------------|
| `step` | `String` | Pipeline step name |
| `inputs` | `Map<String, Value>` | Deterministic inputs |
| `outputs` | `Map<String, Value>` | Step outputs |
| `internal_state` | `Map<String, Value>` | Step internal state |
| `parent_hash` | `Hash` | Hash of previous step's replay artifact |
| `hash` | `Hash` | Hash of this artifact |

**Purpose:** Immutable record for deterministic reconstruction.

**Ownership:** Each pipeline step creates its own replay artifact.

**Replay Requirements:** This is the replay artifact itself; must be self-contained.

---

### PlanningArchaeology

| Field | Type | Description |
|-------|------|-------------|
| `aggregation_key` | `String` | Dimension being aggregated |
| `session_ids` | `List<SessionId>` | Sessions contributing to this aggregation |
| `summary` | `Map<String, Value>` | Aggregate statistics |
| `period_start` | `Instant` | Start of aggregation window |
| `period_end` | `Instant` | End of aggregation window |

**Purpose:** Cross-session analytical summaries for pattern detection and system improvement.

**Ownership:** PlanArchaeology consolidator.

**Replay Requirements:** Not replayable by design — archaeology is derived from replay of multiple sessions.
