# Phase 17.8.4 — Research Portfolio Optimization

document_version: 17.8.4
phase: 17.8
status: Complete
owner: Constitutional Research Council
depends_on:
  - AUTONOMOUS_EXPERIMENT_PLANNER.md (Phase 17.8.3)
  - AUTONOMOUS_RESEARCH_RUNTIME_FREEZE.md (APIs: ARPEPortfolioManager, ARPEBudgetAllocator)
  - RESEARCH_EXECUTION_PIPELINE.md (Stages 6–7)

---

## Scope

Phase 17.8.4 implements the ARPEPortfolioManager (Stage 6) and its supporting
config artifact. It selects the active experiment portfolio from candidates by
optimising across five objectives, all weights driven by PortfolioConfig.

---

## Constitutional Constraints (All Enforced)

- All weights, thresholds, and constraints come from `PortfolioConfig` — never hardcoded.
- `min_value_threshold`, `min_domain_diversity_threshold`, and `max_portfolio_size`
  are required fields in `PortfolioConfig`.
- If `PortfolioConfig` is absent, `optimize/3` returns `{:error, %PortfolioConfigMissing{}}`.
- If `ExperimentBudget` is absent, `optimize/3` returns `{:error, %BudgetMissing{}}`.
- If all candidates are pruned, returns `{:error, %PortfolioSelectionFailure{}}` — not an empty list.
- Tie-breaking: ascending lexicographic over `portfolio_id` (content-addressed hash).
- No `DateTime.utc_now()`. No `random`. No fabricated data.
- Output is an `ExperimentPortfolio` struct with content-addressed ID.

---

## Files Implemented

### New Struct

| File | Module | Purpose |
|---|---|---|
| `portfolio_config.ex` | `PortfolioConfig` | Epoch-frozen config: five objective weights, three selection constraints |

### Rebuilt Engine

| File | Module | Violations Fixed |
|---|---|---|
| `engines/portfolio_optimizer.ex` | `Engines.PortfolioOptimizer` | Removed `min_value_threshold: 0.05`, `min_diversity: 0.3` from context map fallbacks; removed `effect_size: 0.3`, `sample_size: 100`, `entropy: 0.5` fallbacks in information_gain; removed `max_compute_units: 10` divisor in budget allocation; removed `priority_weight: 1.0 / n` hardcoded allocation; output is now a typed `ExperimentPortfolio` struct |

---

## PortfolioConfig (Epoch-Frozen Config Artifact)

Five objective weights (must sum to 1.0):
- `w_information_gain`
- `w_scientific_diversity`
- `w_constitutional_priority`
- `w_resource_utilization`
- `w_long_term_impact`

Three selection constraints (all required):
- `min_domain_diversity_threshold` — float in [0.0, 1.0]
- `min_value_threshold` — float >= 0.0
- `max_portfolio_size` — positive integer

Plus: `optimization_algorithm_version` (frozen string label).

Content-addressed ID: `pcfg_<sha256>`.

---

## Optimization Function

```
score(portfolio) =
  config.w_information_gain         × expected_total_information_gain
  + config.w_scientific_diversity   × diversity_score
  + config.w_constitutional_priority × constitutional_priority_score
  + config.w_resource_utilization   × (1 - resource_utilization_fraction)
  + config.w_long_term_impact       × long_term_impact_score
```

All five signals are read from `ExperimentPortfolio` fields. None are computed
from raw experiment lists inside the optimizer.

---

## Selection Algorithm

1. Score all candidates (deterministic)
2. Prune: reject candidates with score < `config.min_value_threshold`
3. Diversity restore: if average diversity < `config.min_domain_diversity_threshold`,
   re-admit highest-scoring pruned portfolios until threshold is met
4. Cap: keep top `config.max_portfolio_size` by score (tie-break by `portfolio_id` asc)
5. Build output `ExperimentPortfolio` with `optimization_proof_hash`

The `optimization_proof_hash` is SHA-256 over the sorted scored candidate set and `config_id`,
enabling independent auditors to verify the selection was computed from these exact inputs.

---

## Failure Taxonomy

| Failure | Struct | Condition |
|---|---|---|
| Config absent | `PortfolioConfigMissing` | config is nil or not `PortfolioConfig` |
| Config ID invalid | `PortfolioConfigMissing` | `verify_id/1` fails |
| Budget absent | `BudgetMissing` | budget is nil or not `ExperimentBudget` |
| All pruned | `PortfolioSelectionFailure` | No candidate meets `min_value_threshold` after restoration |

---

## Phase 17.8.4 Decision

**PORTFOLIO OPTIMIZATION: COMPLETE**

Phase 17.8.5 (Experiment Scheduler) proceeds in the same session.
