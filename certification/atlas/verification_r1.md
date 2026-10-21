# R1 verification log (Register 6 — verification and certification evidence)

Running log of verification results for remediation changes under the Tiannara System Unification and Closure
Programme. Every entry is bound to an exact revision, an exact command, and the artefact it tests.
A historical green run is history, not proof for a later commit: each entry names the SHA it applies to.

**Status vocabulary:** `FIXED_PENDING_VERIFICATION` (change landed, evidence not yet bound) → `VERIFIED_CLOSED`
(acceptance criteria demonstrated and bound to the exact SHA).

---

## V-R1-001 — R1/OP-01 exposed credential, code-side removal

| Field | Value |
|---|---|
| Change | `d3db325b` — literal production secrets removed from the tracked k8s overlay; base `kustomization.yaml` added; audit document redacted |
| Finding | F-ARC-008, F-PLT-005 (code-side portion) · residual F-SEC-001 |
| Command | `git grep -n "tiannara_nats_prod_token" -- .` and the matching cookie literal; `git grep -n "tiannara_phase6_cookie_prod" -- .` |
| Result | **No matches** in the tracked tree (before: 2 matches each) |
| CI | Elixir CI `39585781409` (sha `d3db325b`) — compile ✓, test-placement ✓, lineage-regression ✓, `tiannara_runtime suite (required)` 40 properties / 1,854 tests / 0 failures ✓, `suite` 79 properties / 2,485 tests / 0 failures ✓; Cross-Platform `39585781380` ✓ |
| Status | `FIXED_PENDING_VERIFICATION` — rotation and history remediation are operator actions (F-SEC-001) and are **not** claimed done |
| Record | `certification/atlas/closure_records/R1-OP-01_CREDENTIAL_EXPOSURE.md` |

## V-R1-002 — R1/Batch 1 step 1, F-GOV-007 (hard invariants authoritative over a policy action)

| Field | Value |
|---|---|
| Change | `5dcc9ebd` — `score_auth/3` withdraws an approval that rests on a violated hard invariant; new `RuleEngine.hard_invariant_violations/2`; new denial-path suite `test/tiannara/council/policy_invariant_precedence_test.exs` (6 tests) |
| Finding | **F-GOV-007** (critical) — root-cause cluster C3 (authority without enforcement) |
| Acceptance criterion (operator) | "A negative test demonstrates that an invariant violation plus an approving policy still produces a non-approved result. The test must run in CI and be bound to the exact commit." |
| Before evidence | Same suite run against the pre-fix `council.ex`: **4 failures** (`:human_final_authority`, `:audit_log_immutability`, `:no_self_amendment` bypass cases + the withdrawal-metadata assertion). The positive control and the `RuleEngine` unit check passed in that state, so the suite is not vacuous. |
| After evidence | Same suite on the fixed code: **6 tests, 0 failures**. Consumer regression (council suite + all five `Council.authorize` consumer files incl. the D127 authorization attack suite): **75 tests, 0 failures** (local, 13.5 s). |
| CI | Elixir CI **`39634396854`** (sha `5dcc9ebd`): compile ✓, test-placement ✓, lineage-regression ✓ (11 tests, 0 failures), `tiannara_runtime suite (required)` **40 properties, 1,854 tests, 0 failures, 6 excluded** ✓, `suite` **79 properties, 2,491 tests, 0 failures, 2 skipped** ✓. Cross-Platform **`39634396510`** ✓. |
| **Proof the new suite ran in CI** | Test-count delta between the two consecutive required root-suite runs: run `39585781409` (sha `d3db325b`, before) = **2,485 tests**; run `39634396854` (sha `5dcc9ebd`, after) = **2,491 tests** → exactly **+6**, the size of the new suite. Both runs: 0 failures. |
| Local-environment note | The local root suite reports 16–18 failures (12 in `Tiannara.Runtime.ExecutiveMemoryTest` DETS behaviour, the rest order-dependent). The 12 DETS failures were **reproduced with this change reverted**, and the remainder pass in isolation; the same command is green in CI. Recorded as an environment difference, **not** as a pass and **not** as a regression. |
| Residual scope | F-GOV-006 / F-GOV-023 (a compliant decision still cannot reach `:approved`; the plugin path is dormant) and F-GOV-004 / F-GOV-017 (no human-approval resume path) remain **OPEN** — deliberately not started in this step. |
| Status | **`VERIFIED_CLOSED`** — the step-1 acceptance criterion is demonstrated by a reproducible negative test that runs in CI, bound to sha `5dcc9ebd`. |
| Record | `certification/atlas/closure_records/R1-B1-01_F-GOV-007.md` |
