# Phase 20.4 — Rollback Engine

## Role

The Rollback Engine is the safety mechanism that restores Tiannara to a known-good state when integration failure is detected. It operates deterministically at every pipeline stage and preserves complete forensic evidence.

## Responsibilities

### 1. Integration Failure Detection

Monitor for failure conditions across all pipeline stages:

| Failure Type | Detection Mechanism |
|--------------|---------------------|
| Migration step failure | State hash mismatch at step boundary |
| Verification failure | Verification criterion not met |
| Performance regression | Metric deviation beyond constitutional tolerance |
| Determinism violation | Replay hash mismatch across runs |
| Resource exhaustion | Resource consumption exceeds budget |
| Constitutional violation | Audit detects constitutional non-compliance |
| Replay chain break | Replay hash chain discontinuity |
| Archaeology chain break | Archaeology root mismatch |

### 2. Runtime State Restoration

Restore runtime to pre-integration state:

- Load pre-integration state snapshot
- Verify snapshot integrity via stored hash
- Apply inverse migration transforms (if partial migration occurred)
- Verify restored state hash matches pre-integration hash
- Confirm all runtime domains restored (modules, knowledge graph, mathematical graph, scientific capital, working memory, governance state)

### 3. Knowledge Graph Restoration

Restore knowledge graph to pre-integration state:

- Load knowledge graph snapshot taken before Stage 6 (State Migration)
- Verify graph integrity via stored hash
- Re-verify all cross-domain references
- Confirm no knowledge gaps introduced

### 4. Mathematical Graph Restoration

Restore mathematical graph to pre-integration state:

- Load mathematical graph snapshot
- Verify proof consistency after restoration
- Verify symbolic engine state consistency
- Confirm no mathematical invariants violated

### 5. Scientific Capital Restoration

Restore scientific capital to pre-integration state:

- Load scientific capital ledger snapshot
- Verify all balances match stored values
- Verify transaction history continuity
- Confirm no capital loss or double-counting

### 6. Replay Verification After Restoration

After state restoration, verify replay integrity:

- Execute replay from genesis to pre-integration state
- Verify final replay hash matches pre-integration fingerprint
- Verify replay chain has no discontinuities
- Confirm cold-storage replay produces identical results

### 7. Rollback Archaeology

Every rollback produces complete forensic evidence:

- RollbackRecord with trigger, previous_version, restored_version
- Evidence of the trigger condition
- Restored state hashes at every domain
- Replay verification results after restoration
- Archaeology update reflecting rollback event

No rollback may modify historical records. Rollback creates new records documenting the rollback itself.

## Rollback Stages

Each pipeline stage has a defined rollback procedure:

| Pipeline Stage | Rollback Action |
|----------------|-----------------|
| Stage 1–4 (Pre-migration) | Discard candidate; no runtime state changed |
| Stage 5 (Simulation) | Discard simulation; no production state changed |
| Stage 6 (State Migration) | Apply inverse migration transforms; restore from snapshot |
| Stage 7 (Verification) | Apply inverse migration; restore from snapshot |
| Stage 8 (Audit) | Apply inverse migration; restore from snapshot |
| Stage 9 (Certification) | Revoke certification; apply inverse migration; restore |
| Stage 10 (Activation) | Deactivate candidate; restore pre-activation state |
| Stage 11 (Monitoring) | Deactivate candidate; restore pre-activation state |
| Stage 12 (Freeze) | Constitutional amendment required; full generation rollback |

## Deterministic Guarantees

- Rollback is fully deterministic — same failure always produces identical restoration
- Rollback restore state always matches pre-integration fingerprint
- Rollback replay verification always produces identical results
- All rollback artifacts are content-addressed and replayable

## Constraints

- No rollback may modify historical replay chains
- No rollback may modify historical archaeology records
- Rollback creates new artifacts documenting the rollback event
- Rollback must preserve all evidence of the failure
- Rollback must be tested during integration simulation (Stage 5)
- Human governance may override automatic rollback
