# Phase 17.5 — Counterfactual Certification

## 1. Certification Checks

| Check | Description |
|-------|-------------|
| `parent_certified` | Parent world model is in :operational status |
| `intervention_valid` | Intervention targets exist and are valid |
| `divergence_deterministic` | Divergence point is fully specified |
| `causal_consistent` | Timeline respects causal constraints |
| `math_verified` | Mathematics Substrate confirms consistency |
| `replay_deterministic` | Fingerprint matches re-execution |
| `archaeology_complete` | Full lineage recorded |
| `uncertainty_propagated` | Uncertainty is quantified |

## 2. Certificate

```elixir
%CounterfactualCertificate{
  certificate_id: "cc_...",
  counterfactual_id: "cf_...",
  checks: [%CertificationCheck{...}],
  overall: :pass | :fail,
  issued_by: :counterfactual_engine,
  issued_at: "ISO 8601",
  metadata: %{}
}
```

## 3. Certification Flow

```elixir
def certify_counterfactual(counterfactual) do
  checks = [
    parent_certified(counterfactual),
    intervention_valid(counterfactual),
    divergence_deterministic(counterfactual),
    causal_consistent(counterfactual),
    math_verified(counterfactual),
    replay_deterministic(counterfactual),
    archaeology_complete(counterfactual),
    uncertainty_propagated(counterfactual)
  ]

  overall = if Enum.all?(checks, &(&1.status == :pass)), do: :pass, else: :fail

  %CounterfactualCertificate{
    counterfactual_id: counterfactual.counterfactual_id,
    checks: checks,
    overall: overall,
    issued_by: :counterfactual_engine
  }
end
```

## 4. Failure Modes

| Failure | Certification Action |
|---------|---------------------|
| Parent not operational | Not certified, return error |
| Invalid intervention target | Return {:error, :invalid_target} |
| Non-deterministic divergence | Return {:error, :non_deterministic} |
| Causal inconsistency | Return {:error, :causal_inconsistency} |
| Math verification fails | Return {:error, :math_inconsistency} |
| Replay mismatch | Return {:error, :replay_mismatch} |
| Incomplete archaeology | Return {:error, :incomplete_archaeology} |

## 5. Counterfactual Lifecycle

```
requested → intervention_applied → branch_generated →
timeline_constructed → validated → fingerprinted →
archived → certified → returned
```
