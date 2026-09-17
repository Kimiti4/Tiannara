# EFDI D3 — Decision Research Notes

## 1. What D3 adds over D2

D2 certified forecast quality: probability integrity, calibration, and base-rate composition.
D3 certifies **decision quality**: the choice among forecast-composed alternatives, evaluated
ex-ante. The two are linked but distinct — a well-calibrated forecast can feed a poor
decision, and D3's quality machinery is what makes that distinction observable.

## 2. Design decisions and their rationale

| Decision | Rationale |
|----------|-----------|
| Expected value = Σ p·u, `:unknown` for unknown | Simple, transparent, independently verifiable arithmetic; no fabricated confidence. |
| Snapshot as first-class object | An epistemic freeze is required for ex-post hindsight isolation (V11). |
| Quality from snapshot, never outcome | The "resulting" lesson made structural (V9, V10). |
| Postmortem attribution = `:not_attributed` | D3 does not overclaim what D4 must compute. |
| Recommendation ≠ authorization | Authority stays with `Council`; D3 only proposes (V15). |
| EVPI over the recommended belief | Uses the decision's own best estimate; degenerates to `:unknown` honestly. |
| Research priorities shaped for `ResearchDirector.ingest_priorities/1` | Composes existing infrastructure instead of creating a parallel signal feed (V16). |
| Duplicate alternative ids rejected | Id keyed maps (`expected_values`) require unambiguous identifiers. |

## 3. Open questions (deferred, not solved)

1. **Noise-aware confidence bounds** on EV (deferred `:noise`): the engine computes point
   estimates only.
2. **Counterfactual consequence evaluation** via `World.TemporalWorldEngine.counterfactual_state/2`
   (deferred `:counterfactual`): D3's `world_consequence` adapter returns a bounded note
   instead of simulating.
3. **Automatic verdict attribution** (luck vs. skill): explicitly D4.
4. **Cold-start decision calibration**: no population of executed decisions yet exists to
   calibrate decision quality scores; `evaluate/2` is compositional, not empirically calibrated.

## 4. Evidence budget

- 73 D3 tests (56 unit + 17 integration/adversarial/replay) across the forecasting suite.
- Full forecasting suite: 269 tests, 0 failures (D1=92, D2=104, D3=73).
- Independent verifier V1–V19 in `certification/forecasting/EFDI_D3_independent_verification.py`.