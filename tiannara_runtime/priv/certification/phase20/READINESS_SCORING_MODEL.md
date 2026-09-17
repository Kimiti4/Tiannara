# Readiness Scoring Model (Phase 20.98)

## Purpose

Define the deterministic scoring model for the Constitutional Readiness Index. All calculations are deterministic, reproducible, and evidence-based.

## Scoring Pipeline

```
Raw Evidence
    ↓
Raw Score (0.0–1.0)
    ↓
Normalized Score (0.0–1.0)
    ↓
Weighted Score (score × dimension_weight)
    ↓
Dimension Readiness (sum of weighted sub-metrics)
    ↓
Domain Readiness (dimension scores aggregated per domain)
    ↓
Overall CRI (weighted sum of dimension scores)
```

## Normalization Methods

| Method | Formula | When Used |
|--------|---------|-----------|
| Min-max | (x - min) / (max - min) | Continuous metrics with known bounds |
| Threshold | 1.0 if x ≥ threshold, else x/threshold | Pass/fail with gradation |
| Boolean | 1.0 if true, 0.0 if false | Binary requirements |
| Ratio | x / target | Productivity metrics |
| Passing | 1.0 if all sub-items pass | Multi-item checks |

## Weighting Strategy

Dimension weights:
- Constitutional Integrity: 0.15
- Mathematical Readiness: 0.10
- Scientific Readiness: 0.10
- Engineering Readiness: 0.10
- Replay Readiness: 0.10
- Archaeology Readiness: 0.10
- Runtime Readiness: 0.10
- Knowledge Readiness: 0.10
- Civilizational Readiness: 0.05
- Governance Readiness: 0.10
Total: 1.00

## Determinism Guarantee

- All scoring functions are pure (no side effects)
- All inputs are content-addressed hashes
- All outputs are content-addressed records
- Same inputs → same CRI every time
- Scoring replayable from cold storage
