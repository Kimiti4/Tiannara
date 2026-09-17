# Phase 20.8 — Optimization Discovery Engine

## Role

The Optimization Discovery Engine transforms bottleneck reports into concrete optimization candidates. It generates candidates by analyzing engineering history, experiment results, runtime metrics, knowledge graph structure, scientific capital trends, planning failures, resource usage patterns, world model drift, mathematical complexity trends, and previous optimization history.

## Inputs

- BottleneckReport (from Detection Engine)
- MetricSet (current and historical)
- Engineering history (Phase 20.6)
- Experiment history (Phase 20.7)
- Knowledge graph state and trends
- Scientific capital ledger
- Runtime generation history
- Previous optimization candidates and outcomes

## Outputs

- OptimizationCandidate(s) with expected gain, cost, risk, and affected domains

## Discovery Sources

### Engineering History
Analyze past engineering projects for patterns that indicate optimization opportunities.

| Source | Signal |
|--------|--------|
| Design iteration count | High iteration count suggests unclear requirements |
| Verification failure patterns | Recurring failures suggest design anti-patterns |
| Integration difficulty | Frequent rollbacks suggest poor compatibility analysis |
| Post-integration issues | Monitoring alerts after integration suggest insufficient validation |

### Experiment Results
Analyze experiment outcomes for optimization insights.

| Source | Signal |
|--------|--------|
| Confirmed hypotheses | Knowledge that can be operationalized |
| Refuted hypotheses | Approaches to avoid |
| Inconclusive results | Areas requiring better experimental design |
| Reproducibility failures | Instabilities in execution environment |

### Runtime Metrics
Analyze runtime performance for optimization opportunities.

| Source | Signal |
|--------|--------|
| Latency trends | Degrading performance suggests algorithmic improvement |
| Resource usage trends | Increasing consumption suggests efficiency opportunity |
| Error rate trends | Increasing errors suggests reliability improvement |
| Throughput plateaus | Stalled throughput suggests architectural bottleneck |

### Knowledge Graph Structure
Analyze knowledge graph for optimization opportunities.

| Source | Signal |
|--------|--------|
| Orphan nodes | Unexplored knowledge areas |
| Contradiction clusters | Areas requiring resolution |
| High centrality nodes | Potential bottlenecks in knowledge flow |
| Sparse regions | Knowledge gaps needing attention |

### Scientific Capital Trends
Analyze scientific capital for optimization opportunities.

| Source | Signal |
|--------|--------|
| Stalled capital growth | Research program efficiency opportunity |
| Capital concentration | Over-investment in specific areas |
| Capital velocity decline | Slowing returns on research investment |
| Capital imbalance | Neglected domains needing attention |

### Resource Usage Patterns
Analyze resource consumption for optimization opportunities.

| Source | Signal |
|--------|--------|
| Over-provisioning | Resource allocation efficiency opportunity |
| Resource contention | Scheduling improvement opportunity |
| Utilization imbalance | Load balancing opportunity |
| Waste patterns | Inefficient resource usage patterns |

## Candidate Generation Process

For each bottleneck, the engine:

1. **Search** — Query all discovery sources for patterns relevant to the bottleneck
2. **Match** — Match patterns against known optimization strategies
3. **Generate** — Produce one or more candidate optimizations
4. **Estimate** — Compute expected gain, cost, and risk for each candidate
5. **Rank** — Rank candidates by expected net benefit

## Candidate Properties

Each OptimizationCandidate includes:

| Field | Description |
|-------|-------------|
| candidate_id | Content-addressed identifier |
| originating_problem | Reference to BottleneckReport |
| originating_metrics | Reference to MetricSet |
| bottleneck_reference | Reference to bottleneck causal chain |
| expected_gain | Predicted improvement per metric |
| expected_cost | Predicted resource cost |
| expected_risk | Predicted risk level and categories |
| affected_domains | Subsystems and domains affected |
| mathematical_justification | Formal reasoning supporting the candidate |
| source_evidence | References to evidence supporting generation |
| replay_root | Root hash of candidate replay chain |
| archaeology_root | Root hash of candidate archaeology |
| status | Draft/Evaluated/Recommended/Accepted/Rejected |
| fingerprint | SHA-256 of canonical form |

## Deterministic Guarantees

- Same bottleneck + same evidence → same candidate set
- Same candidate → same estimated gain, cost, risk
- Candidate ranking is fully deterministic
- All discovery sources are content-addressed and replayable
