# Phase 16.96 — Independent Research Audit (Spec)

document_version: 16.06.0

phase: 16

status: Frozen

owner: Constitutional Research Council

depends_on:
  - RESEARCH_RUNTIME_FREEZE.md
  - AUTONOMOUS_RESEARCH_VALIDATION.md

supersedes: null

## Purpose
Specify the **evidence-only independent audit** that validates Phase 16 autonomous constitutional research outputs **without importing runtime state**.

This audit is the independent evidence-first mechanism that prevents knowledge coupling, replay shortcuts, or certification by narrative.

---

## Constitutional Constraints (Hard Rules)

The independent audit executable (implementation later) must:

1. **Consume only immutable artifacts**
   - research ledgers
   - evidence artifacts
   - lineage artifacts
   - statistical validation artifacts
   - freeze manifests / contracts
2. **Not import runtime modules**
   - no runtime library imports
   - no shared in-memory state from the research engine
3. **Not trust computed hashes without reconstruction**
   - verify content-addressed IDs by recomputation from canonical serialization rules
4. **Emit evidence-based audit reports**
   - outputs must be derived only from immutable inputs
   - no “pass” without recorded reconstruction steps

---

## Audit Modes

### Mode A — Ledger Reconstruction
- Reconstruct the research pipeline decisions from:
  - knowledge gap inputs
  - question generation outputs
  - planning and experiment design
  - evidence bundles references
  - statistical validation references
- Produce a reconstruction ledger trace with deterministic ordering.

### Mode B — Evidence Closure Verification
- Verify that every claimed knowledge integration prerequisite has:
  - evidence bundle references
  - statistical validation references
  - lineage proof references
- Fail closed:
  - if any evidence reference is missing/unresolvable, emit a failure certificate

### Mode C — Replay Consistency Check (Artifact-Level)
- Where replay outputs are included as artifacts, verify:
  - hash equality match flags
  - divergence reports are consistent with deterministic replay requirements
- Do not re-run execution beyond replay where artifacts are explicitly provided.

### Mode D — Archaeological Explainability Check
- For each autonomous decision node:
  - identify provenance chain
  - ensure lineage reconstructs “why/from/through which evidence”
- Emit an archaeology coverage summary:
  - complete / partial / missing reconstruction nodes

---

## Input Inventory Contract (Audit Inputs)

The audit consumes a fixed set of immutable artifacts. At spec time, this document defines the expected semantic inputs:

- Research ledgers (append-only traces for the autonomous cycle)
- Evidence bundles and evidence identifiers
- Statistical validation artifacts
- Research lineage artifacts (e.g., `DISCOVERY_LINEAGE.json`-compatible schema)
- Freeze artifacts and frozen contract manifests
- Replay certification inputs if present as artifacts

> Issued certification artifacts are optional at audit time; the audit validates evidence closure and reconstruction completeness. If certification artifacts exist, the audit verifies them against evidence.

---

## Output Contract (Audit Outputs)

The audit must emit:

1. `IndependentAuditReport` (evidence-only)
   - reconstruction status per stage
   - evidence closure success/failure per research program
   - archaeology coverage summary
   - deterministic artifact hash verification log
2. `AuditCertificate` (issued later, evidence-derived)
   - content-addressed certificate ID
   - signed/attested issuer identity (later implementation)
   - references to audit report artifacts
   - validity conditions (freeze boundaries, replay level, evidence closure)

Concrete issued filenames are intentionally deferred until later phases; Phase 16.96 defines the *semantic contract*.

---

## Fail-Closed Semantics (Spec)

The audit returns failure if:

- any immutable artifact referenced by lineage is missing
- any evidence bundle hash cannot be validated by canonical reconstruction
- any knowledge acceptance prerequisite lacks evidence + statistical validation references
- archaeology reconstruction fails for any required node type

Partial pass is permitted only when the audit explicitly emits:
- `MISSING_NODE_TYPE`
- `MISSING_EVIDENCE_REFERENCE`
- `ARCHAEOLOGY_RECONSTRUCTION_GAP`

---

## Relationship to Acceptance Criteria

This audit directly supports acceptance requirements that:
- autonomous decisions are deterministic and replayable
- evidence-only independent auditors can reconstruct outputs
- no hidden runtime state bypasses certification
- every output is archaeologically explainable

---

## Frozen Interfaces Appendix

### Frozen Schemas

Observation, Question, Hypothesis, Experiment, Theory, Research Portfolio, Knowledge Gap, Research Certificate

### Frozen APIs

ObservationRegistry, QuestionGenerator, HypothesisEngine, ExperimentPlanner, TheoryEngine, ReplayEngine, KnowledgeGraph, ScientificCapital

### Frozen Behaviors

ObservationBehaviour, HypothesisBehaviour, ExperimentBehaviour, TheoryBehaviour, ReplayBehaviour, CertificateBehaviour

---

## Status
Spec-only. No implementation is introduced in Phase 16.96.
