# Mission Metrics

## Purpose

Define the quantitative metrics for measuring the performance, diversity, and health of the autonomous research mission generation system.

## Metrics

### Generated Missions
- Total missions generated
- Missions per generation
- Mission generation rate
- Mission backlog

### Mission Diversity
- Domain distribution
- Mission type distribution
- Program type distribution
- Feasibility score distribution

### Dependency Complexity
- Average dependencies per mission
- Maximum dependency depth
- Dependency graph density
- Cross-domain dependency ratio

### Cross-Domain Missions
- Total interdisciplinary missions
- Cross-domain ratio
- Collaboration type distribution
- Domain pair frequency

### Average Feasibility
- Mean composite feasibility score
- Feasibility distribution
- Infeasible mission rate
- Feasibility improvement over time

### Predicted Information Gain
- Total expected information gain
- Average gain per mission
- High-gain mission ratio (>0.7)
- Gain distribution across domains

### Expected Scientific Capital
- Total scientific capital required
- Average capital per mission
- Capital efficiency (gain/capital)
- Capital distribution

### Expected Engineering Impact
- Engineering-intensive mission count
- Infrastructure requirements
- Instrumentation demand
- Simulation requirements

### Replay Stability
- Replay pass rate
- Hash match percentage
- Replay failure count
- Recovery rate

### Archaeology Completeness
- Complete archaeology records
- Partial archaeology records
- Missing archaeology count
- Archaeology coverage ratio

### Mission Readiness
- Missions ready for portfolio submission
- Missions awaiting dependency resolution
- Missions with incomplete validation plans
- Missions undergoing constitutional review

## Target Thresholds

| Metric | Minimum | Target | Excellence |
|---|---|---|---|
| Generated Missions | 10/gen | 50/gen | 100+/gen |
| Mission Diversity | 5 domains | 10 domains | 15+ domains |
| Cross-Domain Ratio | 20% | 35% | 50%+ |
| Average Feasibility | 0.50 | 0.65 | 0.80+ |
| Replay Stability | 95% | 99% | 99.9% |
| Archaeology Completeness | 90% | 99% | 100% |
| Mission Readiness | 60% | 75% | 90%+ |

## Recording

All metrics must be deterministically computable from mission artifacts. Metrics become part of the constitutional record and must be replayable.
