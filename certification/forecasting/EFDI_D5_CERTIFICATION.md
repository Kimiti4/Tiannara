# EFDI D5 — Certification

**Gate:** EFDI-D5 · **Verdict: D5_CERTIFIED_BOUNDED** · Date: 2026-09-03

## 1. What was certified

D5 — Noise, Judgment Variability, Robustness & Sensitivity Intelligence — as an
analytical layer over the certified D1–D4 substrate (operational mission, Phase 3–6
under contract v1.0.0, `PHASE_3_AUTHORIZED`). Certified surface:

- **§4 Repetition tiers** — TIER-0 (n<5), TIER-1 (5–31, provisional only), TIER-2 (≥32,
  classifiable); n=1 never supports a claim (`no_estimate_permitted`).
- **§5 Perturbation** — pre-registered plans, closed dimension set (9 dims), LATE_ADDED
  plans permanently barred from classification, validity (VALID/INVALID/CONTAMINATION).
- **§6 Noise + §6.4 Bias** — noise classification by CI band at TIER-2 only; source
  identifiability gate; consensus requiring independent lineage; bias only with a
  directional reference; VARIANCE ≠ NOISE enforced, not asserted.
- **§7 Robustness / Sensitivity** — materiality recomputation (flips, threshold crossings,
  ε), evidence-table robustness classes (robust / moderately_robust / sensitive / fragile
  / unstable / unknown), mandatory coverage_manifest (UNKNOWN below full coverage), and
  separate confidence vs robustness axes.
- **§8 Regime** — classification tags, sensitive-dimension mismatch rejection, no
  cross-regime transfer.
- **§9 Temporal** — computed (not self-declared) decision-time labels, POST_OUTCOME_ANALYSIS
  write-guard, D4→D3 temporal firewall extension with adversarial audit events.
- **§10 Budget** — submission-time budget enforcement (512 runs, 8 variants/dim, 6 models,
  6 evaluators, 5 dims), partial-coverage downgrade to coverage-scoped UNKNOWN.
- **§11 Disagreement** — individual judgments preserved (content-addressed), derived
  aggregate only; §15.1 D2 activation via the single sanctioned append-only
  `Forecast.version/2 → ForecastRegistry.register/1` path.
- **§14 Thresholds** — single source of truth with `threshold_set_hash` (anti-laundering).

## 2. Verification

Independent no-trust verifier `EFDI_D5_independent_verification.py` (source-scan + live
`mix test` — never trusts internal flags). All V36–V60 gates pass:

```
V36..V60         PASS (25/25)
MIX_TEST_TOTAL   354  (D1=92, D2=104, D3=73, D4=31, D5=54)
MIX_TEST_FAILURES 0
D1_D2_D3_D4_REGRESSION_PRESERVED PRESERVED (300 tests, 0 failures)
OVERALL          D5_CERTIFIED_BOUNDED
```

Full output: `certification/forecasting/verifiers/EFDI_D5_independent_verification_output.json`.

## 3. Bounds (what certification does NOT claim)

- **No execution / authorization bypass** — D5 is strictly analytical; Council
  authorizes, AEO executes; D6 untouched. Verdict is three-valued
  (`d5_certified_bounded | d5_qualified_partial | d5_not_certified`), never a boolean.
- **No parallel statistics system** — all dispersion/divergence/entropy route through
  canonical `Tiannara.Numerics` / `Tiannara.Foundations.InformationTheory`. No new math engine.
- **No noise from disagreement alone** — evaluator disagreement is a distinct, non-error
  classification; identifiability gates source attribution.
- **No bias from insufficient observations** — bias requires a directional reference AND
  a classifiable sample; otherwise `UNKNOWN`, never a measured direction.
- **No robustness without bounded perturbation coverage** — any declared dimension
  unexecuted / invalid / below minimum forces `UNKNOWN`; UNTESTED ≠ ROBUST.
- **Minority preserved** — individual judgments are recoverable from the aggregate
  (`input_hashes`); no suppression.
- **Historical immutability** — no D1–D4 record rewritten, except the single sanctioned,
  append-only D2 `:disagreement` activation path (§15.1).
- **Thresholds frozen + provenance-bound** — `threshold_set_hash` makes threshold
  laundering detectable; no hidden constants.

## 4. Interface evolution

D5 adds the `Tiannara.Forecasting.D5.*` module namespace (`thresholds`, `repetition`,
`budget`, `perturbation`, `sensitivity`, `noise`, `robustness`, `regime`, `temporal`,
`disagreement`) plus the `Tiannara.Forecasting.D5` facade, all additively over the D1–D4
substrate. No existing struct position or semantics changed.

## 5. Artefacts

| Artefact | Path |
|----------|------|
| Contract | `certification/forecasting/contracts/EFDI_D5_CONTRACT.md` |
| Authorization | `certification/forecasting/authorization/EFDI_D5_AUTHORIZATION.md` |
| Test matrix | `certification/forecasting/EFDI_D5_TEST_MATRIX.md` |
| Evidence | `certification/forecasting/EFDI_D5_EVIDENCE.json` |
| Verifier | `certification/forecasting/verifiers/EFDI_D5_independent_verification.py` |
| Verifier output | `certification/forecasting/verifiers/EFDI_D5_independent_verification_output.json` |
| Recon | `docs/architecture/EFDI_D5_ARCHITECTURE_RECONNAISSANCE.md` |
| Classification matrix | `docs/architecture/EFDI_D5_CLASSIFICATION_MATRIX.md` |
| Audit | `docs/audit/forecasting/EFDI_D5_AUDIT.md` |
