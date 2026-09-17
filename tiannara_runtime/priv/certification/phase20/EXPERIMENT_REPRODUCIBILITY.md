# Phase 20.7 — Experiment Reproducibility

## Role

Experiment Reproducibility is the mechanism that verifies every experiment can be reproduced identically — same proposal, same environment, same execution, same observations, same statistics, same conclusions. Reproducibility is a constitutional requirement for every experiment.

## Reproducibility Requirements

### Full Pipeline Reproducibility
Every stage of the experiment pipeline must reproduce identically:

| Stage | Reproducibility Requirement |
|-------|-----------------------------|
| Proposal | Same proposal must produce identical experiment_id |
| Design | Same proposal + same rules must produce identical ExperimentPlan |
| Environment | Same plan must produce identical environment snapshot |
| Execution | Same environment + same plan must produce identical observations |
| Analysis | Same observations + same plan must produce identical statistics |
| Classification | Same statistics + same criteria must produce identical classification |
| Knowledge integration | Same results must produce identical knowledge updates |

### Reproducibility Verification Protocol

1. **Archive all inputs**: Store complete input set for reproducibility
2. **Replay from inputs**: Execute full pipeline using stored inputs
3. **Compare hashes**: At every stage, compare reproduced hash against stored hash
4. **Report discrepancies**: Any hash mismatch is a reproducibility failure
5. **Classify**: Experiment is reproducible if and only if all hashes match

## Deterministic Environment

Every experiment executes in a fully deterministic environment:

| Environment Component | Determinism Mechanism |
|-----------------------|-----------------------|
| Runtime state | Initialized from deterministic snapshot |
| Dependencies | Fixed versions with deterministic resolution |
| Configuration | Complete configuration snapshot |
| Random seeds | Derived from experiment_id (deterministic) |
| Timing | Step-based (not wall-clock) |
| Resource allocation | Fixed before execution |

## Reproducibility Levels

| Level | Description | Requirements |
|-------|-------------|--------------|
| Full | Complete pipeline reproducibility | All hashes match at all stages |
| Computational | Same algorithm, same results | Replay produces identical observations and statistics |
| Statistical | Same conclusions | Replay produces same classification and confidence |
| Conceptual | Same scientific conclusion | Higher-level conclusion is consistent |
| None | Not reproducible | Experiment is invalid; results not accepted |

## Reproducibility Report

Each experiment produces a ReproducibilityReport:

| Field | Description |
|-------|-------------|
| report_id | Content-addressed identifier |
| experiment | Reference to experiment |
| level | Achieved reproducibility level |
| stage_results | Hash comparison per pipeline stage |
| all_hashes_match | Overall pass/fail |
| discrepancies | Any hash mismatches with diagnostic |
| environment_fingerprint | Environment snapshot hash |
| replay_root | Root hash of reproducibility replay chain |
| fingerprint | SHA-256 of canonical form |

## Constraints

- Reproducibility is a constitutional requirement for experiment acceptance
- Experiments that fail reproducibility verification are marked inconclusive
- No runtime state may influence reproducibility replay
- Reproducibility replay must work from cold storage
- Reproducibility verification must itself be reproducible
