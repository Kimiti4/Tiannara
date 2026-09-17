# Strategy Replay Model

## Purpose

Define deterministic replay for the scientific strategy system, enabling complete reconstruction of every strategic decision, roadmap, trajectory evaluation, priority calculation, and alignment decision.

## Replay Types

### Full Strategy Replay
Reconstructs the entire strategic state at a given generation:
- All roadmaps and their milestones
- All strategic objectives
- All trajectory evaluations
- All priority calculations
- All alignment decisions

### Roadmap Replay
Reconstructs roadmap creation and evolution:
- Strategic goal derivation
- Dependency mapping
- Milestone sequencing
- Resource estimation

### Trajectory Replay
Reconstructs trajectory modeling:
- Trajectory generation
- Comparison evaluation
- Selection rationale

### Priority Replay
Reconstructs priority calculations:
- Dimension scoring
- Weight application
- Priority classification

### Alignment Replay
Reconstructs alignment decisions:
- Institute alignment evaluation
- Portfolio alignment assessment
- Capital alignment verification
- Rebalancing recommendations

## Verification Process

1. Load original hash chain from cold storage
2. Reconstruct each strategy step from inputs and parameters
3. Compare computed hashes with stored hashes
4. Report hash mismatches with full context
5. Provide pass/fail per replay type

## Constraints

- All replay steps must be deterministic
- Identical inputs must produce identical hashes
- Strategy-scale replay must complete within bounded resources
- Hash mismatches must pinpoint exact strategic decision
- Replay must be cold-storage independent
