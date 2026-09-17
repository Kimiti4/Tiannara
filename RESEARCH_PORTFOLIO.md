# Phase 16.5 — Research Portfolio Optimization

## Overview

This document specifies the **Research Portfolio Optimization** contract for Phase 16 autonomous constitutional research.

It is **specification-only**:
- defines deterministic scoring functions
- defines portfolio selection rules
- defers execution implementation

---

## Mission

Given a set of candidate research programs (planned from questions) and frozen constraints, deterministically select a portfolio that maximizes:

- expected scientific capital contribution
- uncertainty reduction
- engineering impact
- novelty
- feasibility
- novelty vs feasibility tradeoffs
- resource cost compliance

All decisions must be replayable and transparent.

---

## Inputs (Immutable)

1. Candidate set:
   - list of `ResearchProgram` artifacts
2. Candidate derived metrics (immutable, stored in priority/program):
   - expected uncertainty reduction
   - estimated scientific capital contribution
   - estimated cost
   - feasibility score hints
   - engineering impact hints
   - novelty hints
3. Frozen portfolio selection configuration:
   - weights per objective
   - hard constraints:
     - max compute units
     - max evidence budget
     - max experiments per epoch
     - dependency constraints ordering
   - tie-breaking rules

---

## Outputs

A deterministic ordered list of selected programs:

- `ResearchPortfolio` (logical output)
  - `selected_program_ids[]` (ordered)
  - `total_cost`
  - `portfolio_score`
  - per-program score decomposition transparency record
  - justification hash / proof record (for replay/audit readiness)

> Note: The file does not introduce a new schema file; it references `RESEARCH_DATA_MODEL.md` where applicable. If you later want a dedicated `ResearchPortfolio` schema, we can add it in Phase 16.1.

---

## Scoring Model (Deterministic)

### 1) Objective Components

For each program `p`:

- `U(p)` = expected uncertainty reduction
- `C(p)` = expected scientific capital contribution
- `E(p)` = engineering impact
- `N(p)` = novelty
- `F(p)` = feasibility
- `K(p)` = estimated cost (resource cost)

### 2) Total Score

Deterministic scoring function (frozen):

```text
Score(p) =
  wU * norm(U(p)) +
  wC * norm(C(p)) +
  wE * norm(E(p)) +
  wN * norm(N(p)) +
  wF * norm(F(p)) -
  wK * norm(K(p))
```

Where:
- `w*` are fixed frozen weights from configuration
- `norm(*)` is a deterministic normalization mapping defined by config:
  - e.g., min-max normalization from candidate set or fixed domain normalization
  - must be deterministic given the immutable candidate set

### 3) Transparency fields

For auditability each program’s score must include:
- each normalized component contribution
- raw component values used
- weight values used
- normalization range inputs (or normalization method id)

All transparency fields must be content-addressed.

---

## Portfolio Selection Contract

### A) Dependency constraints
- If `ResearchProgram` has dependencies:
  - the selected set must respect dependency closure rules.

### B) Hard budget constraints
- The portfolio must satisfy:
  - sum of cost across selected programs ≤ budget bounds

### C) Deterministic selection algorithm
A deterministic greedy algorithm is specified:

1. sort candidate programs by:
   - descending `Score(p)`
   - tie-break by lexicographic `program_id`
2. iterate through sorted programs:
   - add program if it does not violate hard constraints and dependency closure
3. stop when adding any remaining program would violate constraints

This must be deterministic.

---

## Replay Requirements

- portfolio ordering must be replayable from:
  - candidate program artifacts
  - frozen config
  - deterministic normalization rules
- tie-breaking must be by artifact ids only.

Any deviation is a replay failure.

---

## Failure Semantics

If inputs are insufficient:

- `PORTFOLIO_INPUT_MISSING`
- `PORTFOLIO_BUDGET_UNDEFINED`
- `PORTFOLIO_NORMALIZATION_UNDETERMINED`
- `PORTFOLIO_SCORING_CONFIG_UNFROZEN`

Failures must be explicit artifacts.

---

## Summary

`RESEARCH_PORTFOLIO.md` defines deterministic portfolio selection that is transparent, replayable, and certification-ready—forming the constitutional bridge between question generation and research execution planning.
