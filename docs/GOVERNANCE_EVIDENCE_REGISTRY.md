# Evidence Registry

**Version**: 1.0.0  
**Status**: 📋 Constitutional Registry  
**Purpose**: Canonical definition of all evidence artifact types  
**Authority**: `GOVERNANCE_VALIDATION_CONSTITUTION.md` Section 2  
**Amendment Process**: RFC → Review Board → Governance Council

---

## Overview

This registry defines all evidence artifact types that campaigns can produce. Campaigns never define evidence schemas inline - they reference entries from this registry.

This ensures uniform evidence structure across all campaigns.

---

## Evidence Type Index

| ID | Name | Schema | Hash Algorithm | Signature Algorithm | Retention Policy | Compression | Replay Policy |
|----|------|--------|----------------|---------------------|------------------|-------------|---------------|
| EVID-001 | Replay Certificate | `ReplayCertificate` | SHA-256 | Ed25519 | Permanent | gzip | Required |
| EVID-002 | Authority Report | `AuthorityReport` | SHA-256 | Ed25519 | Permanent | gzip | Required |
| EVID-003 | Orphan Report | `OrphanReport` | SHA-256 | Ed25519 | Permanent | gzip | Required |
| EVID-004 | Conservation Report | `ConservationReport` | SHA-256 | Ed25519 | Permanent | gzip | Required |
| EVID-005 | Drift Report | `DriftReport` | SHA-256 | Ed25519 | Permanent | gzip | Required |
| EVID-006 | Certificate Audit | `CertificateAudit` | SHA-256 | Ed25519 | Permanent | gzip | Required |
| EVID-007 | Provenance Report | `ProvenanceReport` | SHA-256 | Ed25519 | Permanent | gzip | Required |
| EVID-008 | Archaeology Report | `ArchaeologyReport` | SHA-256 | Ed25519 | Permanent | gzip | Required |
| EVID-009 | Entropy Report | `EntropyReport` | SHA-256 | Ed25519 | 1 year | gzip | Optional |
| EVID-010 | Fitness Report | `FitnessReport` | SHA-256 | Ed25519 | 1 year | gzip | Optional |
| EVID-011 | Cost Report | `CostReport` | SHA-256 | Ed25519 | Permanent | gzip | Required |
| EVID-012 | Stress Report | `StressReport` | SHA-256 | Ed25519 | 1 year | gzip | Optional |

---

## Evidence Type Specifications

### EVID-001: Replay Certificate

```yaml
evidence_id: EVID-001
name: Replay Certificate
description: >
  Cryptographic proof that governance state was reconstructed deterministically
  from ledger with exact equality.

schema:
  type: :replay_certificate
  fields:
    certificate_id: String.t()
    ledger_hash: String.t()
    captured_state_hash: String.t()
    replayed_state_hash: String.t()
    field_verification: Map.t()
    verification_status: :verified | :mismatch | :failed
    timestamp: DateTime.t()
    signature: String.t()

hash_algorithm: :sha256
signature_algorithm: :ed25519

retention_policy:
  duration: :permanent
  archival: true
  deletion_allowed: false

compression:
  algorithm: :gzip
  level: 6

replay_policy:
  required: true
  verify_signature: true
  verify_hash: true
  compare_fingerprints: true

storage:
  format: :content_addressed
  path_pattern: "evidence/replay/{hash}.json"

example:
  certificate_id: "cert-20260613-abc123"
  ledger_hash: "sha256:a1b2c3..."
  captured_state_hash: "sha256:d4e5f6..."
  replayed_state_hash: "sha256:d4e5f6..."
  field_verification:
    institutions: :match
    appointments: :match
    roles: :match
  verification_status: :verified
  timestamp: "2026-06-13T12:00:00Z"
  signature: "sig_xyz789..."
```

---

### EVID-002: Authority Report

```yaml
evidence_id: EVID-002
name: Authority Report
description: >
  Verification results for role-based access control enforcement.

schema:
  type: :authority_report
  fields:
    scenarios_tested: non_neg_integer()
    violations_rejected: non_neg_integer()
    violations_accepted: non_neg_integer()
    false_positives: non_neg_integer()
    false_negatives: non_neg_integer()
    per_scenario_results: [Map.t()]
    timestamp: DateTime.t()
    signature: String.t()

hash_algorithm: :sha256
signature_algorithm: :ed25519

retention_policy:
  duration: :permanent
  archival: true
  deletion_allowed: false

compression:
  algorithm: :gzip
  level: 6

replay_policy:
  required: true
  verify_signature: true
  verify_hash: true

storage:
  format: :content_addressed
  path_pattern: "evidence/authority/{hash}.json"
```

---

### EVID-003: Orphan Report

```yaml
evidence_id: EVID-003
name: Orphan Report
description: >
  Detection results for orphaned capabilities without valid lineage.

schema:
  type: :orphan_report
  fields:
    capabilities_checked: non_neg_integer()
    orphans_found: non_neg_integer()
    broken_chains: non_neg_integer()
    chain_lengths: Map.t()
    orphan_details: [Map.t()]
    timestamp: DateTime.t()
    signature: String.t()

hash_algorithm: :sha256
signature_algorithm: :ed25519

retention_policy:
  duration: :permanent
  archival: true
  deletion_allowed: false

compression:
  algorithm: :gzip
  level: 6

replay_policy:
  required: true
  verify_signature: true
  verify_hash: true

storage:
  format: :content_addressed
  path_pattern: "evidence/orphan/{hash}.json"
```

---

### EVID-009: Entropy Report

```yaml
evidence_id: EVID-009
name: Entropy Report
description: >
  Time-series entropy measurements during proposal simulation.

schema:
  type: :entropy_report
  fields:
    proposals_simulated: non_neg_integer()
    entropy_readings: [float()]
    behavior_pattern: :increase_stabilize_decrease | :unbounded | :oscillating
    final_entropy: float()
    divergence_detected: boolean()
    trend_analysis: Map.t()
    timestamp: DateTime.t()
    signature: String.t()

hash_algorithm: :sha256
signature_algorithm: :ed25519

retention_policy:
  duration: "1 year"
  archival: false
  deletion_allowed: true

compression:
  algorithm: :gzip
  level: 9  # Higher compression for time-series data

replay_policy:
  required: false
  verify_signature: true
  verify_hash: true

storage:
  format: :content_addressed
  path_pattern: "evidence/entropy/{hash}.json.gz"
```

---

### EVID-012: Stress Report

```yaml
evidence_id: EVID-012
name: Stress Report
description: >
  Performance metrics under scaled governance load.

schema:
  type: :stress_report
  fields:
    config: Map.t()
    cpu_usage: float()
    memory_mb: float()
    replay_time_ms: non_neg_integer()
    entropy_at_scale: float()
    fitness_at_scale: float()
    performance_acceptable: boolean()
    bottlenecks: [String.t()]
    recommendations: [String.t()]
    timestamp: DateTime.t()
    signature: String.t()

hash_algorithm: :sha256
signature_algorithm: :ed25519

retention_policy:
  duration: "1 year"
  archival: false
  deletion_allowed: true

compression:
  algorithm: :gzip
  level: 9

replay_policy:
  required: false
  verify_signature: true
  verify_hash: true

storage:
  format: :content_addressed
  path_pattern: "evidence/stress/{hash}.json.gz"
```

---

## Usage in Campaign Registry

Campaigns reference evidence types by ID:

```yaml
campaign_id: GV-001
evidence_type: EVID-001  # Replay Certificate
```

The runtime looks up schema and storage rules from this registry.

---

## Evidence Artifact Structure

All evidence artifacts follow this canonical wrapper:

```elixir
%EvidenceArtifact{
  evidence_id: String.t(),          # e.g., "EVID-001"
  campaign_id: String.t(),          # e.g., "GV-001"
  campaign_version: String.t(),     # e.g., "1.0.0"
  timestamp: DateTime.t(),
  input_fingerprint: String.t(),
  output_fingerprint: String.t(),
  content_hash: String.t(),         # SHA-256 of actual content
  signature: String.t(),            # Ed25519 signature
  content: map()                    # Actual evidence data (schema-specific)
}
```

### Content-Addressed Storage

Artifacts stored as:
```
evidence/
  {content_hash}.json      # Uncompressed
  {content_hash}.json.gz   # Compressed (if compression enabled)
```

Index file maps evidence_id to hash:
```json
{
  "EVID-001": {
    "hash": "a1b2c3d4e5f6...",
    "path": "evidence/a1b2c3d4e5f6.json",
    "compressed": false
  }
}
```

---

## Version History

| Version | Date | Changes | Amended By |
|---------|------|---------|------------|
| 1.0.0 | 2026-06-13 | Initial evidence registry | Governance Council |

---

**Signed**: Tiannara Constitutional Architecture Team  
**Date**: June 13, 2026  
**Authority**: Governance Council Ratification Required
