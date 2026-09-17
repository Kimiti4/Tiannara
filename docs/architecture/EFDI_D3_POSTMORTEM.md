# EFDI D3 — Postmortem

## 1. Purpose

A structured review pairing a decision with its observed outcome — **without** luck/skill
attribution (that is D4 territory). The D3 postmortem keeps the decision and outcome on
independent axes.

## 2. API

- `postmortem(decision, outcome)` → `%{decision_id, observed, attribution: :not_attributed,
  ...}`. Attribution is deliberately frozen to `:not_attributed`.
- `guard_outcome(outcome, decision)` → `{:ok, _} | {:error, :hindsight_contamination}`.
  An outcome observed **at or before** the decision's `created_at` is rejected: the
  decision cannot have used it.
- `decision_outcome(decision, outcome)` → pairs the decision, the guarded outcome,
  the hindsight-independent quality, and the postmortem in one record.

## 3. Resulting-lesson enforcement

The "resulting" lesson (HBR / Munger / Kahneman) is enforced structurally:

1. outcomes arriving **after** decision time are the only ones admissible,
2. decision quality is always recomputed from the decision-time snapshot,
3. the four-class matrix (`classify/2`) makes GOOD decision / BAD outcome a first-class,
   unembarrassing case.