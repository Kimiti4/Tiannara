# Experiment Genome

## Overview
The Experiment Genome is a first-class, content-addressed specification that defines the complete structure of a constitutional experiment. It enables experiments to be compared, replayed, evolved, and validated across the Tiannara platform.

## Schema Definition

### Core Fields
- **hypothesis**: Text description of the constitutional claim being tested
- **variables**: Set of mutable parameters being manipulated
- **controls**: Baseline configuration for comparison
- **treatments**: Specific configuration changes to apply
- **expected_outcome**: Predicted effect based on theoretical analysis
- **measured_outcome**: Actual observed result from execution
- **statistical_model**: Statistical framework for analysis (e.g., Bayesian, frequentist)
- **replay_seed**: Deterministic seed for reproducible replay
- **evidence_requirements**: List of required evidence artifacts and their content-addressing scheme
- **confidence_model**: Framework for determining confidence levels and thresholds

### Temporal Structure
- **proposal_timestamp**: ISO8601 timestamp of initial proposal
- **approval_timestamp**: Timestamp when experiment was approved
- **execution_timestamp**: Timestamp when experiment was executed
- **completion_timestamp**: Timestamp when experiment completed all phases

### Governance Metadata
- **owner**: Primary steward of the experiment
- **priority**: Assigned priority level (e.g., critical, high, medium, low)
- **dependencies**: List of other experiments or RFCs that must be completed first
- **cancelled**: Boolean flag indicating if experiment was terminated

## Content-Addressing
All Experiment Genome artifacts are stored using SHA-256 hashing of their canonical content. The resulting fingerprint serves as:
- Content identifier
- Integrity validator
- Routing key for distributed storage
- Verifiability anchor

## Example Schema (YAML)
```yaml
hypothesis: "RFC-152 improves governance stability"
variables:
  - "institutional_power_distribution"
  - "resource_allocation_mechanism"
controls:
  - "current_constitutional_framework"
treatments:
  - "apply_RFC_152"
  - "modify_voting_weighting"
expected_outcome: "Increased stability index by 12%"
measured_outcome: "Stability index increased by 10.8%"
statistical_model: "Bayesian hierarchical model"
replay_seed: "0x5f2a8c1d"
evidence_requirements:
  - "SIMULATION_EVIDENCE_GRAPH.json#sha256:abc123..."
  - "STATISTICAL_VALIDATION.md#sha256:def456..."
confidence_model: "95% credible interval with Bayes factor > 10"
owner: "ConstitutionalScienceTeam"
priority: "critical"
dependencies:
  - "RFC-151"
  - "EXPERIMENT_1234"
```

## Lifecycle Integration
1. **Creation**: Generated during Experiment Proposal phase
2. **Versioning**: Each modification creates a new genome with incremented version
3. **Storage**: Stored in Experiment Registry with content-addressable linking
4. **Execution**: Used by Experiment Runtime to drive execution workflow
5. **Audit**: Referenced during Independent Scientific Audit for verification
6. **Evolution**: Serves as basis for Experiment Evolution algorithms

## Validation Requirements
- Genome must be cryptographically signed by owner
- All referenced evidence artifacts must be content-addressable
- Statistical model must be documented and reproducible
- Replay seed must enable deterministic reconstruction
- Confidence thresholds must be explicitly defined