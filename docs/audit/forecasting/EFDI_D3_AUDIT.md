# EFDI D3 — Audit

**Gate:** EFDI-D3 · **Verdict: CERTIFIED_BOUNDED** · Audit date: 2026-09-02

## 1. Claim

D3 delivers decision intelligence (Decision model, engine, registry, snapshot, quality,
pre-mortem, postmortem, value-of-information) that is evaluated with **decision-time
information only** and composes existing authority without replacing any canonical system.

## 2. Audit checks

| # | Check | Result |
|---|-------|--------|
| A-1 | Resulting-lesson invariant: quality is a pure function of the decision-time snapshot | PASS — `DecisionQuality` evaluates `snapshot` inputs; `hindsight_independent: true`; verified by `decision_quality_test` and `d3_replay_test` |
| A-2 | Outcome separation: four decision×outcome combinations representable | PASS — `classify/2`; classification freedom is a *feature* (bad/good outcome does not rewrite the decision axis) |
| A-3 | Hindsight isolation: pre-decision outcomes rejected; post-hoc rewriting detected | PASS — `guard_outcome/2` → `:hindsight_contamination`; `consistent?/2` detects probability rewriting (adversarial tests) |
| A-4 | Recommendation ≠ authorization | PASS — engine returns recommendation; `Adapters.DecisionImpl.authorize/1` defers to `Council`; `:authorization_unavailable` when Council down (V15) |
| A-5 | CIS / immune authority persists | PASS — `check_cis/1` risk-gate; no D3 override path (V17) |
| A-6 | Research boundaries | PASS — `to_research_priorities/2` emits information-gathering priorities, never permissions (V16) |
| A-7 | No parallel system | PASS — reuses `Council`, `Executive.Command`, `AEO`, `OpportunityCostEstimator` pattern; no shadow authorization/probability store |
| A-8 | No fabrication | PASS — `:unknown` distributions propagate; no world-state fabrication (`world_consequence` honest boundary) |
| A-9 | Immutability & append-only versioning | PASS — registry re-register no-op; `version/2` lineage prepend |
| A-10 | D1/D2 integrity | PASS — contracts untouched (additive-only); suite = 269 tests / 0 failures (92 + 104 + 73) |

## 3. Known deviations / disclaimers (all declared, none hiding)

- **Deferred capabilities declared, not silent:** `:counterfactual`, `:noise`, `:memory`
  (status `deferred: [...]`). Certification does not claim them.
- **No luck/skill attribution:** postmortem attribution frozen at `:not_attributed`
  (D4 territory). This is a deliberate boundary, stated in the authorization doc.
- **Decision-quality scores are compositional, not empirically calibrated** (no executed
  decision population exists yet to calibrate against) — noted in `EFDI_D3_DECISION_RESEARCH.md`.
- **Float arithmetic:** EV/variance use IEEE float arithmetic; tests assert with
  `assert_in_delta`; the verifier's replay gate asserts equality on identical inputs
  which is deterministic on the same VM.

## 4. Evidence

- Verifier: `certification/forecasting/verifiers/EFDI_D3_independent_verification.py` →
  `EFDI_D3_independent_verification_output.json` (JSON). All 19 gates + live regression PASS.
- Evidence ledger: `certification/forecasting/EFDI_D3_EVIDENCE.json`.
- Test matrix: `certification/forecasting/EFDI_D3_TEST_MATRIX.md`.

## 5. Conclusion

D3 is **CERTIFIED_BOUNDED**: the certified surface is exactly what the contract/authorization
state; everything outside that surface is either declared-deferred or delegated to existing
authority (Council, CIS). D4 must not begin within this gate's scope.