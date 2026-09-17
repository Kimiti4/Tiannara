# Audit Hash Verification (Phase 20.96)

## Purpose

Define the independent hash verification procedure. Every hash in the Constitutional OS must be independently recomputed by the auditor from raw cold storage data — without trusting any runtime-claimed hash values.

## Hash Types Verified

| Hash Type | Where Used | Verification Method |
|-----------|-----------|-------------------|
| Artifact hash | Content-addressed storage | SHA-256 of raw artifact bytes |
| Evidence hash | Evidence chain | SHA-256 of evidence record |
| Step hash | Replay chain | SHA-256(stage \|\| input_hash \|\| output_hash \|\| previous_hash) |
| Chain root | Chain termination | SHA-256 of all step hashes in sequence |
| Certificate hash | Certification document | SHA-256 of canonical certificate form |
| Generation hash | Generation record | SHA-256 of generation snapshot |
| Transition hash | Generation transition | SHA-256 of transition record |
| Fingerprint | Universal reference | SHA-256 of canonical record form |

## Verification Procedure

For each hash in the system:

```
1. Locate the artifact that claims the hash
2. Read the raw bytes from cold storage (independent copy)
3. Compute SHA-256 independently
4. Compare computed hash against claimed hash
5. Record: match / mismatch
```

## Hash Chain Verification

For each hash chain:

```
1. Get chain root from cold storage
2. Walk chain from first step to last
3. For each step:
   a. Read step record
   b. Read referenced input/output artifacts
   c. Verify referenced artifact hashes
   d. Recompute step hash
4. Compute expected root from all step hashes
5. Compare against claimed chain root
```

## Collision Detection

The auditor also checks for hash collisions:
- No two distinct artifacts should have the same hash
- No two distinct evidence items should have the same hash
- SHA-256 collision resistance is a required property

## Output

For each hash verification:
- Artifact reference
- Claimed hash
- Computed hash
- Match (yes/no)
- If mismatch: detailed discrepancy report
