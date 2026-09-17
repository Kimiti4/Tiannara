# EFDI D3 — Test Matrix

**Gate:** EFDI-D3 — 73 new tests (56 unit + 17 integration/adversarial/replay).
Full forecasting suite: **269 tests, 0 failures** = D1(92) + D2(104) + D3(73).

## Unit tests (56)

| File | Coverage | Count |
|------|----------|-------|
| `decision_test.exs` | construction, validation, versioning, do_nothing baseline | 10 |
| `decision_engine_test.exs` | EV, variance, stddev, decide, recommendation | 9 |
| `decision_registry_test.exs` | register/get/count/all_ids/immutability/health | 7 |
| `decision_snapshot_test.exs` | capture freeze, consistent?/2 hindsight detection | 4 |
| `decision_quality_test.exs` | hindsight-independence, classify 4×4, components | 6 |
| `decision_review_test.exs` | postmortem, guard_outcome, decision_outcome | 4 |
| `pre_mortem_test.exs` | run/run_all/posture, blocked?, require_info | 7 |
| `value_of_information_test.exs` | EVPI, sensitivity, information gap, research priorities | 9 |

## Verification tests (17)

| File | Coverage | Count |
|------|----------|-------|
| `d3_integration_test.exs` | full pipeline (engine→snapshot→registry→quality→review), pre-mortem+VoI, immutability | 4 |
| `d3_adversarial_test.exs` | hindsight smuggling, malformed inputs, duplicate ids, authority boundary | 9 |
| `d3_replay_test.exs` | deterministic replay, outcome non-contamination, registry read stability | 4 |

## Gate → test mapping

| Gate | Primary evidence |
|------|------------------|
| V1 Decision Contract | decision_test.exs: new/validate |
| V2 Alternative Contract | decision_test.validation, decision_engine_test malformed |
| V3 DecisionRequest | decision_test.exs: request input |
| V4 Engine Arithmetic | decision_engine_test: EV 55.0, var 25/stddev 5 |
| V5 Unknown Honesty | decision_engine_test: :unknown cases |
| V6 Recommendation | decision_engine_test: max-EV, nil-when-unknown |
| V7 Immutability/Registry | decision_registry_test: no-op, count, health |
| V8 Version Lineage | decision_test: version/2 |
| V9 Resulting Prevention | decision_quality_test: invariant, decision_review |
| V10 Outcome Separation | decision_quality_test: classify 4×4 |
| V11 Hindsight Isolation | decision_review_test + d3_adversarial (pre-decision outcome) |
| V12 Snapshot | decision_snapshot_test |
| V13 Pre-Mortem | pre_mortem_test + d3_integration |
| V14 Value-of-Information | value_of_information_test |
| V15 Authorization Boundary | d3_adversarial (recommendation ≠ authorization) + adapter source |
| V16 Research Boundary | value_of_information_test (priorities informational) + adapter source |
| V17 CIS Boundary | adapter `check_cis` source |
| V18 Replay | d3_replay_test |
| V19 Adversarial | d3_adversarial_test |