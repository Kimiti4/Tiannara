# Phase 16.3 — Autonomous Question Generation

## Overview

This document specifies the **Question Generation Engine** for Phase 16 autonomous constitutional research.

It is **specification-only**:
- it defines deterministic derivation rules
- it defines required fields and closure/gating semantics
- it defers runtime implementation

---

## Mission

Generate `ResearchQuestion` artifacts from explicit `KnowledgeGap` artifacts such that:

- each question has an explicit uncertainty-reduction target
- the expected impact and cost are quantified for portfolio optimization
- dependencies and stopping criteria are explicit
- required validation types are declared up front

---

## Inputs (Immutable)

1. `KnowledgeGap` artifacts (content-addressed)
2. Frozen constitutional research configuration:
   - weighting parameters for question scoring
   - allowed validation types
   - tie-breaking rules
3. Optional context:
   - evidence coverage map (for dependency derivation)
   - engineering constraints (for cost estimation)

---

## Outputs (ResearchQuestion artifacts)

For each `KnowledgeGap`, produce one or more `ResearchQuestion` artifacts.

Each `ResearchQuestion` MUST include:
- `question_id`
- `knowledge_gap_id`
- `expected_uncertainty_reduction`
- `estimated_impact`
- `estimated_cost.compute_units`
- `estimated_cost.evidence_budget`
- `dependencies`
- `required_validation_types`
- `stopping_criteria`

---

## Question Derivation Rules

### 1) Uncertainty reduction targeting
Given:
- `KnowledgeGap.current_confidence`
- `KnowledgeGap.target_confidence`

Compute:
- `expected_uncertainty_reduction`
  - defined as monotonic improvement towards the target threshold
  - must be deterministic and derived from gap metrics

### 2) Expected impact estimation
Impact is derived from:
- gap domain salience (domain weight from frozen config)
- expected effect on theory confidence / resolution speed
- portfolio novelty/feasibility hints

Must be deterministic and reproducible from:
- gap_type
- domain
- closure requirements

### 3) Cost estimation
Compute deterministic cost from:
- evidence requirements (quantity, required quality)
- measurement complexity proxy (derived from measurement definitions in the gap metadata)
- compute budget proxy

Cost MUST be a bounded estimate (no unbounded scaling in spec).

### 4) Dependencies
A question declares dependencies on:
- upstream lineage artifacts
- contradicting claim IDs / unresolved prediction IDs (if present)
- any required engineering blocker resolution items (if present)

Dependencies must be content-addressed IDs.

### 5) Required validation types
The gap type determines required validation types:

- `UNCERTAINTY` or `MISSING_EVIDENCE`
  - require `STATISTICAL`
  - require `ROBUSTNESS`
- `CONTRADICTION`
  - require `STATISTICAL`, `ROBUSTNESS`
  - require `REPLAY` prereq
  - require `AUDIT` prereq
- `ENGINEERING_BLOCKER`
  - require `ROBUSTNESS` + `AUDIT`
  - may require `REPLAY` based on determinism risk

The mapping is frozen in config.

### 6) Stopping criteria
Stopping criteria must be measurable:

- thresholds on:
  - achieved confidence
  - reduction in uncertainty metrics
  - evidence quantity/quality meeting minimum requirements

---

## Determinism Rules

- Given identical inputs and frozen config, question generation MUST output identical questions:
  - content-addressed IDs match
  - ordering is deterministic by content-hash

- If multiple questions are proposed per gap:
  - selection is deterministic (rank + tie-breaking by artifact id)

---

## Failure Semantics

If inputs are insufficient or invalid, emit explicit failure artifacts:

- `GAP_INVALID`
- `GAP_CLOSURE_UNDEFINED`
- `COST_MODEL_UNAVAILABLE`
- `VALIDATION_TYPE_MAPPING_UNAVAILABLE`

Failures must be replayable.

---

## Summary

`QUESTION_GENERATION.md` specifies deterministic generation of research questions from explicit knowledge gaps, ensuring Phase 16 autonomous discovery is evidence-first, replayable, and certification-bound.
