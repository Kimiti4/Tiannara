# Causal Metrics

## Purpose

Define quantitative metrics for measuring the unified causal graph's connectivity, consistency, coverage, intervention accuracy, uncertainty calibration, and overall cross-scale reasoning readiness.

## Metrics

| Metric | Description | Target |
|---|---|---|
| Cross-Layer Connectivity | Fraction of adjacent layer pairs with active causal edges | 1.0 |
| Causal Consistency | Absence of contradictions in the causal graph | 100% |
| Emergence Coverage | Fraction of higher-layer phenomena with emergence lineage | 0.95 |
| Constraint Coverage | Fraction of higher-layer constraints formally documented | 0.90 |
| Intervention Accuracy | Correlation between predicted and observed intervention effects | 0.85 |
| Uncertainty Calibration | Brier score for uncertainty estimates across layers | <0.05 |
| Graph Completeness | Coverage of known causal relationships per domain | 0.90 |
| Replay Stability | Fraction of replays producing identical hashes | 99.9% |
| Archaeology Completeness | Fraction of causal evolution reconstructible | 99% |
| Cross-Scale Reasoning Readiness | Overall causal architecture maturity index | 0.85+ |

## Target Thresholds

| Metric | Minimum | Target | Excellence |
|---|---|---|---|
| Cross-Layer Connectivity | 0.80 | 1.00 | 1.00 |
| Causal Consistency | 99% | 100% | 100% |
| Emergence Coverage | 0.70 | 0.95 | 1.00 |
| Constraint Coverage | 0.60 | 0.90 | 1.00 |
| Intervention Accuracy | 0.60 | 0.85 | 0.95 |
| Uncertainty Calibration | <0.10 | <0.05 | <0.02 |
| Graph Completeness | 0.70 | 0.90 | 0.99 |
| Replay Stability | 99% | 99.9% | 99.99% |
| Archaeology Completeness | 95% | 99% | 100% |

## Measurement Methodology

- **Cross-Layer Connectivity**: Ratio of active inter-layer edges to maximum possible
- **Causal Consistency**: Automated contradiction detection across the graph
- **Emergence Coverage**: Emergence lineage completeness for known emergent phenomena
- **Intervention Accuracy**: Pearson correlation between predicted and observed effects
- **Uncertainty Calibration**: Brier score decomposition across all uncertainty estimates

## Constraints

- Metrics must be deterministically computable
- Metric records become constitutional artifacts
- Metrics are measured against realized causal outcomes where possible
