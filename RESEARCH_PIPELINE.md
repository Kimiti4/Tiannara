# Phase 16 — Autonomous Constitutional Research Pipeline

## Overview

This document specifies the **autonomous constitutional research pipeline** for Phase 16.

It is **specification-only**: no runtime implementation is introduced here. The pipeline defines deterministic stage contracts, immutable ledger boundaries, evidence-first gates, replay certification boundaries, and freeze semantics.

---

## Non-negotiable Constitutional Discipline (Phase 16)

1. **Explicit Knowledge Gap Start**
   - Every research program originates from a measurable `KnowledgeGap`.
2. **Content-addressed artifacts**
   - Questions, programs, plans, experiments, evidence bundles, statistical results, certificates, and lineage proofs are content-addressed.
3. **Deterministic replay**
   - All autonomous decisions are replayable from immutable artifacts only.
4. **Evidence-only independent audit**
   - Independent audit consumes only immutable artifacts and emits an audit certificate.
5. **No knowledge without constitutional lifecycle**
   - No autonomous output becomes accepted knowledge without completing the full lifecycle and certification gates.

---

## Pipeline Output Contract

For each autonomous research cycle, the pipeline produces append-only ledger entries and content-addressed artifacts:

- `KnowledgeGap`
- `ResearchQuestion`
- `ResearchPriority`
- `ResearchProgram`
- `ResearchExperiment` (design + simulation specs)
- `ResearchEvidence` (bundled + normalized)
- `ResearchStatisticalValidation` (deterministic statistical outputs)
- `ResearchTheoryUpdateProposal`
- `ResearchOutcome` (the program outcome and disposition)
- `DiscoveryLineage` entries / lineage proofs
- `ReplayCertificationRequest` (not issued certificates yet—issuance happens at certification gate)
- `AuditReadinessArtifact` (immutable bundle for later evidence-only audit)

---

## Deterministic Stage Model

Each stage is defined as a deterministic transformation:

```text
stage_input_hashes  --(frozen config + deterministic rules)-->  stage_outputs
```

### Determinism requirements
- No network calls during pipeline derivation (later execution phases may run, but spec defines contracts).
- No wall-clock dependent logic.
- Tie-breaking uses content-hash ordering.
- Any randomness is derived from content-addressed seeds.

---

## Stage Index (Constitutional Lifecycle Mapping)

### Stage A — OBSERVE_LEDGER
**Input**
- immutable research ledgers
- frozen protocol configuration

**Output**
- derived stage context:
  - current unresolved `KnowledgeGap`s
  - candidate programs and their status
  - evidence coverage map
  - confidence/uncertainty coverage map

**Gate**
- If a candidate is missing required immutable references, the pipeline must not proceed.

---

### Stage B — GENERATE_KNOWLEDGE_GAPS
**Input**
- snapshot of the knowledge graph and evidence coverage

**Output**
- `KnowledgeGap` artifacts, each including:
  - missing evidence description
  - contradictory/competing theoretical states (if any)
  - uncertainty metrics and targets
  - evidence collection targets (what must be collected to close the gap)

**Gate**
- Every gap must have measurable closure criteria.

---

### Stage C — GENERATE_RESEARCH_QUESTIONS
**Input**
- `KnowledgeGap` artifacts

**Output**
- `ResearchQuestion` artifacts including:
  - expected impact (scientific value)
  - uncertainty reduction target
  - estimated cost
  - dependencies
  - stopping conditions
  - required statistical validation type(s)

**Gate**
- Questions must be reproducible from `(KnowledgeGap + frozen config)`.

---

### Stage D — PRIORITIZE_QUESTIONS
**Input**
- generated questions
- portfolio selection contract inputs

**Output**
- `ResearchPriority` records containing:
  - deterministic score components
  - total score
  - transparency fields (what evidence/uncertainty/cost drove the score)
  - dependencies ordering constraints

**Gate**
- Ranking must be deterministic with content-hash tie-breaking.

---

### Stage E — PLAN_RESEARCH_PROGRAMS
**Input**
- prioritized questions
- resources + constraints from constitution

**Output**
- `ResearchProgram` artifacts including:
  - objectives and milestones
  - planned experiments and simulation specs
  - evidence requirements per milestone
  - stopping criteria
  - statistical requirements (alpha/confidence/power/robustness targets)
  - planned replay verification level requirements

**Gate**
- Every experiment design must specify evidence mapping keys required for reconstruction.

---

### Stage F — DESIGN_EXPERIMENTS_AND_SIMULATIONS
**Input**
- `ResearchProgram` plans

**Output**
- `ResearchExperiment` artifacts including:
  - sampling/measurement definitions (deterministic where specified)
  - simulation parameterization + derived seeds
  - robustness stress test design:
    - what assumptions are stressed
    - how sensitivity is measured
  - mapping schema from raw execution outputs → `ResearchEvidence`

**Gate**
- Any ambiguity in evidence mapping must be converted into explicit `EvidenceCollectionFailure` artifacts (so the pipeline can generate follow-up questions later).

---

### Stage G — SCHEDULE_AND_DISPATCH (Spec Contract Only)
**Input**
- experiment artifacts
- deterministic resource allocation plan

**Output**
- immutable dispatch intent entries that later execution will use

**Gate**
- Dispatch intent must be fully determined by hashes and frozen configuration.
- Actual execution happens after all freeze/certification specs are satisfied.

---

### Stage H — COLLECT_EVIDENCE_AND_NORMALIZE
**Input**
- executed run outputs (later implementation)
- evidence normalization contract

**Output**
- `ResearchEvidence` bundles:
  - normalized evidence records
  - content-addressed evidence IDs
  - provenance fields referencing experiment design hashes

**Gate**
- Evidence bundles must be reconstructable from immutable artifacts only.

---

### Stage I — RUN_STATISTICAL_VALIDATION
**Input**
- `ResearchEvidence` bundles
- statistical validation contract inside the frozen program plan

**Output**
- statistical validation artifacts including:
  - validation results
  - confidence intervals and uncertainty summaries
  - robustness/sensitivity diagnostics
  - deterministic statistical result hashes

**Gate**
- Outputs must be replay-verifiable and certificate-ready.

---

### Stage J — PRODUCE_THEORY_UPDATE_PROPOSALS
**Input**
- statistical validation artifacts
- current theory state snapshot (as immutable references)

**Output**
- `ResearchTheoryUpdateProposal` artifacts describing:
  - operation: `NEW | REVISE | SUPERSEDE | CONTRADICT | MERGE | DEPRECATE`
  - supporting discovery hashes
  - contradicting evidence hashes (if applicable)
  - justification hash
  - prerequisites (certificate requirements)

**Gate**
- No integration proposal is allowed to imply knowledge acceptance without certificate chain references.

---

### Stage K — REQUEST_REPLAY_CERTIFICATION
**Input**
- evidence + validation + proposal

**Output**
- `ReplayCertificationRequest` artifacts:
  - what must be replayed
  - replay levels required
  - verifier constraints (independent verifier identity later)

**Gate**
- Replay requests reference immutable bundles only.

---

### Stage L — INDEPENDENT_EVIDENCE_ONLY_AUDIT (Spec Contract)
**Input**
- immutable evidence + lineage + replay outputs + pending certificate inputs

**Output**
- evidence-only `IndependentAuditReport` artifacts and `AuditCertificate` later

**Gate**
- The audit executable consumes **no runtime imports** and **imports only immutable artifacts**.

---

### Stage M — FREEZE
**Input**
- certification gate results

**Output**
- immutable freeze marker artifacts:
  - final research certificate bundle
  - freeze manifest
  - archaeology lineage proofs

**Gate**
- Once frozen, research program results become eligible for integration in later phases.

---

## Replay Certification Boundary (Pipeline Rule)

A pipeline-run may emit “certification-ready” artifacts only after:

- all statistical validation artifacts are produced deterministically
- all evidence bundles are content-addressed and reconstructable
- lineage proofs reference every upstream decision/input hash

Then and only then may the pipeline request replay certification and independent evidence-only audit.

---

## Summary

Phase 16’s pipeline is designed to guarantee:

- deterministic autonomous research decision-making
- explicit knowledge-gap origins
- deterministic statistical validation
- evidence-first certification gates
- independent evidence-only audit
- replay certification and freeze before Phase 17

No runtime implementation is introduced by this specification.
