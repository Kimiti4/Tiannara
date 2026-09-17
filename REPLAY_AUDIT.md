# Phase 16.0 Pre-Implementation Constitutional Audit — REPLAY_AUDIT

## Scope
Spec-level audit of the Phase 16 replay model to ensure it is:

- deterministic
- replayable from immutable artifacts only
- archaeologically explainable
- certification-gate compatible
- divergence-handling fail-closed

Audited artifact:
- `RESEARCH_REPLAY_MODEL.md`

---

## Replay Model Checklist

### R1 — Replay Inputs Are Immutable
Requirement: replay must consume only immutable artifacts.

Evidence (in spec):
- `RESEARCH_REPLAY_MODEL.md` defines inputs as:
  - research ledgers
  - evidence artifacts
  - frozen research contracts
  - certificates (when available)
  - lineage proof artifacts

Pass/Fail:
- **PASS** (replay input set is defined as immutable and content-addressed oriented)

---

### R2 — Replay Does Not Depend on Runtime State
Requirement: no mutable DB, no network, no hidden runtime caches.

Pass/Fail:
- **PASS**
- Replay constraints explicitly forbid:
  - mutable databases
  - network access
  - local clocks (except embedded timestamps)
  - hidden runtime state

---

### R3 — Canonical Serialization Contract Exists
Requirement: canonical serialization rules are defined for determinism.

Pass/Fail:
- **PASS**
- Includes:
  - stable key ordering
  - missing vs null preserved
  - deterministic array ordering rules
  - deterministic number formatting

---

### R4 — Determinism Tie-breaking Is Defined
Requirement: if scores tie, selection must be deterministic.

Pass/Fail:
- **PASS**
- Tie-breaking rule is specified:
  - lexicographic ordering by `artifact_id` hash

---

### R5 — Replay Outputs Are Verifiable
Requirement: replay produces verification results and divergence reports.

Pass/Fail:
- **PASS**
- Replay outputs defined:
  - `ReplayVerificationResult`
  - `ReplayMerkleRootProof`
  - `ReplayDivergenceReport`

---

### R6 — Divergence Handling Is Fail-Closed
Requirement: any mismatch yields failure states and evidence, not silent correction.

Pass/Fail:
- **PASS**
- Spec requires FAIL_CLOSED semantics and divergence report inclusion.

---

### R7 — Archaeology Reconstruction Requirements Exist
Requirement: replay must answer why/from/through which/which certificates.

Pass/Fail:
- **PASS**
- Archaeological reconstruction is explicitly described:
  - why question generated
  - mapping from evidence → validation → theory proposals → certificates
  - lineage root hash compatibility

---

### R8 — Independence Constraints for Evidence-only Audit
Requirement: independent audit must not import runtime.

Pass/Fail:
- **PASS (partial at this stage)**
- Replay model describes boundaries, and independent evidence-only audit is specified elsewhere:
  - `RESEARCH_CERTIFICATION.md` / future `INDEPENDENT_RESEARCH_AUDIT.md` (not yet present)

---

## Findings

### F1 — Missing Independence Details at Replay Certificate Level
- Replay model mentions independence constraints later, but Phase 16.0 does not yet include a concrete evidence-only audit executable spec.

Severity:
- **WARNING**
- Converts to **BLOCKER** only when implementing evidence-only audit executable contract.

---

## Conclusion
The Phase 16 replay model is internally consistent and defines:

- canonical serialization
- determinism rules
- replay outputs
- fail-closed divergence semantics
- archaeological reconstruction requirements

The remaining missing artifact (`INDEPENDENT_RESEARCH_AUDIT.md`) is the main gap for completing the end-to-end replay + evidence-only audit loop.
