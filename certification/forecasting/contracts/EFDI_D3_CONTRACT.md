# EFDI D3 — Contract

**Gate:** EFDI-D3

## Scope

D3 delivers: Decision Model (`Decision`), Decision Engine, Decision Registry,
Decision Snapshot, Decision Quality, Decision Review / Postmortem, Pre-Mortem,
Value-of-Information, and the Decision adapter boundary (`Forecasting.Adapters.Decision`).

## Required invariants

| Gate | Verifier test | Behaviour |
|------|---------------|-----------|
| V1   | Decision Contract | `Contracts.Decision` has all required fields; `Decision.new/validate` shape enforcement |
| V2   | Alternative Contract | `Contracts.Alternative` fields (`probabilities`, `outcomes`, `utilities`, `reversibility`, `assets_at_risk`); `:unknown` first-class ≠ `0.0` |
| V3   | DecisionRequest Contract | `Contracts.DecisionRequest` fields present; request → decision mapping |
| V4   | Engine Arithmetic | `expected_value` = Σ p·u; `variance` = Σ p(u−EV)²; `stddev` = √variance; formula exact |
| V5   | Unknown Honesty | `:unknown` distributes to EV/variance/risk; never fabricated |
| V6   | Recommendation Selection | max determinate EV; `nil` when none determinate |
| V7   | Decision Immutability / Registry | ETS registry, register/get/count/health; same id → no-op |
| V8   | Version Lineage | `version/2` → v+1, `lineage` prepend; append-only history |
| V9   | Resulting Prevention | decision quality invariant to observed outcome |
| V10  | Outcome Separation | `classify/2` keeps decision/outcome axes independent; all four combos |
| V11  | Hindsight Isolation | `guard_outcome/2` rejects pre-decision outcomes; `consistent?/2` detects rewriting |
| V12  | Decision Snapshot | `capture/1` freezes decision-time info; `consistent?/2` proofs |
| V13  | Pre-Mortem | `run/run_all/posture` → `:proceed | {:require_info, _} | :block`; irreversible/unknown surfaces risk |
| V14  | Value-of-Information | EVPI/sensitivity/priority emission; informational, not permissive |
| V15  | Authorization Boundary | recommendation ≠ authorization; adapter defers to `Council.authorize/3` |
| V16  | Research Boundary | `to_research_priorities` is a research feed, never permission |
| V17  | CIS Boundary | `check_cis/1` gate runs; immune authority persists |
| V18  | Replay | identical decision-time inputs ⇒ identical EV/risk/quality |
| V19  | Adversarial | hindsight-smuggling, malformed inputs, duplicate ids rejected |

## Not modified

D1 signals/quality/provenance; D2 forecast/calibration/base-rate contracts and modules;
CIS, Council, Executive, AEO, WorldModel internals — untouched (only wired at the adapter boundary).

## Additive contract evolution (D2 → D3)

D3 adds new contract modules (`Alternative`, `DecisionRequest`, `Decision`,
`DecisionOutcome`) to `contracts.ex`. D2 structs (`Forecast`, `ForecastRequest`,
`BaseRate`) are unchanged in position and semantics — the documented additive
exception established by D1→D2 continues.