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

---

## Batch 1 — CI-bound verification summary

**Final state commit:** `799c106d` · **Elixir CI `39682261149`: success** (compile, test-placement, lineage-regression,
`tiannara_runtime suite (required)` 1,854 tests / 0 failures, `suite` 2,491+ tests / 0 failures, and the **new**
`tiannara_audit suite (required)` 13 tests / 0 failures) · **Cross-Platform `39682261150`: success** (ubuntu, macos,
hash comparison).

| Step | Change | Finding | Acceptance evidence | CI (Elixir CI) | Status |
|---|---|---|---|---|---|
| OP-01 | `d3db325b` | F-ARC-008 / F-PLT-005 (exposure) | Literal values removed from the tracked overlay; both greps return no matches; base kustomization added | `39585781409` ✓ | FIXED_PENDING_VERIFICATION (rotation is an operator action — F-SEC-001) |
| 1 | `5dcc9ebd` | **F-GOV-007** | Denial-path suite: 4 failures before, 6/6 after; CI root-suite test count 2,485 → 2,491 (the +6 are the new suite) | `39634396854` ✓ | **VERIFIED_CLOSED** |
| — | `1ff0ecaf` | evidence binding for step 1 | — | `39637895128` ✓ | — |
| 3a | `ca95773b` | **F-GOV-003** | Wildcard suite: 3 failures before, 5/5 after; council + consumers 80/0 | `39640997784` ✓ | **VERIFIED_CLOSED** |
| 3b | `003a53ee` | **F-GOV-005** | Conditional-grant suite: 8 failures before, 15/15 after; regression 169/0 | `39653455302` ✓ | **VERIFIED_CLOSED** |
| 2 | `11404ac9` | **F-GOV-006 / F-GOV-023** | Reachability suite: 3 failures before, 7/7 after; regression 242 tests / 21 properties / 0 | own run `39658874815` **failed on an unrelated pre-existing race** (F-ARC-239); the finding's evidence is the cumulative green run `39673698526` (bb341c60) | **VERIFIED_CLOSED** |
| 4 | `cd036478` | **F-GOV-004 / F-GOV-017** | Resume suite: 4 failures before, 6/6 after; regression 255 / 21 properties / 2 (both in the known-flaky F-ARC-238 file) | pushed together with the F-ARC-239 fix, so its evidence is run `39673698526` ✓ | **VERIFIED_CLOSED** |
| CI | `bb341c60` | **F-ARC-239** | The required runtime job is green with the isolated bridge test | `39673698526` ✓ | **VERIFIED_CLOSED** |
| 5 | `ac12b3a2` | **F-ARC-007 / F-GOV-011** | Fail-closed verifier suite 13/13; the "220/220 PASS" report retired as non-evidence; the tool now has a required CI job | `39677145165` ✓ (Cross-Platform `39677144900` failed with the macOS job **cancelled** — F-ARC-241) | **VERIFIED_CLOSED** |
| 6 | `799c106d` | **F-GOV-013** | Kill-switch suite: 6 of 7 failed before, 7/7 after; affected runtime suites 66/0 | `39682261149` ✓ | **VERIFIED_CLOSED** |

**Order deviations from the operator's plan, and why (all safety-driven, all recorded in the closure records):**

1. **F-GOV-003 and F-GOV-005 were landed before step 2** (approval reachability). With the `:any` wildcard broken, a
   high-risk decision would have reached the rule engine instead of the `high_risk` policy — and once `:approved` is
   reachable, a `:conditional` decision that is still treated as a grant would let an evidence-poor decision authorise
   an effect. Both would have opened a bypass window; landing them first removes it. The operator's explicit
   constraint (F-GOV-007 verified before F-GOV-006/F-GOV-023) was respected: F-GOV-007 closed at `5dcc9ebd` with CI
   evidence before any approval became reachable.
2. **The authority boundary (HC-2) was determined before step 2**, as the operator required, and is recorded in
   `closure_records/R1-B1-04_F-GOV-006.md` and D-ARC-011.

**Batch 1 outcome:** 10 findings VERIFIED_CLOSED, 1 (the credential rotation) FIXED_PENDING_VERIFICATION with the
operator action outstanding, 4 new findings opened (F-ARC-238 chaos flake, F-ARC-239 bridge race — now closed,
F-ARC-240 world supervisor not started, F-ARC-241 macOS job cancellation), and 1 evidence-contract finding
(F-GOV-025). No finding was closed by a code change alone: every closure is bound to a CI run id and a before/after
test result.

**What Batch 1 did not do:** it did not make the constitutional layer reachable from a launcher (F-ARC-226 / F-ARC-240
remain), did not implement certificate signing (F-GOV-010), did not build CAE/CAP gate machinery (the specifications
are still not in the repository, F-GOV-001), and did not change the CIS arbitration default (D-ARC-015).