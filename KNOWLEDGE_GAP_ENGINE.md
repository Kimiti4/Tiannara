# Phase 16.2 — Knowledge Gap Engine

## Overview

This document specifies the **Knowledge Gap Engine** used by Phase 16’s autonomous constitutional research pipeline.

It is **specification-only**:
- it defines inputs, outputs, determinism rules, and evidence requirements
- it does not implement runtime code

---

## Mission

Produce explicit, measurable `KnowledgeGap` artifacts that are:

- grounded in the current knowledge graph snapshot
- explicitly linked to contradictions, uncertainty, missing evidence, failed predictions, or engineering blockers
- equipped with closure criteria and evidence-collection targets

Every research program in Phase 16 must begin from one of these knowledge gaps.

---

## Inputs (Immutable Artifacts)

1. **Knowledge Graph Snapshot**
   - content-addressed theory/evidence graph nodes and edges
2. **Evidence Coverage Map**
   - which predicted outcomes, observations, measurements have evidence coverage
3. **Contradiction Signals**
   - detected inconsistencies between competing theories/claims/predictions
4. **Prediction Failure Records**
   - records of failed predictions (optional but supported)
5. **Engineering Bottleneck Signals**
   - constraints/opportunities that block progress (optional but supported)

All inputs are immutable artifacts referenced by content hashes.

---

## Outputs (KnowledgeGap Artifacts)

Each output is a `KnowledgeGap` content-addressed artifact with:

- `gap_type`
- domain + description
- `current_confidence` and `target_confidence`
- `evidence_requirements` with minimum quantities and required quality
- optional:
  - `contradicting_claim_ids`
  - `unresolved_prediction_ids`
  - `engineering_bottleneck`

---

## Knowledge Gap Derivation Rules

### 1) Uncertainty gaps
A knowledge gap is created when:
- confidence is below the target threshold OR
- uncertainty interval width exceeds the target reduction target.

Derivation uses deterministic aggregation over evidence coverage.

### 2) Contradiction gaps
A gap is created when:
- two or more theory/claim states conflict under defined evaluation semantics
- and existing evidence is insufficient to resolve the conflict.

The gap includes:
- the contradicting claim IDs
- what evidence would discriminate between them

### 3) Missing evidence gaps
A gap is created when:
- a knowledge graph edge/prediction requires evidence type `E`
- but evidence coverage map lacks sufficient evidence quantity/quality for `E`.

### 4) Failed prediction gaps
A gap is created when:
- historical predictions were made with explicit measurement definitions
- the observed outcomes fall outside tolerance thresholds
- replayable comparison indicates systematic deviation.

### 5) Engineering blocker gaps
A gap is created when:
- engineering constraints prevent execution of certain scientific programs
- evidence requirements cannot be satisfied without addressing the engineering bottleneck.

---

## Closure Criteria (Required)

Every `KnowledgeGap` MUST include:

1. **Quantitative target**
   - `target_confidence` (or equivalent numeric confidence metric)
2. **Evidence collection targets**
   - `evidence_requirements` specifying:
     - minimum quantity
     - required quality
3. **Discriminator definition** (for contradictions)
   - which evidence would resolve the conflict (implicit in requirements)

If any closure criterion is missing, the gap is invalid and cannot be used to generate research questions.

---

## Determinism Rules

- Inputs are ordered by artifact ID lexicographic order.
- Aggregations are deterministic and free of non-deterministic floating formats.
- If multiple candidate gaps are tied:
  - select outputs in deterministic sorted order by content hash.
- Randomness, if used for proposal sampling, must be derived from:
  - content hashes of the knowledge graph snapshot and config.

---

## Failure Semantics

The engine must not silently degrade.

If required inputs are missing, it emits explicit failure artifacts:

- `ENGINE_INPUT_MISSING`
- `EVIDENCE_COVERAGE_UNAVAILABLE`
- `CONTRADICTION_UNEVALUABLE`
- `CONFIDENCE_METRIC_UNDEFINED`

Those failures must be replayable and audit-friendly.

---

## Summary

`KNOWLEDGE_GAP_ENGINE.md` specifies how Phase 16 builds explicit, measurable knowledge gaps from immutable knowledge and evidence coverage artifacts, ensuring that autonomous research begins from a constitutionally certified origin.
