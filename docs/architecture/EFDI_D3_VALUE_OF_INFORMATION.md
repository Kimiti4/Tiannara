# EFDI D3 — Value of Information

## 1. EVPI

Expected Value of Perfect Information, computed from the decision-time belief:

```
EVPI = Σ_o p(o) · max_a u_a(o)  −  max_a EV(a)
```
- The belief is the recommended alternative's distribution (the decision's best estimate).
- The first term assumes perfect knowledge (optimal action per outcome);
  the second term is the current best expected value.
- Returns `:unknown` when the belief is `:unknown` or no determinate EV exists.

Also `expected_value_of_information(uncertainty, impact, feasibility)` mirrors
`Discovery.Adaptive.OpportunityCostEstimator`: `uncertainty × impact × feasibility`.

## 2. Decision sensitivity

`decision_sensitivity(alts)` = best − second-best determinate EV (0.0 for a single determinate
alternative, `:unknown` when nothing is determinate). A small gap means additional information
could flip the choice; a large gap means information is unlikely to matter.

`information_gap/1` marks alternatives with
`:high_decision_sensitivity` (gap > 0.5) or `:medium_decision_sensitivity` otherwise.

## 3. Research bridge

`to_research_priorities(decision, sensitivity_threshold:)` produces
`ResearchDirector.ingest_priorities`-shaped items:

```
%{id, level: :immediate | :urgent | :scheduled | :background,
  score, source_type: :information_value, source_id, domain,
  signal, title, rationale, recommended_action, created_at, expires_at}
```

The bridge is honest: priorities are emitted only above the threshold, and they request
**information**, never grant permission to act (V16).