# Phase 20.1 — COS Schema Report

## Overview
Complete schema specification for every constitutional object in the Constitutional Operating System. All 22 ConstitutionalObject subtypes are defined below. All specifications are frozen.

## Base: ConstitutionalObject

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| id | string | yes | content-addressed identifier |
| fingerprint | string | yes | SHA-256 of canonical form |
| created_at | integer | yes | Unix epoch microseconds |
| owner | string | yes | entity that created this object |
| origin | string | yes | source system or process |
| constitutional_version | string | yes | semver of the constitution |
| replay_root | string | no | root hash of replay chain |
| archaeology_root | string | no | root hash of archaeology chain |
| evidence_root | string | no | root hash of evidence chain |
| metadata | object | no | free-form metadata |

**Serialization format:** JSON for artifacts, binary (raw bytes) for hashes.  
**Content-addressing scheme:** `SHA-256(canonical_form(object))` truncated to 64 hex characters.  
**Replay requirements:** Every mutation must produce an identical SHA-256 fingerprint.  
**Archaeology requirements:** Every object must answer all 7 archaeology questions.

## Subtype 1: EvolutionProposal

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| proposal_id | string | yes | unique proposal identifier |
| originating_bottleneck | string | yes | references BottleneckReport.id |
| hypothesis | string | yes | statement of expected improvement |
| expected_improvement | object | yes | key-value metrics with bounds |
| affected_subsystems | array | yes | list of subsystem names |
| status | string | yes | one of: draft, validated, approved, experiment, integrated, archived |

## Subtype 2: BottleneckReport

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| bottleneck_id | string | yes | unique bottleneck identifier |
| subsystem | string | yes | subsystem name |
| severity | number | yes | float 0.0–1.0 |
| evidence | object | yes | evidence block supporting detection |
| detected_by | string | yes | monitor or process that detected it |
| proposed_priority | integer | yes | 1 (highest) to 5 (lowest) |

## Subtype 3: ArchitectureCandidate

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| candidate_id | string | yes | unique candidate identifier |
| proposal | string | yes | references EvolutionProposal.proposal_id |
| architecture_description | string | yes | full architectural description |
| assumptions | array | yes | list of design assumptions |
| expected_metrics | object | yes | predicted metric values |
| benchmark_targets | object | yes | target thresholds for benchmarks |

## Subtype 4: BenchmarkCampaign

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| campaign_id | string | yes | unique campaign identifier |
| candidate | string | yes | references ArchitectureCandidate.candidate_id |
| benchmark_suite | array | yes | list of benchmark names |
| measurements | object | yes | measured values keyed by benchmark |
| status | string | yes | one of: pending, running, completed, failed |

## Subtype 5: ValidationCampaign

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| campaign_id | string | yes | unique validation identifier |
| candidate | string | yes | references ArchitectureCandidate.candidate_id |
| validation_suite | array | yes | list of validation tests |
| results | object | yes | pass/fail per test |
| status | string | yes | one of: pending, running, passed, failed |

## Subtype 6: AuditCampaign

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| campaign_id | string | yes | unique audit identifier |
| target | string | yes | object being audited |
| audit_criteria | array | yes | list of audit checks |
| findings | object | yes | per-criteria findings |
| status | string | yes | one of: pending, running, passed, failed |

## Subtype 7: SandboxDeployment

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| deployment_id | string | yes | unique deployment identifier |
| candidate | string | yes | references ArchitectureCandidate.candidate_id |
| environment | string | yes | "sandbox" |
| start_time | integer | yes | deployment start timestamp |
| end_time | integer | no | deployment end timestamp |
| metrics | object | no | runtime metrics collected |

## Subtype 8: CanaryDeployment

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| deployment_id | string | yes | unique deployment identifier |
| candidate | string | yes | references ArchitectureCandidate.candidate_id |
| environment | string | yes | "canary" |
| traffic_percentage | number | yes | float 0.0–1.0 |
| start_time | integer | yes | deployment start timestamp |
| end_time | integer | no | deployment end timestamp |
| metrics | object | no | runtime metrics collected |

## Subtype 9: ProductionDeployment

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| deployment_id | string | yes | unique deployment identifier |
| candidate | string | yes | references ArchitectureCandidate.candidate_id |
| environment | string | yes | "production" |
| rollout_strategy | string | yes | e.g. "gradual", "blue_green" |
| start_time | integer | yes | deployment start timestamp |
| end_time | integer | no | deployment end timestamp |
| metrics | object | no | runtime metrics collected |

## Subtype 10: RetirementProposal

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| retirement_id | string | yes | unique retirement identifier |
| subsystem | string | yes | subsystem to retire |
| reason | string | yes | justification for retirement |
| replacement | string | no | reference to replacing object |
| status | string | yes | one of: proposed, approved, executed, archived |

## Subtype 11: ExtensionProposal

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| extension_id | string | yes | unique extension identifier |
| name | string | yes | extension name |
| description | string | yes | extension purpose |
| version | string | yes | semver |
| dependencies | array | yes | list of extension dependencies |
| status | string | yes | one of: proposed, approved, registered, retired |

## Subtype 12: ExtensionRegistry

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| registry_id | string | yes | unique registry identifier |
| extensions | array | yes | list of registered ExtensionProposal.extension_id |
| generation | integer | yes | generation at which this registry is current |

## Subtype 13: RuntimeGeneration

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| generation | integer | yes | generation number, monotonically increasing |
| lineage | array | yes | ordered list of generation IDs |
| parent_generation | integer | yes | previous generation number |
| integrated_extensions | array | yes | extension IDs integrated in this generation |
| retired_extensions | array | yes | extension IDs retired in this generation |
| constitutional_hash | string | yes | SHA-256 of full constitutional state |

## Subtype 14: RuntimeSnapshot

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| snapshot_id | string | yes | unique snapshot identifier |
| generation | integer | yes | generation this snapshot captures |
| state_hash | string | yes | SHA-256 of runtime state |
| registry_snapshots | object | yes | snapshot of all registries at this point |
| timestamp | integer | yes | when snapshot was taken |

## Subtype 15: EvolutionDecision

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| decision_id | string | yes | unique decision identifier |
| proposal | string | yes | references EvolutionProposal.proposal_id |
| decision | string | yes | one of: approved, rejected, deferred |
| rationale | string | yes | justification for decision |
| decided_by | string | yes | entity that made the decision |

## Subtype 16: RollbackEvent

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| rollback_id | string | yes | unique rollback identifier |
| generation | integer | yes | generation being rolled back |
| trigger | string | yes | reason for rollback |
| metrics | object | yes | metrics that triggered the rollback |
| restored_generation | integer | yes | generation restored to |

## Subtype 17: ArchitecturalLineage

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| lineage_id | string | yes | unique lineage identifier |
| root_candidate | string | yes | original ArchitectureCandidate.candidate_id |
| successors | array | yes | ordered list of successor candidate IDs |
| generation_span | object | yes | { from: int, to: int } |

## Subtype 18: EvolutionReplay

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| replay_id | string | yes | unique replay identifier |
| generation | integer | yes | generation being replayed |
| replay_chain | array | yes | ordered list of replay step hashes |
| final_hash | string | yes | SHA-256 after replay completes |
| status | string | yes | one of: pending, running, verified, failed |

## Subtype 19: EvolutionEvidence

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| evidence_id | string | yes | unique evidence identifier |
| source | string | yes | source of evidence (benchmark, audit, etc.) |
| claim | string | yes | what this evidence supports or refutes |
| data | object | yes | the evidence data |
| confidence | number | yes | float 0.0–1.0 |

## Subtype 20: EvolutionMetrics

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| metrics_id | string | yes | unique metrics identifier |
| generation | integer | yes | generation these metrics belong to |
| system_metrics | object | yes | latency, throughput, error rates |
| constitutional_metrics | object | yes | proposal velocity, deployment frequency, etc. |
| timestamp | integer | yes | when metrics were collected |

## Subtype 21: ConstitutionalArtifact

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| artifact_id | string | yes | unique artifact identifier |
| type | string | yes | type of artifact (config, binary, manifest) |
| content_hash | string | yes | SHA-256 of artifact content |
| generation | integer | yes | generation that produced this artifact |
| provenance | array | yes | chain of custody |

## Subtype 22: CivilizationSnapshot

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| snapshot_id | string | yes | unique snapshot identifier |
| generation | integer | yes | associated generation |
| scientific_capital | number | yes | cumulative scientific value |
| discovery_rate | number | yes | discoveries per unit time |
| knowledge_growth | number | yes | growth rate of knowledge base |
| research_velocity | number | yes | speed of research execution |
| civilization_readiness | number | yes | readiness score 0.0–1.0 |
