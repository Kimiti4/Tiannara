# Phase 17.5.05 — Constitutional Counterfactual Runtime Freeze

## 1. Frozen Schemas

### CounterfactualWorld

| Field | Type | Required | Default |
|-------|------|----------|---------|
| counterfactual_id | String | computed | `cf_` + SHA-256 |
| parent_model_id | String | yes | — |
| parent_version | integer | yes | — |
| parent_fingerprint | String | yes | — |
| intervention | Intervention.t() | yes | — |
| divergence_point | DivergencePoint.t() | yes | — |
| timeline | AlternativeTimeline.t() | yes | — |
| outcomes | [Forecast.t()] | yes | — |
| assumptions | map() | yes | %{} |
| confidence | ConfidenceEstimate.t() | no | nil |
| uncertainty | UncertaintyDistribution.t() | no | nil |
| evidence_roots | [String.t()] | no | [] |
| replay_fingerprint | String | computed | `fp_` |
| archaeology_root | String | no | nil |
| created_at | String | computed | ISO 8601 |

### Intervention

| Field | Type | Required | Default |
|-------|------|----------|---------|
| intervention_id | String | computed | `iv_` + SHA-256 |
| type | atom | yes | — |
| target | String | yes | — |
| operation | atom | yes | — |
| value | term() | no | nil |
| constraints | [map()] | no | [] |
| evidence_hash | String | no | nil |
| description | String | no | "" |
| metadata | map() | no | %{} |

Intervention types: `:variable | :structural | :policy | :engineering | :environmental`
Operations: `:fix | :remove | :add | :modify | :replace`

### DivergencePoint

| Field | Type | Required | Default |
|-------|------|----------|---------|
| divergence_id | String | computed | `dp_` + SHA-256 |
| parent_model_id | String | yes | — |
| step | integer | yes | — |
| state | map() | yes | — |
| intervention | Intervention.t() | yes | — |
| description | String | no | "" |

### BranchNode

| Field | Type | Required | Default |
|-------|------|----------|---------|
| branch_id | String | computed | `bn_` + SHA-256 |
| parent_branch_id | String | no | nil |
| divergence | DivergencePoint.t() | yes | — |
| children | [String.t()] | no | [] |
| depth | integer | yes | — |
| metadata | map() | no | %{} |

### BranchComparison

| Field | Type | Required | Default |
|-------|------|----------|---------|
| comparison_id | String | computed | `bc_` + SHA-256 |
| original_id | String | yes | — |
| counterfactual_id | String | yes | — |
| divergence_metric | float | yes | 0.0 |
| similarity_metric | float | yes | 1.0 |
| causal_distance | float | yes | 0.0 |
| entropy_delta | float | yes | 0.0 |
| variable_impacts | %{String.t() => float()} | no | %{} |
| explanation | String | no | "" |
| metadata | map() | no | %{} |

### CounterfactualEvidence

| Field | Type | Required | Default |
|-------|------|----------|---------|
| evidence_id | String | computed | `ce_` + SHA-256 |
| counterfactual_id | String | yes | — |
| parent_evidence | [String.t()] | no | [] |
| intervention_evidence | [String.t()] | no | [] |
| timeline_hashes | [String.t()] | no | [] |
| math_verification | String | no | nil |
| replay_attempts | [map()] | no | [] |
| metadata | map() | no | %{} |

### AlternativeTimeline

| Field | Type | Required | Default |
|-------|------|----------|---------|
| timeline_id | String | computed | `at_` + SHA-256 |
| branch_id | String | yes | — |
| steps | [TimelineStep.t()] | yes | — |
| initial_state | map() | yes | — |
| final_state | map() | yes | — |
| total_steps | integer | yes | — |
| metadata | map() | no | %{} |

### TimelineStep

| Field | Type | Required | Default |
|-------|------|----------|---------|
| step | integer | yes | — |
| state | map() | yes | — |
| intervention_active | boolean() | yes | false |
| causal_propagation | [String.t()] | no | [] |
| entropy | float | no | 0.0 |
| timestamp | String | no | nil |

### ScenarioOutcome

| Field | Type | Required | Default |
|-------|------|----------|---------|
| outcome_id | String | computed | `so_` + SHA-256 |
| counterfactual_id | String | yes | — |
| variable | String | yes | — |
| value | float | yes | — |
| confidence | float | yes | 0.0 |
| delta_from_original | float | no | nil |
| metadata | map() | no | %{} |

## 2. Frozen APIs

### CounterfactualEngine

```elixir
@spec create_counterfactual(String.t(), Intervention.t(), keyword()) ::
  {:ok, CounterfactualWorld.t()} | {:error, term()}

@spec get_counterfactual(String.t()) ::
  {:ok, CounterfactualWorld.t()} | {:error, :not_found}

@spec replay_counterfactual(String.t()) ::
  {:ok, %{verified: boolean(), mismatches: [String.t()]}}
```

### InterventionExecutor

```elixir
@spec execute(WorldModel.t(), Intervention.t()) ::
  {:ok, Intervention.t()} | {:error, term()}

@spec validate_intervention(WorldModel.t(), Intervention.t()) ::
  :ok | {:error, String.t()}

@spec apply(WorldModel.t(), Intervention.t()) ::
  {:ok, WorldModel.t()} | {:error, term()}
```

### BranchGenerator

```elixir
@spec generate(WorldModel.t(), Intervention.t(), keyword()) ::
  {:ok, BranchNode.t(), DivergencePoint.t()} | {:error, term()}

@spec generate_nested(WorldModel.t(), [Intervention.t()]) ::
  {:ok, [BranchNode.t()]} | {:error, term()}
```

### BranchComparator

```elixir
@spec compare(WorldModel.t(), CounterfactualWorld.t()) ::
  {:ok, BranchComparison.t()}

@spec compare_multiple([CounterfactualWorld.t()]) ::
  {:ok, [BranchComparison.t()]}

@spec compute_divergence(AlternativeTimeline.t(), AlternativeTimeline.t()) :: float()

@spec compute_similarity(AlternativeTimeline.t(), AlternativeTimeline.t()) :: float()

@spec compute_causal_distance(CausalGraph.t(), CausalGraph.t()) :: float()
```

### AlternativeTimelineBuilder

```elixir
@spec construct(WorldModel.t(), BranchNode.t(), DivergencePoint.t(), keyword()) ::
  {:ok, AlternativeTimeline.t()} | {:error, term()}

@spec simulate_step(map(), [Equation.t()], keyword()) ::
  {:ok, map()} | {:error, term()}
```

### CounterfactualReplay

```elixir
@spec fingerprint(CounterfactualWorld.t()) :: String.t()

@spec verify(CounterfactualWorld.t()) ::
  {:ok, %{verified: boolean(), mismatches: [String.t()]}}

@spec replay(CounterfactualWorld.t()) ::
  {:ok, CounterfactualWorld.t()} | {:error, term()}
```

### CounterfactualArchaeology

```elixir
@spec record_branch(CounterfactualWorld.t()) :: {:ok, CounterfactualEvidence.t()}

@spec get_lineage(String.t()) ::
  {:ok, CounterfactualEvidence.t()} | {:error, :not_found}

@spec record_replay(String.t(), String.t(), String.t(), boolean()) :: :ok
```

## 3. Frozen Behaviours

### CounterfactualBehaviour

```elixir
@callback create_counterfactual(String.t(), Intervention.t(), keyword()) ::
  {:ok, CounterfactualWorld.t()} | {:error, term()}
```

### InterventionBehaviour

```elixir
@callback execute(WorldModel.t(), Intervention.t()) ::
  {:ok, Intervention.t()} | {:error, term()}

@callback validate(WorldModel.t(), Intervention.t()) ::
  :ok | {:error, String.t()}
```

### ReplayBehaviour

```elixir
@callback fingerprint(CounterfactualWorld.t()) :: String.t()
@callback verify(CounterfactualWorld.t()) ::
  {:ok, %{verified: boolean(), mismatches: [String.t()]}}
```

### ComparisonBehaviour

```elixir
@callback compare(WorldModel.t(), CounterfactualWorld.t()) ::
  {:ok, BranchComparison.t()}
```

## 4. ETS Registry Tables

| Table Name | Purpose |
|------------|---------|
| `:counterfactual_store` | CounterfactualWorld cache by ID |
| `:counterfactual_branch_store` | BranchNode cache by ID |
| `:counterfactual_archaeology` | CounterfactualEvidence store |

## 5. Content-Addressed ID Prefixes

| Prefix | Struct |
|--------|--------|
| `cf_` | CounterfactualWorld |
| `iv_` | Intervention |
| `dp_` | DivergencePoint |
| `bn_` | BranchNode |
| `bc_` | BranchComparison |
| `ce_` | CounterfactualEvidence |
| `at_` | AlternativeTimeline |
| `ts_` | TimelineStep |
| `so_` | ScenarioOutcome |
| `fp_` | Replay fingerprint |
| `ar_` | Archaeology root |

## 6. Module Paths

All struct and engine modules live under:
`lib/tiannara_runtime/world_model/counterfactual/`

Behaviours under:
`lib/tiannara_runtime/world_model/counterfactual/behaviours/`

## 7. Serialization Rules

- All structs implement `canonicalize/1` returning key-sorted map
- Nested structs canonicalized recursively
- Atoms stringified via `Atom.to_string/1`
- Lists sorted where order is semantically irrelevant
- ID computed via SHA-256 over canonical JSON
- Replay fingerprint is SHA-256 over canonical CounterfactualWorld (excluding: counterfactual_id, archaeology_root, created_at, metadata, replay_fingerprint)

## 8. Freeze Scope

This freeze covers:
- 9 Counterfactual Ontology structs
- 7 Engine modules
- 4 Behaviours
- 3 ETS tables
- 11 ID prefixes
