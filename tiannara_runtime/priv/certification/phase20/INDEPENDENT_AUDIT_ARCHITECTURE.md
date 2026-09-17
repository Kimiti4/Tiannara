# Independent Executable Constitutional Audit (Phase 20.96)

## Mission

An external, evidence-only verifier reconstructs the entire Constitutional Operating System from immutable artifacts. No runtime trust. No implicit assumptions. Only cold storage archaeology and deterministic reconstruction.

## Independence Requirements

The audit is independent if and only if:
1. **No runtime access** — Auditor cannot execute the runtime; only reads cold storage
2. **No implicit trust** — Every artifact hash is independently recomputed
3. **Deterministic reconstruction** — Artifacts are reconstructed from specification alone
4. **Evidence-only** — Claims are accepted only with verifiable evidence chains
5. **Cross-verification** — Two independent auditors must reach identical conclusions
6. **Archaeology isolation** — Auditor operates on an isolated copy of cold storage

## Audit Architecture

```
Cold Storage (isolated copy)
    │
    ├── Phase 18 artifacts (cognitive runtime)
    ├── Phase 19 artifacts (civilizational runtime)
    ├── Phase 20 artifacts (constitutional architecture)
    └── Replay/Archaeology hash chains
         │
         v
+---------------------------+
|  Independent Auditor      |
|  (no runtime, no trust)   |
+---------------------------+
    │
    ├── 1. Reconstruct each artifact from raw data
    ├── 2. Recompute every hash independently
    ├── 3. Verify hash chain continuity
    ├── 4. Verify evidence chain completeness
    ├── 5. Verify determinism (identical inputs → identical hashes)
    ├── 6. Verify constitutional invariants
    └── 7. Produce audit certificate
         │
         v
+---------------------------+
|  Audit Report             |
|  (findings, verdicts,     |
|   certificate)            |
+---------------------------+
```

## What the Auditor Reconstructs

1. **Artifact Reconstruction** — Every struct, engine, schema, and doc rebuilt from raw cold storage data
2. **Hash Verification** — Every SHA-256 hash independently recomputed
3. **Chain Continuity** — Every replay/archaeology chain verified end-to-end
4. **Evidence Completeness** — Every evidence chain verified for completeness
5. **Determinism Verification** — Same inputs → same outputs across independent reconstructions
6. **Dependency Resolution** — All artifact dependencies resolvable within cold storage
7. **Constitutional Compliance** — All artifacts comply with constitutional schema
8. **Generation Lineage** — All generation transitions form a valid lineage tree
