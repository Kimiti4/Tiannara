# Extension Guide — CSOS v1.0

## Purpose

Guide for extending the Constitutional Scientific Operating System. Future phases (21 onward) plug into CSOS as constitutional extensions — they consume the certified baseline without modifying it.

## Extension Philosophy

Extensions do not modify CSOS 1.0. They build on top of it:
- CSOS 1.0 is the frozen, immutable foundation
- Extensions add new capabilities as constitutional layers
- Extensions inherit all constitutional guarantees
- Extensions cannot violate any constitutional invariant

## Extension Architecture

```
+----------------------------------------------------------+
|                   Extension Layer                          |
|  Phase 21+: New capabilities built on CSOS 1.0            |
+----------------------------------------------------------+
|                CSOS 1.0 Foundation (frozen)               |
|  Constitutional contracts, replay, archaeology,           |
|  certification, governance, mathematics, science,         |
|  engineering, runtime                                     |
+----------------------------------------------------------+
```

## Extension Types

| Type | Description | Certification Required |
|------|-------------|----------------------|
| Domain extension | New research domain added | Phase certification |
| Service extension | New constitutional service | Full certification |
| Interface extension | New constitutional contract | Interface certification |
| Runtime extension | New runtime capability | Runtime certification |

## Extension Lifecycle

```
1. Proposal    → Extension proposal with evidence chain
2. Review      → Constitutional review of extension scope
3. Compatibility → Compatibility check against frozen constitution
4. Development → Extension implementation (using CSOS APIs)
5. Verification → Extension verification against requirements
6. Certification → Extension certification process
7. Registration → Entry in Constitutional Extension Registry
8. Deployment  → Integration into active generation
```

## Extension Requirements

Every extension must:
1. Define its scope and boundaries
2. Provide complete evidence chain
3. Demonstrate constitutional compatibility
4. Define replay contracts (how it is replayed)
5. Define archaeology contracts (how it is preserved)
6. Define rollback plan (how it is removed)
7. Pass certification process

## Extension Registry

The Constitutional Extension Registry (`CONSTITUTIONAL_EXTENSION_REGISTRY.md`) tracks all approved extensions:
- Extension ID
- Version
- Scope
- Certification evidence
- Deployment status
- Retirement status

## Schema Extensions

Extensions can define new schemas that extend the constitutional schema system:
- New schemas must not conflict with existing schemas
- New schemas must conform to schema extension rules
- New schemas must be registered in the extension registry

## Replay Extensions

Extensions extend the replay chain:
- Extension operations add new steps to the replay chain
- Extension replay must be continuous with CSOS 1.0 replay
- Extension replay must produce identical hashes

## Archaeology Extensions

Extensions extend the archaeology record:
- Extension artifacts are deposited alongside CSOS 1.0 artifacts
- Extension archaeology forms a sub-chain under CSOS 1.0 archaeology
- Extension archaeology must be independently reconstructible

## Versioning

Extensions follow CSOS versioning:
- CSOS 1.0 + Extension 1.0 → Compatible
- CSOS 1.0 + Extension 2.0 → Requires extension re-certification
- CSOS 2.0 + Extension 1.0 → Requires extension compatibility check

## Retirement

Extensions can be retired:
1. Retirement proposal with evidence
2. Compatibility check (no remaining dependencies)
3. Retirement certification
4. Archaeology preservation of retired extension
5. Registry update

## Reference Documents

| Document | Path | Purpose |
|----------|------|---------|
| Extension Framework | `phase20/EXTENSION_FRAMEWORK.md` | Framework specification |
| Extension Schema Report | `phase20/EXTENSION_SCHEMA_REPORT.md` | Schema constraints |
| Extension Registry | `phase20/CONSTITUTIONAL_EXTENSION_REGISTRY.md` | Extension tracking |
| CSOS Certification Standard | `phase20/CSOS_CERTIFICATION_STANDARD.md` | Certification requirements |
| Certification Decision Model | `phase20/CERTIFICATION_DECISION_MODEL.md` | Decision logic |
| Future Generation Bootstrap | `phase20/FUTURE_GENERATION_BOOTSTRAP.md` | Bootstrap procedure |
| Foundational Baseline | `phase20/FOUNDATIONAL_BASELINE.md` | Immutable baseline |
| Future Evolution Framework | `phase20/FUTURE_EVOLUTION_FRAMEWORK.md` | Evolution rules |
