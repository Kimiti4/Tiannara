# Readiness Replay Model (Phase 20.98)

## Purpose

Define the replay model for readiness assessment. Replay reconstructs all readiness calculations, all weights, all dimension scores, all domain scores, and the overall CRI — with identical hashes required.

## Replay Scope

| Replay Type | Coverage | Description |
|-------------|----------|-------------|
| Full | Complete CRI calculation | All dimensions, domains, scores |
| Dimension | Single readiness dimension | Dimension scoring replay |
| Domain | Single research domain | Domain readiness replay |
| Score | Single metric score | Atomic score recalculation |

## Replay Verification

For each replay target:
1. Load evidence inputs from archaeology
2. Recompute all sub-metric scores deterministically
3. Recompute normalized scores
4. Recompute weighted scores
5. Aggregate dimension scores
6. Aggregate domain scores (if applicable)
7. Compute overall CRI
8. Compare against recorded CRI
9. Verify all intermediate hashes match

## Replay Chain

```
Evidence Inputs → Sub-Metric Scores → Normalized Scores → Weighted Scores → Dimension Scores → Domain Scores → Overall CRI
    │                  │                    │                    │                   │               │            │
    v                  v                    v                    v                   v               v            v
  hash[1]            hash[2]              hash[3]              hash[4]             hash[5]         hash[6]      hash[7]
                                                                                                               │
                                                                                                               v
                                                                                                          Root hash
```

## Identical Hash Requirements

- Full CRI replay must produce identical hashes
- All intermediate hashes must match originals
- Any hash mismatch = scoring replay drift (critical)
