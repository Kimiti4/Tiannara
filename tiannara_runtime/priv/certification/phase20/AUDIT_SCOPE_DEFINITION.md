# Audit Scope Definition (Phase 20.96)

## Purpose

Precisely define what the independent audit covers and what it excludes. Scope boundaries prevent scope creep and ensure the auditor knows exactly what to verify.

## In Scope

### All Constitutional Artifacts
- Phase 18: Cognitive runtime artifacts (69 structs, 63 engines, 17 behaviours, 7 docs)
- Phase 19: Civilizational runtime artifacts (61 modules, 30 docs, 17 certification docs)
- Phase 20: Constitutional architecture artifacts (178+ docs, schemas, certification docs)
- All replay hash chains
- All archaeology deposit records
- All evidence chains
- All certification documents

### All Constitutional Domains
- State, Knowledge, Mathematics, World Model, Planning, Runtime, Archaeology

### All Generation Records
- Every generation transition
- Every promotion decision
- Every rollback/rollforward record
- Generation lineage tree

### Audit Types
- Replay audit — Reconstruct and verify all replay chains
- Evidence audit — Verify all evidence chains
- Hash audit — Independently recompute all hashes
- Structure audit — Verify schema conformance
- Dependency audit — Verify dependency resolution
- Lineage audit — Verify generation lineage
- Full audit — All audit types combined

## Out of Scope
- Runtime behaviour (executing code) — auditor has no runtime
- Performance characteristics — not relevant to constitutional integrity
- Future system behavior — only past artifacts matter
- External dependencies not preserved in cold storage
- Human-readable documentation not part of the constitutional record
