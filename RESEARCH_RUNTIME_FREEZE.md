# Phase 16.05 — Research Runtime Freeze (Spec-only)

document_version: 16.06.0

phase: 16

status: Frozen

owner: Constitutional Research Council

depends_on:
  - RESEARCH_DATA_MODEL.md
  - RESEARCH_PIPELINE.md

supersedes: null

## Overview

This document defines the **Phase 16.05 constitutional freeze** for the autonomous constitutional research runtime.

Per Phase 16 discipline:
- **documentation-only**
- no runtime implementation is introduced here
- this file freezes **contracts, schemas, behaviors, and deterministic replay boundaries** that are prerequisites for runtime implementation in later phases.

---

## 0) Frozen Specification Markers

**Frozen at:** `PHASE16.05`

**Related Freeze Artifacts**
- `RESEARCH_FREEZE_CERTIFICATE.json` (template/spec artifact)
- `RESEARCH_DATA_MODEL.md`
- `RESEARCH_PIPELINE.md`
- `RESEARCH_REPLAY_MODEL.md`
- `RESEARCH_CERTIFICATION.md`

---

## 1) What “Frozen” Means

A component is frozen iff all of the following are fixed for the epoch:

1. **Schemas**
   - JSON structure and required fields
   - canonical serialization rules
2. **Behavior contracts**
   - allowed inputs/outputs
   - determinism requirements
   - error semantics
3. **API surfaces**
   - function signatures / request-response fields
4. **Replay prerequisites**
   - which stage outputs are replay-critical
   - required replay levels
5. **Evidence mapping rules**
   - how raw execution outputs map to evidence bundles
6. **Constitutional compliance gates**
   - which conditions block transitions

Anything not explicitly frozen is non-binding and may change in later epochs.

---

## 2) Frozen Contracts (Spec-level APIs)

### 2.1 ResearchPlanner
Creates deterministic `ResearchProgram` artifacts from `ResearchPriority` and `KnowledgeGap`.

**Frozen API contract** (conceptual)
- `plan(program_inputs) -> ResearchProgram`

**Determinism rules**
- tie-breaking by content hash ordering
- no external state reads

---

### 2.2 QuestionGenerator
Creates deterministic `ResearchQuestion` artifacts from `KnowledgeGap`.

**Frozen API contract**
- `generate_questions(gap_inputs) -> [ResearchQuestion]`

**Determinism rules**
- derived seeds must be content-hash derived

---

### 2.3 PortfolioManager
Selects a deterministic portfolio of research programs/questions.

**Frozen API contract**
- `select_portfolio(priorities, constraints) -> [ResearchProgram]`

**Determinism rules**
- objective function + tie-breaking are fixed

---

### 2.4 ResearchScheduler (spec contract only)
Produces deterministic dispatch intents.

**Frozen API contract**
- `schedule(programs, resource_policy) -> [DispatchIntent]`

**Constitutional boundary**
- scheduling produces intents only; execution is not part of Phase 16 runtime freeze.

---

### 2.5 EvidenceCollector
Defines deterministic evidence normalization mapping.

**Frozen API contract**
- `normalize(execution_output, experiment_spec) -> ResearchEvidence`

**Replay requirement**
- evidence normalization must be replayable from immutable execution outputs (later implementation).

---

### 2.6 StatisticalValidationEngine (spec contract only)
Defines deterministic statistical validation outputs.

**Frozen API contract**
- `validate(evidence_bundle, validation_spec) -> ResearchStatisticalValidation`

**Replay requirement**
- validation outputs must be replay-verifiable.

---

### 2.7 TheoryUpdater
Creates deterministic `ResearchTheoryUpdateProposal` from validated outputs.

**Frozen API contract**
- `propose_update(stat_validation, theory_snapshot, certification_prereqs) -> ResearchTheoryUpdateProposal`

**Gate rule**
- must reference required certificate prerequisites (no implied acceptance).

---

### 2.8 ReplayVerifier (spec contract only)
Verifies determinism for requested artifacts.

**Frozen API contract**
- `verify_replay(artifact_set, replay_levels) -> ReplayVerificationResult`

---

### 2.9 CertificateIssuer (spec boundary)
Certificate issuance is **protocol-managed** and must remain detached from scientific judgment.

**Frozen behavior rule**
- issuer verifies criteria satisfaction from immutable artifacts and emits certificate outputs.

Implementation deferred.

---

## 3) Frozen Stage Transitions & Gates

The following stage transitions MUST NOT occur unless gates pass:

1. `THEORY_UPDATE_PROPOSAL` is allowed after:
   - statistical validation artifacts exist
   - mapping from evidence bundles is present
2. Knowledge integration/inclusion is allowed only after:
   - `ResearchProgramCertificate` acceptance prerequisites exist
   - independent evidence-only audit passed
   - replay certification succeeded
3. `FREEZE` is allowed only after:
   - replay certification artifacts exist (or are referenced)
   - research readiness/certification readiness artifacts exist

---

## 4) Replay-critical Outputs (Frozen List)

For the Phase 16 epoch, the following outputs are replay-critical:
- `KnowledgeGap`
- `ResearchQuestion`
- `ResearchPriority`
- `ResearchProgram` (plan + requirements)
- `ResearchExperiment` (design + evidence mapping)
- `ResearchEvidence` (normalized bundle)
- `ResearchStatisticalValidation`
- `ResearchTheoryUpdateProposal`
- lineage proofs (`DISCOVERY_LINEAGE.json` structure)

If replay verification is requested for a program, these outputs must be reproducible.

---

## 5) Constitutional Error Semantics (Frozen)

On any determinism or evidence-mapping failure, the runtime must:
- return explicit failure artifacts (not silent correction)
- preserve divergence metadata for archaeology

Canonical failure classes:
- `EVIDENCE_NOT_REPLAYABLE`
- `EVIDENCE_MAPPING_AMBIGUITY`
- `CANONICAL_SERIALIZATION_ERROR`
- `REPLAY_DIVERGENCE`
- `CERTIFICATE_PREREQ_MISSING`

---

## Dependency Graph

```
RESEARCH_DATA_MODEL
        │
        ▼
RESEARCH_PIPELINE
        │
        ▼
RESEARCH_REPLAY_MODEL
        │
        ▼
RESEARCH_CERTIFICATION
        │
        ▼
RESEARCH_RUNTIME_FREEZE
        │
        ▼
AUTONOMOUS_RESEARCH_VALIDATION
```

---

## Frozen Interfaces Appendix

### Frozen Schemas

Observation, Question, Hypothesis, Experiment, Theory, Research Portfolio, Knowledge Gap, Research Certificate

### Frozen APIs

ObservationRegistry, QuestionGenerator, HypothesisEngine, ExperimentPlanner, TheoryEngine, ReplayEngine, KnowledgeGraph, ScientificCapital

### Frozen Behaviors

ObservationBehaviour, HypothesisBehaviour, ExperimentBehaviour, TheoryBehaviour, ReplayBehaviour, CertificateBehaviour

---

## No Implementation Note

This document is a freeze spec.

Runtime implementation must begin only after:
- ontology and data model freezes exist
- replay model is validated for determinism
- independent evidence-only audit design is frozen
- Phase 16.999 final certification package is produced

---

## Summary

`RESEARCH_RUNTIME_FREEZE.md` freezes the contracts and replay-critical boundaries for the Phase 16 autonomous constitutional research runtime.

No implementation is included.

