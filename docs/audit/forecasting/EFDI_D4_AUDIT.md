# EFDI D4 — Audit

**Gate:** EFDI-D4 · **Verdict: D4_CERTIFIED_BOUNDED** · Audit date: 2026-09-02

## 1. Claim

D4 delivers counterfactual / attribution analysis as an **adapter** over the canonical
substrate: a first-class status ontology, explicit intervention spec, bounded
alternative-history bundles, boundary-guarded luck/skill attribution (NOT_ATTRIBUTED
default), survivorship / selection with denominator registry, non-causal regression-to-mean,
and a D4→D3 temporal firewall. Genuinely-NEW surface is limited; no new causal engine,
no execution surface.

## 2. Audit checks

| # | Check | Result |
|---|-------|--------|
| A-1 | Status ontology first-class, never boolean-collapsed | PASS — `UNKNOWN`/`UNDERDETERMINED`/`INVALID` distinct; `known?/1` returns false without hiding which state (counterfactual_test V20) |
| A-2 | OBSERVED only via D1 path | PASS — `enforce_observability_boundary/1` + `{:error, :observed_not_assignable_by_d4}` (V21) |
| A-3 | Counterfactual = labeled analytical record, never a fact | PASS — no merge operation; branch/2 by content hash; never promoted to OBSERVED (V22, V25) |
| A-4 | Intervention explicitness (OBSERVE ≠ SET) | PASS — `InterventionSpec` kinds incl. observe_only/do_nothing/defer; D4 record from OBSERVE_ONLY cannot claim intervention effect (V23) |
| A-5 | Bundles bounded + always include no-action | PASS — max_alternatives default 8; deterministic exclusion records (V24) |
| A-6 | Attribution boundary (not single-outcome) | PASS — default `:not_attributed`; repeated-outcome thresholds; no BAD/GOOD outcome→decision inference (V26, V28) |
| A-7 | Threshold provenance, no hidden constants | PASS — `thresholds_provenance` records n_min/skill_margin/consistency gates (V27) |
| A-8 | Survivorship / denominator honesty | PASS — known/partial/unknown; `UNKNOWN_SELECTION_EFFECT`; `select_from` → `{:error, :denominator_unknown}` rather than silent generalization (V29, V30) |
| A-9 | RTM non-causal by construction | PASS — schema has NO causal-claim field; `causal_claim_free?/1` (V31, V32) |
| A-10 | D4→D3 temporal firewall first-class | PASS — `firewall_intact?`, snapshot_consistent?, hindsight contamination, d3_writes rejection (V33, V34) |
| A-11 | Adapter over substrate, not a new engine | PASS — classification matrix REUSE/ADAPTER; no new causal/probability/authorization system; D5/D6 deferred (V35) |
| A-12 | D1/D2/D3 integrity preserved | PASS — 269 regression + 31 D4 = 300 tests / 0 failures; contracts additive-only |

## 3. Known deviations / disclaimers (all declared, none hiding)

- **No cross-Mix-project coupling:** D4 composes the canonical substrate via
  equivalent main-app composition (`encode/decode` do not depend on `tiannara_runtime`);
  non-goal respected (no `tiannara_runtime` dep).
- **Attribution is bounded, not empirically calibrated:** thresholds are configurable
  with provenance; no executed large population yet to calibrate against should a future
  stage want it — not claimed.
- **RTM extremity uses a z-score proxy; causal reversion is never claimed.**
- **Float arithmetic:** IEEE floats; tests use exact equality only for deterministic
  same-VM comparisons, otherwise `assert_in_delta`-style checks.

## 4. Evidence

- Verifier: `certification/forecasting/verifiers/EFDI_D4_independent_verification.py` →
  `EFDI_D4_independent_verification_output.json` (JSON). All 16 gates (V20–V35) + live regression PASS.
- Evidence ledger: `certification/forecasting/EFDI_D4_EVIDENCE.json`.
- Test matrix: `certification/forecasting/EFDI_D4_TEST_MATRIX.md`.

## 5. Conclusion

D4 is **D4_CERTIFIED_BOUNDED**: the certified surface is exactly what the contract /
authorization state; everything outside that surface is either declared-deferred
(D5 noise, D6 memory) or delegated to existing authority (Council, CIS, AEO). Implementation
STOPS here per the D4 mission; D5/D6 are not begun.
