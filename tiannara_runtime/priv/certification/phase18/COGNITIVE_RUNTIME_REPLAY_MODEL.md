# Phase 18.9 — Cognitive Runtime Replay Model

## Structure

Every mission produces a single `RuntimeReplay` with one root per subsystem. The full mission can be reconstructed from replay artifacts alone — no runtime state is required.

## Replay Roots

| Root | Subsystem | Contents |
|------|-----------|----------|
| `mission_root` | Runtime | Mission identity, pipeline version, timestamps |
| `kernel_root` | Kernel 18.2 | Mission validation, objective hash, constraints |
| `working_memory_root` | WM 18.3 | Memory load operations, recall chain, context snapshots |
| `attention_root` | Attention 18.4 | Salience vectors, focus maps, discarded inputs |
| `planning_root` | Planning 18.5 | Plan candidates, selection criteria, plan graph |
| `decision_root` | Decision 18.6 | Authorization trail, risk scores, decision alternatives |
| `reflection_root` | Reflection 18.7 | Deviation vectors, confidence scores, lessons |
| `metacognition_root` | Meta 18.8 | Meta-scores, calibration trace, anomaly flags |

## Reconstruction Rule

Given only `RuntimeReplay`:
1. Traverse `mission_root` to establish mission identity and pipeline version
2. Follow each subsystem root to reconstruct subsystem-specific state at every stage
3. Cross-reference timestamps and evidence hashes to validate sequencing
4. Build `RuntimeArchaeology` entirely from replay artifacts — no live queries

## Integrity

- `integrity_hash` covers all 8 roots in canonical order
- Each root is content-addressed; replay is tamper-evident
- Reconstruction is deterministic: same replay always yields same narrative
