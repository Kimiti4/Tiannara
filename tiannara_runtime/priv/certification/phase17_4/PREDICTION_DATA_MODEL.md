# Phase 17.4 — Prediction Data Model

## 1. Struct Hierarchy

```
Prediction
├── prediction_id       : String (prefix: "pr_")
├── world_model_id      : String
├── world_model_version : integer
├── model_fingerprint   : String
├── target_variables    : [ForecastVariable.t()]
├── horizon             : :immediate | :short_term | :medium_term | :long_term | :civilization
├── assumptions         : map()
├── confidence          : ConfidenceEstimate.t()
├── uncertainty         : UncertaintyDistribution.t()
├── forecast            : Forecast.t()
├── replay_fingerprint  : String (prefix: "fp_")
├── evidence_roots      : [String.t()]
├── math_verification   : String (or nil)
├── archaeology_root    : String (prefix: "ar_")
├── metadata            : map()
└── created_at          : String (ISO 8601)

Forecast
├── forecast_id         : String (prefix: "fc_")
├── horizon             : atom()
├── time_steps          : [ForecastStep.t()]
├── variables           : [ForecastVariable.t()]
├── governing_equations : [String.t()]
├── causal_constraints  : [String.t()]
└── metadata            : map()

ForecastStep
├── step                : integer
├── timestamp           : String (ISO 8601)
├── values              : %{variable_name => float()}
└── intervention_state  : map() | nil

ForecastVariable
├── variable_id         : String
├── name                : String
├── type                : :continuous | :categorical
├── domain              : term()
└── metadata            : map()

ConfidenceEstimate
├── confidence_id       : String (prefix: "ce_")
├── score               : float() (0.0..1.0)
├── evidence_quality    : float() (0.0..1.0)
├── model_maturity      : float() (0.0..1.0)
├── replay_stability    : float() (0.0..1.0)
├── historical_perf     : float() (0.0..1.0)
├── explanation         : String
└── metadata            : map()

UncertaintyDistribution
├── uncertainty_id      : String (prefix: "ud_")
├── variance            : float()
├── std_deviation       : float()
├── confidence_interval : Interval.t()
├── distribution_type   : :normal | :uniform | :empirical | :unknown
├── entropy             : float()
├── sources             : [String.t()]
└── metadata            : map()

PredictionScenario
├── scenario_id         : String (prefix: "ps_")
├── name                : String
├── assumptions         : map()
├── intervention        : Intervention.t() | nil
├── forecast            : Forecast.t()
└── metadata            : map()

ForecastComparison
├── comparison_id       : String (prefix: "pc_")
├── forecasts           : [Forecast.t()]
├── divergence          : float()
├── consensus           : map()
├── confidence_ranking  : [String.t()]
├── explanation         : String
└── metadata            : map()

PredictionEvidence
├── evidence_id         : String (prefix: "pe_")
├── prediction_id       : String
├── model_evidence      : [String.t()]
├── assumption_hashes   : [String.t()]
├── equation_hashes     : [String.t()]
├── causal_roots        : [String.t()]
└── metadata            : map()
```

## 2. Content-Addressed ID Prefixes

| Struct | Prefix |
|--------|--------|
| Prediction | `pr_` |
| Forecast | `fc_` |
| ForecastStep | `fs_` |
| ForecastVariable | `fv_` |
| ConfidenceEstimate | `ce_` |
| UncertaintyDistribution | `ud_` |
| PredictionScenario | `ps_` |
| ForecastComparison | `pc_` |
| PredictionEvidence | `pe_` |

## 3. Validation Rules

| Struct | Rules |
|--------|-------|
| Prediction | non-empty model_id, ≥1 target_variable, valid horizon, confidence 0-1 |
| Forecast | non-empty variables, each step has same variable keys |
| ForecastStep | step ≥ 0, no nil values, intervention_state optional |
| ForecastVariable | non-empty name, valid type, domain constraints |
| ConfidenceEstimate | score 0-1, sub-scores 0-1, non-empty explanation |
| UncertaintyDistribution | variance ≥ 0, std_dev ≥ 0, CI valid range |
| PredictionScenario | non-empty name, non-nil forecast |
| ForecastComparison | ≥2 forecasts, divergence ≥ 0 |
| PredictionEvidence | non-empty prediction_id |

## 4. Serialization

All structs implement `canonicalize/1` returning key-sorted maps. Canonical JSON via `Jason.encode!/1`. SHA-256 via `:crypto.hash/2`.

## 5. Replay Fingerprint

The replay fingerprint is computed over the canonicalized Prediction struct excluding:
- `prediction_id` (assigned deterministically but post-hoc)
- `archaeology_root` (assigned post-hoc)
- `created_at` (temporal but not semantic)
- `metadata` (excluded for forward compatibility)

All other fields contribute to the SHA-256 fingerprint.
