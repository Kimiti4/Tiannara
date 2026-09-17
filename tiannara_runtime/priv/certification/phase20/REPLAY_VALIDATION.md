# Replay Validation (Phase 20.95)

## Objective

Prove that the entire Constitutional OS can be deterministically reconstructed from its archaeology. Replay must reconstruct the entire operating system, entire runtime, every subsystem, and every validation — with identical hashes required.

## Replay Scope

| Replay Target | Description | Depth |
|--------------|-------------|-------|
| Full OS replay | Reconstruct entire Constitutional OS from genesis | Complete |
| Subsystem replay | Reconstruct single subsystem | Per-subsystem |
| Campaign replay | Reconstruct validation campaign execution | Per-campaign |
| Scenario replay | Reconstruct single validation scenario | Per-scenario |
| Generation replay | Reconstruct generation lifecycle | Per-generation |
| Transition replay | Reconstruct generation transition | Per-transition |
| Archaeology replay | Reconstruct archaeology deposit chain | Full chain |

## Replay Verification Method

For each replay target:
1. Read archaeology artifacts from cold storage
2. Replay each step in deterministic order
3. Compute step hash = SHA-256(stage || input_hash || output_hash || previous_hash)
4. Compare computed hash chain against recorded chain
5. All hashes must match exactly

## Replay Types

- **Full** — Complete OS reconstruction from genesis
- **Campaign** — Reconstruct specific campaign execution
- **Scenario** — Reconstruct single validation scenario
- **Subsystem** — Reconstruct single subsystem lifecycle

## Replay Chain Properties

- Every step is content-addressed
- Step order is acyclic by construction
- Chain root hash verifies entire chain integrity
- Cold storage independent — replay from immutable artifacts only
- No runtime required — replay from archaeology alone

## Success Criteria

- All replay targets produce identical hashes to originals
- Full OS replay completes successfully
- All 8 campaigns are independently replayable
- Every subsystem is independently replayable
- Cross-subsystem replay chains are continuous
- Replay from cold storage produces identical results
- Replay score = 1.0 (all hashes match)
