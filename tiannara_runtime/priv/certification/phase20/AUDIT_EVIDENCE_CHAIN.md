# Audit Evidence Chain (Phase 20.96)

## Purpose

Define how the auditor reconstructs evidence chains from cold storage artifacts. Every evidence chain must be independently verified without trusting any runtime claims.

## Evidence Chain Structure

Each evidence chain is a sequence of content-addressed records:

```
Evidence[1]: artifact_hash → evidence_hash[1]
Evidence[2]: evidence_hash[1] → evidence_hash[2]
Evidence[N]: evidence_hash[N-1] → evidence_hash[N]
Chain Root: evidence_hash[N]
```

## Reconstruction Procedure

For each evidence chain:

1. Locate the chain root in cold storage
2. Walk the chain from root to first evidence item
3. For each evidence item:
   a. Read the artifact from cold storage
   b. Recompute SHA-256 hash of artifact content
   c. Compare against the claimed artifact hash
   d. Verify the evidence hash chain continuity
4. Verify chain root matches computed root

## Evidence Types

| Type | Description | Reconstruction Method |
|------|-------------|---------------------|
| Artifact evidence | Raw artifact content | Read from cold storage, hash |
| Replay evidence | Replay step record | Replay step deterministically |
| Decision evidence | Decision record | Verify decision inputs → outputs |
| Promotion evidence | Promotion record | Verify promotion stage sequence |
| Transition evidence | Generation transition | Verify source/target hashes |
| Certification evidence | Certificate | Verify all referenced hashes |

## Independence Guarantee

Evidence chains are verified without trust by:
- Starting from cold storage (immutable, independently accessible)
- Recomputing every hash from raw data
- Using only deterministic algorithms (SHA-256, deterministic replay)
- Cross-referencing against second independent reconstruction
