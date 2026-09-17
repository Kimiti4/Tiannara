# Phase 20.8 — Bottleneck Detection Engine

## Role

The Bottleneck Detection Engine continuously monitors all subsystems for limitations, inefficiencies, and degradation. It produces deterministic BottleneckReports with causal chain analysis and severity classification.

## Inputs

- MetricSet from all subsystems (runtime, memory, reasoning, planning, engineering, research, simulation, knowledge graph, mathematics, world model, governance)
- Baseline performance profiles
- Historical trend data

## Outputs

- BottleneckReport with bottleneck_id, subsystem, severity, frequency, causal_chain, evidence_root

## Detection Dimensions

### Runtime Bottlenecks
Limitations in execution infrastructure.

| Metric | Bottleneck Signal |
|--------|-------------------|
| Dispatch latency | Increasing trend |
| Queue depth | Consistently high |
| Resource contention | Frequent conflicts |
| Thread starvation | Insufficient parallelism |
| Context switch overhead | Excessive switching |

### Memory Bottlenecks
Limitations in memory subsystems.

| Metric | Bottleneck Signal |
|--------|-------------------|
| Retrieval latency | Above threshold |
| Memory pressure | Approaching limits |
| Cache miss rate | Increasing trend |
| Eviction rate | Excessive evictions |
| Fragmentation | Growing fragmentation |

### Reasoning Bottlenecks
Limitations in reasoning throughput.

| Metric | Bottleneck Signal |
|--------|-------------------|
| Inference time | Above threshold |
| Proof generation time | Increasing trend |
| Decision latency | Degraded response |
| Error rate | Increasing errors |
| Retry rate | Frequent retries |

### Planning Bottlenecks
Limitations in planning efficiency.

| Metric | Bottleneck Signal |
|--------|-------------------|
| Plan generation time | Above threshold |
| Plan execution failure | Increasing failures |
| Re-planning frequency | Excessive replanning |
| Horizon depth | Below target |
| Branching factor | Explosive growth |

### Engineering Bottlenecks
Limitations in engineering throughput (Phase 20.6).

| Metric | Bottleneck Signal |
|--------|-------------------|
| Engineering cycle time | Increasing |
| Design iteration count | Excessive iterations |
| Verification failure rate | Above threshold |
| Integration failure rate | Increasing |
| Re-engineering frequency | Frequent rework |

### Research Bottlenecks
Limitations in research productivity (Phase 16).

| Metric | Bottleneck Signal |
|--------|-------------------|
| Hypothesis generation rate | Below baseline |
| Experiment throughput | Declining |
| Theory update rate | Slowing |
| Scientific capital growth | Below target |
| Discovery rate | Plateauing |

### Knowledge Graph Bottlenecks
Limitations in knowledge infrastructure.

| Metric | Bottleneck Signal |
|--------|-------------------|
| Query latency | Above threshold |
| Consistency violations | Increasing |
| Orphaned nodes | Growing count |
| Cross-reference breaks | Increasing breaks |
| Contradiction rate | Rising contradictions |

### Mathematics Bottlenecks
Limitations in mathematical processing.

| Metric | Bottleneck Signal |
|--------|-------------------|
| Proof verification time | Increasing |
| Symbolic computation time | Above threshold |
| Conjecture evaluation time | Degrading |
| Mathematical graph size | Exponential growth |
| Cross-proof dependency depth | Excessive depth |

### World Model Bottlenecks
Limitations in world model fidelity.

| Metric | Bottleneck Signal |
|--------|-------------------|
| Prediction error | Growing drift |
| Model update latency | Above threshold |
| Simulation divergence | Increasing deviation |
| Coverage gap | Expanding blind spots |
| Uncertainty | Growing uncertainty bounds |

### Governance Bottlenecks
Limitations in governance throughput.

| Metric | Bottleneck Signal |
|--------|-------------------|
| Audit queue depth | Growing backlog |
| Certification latency | Increasing |
| Review cycle time | Extending |
| Compliance violation rate | Rising violations |

## Causal Chain Analysis

Each bottleneck report traces the causal chain:

```
Bottleneck A (observed symptom)
    ↑
Causes B (intermediate cause)
    ↑
Causes C (root cause)
```

Each link includes:
- Evidence supporting the causal relationship
- Confidence in the causal link
- Whether the cause is addressable

## Severity Classification

| Severity | Criteria | Response |
|----------|----------|----------|
| Critical | Constitutional goal at risk | Immediate optimization required |
| Major | Significant degradation | High-priority optimization |
| Moderate | Noticeable degradation | Normal-priority optimization |
| Minor | Slight degradation | Low-priority optimization |
| Informational | Potential future issue | Monitor for escalation |

## Output Format

The BottleneckReport is an immutable, content-addressed object:

| Field | Description |
|-------|-------------|
| bottleneck_id | Content-addressed identifier |
| subsystem | Affected subsystem |
| severity | Critical/Major/Moderate/Minor/Informational |
| frequency | Continuous/Periodic/Intermittent/Rare |
| resource_usage | Resource consumption at detection |
| performance_loss | Quantified performance impact |
| causal_chain | Ordered list of cause-effect links |
| evidence_root | Root hash of evidence chain |
| fingerprint | SHA-256 of canonical form |
