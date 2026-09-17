# Opportunity Replay Model

## Purpose

Define deterministic replay for the scientific opportunity management system, enabling complete reconstruction of the knowledge frontier, opportunity identification, priority calculations, and frontier evolution.

## Replay Types

### Full Frontier Replay
Reconstructs entire knowledge frontier state at a given generation:
- All 7 frontier layers
- All frontier elements with their properties
- Frontier state hashes
- Frontier evolution chain

### Opportunity Replay
Reconstructs the lifecycle of a specific opportunity:
- Discovery mechanism and evidence
- Initial characterization
- Priority score computation
- Lifecycle transitions (identified → verified → ranked → etc.)

### Information Gain Replay
Reconstructs gain estimation for an opportunity:
- All 8 dimension scores
- Uncertainty ranges
- Composite gain computation
- Supporting evidence hashes

### Cross-Domain Replay
Reconstructs cross-domain opportunity detection:
- Domain pair analysis
- Tension measurement
- Opportunity formation
- Provenance chain verification

### Priority Replay
Reconstructs priority ranking:
- All 10 dimension scores
- Weight application
- Composite score computation
- Rank assignment within opportunity set

## Verification Process

1. Load original hash chain from cold storage
2. Reconstruct each step from inputs and parameters
3. Compare computed hashes with stored hashes
4. Report hash mismatches with full context
5. Provide pass/fail per replay type

## Constraints

- All replay steps must be deterministic
- Identical inputs must produce identical hashes
- Frontier-scale replay must complete within bounded resources
- Hash mismatches must pinpoint exact opportunity decision
- Replay must be cold-storage independent
