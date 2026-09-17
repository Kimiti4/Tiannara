# Phase 20.0 — Architectural Discovery Specification

## Overview

Architectural Discovery is the CER function that generates candidate architectures capable of resolving identified bottlenecks. Discovery may produce candidates across any architectural domain.

## Candidate Types

- New algorithms (reasoning, planning, learning, optimization)
- New runtimes (specialized execution environments)
- New schedulers (resource allocation, prioritization)
- New memory systems (representations, storage, retrieval)
- New mathematical frameworks (formalisms, notations, tools)
- New planning systems (representation, search, execution)
- New scientific workflows (experimentation, validation, discovery)
- New interfaces (communication protocols, integration points)
- New subsystems (independent architectural units)

## Constitutional Constraint

No candidate may bypass constitutional review. Every candidate, regardless of perceived urgency, triviality, or benefit, must enter the evolution pipeline at Stage 1 (Observation).

## Candidate Specification

Every candidate must specify:

### Architecture
Complete structural description including components, interfaces, data flows, dependencies, and integration points with existing subsystems.

### Expected Improvement
Quantitative prediction of the improvement the candidate will produce, measured against the bottleneck it addresses. Must include confidence intervals.

### Risks
Complete risk assessment including:
- Failure modes
- Regression risks
- Integration risks
- Security risks
- Constitutional compliance risks
- Unknown unknowns

### Simulation Plan
Detailed plan for simulating the candidate architecture, including:
- Simulation environment requirements
- Key metrics to measure
- Comparison baselines
- Duration and scale

### Benchmark Criteria
Specific, measurable benchmarks the candidate must pass to proceed through the evolution pipeline. Must include:
- Pass/fail thresholds
- Comparison against current architecture
- Minimum improvement thresholds
- Adversarial benchmark specifications

## Discovery Methods

Architectural Discovery may use:
- Analytical derivation from bottleneck analysis
- Generative architecture synthesis
- Evolutionary search over architectural space
- Transfer from external research
- Human expert input

All discovery methods are documented and replayable. No ad-hoc or undocumented discovery is permitted.
