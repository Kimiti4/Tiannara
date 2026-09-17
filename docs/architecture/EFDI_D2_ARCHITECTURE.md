# EFDI D2 — Forecast & Calibration Architecture

**Phase:** D2 — Forecast + Calibration (after certified D1 Signal Intelligence).

## 1. Mission

D2 delivers the forecast layer of the EFDI epistemic pipeline:

```
observation → signal → evidence → hypothesis → forecast → outcome → calibration → confidence
```

A D2 forecast is an **immutable, evidence-linked, explicitly uncertain, reproducible,
eventually scoreable** probability distribution over mutually exclusive outcomes.
D2 never claims accuracy before sufficient outcome data exists:
`INSUFFICIENT_DATA` is a distinct verdict from `POOR_CALIBRATION`.

## 2. Scope boundary

| Concern | D2 responsibility |
|---------|-------------------|
| Forecast construction | Yes |
| Probability integrity | Yes |
| Base-rate composition | Yes |
| Evidence linkage | Yes |
| Outcome linking (hindsight-isolated) | Yes |
| Calibration scoring | Yes |
| Decision-taking | **No** (D3) |
| Constitutional regulation | **No** (CIS keeps authority) |
| World-state representation | **No** (Unified Reality Graph remains canonical) |

## 3. Architecture

```
                 +------------------------------+
   signals ────► │ ForecastEngine.forecast/1    │  ◄── BaseRateEngine (reference class)
   evidence ───► │  (composes Math.Probability) │  ◄── ForecastRequest contract
                 +--------------+---------------+
                                │
                                v
                 +------------------------------+
                 │    Contracts.Forecast        │  immutable, versioned, evidence-linked
                 +--------------+---------------+
                                │
                                v
                 +------------------------------+        +------------------------------+
                 │    ForecastRegistry          │ ─────► │  Outcome.guard!/2 (hindsight) │
                 │    (ETS, immutable)          │        +--------------+---------------+
                 +--------------+---------------+                       │
                                │                                      v
                                │                        +------------------------------+
                                +────────────────────────► │    Calibration              │
                                                          │  Brier/LogLoss/Reliability  │
                                                          +------------------------------+
```

## 4. Reuse vs new (no parallel system)

| Capability | Source | D2 usage |
|------------|--------|----------|
| Probability normalize | `Tiannara.Constraints` | `normalize_probabilities` in `Forecast.new` |
| Bayes update | `Tiannara.Math.Probability` | `ForecastEngine.update_with_bayes/3` |
| Shannon entropy | `Tiannara.Foundations.InformationTheory` | `Calibration.sharpness/1` |
| ID generation | `Tiannara.Executive.Types` | forecast / outcome ids |
| Event lineage | `Tiannara.Executive.EventStore` | best-effort `efdi.forecast.registered` |

No parallel probability engine, no local posterior store, no artificial model zoo:
`ForecastEngine` is the single honest forecaster.

## 5. Adapter boundaries (implemented from the D1-declared behaviours)

| Behaviour | Implementation | Boundary honored |
|-----------|----------------|------------------|
| `Adapters.Evidence` | `EvidenceImpl` | signals link to existing evidence by id |
| `Adapters.Research` | `ResearchImpl` | signal → ResearchDirector priority ingestion |
| `Adapters.CIS` | `CISImpl` | telemetry/collapse-proxy; CIS keeps authority |
| `Adapters.WorldModel` | `WorldModelImpl` | consume-only; refuses pseudo world-conflict |

D1 declared these only; D2 provides honest concrete implementations.

## 6. Design principles

1. **Epistemic honesty** — when a distribution cannot be justified, the forecast
   carries `probabilities: :unknown`, never a fabricated uniform.
2. **Immutability** — forecasts are never rewritten; corrections are new versions
   linked through `lineage`.
3. **No hindsight** — outcomes are linked only when observed at/after forecast time.
4. **No hidden recalibration** — scoring is attribute-safe and single-valued per method.
5. **Composition** — existing Tiannara math is reused; boundaries are declared and honored.