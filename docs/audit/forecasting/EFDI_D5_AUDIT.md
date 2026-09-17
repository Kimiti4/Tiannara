# EFDI D5 — Audit

**Gate:** EFDI-D5 · **Verdict: D5_CERTIFIED_BOUNDED** · Audit date: 2026-09-03

## 1. Claim

D5 delivers noise, judgment-variability, robustness & sensitivity intelligence as an
analytical layer over the certified D1–D4 substrate. It composes canonical math only,
adds no execution surface, and enforces epistemic honesty: UNKNOWN on insufficient
coverage, no bias from insufficient observations, no robustness without bounded
perturbation coverage, minority preservation before aggregation, and no noise inferred
from disagreement alone. Genuinely-NEW surface is the D5 module family + facade; no new
statistics/probability/calibration/causal/World Model/authorization/execution/memory system.

## 2. Audit checks

| # | Check | Result |
|---|-------|--------|
| A-1 | Contract integrity / authorization binding | PASS — contract v1.0.0 persisted; authorization executed (`PHASE_3_AUTHORIZED`); §15.1 re-verified against live D2 before modification (V36) |
| A-2 | Canonical reuse, no duplicate math engine | PASS — `bias_separation`/`dispersion`/`consensus`/KL/entropy route through `Tiannara.Numerics` / `InformationTheory` (V37) |
| A-3 | Immutable preservation of substrate | PASS — D5 reads substrate; only sanctioned append-only D2 `:disagreement` activation path used (V38, V58) |
| A-4 | Repetition tiers; n=1 never supports claims | PASS — TIER-0/1/2; `classifiable?` requires ≥32; n=1 → `no_estimate_permitted` (V39) |
| A-5 | Evaluator identifiability; disagreement ≠ error | PASS — `isolate`/`identify_source` only attribute an isolated source; agreement ≠ correctness (V40, adversarial) |
| A-6 | Model consensus lineage | PASS — correlated/unknown-lineage → `effective_independent_count: :unknown`; no numeric consensus claim (V41) |
| A-7 | Plan completeness; LATE_ADDED barred | PASS — `register_late_added` can never classify, even completed (V42) |
| A-8 | Materiality recomputation | PASS — flips, threshold crossings, ε = 10% of range; small movement not material (V43) |
| A-9 | Robustness requires evidence + coverage manifest | PASS — any declared dim unexecuted/invalid/below-min → UNKNOWN; execution spoofing (executed:true, runs:0) → UNKNOWN (V44, adversarial) |
| A-10 | UNKNOWN truth-table; no coercion to boolean | PASS — `coverage_scoped_unknown`, `no_estimate_permitted`, insufficient-sample UNKNOWN enforced (V45) |
| A-11 | Confidence / robustness separate axes | PASS — `axes/2` never merges (`merged:false`) (V46) |
| A-12 | Bias vs noise separation | PASS — bias needs a directional reference + classifiable n; no direction emitted on insufficient samples (V47, adversarial) |
| A-13 | Regime mismatch rejection | PASS — `aggregable?` → `{:error, :regime_mismatch}` on sensitive-dimension mismatch (V48) |
| A-14 | Temporal firewall / computed labels | PASS — temporal label computed not self-declared; POST_OUTCOME cannot write decision-time fields (V49) |
| A-15 | D2 integration (conditional §15.1 clause) | PASS — live-verified `:disagreement` at contracts.ex:73; activation via `Forecast.version/2 → register/1` (V50) |
| A-16 | D3 annotation-only | PASS — D5 annotates/adjudges recommendations; does not itself declare D3 robustness (V51) |
| A-17 | D4 ontology integrity | PASS — D5 never constructs/promotes a record to OBSERVED; holds read-only handles (V52) |
| A-18 | Budget enforcement | PASS — over-budget → deterministic rejection (`:too_many_models`: etc.); partial coverage downgrades to coverage-scoped UNKNOWN (V53) |
| A-19 | Replay determinism | PASS — pure deterministic functions + content-addressed hashes exercised by replay suite (V54) |
| A-20 | Anti laundering / selective perturbation | PASS — `threshold_set_hash` cites provenance; late-added perturbation cannot classify (V55) |
| A-21 | Minority preservation before aggregation | PASS — individuals recoverable via `input_hashes`; minority counted, never suppressed (V56) |
| A-22 | Provenance chain completeness | PASS — contract_version + threshold_set_hash + content_hash + n mandatory (V57) |
| A-23 | No execution / authorization bypass | PASS — strictly analytical facade; Council/AEO separation; D6 untouched (V59) |
| A-24 | D1–D4 integrity preserved | PASS — 300 regression + 54 D5 = 354 tests / 0 failures |

## 3. Known deviations / disclaimers (all declared, none hiding)

- **No cross-Mix-project coupling:** D5 composes canonical math via same-app
  `Tiannara.Numerics` / `InformationTheory`; non-goal (no `tiannara_runtime` dep).
- **UNSTABLE inference:** `Robustness` flags UNSTABLE only when repetition tier is
  classifiable (≥32) and the plan declares the identity/order independence dimension
  (evidence_order/sampling). It is a cautionary class, never a robustness claim; further
  empirical calibration is out of scope and not claimed.
- **Bias magnitude heuristic:** directional deviation uses a fixed Cohen's d margin
  (0.2); it is a declared, provenance-carrying threshold, not a calibrated population
  statistic.
- **Float arithmetic:** IEEE floats; tests use exact equality only for deterministic
  same-VM comparisons, otherwise `assert_in_delta`-style checks.

## 4. Evidence

- Verifier: `certification/forecasting/verifiers/EFDI_D5_independent_verification.py` →
  `EFDI_D5_independent_verification_output.json`. All 25 gates (V36–V60) + live regression PASS.
- Evidence ledger: `certification/forecasting/EFDI_D5_EVIDENCE.json`.
- Test matrix: `certification/forecasting/EFDI_D5_TEST_MATRIX.md`.
- Adversarial suite (`d5_adversarial_test.exs`) contains real, non-hardcoded challenges:
  agreement ≠ correctness, disagreement ≠ error, variance ≠ noise, execution spoofing
  (executed:true/runs:0 → UNKNOWN), contamination-dominates-invalidity, source
  spoofing via inflated n, and bias-direction laundering — each verified against live
  module behavior, not stubs.

## 5. Conclusion

D5 is **D5_CERTIFIED_BOUNDED**: the certified surface is exactly what the contract and
authorization state; everything outside that surface is declared-deferred (D6
institutional memory) or delegated to existing authority (Council, CIS, AEO). The verdict
is three-valued and was reached without weakening it to achieve certification.
Implementation STOPS here per the D5 mission; D6 is not begun.
