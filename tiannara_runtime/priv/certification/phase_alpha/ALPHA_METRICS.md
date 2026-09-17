# Alpha Metrics Specification

## Runtime Metrics

| Metric | Unit | Collection | Target | Alert |
|--------|------|-----------|--------|-------|
| Availability | % | Continuous | ≥99.9% | <99.9% |
| Uptime | seconds | Continuous | ≥ full duration | N/A |
| Checkpoint Success Rate | % | Per checkpoint | ≥99.99% | <100% |
| Checkpoint Interval | seconds | Per checkpoint | Configurable | >2x configured |
| Recovery Time | seconds | Per recovery | <30s | >60s |
| Memory Usage | GB | Per cycle | <80% budget | >90% budget |
| Memory Growth Rate | GB/day | Per day | Plateau | >1% per day |
| Queue Depth | count | Per cycle | <80% capacity | >90% capacity |
| Cycle Duration | seconds | Per cycle | <5 min | >10 min |
| Cycle Throughput | ops/s | Per cycle | Stable | >2x variance |
| Execution Stability | variance | Per 100 cycles | <0.1 | >0.5 |

## Scientific Metrics

| Metric | Unit | Collection | Target | Alert |
|--------|------|-----------|--------|-------|
| Hypotheses Generated | count/period | Per cycle | ≥10/day | 0 for 24h |
| Hypotheses Validated | count/period | Per cycle | ≥1/day | 0 for 7 days |
| Hypotheses Refuted | count/period | Per cycle | Measured | N/A |
| Prediction Accuracy | % | Per validation | ≥60% | <40% |
| Novel Discoveries | count/period | Per cycle | Measured | 0 for 30 days |
| Unknowns Created | count/period | Per cycle | Measured | N/A |
| Unknowns Resolved | count/period | Per cycle | Measured | 0 for 30 days |
| Scientific ROI | score/resource | Per discovery | >0.5 | <0.1 |
| Knowledge Growth Rate | entries/day | Per day | ≥5/day | 0 for 7 days |
| Discovery Velocity | discoveries/day | Per day | Measured | 0 for 14 days |
| Theory Diversity | count | Per day | ≥2 per domain | <2 per domain |

## Engineering Metrics

| Metric | Unit | Collection | Target | Alert |
|--------|------|-----------|--------|-------|
| Designs Generated | count/period | Per cycle | ≥1/day | 0 for 7 days |
| Verification Success Rate | % | Per verification | ≥80% | <50% |
| Optimization Yield | % improvement | Per optimization | ≥5% | <1% |
| Technology Readiness | avg TRL | Per week | Measured | Decreasing |
| Manufacturing Readiness | avg MRL | Per week | Measured | Decreasing |
| Engineering ROI | score/resource | Per design | >0.5 | <0.1 |
| Infrastructure Readiness | index | Per week | Measured | Decreasing |

## Planetary Metrics

| Metric | Unit | Collection | Target | Alert |
|--------|------|-----------|--------|-------|
| Planetary Health Index | 0-1 | Per day | ≥0.5 | <0.3 |
| Resource Sustainability Index | 0-1 | Per day | ≥0.5 | <0.3 |
| Risk Index | 0-1 | Per day | <0.5 | >0.7 |
| Intervention Readiness | 0-1 | Per day | ≥0.6 | <0.4 |
| Infrastructure Stability Index | 0-1 | Per day | ≥0.6 | <0.4 |
| Resilience Index | 0-1 | Per day | ≥0.5 | <0.3 |

## Civilization Metrics

| Metric | Unit | Collection | Target | Alert |
|--------|------|-----------|--------|-------|
| Innovation Index | 0-1 | Per week | Increasing | Decreasing 60d |
| Scientific Capacity | 0-1 | Per week | Growing | Stagnant 30d |
| Engineering Capacity | 0-1 | Per week | Growing | Stagnant 30d |
| Knowledge Economy Fraction | % | Per week | Measured | N/A |
| Discovery Impact Score | 0-1 | Per discovery | Measured | N/A |
| Civilizational Benefit Score | 0-1 | Per period | >0.2 | <0.2 |

## Constitutional Metrics

| Metric | Unit | Collection | Target | Alert |
|--------|------|-----------|--------|-------|
| Constitution Health | 0-1 | Per day | ≥0.95 | <0.9 |
| Replay Integrity | % | Per operation | ≥99.9% | <99.9% |
| Certification Coverage | % | Per week | ≥95% | <90% |
| Archaeology Integrity | % | Per week | ≥99% | <95% |
| Governance Compliance | % | Per audit | ≥99% | <95% |
| Lineage Preservation | % | Per operation | ≥99.99% | <99.9% |
| Unknown Preservation | % | Per operation | ≥99.99% | <99.9% |
