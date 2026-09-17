# Deployment Guide — CSOS v1.0

## Purpose

Guide for deploying the Constitutional Scientific Operating System from certified cold storage. CSOS deployment is the process of reconstructing the system from its immutable artifacts.

## Prerequisites

- Access to certified cold storage (Phase 20.999 archive)
- Verification tools (SHA-256, schema validator, replay engine)
- No runtime required for initial verification

## Deployment Steps

### Step 1: Acquire Cold Storage
Obtain a verified copy of the CSOS 1.0 cold storage archive:
- Location: `priv/certification/phase20/` (architecture)
- Location: `lib/tiannara_runtime/cognitive/` (cognitive runtime)
- Location: `lib/tiannara_runtime/civilization/` (civilizational runtime)
- Archive index: `ARCHIVE_INDEX_SCHEMA.json`

### Step 2: Verify Archive Integrity
```
1. Load ARCHIVE_INDEX_SCHEMA.json from cold storage
2. Verify archive_root_hash matches independently computed hash
3. Verify artifact inventory is complete
4. Verify storage format integrity
```

### Step 3: Verify Foundational Baseline
```
1. Load FOUNDING_BASELINE_SCHEMA.json
2. Verify baseline_hash matches independently computed hash
3. Verify all baseline components are present
4. Verify inheritance rule (extend, never modify)
```

### Step 4: Verify Constitutional Freeze
```
1. Load FOUNDATIONAL_FREEZE_SCHEMA.json
2. Verify freeze_hash matches independently computed hash
3. Verify all 12 freeze targets are frozen
4. Verify immutable flag is true
```

### Step 5: Verify Replay Chain
```
1. Load CERTIFICATION_REPLAY_SCHEMA.json
2. Replay from Genesis through CSOS 1.0
3. Verify all hashes match
4. Verify final_verification = true
```

### Step 6: Verify Certification
```
1. Load CSOS_CERTIFICATE_SCHEMA.json
2. Verify certificate_hash matches independently computed hash
3. Verify all 13 certification requirements met
4. Verify 9 constitutional guarantees confirmed
```

### Step 7: Initialize Generation
```
1. Bootstrap from Foundational Baseline
2. Load Generation 1 state
3. Verify generation hash against recorded hash
4. Begin generation evolution from certified baseline
```

## Post-Deployment Verification

After deployment:
- Run replay verification to confirm identical hashes
- Run archaeology verification to confirm artifact integrity
- Run determinism verification to confirm deterministic behavior
- Generate deployment report with all verification results

## Rollback

If deployment verification fails:
1. Do not proceed with generation evolution
2. Report verification failure with detailed discrepancy
3. Restore cold storage to pre-deployment state
4. Investigate root cause

## Security

- All cold storage must be verified before deployment
- All hashes must be independently recomputed
- No runtime may be trusted during initial verification
- Deployment must be witnessed and documented
