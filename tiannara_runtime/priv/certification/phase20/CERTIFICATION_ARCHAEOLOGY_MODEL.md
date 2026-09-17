# Certification Archaeology Model (Phase 20.999)

## Purpose

Define the archaeology model for the CSOS v1.0 certification. Certification archaeology answers the essential questions about why certification was granted and how it can be independently reconstructed.

## Seven Essential Questions

| Question | Answer Source |
|----------|--------------|
| Why was certification granted? | Certification decision logic + evidence review |
| Which evidence supported certification? | All evidence package references (20.95–20.98) |
| Which validation campaigns passed? | Phase 20.95 campaign results |
| Which audits verified the system? | Phase 20.96 audit verdicts |
| Which readiness dimensions were satisfied? | Phase 20.98 dimension scores |
| Which constitutional invariants were demonstrated? | All 10 invariant verification results |
| How can the certification be independently reconstructed? | Complete replay chain + reconstruction instructions |

## Archaeology Artifacts

| Artifact | Content | Hash Reference |
|----------|---------|---------------|
| Evidence review record | Summary of all evidence evaluated | evidence_review_hash |
| Decision record | Certification decision + rationale | decision_hash |
| Freeze record | FoundationalFreeze record | freeze_hash |
| Baseline record | FoundingBaseline record | baseline_hash |
| Archive index | ArchiveIndex record | archive_hash |
| Replay package | CertificationReplay record | replay_hash |
| Certificate | CSOSCertificate record | certificate_hash |

## Archaeology Chain

```
Evidence Review → Decision → Freeze → Baseline → Archive → Replay → Certificate
     hash[1]     hash[2]   hash[3]  hash[4]    hash[5]   hash[6]   hash[7]
                                                                        ↓
                                                              ARCHAEOLOGY_ROOT
```

## Independence

Certification archaeology can be independently verified:
- Any party can reconstruct the certification from artifacts
- No runtime required — only cold storage
- All hashes must match the recorded certification
- Reconstruction instructions are included in the archive
