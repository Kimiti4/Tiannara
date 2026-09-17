# Phase 20.1 — COS Data Model

## ConstitutionalObject Hierarchy

All 22 subtypes inherit from the base ConstitutionalObject:

```
ConstitutionalObject (base)
├── EvolutionProposal
├── BottleneckReport
├── ArchitectureCandidate
├── BenchmarkCampaign
├── ValidationCampaign
├── AuditCampaign
├── SandboxDeployment
├── CanaryDeployment
├── ProductionDeployment
├── RetirementProposal
├── ExtensionProposal
├── ExtensionRegistry
├── RuntimeGeneration
├── RuntimeSnapshot
├── EvolutionDecision
├── RollbackEvent
├── ArchitecturalLineage
├── EvolutionReplay
├── EvolutionEvidence
├── EvolutionMetrics
├── ConstitutionalArtifact
└── CivilizationSnapshot
```

## Base Fields (inherited by all subtypes)

| Field | Type | Description |
|-------|------|-------------|
| id | string | Content-addressed identifier |
| fingerprint | string | SHA-256 of canonical form |
| created_at | integer | Unix epoch microseconds |
| owner | string | Entity that created this object |
| origin | string | Source system or process |
| constitutional_version | string | Semver of the constitution |
| replay_root | string | Root hash of replay chain |
| archaeology_root | string | Root hash of archaeology chain |
| evidence_root | string | Root hash of evidence chain |
| metadata | object | Free-form metadata |

## Lifecycle Stages

Each object progresses through a subset of these stages:

| Stage | Description |
|-------|-------------|
| Draft | Object created, not yet validated |
| Validated | Object passes structural validation |
| Replay Verified | Object passes replay hash verification |
| Audited | Object passes audit criteria |
| Certified | Object certified by constitutional authority |
| Integrated | Object integrated into runtime |
| Observed | Object under observation in deployment |
| Archived | Object frozen and moved to cold storage |

### Lifecycle Per Subtype

| Subtype | Lifecycle Stages |
|---------|-----------------|
| EvolutionProposal | Draft → Validated → Replay Verified → Audited → Certified → Integrated → Archived |
| BottleneckReport | Draft → Validated → Replay Verified → Archived |
| ArchitectureCandidate | Draft → Validated → Replay Verified → Audited → Certified → Integrated → Archived |
| BenchmarkCampaign | Draft → Validated → Replay Verified → Audited → Archived |
| ValidationCampaign | Draft → Validated → Replay Verified → Audited → Archived |
| AuditCampaign | Draft → Validated → Replay Verified → Archived |
| SandboxDeployment | Draft → Validated → Replay Verified → Integrated → Observed → Archived |
| CanaryDeployment | Draft → Validated → Replay Verified → Integrated → Observed → Archived |
| ProductionDeployment | Draft → Validated → Replay Verified → Audited → Certified → Integrated → Observed → Archived |
| RetirementProposal | Draft → Validated → Replay Verified → Certified → Integrated → Archived |
| ExtensionProposal | Draft → Validated → Replay Verified → Audited → Certified → Integrated → Archived |
| ExtensionRegistry | Draft → Validated → Replay Verified → Audited → Certified → Archived |
| RuntimeGeneration | Draft → Validated → Replay Verified → Audited → Certified → Integrated → Observed → Archived |
| RuntimeSnapshot | Draft → Validated → Replay Verified → Archived |
| EvolutionDecision | Draft → Validated → Replay Verified → Audited → Certified → Archived |
| RollbackEvent | Draft → Validated → Replay Verified → Audited → Integrated → Archived |
| ArchitecturalLineage | Draft → Validated → Replay Verified → Archived |
| EvolutionReplay | Draft → Validated → Replay Verified → Archived |
| EvolutionEvidence | Draft → Validated → Replay Verified → Audited → Archived |
| EvolutionMetrics | Draft → Validated → Replay Verified → Archived |
| ConstitutionalArtifact | Draft → Validated → Replay Verified → Audited → Certified → Archived |
| CivilizationSnapshot | Draft → Validated → Replay Verified → Audited → Archived |

## Dependency Graph

Dependencies form a Directed Acyclic Graph (DAG). Cycles are prohibited.

```
BottleneckReport
    └──→ EvolutionProposal
              └──→ ArchitectureCandidate
                        ├──→ BenchmarkCampaign
                        ├──→ ValidationCampaign
                        └──→ AuditCampaign
                                   └──→ EvolutionDecision
                                             ├──→ SandboxDeployment
                                             ├──→ CanaryDeployment
                                             └──→ ProductionDeployment
                                                        ├──→ RuntimeGeneration
                                                        ├──→ EvolutionMetrics
                                                        ├──→ CivilizationSnapshot
                                                        └──→ RuntimeSnapshot
                                                                   └──→ RollbackEvent
                                                                   └──→ RetirementProposal
                                                                             └──→ ExtensionProposal
                                                                                        └──→ ExtensionRegistry
EvolutionEvidence ──────→ (supports any object)
EvolutionReplay   ─────→ (verifies any object)
ArchitecturalLineage ──→ (documents candidate ancestry)
ConstitutionalArtifact ─→ (produced by any generation)
```

## Content-Addressing

- Each object's `id` is derived as `SHA-256(canonical_form(object))`.
- The `fingerprint` field stores this hash for cross-verification.
- Any mutation to an object produces a new `id` and `fingerprint`.
- References between objects use `id` values, forming a Merkle DAG.
