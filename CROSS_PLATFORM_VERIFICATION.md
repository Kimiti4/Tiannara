# Phase 14 RC3 - Cross-Platform Verification Guide

[![Cross-Platform Verification](https://github.com/Kimiti4/Tiannara/actions/workflows/cross_platform_verify.yml/badge.svg)](https://github.com/Kimiti4/Tiannara/actions/workflows/cross_platform_verify.yml)

## Overview

This document describes how to verify Phase 14 constitutional certification across multiple platforms (Linux, macOS, Windows) to ensure deterministic reproducibility.

Linux and macOS verification is **automated via GitHub Actions** on every push. See [`.github/workflows/cross_platform_verify.yml`](.github/workflows/cross_platform_verify.yml).

## Prerequisites

All platforms must have:
- Elixir 1.18+ installed
- Erlang/OTP compatible version
- Git for version control

## Verification Procedure

### Step 1: Clean Repository Clone

```bash
# On EACH platform (Linux, macOS, Windows)
git clone <repository-url> tiannara-verify
cd tiannara-verify
mix deps.get
mix compile
```

### Step 2: Generate Evidence Package

```bash
# Run the evidence package generator
mix run generate_phase14_evidence_package.exs
```

### Step 3: Extract Certificate Hash

```bash
# Linux/macOS
cat phase14/certification/certificate.json | jq -r '.sha256'

# Windows PowerShell
(Get-Content phase14/certification/certificate.json | ConvertFrom-Json).sha256
```

### Step 4: Compare Hashes Across Platforms

The SHA-256 hash of `certificate.json` **MUST** be identical across all platforms.

If hashes differ → hidden nondeterminism exists → Phase 14 NOT frozen.

## Expected Results

| Platform | Certificate SHA-256 | Status |
|----------|---------------------|--------|
| Windows  | *(manual run — see PowerShell script below)* | ⏳ Pending |
| Linux    | Automated via GitHub Actions CI | 🤖 Automated |
| macOS    | Automated via GitHub Actions CI | 🤖 Automated |

> The CI workflow uploads the canonical hash and full evidence package as downloadable artifacts on every run.
> Check the latest [Actions run](https://github.com/Kimiti4/Tiannara/actions/workflows/cross_platform_verify.yml) for the current values.

## Known Sources of Nondeterminism

These factors can cause hash mismatches and must be controlled:

1. **Timestamps**: DateTime.utc_now() varies by execution time
   - Solution: Compare content excluding timestamp fields
   
2. **Random Seeds**: :rand.uniform() without seed
   - Solution: Set deterministic seed before execution
   
3. **File System Order**: Directory listing order varies
   - Solution: Sort file lists before processing
   
4. **Floating Point**: Platform-specific float representation
   - Solution: Use consistent rounding (Float.round(x, 4))

## Current Implementation Status

✅ **Archaeological Reconstruction**: PASSED (Windows)
- All 9 components verified with 100% confidence
- Single Source of Truth principle validated

✅ **Mutation Testing**: PASSED (Windows)
- 6/6 mutations detected
- 100% adversarial robustness

✅ **Long-Horizon Replay**: PASSED (Windows, 10k iterations)
- Entropy stable (std_dev = 0.0)
- Fitness stable (mean = 0.807)
- No entropy accumulation detected

🤖 **Cross-Platform Verification**: AUTOMATED (Linux + macOS)
- Runs on every push via `.github/workflows/cross_platform_verify.yml`
- Hash comparison performed automatically in `compare-hashes` job
- Results appear in GitHub Actions job summary as a Markdown table

⏳ **Windows Verification**: PENDING
- Run `verify_cross_platform.ps1` on a Windows machine (this machine)
- Compare hash with the Linux/macOS hash from the latest CI run

⏳ **Clean Clone Reproducibility**: PENDING
- Requires fresh git clone test
- Full pipeline re-execution pending

## Automation Script

For automated cross-platform testing, use:

```bash
# verify_cross_platform.sh (Linux/macOS)
#!/bin/bash
PLATFORM=$(uname -s)
echo "Running on: $PLATFORM"

mix run generate_phase14_evidence_package.exs > /dev/null 2>&1
HASH=$(cat phase14/certification/certificate.json | jq -r '.sha256')
echo "$PLATFORM: $HASH"
```

```powershell
# verify_cross_platform.ps1 (Windows)
$platform = "Windows"
Write-Host "Running on: $platform"

mix run generate_phase14_evidence_package.exs | Out-Null
$cert = Get-Content phase14/certification/certificate.json | ConvertFrom-Json
$hash = $cert.sha256
Write-Host "$platform`: $hash"
```

## Success Criteria

Phase 14 achieves cross-platform verification when:

1. ✅ All three platforms generate identical certificate hashes
2. ✅ All campaigns pass on all platforms (12/12)
3. ✅ Independent audit passes on all platforms (100% confidence)
4. ✅ Archaeological reconstruction succeeds on all platforms
5. ✅ Mutation testing detects all mutations on all platforms
6. ✅ Long-horizon replay shows stability on all platforms

## Next Steps

1. ✅ Push to GitHub — CI automatically verifies Linux and macOS
2. Check the [latest Actions run](https://github.com/Kimiti4/Tiannara/actions/workflows/cross_platform_verify.yml) for the canonical hashes
3. Run `verify_cross_platform.ps1` on this Windows machine and compare with the CI hash
4. If all three match → Phase 14 ready for freeze
5. If hashes differ → see nondeterminism sources above and fix

## CI Automation Details

The workflow (`.github/workflows/cross_platform_verify.yml`) performs:

| Step | What it does |
|------|--------------|
| `verify` (parallel) | Runs on `ubuntu-latest` and `macos-latest` |
| Install Elixir 1.18 / OTP 27 | Pinned versions for reproducibility |
| `mix compile` | Fails on warnings to keep code clean |
| `generate_phase14_evidence_package.exs` | Generates the certificate with deterministic timestamp |
| Canonical hash | Strips timestamp fields, sorts JSON keys, SHA-256 hashes |
| Upload artifact | Saves hash file + full `phase14/certification/` for download |
| Archaeological reconstruction | Verifies 9-component single-source-of-truth |
| Mutation testing | Verifies 6/6 mutations detected |
| Independent audit | Verifies 100% confidence |
| `compare-hashes` job | Downloads both platform hashes and compares them |

## Contact

For questions or issues with cross-platform verification, refer to:
- Phase 14 Constitutional Milestones documentation
- GOVERNANCE_PROOF_CONSTITUTION.md
- Tiannara Elite Architecture Mode guidelines
