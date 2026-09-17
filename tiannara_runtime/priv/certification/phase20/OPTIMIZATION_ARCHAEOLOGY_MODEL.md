# Phase 20.8 — Optimization Archaeology Model

## Role

Optimization Archaeology preserves the complete history of every optimization — proposed, recommended, accepted, or rejected. Every optimization answers the Seven Archaeological Questions, preserving full context for future reconstruction, audit, and meta-optimization.

## The Seven Archaeological Questions (Optimization)

Every optimization must answer:

1. **Why was this optimization proposed?** — The bottleneck, inefficiency, or opportunity that motivated the optimization. Reference to the originating BottleneckReport, MetricSet trends, or observed degradation.

2. **Which bottleneck motivated it?** — The specific bottleneck that triggered the optimization. Reference to bottleneck_id, severity, causal_chain, and evidence_root.

3. **Which experiments support it?** — Experiment results (Phase 20.7) that validate the predicted improvement. Each experiment reference includes experiment_id, classification (confirmed/refuted), and observed effect size.

4. **Which engineering systems are affected?** — Engineering projects (Phase 20.6), subsystems, or capabilities that would be modified by this optimization. Each affected system reference includes system_id and change description.

5. **Which runtime generations would change?** — Runtime generations (Phase 20.5) that would be affected by this optimization. Each generation reference includes generation_id and scope of change.

6. **Which alternatives were rejected?** — Optimization candidates that were considered but not recommended. Each rejection reference includes candidate_id, trade-off comparison, and rationale.

7. **What long-term impact is expected?** — Predicted long-term impact across all objectives: performance, accuracy, scientific productivity, engineering productivity, energy efficiency, maintainability, and constitutional safety. Includes confidence intervals and risk assessment.

## Optimization Archaeology Record

Each optimization produces an archaeology record:

| Field | Description |
|-------|-------------|
| candidate_id | Reference to OptimizationCandidate |
| answers | Answers to all 7 archaeological questions |
| evidence_chain | Complete evidence chain |
| trade-off_history | Complete trade-off analysis history |
| alternative_history | Record of rejected alternatives |
| impact_prediction | Long-term impact predictions |
| archaeology_root | SHA-256(canonical_form(answers)) |

## Archaeology Registry

| Function | Description |
|----------|-------------|
| register | Register an optimization's archaeological record |
| explain | Given a candidate_id, return answers to all 7 questions |
| optimization_history | Return complete optimization history for a subsystem |
| bottleneck_history | Return all optimizations targeting a specific bottleneck |
| alternative_history | Return all rejected alternatives with rationale |

## Cold Storage Reconstruction

From cold storage alone:

1. Read the optimization's replay chain from replay_root
2. Reconstruct each pipeline stage in order
3. From reconstructed artifacts, derive answers to all 7 archaeological questions
4. Compute archaeology_root = SHA-256(canonical_form(answers))
5. Verify archaeology_root matches stored value
6. Reconstruct optimization lineage

## Constraints

- No optimization record is ever deleted
- Rejected and failed optimizations are fully preserved
- All rejected alternatives are preserved with rationale
- Archaeology is reconstructable from cold storage
- Archaeology is deterministic (same evidence + replay → same answers → same archaeology_root)
