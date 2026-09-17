# Portfolio Metrics (Phase 21.1)

## Purpose

Define metrics for research portfolio governance. Metrics measure portfolio health, program performance, capital efficiency, and civilization-level research productivity.

## Metrics Defined

| Metric | Formula | Target | Warning Threshold |
|--------|---------|--------|-------------------|
| Portfolio diversity | Shannon entropy over domain distribution | ≥ 0.8 | < 0.5 |
| Active programs | Count of programs in executing state | ≥ 20 | < 10 |
| Program completion | Programs completed per 100 generations | ≥ 5 | < 2 |
| Scientific capital utilization | Capital used / capital allocated | ≥ 0.8 | < 0.5 |
| Cross-domain collaboration | Programs with cross-domain dependencies | ≥ 30% | < 10% |
| Knowledge growth | New knowledge entries per generation | ≥ prior gen | < 50% of prior |
| Engineering impact | Engineering artifacts per 100 discoveries | ≥ 20 | < 10 |
| Information gain | Knowledge entropy reduction per generation | ≥ 0.05 | < 0.01 |
| Long-term continuity | Programs lasting > 100 generations | ≥ 5 | < 2 |
| Portfolio resilience | Programs that survive review cycle changes | ≥ 80% | < 50% |
| Civilizational research productivity | Weighted composite of all above | ≥ 0.8 | < 0.5 |

## Metric Collection

- Metrics are computed at each generation boundary
- All metrics are deterministic and replayable
- Metrics are deposited in archaeology
- Metric history is preserved for trend analysis
- Metric computation is independently verifiable

## Dashboard

A portfolio metrics dashboard shows:
- Current metric values vs targets
- Metric trends over generations
- Alerts for metrics below warning thresholds
- Portfolio balance visualization
- Capital allocation efficiency
- Program lifecycle distribution
