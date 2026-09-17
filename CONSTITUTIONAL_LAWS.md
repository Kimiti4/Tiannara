# Constitutional Laws

Status: candidate laws; validation is tracked in `CONSTITUTIONAL_LAWS_VALIDATION.md`.

| ID | Law | Falsifiable prediction | Evidence required |
|---|---|---|---|
| CL-001 | Canonical ownership | Ambiguous ownership increases conflicting writes and replay divergence. | Ownership-conflict campaign across valid topologies. |
| CL-002 | Provenance completeness | Decisions without complete provenance cannot be independently reproduced. | Blind replay from exported ledgers only. |
| CL-003 | Replay continuity | Identical frozen inputs, code, seed, and logical clock produce identical state roots. | Multi-host deterministic replay. |
| CL-004 | Evidence quality | Decision reliability rises with independently replicated evidence quality. | Controlled evidence-quality ablation. |
| CL-005 | Bounded authority | Unchecked concentrated authority increases single-point constitutional failure. | Centralization sweep under matched loads. |
| CL-006 | Entropy control | Explicit invariants and repair protocols bound governance-state entropy. | Long-horizon simulations with invariant ablation. |

No law is ratified merely by inclusion here. Ratification requires preregistered tests, effect thresholds, replication, contradiction analysis, and an auditable evidence-chain identifier.
