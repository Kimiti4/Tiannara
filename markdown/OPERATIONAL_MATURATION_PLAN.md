# Tiannara Operational Maturation Implementation Plan

## Strategic Context (next.md lines 452-1007)

Tiannara has transitioned from **experimental intelligence framework** → **operational cognitive platform**.

### Critical Shift:
- **FROM**: Feature expansion (build → build → build → collapse)
- **TO**: Operational maturation cycles (build → stress → observe → stabilize → evolve)

### Current Status: ✅ Stabilization Infrastructure Complete
All 6 critical stabilization systems implemented (3,766 lines):
- Health Metrics, Constitutional Evolution, Reality Anchors
- Friction Integration, Failure Museum Enhancement, Interpretability Suite

---

## Phase 1: Cognitive Operations Center (Dashboard Transformation)

**Goal**: Transform dashboard from "chat app" → "mission control for evolving cognition"

### Layer 1: Cognitive State Visualization
**Purpose**: Let you SEE cognition in real-time

**Implementation Tasks**:
1. Create `/dashboard/cognitive-state` page
2. Display active goals with progress tracking
3. Visualize confidence maps across domains
4. Show competing hypotheses with evidence weights
5. Render active memory clusters as interactive graph
6. Display causal models with strength indicators
7. Highlight unresolved contradictions with severity

**Backend Requirements**:
```python
# New API endpoint: GET /api/v1/cognitive/state
{
  "active_goals": [...],
  "confidence_maps": {"domain": confidence},
  "competing_hypotheses": [...],
  "memory_clusters": [...],
  "causal_models": [...],
  "unresolved_contradictions": [...]
}
```

**Files to Create**:
- `tiannara_saas/app/dashboard/cognitive-state/page.tsx`
- `tiannara_api/routes/cognitive_state.py`

---

### Layer 2: Epistemic Health Dashboard ⭐ PRIORITY
**Purpose**: "AI vital signs monitor" - detect invisible cognitive drift

**Implementation Tasks**:
1. Enhance existing `/dashboard/monitoring` page
2. Integrate health metrics system (already built)
3. Show truth-confidence calibration curves over time
4. Display drift risk scores with trend analysis
5. Calculate hallucination probability per domain
6. Visualize evidence quality distribution
7. Track synthesis stability metrics
8. Monitor dissent diversity (prevents echo chambers)

**Integration Points**:
- Connect to `CognitiveHealthMonitor` (tiannara_core/monitoring/health_metrics.py)
- Connect to `RealityAnchorSystem` (tiannara_core/monitoring/reality_anchors.py)
- Display drift detection alerts from reality anchors

**Backend Requirements**:
```python
# Enhance existing: GET /api/v1/monitoring/health
{
  "calibration_accuracy": 0.87,
  "drift_risk_score": 0.23,
  "hallucination_probability": 0.12,
  "evidence_quality_avg": 0.78,
  "synthesis_stability": 0.91,
  "dissent_diversity_index": 0.65,
  "trend_analysis": {...}
}
```

**Files to Modify**:
- `tiannara_saas/app/dashboard/monitoring/page.tsx` (enhance)
- `tiannara_api/routes/monitoring_stabilization.py` (add epistemic endpoints)

---

### Layer 3: Evolution Dashboard
**Purpose**: Safe evolution tracking - prevent silent corruption

**Implementation Tasks**:
1. Create `/dashboard/evolution` page
2. Visualize constitutional evolution timeline
3. Show mutations attempted vs successful adaptations
4. Display rejected self-modifications with reasons
5. Track rollback events with causation analysis
6. Plot learning trajectories over time
7. Show skill acquisition curves

**Integration Points**:
- Connect to `ConstitutionalEvolution` (tiannara_core/monitoring/constitutional_evolution.py)
- Display modification history and approval workflows

**Backend Requirements**:
```python
# New endpoint: GET /api/v1/evolution/history
{
  "mutations_attempted": 47,
  "successful_adaptations": 32,
  "rejected_modifications": 15,
  "rollback_events": 3,
  "learning_trajectories": [...],
  "skill_acquisition_curves": {...}
}
```

**Files to Create**:
- `tiannara_saas/app/dashboard/evolution/page.tsx`
- Add evolution endpoints to `tiannara_api/routes/monitoring_stabilization.py`

---

### Layer 4: Multi-Agent Coordination Dashboard
**Purpose**: Make distributed cognition visible

**Implementation Tasks**:
1. Create `/dashboard/multi-agent` page
2. Render agent communication graph (force-directed layout)
3. Show coalition emergence over time
4. Visualize debate pathways with argument trees
5. Track dissent preservation metrics
6. Display consensus formation patterns
7. Identify coordination bottlenecks

**Integration Points**:
- Connect to `MultiAgentSystem` (tiannara_core/agents/multi_agent_system.py)
- Use telemetry data for communication patterns

**Backend Requirements**:
```python
# New endpoint: GET /api/v1/agents/coordination
{
  "communication_graph": {nodes: [...], edges: [...]},
  "coalitions": [...],
  "debate_pathways": [...],
  "dissent_preservation_rate": 0.78,
  "consensus_formation_time_avg": 245.3,
  "bottlenecks": [...]
}
```

**Files to Create**:
- `tiannara_saas/app/dashboard/multi-agent/page.tsx`
- `tiannara_api/routes/agent_coordination.py`

---

### Layer 5: Reality Grounding Dashboard ⭐ PRIORITY
**Purpose**: Prevent "beautiful delusion" - external validation status

**Implementation Tasks**:
1. Enhance existing monitoring page OR create `/dashboard/reality-grounding`
2. Show external verification status per domain
3. Display causal confidence scores with uncertainty bands
4. Track failed predictions with root cause analysis
5. Calculate world-model accuracy metrics
6. Run physical plausibility checks visualization
7. Monitor temporal consistency over time

**Integration Points**:
- Connect to `RealityAnchorSystem` (tiannara_core/monitoring/reality_anchors.py)
- Display anchor validation results

**Backend Requirements**:
```python
# Enhance existing or new: GET /api/v1/reality/grounding
{
  "external_verification_status": {...},
  "causal_confidence_scores": {...},
  "failed_predictions": [...],
  "world_model_accuracy": 0.89,
  "physical_plausibility_checks": {...},
  "temporal_consistency_score": 0.94
}
```

**Files to Modify/Create**:
- Option A: Enhance `tiannara_saas/app/dashboard/monitoring/page.tsx`
- Option B: Create `tiannara_saas/app/dashboard/reality-grounding/page.tsx`

---

## Phase 2: Cognitive Telemetry System

**Goal**: Longitudinal metric collection - identify cognitive signatures & instability precursors

### Task 2.1: Build Telemetry Collector
**Purpose**: Log 8+ cognitive metrics continuously

**Metrics to Track**:
1. Contradiction density over time
2. Synthesis convergence rates
3. Confidence calibration accuracy
4. Theory survival curves
5. Communication entropy
6. Causal consistency scores
7. Epistemic recovery rates
8. Memory reconstruction fidelity

**Implementation**:
```python
# tiannara_core/telemetry/cognitive_telemetry.py
class CognitiveTelemetryCollector:
    def record_metric(self, metric_name: str, value: float, metadata: dict)
    def query_metrics(self, metric_names: List[str], time_range: tuple) -> DataFrame
    def export_metrics(self, format: str = "csv") -> bytes
    def detect_anomalies(self, metric_name: str, window_size: int = 100) -> List[Anomaly]
```

**Storage Strategy**:
- Use SQLite for local development (runs/ directory)
- Support PostgreSQL for production deployment
- Time-series optimized queries

**Files to Create**:
- `tiannara_core/telemetry/cognitive_telemetry.py` (new module)
- Update `tiannara_core/telemetry/__init__.py`

---

### Task 2.2: Create Telemetry API Endpoints
**Backend Requirements**:
```python
# tiannara_api/routes/telemetry.py
POST /api/v1/telemetry/record          # Record metric
GET  /api/v1/telemetry/query           # Query with filters
GET  /api/v1/telemetry/export          # Export CSV/JSON
GET  /api/v1/telemetry/anomalies       # Detect anomalies
GET  /api/v1/telemetry/dashboard       # Dashboard summary
```

**Files to Create**:
- `tiannara_api/routes/telemetry.py`

---

### Task 2.3: Build Telemetry Dashboard
**Frontend Requirements**:
1. Create `/dashboard/telemetry` page
2. Time-series charts for all 8+ metrics
3. Anomaly detection alerts with severity
4. Correlation analysis between metrics
5. Export functionality (CSV/PDF reports)
6. Configurable time ranges (1h, 24h, 7d, 30d, custom)

**Visualization Libraries**:
- Use Recharts or Chart.js for time-series
- Heatmaps for correlation matrices
- Alert badges for anomaly detection

**Files to Create**:
- `tiannara_saas/app/dashboard/telemetry/page.tsx`

---

## Phase 3: Deterministic Replay System (Cognitive Debugger)

**Goal**: Replay any episode, reconstruct state, compare branches - invaluable for debugging

### Task 3.1: Implement Event Logging Infrastructure
**Purpose**: Capture everything needed for full replay

**Events to Log**:
1. Reasoning steps (with intermediate conclusions)
2. Agent communications (messages, responses)
3. Memory operations (read, write, consolidate)
4. Decision points (options considered, final choice, rationale)
5. State transitions (before/after snapshots)

**Implementation**:
```python
# tiannara_core/debugging/event_logger.py
class CognitiveEventLogger:
    def log_reasoning_step(self, step_id, input, output, metadata)
    def log_communication(self, sender, receiver, message, response)
    def log_memory_operation(self, operation, key, value, before_state, after_state)
    def log_decision(self, decision_id, options, chosen, rationale)
    def snapshot_state(self, session_id) -> StateSnapshot
```

**Storage Format**:
- JSONL files in `runs/{session_id}/events.jsonl`
- Indexed by timestamp and correlation_id
- Compress old sessions automatically

**Files to Create**:
- `tiannara_core/debugging/event_logger.py`
- `tiannara_core/debugging/state_snapshot.py`

---

### Task 3.2: Create Replay Engine
**Purpose**: Reconstruct past states and step through execution

**Features**:
1. Load episode from event log
2. Reconstruct memory state at any point
3. Step-through execution (forward/backward)
4. Branch comparison (what-if analysis)
5. Export replay session as report

**Implementation**:
```python
# tiannara_core/debugging/replay_engine.py
class CognitiveReplayEngine:
    def load_episode(self, session_id: str) -> Episode
    def reconstruct_state(self, episode, timestamp: str) -> StateSnapshot
    def step_forward(self, current_state) -> NextState
    def step_backward(self, current_state) -> PreviousState
    def compare_branches(self, branch_a, branch_b) -> ComparisonReport
```

**Files to Create**:
- `tiannara_core/debugging/replay_engine.py`

---

### Task 3.3: Build Replay Debugger UI
**Purpose**: Visual interface for cognitive debugging

**Features**:
1. Episode browser (list of past sessions)
2. Timeline view with event markers
3. State inspector (show variables at each step)
4. Branch comparison view (side-by-side diffs)
5. Search/filter events by type, component, keyword

**UI Components**:
- Timeline slider with zoom
- Event type filters (reasoning, communication, memory, decisions)
- State diff viewer (highlight changes)
- Export report button

**Files to Create**:
- `tiannara_saas/app/dashboard/replay-debugger/page.tsx`
- `tiannara_saas/components/replay/TimelineViewer.tsx`
- `tiannara_saas/components/replay/StateInspector.tsx`
- `tiannara_saas/components/replay/BranchComparator.tsx`

---

## Phase 4: Cognitive Sandboxing

**Goal**: Test evolution safely before merging to main cognition

### Task 4.1: Build Sandbox Environment
**Purpose**: Isolated testing with auto-rollback on failure

**Features**:
1. Fork current cognitive state into sandbox
2. Apply modifications in isolation
3. Resource limits (max steps, max memory, timeout)
4. Auto-rollback if violations detected
5. Safe merge only after epistemic audit passes

**Implementation**:
```python
# tiannara_core/sandbox/cognitive_sandbox.py
class CognitiveSandbox:
    def fork_state(self, base_state_id: str) -> SandboxSession
    def apply_modification(self, session_id, modification) -> Result
    def check_resource_limits(self, session_id) -> Violation | None
    def rollback(self, session_id) -> RollbackReport
    def safe_merge(self, session_id) -> MergeResult | RejectionReason
```

**Files to Create**:
- `tiannara_core/sandbox/cognitive_sandbox.py`
- `tiannara_core/sandbox/resource_limiter.py`

---

### Task 4.2: Create Stress Test Suite
**Purpose**: Validate stabilization under extreme conditions

**Tests to Implement**:

#### Test A: 1,000-Step Mission
**Track**:
- Identity drift (constitution adherence over time)
- Causal degradation (trace completeness decay)
- Memory corruption (retrieval accuracy decline)
- Confidence inflation (calibration error growth)
- Contradiction accumulation (unresolved count)

**Implementation**:
```python
# tiannara_core/testing/stress_tests.py
def run_1000_step_mission() -> StressTestReport:
    """Execute 1000 reasoning steps, track degradation metrics."""
```

#### Test B: 100-Agent Distributed Cognition
**Track**:
- Coalition formation patterns
- Communication overload (message queue depth)
- Synchronization failures (timeout count)
- Minority suppression (dissent silencing rate)
- Epistemic fragmentation (belief divergence)

**Implementation**:
```python
def run_100_agent_test() -> StressTestReport:
    """Deploy 100 agents on complex task, measure coordination."""
```

#### Test C: False Paradigm Injection ⭐ CRITICAL
**Track**:
- Recovery speed (steps to reject false theory)
- Dissent survival (minority voices preserved)
- Evidence reassessment (re-evaluation thoroughness)
- Confidence correction (overconfidence reduction)

**Implementation**:
```python
def run_false_paradigm_injection() -> StressTestReport:
    """Inject convincing but false theory, measure immune response."""
```

**Additional Tests**:
- D. Memory Corruption Test (inject corrupted memories)
- E. Adversarial Input Test (malicious prompts)
- F. Resource Exhaustion Test (OOM scenarios)
- G. Cascading Failure Test (component failure propagation)

**Files to Create**:
- `tiannara_core/testing/stress_tests.py`
- `tiannara_core/testing/false_paradigm_generator.py`

---

### Task 4.3: Implement Epistemic Audit System
**Purpose**: Safety evaluation before approving evolution

**Audit Checks**:
1. Constitution alignment verification
2. Causal grounding integrity
3. Contradiction resolution completeness
4. Evidence quality assessment
5. Confidence calibration check
6. Drift detection scan
7. Failure pattern matching (compare to Failure Museum)

**Implementation**:
```python
# tiannara_core/sandbox/epistemic_audit.py
class EpistemicAuditor:
    def evaluate_modification(self, sandbox_session) -> AuditReport:
        return AuditReport(
            alignment_score=...,
            causal_integrity=...,
            contradiction_status=...,
            evidence_quality=...,
            calibration_check=...,
            drift_detected=...,
            failure_patterns_matched=...,
            recommendation="APPROVE" | "REJECT" | "NEEDS_REVIEW"
        )
```

**Approval Workflow**:
```
main cognition
    ↓
sandbox branch
    ↓
stress test suite
    ↓
epistemic audit
    ↓
safe merge (if approved)
```

**Files to Create**:
- `tiannara_core/sandbox/epistemic_audit.py`

---

## Phase 5: Execute Long-Duration Stress Tests

**Goal**: Validate all stabilization infrastructure under realistic loads

### Task 5.1: Run 1,000-Step Mission Test
**Duration**: ~2-4 hours
**Success Criteria**:
- Identity drift < 5%
- Causal trace completeness > 90%
- Memory retrieval accuracy > 95%
- Confidence calibration error < 10%
- Unresolved contradictions < 3%

**Monitoring**:
- Real-time dashboard updates every 10 steps
- Alert on threshold violations
- Automatic pause if critical failure detected

**Output**:
- Comprehensive report with graphs
- Recommendations for improvements
- Baseline metrics for future comparisons

---

### Task 5.2: Execute 100-Agent Distributed Cognition Test
**Duration**: ~4-8 hours
**Success Criteria**:
- Coalition formation follows expected patterns
- Communication overhead < 30% of total time
- Synchronization success rate > 95%
- Minority dissent preserved in > 80% of debates
- Epistemic fragmentation index < 0.3

**Monitoring**:
- Live agent communication graph
- Message queue depth over time
- Consensus formation timelines
- Dissent preservation metrics

**Output**:
- Coordination efficiency analysis
- Bottleneck identification
- Scaling recommendations

---

### Task 5.3: Perform False Paradigm Injection Tests
**Duration**: ~1-2 hours per injection
**Number of Tests**: 5-10 different false paradigms
**Success Criteria**:
- Recovery speed < 50 steps average
- Dissent survival rate > 70%
- Evidence reassessment thoroughness > 80%
- Confidence correction within 20% of true value

**Test Scenarios**:
1. Physics: Perpetual motion machine theory
2. Economics: Market always goes up
3. Medicine: Homeopathy effectiveness claim
4. History: Alternative timeline conspiracy
5. Technology: Free energy device

**Monitoring**:
- Belief adoption curves over time
- Dissent voice persistence
- Evidence counter-argument generation
- Confidence adjustment trajectory

**Output**:
- Immune system effectiveness report
- Vulnerability identification
- Improvement recommendations

---

## Implementation Priority Order

### Week 1-2: Observability Foundation
1. ✅ Layer 2: Epistemic Health Dashboard (PRIORITY - prevents invisible drift)
2. ✅ Layer 5: Reality Grounding Dashboard (PRIORITY - prevents delusion)
3. ✅ Task 2.1: Build Telemetry Collector (foundation for all monitoring)

### Week 3-4: Debugging Capability
4. ✅ Task 3.1: Event Logging Infrastructure
5. ✅ Task 3.2: Replay Engine
6. ✅ Task 3.3: Replay Debugger UI

### Week 5-6: Safe Evolution
7. ✅ Task 4.1: Sandbox Environment
8. ✅ Task 4.3: Epistemic Audit System
9. ✅ Layer 3: Evolution Dashboard

### Week 7-8: Stress Testing
10. ✅ Task 4.2: Stress Test Suite
11. ✅ Task 5.1: 1,000-Step Mission Test
12. ✅ Task 5.3: False Paradigm Injection Tests

### Week 9-10: Advanced Features
13. ✅ Layer 1: Cognitive State Visualization
14. ✅ Layer 4: Multi-Agent Coordination Dashboard
15. ✅ Task 5.2: 100-Agent Distributed Cognition Test

### Week 11-12: Integration & Polish
16. ✅ Task 2.2: Telemetry API Endpoints
17. ✅ Task 2.3: Telemetry Dashboard
18. ✅ Cross-layer integration testing
19. ✅ Performance optimization
20. ✅ Documentation & user guides

---

## Success Metrics

### Quantitative Targets:
- **Identity Drift**: < 5% over 1,000 steps
- **Causal Completeness**: > 90% trace retention
- **Memory Integrity**: > 95% retrieval accuracy
- **Confidence Calibration**: < 10% error rate
- **Contradiction Resolution**: < 3% unresolved
- **Dissent Preservation**: > 70% minority voices survive
- **Recovery Speed**: < 50 steps to reject false paradigm
- **Agent Coordination**: > 95% synchronization success

### Qualitative Targets:
- Can visually SEE cognition happening (Layer 1)
- Early warning system for cognitive drift (Layer 2)
- Can replay and debug any past episode (Phase 3)
- Safe evolution workflow prevents corruption (Phase 4)
- Stress tests validate resilience under load (Phase 5)

---

## Risk Mitigation

### Risk 1: Complexity Overload
**Mitigation**: Implement incrementally, one layer at a time. Validate each before proceeding.

### Risk 2: Performance Degradation
**Mitigation**: 
- Telemetry uses async logging
- Replay engine runs offline (doesn't affect live system)
- Sandboxing has resource limits
- Monitor performance metrics during stress tests

### Risk 3: False Positives in Drift Detection
**Mitigation**:
- Calibrate thresholds using baseline data
- Require multiple signals before alerting
- Allow manual override for known edge cases
- Continuously refine detection algorithms

### Risk 4: Sandbox Escape
**Mitigation**:
- Strict resource limits enforced at OS level
- Network isolation for sandbox processes
- Automatic kill switch on violation detection
- Regular security audits of sandbox code

---

## Next Immediate Actions

1. **Start with Layer 2 (Epistemic Health)** - Most critical for preventing invisible drift
2. **Build Telemetry Collector** - Foundation for all longitudinal analysis
3. **Enhance Monitoring Page** - Quick win, integrates existing health metrics
4. **Create Implementation Tasks** - Break down into weekly sprints
5. **Set Up Project Board** - Track progress across all 5 phases

---

## Key Insight from next.md

> "Your bottleneck is no longer reasoning capability. It's **epistemic governance capacity**."
> 
> "The biggest risk is **invisible cognitive drift**."
> 
> "Observability first. If you cannot observe why it changed, why it believed something, why it evolved, why it coordinated - then eventually you lose control."

This implementation plan directly addresses these concerns by building:
- Complete observability (5 dashboard layers)
- Drift detection (epistemic health monitoring)
- Debugging capability (deterministic replay)
- Safe evolution (sandboxing + epistemic audit)
- Validation (stress tests)
