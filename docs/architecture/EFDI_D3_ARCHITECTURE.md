# EFDI D3 — Decision Intelligence Architecture

**Phase:** D3 — Decision Intelligence (after certified D1 Signal Intelligence and D2 Forecast + Calibration).

## 1. Mission

D3 delivers the decision layer of the EFDI epistemic pipeline:

```
observation → signal → evidence → hypothesis → forecast → outcome → calibration → confidence
                                          └──────────────► decision → action → outcome
```

A D3 decision is an **immutable, ex-ante-evaluable, hindsight-isolated choice** over
forecast-composed alternatives. D3 judges a decision by the information and uncertainty
available **when it was made** — never by its outcome.

## 2. Scope boundary

| Concern | D3 responsibility |
|---------|-------------------|
| Alternative formulation & expected value | Yes |
| Decision-time snapshot (epistemic freeze) | Yes |
| Ex-ante decision quality | Yes |
| Risk evaluation (variance / reversibility) | Yes |
| Pre-mortem & postmortem review | Yes (review, not attribution) |
| Value-of-information → research priorities | Yes |
| Recommendation | Yes (a recommendation, nothing more) |
| **Authorization / permission** | **No** — `Council.authorize/3` retains sole authority |
| Confidence / legitimacy | **No** — Council property |
| Execution | **No** — `AEO` / `Executive.Command` at the adapter |
| Internet-level security / monitoring | **No** — CIS keeps authority (V17) |
| Luck/skill attribution | **No** — D4 territory; D3 postmortem is `:not_attributed` |
| World-state representation | **No** — Unified Reality Graph remains canonical |

## 3. The resulting lesson, operationalized

The central invariant: **fit is evaluated with ex-ante information only.** Concretely:

- `DecisionSnapshot.capture/1` freezes decision-time distributions.
- `DecisionQuality` is a pure function of the snapshot (`hindsight_independent: true`).
- `DecisionReview.guard_outcome/2` rejects any outcome observed *before* the decision
  as `:hindsight_contamination`.
- `DecisionSnapshot.consistent?/2` proves a decision has not been rewritten with hindsight.

The **triple distinction** is preserved: FORECAST QUALITY ≠ DECISION QUALITY ≠ OUTCOME QUALITY.
All four decision×outcome combinations are representable via `DecisionQuality.classify/2`.

## 4. Architecture

```
         request ──► DecisionEngine.decide/1 ──► Decision (Contract)
                        │  EV = Σ p·u                    │
                        │  risk = variance/stddev        │ capture
                        ▼                                ▼
        +----------------------------+        +-------------------------+
        │ Decision.new / validate    │        │ DecisionSnapshot         │
        │ version (immutable append) │        │ (decision-time freeze)   │
        +--------------+-------------+        +------------+-------------+
                       │                                 │
                       v                                 v
        +----------------------------+        +-------------------------+
        │ DecisionRegistry (ETS)     │        │ DecisionQuality (ex-ante)│
        │ register/get/count/health  │        │ classify/consistent?     │
        +--------------+-------------+        +------------+-------------+
                       │                                 │
                       v                                 v
        +----------------------------+        +-------------------------+
        │ PreMortem.run_all/posture  │        │ ValueOfInformation        │
        │ (proceed/require_info/     │        │ EVPI · sensitivity ·      │
        │  block)                    │        │ to_research_priorities   │
        +--------------+-------------+        +------------+-------------+
                       │                                 │
                       ▼                                 ▼
        +---------------------------------------------------------------+
        │ Adapters.DecisionImpl  — boundary wiring                      │
        │   authorize/1      → Council.authorize/3  (authority gate)    │
        │   to_command/1     → Executive.Command   (EXTEND boundary)    │
        │   submit_intent/1  → AEO.submit_to_runtime                    │
        │   check_cis/1      → CIS risk-score gate (authority persists) │
        │   request_research → ValueOfInformation → ResearchDirector    │
        │   world_consequence→ honest boundary (notes, never fabricates)│
        +---------------------------------------------------------------+
                       │
                       ▼
        postmortem ──► DecisionReview (decision_outcome/guard_outcome)
```

## 5. Reuse vs new (no parallel system)

| Capability | Source | D3 usage |
|------------|--------|----------|
| ID generation | `Tiannara.Executive.Types.new_id/0` | decision ids |
| Event lineage | `Tiannara.Executive.Event/EventStore` | `efdi.decision.registered` (best-effort) |
| Authorization | `Council.authorize/3`, `Council.Authorization` | adapter gate; never bypassed |
| Command model | `Executive.Command` | `to_command/1` (extend at boundary) |
| Execution intent | `AEO.translate_intent/1` | adapter |
| Immune authority | `CIS.PathogenDetector` etc. | `check_cis/1` risk score |
| Opportunity-cost framing | `Discovery.Adaptive.OpportunityCostEstimator` | mirrored in `ValueOfInformation` |
| Counterfactual world state | `World.TemporalWorldEngine.counterfactual_state/2` | deferred `:counterfactual` |
| Hindsight ledger | `Sentinel.Verification` / `Sentinel.Governance` | verification gate (V18) |

No parallel decision ontology, no delegate "sub-Council", no separate authorization store.
`Adapters.DecisionImpl` is the single honest boundary.

## 6. Files

- `lib/tiannara/forecasting/decision.ex` — constructor, validation, versioning
- `lib/tiannara/forecasting/decision_engine.ex` — EV / variance / risk / recommendation
- `lib/tiannara/forecasting/decision_registry.ex` — ETS registry (gen_server)
- `lib/tiannara/forecasting/decision_snapshot.ex` — decision-time freeze + consistency proof
- `lib/tiannara/forecasting/decision_quality.ex` — ex-ante quality (6 components)
- `lib/tiannara/forecasting/decision_review.ex` — postmortem + hindsight guards
- `lib/tiannara/forecasting/pre_mortem.ex` — failure-mode posture
- `lib/tiannara/forecasting/value_of_information.ex` — EVPI / sensitivity / research bridge
- `lib/tiannara/forecasting/adapters/decision.ex` — behaviour + `DecisionImpl`
- `lib/tiannara/forecasting/contracts.ex` — `Alternative`, `DecisionRequest`, `Decision`, `DecisionOutcome`
- `lib/tiannara/forecasting/efdi.ex` — facade (`decide/1`, `register_decision/1`, `get_decision/1`)

See also: `EFDI_D3_DECISION_MODEL.md`, `EFDI_D3_DECISION_SNAPSHOT.md`,
`EFDI_D3_RISK_MODEL.md`, `EFDI_D3_VALUE_OF_INFORMATION.md`, `EFDI_D3_DECISION_QUALITY.md`,
`EFDI_D3_PREMORTEM.md`, `EFDI_D3_POSTMORTEM.md`, `EFDI_D3_INVARIANTS.md`,
`EFDI_D3_INTEGRATION.md`, `EFDI_D3_ARCHITECTURE_RECONNAISSANCE.md`.