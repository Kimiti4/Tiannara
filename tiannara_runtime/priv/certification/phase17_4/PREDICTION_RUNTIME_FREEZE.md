# Phase 17.4.05 — Constitutional Prediction Runtime Freeze

## 1. Frozen Schemas

### Prediction

| Field | Type | Required | Default |
|-------|------|----------|---------|
| prediction_id | String | computed | `pr_` + SHA-256 |
| world_model_id | String | yes | — |
| world_model_version | integer | yes | — |
| model_fingerprint | String | yes | — |
| target_variables | [ForecastVariable.t()] | yes | — |
| horizon | atom | yes | — |
| assumptions | map() | yes | %{} |
| confidence | ConfidenceEstimate.t() | no | nil |
| uncertainty | UncertaintyDistribution.t() | no | nil |
| forecast | Forecast.t() | yes | — |
| replay_fingerprint | String | computed | `fp_` |
| evidence_roots | [String.t()] | no | [] |
| math_verification | String | no | nil |
| archaeology_root | String | no | nil |
| metadata | map() | no | %{} |
| created_at | String | computed | ISO 8601 |

### Forecast

| Field | Type | Required | Default |
|-------|------|----------|---------|
| forecast_id | String | computed | `fc_` + SHA-256 |
| horizon | atom | yes | — |
| time_steps | [ForecastStep.t()] | yes | — |
| variables | [ForecastVariable.t()] | yes | — |
| governing_equations | [String.t()] | no | [] |
| causal_constraints | [String.t()] | no | [] |
| metadata | map() | no | %{} |

### ForecastStep

| Field | Type | Required | Default |
|-------|------|----------|---------|
| step | integer | yes | — |
| timestamp | String | no | nil |
| values | %{String.t() => float()} | yes | — |
| intervention_state | map() | no | nil |

### ForecastVariable

| Field | Type | Required | Default |
|-------|------|----------|---------|
| variable_id | String | computed | `fv_` + SHA-256 |
| name | String | yes | — |
| type | atom | yes | :continuous |
| domain | term() | no | nil |
| metadata | map() | no | %{} |

### ConfidenceEstimate

| Field | Type | Required | Default |
|-------|------|----------|---------|
| confidence_id | String | computed | `ce_` + SHA-256 |
| score | float | yes | — |
| evidence_quality | float | yes | 0.0 |
| model_maturity | float | yes | 0.0 |
| replay_stability | float | yes | 0.0 |
| historical_perf | float | no | nil |
| explanation | String | yes | "" |
| metadata | map() | no | %{} |

### UncertaintyDistribution

| Field | Type | Required | Default |
|-------|------|----------|---------|
| uncertainty_id | String | computed | `ud_` + SHA-256 |
| variance | float | yes | 0.0 |
| std_deviation | float | yes | 0.0 |
| confidence_interval | Interval.t() | no | nil |
| distribution_type | atom | yes | :unknown |
| entropy | float | yes | 0.0 |
| sources | [String.t()] | no | [] |
| metadata | map() | no | %{} |

### PredictionScenario

| Field | Type | Required | Default |
|-------|------|----------|---------|
| scenario_id | String | computed | `ps_` + SHA-256 |
| name | String | yes | — |
| assumptions | map() | no | %{} |
| intervention | Intervention.t() | no | nil |
| forecast | Forecast.t() | yes | — |
| metadata | map() | no | %{} |

### ForecastComparison

| Field | Type | Required | Default |
|-------|------|----------|---------|
| comparison_id | String | computed | `pc_` + SHA-256 |
| forecasts | [Forecast.t()] | yes | — |
| divergence | float | yes | 0.0 |
| consensus | map() | no | %{} |
| confidence_ranking | [String.t()] | no | [] |
| explanation | String | no | "" |
| metadata | map() | no | %{} |

### PredictionEvidence

| Field | Type | Required | Default |
|-------|------|----------|---------|
| evidence_id | String | computed | `pe_` + SHA-256 |
| prediction_id | String | yes | — |
| model_evidence | [String.t()] | no | [] |
| assumption_hashes | [String.t()] | no | [] |
| equation_hashes | [String.t()] | no | [] |
| causal_roots | [String.t()] | no | [] |
| metadata | map() | no | %{} |

## 2. Frozen APIs

### PredictionEngine

```elixir
@spec predict(String.t(), [String.t()], atom(), keyword()) ::
  {:ok, Prediction.t()} | {:error, term()}

@spec predict_scenario(String.t(), [String.t()], atom(), keyword(), Intervention.t()) ::
  {:ok, PredictionScenario.t()} | {:error, term()}

@spec get_prediction(String.t()) ::
  {:ok, Prediction.t()} | {:error, :not_found}
```

### ForecastGenerator

```elixir
@spec generate(WorldModel.t(), [ForecastVariable.t()], atom(), keyword()) ::
  {:ok, Forecast.t()} | {:error, term()}

@spec generate_trajectory(WorldModel.t(), String.t(), integer(), keyword()) ::
  {:ok, [ForecastStep.t()]} | {:error, term()}

@spec generate_equilibrium(WorldModel.t(), String.t(), keyword()) ::
  {:ok, float()} | {:error, term()}
```

### ConfidenceEngine

```elixir
@spec compute(WorldModel.t(), Forecast.t(), keyword()) ::
  {:ok, ConfidenceEstimate.t()}

@spec compute_evidence_quality(WorldModel.t()) :: float()

@spec compute_model_maturity(String.t(), integer()) :: float()
```

### UncertaintyEngine

```elixir
@spec propagate(WorldModel.t(), Forecast.t(), keyword()) ::
  {:ok, UncertaintyDistribution.t()}

@spec parameter_uncertainty(WorldModel.t()) :: float()

@spec measurement_uncertainty(WorldModel.t()) :: float()

@spec structure_uncertainty(WorldModel.t()) :: float()
```

### ForecastComparator

```elixir
@spec compare([Forecast.t()]) ::
  {:ok, ForecastComparison.t()}

@spec compute_divergence(Forecast.t(), Forecast.t()) :: float()

@spec rank_by_confidence([Forecast.t()]) :: [String.t()]
```

### PredictionReplay

```elixir
@spec fingerprint(Prediction.t()) :: String.t()

@spec verify(String.t(), keyword()) ::
  {:ok, %{verified: boolean(), mismatches: [String.t()]}}

@spec replay(Prediction.t()) :: {:ok, Prediction.t()} | {:error, term()}
```

### PredictionArchaeology

```elixir
@spec record_prediction(Prediction.t()) :: {:ok, PredictionEvidence.t()}

@spec get_prediction_lineage(String.t()) ::
  {:ok, PredictionEvidence.t()} | {:error, :not_found}

@spec record_replay(String.t(), String.t(), String.t(), boolean()) :: :ok
```

## 3. Frozen Behaviours

### PredictionBehaviour

```elixir
@callback predict(String.t(), [String.t()], atom(), keyword()) ::
  {:ok, Prediction.t()} | {:error, term()}
```

### ForecastBehaviour

```elixir
@callback generate(WorldModel.t(), [ForecastVariable.t()], atom(), keyword()) ::
  {:ok, Forecast.t()} | {:error, term()}
```

### ReplayBehaviour

```elixir
@callback fingerprint(Prediction.t()) :: String.t()
@callback verify(String.t(), keyword()) ::
  {:ok, %{verified: boolean(), mismatches: [String.t()]}}
```

### ConfidenceBehaviour

```elixir
@callback compute(WorldModel.t(), Forecast.t(), keyword()) ::
  {:ok, ConfidenceEstimate.t()}
```

## 4. ETS Registry Tables

| Table Name | Purpose |
|------------|---------|
| `:prediction_store` | Prediction cache by ID |
| `:forecast_store` | Forecast cache by ID |
| `:prediction_archaeology` | Prediction evidence store |
| `:prediction_comparisons` | Forecast comparison cache |

## 5. Content-Addressed ID Prefixes

| Prefix | Struct |
|--------|--------|
| `pr_` | Prediction |
| `fc_` | Forecast |
| `fs_` | ForecastStep |
| `fv_` | ForecastVariable |
| `ce_` | ConfidenceEstimate |
| `ud_` | UncertaintyDistribution |
| `ps_` | PredictionScenario |
| `pc_` | ForecastComparison |
| `pe_` | PredictionEvidence |
| `fp_` | Replay fingerprint |
| `ar_` | Archaeology root |

## 6. Module Paths

All struct and engine modules live under:
`lib/tiannara_runtime/world_model/prediction/`

Behaviours under:
`lib/tiannara_runtime/world_model/prediction/behaviours/`

## 7. Serialization Rules

- All structs implement `canonicalize/1` returning key-sorted map
- Nested structs canonicalized recursively
- Atoms stringified via `Atom.to_string/1`
- Lists sorted where order is semantically irrelevant
- ID computed via SHA-256 over canonical JSON
- Replay fingerprint is SHA-256 over canonical Prediction (excluding: prediction_id, archaeology_root, created_at, metadata)

## 8. Freeze Scope

This freeze covers:
- 8 Prediction Ontology structs
- 7 Prediction Engine modules
- 4 Behaviours
- 4 ETS tables
- 10 ID prefixes
