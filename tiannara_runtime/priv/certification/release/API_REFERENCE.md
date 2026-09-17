# API Reference — CSOS v1.0

## Overview

CSOS v1.0 is architecture-only at the constitutional layer. The "API" refers to the set of constitutional contracts, schemas, and replay/archaeology interfaces that all subsystems and extensions must conform to.

## Constitutional Contracts

### Replay Contracts
| Contract | Specification | Schema |
|----------|--------------|--------|
| Replay step format | `REPLAY_SCHEMA.json` | Content-addressed step hashes |
| Step hash computation | SHA-256(stage \|\| input_hash \|\| output_hash \|\| previous_hash) | — |
| Chain root computation | SHA-256(all step hashes in sequence) | — |
| Replay types | Full, Campaign, Scenario, Subsystem | `VALIDATION_REPLAY_SCHEMA.json` |

### Archaeology Contracts
| Contract | Specification | Schema |
|----------|--------------|--------|
| Archaeology deposit format | `ARCHAEOLOGY_SCHEMA.json` | Content-addressed artifact records |
| Chain continuity | Every artifact links to parent via fingerprint | — |
| Cold storage format | Machine-readable + human-readable | — |

### Evidence Chain Contracts
| Contract | Specification | Schema |
|----------|--------------|--------|
| Evidence record format | `AUDIT_EVIDENCE_SCHEMA.json` | Content-addressed evidence items |
| Evidence chain traversal | Walk from root to first evidence item | — |
| Chain root verification | Recompute root from evidence hashes | — |

### Certification Contracts
| Contract | Specification | Schema |
|----------|--------------|--------|
| Certificate format | `CSOS_CERTIFICATE_SCHEMA.json` | System certificate |
| Freeze format | `FOUNDATIONAL_FREEZE_SCHEMA.json` | Constitutional freeze |
| Baseline format | `FOUNDING_BASELINE_SCHEMA.json` | Foundational baseline |
| Archive format | `ARCHIVE_INDEX_SCHEMA.json` | Archive index |

## Schema Reference

All 80 JSON schemas are in `priv/certification/phase20/`. Key schema categories:

| Category | Count | Prefix |
|----------|-------|--------|
| Evolution schemas | 6 | EVOLUTION_*, HYPOTHESIS_*, CANDIDATE_*, ROLLBACK_*, METRICS_* |
| Integration schemas | 4 | INTEGRATION_PROPOSAL_*, PROMOTION_*, TRANSITION_*, ROLLFORWARD_* |
| Engineering schemas | 6 | PROJECT_*, REQUIREMENT_*, DESIGN_*, IMPLEMENTATION_*, VERIFICATION_*, VALIDATION_* |
| Experiment schemas | 6 | EXPERIMENT_*, PLAN_*, RESULT_*, REPLAY_*, ARCHAEOLOGY_*, CERTIFICATE_* |
| Optimization schemas | 6 | CANDIDATE_*, BOTTLENECK_*, TRADEOFF_*, PROFILE_*, REPLAY_*, CERTIFICATE_* |
| Validation schemas | 6 | CAMPAIGN_*, RESULT_*, METRICS_*, FAILURE_*, REPLAY_*, CERTIFICATE_* |
| Audit schemas | 6 | SCOPE_*, EVIDENCE_*, RESULT_*, FINDING_*, REPLAY_*, CERTIFICATE_* |
| Long-horizon schemas | 6 | HISTORY_*, METRICS_*, EVENT_*, CONTINUITY_*, REPLAY_*, CERTIFICATE_* |
| Readiness schemas | 6 | INDEX_*, DIMENSION_*, SCORE_*, DOMAIN_*, REPLAY_*, CERTIFICATE_* |
| Certification schemas | 6 | CERTIFICATE_*, FREEZE_*, INDEX_*, BASELINE_*, REPLAY_*, ARCHAEOLOGY_* |

## Deterministic Timestamp API

All timestamps use `:erlang.unique_integer([:positive])` — never `DateTime.utc_now()` or `System.system_time`.

## Hash API

All content addressing uses SHA-256. The canonical hash computation is:
```
fingerprint = SHA-256(canonical_form(record))
```

Where `canonical_form` is a deterministic serialization of the record's required fields in schema-defined order.
