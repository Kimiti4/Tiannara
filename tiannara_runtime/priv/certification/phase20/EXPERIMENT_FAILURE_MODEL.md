# Phase 20.7 — Experiment Failure Model

## Role

The Experiment Failure Model defines every failure mode that can occur during the experiment lifecycle, the deterministic response to each failure, and the complete evidence preservation requirements.

## Failure Categories

### 1. Design Failures
Failures detected during experiment design or constitutional review.

| Failure | Detection Point | Response |
|---------|-----------------|----------|
| Unfalsifiable hypothesis | Design | Reject; require falsifiable hypothesis |
| Undefined variables | Design | Reject; require complete variable specification |
| Missing controls | Design | Reject; require control specification |
| Insufficient power | Design | Return for redesign with larger sample |
| Unsafe design | Constitutional review | Reject; document safety concerns |
| Resource budget exceeded | Constitutional review | Return for budget reduction |
| Mathematical inconsistency | Constitutional review | Escalate to mathematics runtime |

### 2. Resource Failures
Failures during resource reservation or execution.

| Failure | Detection Point | Response |
|---------|-----------------|----------|
| Insufficient compute | Reservation | Defer until resources available |
| Insufficient memory | Reservation | Defer or reduce scope |
| Resource exhaustion during execution | Execution | Pause, capture partial results, terminate |
| Budget overrun | Execution | Terminate, flag for analysis |

### 3. Execution Failures
Failures during experiment execution.

| Failure | Detection Point | Response |
|---------|-----------------|----------|
| Environment initialization failure | Execution start | Abort; restore to pre-execution state |
| Treatment application error | Execution | Abort; capture partial observations |
| Observation collection failure | Execution | Capture partial data; flag missing observations |
| Determinism violation | Execution | Abort; flag for investigation |
| Safety limit reached | Execution | Immediate abort; preserve all state |

### 4. Analysis Failures
Failures during statistical analysis.

| Failure | Detection Point | Response |
|---------|-----------------|----------|
| Assumption violation | Analysis | Use non-parametric alternative; flag deviation |
| Insufficient data | Analysis | Classify as inconclusive |
| Invalid statistics | Analysis | Recompute with corrected method |
| Contradictory observations | Analysis | Flag for meta-analysis |

### 5. Reproducibility Failures
Failures during reproducibility verification.

| Failure | Detection Point | Response |
|---------|-----------------|----------|
| Hash mismatch in replay | Reproducibility | Mark experiment as non-reproducible |
| Different observations | Reproducibility | Mark as non-reproducible; investigate |
| Different statistics | Reproducibility | Mark as non-reproducible; investigate |
| Different classification | Reproducibility | Mark as non-reproducible; investigate |

### 6. Integration Failures
Failures during knowledge integration.

| Failure | Detection Point | Response |
|---------|-----------------|----------|
| Knowledge inconsistency | Integration | Abort integration; flag for manual review |
| Theory conflict | Integration | Document conflict; preserve both |
| Confidence degradation | Integration | Flag for meta-analysis |

## Failure Response Protocol

All failures follow the same deterministic response:

1. **Detect**: Identify failure condition via deterministic check
2. **Record**: Capture complete failure evidence (state, inputs, outputs, error)
3. **Classify**: Assign failure category and severity
4. **Respond**: Execute deterministic response (abort, defer, flag, recompute)
5. **Preserve**: Store all failure artifacts immutably
6. **Notify**: If constitutional threshold, notify governance

## Fail-Closed Principle

When any failure is detected, the experiment fails closed:

- No partial results are used for knowledge integration
- No evidence from a failed experiment updates any model
- Failed experiments are fully preserved for forensic analysis
- Failed experiments may be re-attempted after root cause resolution
- Re-attempted experiments restart from Stage 1 (Proposal)

## Failure Archaeology

Every failure produces:

| Artifact | Description |
|----------|-------------|
| Failure record | Failure type, category, severity, timestamp |
| State at failure | Complete state snapshot at failure point |
| Error diagnostics | Structured error information |
| Partial results | Any observations collected before failure |
| Replay evidence | Replay chain showing exact failure path |
