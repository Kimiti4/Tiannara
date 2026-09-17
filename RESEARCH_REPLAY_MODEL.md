# Phase 16.2 — Research Replay Model (Determinism + Archaeology)

## Overview

This document defines the **replay model** for Phase 16 Autonomous Constitutional Research.

It specifies how autonomous research artifacts are deterministically replayed from immutable artifacts, how reconstruction is verified, and how archaeological lineage proofs are validated.

This is **specification-only** (no runtime implementation).

---

## 1) Replay Objectives

A replay system must be able to:

1. **Reconstruct** every derived research artifact from immutable inputs:
   - knowledge gaps
   - question generation outputs
   - prioritization outputs
   - research program plans
   - experiment and simulation design artifacts
   - evidence bundles (when evidence is replayable)
   - statistical validation outputs (when validation is replayable)
   - theory update proposals
   - lineage proofs

2. **Verify determinism**:
   - content-addressed IDs match expected values
   - Merkle roots and hash chains are consistent

3. **Verify constitutional compliance**:
   - no integration/acceptance occurs without certified gates

4. **Support independent audit**:
   - evidence-only auditors can replay the proof chain without importing runtime code or mutable state.

---

## 2) Replay Inputs (Immutable Artifact Set)

Replay consumes only the following immutable artifacts:

- **Research Ledgers**
  - append-only logs of stage transitions and decisions
- **Evidence Artifacts**
  - normalized evidence bundles, content-addressed
- **Frozen Research Contracts**
  - schemas, API contracts, deterministic rules, replay levels
- **Certificates**
  - replay certificates and audit certificates (when available)
- **Lineage Proof Artifacts**
  - `DISCOVERY_LINEAGE.json`-style proofs (Phase 16.6 will define structure)

Replay must not depend on:
- mutable databases
- network access
- local clocks (except timestamps embedded in artifacts)
- hidden runtime caches/state

---

## 3) Replay Levels

Replay is required in distinct verification levels (determinism depth).

### LEVEL1 — Hash Equality
- Recompute content-addressed IDs for all specified artifacts.
- Require exact canonical serialization equality.

### LEVEL2 — Semantic Equality
- For derived outputs where raw floating values may be serialized differently:
  - compare results with deterministic tolerances OR normalized representations.
- Still require ID equality for canonicalized fields.

### LEVEL3 — Structural Pipeline Equality
- Re-run full stage pipeline in deterministic mode.
- Verify intermediate artifacts and stage outputs match expected canonical outputs.

---

## 4) Canonical Serialization Contract

For determinism, all artifacts must define canonical serialization:

1. **Stable key ordering** in JSON.
2. **Canonical number formatting** rules (no NaN, no locale formatting).
3. **Deterministic array ordering**:
   - either arrays are modeled in deterministic order
   - or canonical ordering keys are included in the schema
4. **No implicit fields**:
   - missing vs null vs empty must be canonicalized according to schema rules

Canonicalization errors are considered replay failures.

---

## 5) Deterministic Replay Constraints (Autonomous Decisions)

Every autonomous decision that affects the research outcome must be derived from:
- frozen config
- immutable artifact inputs
- deterministic scoring/tie-break functions

### Tie-breaking rule
When multiple options share equal score, the selection is:
- lexicographic ordering over `artifact_id` hashes.

---

## 6) Replay Outputs

A replay run outputs:

1. `ReplayVerificationResult`
   - list of verified artifact IDs
   - mismatch report (if any)
2. `ReplayMerkleRootProof`
   - Merkle roots computed over a canonical set of replayed artifacts
3. `ReplayDivergenceReport`
   - structured explanation of divergences:
     - stage name
     - input hash set
     - differing output hash set
     - earliest divergence artifact

---

## 7) Replay Divergence Handling

If replay mismatches are detected:

- replay returns FAIL_CLOSED:
  - independent auditor can’t accept results
- divergence report must be included as evidence:
  - earliest divergence points must be explainable

A divergence must never be silently corrected via heuristics in replay verification.

---

## 8) Archaeological Reconstruction Contract

Replay must also produce a reconstructability proof that answers:

- **Why** was a research question generated?
- **From which** knowledge gap?
- **Which** scoring function prioritized it?
- **Which** program plan and evidence requirements were chosen?
- **Which** experiments were designed and why?
- **Which** evidence and statistics led to the theory update proposal?
- **Which** certificates gated acceptance/integration?

Archaeology requires lineage trace completeness for each accepted stage output.

---

## 9) Replay Certificate Request Semantics (Spec Level)

Phase 16 produces `ReplayCertificationRequest` artifacts (Phase 16.0/16.7 describes requests).

Replay certification request includes:

- artifact set required to replay
- required replay levels (LEVEL1/2/3)
- independence constraints:
  - verifier identity must differ from executor identity (later implementation)

Only after successful replay certification may the system issue knowledge acceptance artifacts.

---

## 10) Independent Evidence-only Replay

The evidence-only auditor executable must be able to replay:

- any artifact whose derivation is defined as replayable from immutable inputs
- and must refuse to proceed if:
  - inputs required for reconstruction are missing
  - certificate prerequisites are not satisfied
  - replay levels cannot be met

---

## Summary

This replay model guarantees:

- deterministic reconstruction of autonomous research outputs
- content-addressed ID verification
- replay divergence evidence for audit
- archaeological explainability
- evidence-only independent audit readiness

No implementation is provided in this document.
