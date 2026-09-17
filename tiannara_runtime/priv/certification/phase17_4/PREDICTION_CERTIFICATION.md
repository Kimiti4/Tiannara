# Phase 17.4 — Prediction Certification

## 1. Certification Checks

Every prediction is certified against these checks:

| Check | Description |
|-------|-------------|
| `model_certified` | Source world model is in `:operational` status |
| `variables_exist` | All target variables exist in the model |
| `equations_solvable` | Equation system is solvable (no singularities) |
| `causal_consistent` | Forecast respects causal graph constraints |
| `horizon_feasible` | Evidence supports the requested horizon |
| `confidence_valid` | ConfidenceEstimate scores are in [0.0, 1.0] |
| `uncertainty_valid` | UncertaintyDistribution is well-formed |
| `replay_deterministic` | Fingerprint matches re-execution |
| `math_verified` | Forecast is consistent with Mathematics Substrate |

## 2. Certificate

```elixir
%PredictionCertificate{
  certificate_id: "pc_...",      # SHA-256 prefix
  prediction_id: "pr_...",
  checks: [%CertificationCheck{...}],
  overall: :pass | :fail,
  issued_by: :prediction_engine,
  issued_at: "ISO 8601",
  metadata: %{}
}
```

## 3. Integration with ModelCertification

Prediction certification is independent from model certification:
- A model must be certified (:operational) before predictions use it
- A prediction is certified per-forecast, not per-model
- Multiple predictions from the same model each have their own certificate

## 4. Prediction Status Lifecycle

```
requested → generated → confidence_scored → uncertainty_propagated →
fingerprinted → archived → certified → returned
```

After certification, a prediction is immutable.

## 5. Failure Modes

| Failure | Certification Action |
|---------|---------------------|
| Model not operational | Not certified, return error |
| Equation singularity | Return {:error, :singular_equation} |
| Horizon too long | Return {:error, :insufficient_evidence} |
| Math verification fails | Return {:error, :math_inconsistency} |
| Replay mismatch | Return {:error, :replay_mismatch} |

## 6. Certification Flow

```elixir
def certify_prediction(prediction) do
  checks = [
    model_certified(prediction),
    variables_exist(prediction),
    equations_solvable(prediction),
    causal_consistent(prediction),
    horizon_feasible(prediction),
    confidence_valid(prediction),
    uncertainty_valid(prediction),
    replay_deterministic(prediction),
    math_verified(prediction)
  ]

  overall = if Enum.all?(checks, &(&1.status == :pass)), do: :pass, else: :fail

  PredictionCertificate.new(
    prediction_id: prediction.prediction_id,
    checks: checks,
    overall: overall,
    issued_by: :prediction_engine
  )
end
```
