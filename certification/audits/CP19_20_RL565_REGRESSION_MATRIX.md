# CP19.20 — RL-565 Regression Matrix

## Suite
`test/tiannara/omega/rl565_council_decision_provenance_adversarial_test.exs` (19 tests)

## Positive controls (must pass)
| ID | Case | Expected |
|----|------|----------|
| R565-05 | delete authorization cannot authorize an update (scope mismatch at bind) | `:council_scope_mismatch` |
| R565-06 | authorization for entity A cannot delete entity B | `:effect_id_mismatch` |
| R565-07 | concurrent replay of one genuine grant deletes once | 1 `{:ok,_}`, rest `:already_consumed` |
| R565-10 | one receipt produces at most one machine grant | second mint `:council_decision_receipt_consumed` |
| control | genuine Council decision mints and binds | mint + bind succeed |

## Adversarial refusals (precise errors + postconditions)
| ID | Case | Expected error | Postcondition |
|----|------|----------------|---------------|
| R565-01 | public `Authorization.approved/1` struct | `:council_decision_proof_required` | no grant |
| R565-02 | manually reconstructed approved decision | `:council_decision_proof_required` | no grant |
| R565-03 | fabricated mint→bind→delete chain | `:council_decision_proof_required` | entity exists |
| R565-04 | altered decision reusing genuine receipt | `:council_decision_digest_mismatch` | receipt stays `:issued` |
| R565-08a | emergency blocks issuance | `:council_emergency_active` | no receipt |
| R565-08b | emergency blocks mint | `:council_emergency_active` | receipt stays `:issued` |
| R565-08c | emergency blocks effect execution | `:council_emergency_active` | entity exists |
| R565-11 | wrong issuer | `:council_receipt_issuer_invalid` | — |
| R565-12 | stale policy version | `:council_receipt_policy_mismatch` | — |
| R565-13 | expired receipt | `:council_decision_receipt_expired` | — |
| R565-14 | forged MAC | `:council_decision_receipt_invalid` | — |
| R565-15 | receipt replay | `:council_decision_receipt_consumed` | — |
| R565-16 | tampered grant digest at bind | `:authorization_grant_digest_mismatch` | — |
| R565-17 | unbound grant at UWM | `:effect_binding_required` | entity exists |

## Seeds
- Seed 0: 19 tests, 0 failures
- Seed 123456: 19 tests, 0 failures

## Broader affected suites
- `d127_uwm_delete_evaluation_test.exs`, `uwm_delete_governance_test.exs`, `d127_council_path_evaluation_test.exs`: 34 tests, 0 failures.
- `step13_g9_r1_authorization_followups_test.exs`, `conditional_grant_mechanism_test.exs`, `step13_r2_mint_authentication_test.exs`: 0 failures.
- `rl564_registry_issuance_adversarial_test.exs`: remains red baseline (RL-564 out of scope).

## Prohibited patterns
No `match?({:error, _})` or broad error lists in the RL-565 suite; all assertions use exact error atoms plus state postconditions.
