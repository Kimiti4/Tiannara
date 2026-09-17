# EFDI D4 — Test Matrix

**Gate:** EFDI-D4 — 31 new tests (25 unit + 6 verification).
Full forecasting suite: **300 tests, 0 failures** = D1(92) + D2(104) + D3(73) + D4(31).

## Unit tests (25)

| File | Coverage | Count |
|------|----------|-------|
| `counterfactual_test.exs` | status ontology, observed-only-via-D1, labeled record, intervention explicitness, branch/2 parent-ref, validate | 6 |
| `alternative_history_test.exs` | bounded bundle, always-includes do_nothing, exclusion records, add beyond bound, non-observed elements | 4 |
| `attribution_test.exs` | NOT_ATTRIBUTED default, single outcome never attributed, no resulting inference, skill/luck classification, threshold provenance | 6 |
| `selection_test.exs` | known/unknown denominator, survivorship flag, selection read | 4 |
| `regression_to_mean_test.exs` | unknown reference class, extremity, single-observation unknown, non-causal schema | 5 |

## Verification tests (6)

| File | Coverage | Count |
|------|----------|-------|
| `temporal_firewall_test.exs` | firewall_intact?, hindsight contamination, D3 read-only / d3_writes | 4 |
| `d4_integration_test.exs` | full pipeline bundle→analysis→selection→RTM over D3, status reflects D4 implemented + D5/D6 deferred | 2 |

## Gate → test mapping

| Gate | Primary evidence |
|------|------------------|
| V20 Status Ontology | counterfactual_test: statuses/known? first-class |
| V21 Observed-only-via-D1 | counterfactual_test: enforce_observability_boundary, validate observed |
| V22 Labeled Analytical Record | counterfactual_test: branch/content_ref, no merge |
| V23 Intervention Explicitness | counterfactual_test: observe_only, validate missing intervention |
| V24 Alt-History Bounded | alternative_history_test: max_alternatives, exclusion |
| V25 Bundle Non-Observed | alternative_history_test: every element non-observed |
| V26 Attribution Default | attribution_test: no evidence → NOT_ATTRIBUTED |
| V27 Threshold Provenance | attribution_test: thresholds_provenance |
| V28 Attribution Boundary | attribution_test: single outcome, BAD/GOOD outcome |
| V29 Survivorship/Denominator | selection_test: known/unknown denominator, survivorship |
| V30 UNKNOWN_SELECTION_EFFECT | selection_test: select_from returns error |
| V31 RTM Non-Causal | regression_to_mean_test: causal_claim_free? |
| V32 RTM Unknown Honesty | regression_to_mean_test: no reference class → unknown |
| V33 Temporal Firewall | temporal_firewall_test: firewall_intact? |
| V34 D3 Read-Only | temporal_firewall_test: d3_writes |
| V35 Adapter-not-new-engine | classification matrix (REUSE/ADAPTER) + efdi status deferred D5/D6 |
