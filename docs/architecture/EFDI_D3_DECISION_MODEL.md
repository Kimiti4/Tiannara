# EFDI D3 — Decision Model

## 1. What a decision is

A `Contracts.Decision` is an immutable record of a choice made at a specific time:

- `question` — the decision question.
- `alternatives` — mutually exclusive `Alternative` structs (probabilities, outcomes, utilities,
  reversibility, assets at risk).
- `recommended_alternative_id` — the engine's recommendation (determinate max-EV), **never** an authorization.
- `selected_alternative_id` — the (eventual) selected alternative, set outside the D3 honesty core.
- `expected_values` / `risk_evaluation` — decision-time arithmetic, one entry per alternative.
- `created_at`, `decision_version`, `lineage`, `forecast_refs`, `context`, `decisioner`.

## 2. Alternative contract

```
%Alternative{
  id, label,
  probabilities: [p1, p2, ...] | :unknown,
  outcomes:      [o1, o2, ...],
  utilities:     [u1, u2, ...],
  risk, reversibility: :reversible | :partially_reversible | :irreversible,
  assets_at_risk
}
```
- Probabilities and utilities are **aligned by index** with outcomes.
- `:unknown` is a first-class value and is distinct from `0.0` (never silently dropped).
- `:`unknown` survives `Decision.validate/1` — validation checks shape, not knowledge.

## 3. Construction and validation (Decision module)

- `Decision.new/1` — pure constructor; assigns `id`, `decision_version: 1`, `lineage: []`.
- `Decision.validate/1` — rejects `:missing_question`, `:missing_alternatives`,
  `:invalid_alternative` (mismatched shapes), `:duplicate_alternative_ids`.
- `Decision.version/2` — produces v+1 with `lineage: [previous_id | lineage]`; history is append-only.
- `Decision.do_nothing/0` — deterministic no-op baseline (`[no_change]`, `p=[1.0]`, `u=[0]`,
  `reversibility=:reversible`). Every decision compares against inaction.

## 4. Engine arithmetic (DecisionEngine)

- `expected_value(a) = Σ p_i · u_i`, `:unknown` when probabilities are not determinate.
- `variance(a) = Σ p_i · (u_i − EV)²`, `:unknown` when EV is `:unknown`.
- `stddev = √variance`.
- `risk_evaluation(a) = %{expected_value, variance, stddev, risk_score}` where
  `risk_score` blends coefficient-of-variation with reversibility in `[0,1]`.
- `select_recommendation/1` — max determinate EV; `nil` when nothing is determinate.
- `decide/1` → `{:ok, Decision}` | `{:error, reason}`.

## 5. Honesty rules

1. The engine never fabricates an EV for `:unknown` distributions.
2. A recommendation is a recommendation, not an authorization (V15).
3. Expected values are recomputable and independently verifiable.
4. A decision, once built, is never mutated in place; new information ⇒ new version.