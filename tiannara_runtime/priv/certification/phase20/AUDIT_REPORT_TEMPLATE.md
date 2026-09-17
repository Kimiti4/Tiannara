# Audit Report Template (Phase 20.96)

## Audit: [Audit Title]
## Auditor: [Auditor Identity]
## Date: Deterministic generation timestamp

---

### 1. Audit Metadata
- Audit ID: Content-addressed identifier computed from the artifact contents
- Scope Reference: [AuditScope ID]
- Independence Declaration: Binary verification result
- Cold Storage Root Hash: Content-addressed SHA-256 hash of the certified artifact
- Audit Start Timestamp: [deterministic]
- Audit End Timestamp: [deterministic]

### 2. Scope Coverage
- Subsystems Audited: [list]
- Generations Audited: [list]
- Audit Types Performed: [Replay/Evidence/Hash/Structure/Dependency/Lineage/Full]
- Total Artifacts in Scope: Total count
- Artifacts Actually Audited: Total count
- Coverage: [N%]

### 3. Summary Results
| Metric | Value |
|--------|-------|
| Total artifacts verified | Total count |
| Artifacts passed | Total count |
| Artifacts failed | Total count |
| Artifacts unverifiable | Total count |
| Replay chains verified | Total count |
| Replay chains failed | Total count |
| Evidence chains verified | Total count |
| Evidence chains failed | Total count |
| Hash matches | Total count |
| Hash mismatches | Total count |
| Findings (total) | Total count |
| Critical findings | Total count |
| Major findings | Total count |
| Minor findings | Total count |
| Observations | Total count |
| Determinism score | [0.0–1.0] |
| Integrity score | [0.0–1.0] |
| Overall verdict | [Pass/ConditionalPass/Fail] |

### 4. Subsystem Results
| Subsystem | Artifacts | Verified | Failed | Deterministic | Replayable | Verdict |
|-----------|-----------|----------|--------|---------------|------------|---------|
| [name] | Total count | Total count | Total count | Yes/No | Yes/No | Intact/Compromised |

### 5. Critical Findings
| Finding ID | Subsystem | Description | Severity | Recommendation |
|-----------|-----------|-------------|----------|---------------|
| [id] | [name] | [description] | Critical | [recommendation] |

### 6. Major Findings
| Finding ID | Subsystem | Description | Severity | Recommendation |

### 7. Minor Findings & Observations
| Finding ID | Subsystem | Description | Severity | Recommendation |

### 8. Replay Verification
- Full OS replay: Verification outcome
- Subsystem replays: [N passed / N failed]
- Campaign replays: [N passed / N failed]
- Generation replays: [N passed / N failed]
- Root hash match: Binary verification result
- Reconstructed root: Content-addressed SHA-256 hash of the certified artifact
- Expected root: Content-addressed SHA-256 hash of the certified artifact

### 9. Determinism Verification
- Subsystems deterministic: Passing count over total count
- Non-determinism sources found: [list or none]
- Non-determinism severity: [None/Minor/Major/Critical]

### 10. Constitutional Invariants
| Invariant | Status | Detail |
|-----------|--------|--------|
| Determinism | ✓/✗ | |
| Replayability | ✓/✗ | |
| Hash chain continuity | ✓/✗ | |
| Evidence completeness | ✓/✗ | |
| Knowledge preservation | ✓/✗ | |
| Scientific capital preservation | ✓/✗ | |
| Generation lineage | ✓/✗ | |
| Schema conformance | ✓/✗ | |
| Dependency completeness | ✓/✗ | |
| Certificate validity | ✓/✗ | |

### 11. Independence Confirmation
- Runtime not used: Binary verification result
- Cold storage isolated: Binary verification result
- Dual audit performed: Binary verification result
- Dual audit agreement: [Yes/No/Partial]
- Independence score: [0.0–1.0]

### 12. Conclusion & Recommendations
[Summary of audit findings, overall assessment, and recommendations for remediation or certification.]

### 13. Audit Certificate
- Certificate ID: [if issued]
- Certificate Status: [Issued/Pending/Denied]
- Certificate Hash: Content-addressed SHA-256 hash of the certified artifact
