# Audit Integrity Check (Phase 20.96)

## Purpose

Verify that all constitutional invariants are preserved across the entire artifact set. The auditor checks each invariant independently from cold storage — no runtime trust required.

## Constitutional Invariants

### I1: Determinism
- Every deterministic computation produces identical output for identical input
- Verified by: Running spec 3+ times, comparing hashes

### I2: Replayability
- Every step in every chain is deterministically replayable
- Verified by: Replaying each chain from cold storage

### I3: Hash Chain Continuity
- Every hash chain is continuous (no gaps, no reorders)
- Verified by: Walking each chain, verifying step hashes

### I4: Evidence Completeness
- Every claim has a complete evidence chain
- Verified by: Walking each evidence chain to its root

### I5: Knowledge Preservation
- Knowledge never decreases across generations
- Verified by: Comparing knowledge snapshots across generations

### I6: Scientific Capital Preservation
- Scientific capital never decreases
- Verified by: Comparing capital records across generations

### I7: Generation Lineage
- Generation tree is acyclic and continuous
- Verified by: Reconstructing lineage tree from transition records

### I8: Schema Conformance
- Every artifact conforms to its schema
- Verified by: Validating each artifact against its schema

### I9: Dependency Completeness
- Every artifact dependency is resolvable within cold storage
- Verified by: Traversing dependency graph

### I10: Certificate Validity
- Every certificate references valid, verified artifacts
- Verified by: Following certificate evidence chains

## Integrity Scoring

Each invariant is scored:
- **1.0** — Invariant fully preserved
- **0.0** — Invariant violated (critical finding)
- **Partial** — Some aspects preserved, others not (finding recorded)

## Output

Complete integrity report containing:
- Per-invariant verdict
- Per-subsystem integrity score
- Any invariant violations as audit findings
- Overall integrity score
