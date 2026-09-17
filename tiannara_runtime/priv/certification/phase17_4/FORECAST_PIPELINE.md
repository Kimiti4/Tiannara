# Phase 17.4 — Forecast Pipeline

## 1. Pipeline Stages

```
Stage 0: Request       ─→ Consumer specifies variables, horizon, assumptions
Stage 1: Load Model     ─→ Load certified world model by ID or fingerprint
Stage 2: Generate       ─→ Execute model equations to produce raw forecast
Stage 3: Confidence     ─→ Compute confidence from evidence quality + model maturity
Stage 4: Uncertainty    ─→ Propagate uncertainty from all sources
Stage 5: Horizon Align  ─→ Snap forecast to nearest replay-compatible horizon
Stage 6: Fingerprint    ─→ Compute replay fingerprint over canonical forecast
Stage 7: Archive        ─→ Record prediction + lineage in archaeology store
Stage 8: Certify        ─→ Verify prediction consistency with Mathematics Substrate
Stage 9: Return         ─→ Return Prediction to consumer
```

## 2. Stage Detail

### Stage 0: Request

Input: `target_variables :: [String.t()]`, `horizon :: atom()`, `assumptions :: keyword()`, `model_id :: String.t()`

Validation:
- All target variables exist in the world model
- Horizon is one of known horizons
- Assumptions are well-formed

### Stage 1: Load Model

Load the certified world model from `ModelRegistry`.

- Verifies model status is `:operational`
- Loads equation system, causal graph, parameter estimates
- Fails if model not found or not certified

### Stage 2: Generate

Execute model equations:

```
For each target variable:
  - Collect observed initial conditions from evidence
  - Solve equation system forward over the time horizon
  - Apply causal graph constraints (acyclic ordering)
  - Return raw trajectory or equilibrium value
```

Determinism ensured by:
- Fixed variable ordering
- Seeded random number generation (if stochastic)
- Canonical equation processing order

### Stage 3: Confidence

Compute confidence from:

| Metric | Weight |
|--------|--------|
| Evidence quality (N observations, recency, source diversity) | 0.35 |
| Model maturity (number of recertifications, stability) | 0.25 |
| Replay stability (variance across replays) | 0.20 |
| Historical performance (prediction accuracy vs actuals) | 0.20 |

Output: `confidence_score :: 0.0..1.0`

### Stage 4: Uncertainty

Propagate uncertainty from:

| Source | Representation |
|--------|---------------|
| Parameter uncertainty | Variance in parameter estimates |
| Measurement uncertainty | Variance in observation values |
| Model structure uncertainty | Ensemble spread across candidate models |
| Intervention uncertainty | Variance from do-operator assumptions |

Output: `UncertaintyDistribution` with variance, interval, distribution type.

### Stage 5: Horizon Align

Map request horizon to supported horizon:

| Request | Internal |
|---------|----------|
| `:immediate` | t+1 step |
| `:short_term` | t+1 to t+10 steps |
| `:medium_term` | t+11 to t+100 steps |
| `:long_term` | t+101 to t+1000 steps |
| `:civilization` | t+1001+ steps |

Each horizon preserves fingerprint compatibility via step-aligned sampling.

### Stage 6: Fingerprint

Canonicalize the full `Forecast` struct to deterministic JSON, then:

```
fingerprint = "fp_" <> SHA-256(canonical_json)
```

### Stage 7: Archive

Store prediction lineage in prediction archaeology ETS:
- Evidence roots from world model
- Assumptions hash
- Model fingerprint
- Forecast fingerprint
- Math verification hash

### Stage 8: Certify

Verify forecast consistency:
- Symbolic equation checking with Math Substrate
- Type consistency of forecast values with variable types
- Causal graph consistency (no edge violations)

### Stage 9: Return

Assemble and return `Prediction.t()` struct.

## 3. Error Handling

| Failure | Behavior |
|---------|----------|
| Model not found | Return `{:error, :model_not_found}` |
| Variable not in model | Return `{:error, :unknown_variable}` |
| Horizon too long for evidence | Return `{:error, :insufficient_evidence}` |
| Math verification fails | Return `{:error, :math_inconsistency}` |
| Replay fingerprint mismatch | Return `{:error, :replay_mismatch}` |

## 4. Determinism Verification

```elixir
# Run 1
{:ok, p1} = PredictionEngine.predict(model_id, variables, horizon, assumptions)

# Run 2 (same inputs, possibly different process)
{:ok, p2} = PredictionEngine.predict(model_id, variables, horizon, assumptions)

assert p1.prediction_id == p2.prediction_id
assert p1.replay_fingerprint == p2.replay_fingerprint
```
