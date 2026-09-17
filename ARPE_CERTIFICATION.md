# Phase 17.8.0 — ARPE Certification Framework (CAR)

document_version: 17.8.0
phase: 17.8
status: Architecture Review
owner: Constitutional Research Council
depends_on:
  - AUTONOMOUS_RESEARCH_PROGRAM_ARCHITECTURE.md
  - RESEARCH_EXECUTION_PIPELINE.md
  - RESEARCH_PROGRAM_DATA_MODEL.md
  - ARPE_REPLAY_MODEL.md
  - RESEARCH_CERTIFICATION.md (Phase 16.4 — extended)
  - PHASE15_FINAL_CERTIFICATION.md
  - PHASE16_FINAL_CERTIFICATION.md
supersedes: null

---

## Purpose

This document specifies the Phase 17.8 certification framework architecture.

It defines certificate types, certification gates, the independent audit design,
and the final certification package structure for the ARPE subsystem.

This is a constitutional architecture document. No implementation is introduced here.
No certificates are issued here.

---

## Fundamental Rule

**Phase 17.8 inherits Phase 16's certification principle verbatim:**

No autonomous research output becomes accepted knowledge without a valid certificate.
No certificate is valid without replayable evidence referenced by immutable IDs.

Phase 17.8 adds: no certificate is CERTIFIED (as opposed to PROVISIONAL) while
Phase 16 certification remains WITHHELD.

---

## 1. Certificate Hierarchy

Phase 17.8 operates within the existing certificate hierarchy:

```
Phase 15 DiscoveryCertificate
    ↑ consumed by
Phase 16 ResearchProgramCertificate
    ↑ consumed by
Phase 17.8 ARPECertificate
```

Phase 17.8 ARPECertificate is the terminal certificate in this chain for ARPE outputs.

No Phase 17.8 certificate is issued without valid prerequisite certificates in the chain.

---

## 2. Certificate Types

### 2.1 ARPECertificate

The terminal constitutional certificate for a completed autonomous research program.

**Contents (architecture-level fields — schema defined in Phase 17.8.1):**
- certificate_id (content-addressed, blake3)
- schema_version: "17.8.0"
- subject_type: ARPE_RESEARCH_PROGRAM
- program_id (content-addressed)
- outcome_id (content-addressed)
- replay_fingerprint_id (content-addressed)
- archaeology_record_id (content-addressed)
- independent_audit_id (content-addressed)
- math_verification_id (content-addressed)
- statistical_validation_ids (content-addressed list)
- phase_16_upstream_status: CERTIFIED | WITHHELD | PENDING
- certificate_status: CERTIFIED | PROVISIONAL | WITHHELD
- issuer_id
- issuer_signature (Ed25519)
- timestamp

**certificate_status rules:**
- CERTIFIED: all gates pass AND Phase 16 upstream is CERTIFIED
- PROVISIONAL: all ARPE-internal gates pass BUT Phase 16 upstream is WITHHELD or PENDING
- WITHHELD: any ARPE-internal gate fails

**Generators never certify themselves.** The ConstitutionalCertificateAuthority is
independent of the ARPEProgramEngine and all ARPE runtime modules.

---

### 2.2 ARPEReplayCertificate

Attests that a program's ProgramReplayFingerprint has been verified to the
required replay levels.

**Contents:**
- replay_certificate_id (content-addressed)
- program_id
- fingerprint_id
- levels_certified: [LEVEL1, LEVEL2, LEVEL3]
- merkle_root_verified: boolean
- divergence_absent: boolean
- issuer_id
- timestamp

---

### 2.3 ARPEAuditCertificate

Issued by the independent evidence-only auditor after successful reconstruction.

**Contents:**
- audit_certificate_id (content-addressed)
- program_id
- audit_report_id
- reconstruction_modes_completed: [LEDGER_RECONSTRUCTION, EVIDENCE_CLOSURE, REPLAY_CONSISTENCY, ARCHAEOLOGY_EXPLAINABILITY]
- evidence_closure_verified: boolean
- archaeology_completeness: COMPLETE | PARTIAL | INCOMPLETE
- issuer_id (must differ from any ARPE runtime module identity)
- timestamp

---

## 3. Certification Gates (Ordered)

Phase 17.8 certification is fail-closed through these gates in order.
Any gate failure blocks all subsequent gates.

### Gate 0 — Upstream Dependency Check
Required:
- Phase 16 contracts are frozen (RESEARCH_RUNTIME_FREEZE.md exists)
- Phase 15 is CERTIFIED (PHASE15_FINAL_CERTIFICATION.md status = CERTIFIED)
- Phase 17.7 Digital Twin runtime is implemented (DigitalTwinEngine present)

Pass: all above present
Fail: produce DependencyGateFail artifact — no further certification

Note: Phase 16 WITHHELD does not block Gate 0 — it is acknowledged as a risk
and results in PROVISIONAL certificates, not gate failure. Phase 16 WITHHELD
blocks the upgrade from PROVISIONAL to CERTIFIED.

---

### Gate 1 — Architectural Freeze Check
Required:
- AUTONOMOUS_RESEARCH_PROGRAM_ARCHITECTURE.md (this phase's CAR, status = PASS)
- RESEARCH_EXECUTION_PIPELINE.md (status = Architecture Review)
- RESEARCH_PROGRAM_DATA_MODEL.md (status = Architecture Review)
- ARPE_REPLAY_MODEL.md (status = Architecture Review)
- ARPE_CERTIFICATION.md (this document, status = Architecture Review)
- AUTONOMOUS_RESEARCH_RUNTIME_FREEZE.md (Phase 17.8.05, after freeze)

Pass: all above exist
Fail: produce ArchitectureFreezeGateFail — no implementation may proceed

---

### Gate 2 — Ontology and Schema Certification
Required:
- AUTONOMOUS_RESEARCH_SCHEMA_REPORT.md (Phase 17.8.1)
- All Phase 17.8 schemas validated: content-addressed IDs, serialization,
  validators, canonical ID correctness for all 9 new entities

Pass: AUTONOMOUS_RESEARCH_SCHEMA_REPORT.md exists and all audits pass
Fail: produce SchemaGateFail

---

### Gate 3 — Mathematical Verification Gate
Required:
- All experiments in the program have a MathematicalVerificationResult
- At minimum, all results have status: VERIFIED or MATHEMATICALLY_UNVERIFIED
  (VERIFICATION_FAILED blocks this gate)

Pass: no VERIFICATION_FAILED in program's math verification results
Fail: produce MathVerificationGateFail

Note: MATHEMATICALLY_UNVERIFIED is a gate-pass-with-warning — it produces
a PROVISIONAL certificate, not a full CERTIFIED.

---

### Gate 4 — Statistical Validation Gate
Required:
- ResearchStatisticalValidation exists for all experiments
- Validation conclusion != INCONCLUSIVE for all required experiments
- Alpha, power, and confidence interval targets from ResearchProgram are satisfied

Pass: all statistical requirements met
Fail: produce StatisticalGateFail

---

### Gate 5 — Replay Certification Gate
Required:
- ProgramReplayFingerprint exists for the program
- Replay levels LEVEL1 and LEVEL3 both achieved
- No divergence report present (or all divergences documented and explained)
- ARPEReplayCertificate issued

Pass: ARPEReplayCertificate present with levels_certified = [LEVEL1, LEVEL2, LEVEL3]
Fail: produce ReplayCertificationGateFail

---

### Gate 6 — Archaeological Completeness Gate
Required:
- ProgramArchaeologyRecord exists for the program
- explanation_completeness = COMPLETE
- All entities have Explain() coverage (see ownership map in architecture doc)
- missing_explanation_nodes = []

Pass: ProgramArchaeologyRecord with explanation_completeness = COMPLETE
Fail: produce ArchaeologyGateFail (with missing_explanation_nodes as evidence)

---

### Gate 7 — Independent Evidence-Only Audit Gate
Required:
- Independent auditor executable consumes only immutable artifacts
- ARPEAuditCertificate issued with:
  - reconstruction_modes_completed = all four modes
  - evidence_closure_verified = true
  - archaeology_completeness = COMPLETE
- Auditor identity != any ARPE runtime module identity

Pass: ARPEAuditCertificate present and valid
Fail: produce IndependentAuditGateFail

---

### Gate 8 — Phase 16 Upstream Status Check
This gate determines the final certificate_status:

- If Phase 16 = CERTIFIED → certificate_status = CERTIFIED
- If Phase 16 = WITHHELD or PENDING → certificate_status = PROVISIONAL
- PROVISIONAL certificates are valid for archiving and internal research use
- PROVISIONAL certificates are not valid for external publication or inter-phase integration
  until upgraded to CERTIFIED after Phase 16 certifies

---

## 4. Certification Process (Protocol)

```
ARPEProgramEngine produces ResearchOutcome
    ↓
ConstitutionalCertificateAuthority receives certification request
    ↓
Gate 0: Upstream dependency check
    ↓
Gate 1: Architecture freeze check
    ↓
Gate 2: Schema check
    ↓
Gate 3: Math verification check
    ↓
Gate 4: Statistical validation check
    ↓
Gate 5: Replay certification
    ↓
Gate 6: Archaeological completeness
    ↓
Gate 7: Independent audit
    ↓
Gate 8: Phase 16 upstream status
    ↓
Compute certificate content hash
    ↓
Sign with issuer key
    ↓
Register in CertificateRegistry (append-only)
    ↓
Emit CertificateIssuedEvent
    ↓
Update ProgramRegistry with certificate_id
```

---

## 5. Certificate Revocation Architecture

Certificates are revocable under the following conditions:
- Replay divergence discovered post-certification
- Evidence fraud detected
- Phase 16 certificate revoked (upstream)
- Mathematical verification failure discovered post-certification
- Archaeology reconstruction failure discovered post-certification

Revocation is append-only:
- RevocationRecord is appended to the CertificateRegistry
- The original certificate artifact is never deleted
- All downstream certificates that depend on the revoked certificate are
  automatically flagged for review (RevocationCascadeRecord)

---

## 6. Phase 17.8.999 Final Certification Package

The final Phase 17.8 certification (for the subsystem, not individual programs) requires:

| Deliverable | Gate |
|---|---|
| AUTONOMOUS_RESEARCH_PROGRAM_ARCHITECTURE.md | Architecture frozen |
| AUTONOMOUS_RESEARCH_RUNTIME_FREEZE.md | Freeze complete (17.8.05) |
| AUTONOMOUS_RESEARCH_SCHEMA_REPORT.md | Ontology certified (17.8.1) |
| AUTONOMOUS_EXPERIMENT_PLANNER.md | Planning spec complete (17.8.3) |
| RESEARCH_PORTFOLIO_OPTIMIZATION.md | Portfolio spec complete (17.8.4) |
| AUTONOMOUS_SCHEDULER.md | Scheduler spec complete (17.8.5) |
| AUTONOMOUS_THEORY_EVOLUTION.md | Theory evolution spec complete (17.8.6) |
| AUTONOMOUS_RESEARCH_ARCHAEOLOGY.md | Archaeology complete (17.8.7) |
| AUTONOMOUS_RESEARCH_MATHEMATICS.md | Math verification complete (17.8.8) |
| AUTONOMOUS_RESEARCH_VALIDATION.md (17.8-scoped) | Validation campaigns passed (17.8.95) |
| INDEPENDENT_AUTONOMOUS_RESEARCH_AUDIT.md | Independent audit passed (17.8.96) |
| AUTONOMOUS_RESEARCH_CERTIFICATE.json | Final certificate (17.8.999) |
| AUTONOMOUS_RESEARCH_FREEZE.md | Final freeze seal |
| AUTONOMOUS_RESEARCH_FINAL_REPORT.md | Final report |
| AUTONOMOUS_RESEARCH_PROOF.json | Cryptographic proof |
| PHASE17_8_FINAL_CERTIFICATION.md | Final certification decision |

Final decision: CERTIFIED or WITHHELD. Never partial.

---

## 7. Relationship to Phase 18

Phase 17.8 certification is a prerequisite for Phase 18 (Constitutional Cognitive
Operating System).

Phase 18 integrates all scientific, engineering, reasoning, governance, and learning
capabilities. It requires a CERTIFIED or PROVISIONAL Phase 17.8 certificate to consume
ARPE outputs.

Phase 18 must not begin until Phase 17.8 achieves at minimum PROVISIONAL certification.

---

## 8. CAR Compliance

Certification framework satisfies all Phase 17.8.0 CAR requirements:

- Certificate hierarchy is explicit and non-circular
- ConstitutionalCertificateAuthority is independent of runtime
- Certificate gates are ordered and fail-closed
- Revocation is append-only and cascades correctly
- PROVISIONAL vs CERTIFIED distinction handles Phase 16 upstream risk
- Final certification package is fully specified
- No implementation introduced
- No certificates issued in this document
