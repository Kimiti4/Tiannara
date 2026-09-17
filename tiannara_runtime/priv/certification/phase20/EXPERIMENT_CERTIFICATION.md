# Phase 20.7 — Experiment Certification

## Role

Experiment Certification is the constitutional gate that validates an experiment's results for knowledge integration. No experiment results may update theories, models, or knowledge without a valid ExperimentCertificate.

## Certification Requirements

### Pipeline Completeness
- All 12 pipeline stages completed in order
- No stage skipped or bypassed
- All stage artifacts present, valid, and replay-verified

### Design Validity
- Experiment design is constitutionally compliant
- All variables are defined and controlled
- Controls are appropriate for the hypothesis
- Sample size meets statistical power requirements

### Execution Integrity
- Execution completed without unresolved failure
- Observations are complete and uncorrupted
- Execution trace is consistent with the experiment plan
- All safety limits were respected

### Statistical Validity
- Statistical assumptions were verified
- Appropriate tests were applied
- Multiple comparison corrections were applied
- Power analysis confirms adequate sensitivity

### Reproducibility
- Full pipeline reproducibility verified
- All hashes match at all stages
- Reproducibility report confirms reproducibility level
- Cold storage replay produces identical results

### Constitutional Compliance
- Determinism confirmed
- Replayability confirmed
- Archaeology completeness confirmed
- Evidence-based decisions confirmed
- No governance bypass

### Audit Clearance
- Results are independently verifiable
- No unresolved critical or major findings
- All assumptions are documented and justified
- Limitations are documented

## Certification Document

The ExperimentCertificate contains:

| Field | Description |
|-------|-------------|
| certificate_id | Content-addressed identifier |
| experiment | Reference to experiment |
| design_root | Root hash of design chain |
| execution_root | Root hash of execution chain |
| analysis_root | Root hash of analysis chain |
| reproducibility_root | Root hash of reproducibility chain |
| certificate_hash | SHA-256 of certificate canonical form |
| classification | Result classification (confirmed/refuted/inconclusive) |
| confidence | Confidence level of result |
| recommendations | Recommendations for further action |
| issued_by | Constitutional authority entity |
| issued_at | Deterministic timestamp |
| scope | Authorized knowledge integration scope |

## Certification Lifecycle

```
Draft → Under Review → Certified → Knowledge Integrated → Archived
```

## Post-Certification

After certification, experiment results may be integrated into knowledge:

- Confirmed results → update theories, models, confidence
- Refuted results → update confidence, refine hypotheses
- Inconclusive results → recommend redesign or additional experiments
- All results → archaeological preservation

## Certification Registry

| Function | Description |
|----------|-------------|
| register | Register a new ExperimentCertificate |
| lookup | Retrieve certificate by experiment_id or certificate_id |
| verify | Verify certificate is valid and current |
| revoke | Revoke certificate if results are superseded |
