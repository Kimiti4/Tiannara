# Phase 20.7 — Autonomous Experimentation Architecture

## Role

The Autonomous Experimentation Architecture governs how Tiannara designs, schedules, executes, analyzes, and archives engineering experiments under constitutional control. Every experiment is deterministic, replayable, statistically valid, and archaeologically preserved.

## Constitutional Principle

Every experiment is a constitutional event. It must have a defined purpose, hypothesis, prediction, variables, constraints, safety assumptions, mathematical justification, and statistical validity requirements. No experiment may execute outside this framework.

## Interaction with Previous Phases

| Phase | Relationship |
|-------|-------------|
| 15 (Discovery) | Experiments validate discoveries; discovery observations may trigger experiments |
| 16 (Research) | Experiments test research hypotheses; research programs propose experiment campaigns |
| 16.X (Mathematics) | Experiments require mathematical justification; results may update mathematical models |
| 17 (World Models) | Experiments use world models for simulation; results may refine world models |
| 18 (Cognitive OS) | Experiments test cognitive hypotheses; results inform cognitive architecture |
| 20.0–20.5 (Runtime Evolution) | Experiments validate runtime evolution candidates before integration |
| 20.6 (Autonomous Engineering) | Engineering designs produce experiment plans; experiments validate engineering artifacts |
| **20.7** | **Governs autonomous design, execution, analysis, and archiving of experiments** |

## System Boundaries

- Engineering (20.6) proposes experiments; experiments do not directly modify engineering artifacts
- Experiments produce evidence that feeds back into engineering, discovery, and research
- Experiment results are one-way into knowledge — they do not directly modify the runtime
- All experiments go through constitutional review before execution

## Architecture Overview

```
Experiment Proposal (from Engineering, Discovery, Research, or Runtime Evolution)
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│             Autonomous Experimentation Framework             │
│                                                             │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ Experiment Design│→│ Experiment        │                │
│  │ Engine           │  │ Scheduler        │                │
│  └──────────────────┘  └────────┬─────────┘                │
│                                 ▼                          │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ Execution        │→│ Analysis Engine   │                │
│  │ Model            │  │                  │                │
│  └──────────────────┘  └────────┬─────────┘                │
│                                 ▼                          │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ Reproducibility  │→│ Certification    │                │
│  │ Verification     │  │                  │                │
│  └──────────────────┘  └────────┬─────────┘                │
│                                 ▼                          │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ Replay Model     │  │ Archaeology      │                │
│  │                  │  │ Model            │                │
│  └──────────────────┘  └──────────────────┘                │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Failure Model │ Safety Gates │ Resource Budgets     │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
Experiment Results → Evidence Chain → Knowledge Integration
```

## Experiment Lifecycle

```
Proposal → Constitutional Review → Resource Reservation → Environment Preparation
    → Execution → Observation Capture → Statistical Analysis → Result Classification
    → Reproducibility Verification → Knowledge Integration → Archaeology → Freeze
```

All 12 stages must complete in order. No stage may be skipped.

## Constitutional Contracts

Every experiment must define:

| Contract | Description |
|----------|-------------|
| Purpose | What question this experiment answers |
| Hypothesis | Falsifiable statement being tested |
| Prediction | Quantitative predicted outcome |
| Variables | Independent, dependent, and controlled variables |
| Constraints | Resource, safety, and scope constraints |
| Safety assumptions | Conditions under which experiment is safe |
| Required resources | Compute, memory, time, and domain budgets |
| Mathematical justification | Formal reasoning supporting the design |
| Statistical assumptions | Distribution, power, significance thresholds |
| Expected confidence | Predicted confidence interval of results |

## Safety Rules

| Condition | Response |
|-----------|----------|
| Resource exhaustion | Fail closed; preserve partial results |
| Invalid assumptions | Abort; flag for redesign |
| Unsafe experiment | Reject at constitutional review |
| Missing controls | Reject as incomplete |
| Non-reproducible results | Mark as inconclusive; preserve evidence |
| Contradictory observations | Flag for meta-analysis |
| Invalid statistics | Discard analysis; recompute |
| Mathematical inconsistency | Abort; escalate to mathematics runtime |
