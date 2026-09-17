# Clean Repository Reproducibility - Phase 14 RC3

## Overview

This document describes the clean repository reproducibility verification process, which ensures that Phase 14 certification can be reproduced from a fresh git clone with identical SHA-256 hashes.

## Constitutional Principle

**Reproducibility is a prerequisite for constitutional validity.** A certification that cannot be independently reproduced from source code is merely an assertion, not proof.

## What This Tests

1. **Deterministic Build**: Same source code produces same artifacts
2. **No Hidden Dependencies**: All dependencies are explicitly declared
3. **No Environment Leakage**: No reliance on local machine state
4. **Hash Consistency**: SHA-256 hashes match across clones

## Verification Procedure

### Prerequisites

- Git installed
- Elixir 1.18+ and Erlang/OTP 26+
- Mix package manager
- Python 3 (for hash comparison)

### Automated Verification

#### Linux/macOS (Bash)

```bash
# Run from repository root
./verify_clean_reproducibility.sh

# Or specify custom repo URL and clone directory
./verify_clean_reproducibility.sh https://github.com/user/repo.git /tmp/my_clone
```

#### Windows (PowerShell)

```powershell
# Run from repository root
.\verify_clean_reproducibility.ps1

# Or specify custom repo URL and clone directory
.\verify_clean_reproducibility.ps1 -RepoUrl "https://github.com/user/repo.git" -CloneDir "$env:TEMP\my_clone"
```

### Manual Verification Steps

If you prefer to verify manually:

```bash
# Step 1: Clone fresh
git clone <repo-url> /tmp/tiannara_test --depth 1
cd /tmp/tiannara_test

# Step 2: Install dependencies
mix deps.get --only prod

# Step 3: Compile
mix compile

# Step 4: Generate evidence package
mix run generate_phase14_evidence_package.exs

# Step 5: Compare hashes
# Compare phase14/certification/hashes/evidence_index.json
# with reference_hashes.json (if available)
```

## Expected Output

### First Run (Creates Reference)

```
🧪 Clean Repository Reproducibility Test
==========================================

Repository: .
Clone directory: /tmp/tiannara_clean_clone_12345

🗑️  Removing previous clone...
📦 Cloning repository...
📚 Installing dependencies...
🔨 Compiling...
🎯 Generating evidence package...
🔍 Extracting certificate hashes...
⚠️  No reference hash file found at phase14/certification/hashes/reference_hashes.json
💡 Saving current hashes as reference for future comparisons...
✅ Reference hashes saved

🧹 Cleaning up clone directory...

✅ Clean Repository Reproducibility Test COMPLETE
```

### Subsequent Runs (Verifies Match)

```
🧪 Clean Repository Reproducibility Test
==========================================

Repository: .
Clone directory: /tmp/tiannara_clean_clone_12345

🗑️  Removing previous clone...
📦 Cloning repository...
📚 Installing dependencies...
🔨 Compiling...
🎯 Generating evidence package...
🔍 Extracting certificate hashes...
⚖️  Comparing with reference hashes...
✅ All 60 file hashes match perfectly!
✅ Clean repository reproducibility VERIFIED

🧹 Cleaning up clone directory...

✅ Clean Repository Reproducibility Test COMPLETE
```

## Known Sources of Nondeterminism

The following factors can cause hash mismatches:

1. **Timestamps**: `DateTime.utc_now()` calls produce different values
   - Impact: Certificates contain timestamps in metadata
   - Mitigation: Timestamps are excluded from hash-critical fields

2. **Random Seeds**: Random number generation without fixed seeds
   - Impact: Any randomized algorithms produce different results
   - Mitigation: Governance system uses deterministic replay

3. **File System Order**: Directory listing order varies by OS
   - Impact: JSON arrays may have different ordering
   - Mitigation: Sort files before processing

4. **Floating Point Precision**: Different architectures may round differently
   - Impact: Fitness scores, entropy measurements
   - Mitigation: Round to 4 decimal places consistently

5. **Mix Compilation Cache**: Cached BEAM files may differ
   - Impact: Compiled bytecode differences
   - Mitigation: Use `mix clean` before compilation

## Troubleshooting

### Hash Mismatch Detected

If hashes don't match:

1. **Check timestamps**: Are certificates generated at exactly the same time?
2. **Verify dependencies**: Run `mix deps.clean --all && mix deps.get`
3. **Clear cache**: Run `mix clean` before recompiling
4. **Check file order**: Ensure deterministic file processing order
5. **Compare manually**: Diff individual JSON files to find differences

```bash
# Manual comparison example
diff <(jq -S . phase14/certification/campaign_results/gc_001.json) \
     <(jq -S . /tmp/tiannara_test/phase14/certification/campaign_results/gc_001.json)
```

### Clone Fails

Ensure:
- Git is installed and accessible
- Network connectivity to repository
- Sufficient disk space in clone directory
- No firewall blocking git protocol

### Compilation Errors

Ensure:
- Elixir 1.18+ installed (`elixir --version`)
- Erlang/OTP 26+ installed (`erl -version`)
- All dependencies resolved (`mix deps.get`)
- No syntax errors in source code

## Success Criteria

Clean repository reproducibility is considered **VERIFIED** when:

1. ✅ Fresh clone completes without errors
2. ✅ All dependencies install successfully
3. ✅ Compilation completes without warnings/errors
4. ✅ Evidence package generates successfully
5. ✅ All SHA-256 hashes match reference (or reference created on first run)
6. ✅ Certificate structure matches expected format

## Integration with Phase 14 Certification

This verification is part of the complete Phase 14 RC3 certification suite:

1. ✅ 12 Campaign Execution (GC-001 through GC-012)
2. ✅ Independent Audit (100% confidence)
3. ✅ Archaeological Reconstruction (Single Source of Truth)
4. ✅ Mutation Testing (Adversarial Robustness)
5. ✅ Long-Horizon Replay (Entropy Stability)
6. ✅ **Clean Repository Reproducibility** ← This test
7. ✅ Meta-Certification (Recursive Certification Chain)
8. ⏳ Cross-Platform Verification (Linux/macOS/Windows)

## References

- [Phase 14 Constitutional Meta-Governance Plan](Phase_14_Constitutional_Meta-Governance.md)
- [Cross-Platform Verification](CROSS_PLATFORM_VERIFICATION.md)
- [Governance Proof Constitution](GOVERNANCE_PROOF_CONSTITUTION.md)
