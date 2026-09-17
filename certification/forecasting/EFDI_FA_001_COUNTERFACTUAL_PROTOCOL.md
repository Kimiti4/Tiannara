# EFDI-FA-001 — Counterfactual Protocol

**artifact:** `EFDI_FA_001_COUNTERFACTUAL_PROTOCOL.md`
**status:** FROZEN 2026-09-13
**governing contract:** `EFDI_FA_001_AUDIT_CONTRACT`
**schema:** `EFDI_FA_001_FORECAST_SCHEMA.yaml` (postmortem, alternative_outcomes)

---

## 1. Purpose

Make certain that a good outcome is never confused with a good decision, and a
good forecast never confused with good luck. Every significant forecast gets a
counterfactual pass BEFORE any capability conclusion is drawn.

---

## 2. Decision vs outcome (resulting, efdi.md §28) — MANDATORY

Provide pairs where:

- **Decision A → good outcome** but Decision A had POOR expected value
  (e.g., a lottery ticket that won).
- **Decision B → bad outcome** but Decision B had HIGH expected value
  (e.g., a +EV bet that lost).

Tiannara must judge DECISION QUALITY, not outcome quality. A system that
retroactively praises the winning lottery ticket fails the test.

Sample rule: at least 8 such pairs per calibration batch, mixed with honest
pairs where outcome and value agree.

---

## 3. Luck vs skill (efdi.md §29)

- Generate 10,000 simulated environments; identical strategies; some succeed
  by skill, some by luck, some fail DESPITE being optimal.
- Provide only the possessed-to-them evidence and outcomes stream as a
  synthetic problem; ask for `P(skill | observed outcomes)`.
- Score the estimated probability of skill against the ground-truth mixing
  proportion. The audit label "skill=success" is prohibited inside Tiannara's
  own reasoning record for this protocol.

---

## 4. Survivorship (efdi.md §30)

- Generate 10,000 strategies, run them, SELECT the top 10 winners and present
  ONLY the winners.
- Ask "What caused these strategies to succeed?"
- Reveal the full population. Expect a REVISED conclusion that attributes part
  of the observed success to selection.
- A system that fails to revise is scored as s survivorship failure.

---

## 5. Regression to the mean (efdi.md §31)

- Synthesize extreme performance followed by normal performance.
- Check the forecast for the next period does NOT blindly project the extreme
  state when the generator is mean-reverting. (Only when ground truth supports
  reversion; the generator parameters must be disclosed to the scorer but NOT
  to the forecaster until the forecast is frozen.)

---

## 6. Alternative-history (efdi.md §32)

- After every MAJOR live or synthetic forecast: produce
  `actual outcome + plausible alternatives`.
- Ask: "Would the conclusion still hold under plausible alternative outcomes?"
- This distinguishes principle-learning from history-memorization. Recorded in
  the postmortem block; at least 20% of series forecasts require this pass.

---

## 7. Hindsight / information-cutoff (efdi.md §33)

- Two-stage tests (T0-only evidence vs T0+T1 evidence) with TWO forecasts; the
  T0 forecast must be untouched by T1. (Complements DATA_CUTOFF_PROTOCOL §5.)

---

## 8. Model monoculture (efdi.md §25)

- Synthetic 10-model panels where 8 share one hidden assumption and 2 are
  independent; the panel AGREES either way.
- The system must distinguish APPARENT agreement from INDEPENDENT agreement
  (measure redundancy via covariance of errors, not via output equality).
- Monoculture detection output: an `independence_strength` value per panel;
  scored against the known panel structure.

---

## 9. Spurious correlation (efdi.md §21)

- `X ↔ Y` strongly correlated with no causal link; then `Z → X, Z → Y`.
- The system must avoid asserting `X → Y`; it should flag the confounder.
- Outcome scored by causal-statement correctness, NOT by correlation magnitude.

---

## 10. Outputs

- `EFDI_FA_001_COUNTERFACTUAL_REPORT.md`: decision/outcome table with scoring,
  luck-vs-skill estimates vs truth, survivorship pre/post-reveal conclusions,
  regression-to-mean trace, alternative-history pass coverage, monoculture
  independence_strength, spurious-correlation flag rate.
- Each major live forecast's postmortem (FORECAST_SCHEMA) contains its
  alternative-history write-up; the report aggregates them.