# TCP-002.6 Final Reconciliation

**Purpose:** Superseding documentation for the TCP-002.6 checkpoint sequence.  
**Workstream:** W0 — Activate Existing Capabilities  
**Baseline parent:** `153f09799d301b1e8f803a02a26d10a31cd0d050`

This document reconciles the commit history, evidence artifacts and test results
for the TCP-002.6 checkpoint sequence without rewriting prior records.

## Commit sequence

| Stage | Commit | Branch | Purpose |
|---|---|---|---|
| TCP-002.6 | `1a370ed42aac361f097ab37f649680a839ba4083` | `feat/tcp-001-completion-programme` | Immutable observation binding, independent evidence verification, horizon enforcement |
| TCP-002.6-R1 | `adfe001d79d42837ba8ee78b70c8527f44978168` | `feat/tcp-002-6-r1-recovery-closure` | Recovery-order correction, genuine restart tests |
| TCP-002.6-R1-F | `c267c67c7ea3776a1adb2b59bf7611ac7d34ab9f` | `feat/tcp-002-6-r1-recovery-closure` | Complete semantic binding comparison, 14 adversarial restart tests |

## Parent relationships

- TCP-002.6 parent: `153f0979` (TCP-002.5)
- TCP-002.6-R1 parent: `1a370ed4` (TCP-002.6)
- TCP-002.6-R1-F parent: `adfe001d` (TCP-002.6-R1)

All are linear descendants. No force-push or history rewrite was performed on the
final sequence.

## Evidence artifacts

| Commit | Report | Manifest |
|---|---|---|
| TCP-002.6 | `certification/tcp/TCP_002_6_IMPLEMENTATION_REPORT.md` | `certification/tcp/TCP_002_6_EVIDENCE_MANIFEST.json` |
| TCP-002.6-R1 | (inherited) | (inherited — identified `7a36a6d`, superseded) |
| TCP-002.6-R1-F | (inherited) | (inherited — identified `7a36a6d`, superseded) |

The R1 and R1-F commits did not create separate reports or manifests. Their
evidence is recorded in the TCP-002.6 report and this reconciliation document.

## Test evidence

### TCP-002.6 (at `1a370ed4`)

- Application forecasting + research: 561 tests, 0 failures (seeds 0 and 123456)
- `outcome_integrity_test.exs`: 34 tests, 0 failures
- `outcome_resolution_test.exs`: 28 tests, 0 failures
- `lifecycle_observability_test.exs`: 12 tests, 0 failures
- Runtime regression: 792 tests, 32 properties, 0 failures

### TCP-002.6-R1 (at `adfe001d`)

- Application forecasting + research: 569 tests, 0 failures (seeds 0 and 123456)
- `outcome_recovery_test.exs`: 8 tests, 0 failures

### TCP-002.6-R1-F (at `c267c67`)

- Application forecasting + research: 575 tests, 0 failures (seeds 0 and 123456)
- `outcome_recovery_test.exs`: 14 tests, 0 failures

## Open findings at TCP-002.6 completion

| Finding | Status | Notes |
|---|---|---|
| TCP-B-046 | OPEN | Cross-stack compile-time boundary |
| TCP-B-048 | OPEN | No live outcome source |
| TCP-B-056 | OPEN | Hardcoded pseudo-measurements |
| TCP-B-058 | PARTIAL | Integrity established; authenticity not established |
| TCP-B-061 | OPEN | No external trusted integrity anchor |
| TCP-B-062 | OPEN | Single-writer log |
| TCP-B-064 | OPEN | Resolution not durably persisted |
| TCP-B-065 | OPEN | Unbounded runtime file growth |
| TCP-B-066 | OPEN | No ratified source-trust policy |
| TCP-B-067 | OPEN | Verification authority key is ephemeral and process-exposed |
| RL-565 | HIGH / OPEN | — |
| RL-564 | OPEN | — |
| F-ARC-018 | OPEN | — |

## Resolved findings

| Finding | Status | Evidence |
|---|---|---|
| TCP-B-047 | RESOLVED | Regression-protected |
| TCP-B-050 | RESOLVED | Regression-protected |
| TCP-B-057 | RESOLVED | Regression-protected |
| TCP-B-059 | RESOLVED | Canonical resolver reads and enforces registered typed horizon |
| TCP-B-060 | RESOLVED | Binding, evidence integrity, legacy handling, verification transition implemented and tested |
| TCP-B-063 | RESOLVED | Single temporal authority, no bypass path |

## CI status

The full repository suite failed on both TCP-002.6 and R1-F with the same ten
`ResearchForecastingIntegrationTest` failures. These are a pre-existing
test-isolation issue (shared state causes `:registered`, `:not_forecastable`
and `:unavailable` expectations to receive incorrect results). The required
runtime suite, audit suite, lineage regression, compilation and cross-platform
verification all passed.

The runtime quarantine (non-blocking) also failed four tests involving
passive-mode mutation, reactivity, CPL process ownership and a certification
typing assertion.

## Git history note

The branch history for TCP-002.6 involved force-pushed amended commits. The
final remote HEAD at each stage was a single commit ahead of its parent. No
divergence exists in the final state — each final commit is a direct
descendant of its predecessor.

The three pre-existing untracked files and all 13,596 tracked runtime
checkpoints were preserved throughout.

## Governance

- `ModelUpdateGate`: unchanged (`authority: :none`, `production_mutation: :forbidden`, `human_review_required: true`)
- No model promotion, deployment, registry promotion or physical actuation occurred.
- No source-trust policy was self-ratified.
- No synthetic evidence was presented as real.
