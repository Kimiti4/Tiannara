# Phase 20.9 — Self-Integration Archaeology Model

## Role

Self-Integration Archaeology preserves the complete history of every integration — proposed, promoted, delayed, or rejected. Every integration answers the Eight Archaeological Questions, preserving full context for future reconstruction, audit, and constitutional review.

## The Eight Archaeological Questions (Self-Integration)

Every integration must answer:

1. **Why was integration proposed?** — The validated improvement (engineering, experiment result, or optimization) that motivated the integration proposal. Reference to the originating proposal_id, improvement type, and evidence chain.

2. **Which optimization motivated it?** — The specific optimization recommendation (Phase 20.8) that triggered the integration. Reference to candidate_id, bottleneck_id, expected gain, and trade-off analysis.

3. **Which experiments justified it?** — Experiment results (Phase 20.7) that validated the predicted improvement. Each experiment reference includes experiment_id, classification, effect size, and confidence.

4. **Which engineering artifacts changed?** — Engineering projects (Phase 20.6), designs, or implementation plans that were modified or created by this integration. Each artifact reference includes artifact_id and change description.

5. **Which runtime generation was created?** — The new runtime generation (Phase 20.5) produced by this integration. Reference to generation_id, semantic_version, constitutional_hash, and parent generation.

6. **Which previous generation was preserved?** — The previous runtime generation that was moved to Historical status. Reference to generation_id, archive location, and replay verification.

7. **Which mathematical systems changed?** — Mathematical modules, proofs, formalisms, or symbolic state that were modified by this integration. Each change reference includes domain, before/after hash, and proof impact.

8. **Which scientific capabilities improved?** — Scientific discovery, research, or modeling capabilities that improved as a result of this integration. Each improvement reference includes capability, metric delta, and confidence.

## Integration Archaeology Record

Each integration produces an archaeology record:

| Field | Description |
|-------|-------------|
| proposal_id | Reference to IntegrationProposal |
| answers | Answers to all 8 archaeological questions |
| evidence_chain | Complete evidence chain for the integration |
| generation_transition | Source and target generation references |
| artifact_manifest | Complete inventory of changed artifacts |
| archaeology_root | SHA-256(canonical_form(answers)) |

## Archaeology Registry

| Function | Description |
|----------|-------------|
| register | Register an integration's archaeological record |
| explain | Given a proposal_id, return answers to all 8 questions |
| integration_history | Return complete integration history for the OS |
| generation_impact | Return integrations that affected a specific generation |
| capability_improvement | Return capability improvements across integrations |

## Cold Storage Reconstruction

From cold storage alone:

1. Read the integration's replay chain from replay_root
2. Reconstruct each pipeline stage in order
3. From reconstructed artifacts, derive answers to all 8 archaeological questions
4. Compute archaeology_root = SHA-256(canonical_form(answers))
5. Verify archaeology_root matches stored value
6. Reconstruct complete integration lineage

## Constraints

- No integration record is ever deleted
- Delayed and rejected integrations are fully preserved
- All promotion decisions are preserved with rationale
- Archaeology is reconstructable from cold storage (no runtime state required)
- Archaeology is deterministic (same evidence + replay → same answers → same archaeology_root)
