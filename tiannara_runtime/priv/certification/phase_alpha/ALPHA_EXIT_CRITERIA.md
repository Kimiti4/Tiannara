# Alpha Exit Criteria — Stage Beta Readiness

## Purpose
Specify measurable requirements that must be met before Stage Alpha can conclude and Stage Beta can begin. These are minimum thresholds — exceeding them is encouraged.

## Runtime Criteria

### Replay Integrity
- ≥99.9% replay integrity over entire Alpha duration
- Measured: operations replayed with identical results / total operations
- Verification: continuous replay verification, not sampling

### Unrecoverable Failures
- Zero unrecoverable failures
- An unrecoverable failure is one where knowledge loss occurred or manual intervention was required to restore operation
- Acceptable: 3+ recoverable failures with zero knowledge loss

### Automatic Recovery
- ≥3 automatic recovery events verified
- Each recovery: detection → load checkpoint → verify → resume
- Recovery time all under 30s
- Zero knowledge loss per recovery

### Memory Plateau
- Memory growth rate <1% per day after first 7 days
- Measured over minimum 14-day window
- Demonstrated under normal operating load

### Continuous Execution
- Minimum 30 days continuous execution (no restart required)
- Acceptable: restarts only for planned experiments or verified failure recovery
- Not acceptable: restarts due to memory leak, resource leak, or unhandled error

### Checkpoint Integrity
- 100% checkpoint success rate (all checkpoints verified valid)
- 100% checkpoint verification success (all content hashes match)
- All checkpoints reconstructible to verify

## Scientific Criteria

### Hypothesis Generation
- Minimum 1,000 hypotheses generated over Alpha duration
- Minimum 10 hypotheses per day on average
- Distribution across minimum 3 scientific domains

### Hypothesis Validation
- Minimum 100 hypotheses validated or refuted
- ≥60% prediction accuracy on validated hypotheses
- Evidence lineage complete for all validated hypotheses

### Discovery Pipeline
- Pipeline demonstrated end-to-end: observation → question → hypothesis → experiment → simulation → evidence → verification → knowledge
- Pipeline cycle time documented (average and distribution)
- Pipeline reproducibility demonstrated (same observation → same knowledge)

### Evidence Lineage
- Complete evidence lineage for every validated hypothesis
- Lineage includes: evidence sources, methodology, replication count, confidence

### Knowledge Growth
- Minimum 500 new knowledge entries
- Distribution across minimum 3 domains
- Measurable confidence increase (average confidence increase per domain)

## Engineering Criteria

### Engineering Artifacts
- Minimum 100 verified engineering designs
- Minimum 60% verification success rate
- Designs across minimum 2 engineering domains

### Optimization Improvement
- Average optimization yield ≥5%
- Optimization reproducibility demonstrated (same design → same Pareto frontier)
- Tradeoff analysis documented per design

### Technology Readiness
- Technology readiness assessment functioning for all designed artifacts
- TRL assignments consistent and auditable

## Observatory Criteria

### Telemetry Duration
- Minimum 30 days of continuous telemetry
- No telemetry gaps >1 second (acceptable exceptions: during failure recovery, documented)
- Telemetry integrity verified (content hashes match)

### Historical Playback
- Historical playback functioning for entire telemetry duration
- Any past state reconstructible from replay
- Playback verified against original timestamps

### Archaeology Reconstruction
- Complete archaeology reconstruction possible for entire Alpha duration
- Reconstruction verified: state at any time t reconstructed from replay matches original recorded state at t

### Mission Control
- All observatory panels functioning with real-time data
- All alert thresholds configured
- Alert accuracy: false positive rate <10%, missed alert count <5

### Replay Certification
- Replay certification passing continuously
- No replay divergence detected
- Replay coverage ≥99% of all operations

## Constitutional Criteria

### Stable Governance
- Constitutional compliance ≥99% over entire Alpha
- No constitutional violations (zero)
- Governance compliance documented per domain

### Stable Evolution
- Constitutional evolution events all recorded, certified, replayable
- Evolution rate stable (no rapid, unexplained changes)
- All evolution events human-reviewable

### Stable Replay
- Replay integrity ≥99.9%
- Replay coverage ≥99%
- No replay divergence

### Stable Certification
- All certifications current (none expired or failed)
- Certification coverage ≥95%
- Certification chain integrity verified

### Stable Archaeology
- Archaeology completeness ≥99%
- All state reconstructions successful
- Archaeology queryable for entire Alpha duration

### Stable Resilience
- All recovery events documented and verified
- Zero knowledge loss across all events
- Recovery improvements demonstrated (recovery time decreasing trend)

## Documentation Criteria

### Complete Records
- All weekly certification packages archived
- All failure recovery records preserved
- All experiment results documented

### Stage Beta Readiness Document
- Readiness assessment complete
- Critical gaps identified and addressed
- Transition plan documented
- Human approval obtained

## Conditional Exceptions
Criteria may be marked as CONDITIONAL (not fully met but acceptable for Stage Beta) under the following conditions:
- Criterion is >90% met, and clear remediation plan exists
- Criterion is not critical for Stage Beta operations
- Exception is documented with rationale and timeline for resolution

CONDITIONAL criteria must be resolved before Stage Gamma.

## Exit Decision
- All criteria must be PASS or CONDITIONAL
- Zero FAIL criteria
- Human review of all criteria
- Human approval required for Alpha exit
- Exit certification permanently archived
