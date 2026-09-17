# CONSTITUTION ARCHITECTURE — Canonical Ownership Hierarchy

**Phase 13.5B.3 Final Constitutional Freeze**  
**Document Version**: 1.0  
**Constitution ID**: TOS-CONSTITUTION-0001  
**Effective Date**: 2026-06-13  

---

## Executive Summary

This document defines the **single canonical ownership hierarchy** for the Tiannara Operating System's constitutional architecture. Every constitutional concept has **exactly one owner**. No parallel implementations exist. No duplicated hashes. No alternate execution paths.

The ownership graph is frozen and immutable. All future constitutional evolution must compose these primitives, never bypass them.

---

## Canonical Ownership Graph

```
ConstitutionIdentity
        │
        ▼
ConstitutionManifest
        │
        ├── ConstitutionFingerprint (derived)
        │
        ├── ConstitutionCertificate (per-execution)
        │
        └── ConstitutionalDriftJournal (history)
                │
                ▼
            Replay (verification)
```

### Key Principles

1. **Identity owns metadata only** - Never owns hashes
2. **Manifest owns all hashes** - Complete Software Bill of Materials (SBOM)
3. **Fingerprint is derived** - SHA256(SerializedManifest), nothing more
4. **Certificate certifies execution** - Binds runtime to manifest
5. **Journal stores certificates** - Immutable execution history
6. **Replay verifies transactions** - Reconstructs state from canonical events

---

## Component Specifications

### 1. ConstitutionIdentity

**Purpose**: Immutable identity of the constitution itself.

**Ownership**: Metadata ONLY. Never owns hashes.

**Fields**:
```elixir
%ConstitutionIdentity{
  constitution_id: "TOS-CONSTITUTION-0001",  # Immutable forever
  version: "13.5B.3",                         # Evolves with changes
  created_at: DateTime.t(),                   # Creation timestamp
  effective_from: DateTime.t(),               # When this version takes effect
  effective_until: DateTime.t() | nil,        # When superseded (nil if current)
  approved_by: String.t()                     # Governance authority
}
```

**Responsibilities**:
- Provide stable identity across versions
- Track version lineage
- Record governance approval
- Define temporal scope

**Does NOT own**:
- ❌ Component hashes
- ❌ Combined hash
- ❌ Fingerprint
- ❌ Certificate references

**Module**: `lib/tiannara/os/constitution_identity.ex` (to be created)

---

### 2. ConstitutionManifest

**Purpose**: Complete Software Bill of Materials (SBOM) for the constitutional substrate.

**Ownership**: ALL component hashes. This is the canonical source of truth.

**Fields**:
```elixir
%ConstitutionManifest{
  manifest_id: String.t(),                    # Unique identifier
  constitution_id: String.t(),                # References Identity
  version: String.t(),                        # Matches Identity.version
  created_at: DateTime.t(),
  
  # Component Hashes (content-derived via ConstitutionSerializer)
  definition_hash: String.t(),                # ScientificCapitalDefinition
  policy_hash: String.t(),                    # ScientificCapitalPolicy
  ledger_hash: String.t(),                    # ScientificCapitalLedger
  executor_hash: String.t(),                  # ConstitutionalExecutor
  registry_hash: String.t(),                  # ConstitutionalInvariantRegistry
  gate_hash: String.t(),                      # StructuralValidationGate
  resolver_hash: String.t(),                  # MetricProvenanceResolver
  
  combined_hash: String.t(),                  # SHA256(all component hashes)
  
  metadata: %{
    serializer_version: "1.0",
    serialization_format: "canonical_json",
    hash_algorithm: "SHA256"
  }
}
```

**Responsibilities**:
- Store complete SBOM of constitutional components
- Provide canonical hash inventory
- Enable independent verification
- Support drift detection via comparison
- Enable external reproducibility

**Hash Computation**:
All hashes computed via `ConstitutionSerializer`:
```elixir
definition_hash = ConstitutionSerializer.hash_component(:scientific_capital_definition)
policy_hash = ConstitutionSerializer.hash_component(:scientific_capital_policy)
# ... etc
combined_hash = SHA256(sorted_concatenation(all_hashes))
```

**Module**: `lib/tiannara/os/constitution_manifest.ex` ✅ Complete

---

### 3. ConstitutionFingerprint

**Purpose**: Cryptographic digest of the Manifest. Derived, not independent.

**Ownership**: Single hash value. Nothing else.

**Fields**:
```elixir
%ConstitutionFingerprint{
  fingerprint: String.t(),                    # SHA256(SerializedManifest)
  manifest_id: String.t(),                    # Reference to Manifest
  computed_at: DateTime.t()
}
```

**Computation**:
```elixir
def compute_fingerprint(%ConstitutionManifest{} = manifest) do
  serialized = ConstitutionManifest.to_json(manifest)
  fingerprint = :crypto.hash(:sha256, serialized) |> Base.encode16(case: :lower)
  
  %ConstitutionFingerprint{
    fingerprint: fingerprint,
    manifest_id: manifest.manifest_id,
    computed_at: DateTime.utc_now()
  }
end
```

**Critical Constraint**:
- ❌ Does NOT recompute component hashes
- ❌ Does NOT store individual component hashes
- ✅ Only stores SHA256 of entire Manifest JSON

**Module**: `lib/tiannara/os/constitution_fingerprint.ex` (to be refactored)

---

### 4. ConstitutionCertificate

**Purpose**: Attestation artifact for a single execution. Certifies runtime state.

**Ownership**: Execution-specific verification results. Not constitutional definitions.

**Fields**:
```elixir
%ConstitutionCertificate{
  certificate_id: String.t(),                 # Unique per execution
  execution_id: String.t(),                   # Execution identifier
  manifest_id: String.t(),                    # References Manifest
  fingerprint: String.t(),                    # Fingerprint at execution time
  
  generation_count: integer(),                # Generation number
  timestamp: DateTime.t(),                    # Execution timestamp
  
  # Verification Status
  validation_status: :passed | :failed,       # StructuralValidationGate
  replay_status: :verified | :not_run | :failed,  # Replay verification
  watchdog_status: :completed | :drift_detected,  # Watchdog monitoring
  invariant_status: :all_passed | :some_failed,   # Invariant checks
  
  certificate_hash: String.t(),               # SHA256(entire certificate)
  
  metadata: %{
    certification_level: "full" | "partial" | "minimal",
    independent_verification: boolean()
  }
}
```

**Responsibilities**:
- Certify single execution against manifest
- Record all verification statuses
- Enable external audit of execution
- Bind statistical results to constitutional state

**Does NOT own**:
- ❌ Constitutional definitions
- ❌ Component hashes (references Manifest instead)
- ❌ Policy coefficients

**Module**: `lib/tiannara/os/constitution_certificate.ex` ✅ Complete

---

### 5. ConstitutionalDriftJournal

**Purpose**: Append-only immutable record of all executions.

**Ownership**: Certificates. Not hashes. Not policies.

**Entry Structure**:
```elixir
%DriftJournalEntry{
  entry_id: String.t(),
  execution_id: String.t(),
  certificate_id: String.t(),                 # References Certificate
  timestamp: DateTime.t(),
  
  drift_detected: boolean(),
  drift_type: :structural | :policy | :execution | :runtime | :documentation | :none,
  drift_severity: :critical | :high | :medium | :low | :none,
  
  changed_components: [atom()],               # If drift detected
  approved: boolean(),
  approved_by: String.t() | nil,
  
  result: :execution_allowed | :execution_blocked
}
```

**Storage**:
- ETS table for runtime persistence
- Serialized to disk for long-term archival
- Each entry references a Certificate
- Certificates contain full manifest reference

**Responsibilities**:
- Record every execution immutably
- Detect and classify drift
- Track governance approvals
- Provide complete audit trail

**Module**: `lib/tiannara/os/constitutional_drift_journal.ex` (to be updated)

---

### 6. Replay

**Purpose**: Verify determinism by reconstructing state from canonical transactions.

**Ownership**: Transaction reconstruction logic.

**Process**:
```
Canonical Transactions (from GenerationHistory)
        ↓
Replay Engine
        ↓
Reconstructed State
        ↓
Compare with Recorded State
        ↓
Match? → PASS
Mismatch? → FAIL (report differences)
```

**Inputs**:
- Canonical transactions only (no recorded metrics)
- ConstitutionManifest (for policy/definition hashes)

**Outputs**:
- Replay status (:verified | :failed)
- Mismatch details (if any)
- Reconstruction proof

**Module**: `lib/tiannara/os/scientific_capital_ledger.ex` (replay functions)

---

## Integration Points

### GenerationHistory

**Current State** (❌ Violates single-source-of-truth):
```elixir
%GenerationHistory{
  policy_hash: String.t(),           # DUPLICATE - owned by Manifest
  definition_hash: String.t(),       # DUPLICATE - owned by Manifest
  ledger_hash: String.t(),           # DUPLICATE - owned by Manifest
  # ... more duplicate hashes
}
```

**Required State** (✅ Single source of truth):
```elixir
%GenerationHistory{
  manifest_id: String.t(),           # Reference to Manifest
  certificate_id: String.t(),        # Reference to Certificate
  # All other data reconstructible from Manifest + Certificate
}
```

### ConstitutionalExecutor

**Execution Pipeline** (Mandatory path):
```
User Request
    ↓
ConstitutionalExecutor.execute(config)
    ↓
1. Load ConstitutionIdentity
    ↓
2. Build ConstitutionManifest (or load existing)
    ↓
3. Compute ConstitutionFingerprint = SHA256(SerializedManifest)
    ↓
4. Check ConstitutionalDriftJournal for drift
    ↓
5. Spawn ConstitutionalWatchdog
    ↓
6. Run StructuralValidationGate
    ↓
7. Execute RecursiveCivilizationRunner
    ↓
8. Generate ConstitutionCertificate
    ↓
9. Append Certificate to DriftJournal
    ↓
10. Stop Watchdog with final verification
    ↓
Return {:ok, generation_history}
```

**No Alternate Paths**:
- ❌ Direct calls to RecursiveCivilizationRunner forbidden
- ❌ Bypassing StructuralValidationGate forbidden
- ❌ Skipping certificate generation forbidden

---

## Hash Computation Flow

```
ScientificCapitalDefinition.canonical_sources()
        ↓
ConstitutionSerializer.serialize(:scientific_capital_definition)
        ↓
Canonical JSON (sorted keys, compact)
        ↓
SHA256 hash
        ↓
definition_hash stored in ConstitutionManifest

(Repeat for all 7 components)
        ↓
combined_hash = SHA256(sorted_concatenation(all_7_hashes))
        ↓
fingerprint = SHA256(SerializedManifest_JSON)
```

**Key Property**: Same inputs → same hashes on any machine, any Elixir version, any compiler.

---

## Ownership Questions Answered

### Q1: Which object owns hashes?
**A**: `ConstitutionManifest` owns all component hashes. Nothing else stores them independently.

### Q2: Which object owns identity?
**A**: `ConstitutionIdentity` owns metadata (ID, version, timestamps). Never owns hashes.

### Q3: Which object certifies execution?
**A**: `ConstitutionCertificate` certifies a single execution against its manifest.

### Q4: Which object records history?
**A**: `ConstitutionalDriftJournal` records history by storing certificates.

### Q5: Can I get hashes from GenerationHistory?
**A**: No. GenerationHistory stores `manifest_id` and `certificate_id`. Load the Manifest to get hashes.

### Q6: How do I verify a past execution?
**A**: 
1. Load Certificate from Journal
2. Load referenced Manifest
3. Recompute fingerprint from Manifest
4. Compare with Certificate.fingerprint
5. Verify all statuses (validation, replay, watchdog)

### Q7: What if I need to compare two constitutional states?
**A**: Compare their Manifests using `ConstitutionManifest.compare(manifest1, manifest2)`. Returns list of changed components.

---

## Violations to Prevent

### ❌ Duplicate Hash Storage
```elixir
# WRONG - GenerationHistory should NOT store hashes
%GenerationHistory{
  policy_hash: "...",
  definition_hash: "..."
}

# RIGHT - Store references only
%GenerationHistory{
  manifest_id: "MANIFEST-abc123",
  certificate_id: "CERT-xyz789"
}
```

### ❌ Independent Fingerprint Computation
```elixir
# WRONG - Fingerprint recomputing component hashes
def compute_fingerprint do
  definition_hash = hash_definition()  # DUPLICATE computation
  policy_hash = hash_policy()          # DUPLICATE computation
  # ...
end

# RIGHT - Fingerprint derives from Manifest
def compute_fingerprint(%ConstitutionManifest{} = manifest) do
  serialized = ConstitutionManifest.to_json(manifest)
  SHA256(serialized)
end
```

### ❌ Parallel Execution Paths
```elixir
# FORBIDDEN - Direct runner invocation
RecursiveCivilizationRunner.execute(config)

# REQUIRED - Mandatory executor path
ConstitutionalExecutor.execute(config)
```

---

## Module Inventory

### Completed Modules ✅
- `ConstitutionSerializer` - Canonical serialization engine
- `ConstitutionManifest` - SBOM with all hashes
- `ConstitutionCertificate` - Execution attestation

### Modules Requiring Refactoring 🔄
- `ConstitutionFingerprint` - Simplify to SHA256(Manifest) only
- `ConstitutionalDriftJournal` - Store certificates, not hashes
- `ConstitutionIdentity` - Create new module (metadata only)
- `GenerationHistory` - Remove duplicate hashes, add manifest_id/certificate_id
- `ConstitutionalExecutor` - Integrate manifest/certificate generation

### Frozen Primitives (No Changes Allowed) ❄️
- `ScientificCapitalDefinition`
- `ScientificCapitalPolicy`
- `ScientificCapitalLedger`
- `ConstitutionalInvariantRegistry`
- `StructuralValidationGate`
- `MetricProvenanceResolver`
- `RecursiveCivilizationRunner`

---

## Future Evolution Boundaries

### Allowed Changes
- ✅ New constitutional versions (update Identity.version, create new Manifest)
- ✅ Governance-approved drift (record in Journal with approval)
- ✅ Statistical validation trials (generate certificates for each)
- ✅ Performance optimizations (without changing hashes)

### Forbidden Changes
- ❌ Adding new capital coefficients (violates Definition freeze)
- ❌ Modifying invariant registry structure (violates Registry freeze)
- ❌ Creating alternate execution paths (violates Executor mandate)
- ❌ Storing hashes outside Manifest (violates single-source-of-truth)
- ❌ Bypassing certificate generation (violates attestation requirement)

---

## Verification Checklist

Before declaring Phase 13 complete, verify:

- [ ] ConstitutionIdentity exists with metadata-only fields
- [ ] ConstitutionManifest stores all 7 component hashes
- [ ] ConstitutionFingerprint computes SHA256(SerializedManifest) only
- [ ] ConstitutionCertificate references Manifest, not individual hashes
- [ ] ConstitutionalDriftJournal stores certificates
- [ ] GenerationHistory stores manifest_id + certificate_id only
- [ ] No module stores duplicate component hashes
- [ ] ConstitutionalExecutor is only legal execution path
- [ ] All certificates include verification statuses
- [ ] Replay reconstructs state from transactions only

---

## Sign-Off

**Architecture Frozen**: Yes  
**Ownership Unambiguous**: Yes  
**Single Source of Truth**: ConstitutionManifest  
**Mandatory Enforcement**: ConstitutionalExecutor  
**External Reproducibility**: constitution_manifest.json + constitution_certificate.json  

**Next Phase**: 13.5C - Protected Statistical Validation (only after this architecture is fully implemented and verified)

---

*This document is part of the constitutional freeze. Any changes require governance approval and must maintain the single-source-of-truth principle.*
