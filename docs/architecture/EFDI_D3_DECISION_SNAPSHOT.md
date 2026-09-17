# EFDI D3 — Decision Snapshot

## 1. Purpose

`DecisionSnapshot.capture(decision)` freezes **exactly what was known at decision time**:
the alternatives with their decision-time probability distributions and utilities, the
question, forecast references, and a record of which positions were `:unknown`.

A snapshot is the fixed basis against which quality and review are evaluated, so
**a decision is never judged with hindsight.**

## 2. Contents

```
%DecisionSnapshot{
  decision_id, question,
  alternatives: [%{id, outcomes, probabilities, utilities, reversibility}, ...],
  forecast_refs,
  unknowns: [{alternative_id, :unknown_distribution | index}, ...],
  captured_at
}
```
- Alternatives are stored as plain maps (frozen), not live structs.
- `unknowns` records information sufficiency *at capture time* — measurable later without hindsight.

## 3. Consistency proof

`consistent?(snapshot, decision)` returns true when the decision's decision-time data still
matches the snapshot (same alternative ids; identical probabilities and utilities). It is the
defense against hindsight smuggling: if probabilities were rewritten *after the fact* to the
"known" outcome, consistency fails.

`DecisionQuality.consistent_with_snapshot?/2` exposes the same proof on the quality path.

## 4. Constitutional rules

1. A snapshot is taken at decision time and never mutated (V11).
2. Decision quality is a function of the snapshot, never of the outcome (V9).
3. Rewriting decision-time data post hoc is detectable and invalidates ex-post evaluation (V10).