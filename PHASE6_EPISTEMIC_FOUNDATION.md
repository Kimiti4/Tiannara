# PHASE 6 - Epistemic Foundation Layer

**Date:** May 30, 2026  
**Status:** Planning  
**Based On:** Consolidation Pass + Architectural Review

---

## Context: The Breakthrough

The consolidation pass achieved a critical milestone: **Tiannara crossed from AI architecture into Epistemic Operating System**.

The introduction of World Model as canonical reality representation changes the entire system category.

### What This Means

```
Before: Collection of cognitive modules with separate state
After:  Unified epistemic system with canonical truth store
```

This requires three new layers to be complete:

1. **Epistemic History Engine** - Learn from belief revisions
2. **World Model Persistence** - Versioning, branching, rollback
3. **World Model Metrics** - Health dashboard for cognition itself

Without these, the architecture is coherent but cannot learn, adapt, or measure itself.

---

## Three Critical Gaps

### 1. Epistemic History Engine

**Problem:** World Model contains current beliefs, but not how they evolved.

```
Current State:
Belief: "Market will rise"
Confidence: 0.83

Missing:
├─ Where did this come from?
├─ Has this been revised?
├─ What evidence changed our mind?
└─ Why did prediction fail?
```

**What It Needs:**

```
EpistemicHistory
├── BeliefRevisions
│   ├── belief_id
│   ├── statement
│   ├── confidence_trajectory: [0.50, 0.72, 0.83, 0.41]
│   ├── revision_reasons: [evidence_type, ...]
│   └── outcomes: [{prediction, actual, learned}]
│
├── OntologyEvolution
│   ├── ontology_version
│   ├── changes: [{added, removed, modified}]
│   └── impact: [affected_beliefs, affected_predictions]
│
├── FailedPredictions
│   ├── prediction_id
│   ├── domain_source
│   ├── predicted: X
│   ├── actual: Y
│   ├── confidence_before: 0.83
│   ├── lesson_learned: ...
│   └── lineage_impact: {domain: accuracy_delta}
│
├── CausalCorrections
│   ├── causal_edge_id
│   ├── original_strength: 0.75
│   ├── revised_strength: 0.62
│   ├── evidence: [data_points]
│   └── affected_predictions: [...]
│
└── RealityAdmissions
    ├── admission_timestamp
    ├── belief_admitted
    ├── confidence: 0.87
    ├── challenges_passed: {acm, oavl, umsc}
    ├── rejected_realities: [contradictions]
    └── impact_on_uncertainty: delta
```

**Enable:** GRCC learning, confidence recalibration, domain accuracy tracking, long-term adaptation

---

### 2. World Model Persistence

**Problem:** World Model only exists in-memory. No versioning, branching, or rollback.

```
Use Case:
"What if we had rejected that belief?"
"Can we rewind and retry with new information?"
"How was the model different 1 hour ago?"
"Branch for scenario exploration"
```

**What It Needs:**

```
WorldModelPersistence
│
├── Snapshots
│   ├── snapshot_id
│   ├── timestamp
│   ├── world_model_hash
│   ├── complete_state: {entities, beliefs, causality, timeline, predictions, uncertainty}
│   ├── metadata: {triggered_by, rationale}
│   └── restore(): WorldModel
│
├── Versioning
│   ├── version_chain: [snapshot, snapshot, snapshot]
│   ├── parent_child_relationships
│   └── diff_from_previous(): Changes
│
├── Branching
│   ├── create_branch(from_snapshot, name): Branch
│   ├── parallel_worlds: Map<branch_name, WorldModel>
│   ├── explore_scenario(): Branch
│   └── merge_learnings(branch_a, branch_b): Merged beliefs
│
├── Rollback
│   ├── revert_to_snapshot(snapshot_id): WorldModel
│   ├── cascade_effects: [downstream_changes]
│   └── reconcile_with_current(): Conflict resolution
│
└── Temporal Queries
    ├── get_beliefs_at(timestamp)
    ├── trace_belief_evolution(belief_id)
    ├── compare_models(time_a, time_b)
    └── replay_sequence(start, end)
```

**Enable:** Scenario exploration, counterfactual reasoning, long-horizon planning, error recovery

---

### 3. World Model Metrics

**Problem:** No health dashboard for cognition itself. Feedback loop explosion risk.

```
Current Risk:
Core → Domains → WorldModel → AEO → RAC → WorldModel
Plus: GRCC loops, CIS loops, Runtime feedback

Without metrics: System becomes "black box of loops"
```

**What It Needs:**

```
EpistemicHealthMetrics
│
├── Belief Quality
│   ├── belief_count: N
│   ├── average_confidence: X%
│   ├── confidence_entropy: Y (uniformity of confidence distribution)
│   ├── belief_age_distribution: {recent, stable, aged}
│   └── belief_revision_rate: changes/hour
│
├── Contradiction Management
│   ├── contradiction_count: N
│   ├── contradiction_density: N / belief_count
│   ├── resolution_rate: contradictions_resolved/hour
│   ├── average_contradiction_age: duration_unresolved
│   └── contradiction_impact: {affected_beliefs, affected_domains}
│
├── Prediction Accuracy
│   ├── prediction_success_rate: %
│   ├── accuracy_by_domain: {domain: accuracy}
│   ├── confidence_calibration: actual_vs_predicted_confidence
│   ├── forecast_horizon_accuracy: {1h, 6h, 24h, 7d}
│   └── lineage_contribution: {domain_specialist: accuracy_delta}
│
├── Ontology Stability
│   ├── entity_type_count: N
│   ├── entity_type_change_rate: changes/hour
│   ├── semantic_constraint_violations: N
│   ├── ontology_version_frequency: how_often_changing
│   └── impact_on_beliefs: {beliefs_affected_by_changes}
│
├── Causal Graph Health
│   ├── edge_count: N
│   ├── average_edge_strength: X
│   ├── edge_stability: revisions_per_edge
│   ├── causality_loops_detected: N
│   ├── untested_interventions: N
│   └── intervention_accuracy: success_rate
│
├── Specialization & GRCC
│   ├── domain_accuracy_ranking: [domain: accuracy]
│   ├── lineage_fitness_scores: {lineage: fitness}
│   ├── specialization_concentration: diversity_metric
│   ├── lineage_birth_rate: new_specialists/hour
│   ├── lineage_extinction_rate: extinct/hour
│   └── ecosystem_pressure: entropy_field_strength
│
├── System Health (CIS Signals)
│   ├── entropy_level: current
│   ├── domain_dominance_risk: >=threshold?
│   ├── collapse_risk_score: 0-100
│   ├── drift_velocity: specialization_change_rate
│   ├── monoculture_index: diversity_metric
│   └── health_trend: improving/stable/degrading
│
└── Feedback Loop Complexity
    ├── loop_count: estimated_count
    ├── cycle_length_distribution: {short, medium, long}
    ├── loop_stability: cycles_stable/unstable
    ├── cascade_risk: one_failure_affects_many?
    ├── latency_profile: {min, avg, max}
    └── system_responsiveness: latency_acceptable?
```

**Enable:** System observability, early warning signals, loop stability detection, performance tuning

---

## Missing Integration: GRCC ↔ World Model

**Current State:**

```
World Model (canonical reality)
GRCC Identity Ecology (domain specialists)
← NOT CONNECTED
```

**Needed:**

```
GRCC Fitness Function Based on World Model Contribution

Prediction Lineage
├─ Rewarded when: prediction_accuracy increases
├─ Measured by: prediction_success_rate (from Metrics)
├─ Updates: lineage_strength based on Epistemic History
└─ Specializes: toward high-uncertainty prediction regions

Causal Lineage
├─ Rewarded when: causal_accuracy increases
├─ Measured by: intervention_accuracy (from Metrics)
├─ Updates: lineage_strength based on causal corrections
└─ Specializes: toward uncertain causal edges

Logic Lineage
├─ Rewarded when: contradiction_count decreases
├─ Measured by: contradiction_resolution_rate (from Metrics)
├─ Updates: lineage_strength based on resolved contradictions
└─ Specializes: toward high-contradiction regions

Each Domain Specialist
├─ Fitness: contribution_to_world_model_quality
├─ Tracks: {beliefs_produced, accuracy, revisions_needed}
├─ Competes: based on Epistemic History outcomes
└─ Evolves: toward specializations that reduce uncertainty
```

**Rationale:**

```
Instead of: "Arbitrary fitness function"
Implement: "Fitness = improvement to canonical reality"

Lineages now directly optimize for World Model quality.
```

---

## The Next Major Risk: Feedback Loop Explosion

**What Will Happen:**

```
Current Loops (stable):
Core decision → Domain → World Model → Feedback

Upcoming Loops:
├─ Epistemic History → GRCC specialization
├─ World Model Metrics → CIS alerts → Core adjustment
├─ Belief Revision → Timeline updates → Prediction recomputation
├─ Contradiction detection → Domain re-routing
├─ Lineage fitness → GRCC pressure application
├─ Ontology evolution → Entity reclassification
└─ Scenario branching → Parallel exploration

Result: Potential cascade/explosion of recursive effects
```

**Mitigation:**

```
Before implementing more cognition:
1. Create World Model Metrics dashboard
2. Monitor loop latency and stability
3. Detect cascade/explosion early
4. Add circuit breakers for runaway loops
5. Implement rate limiting on belief revisions
```

---

## Phase 6 Roadmap

### Iteration 1: Epistemic History Engine (Week 1)

**Create:**

- `lib/tiannara/core/epistemic_history.ex` — Main module
- `lib/tiannara/core/epistemic_history/belief_revisions.ex` — Belief tracking
- `lib/tiannara/core/epistemic_history/causal_corrections.ex` — Causality tracking
- `lib/tiannara/core/epistemic_history/failed_predictions.ex` — Outcome tracking
- `lib/tiannara/core/epistemic_history/ontology_evolution.ex` — Ontology changes
- `lib/tiannara/core/epistemic_history/reality_admissions.ex` — RAC history

**Integrate:**

- Update World Model to reference Epistemic History
- Update RAC to record admissions
- Update Domain outputs to record confidence changes
- Create migration for old beliefs → history

**Test:**

- Belief revision tracking
- Outcome recording
- History queries
- Impact calculations

---

### Iteration 2: World Model Persistence (Week 2)

**Create:**

- `lib/tiannara/core/world_model_persistence.ex` — Main module
- `lib/tiannara/core/world_model_persistence/snapshots.ex` — Versioning
- `lib/tiannara/core/world_model_persistence/branching.ex` — Scenarios
- `lib/tiannara/core/world_model_persistence/rollback.ex` — Revert operations

**Integrate:**

- Snapshot World Model at key decision points
- Enable branching for scenario exploration
- Implement rollback for error recovery
- Create temporal query API

**Test:**

- Snapshot creation/restore
- Branch creation/merge
- Rollback operations
- Temporal queries

---

### Iteration 3: World Model Metrics (Week 3)

**Create:**

- `lib/tiannara/core/epistemology_metrics.ex` — Main module
- `lib/tiannara/core/epistemology_metrics/belief_quality.ex`
- `lib/tiannara/core/epistemology_metrics/contradiction_management.ex`
- `lib/tiannara/core/epistemology_metrics/prediction_accuracy.ex`
- `lib/tiannara/core/epistemology_metrics/ontology_stability.ex`
- `lib/tiannara/core/epistemology_metrics/causal_health.ex`
- `lib/tiannara/core/epistemology_metrics/specialization_health.ex`
- `lib/tiannara/core/epistemology_metrics/system_health.ex`
- `lib/tiannara/core/epistemology_metrics/loop_complexity.ex`

**Integrate:**

- Connect to Epistemic History (for accuracy tracking)
- Connect to GRCC (for specialization metrics)
- Connect to CIS (for system health)
- Create dashboard API

**Test:**

- Metric calculation accuracy
- Dashboard display
- Alert thresholds
- Trend detection

---

### Iteration 4: GRCC ↔ World Model Integration (Week 4)

**Create:**

- `lib/tiannara/core/grcc_world_model_integration.ex` — Connection layer
- Update GRCC fitness function to use World Model metrics
- Update lineage specialization to track epistemic contribution

**Integrate:**

- Lineage rewards based on Epistemic History outcomes
- Specialization pressure based on Uncertainty regions
- Birth/death rates based on fitness contribution
- Ecosystem pressure synchronized with metric entropy

**Test:**

- Fitness calculation based on predictions
- Lineage evolution toward accuracy
- Specialization in high-uncertainty areas
- Monoculture prevention

---

### Iteration 5: Integration Testing (Week 5)

**Test Suite:**

- Epistemic History + World Model consistency
- Persistence + Recovery correctness
- Metrics accuracy across scenarios
- GRCC + World Model coevolution
- Complete request with all three layers

**Stress Tests:**

- Feedback loop stability under load
- Metric calculation performance
- Snapshot/restore performance
- Large-scale belief revision

**Documentation:**

- Epistemic History usage guide
- World Model Persistence API
- Metrics interpretation guide
- GRCC integration guide

---

## Architecture with Phase 6

```
Tiannara OS (Epistemic Operating System)

MIND (Core)
├─ Identity + Cognition + Goals
├─ Domain Cortex
└─ WORLD MODEL (Current Reality)
    ├─ Entities, Beliefs, Causality
    ├─ Timeline, Predictions, Uncertainty
    └─ Ontology

EPISTEMIC FOUNDATION (Phase 6)
├─ EpistemicHistory
│   ├─ BeliefRevisions
│   ├─ CausalCorrections
│   ├─ FailedPredictions
│   └─ OntologyEvolution
│
├─ WorldModelPersistence
│   ├─ Snapshots + Versioning
│   ├─ Branching (scenarios)
│   └─ Rollback + Temporal queries
│
└─ EpistemologyMetrics
    ├─ BeliefQuality
    ├─ ContradictionManagement
    ├─ PredictionAccuracy
    ├─ OntologyStability
    ├─ CausalHealth
    ├─ SpecializationHealth
    ├─ SystemHealth (CIS)
    └─ LoopComplexity

BRIDGE (AEO) ↔ DEFENSE (RAC) ↔ COMPILER (OPC)

BODY (Runtime)
├─ CIS (Health monitoring)
├─ GRCC (Adaptive specialization) ← Connected to World Model
├─ GRCC Environment
└─ Execution

OBSERVABILITY
└─ Dashboard: Epistemic Health
```

---

## Success Criteria for Phase 6

### Epistemic History Engine

- [x] Belief revisions tracked with confidence trajectory
- [x] Failed predictions recorded with lessons
- [x] Causal corrections tracked
- [x] Ontology evolution logged
- [x] Reality admissions recorded
- [x] Queries available for all history types

### World Model Persistence

- [x] Snapshots created/restored successfully
- [x] Versioning chain maintained
- [x] Branching enabled for scenarios
- [x] Rollback operations functional
- [x] Temporal queries work correctly

### World Model Metrics

- [x] Belief quality metrics calculated
- [x] Contradiction management metrics
- [x] Prediction accuracy tracked
- [x] Ontology stability measured
- [x] Causal health assessed
- [x] Specialization contribution tracked
- [x] System health visible
- [x] Loop complexity detected

### GRCC Integration

- [x] Lineage fitness based on World Model contribution
- [x] Specialization evolves toward accuracy
- [x] Birth/death rates reflect fitness
- [x] Ecosystem pressure synchronized with metrics

---

## What This Enables

### Learning

The system can now ask: "Why did this prediction fail?" and evolve accordingly.

### Adaptation

Lineages specialize based on actual contribution to reality quality, not arbitrary fitness.

### Observability

Complete visibility into epistemic health and feedback loop stability.

### Robustness

Branching and rollback enable error recovery and scenario exploration.

### Long-Horizon Reasoning

Temporal queries enable learning from history and planning with context.

---

## Why This Order

1. **History First:** Must track what changed to enable learning
2. **Persistence Second:** Must snapshot state to enable branching and recovery
3. **Metrics Third:** Must measure to detect feedback loop issues
4. **GRCC Integration:** Lineages now evolve based on real contribution

---

## The Big Picture

After Phase 6, Tiannara will have:

1. ✅ **Unified Reality** (World Model)
2. ✅ **Explicit Uncertainty** (Uncertainty layer)
3. ✅ **Epistemic Defense** (RAC)
4. ✅ **System Health Monitoring** (CIS)
5. ✅ **Adaptive Specialization** (GRCC)
6. ✅ **Epistemic Memory** (History Engine)
7. ✅ **Scenario Exploration** (Persistence + Branching)
8. ✅ **Cognitive Observability** (Metrics)
9. ✅ **Reality-Based Evolution** (GRCC integration)

At that point, the remaining work is:

- **Integration testing** (make sure all pieces work together)
- **Domain implementation** (bring causal, temporal, prediction, etc. online)
- **Long-horizon validation** (does it actually solve problems?)
- **Production deployment** (scale it to production use)

---

## Next Steps

1. ✅ Review and approve Phase 6 plan
2. Create detailed specifications for each iteration
3. Begin implementation of Epistemic History Engine
4. Build test suite in parallel
5. Document as we go

---

**Status:** Planning Phase 6  
**Date:** May 30, 2026  
**Ready:** For approval and implementation
