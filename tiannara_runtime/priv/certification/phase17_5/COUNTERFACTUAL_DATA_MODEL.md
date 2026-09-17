# Phase 17.5 — Counterfactual Data Model

## 1. Core Structs

### CounterfactualWorld

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| counterfactual_id | String | computed | `cf_` + SHA-256 |
| parent_model_id | String | yes | Certified world model ID |
| parent_version | integer | yes | World model version |
| parent_fingerprint | String | yes | World model fingerprint |
| intervention | Intervention.t() | yes | The applied intervention |
| divergence_point | DivergencePoint.t() | yes | Where/when divergence occurs |
| timeline | AlternativeTimeline.t() | yes | The constructed timeline |
| outcomes | [Forecast.t()] | yes | Predicted outcomes |
| assumptions | map() | yes | Explicit assumptions |
| confidence | ConfidenceEstimate.t() | no | Optional confidence |
| uncertainty | UncertaintyDistribution.t() | no | Optional uncertainty |
| evidence_roots | [String.t()] | no | Evidence lineage |
| replay_fingerprint | String | computed | `fp_` + SHA-256 |
| archaeology_root | String | no | Archaeology record |
| created_at | String | computed | ISO 8601 |

### Intervention

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| intervention_id | String | computed | `iv_` + SHA-256 |
| type | atom | yes | :variable \| :structural \| :policy \| :engineering \| :environmental |
| target | String | yes | Target variable or structure |
| operation | atom | yes | :fix \| :remove \| :add \| :modify \| :replace |
| value | term() | no | New value (for :fix/:modify/:replace) |
| constraints | [map()] | no | Additional constraints |
| evidence_hash | String | no | Evidence backing this intervention |
| description | String | no | Human-readable description |
| metadata | map() | no | Extra metadata |

### DivergencePoint

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| divergence_id | String | computed | `dp_` + SHA-256 |
| parent_model_id | String | yes | World model diverged from |
| step | integer | yes | Time step of divergence |
| state | map() | yes | World state at divergence |
| intervention | Intervention.t() | yes | Triggering intervention |
| description | String | no | Description |

### BranchNode

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| branch_id | String | computed | `bn_` + SHA-256 |
| parent_branch_id | String | no | Parent branch (nil for root) |
| divergence | DivergencePoint.t() | yes | How this branch diverges |
| children | [String.t()] | no | Child branch IDs |
| depth | integer | yes | Depth from root (0 = root) |
| metadata | map() | no | Extra metadata |

### BranchComparison

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| comparison_id | String | computed | `bc_` + SHA-256 |
| original_id | String | yes | Original world/forecast ID |
| counterfactual_id | String | yes | Counterfactual world ID |
| divergence_metric | float | yes | Divergence in [0, 1] |
| similarity_metric | float | yes | Similarity in [0, 1] |
| causal_distance | float | yes | Causal distance |
| entropy_delta | float | yes | Entropy change |
| variable_impacts | %{String.t() => float()} | no | Per-variable impact |
| explanation | String | no | Text explanation |
| metadata | map() | no | Extra metadata |

### CounterfactualEvidence

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| evidence_id | String | computed | `ce_` + SHA-256 |
| counterfactual_id | String | yes | Counterfactual world ID |
| parent_evidence | [String.t()] | no | Parent evidence roots |
| intervention_evidence | [String.t()] | no | Intervention evidence |
| timeline_hashes | [String.t()] | no | Timeline step hashes |
| math_verification | String | no | Math verification hash |
| replay_attempts | [map()] | no | Replay records |
| metadata | map() | no | Extra metadata |

### AlternativeTimeline

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| timeline_id | String | computed | `at_` + SHA-256 |
| branch_id | String | yes | Source branch |
| steps | [TimelineStep.t()] | yes | Ordered state sequence |
| initial_state | map() | yes | State at divergence |
| final_state | map() | yes | State at end |
| total_steps | integer | yes | Number of steps |
| metadata | map() | no | Extra metadata |

### TimelineStep

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| step | integer | yes | Step number |
| state | map() | yes | World state at this step |
| intervention_active | boolean() | yes | Whether intervention is active |
| causal_propagation | [String.t()] | no | Variables affected this step |
| entropy | float | no | State entropy at step |
| timestamp | String | no | ISO 8601 timestamp |

### ScenarioOutcome

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| outcome_id | String | computed | `so_` + SHA-256 |
| counterfactual_id | String | yes | Parent counterfactual |
| variable | String | yes | Outcome variable name |
| value | float | yes | Predicted value |
| confidence | float | yes | Confidence in [0, 1] |
| delta_from_original | float | no | Change from original |
| metadata | map() | no | Extra metadata |

## 2. ID Prefixes

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

## 3. Serialization Rules

- All structs implement `canonicalize/1` returning key-sorted map
- Nested structs canonicalized recursively
- Atoms stringified via `Atom.to_string/1`
- Lists sorted where order is semantically irrelevant
- ID computed via SHA-256 over canonical JSON
- Replay fingerprint excludes: counterfactual_id, archaeology_root, created_at, metadata
