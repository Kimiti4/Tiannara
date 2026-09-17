# Phase 15 Discovery Robustness Report

Executed: 2026-07-05 using `scripts/phase15_validation_campaign.exs` and the standalone ExUnit suite.

| Test | Result | Detection mechanism |
|---|---|---|
| DR-001 Corrupt evidence | PASS | Content ID and ledger entry mismatch |
| DR-002 Corrupt theory lineage | PASS | Content ID mismatch |
| DR-003 Corrupt discovery graph | PASS | Graph fingerprint changed |
| DR-004 Duplicate evidence | PASS | Identical content address deduplicated |
| DR-005 Forge certificate | PASS | HMAC verification rejected mutation/wrong key |
| DR-006 Replay mutation | PASS | Hash-chain/content fingerprint mismatch |

Result: 6/6 adversarial cases detected, with zero undetected cases in this test set. This is validation-kernel evidence; production key management and legacy registry integration remain outside scope.
