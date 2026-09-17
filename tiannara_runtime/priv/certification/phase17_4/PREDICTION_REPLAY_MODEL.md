# Phase 17.4 — Prediction Replay Model

## 1. Determinism Contract

A prediction is replayable iff:

```
identical(prediction_inputs) ⇒ identical(prediction_output)
```

Identical means byte-identical SHA-256 replay fingerprint.

## 2. Replay Fingerprint

The replay fingerprint covers:

```
fingerprint = SHA-256(canonicalize(%Prediction{
  world_model_id, model_fingerprint, target_variables,
  horizon, assumptions, confidence, uncertainty, forecast
}))
```

Prefix: `fp_`

## 3. Replay Protocol

```elixir
# First execution
{:ok, prediction} = PredictionEngine.predict(model_id, vars, :short_term, [])

# Re-execution (same or different process, same inputs)
{:ok, replay} = PredictionEngine.predict(model_id, vars, :short_term, [])

# Verification
assert prediction.replay_fingerprint == replay.replay_fingerprint
```

## 4. Sources of Determinism

| Source | Guarantee |
|--------|-----------|
| World model loading | ModelRegistry.get_model returns identical struct |
| Equation solving | Deterministic ODE/equation solver (no float-optimized reordering) |
| Variable ordering | Sorted by variable_id (canonical) |
| Random sampling | Seeded PRNG: seed = SHA-256(model_fingerprint ++ horizon) |
| Uncertainty propagation | Closed-form formulas only (no Monte Carlo) |
| Confidence computation | Deterministic formula over immutable metrics |
| Fingerprint computation | SHA-256 over canonical JSON |

## 5. Verifier

`PredictionReplay.verify/2`:

```elixir
@spec verify(String.t(), String.t()) :: {:ok, %{verified: boolean(), mismatches: [String.t()]}}
```

Compares a stored prediction fingerprint against a fresh computation.

## 6. Replay Archaeology

Every replay verification is recorded:

```elixir
PredictionArchaeology.record_replay(
  prediction_id,
  original_fingerprint,
  replayed_fingerprint,
  match?,
  metadata
)
```

## 7. Non-Determinism Detection

If a replay fails, the system identifies the source by recursive fingerprinting:

1. Fingerprint the world model load
2. Fingerprint the equation execution
3. Fingerprint the confidence computation
4. Fingerprint the uncertainty computation
5. Compare sub-fingerprints to isolate divergence

## 8. Cross-Process Guarantee

Fingerprints must match across:
- Different BEAM nodes
- Different OTP versions (same Elixir version)
- Different calendar dates (same inputs)

The replay model assumes stable:
- `:crypto.hash/2` SHA-256 output
- `Jason.encode!/1` canonical JSON
- `Enum.sort/1` element ordering
- Float arithmetic determinism
