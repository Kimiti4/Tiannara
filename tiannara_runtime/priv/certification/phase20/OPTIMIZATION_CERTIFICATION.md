# Phase 20.8 — Optimization Certification

## Role

Optimization Certification is the constitutional gate that validates an optimization recommendation for further action. No optimization recommendation may proceed to integration or engineering without a valid OptimizationCertificate.

## Certification Requirements

### Evidence Foundation
- Optimization originates from measurable evidence
- All metrics are reproducible
- Bottleneck is reproducible
- Causal chain is documented

### Trade-off Completeness
- All trade-off dimensions analyzed
- Advantages and disadvantages documented
- Expected gains and regressions quantified
- Risk profile assessed with mitigations

### Simulation Validity
- Simulation reproduces predicted outcomes
- Confidence intervals are documented
- Predictions are falsifiable by experiment

### Constitutional Compliance
- Determinism confirmed
- Replayability confirmed
- Archaeology completeness confirmed
- No governance bypass

### Recommendation Clarity
- Recommendation type is clear (engineering/experiment/evolution)
- Required actions are specified
- Priority is assigned deterministically
- Expected impact is quantified

### Audit Clearance
- Trade-off analysis is independently auditable
- All assumptions are documented
- Limitations are documented

## Certification Document

The OptimizationCertificate contains:

| Field | Description |
|-------|-------------|
| certificate_id | Content-addressed identifier |
| candidate | Reference to OptimizationCandidate |
| bottleneck | Reference to BottleneckReport |
| tradeoff_root | Root hash of trade-off analysis |
| simulation_root | Root hash of simulation |
| recommendation_root | Root hash of recommendation |
| certificate_hash | SHA-256 of certificate canonical form |
| recommendation_type | Engineering/Experiment/Evolution/Research |
| priority | Deterministic priority ranking |
| expected_impact | Quantified expected impact |
| issued_by | Constitutional authority entity |
| issued_at | Deterministic timestamp |
| scope | Authorized scope of recommendation |

## Certification Lifecycle

```
Draft → Under Review → Certified → Actioned → Archived → Revoked
```

## Post-Certification

After certification, the optimization recommendation is forwarded to:

- Phase 20.6 (Engineering) — if engineering change is recommended
- Phase 20.7 (Experimentation) — if experimental validation is needed
- Phase 20.3 (Evolution Pipeline) — if runtime evolution is recommended

## Certification Registry

| Function | Description |
|----------|-------------|
| register | Register a new OptimizationCertificate |
| lookup | Retrieve certificate by candidate_id or certificate_id |
| verify | Verify certificate is valid and current |
| revoke | Revoke certificate if superseded by better optimization |
