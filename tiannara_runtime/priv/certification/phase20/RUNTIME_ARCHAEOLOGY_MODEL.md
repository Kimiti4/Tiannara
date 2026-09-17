# Phase 20.5 — Runtime Archaeology Model

## Role

Runtime Archaeology preserves the complete evolutionary history of every runtime generation. Every generation answers the Seven Archaeological Questions, enabling full reconstruction of why and how the operating system evolved.

## The Seven Archaeological Questions (Runtime Evolution)

Every runtime generation must answer:

1. **Why was this generation created?** — The bottleneck, opportunity, or requirement that motivated the creation of this generation. Reference to the originating EvolutionOpportunity (Phase 20.3), the certified candidate, and the integration that produced this generation.

2. **Which bottlenecks motivated it?** — The specific bottleneck reports that triggered the evolution pipeline, resulting in innovations integrated into this generation. Each bottleneck reference includes its report_id and severity.

3. **Which extensions were integrated?** — Complete list of all constitutional extensions integrated in this generation. Each extension reference includes its extension_id, version, and certification_ref.

4. **Which systems were retired or deprecated?** — Subsystems, modules, or extensions that were retired, deprecated, or replaced in this generation. Each reference includes retirement documentation and replacement references.

5. **Which experiments justified it?** — Complete references to the constitutional experiments (Phase 20.3 Evolution Sandbox) and integration simulations (Phase 20.4) that produced the evidence supporting this generation. Each experiment reference includes its evidence_root and certification artifacts.

6. **Which audits certified it?** — All independent audit references, audit findings, and certification documents that authorized this generation for each lifecycle stage (Certified, Sandbox, Canary, Production, Frozen). Each audit reference includes its audit_root and certificate_hash.

7. **How did civilization metrics change?** — Civilization-scale metric comparison between this generation and its parent. Includes scientific capital, knowledge growth, research velocity, engineering productivity, and civilization readiness deltas.

## Archaeology Record Per Generation

Each generation produces an archaeology record:

| Field | Description |
|-------|-------------|
| generation_id | Reference to RuntimeGeneration |
| answers | Answers to all 7 archaeological questions |
| evidence_chain | Complete evidence chain for this generation |
| lineage_references | Parent and child generation links |
| metric_deltas | Civilization metric changes from parent |
| archaeology_root | SHA-256(canonical_form(answers)) |

## Archaeology Registry

| Function | Description |
|----------|-------------|
| register | Register a generation's archaeological record |
| explain | Given a generation_id, return answers to all 7 archaeology questions |
| lineage | Return complete generation lineage (ancestors and descendants) |
| compare | Compare archaeology of two generations |
| metrics_history | Return civilization metric trends across generations |

## Cold Storage Reconstruction

From cold storage alone:

1. Read the generation's replay chain from replay_root
2. Reconstruct the complete runtime generation
3. From the reconstructed generation and its evidence chain, derive answers to the 7 archaeological questions
4. Compute archaeology_root = SHA-256(canonical_form(answers))
5. Verify archaeology_root matches stored value
6. Reconstruct generation lineage by following parent references

This property ensures that any past state of the operating system can be fully understood — not just replayed, but explained — without any runtime state.

## Constraints

- No generation archaeology record is ever deleted
- Failed generations (rolled back before freeze) are fully preserved
- Archaeology is reconstructable from cold storage (no runtime state required)
- Archaeology is deterministic (same evidence + replay → same answers → same archaeology_root)
- Archaeology supports cryptographic verification of all records
