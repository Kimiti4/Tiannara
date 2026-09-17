# EFDI D5 — Test Matrix

**Gate:** EFDI-D5 — 54 new tests (27 unit + 5 integration + 16 adversarial + 6 replay).
Full forecasting suite: **354 tests, 0 failures** = D1(92) + D2(104) + D3(73) + D4(31) + D5(54).

## Unit tests (27)

`test/tiannara/forecasting/d5/d5_unit_test.exs`

| Coverage | Count |
|----------|-------|
| Threshold provenance, frozen hash, budget/eps/tier constants (§14) | 2 |
| Repetition tiers (TIER-0/1/2, n=1 no-estimate), canonical dispersion (§4) | 2 |
| Budget within/over, closed dims, partial-coverage UNKNOWN (§10) | 3 |
| Perturbation pre-registration/eligibility, LATE_ADDED barred, validity/contamination (§5) | 3 |
| Sensitivity: flips, crossings, epsilon materiality (§7.1) | 1 |
| Noise classification at TIER-2 only, identifiability, bias w/ reference, consensus lineage, analyze (§6) | 5 |
| Robustness REQUIRES coverage; classes robust/sensitive/fragile/moderately_robust; separate axes (§7) | 3 |
| Regime mismatch rejection, no cross-regime transfer (§8) | 2 |
| Temporal computed labels, POST_OUTCOME write-guard, adversarial audit event (§9) | 3 |
| Disagreement preserves individuals, rejects unpermitted methods; D5 facade (§11) | 3 |

## Integration tests (5)

`test/tiannara/forecasting/d5/d5_integration_test.exs` — end-to-end D5 flow over the
D1–D4 substrate: perturbation plan → execution → robustness, disagreement aggregation
over the registry, and the §15.1 sanctioned D2 `:disagreement` activation via
`Forecast.version/2 → ForecastRegistry.register/1`.

## Adversarial tests (16)

`test/tiannara/forecasting/d5/d5_adversarial_test.exs` — real, non-hardcoded epistemic
challenges (each verified against live module behavior):

- agreement ≠ correctness; disagreement ≠ error
- variance ≠ noise (no source from spread alone)
- no bias from insufficient observations (even with a reference)
- no robustness without actual bounded perturbation coverage
- threshold-laundering detectable; selective perturbation (late-added) barred
- minority preserved in aggregation
- post-outcome cannot write decision-time fields
- regime mismatch → aggregate UNKNOWN
- budget exhaustion → deterministic rejection, not silent truncation
- variance cannot claim robustness without manifest
- **execution spoofing** (executed:true / runs:0 → UNKNOWN, never robust)
- **contamination dominates** over-budget / undeclared-dimension invalidity
- **source-spoofing** via inflated n cannot force single-source attribution
- **bias-direction laundering** never emits a direction on insufficient samples

## Replay tests (6)

`test/tiannara/forecasting/d5/d5_replay_test.exs` — deterministic re-execution of D5
classifications/pure functions reproduces identical results; content-addressed hashes
are stable across replays; no hidden state mutation.

## Gate → test mapping

| Gate | Primary evidence |
|------|------------------|
| V36 Contract integrity | unit: threshold provenance / contract_version == 1.0.0 |
| V37 Canonical reuse | unit: dispersion routes through `Tiannara.Numerics` |
| V38/V58 Immutability | integration: §15.1 append-only activation; never overwrites |
| V39 Repetition tiers | unit: tier_for / classifiable / no_estimate_permitted |
| V40/V41 Identifiability + lineage | unit+adversarial: isolate/identify_source, consensus lineage |
| V42 LATE_ADDED barred | unit+adversarial: register_late_added can never classify |
| V43 Materiality | unit: flip?/threshold_crossing?/material? |
| V44/V46 Robustness evidence + axes | unit+adversarial: coverage_manifest, execution spoofing, separate axes |
| V45 UNKNOWN truth-table | unit+adversarial: coverage_scoped_unknown / insufficient_samples |
| V47 Bias vs noise | unit+adversarial: bias_separation, variance ≠ noise, no direction laundering |
| V48 Regime mismatch | unit+adversarial: aggregable? regime_mismatch |
| V49 Temporal firewall | unit: guarantee_write_guard / adversarial audit event |
| V50 D2 integration | integration: activate_disagreement via version/2 → register/1 |
| V51/V52 D3/D4 read-only | adversarial: no OBSERVED promotion; annotation-only |
| V53 Budget enforcement | unit+adversarial: over-budget rejection, partial coverage |
| V54 Replay determinism | replay: reproducible results, stable hashes |
| V55 Anti-laundering | unit+adversarial: threshold_set_hash, late-added barred |
| V56 Minority preservation | unit+adversarial: input_hashes, minority counted |
| V57 Provenance | unit: contract_version + threshold_set_hash + content_hash + n |
| V59 No execution bypass | integration/facade: analytical-only, three-valued verdict |
| V60 Full regression | whole-suite 354 / 0 failures (300 D1–D4 + 54 D5) |
