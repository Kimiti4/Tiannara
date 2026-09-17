# Phase 16.4 — Research Planning Engine

## Overview

This document specifies the **Research Planning Engine** used by Phase 16 autonomous constitutional research.

It is **specification-only**:
- defines deterministic planning inputs/outputs
- defines frozen stopping criteria and evidence requirements
- defers execution implementation

---

## Mission

Given:
- explicit `ResearchQuestion` artifacts
- frozen constitutional constraints
- deterministic portfolio constraints

Produce:
- `ResearchProgram` artifacts that include:
  - objectives and milestones
  - experiment/simulation plan hashes
  - evidence requirements per milestone
  - statistical validation requirements
  - stopping criteria
  - replay and certification prerequisites

No program becomes eligible for later execution/integration unless its plan is fully reconstructable from immutable artifacts.

---

## Inputs (Immutable)

1. `ResearchQuestion`
2. Frozen planning configuration:
   - mapping of required validation types
   - evidence schema IDs allowed for the epoch
   - cost budgets mapping
3. Optional context (immutable references):
   - `ResearchPriority` scoring transparency hints
   - known constraints from engineering bottleneck metadata

---

## Outputs (ResearchProgram)

A `ResearchProgram` artifact MUST include all required fields defined by `RESEARCH_DATA_MODEL.md`:

- `research_program_id`
- `primary_question_id`
- `objectives[]`
- `milestones[]` (with evidence bundle expectations and stopping rules)
- `experiments[]`
- `evidence_requirements[]`
- `statistical_requirements` (alpha/power/confidence targets)
- `stopping_criteria[]`
- `resource_constraints`

---

## Planning Determinism Rules

Planning must be deterministic given identical inputs:

1. **Milestone generation**
   - milestone ordering is deterministic (sorted by milestone key hash)
2. **Evidence requirements selection**
   - derived purely from:
     - knowledge gap type
     - question stop/continue criteria
     - required validation types
3. **Statistical requirement derivation**
   - alpha/target_power/confidence targets are computed deterministically from:
     - question uncertainty reduction target
     - evidence budget bounds
4. **Resource constraints**
   - computed from estimated cost model inputs (deterministic)
5. **Tie-breaking**
   - all ambiguous choices resolve by artifact id lexicographic ordering

---

## Milestones & Stopping Criteria

Each milestone defines:

- expected evidence bundle id (may be `null` until evidence exists)
- stopping rule reference:
  - the program may stop early only if:
    - required stopping criteria are satisfied under deterministic evidence evaluation semantics
- evidence mapping keys:
  - the program plan MUST define which evidence fields map to measurement definitions

---

## Experiment Design Hooks (Spec-only)

The planner produces:
- experiment design references (hashes) that will be concretized by a later stage (Phase 16.0/architecture).

The planner MUST specify:

- which measurements are required
- which evidence types are expected
- what robustness/sensitivity diagnostics will be required

---

## Certification Prerequisites (Spec)

Every planned `ResearchProgram` MUST declare:

- replay prerequisite levels required for certification
- certificate compatibility constraints:
  - only accept certificate types defined in `RESEARCH_CERTIFICATION.md`

This prevents “plan drift” where execution uses undefined certificate gates.

---

## Failure Semantics

If any planning prerequisite cannot be satisfied, emit explicit failure artifacts:

- `PLAN_INVALID_INPUT`
- `STOPPING_CRITERIA_UNMEASURABLE`
- `EVIDENCE_REQUIREMENTS_INCOMPLETE`
- `STATISTICAL_REQUIREMENTS_UNSPECIFIED`
- `CERTIFICATION_PREREQ_UNDEFINED`

Failures must be replayable from the same immutable inputs.

---

## Summary

`RESEARCH_PLANNER.md` specifies how Phase 16 transforms explicit, measurable research questions into fully reconstructable research programs with deterministic milestones, evidence requirements, statistical validation targets, and certification prerequisites.
