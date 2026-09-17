# Phase 20.7 — Experiment Archaeology Model

## Role

Experiment Archaeology preserves the complete history of every experiment — successful, inconclusive, or failed. Every experiment answers the Seven Archaeological Questions, preserving full context for future reconstruction, audit, and meta-analysis.

## The Seven Archaeological Questions (Experimentation)

Every experiment must answer:

1. **Why was this experiment proposed?** — The knowledge gap, hypothesis, or engineering question that motivated the experiment. Reference to the originating proposal, engineering project (20.6), discovery (15), or research (16) request.

2. **Which hypothesis motivated it?** — The specific falsifiable hypothesis being tested. Reference to the hypothesis statement, predicted outcome, and theoretical framework.

3. **Which knowledge gap triggered it?** — The specific gap in knowledge, theory, or understanding that this experiment was designed to fill. Reference to the knowledge graph node or theory that motivated the experiment.

4. **Which resources were consumed?** — Complete accounting of resources consumed: compute, memory, storage, time, domain-specific resources. Each resource record includes budget allocation, actual consumption, and variance.

5. **Which theories changed?** — Theories, models, or knowledge claims that were updated as a result of this experiment. Each change reference includes before/after state and confidence adjustment.

6. **Which engineering systems were affected?** — Engineering projects (20.6), runtime subsystems, or capabilities that were informed by or modified based on experiment results. Each reference includes the engineering project_id and integration status.

7. **Which future experiments depend on it?** — Experiments that list this experiment as a dependency, rely on its results, or were motivated by its findings. Each dependent reference includes the dependent experiment_id and relationship type.

## Experiment Archaeology Record

Each experiment produces an archaeology record:

| Field | Description |
|-------|-------------|
| experiment_id | Reference to experiment |
| answers | Answers to all 7 archaeological questions |
| evidence_chain | Complete evidence chain for the experiment |
| resource_accounting | Complete resource consumption record |
| theory_changes | Theories updated with before/after states |
| engineering_impact | Engineering projects affected |
| dependency_graph | Dependent experiments |
| archaeology_root | SHA-256(canonical_form(answers)) |

## Archaeology Registry

| Function | Description |
|----------|-------------|
| register | Register an experiment's archaeological record |
| explain | Given an experiment_id, return answers to all 7 questions |
| experiment_history | Return complete experiment history for a hypothesis |
| resource_analysis | Return resource consumption trends across experiments |
| theory_impact | Return experiments sorted by theory impact |

## Cold Storage Reconstruction

From cold storage alone:

1. Read the experiment's replay chain from replay_root
2. Reconstruct each pipeline stage in order
3. From reconstructed artifacts, derive answers to all 7 archaeological questions
4. Compute archaeology_root = SHA-256(canonical_form(answers))
5. Verify archaeology_root matches stored value
6. Reconstruct experiment dependency graph

## Constraints

- No experiment record is ever deleted
- Failed, inconclusive, and aborted experiments are fully preserved
- All statistical results are preserved (not just significant ones)
- Archaeology is reconstructable from cold storage (no runtime state required)
- Archaeology is deterministic (same evidence + replay → same answers → same archaeology_root)
