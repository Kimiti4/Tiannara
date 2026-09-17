# EFDI D2 — Architecture Reconnaissance

**Gate:** EFDI-D2
**Phase:** Forecast + Calibration
**Inputs:** D1 (Signal Intelligence, CERTIFIED_BOUNDED), existing Tiannara infrastructure.

## 1. Classification

### REUSE (compose existing, do not fork)

| Capability | Canonical module / signature | D2 use |
|-----------|------------------------------|--------|
| Bayesian update | `Tiannara.Math.Probability.bayes_update/3` → `{:ok, posterior}` | posterior recomputation on evidence |
| Entropy | `Tiannara.Foundations.InformationTheory.shannon_entropy/1` (raw float) | forecast resolution / divergence |
| KL divergence | `Tiannara.Foundations.InformationTheory.kl_divergence/2` (raw float) | evidence update, info gain |
| Normalization | `Tiannara.Constraints.normalize_probabilities/1`, `normalize_to/2` → `{:ok, list, evidence}` | distribution integrity / normalization |
| Evidence report | `Tiannara.Constraints.evidence_report/1` → `%{status, result, evidence, ...}` | certification-consistent results |
| Identity | `Tiannara.Executive.Types.new_id/0` | forecast ids |
| Events / lineage | `Tiannara.Executive.Event`, `EventStore.append/1` | append-only forecast events |
| Signal contracts | `Tiannara.Forecasting.Signal`, `SignalRegistry` | forecast signal_refs |
| D1 contract structs | `Tiannara.Forecasting.Contracts.{Forecast,BaseRate,ForecastRequest}` | D2 implements these |

### NEW (D2 must implement)

- Base-rate engine (`BaseRateEngine`)
- Probabilistic forecast engine (`ForecastEngine`)
- Forecast registry + immutable lineage (`ForecastRegistry`)
- Calibration engine (Brier / LogLoss / calibration error / reliability / resolution / sharpness)
- Outcome linking + hindsight isolation (`Outcome`)

### ADAPTER (implement D1-declared behaviours)

- `Adapters.Evidence`, `Adapters.Research`, `Adapters.CIS`, `Adapters.WorldModel`
  (callbacks declared in D1, now implemented in D2)

### DEPRECATED / AVOID

- Do **not** use `Tiannara.Math.Probability.shannon_entropy/1` (`{:ok, float}`)
  alongside `InformationTheory` (raw float) — **divergence risk.** D2 standardizes
  on `InformationTheory` (raw floats), matching `SignalValue`.
- Do **not** copy local `normalize_probabilities` / `compute_posterior` /
  `entropy` implementations found in `WorldModel.PredictionEngine`,
  `Discovery.Discovery`, `Research.Director.EvidenceDriven`. Use the shared
  `Constraints` / `Math.Probability` / `InformationTheory`.

### UNKNOWN

- No unified `Outcome` contract exists; outcomes are scattered
  (`DiscoveryResult.outcome` atom, `Research.Experiment.result`, EventStore
  events). D2 defines a canonical `Outcome` adapter and (via `Adapters.Evidence`)
  maps to the existing event infrastructure.

## 2. Canonical dependency direction

```
Constitutional Mathematics (Reuse: Math.Probability, Constraints, InformationTheory)
                              │
                              ▼
   D1 Signal ────► D2 Forecast Engine ──► Forecast Registry ──► Calibration
                              │                                      │
                              └──────────► Outcome (reality) ────────┘
```

Not: a second EFDI probability system. D2 composes existing math primitives.

## 3. Divergence landmines identified

1. Two `shannon_entropy` contracts — standardize on `InformationTheory` (raw).
2. Local posterior/normalize copies — reuse `Constraints` + `Math.Probability`.
3. No `EvidenceSet`/unified `Outcome` — D2 defines adapters, does not invent a
   parallel evidence ontology.

## 4. Non-negotiable boundaries

- Do **not** modify the D1-certified forecasting stubs
  (`ForecastAuditor`, `FutureSimulator`, `StrategicPlanner`, `DecisionArchive`).
- Do **not** replace CIS predictive logic — expose a forecast-consumption
  interface only.
- Do **not** redesign the World Model — expose the future-state-transition
  interface only.
- Probability ≠ confidence; distribution ≠ point estimate.
