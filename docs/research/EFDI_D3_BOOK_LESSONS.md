# EFDI D3 — Book Lessons

## 1. Sources

D3 operationalizes the decision-quality literature that D1/D2 underlying forecasting lessons
did not cover: the boundary between good decisions and good outcomes.

## 2. The "resulting" lesson (HBR, "The Difference Between Good Decisions and Good Outcomes")

> "Process, not outcome, is the appropriate measure of a decision."

D3 makes this structural, not advisory:
- `DecisionQuality` is a pure function of the decision-time snapshot (`hindsight_independent: true`).
- The outcome is never an input to quality.
- `classify/2` keeps decision and outcome on independent axes — all four combinations exist,
  so "good decision, bad outcome" needs no special pleading.

## 3. Kahneman / Tversky — evaluation of decisions

- **Bracket (framing) discipline:** alternatives carry explicit probabilities and utilities;
  `:unknown` is a first-class value so uncertainty is never laundered into a number.
- **Loss framing / status quo:** `Decision.do_nothing/0` is a mandatory comparison baseline;
  the no-op alternative carries a deterministic outcome, so forgoing a gamble is itself evaluated.
- **Planning fallacy:** the pre-mortem (`PreMortem.posture/2`) forces the "assume it failed"
  mode before authorization.

## 4. Munger — decision hygiene

- Reversibility is recorded per alternative at decision time (`:reversible /
  :partially_reversible / :irreversible`) and enters both `risk_score` and pre-mortem likelihood.
- Irreversible commitments with `:unknown` distributions must surface
  `{:require_info, _} | :block` rather than silent `:proceed` (V13).

## 5. Value-of-information (Howard / decision analysis)

- EVPI and decision-sensitivity convert uncertainty into a research signal.
- The output is a **research priority**, never a permission-to-act grant (V16).

## 6. Attribution discipline

Outcome postmortems freeze attribution to `:not_attributed`. Luck/skill decomposition is
explicitly deferred to D4 — D3 will not overclaim what it does not compute.