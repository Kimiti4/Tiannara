# Phase 16.1 — Research Ontology (Schema Report)

## Overview

This document reports the **research ontology schemas** for Phase 16.1.

It includes:
- canonical content-addressing rules (Blake3)
- schema list and required fields
- serialization/canonicalization requirements
- validators expectations

This is specification-only.

---

## Frozen Specification

- `RESEARCH_DATA_MODEL.md` is the authoritative schema ontology document for Phase 16.1.
- All IDs inside Phase 16 are content-addressed using canonical serialization.
- Replay-critical schemas must be stable across the epoch.

---

## Canonical Serialization Rules (Required)

Any artifact whose ID is content-addressed MUST use canonical serialization:

1. **Key ordering**
   - Serialize JSON objects with lexicographic key ordering.
2. **Canonical null vs missing**
   - Missing vs `null` must not silently collapse; they are distinct in serialization.
3. **Canonical number formatting**
   - Use deterministic number formatting (no locale, no scientific ambiguity).
4. **Deterministic arrays**
   - If ordering matters, arrays must appear in deterministic order.
   - If ordering does not matter, the schema must define canonical ordering keys.
5. **No implicit fields**
   - Serialization must not include runtime-derived fields.

---

## Content-addressed ID Algorithm

**Definition**

```text
artifact_id = blake3_hash( canonical_json(artifact_without_artifact_id) )
```

**Canonicalization errors** are replay certification failures.

---

## Schema Inventory (Phase 16.1)

The following schemas are defined in `RESEARCH_DATA_MODEL.md`:

1. `KnowledgeGap`
2. `ResearchQuestion`
3. `ResearchExperiment`
4. `ResearchEvidence`
5. `ResearchStatisticalValidation`
6. `ResearchTheoryUpdateProposal`
7. `ResearchProgram`
8. `DiscoveryLineage` fragment schema

---

## Cross-schema Validation Rules

For each artifact, validators must confirm:

### A) Shape correctness
- JSON schema validation or equivalent struct validation.

### B) ID correctness
- `*_id` equals the recomputed Blake3 canonical serialization hash.

### C) Reference correctness
- Any referenced IDs must be structurally valid and point to existing immutable artifacts *later in the pipeline*.
  - In Phase 16.1, validators check only syntactic/reference presence requirements; existence checks are replay/audit responsibilities.

### D) Determinism compatibility
- No fields are allowed that:
  - depend on local time at generation
  - depend on network calls
  - depend on hidden runtime mutable state

### E) Certificate compatibility constraints
- Where the schema includes certificate prerequisites:
  - only allow prerequisite types defined in `RESEARCH_CERTIFICATION.md`

---

## Replay-critical Fields (Must be Stable)

For replay determinism, the following fields must be stable across derivations:

- all `*_id` fields (content-addressed)
- canonical serialization representation
- scoring transparency fields inside `ResearchPriority` (if present)
- replay prerequisite arrays (order normalized deterministically)
- lineage graph parent references (`parents`) ordering rules

---

## Example Canonicalization Contract (Spec)

- If the artifact contains arrays:
  - either schema guarantees inherent ordering,
  - or validators must normalize by sorting using stable keys (e.g., referenced ID hashes).

---

## Validation Outcomes

A validator must produce one of:

- `OK`
- `SCHEMA_INVALID` (shape)
- `ID_MISMATCH` (content-address)
- `REFERENCE_INVALID` (bad IDs / missing required reference fields)
- `DETERMINISM_VIOLATION` (non-frozen dependencies)

---

## Summary

`RESEARCH_SCHEMA_REPORT.md` establishes the schema inventory and canonicalization rules required for:
- deterministic replay certification
- evidence-only independent auditing
- archaeological explainability

Implementation occurs after freeze; this document is spec-only.
