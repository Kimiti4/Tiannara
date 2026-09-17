# Phase 20.3 — Evolution Replay Model

## Overview

Every evolution object supports deterministic replay. Replay must reproduce identical SHA-256 hashes at every step, across all pipeline stages, for all evolution object types.

## Replay Types

### Opportunity Replay
Reconstruct the detection of an evolution opportunity from raw observations. Must reproduce identical opportunity_id, priority, and estimated_gain.

### Bottleneck Replay
Reconstruct bottleneck analysis from observation records. Must reproduce identical bottleneck_id, category, severity, and root_cause.

### Hypothesis Replay
Reconstruct hypothesis formulation from bottleneck report. Must reproduce identical hypothesis_id, predictions, assumptions, and failure_conditions.

### Candidate Replay
Reconstruct candidate architecture from hypothesis. Must reproduce identical candidate_id, interfaces, dependencies, and expected_metrics.

### Campaign Replay
Reconstruct campaign planning from candidate. Must reproduce identical campaign_id, benchmark_plan, simulation_plan, and deployment_plan.

### Experiment Replay
Reconstruct experiment execution from campaign plan. Must reproduce identical experiment results, benchmark measurements, and evidence_root.

### Sandbox Replay
Reconstruct sandbox deployment and validation. Must reproduce identical sandbox metrics, simulation comparison, and status.

### Canary Replay
Reconstruct canary deployment. Must reproduce identical metrics, sandbox comparison, and pass/fail determination.

### Production Replay
Reconstruct production deployment and generation freeze. Must reproduce identical generation number, constitutional_hash, and all integrated extensions.

### Rollback Replay
Reconstruct rollback event from trigger to restoration. Must reproduce identical trigger_evidence, rolled_back_generations, and restored generation state.

### Generation Replay
Reconstruct an entire evolution generation from genesis. Starting from generation 0, apply every opportunity, hypothesis, candidate, campaign, experiment, deployment, and rollback in order. Must reproduce identical constitutional_hash for every generation.

## Replay Chain Structure

Each replay type produces a chain of step hashes:

```
step_hash[N] = SHA-256(step_hash[N-1] || step_data[N])
root_hash = step_hash[N]  (final step)
```

Where:
- `step_hash[0]` = SHA-256(genesis_seed || object_type)
- `step_data[N]` = canonical binary encoding of step N's inputs and outputs
- `root_hash` = stored in the object's replay_root field

## Deterministic Ordering

Replay steps are ordered by:

1. **Priority** — lower numeric priority executes first (defined per object type)
2. **Dependency graph** — objects replay in dependency order (DAG; dependency before dependent)
3. **Timestamp** — within same priority and dependency level, earlier timestamps first
4. **Content hash** — as final tiebreaker, lexicographically smaller content hashes first

## Ordering Rules Per Object Type

| Object Type | Priority | Dependencies |
|-------------|----------|--------------|
| EvolutionOpportunity | 1 | None |
| BottleneckReport | 2 | EvolutionOpportunity |
| ArchitecturalHypothesis | 3 | BottleneckReport |
| ArchitectureCandidate | 4 | ArchitecturalHypothesis |
| EvolutionCampaign | 5 | ArchitectureCandidate |
| ExperimentResult | 6 | EvolutionCampaign |
| SandboxRun | 7 | ArchitectureCandidate, ExperimentResult |
| CanaryRun | 8 | SandboxRun |
| ProductionRun | 9 | CanaryRun |
| EvolutionGeneration | 10 | ProductionRun |
| RollbackEvent | 11 | EvolutionGeneration |
| EvolutionMetrics | 12 | EvolutionGeneration |
| EvolutionDecision | 13 | ExperimentResult |
| GenerationLineage | 14 | EvolutionGeneration |

## Verification

- Every replay step must produce an identical SHA-256 hash to the recorded value
- If any step produces a different hash, replay is considered failed
- A failed replay triggers a RollbackEvent and alerts constitutional monitoring
- The EvolutionReplayRegistry tracks all replay roots and verification status

## Constraints

- Replay must be fully deterministic: same inputs always produce same outputs
- Replay must be acyclic: no replay step depends on a later step
- Replay must be content-addressed: every intermediate hash uniquely identifies that state
- Replay must be independent of runtime state: cold storage replay must reproduce identical hashes
