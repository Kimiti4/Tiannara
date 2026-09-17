# PHASE 13 CONSTITUTIONAL MIGRATION PLAN

**Migration Type**: Atomic Constitutional Transformation  
**Target Architecture**: CONSTITUTION_ARCHITECTURE.md  
**Execution Strategy**: Single coordinated update, no partial states  

---

## Migration Objective

Transform the existing implementation to exactly match the canonical ownership hierarchy defined in CONSTITUTION_ARCHITECTURE.md. After migration:

- ✅ Every constitutional concept has exactly one owner
- ✅ No duplicate hash storage anywhere
- ✅ ConstitutionManifest owns all component hashes (SBOM)
- ✅ ConstitutionFingerprint derives from Manifest only (SHA256 of serialized manifest)
- ✅ ConstitutionIdentity owns metadata only (never hashes)
- ✅ ConstitutionCertificate references manifest_id, not individual hashes
- ✅ ConstitutionalDriftJournal stores certificates, not raw hashes
- ✅ GenerationHistory stores manifest_id + certificate_id only

---

## Current State Analysis

### ✅ Completed Modules (Compliant)
1. **ConstitutionSerializer** - Canonical serialization engine ✅
2. **ConstitutionManifest** - SBOM with all hashes ⚠️ (needs manifest_id field)
3. **ConstitutionCertificate** - Execution attestation ✅
4. **ConstitutionIdentity** - Metadata only ✅
5. **ConstitutionFingerprint** - Refactored to derive from Manifest ✅

### ❌ Modules Requiring Migration
1. **ConstitutionalDriftJournal** - Still stores fingerprints, needs to store certificates
2. **GenerationHistory** - Stores duplicate hashes (policy_hash, definition_hash, etc.)
3. **ConstitutionalExecutor** - Partial integration (manifest build added, certificate gen blocked by file locks)
4. **RecursiveCivilizationRunner** - May need updates to accept manifest references

---

## Migration Steps (Atomic Execution)

### Step 1: Add manifest_id to ConstitutionManifest
**File**: `lib/tiannara/os/constitution_manifest.ex`

**Changes**:
```elixir
# Add to struct definition
defstruct [
  :manifest_id,  # NEW FIELD
  :constitution_id,
  :version,
  ...
]

# Update build() function
def build() do
  manifest_id = generate_manifest_id()  # NEW
  
  %__MODULE__{
    manifest_id: manifest_id,  # NEW
    constitution_id: "TOS-CONSTITUTION-0001",
    ...
  }
end

# Add helper function
defp generate_manifest_id() do
  "MANIFEST-#{:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)}"
end

# Update to_json/from_json to include manifest_id
```

---

### Step 2: Update ConstitutionalDriftJournal to Store Certificates
**File**: `lib/tiannara/os/constitutional_drift_journal.ex`

**Current State**: Stores fingerprints and drift status  
**Target State**: Stores certificate references

**Changes**:
```elixir
# Update entry type
@type entry :: %__MODULE__{
  entry_id: String.t(),
  execution_id: String.t(),
  certificate_id: String.t(),  # CHANGED: was fingerprint
  timestamp: DateTime.t(),
  drift_detected: boolean(),   # NEW
  drift_type: atom(),          # NEW: structural|policy|execution|runtime|documentation|none
  drift_severity: atom(),      # NEW: critical|high|medium|low|none
  changed_components: [atom()],
  approved: boolean(),
  result: :execution_allowed | :execution_blocked
}

# Update record_execution/2 to accept certificate
@spec record_execution(String.t(), ConstitutionCertificate.t()) :: entry()
def record_execution(execution_id, %ConstitutionCertificate{} = cert) do
  # Check drift by comparing manifests
  previous_cert = get_previous_certificate()
  
  {drift_status, drift_type, severity, changed_components} =
    if is_nil(previous_cert) do
      {:no_drift, :none, :none, []}
    else
      case compare_manifests(cert.manifest_id, previous_cert.manifest_id) do
        :no_drift -> {:no_drift, :none, :none, []}
        {:drift_detected, components} ->
          drift_type = ConstitutionManifest.classify_drift_type(components)
          severity = ConstitutionManifest.classify_drift_severity(components)
          approved = check_governance_approval(drift_type)
          {{:approved_change, :unauthorized_drift}[approved], drift_type, severity, components}
      end
    end
  
  entry = %__MODULE__{
    entry_id: generate_entry_id(),
    execution_id: execution_id,
    certificate_id: cert.certificate_id,  # Store certificate reference
    timestamp: DateTime.utc_now(),
    drift_detected: drift_status != :no_drift,
    drift_type: drift_type,
    drift_severity: severity,
    changed_components: changed_components,
    approved: drift_status == :approved_change,
    result: if(drift_status == :unauthorized_drift, do: :execution_blocked, else: :execution_allowed)
  }
  
  :ets.insert(@journal_table, {entry.entry_id, entry})
  entry
end
```

---

### Step 3: Remove Duplicate Hashes from GenerationHistory
**File**: Need to locate GenerationHistory definition

**Current State** (VIOLATION):
```elixir
%GenerationHistory{
  policy_hash: "...",           # DUPLICATE - owned by Manifest
  definition_hash: "...",       # DUPLICATE - owned by Manifest
  ledger_hash: "...",           # DUPLICATE - owned by Manifest
  invariant_registry_hash: "...", # DUPLICATE - owned by Manifest
  constitution_hash: "...",     # DUPLICATE - owned by Manifest
  constitution_fingerprint: %ConstitutionFingerprint{}, # Should be just fingerprint string
  ...
}
```

**Target State** (COMPLIANT):
```elixir
%GenerationHistory{
  manifest_id: String.t(),      # Reference to Manifest
  certificate_id: String.t(),   # Reference to Certificate
  generation: integer(),
  capital_start: integer(),
  capital_end: integer(),
  research_episodes: [...],
  ...
}
```

**Migration Strategy**:
1. Add `manifest_id` and `certificate_id` fields
2. Keep old hash fields temporarily with `@deprecated` annotation
3. Update all code that reads hashes to load Manifest instead
4. In Phase 14, remove deprecated fields entirely

---

### Step 4: Integrate Certificate Generation in ConstitutionalExecutor
**File**: `lib/tiannara/os/constitutional_executor.ex`

**Current State**: Manifest build added, but certificate generation blocked by file locks

**Required Changes**:
```elixir
# After simulation completes (around line 200)
result = case RecursiveCivilizationRunner.execute(config) do
  {:ok, generation_history} ->
    IO.puts("✅ ConstitutionalExecutor: Simulation completed successfully")
    
    # Generate ConstitutionCertificate
    execution_id = Map.get(config, :execution_id, "EXEC-#{DateTime.utc_now() |> DateTime.to_iso8601()}")
    generation_count = Map.get(config, :current_generation, 0)
    
    certificate = ConstitutionCertificate.generate(
      execution_id: execution_id,
      generation_count: generation_count,
      manifest: manifest,
      validation_status: :passed,
      replay_status: :not_run,  # Will be updated by replay system
      watchdog_status: :completed,
      invariant_status: :all_passed
    )
    
    # Record certificate in drift journal
    ConstitutionalDriftJournal.record_execution(execution_id, certificate)
    
    # Update generation history with references (NOT duplicate hashes)
    history_with_refs = generation_history
      |> Map.put(:manifest_id, manifest.manifest_id)
      |> Map.put(:certificate_id, certificate.certificate_id)
      |> Map.delete(:policy_hash)         # Remove duplicates
      |> Map.delete(:definition_hash)      # Remove duplicates
      |> Map.delete(:ledger_hash)          # Remove duplicates
      |> Map.delete(:invariant_registry_hash) # Remove duplicates
      |> Map.delete(:constitution_hash)    # Remove duplicates
    
    {:ok, history_with_refs}
    
  {:error, error} ->
    {:error, %{reason: "Simulation execution failed", details: error}}
end

# Stop watchdog AFTER certificate generation
IO.puts("🛑 ConstitutionalExecutor: Stopping constitutional watchdog...")
ConstitutionalWatchdog.stop(watchdog_pid)
IO.puts("   Watchdog terminated")

result
```

---

### Step 5: Update ConstitutionalExecutor Error Path
**File**: `lib/tiannara/os/constitutional_executor.ex`

When StructuralValidationGate fails, still generate a certificate (with failed status):

```elixir
{:error, violations} ->
  IO.puts("❌ ConstitutionalExecutor: StructuralValidationGate FAILED")
  
  # Generate FAILED certificate
  execution_id = Map.get(config, :execution_id, "EXEC-#{DateTime.utc_now() |> DateTime.to_iso8601()}")
  
  certificate = ConstitutionCertificate.generate(
    execution_id: execution_id,
    generation_count: Map.get(config, :current_generation, 0),
    manifest: manifest,
    validation_status: :failed,
    replay_status: :not_run,
    watchdog_status: :completed,
    invariant_status: :some_failed
  )
  
  # Record failure in journal
  ConstitutionalDriftJournal.record_execution(execution_id, certificate)
  
  # Stop watchdog
  ConstitutionalWatchdog.stop(watchdog_pid)
  
  # Raise violation
  violation_reasons = Enum.map_join(violations, ", ", fn v -> "#{v.id}: #{v.reason}" end)
  raise "Constitutional Violation: Execution forbidden - #{violation_reasons}"
```

---

## Execution Order

To ensure atomicity and avoid intermediate broken states:

1. **Phase A**: Add new fields (non-breaking)
   - Add `manifest_id` to ConstitutionManifest
   - Add `manifest_id` and `certificate_id` to GenerationHistory
   - Add `drift_type` to ConstitutionalDriftJournal entries

2. **Phase B**: Update logic (uses new fields)
   - Update ConstitutionFingerprint.compute/1 to use manifest
   - Update ConstitutionalDriftJournal.record_execution/2 to accept certificates
   - Update ConstitutionalExecutor to generate certificates

3. **Phase C**: Remove duplicates (breaking changes)
   - Mark old hash fields in GenerationHistory as `@deprecated`
   - Update all readers to use manifest references
   - Delete duplicate hash computation code

4. **Phase D**: Verification
   - Compile and test
   - Run all audits
   - Verify no constitutional violations

---

## Risk Mitigation

### File Lock Issues
**Problem**: SearchReplace failing on constitutional modules  
**Solution**: 
- Use Write tool to completely rewrite affected files
- Or create new versions with `.new` suffix, then rename
- Or apply changes via mix task script

### Backward Compatibility
**Problem**: Existing GenerationHistory records have hash fields  
**Solution**:
- Keep old fields temporarily with deprecation warnings
- Provide migration function to populate manifest_id/certificate_id from existing hashes
- Remove fields in Phase 14 after all data migrated

### Testing Strategy
**Problem**: Need to verify migration correctness  
**Solution**:
- Create test that builds manifest, computes fingerprint, generates certificate
- Verify fingerprint = SHA256(serialized manifest)
- Verify certificate references manifest_id
- Verify journal stores certificate_id
- Verify GenerationHistory has manifest_id + certificate_id only

---

## Success Criteria

Migration succeeds when:

- [ ] ConstitutionManifest has `manifest_id` field
- [ ] ConstitutionFingerprint.compute/1 accepts Manifest parameter
- [ ] ConstitutionFingerprint does NOT compute component hashes
- [ ] ConstitutionalDriftJournal.record_execution/2 accepts Certificate
- [ ] ConstitutionalDriftJournal entries have `certificate_id` field
- [ ] GenerationHistory has `manifest_id` and `certificate_id` fields
- [ ] GenerationHistory does NOT store duplicate component hashes
- [ ] ConstitutionalExecutor generates certificates after every execution
- [ ] All code compiles without errors
- [ ] All tests pass
- [ ] OWNERSHIP_AUDIT.md shows zero violations
- [ ] EXECUTION_AUDIT.md shows single execution path
- [ ] PHASE13_FINAL_AUDIT.md passes all checks

---

## Rollback Plan

If migration fails:

1. Revert to git commit before migration
2. Document failure reasons
3. Fix issues in isolation
4. Retry migration with fixes

**Critical**: Do NOT leave system in partially-migrated state. Either complete all steps or rollback entirely.

---

## Next Actions

1. Execute Phase A (add new fields)
2. Execute Phase B (update logic)
3. Execute Phase C (remove duplicates)
4. Execute Phase D (verification)
5. Generate all audit documents
6. Declare Phase 13 frozen

---

*This migration plan ensures atomic transformation with no intermediate broken states. All changes conform to CONSTITUTION_ARCHITECTURE.md.*
