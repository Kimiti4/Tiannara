# Phase 20.6 — Engineering Archaeology Model

## Role

Engineering Archaeology preserves the complete history of every engineering project — successful or abandoned. Every project answers the Seven Archaeological Questions, preserving full context for future reconstruction and audit.

## The Seven Archaeological Questions (Engineering)

Every engineering project must answer:

1. **Why was this project created?** — The problem, bottleneck, or opportunity that motivated the engineering project. Reference to the originating observation or bottleneck report.

2. **Which bottleneck motivated it?** — The specific bottleneck report or capability gap that triggered the engineering request. Each reference includes bottleneck_id and severity.

3. **Which evidence justified it?** — The simulation results, verification reports, and validation outcomes that justified the engineering approach. Each evidence reference includes its evidence_root and fingerprint.

4. **Which alternatives were rejected?** — Architectural alternatives, design alternatives, and implementation approaches that were considered but rejected. Each rejection includes rationale and evidence.

5. **Which simulations succeeded?** — Complete simulation results demonstrating the engineered capability's behavior, performance, and determinism. Each simulation reference includes its report_id and metrics.

6. **Which runtime changed?** — The specific runtime modules, subsystems, interfaces, and configurations that were modified or created by this engineering project. Each change reference includes its before/after hashes.

7. **Which mathematics was introduced?** — New mathematical modules, formalisms, algorithms, or proofs introduced by this engineering project. Each mathematics reference includes its verification status and proof references.

## Additional Archaeological Questions

8. **Which previous systems were replaced?** — Subsystems or capabilities that were superseded by this engineering project. Each replacement reference includes retirement documentation.

9. **Which dependencies were introduced?** — New dependencies created or relied upon by this engineering project. Each dependency reference includes version constraints and compatibility verification.

## Engineering Archaeology Record

Each engineering project produces an archaeology record containing:

| Field | Description |
|-------|-------------|
| project_id | Reference to EngineeringProject |
| answers | Answers to all archaeological questions |
| evidence_chain | Complete evidence chain for the project |
| design_lineage | Ancestry of design decisions |
| alternative_history | Record of rejected alternatives |
| runtime_change_manifest | Complete record of runtime changes |
| mathematics_manifest | Complete record of mathematics introduced |
| archaeology_root | SHA-256(canonical_form(answers)) |

## Archaeology Registry

| Function | Description |
|----------|-------------|
| register | Register a project's archaeological record |
| explain | Given a project_id, return answers to all archaeological questions |
| project_history | Return complete engineering project lineage |
| alternative_history | Return all rejected alternatives with rationale |
| runtime_changes | Return all runtime changes introduced by projects |

## Cold Storage Reconstruction

From cold storage alone:

1. Read the project's replay chain from replay_root
2. Reconstruct each engineering stage in order
3. From reconstructed artifacts, derive answers to all archaeological questions
4. Compute archaeology_root = SHA-256(canonical_form(answers))
5. Verify archaeology_root matches stored value
6. Reconstruct complete engineering project lineage

## Constraints

- No engineering project record is ever deleted
- Abandoned and failed projects are fully preserved
- All rejected alternatives are preserved with rationale
- Archaeology is reconstructable from cold storage (no runtime state required)
- Archaeology is deterministic (same evidence + replay → same answers → same archaeology_root)
