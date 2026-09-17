# Phase 18.8 — Meta-Cognitive Control: Architecture

## Overview

Phase 18.8 implements a **self-monitoring pipeline** that enables the runtime to observe, calibrate, and assess its own cognitive processes. This is a read-only introspection layer — no self-modification is performed at this stage.

## Pipeline Stages

```
CognitiveState → ConfidenceCalibration → UncertaintyPropagation → HealthAssessment → EscalationDecisions → ConstitutionalIntrospection
```

### 1. Cognitive State Acquisition
Raw internal state snapshots are collected from active cognitive processes. Includes active task queues, resource usage, inference buffers, and decision stacks.

### 2. Confidence Calibration
Measures alignment between the system's internal confidence estimates and observed outcome correctness. Produces calibration curves and flags miscalibration.

### 3. Uncertainty Propagation
Distinguishes between aleatoric (data-inherent) and epistemic (model-knowledge) uncertainty. Propagates uncertainty estimates through the decision chain.

### 4. Health Assessment
Evaluates cognitive health across multiple dimensions: load, error density, latency variance, resource pressure, and stability index.

### 5. Escalation Decisions
Maps health assessment scores to escalation levels (info, warning, critical, emergency). Determines whether human oversight should be notified.

### 6. Constitutional Introspection
Compares internal decisions against constitutional principles. Produces introspection findings documenting alignment or deviation.

## Design Principles

- **No self-modification**: The pipeline observes only. All outputs are recorded as evidence.
- **Deterministic replay**: Every stage produces replay artifacts that can reconstruct its state.
- **Temporal archaeology**: Archived snapshots enable post-hoc analysis of past meta-cognitive states.
