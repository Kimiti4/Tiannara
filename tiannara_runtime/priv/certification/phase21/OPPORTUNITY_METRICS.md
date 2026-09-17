# Opportunity Metrics

## Purpose

Define quantitative metrics for measuring the performance, coverage, and health of the scientific opportunity management system.

## Metrics

### Knowledge Frontier Size
- Total frontier elements across all layers
- Elements per layer distribution
- Frontier growth rate
- Layer density ratios

### Scientific Opportunities
- Total identified opportunities
- Opportunities per domain
- Opportunity quality distribution
- Opportunity discovery rate

### Cross-Domain Opportunities
- Total cross-domain opportunities
- Cross-domain ratio
- Domain pair frequency
- Cross-domain discovery rate

### Average Information Gain
- Mean expected information gain across opportunities
- Gain distribution by domain
- High-gain opportunity count (>0.7)
- Gain estimate confidence distribution

### Knowledge Gap Reduction
- Gaps closed per generation
- Gap closure rate
- Gap reduction per domain
- Remaining gap trajectory

### Opportunity Utilization
- Opportunities converted to missions
- Opportunities completed
- Opportunities archived without action
- Conversion rate by priority tier

### Discovery Conversion Rate
- Completed discoveries / pursued opportunities
- Expected vs actual information gain ratio
- Discovery quality distribution
- Surprise discovery rate

### Scientific Capital Generated
- Capital value of discoveries from opportunities
- Capital efficiency (gain / capital invested)
- Capital distribution by domain
- Capital return on opportunity investment

### Replay Stability
- Opportunity replay pass rate
- Hash match percentage
- Replay failure count
- Root hash convergence

### Archaeology Completeness
- Complete archaeology records
- Archaeology coverage ratio
- Independent reconstruction success rate
- Archaeology gap count

## Target Thresholds

| Metric | Minimum | Target | Excellence |
|---|---|---|---|
| Frontier Elements Tracked | 1,000 | 10,000 | 100,000+ |
| Active Opportunities | 50 | 200 | 1,000+ |
| Cross-Domain Ratio | 15% | 25% | 40%+ |
| Average Information Gain | 0.30 | 0.50 | 0.70+ |
| Opportunity Utilization | 40% | 60% | 80%+ |
| Replay Stability | 99% | 99.9% | 99.99% |
| Archaeology Completeness | 95% | 99% | 100% |

## Recording

All metrics must be deterministically computable from opportunity artifacts. Metrics become part of the constitutional record and must be replayable.
