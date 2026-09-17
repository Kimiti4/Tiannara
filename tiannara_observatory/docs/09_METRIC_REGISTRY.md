# Observatory Metric Registry

## Specification

Every metric in the Observatory is registered in this document before implementation.
Each entry follows this schema:

```
Name:           unique identifier
Owner:          domain/subdomain responsible
Definition:     natural language description
Formula:        precise computation (or reference to code)
Units:          SI units where applicable
Sampling:       frequency and strategy
Aggregation:    how raw values become time-window values
Retention:      raw retention, aggregated retention
Confidence:     how confidence is computed
Dependencies:   metrics or sources this metric depends on
Certification:  how certification status is determined
```

---

## Runtime Metrics

### `runtime.uptime`
- Owner: `runtime/health`
- Definition: Total wall-clock time the Runtime has been continuously running.
- Formula: `now() - runtime_start_time`
- Units: seconds (integer)
- Sampling: every 10s, counter
- Aggregation: last value per window
- Retention: raw 90d, aggregated 5y
- Confidence: 1.0 (sourced from system clock)
- Dependencies: none
- Certification: verified if heartbeat is present

### `runtime.discovery_rate`
- Owner: `runtime/discovery`
- Definition: Number of discovery cycles completed per hour.
- Formula: `count(discovery_completed_events) / window_hours`
- Units: discoveries/hour
- Sampling: per discovery completion
- Aggregation: rate over sliding windows (1h, 24h, 7d)
- Retention: raw 90d, aggregated 5y
- Confidence: derived from event completeness
- Dependencies: `runtime/discovery_completed` events
- Certification: certified if event count matches checkpoint count

### `runtime.cpu_percent`
- Owner: `runtime/health`
- Definition: CPU utilization of the Runtime Phoenix node.
- Formula: `100 * (total_ticks - idle_ticks) / total_ticks`
- Units: percent (0.0–100.0)
- Sampling: every 5s
- Aggregation: mean, p95, max per window
- Retention: raw 7d, aggregated 1y
- Confidence: 1.0
- Dependencies: none
- Certification: verified on receipt

### `runtime.memory_percent`
- Owner: `runtime/health`
- Definition: Memory utilization of the Runtime BEAM VM.
- Formula: `100 * used_memory / total_memory`
- Units: percent (0.0–100.0)
- Sampling: every 10s
- Aggregation: mean, p95, max per window
- Retention: raw 7d, aggregated 1y
- Confidence: 1.0
- Dependencies: none
- Certification: verified on receipt

### `runtime.active_challenges`
- Owner: `runtime/challenge`
- Definition: Number of challenges currently in active status.
- Formula: `count(challenges WHERE status = 'active')`
- Units: integer
- Sampling: per challenge status change
- Aggregation: last value per window
- Retention: raw 90d, aggregated 5y
- Confidence: 1.0
- Dependencies: `runtime/challenge` events
- Certification: certified if event store is consistent

### `runtime.cpl_checkpoint_count`
- Owner: `runtime/checkpoint`
- Definition: Total number of CPL checkpoints created.
- Formula: `count(checkpoint_created_events)`
- Units: integer
- Sampling: per checkpoint creation
- Aggregation: last value per window
- Retention: raw indefinite (CPL is source of truth)
- Confidence: 1.0
- Dependencies: `runtime/checkpoint` events
- Certification: verified against CPL hash chain

---

## Scientific Metrics

### `science.experiment_success_rate`
- Owner: `scientific/measurement`
- Definition: Percentage of experiments that produced expected results.
- Formula: `100 * count(experiments WHERE result = 'passed') / count(experiments)`
- Units: percent (0.0–100.0)
- Sampling: per experiment completion
- Aggregation: rate over sliding windows (24h, 7d, 30d)
- Retention: raw 90d, aggregated 5y
- Confidence: proportional to sample size
- Dependencies: `scientific/measurement` events
- Certification: certified if experiment count > 0

### `science.hypothesis_confirmed_rate`
- Owner: `scientific/hypothesis`
- Definition: Percentage of hypotheses that reached confirmed status.
- Formula: `100 * count(hypotheses WHERE status = 'confirmed') / count(hypotheses)`
- Units: percent (0.0–100.0)
- Sampling: per hypothesis status change
- Aggregation: rate over sliding windows (7d, 30d, all-time)
- Retention: raw 90d, aggregated indefinite
- Confidence: proportional to sample size
- Dependencies: `scientific/hypothesis` events
- Certification: certified if hypothesis count > 0

### `science.peer_review_latency`
- Owner: `scientific/peer_review`
- Definition: Time between submission and decision.
- Formula: `avg(decision_timestamp - submission_timestamp)`
- Units: hours
- Sampling: per peer review decision
- Aggregation: mean, p50, p95 per window
- Retention: raw 90d, aggregated 1y
- Confidence: proportional to sample size
- Dependencies: `scientific/peer_review` events
- Certification: provisional if low sample size

---

## Engineering Metrics

### `engineering.trl_level`
- Owner: `engineering/trl`
- Definition: Current Technology Readiness Level (1–9).
- Formula: `last(trl_change_event.target_level)`
- Units: integer (1–9)
- Sampling: per TRL change
- Aggregation: last value per window
- Retention: raw indefinite
- Confidence: 1.0 (formal assessment)
- Dependencies: `engineering/trl` events
- Certification: certified if signed by authorized assessor

### `engineering.deployment_success_rate`
- Owner: `engineering/deployment`
- Definition: Percentage of deployments that completed without rollback.
- Formula: `100 * count(deployments WHERE outcome = 'success') / count(deployments)`
- Units: percent (0.0–100.0)
- Sampling: per deployment completion
- Aggregation: rate over windows (7d, 30d)
- Retention: raw 90d, aggregated 1y
- Confidence: proportional to sample size
- Dependencies: `engineering/deployment` events
- Certification: certified if deployment count > 0

---

## Knowledge Metrics

### `knowledge.concept_count`
- Owner: `knowledge/concept`
- Definition: Total number of defined concepts.
- Formula: `count(concept_defined_events) - count(concept_retired_events)`
- Units: integer
- Sampling: per concept lifecycle event
- Aggregation: last value per window
- Retention: raw indefinite
- Confidence: 1.0
- Dependencies: `knowledge/concept` events
- Certification: certified if event store is consistent

### `knowledge.theory_network_density`
- Owner: `knowledge/theory`
- Definition: Ratio of existing concept relationships to maximum possible.
- Formula: `2 * edge_count / (node_count * (node_count - 1))`
- Units: float (0.0–1.0)
- Sampling: per relationship event
- Aggregation: last value per window
- Retention: raw 90d, aggregated 5y
- Confidence: 1.0
- Dependencies: `knowledge/concept`, `knowledge/relationship` events
- Certification: certified if graph is consistent

---

## Governance Metrics

### `governance.drift_score`
- Owner: `governance/drift`
- Definition: Aggregate measure of constitutional drift across all domains.
- Formula: `mean(drift_scores_by_domain)` (weighted by domain criticality)
- Units: float (0.0–1.0, higher = more drift)
- Sampling: per drift measurement event
- Aggregation: mean, max per window
- Retention: raw 90d, aggregated 5y
- Confidence: depends on domain coverage
- Dependencies: all drift events
- Certification: certified if >80% of domains reporting

### `governance.policy_violation_rate`
- Owner: `governance/compliance`
- Definition: Policy violations per unit time.
- Formula: `count(violation_events) / window_days`
- Units: violations/day
- Sampling: per policy violation
- Aggregation: rate over windows (7d, 30d)
- Retention: raw 90d, aggregated 5y
- Confidence: 1.0
- Dependencies: `governance/policy` events
- Certification: certified if audit trail is complete

---

## Certification Metrics

### `certification.overall_status`
- Owner: `certification/status`
- Definition: Aggregate observatory certification status.
- Formula: `min(certification_status_across_all_domains)` — weakest link
- Units: enum (certified, provisional, degraded, stale, uncertain)
- Sampling: per recertification cycle
- Aggregation: last value per window
- Retention: raw indefinite
- Confidence: 1.0
- Dependencies: all domain certification events
- Certification: self-certifying (meta-certification)

### `certification.data_coverage`
- Owner: `certification/audit`
- Definition: Percentage of expected data streams currently receiving certified data.
- Formula: `100 * certified_streams / total_expected_streams`
- Units: percent (0.0–100.0)
- Sampling: per recertification cycle
- Aggregation: last value per window
- Retention: raw 90d, aggregated 5y
- Confidence: 1.0
- Dependencies: `certification/status` events
- Certification: self-certifying

---

## Metric Registration Rules

| Rule | Description |
|------|-------------|
| **Pre-registration** | No metric is computed without a registry entry. |
| **Versioning** | Metric definition changes produce a new metric version. Old versions continue to be computable for replay. |
| **Deprecation** | Metrics may be deprecated but the registry entry is never deleted. Deprecated metrics are still computable. |
| **Units** | All metrics use SI units unless explicitly justified. |
| **Null handling** | Missing source data produces explicit null, not zero. |
| **Boundaries** | Every metric defines its valid range. Values outside range are flagged. |
