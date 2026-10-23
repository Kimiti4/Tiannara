# R1 verification log (Register 6 — verification and certification evidence)

Running log of verification results for remediation changes under the Tiannara System Unification and Closure
Programme. Every entry is bound to an exact revision, an exact command, and the artefact it tests.
A historical green run is history, not proof for a later commit: each entry names the SHA it applies to.

**Status vocabulary:** `FIXED_PENDING_VERIFICATION` (change landed, evidence not yet bound) → `VERIFIED_CLOSED`
(acceptance criteria demonstrated and bound to the exact SHA).

## Revision fields (traceability correction, 2026-10-21, operator review)

A verification result binds **three separate revisions**, which are not the same thing and must not be conflated:

| Field | Meaning |
|---|---|
| `source_code_revision` | The commit whose **code** was exercised. This is the revision the evidence is a claim *about*. |
| `evidence_record_revision` | The commit that records the evidence in the atlas. It is frequently a documentation-only commit that sits *on top of* the source revision. |
| `ci_run_id` / `ci_run_tested_sha` | The workflow run, and the SHA that run actually checked out and tested. A run cited against a documentation commit tested the code as of that commit — which is the code revision only if the documentation commit changed no code. |

**Rule:** a run is only evidence for a source revision if the tested SHA contains that source revision and changes no
code beyond it. In the entries below the tested SHA and the source revision are stated separately, and where the tested
SHA is a documentation commit, that is said explicitly. The distinction is a traceability correction only — it does not
reopen any finding, because each closure already rests on its own before/after test evidence.

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

| Step | source_code_revision | evidence_record_revision | ci_run_id (tested SHA) | Finding | Acceptance evidence | Status |
|---|---|---|---|---|---|---|
| OP-01 | `d3db325b` | `7d6bd061` (docs) | `39585781409` @ `d3db325b` | F-ARC-008 / F-PLT-005 (exposure) | Literal values removed from the tracked overlay; both greps return no matches; base kustomization added | FIXED_PENDING_VERIFICATION (rotation is an operator action — F-SEC-001) |
| 1 | `5dcc9ebd` | `1ff0ecaf` (docs) | `39634396854` @ `5dcc9ebd` | **F-GOV-007** | Denial-path suite: 4 failures before, 6/6 after; CI root-suite test count 2,485 → 2,491 (the +6 are the new suite) | **VERIFIED_CLOSED** |
| — | `5dcc9ebd` | `1ff0ecaf` (docs) | `39637895128` @ `1ff0ecaf` (docs; same code as `5dcc9ebd`) | evidence binding for step 1 | — | — |
| 3a | `ca95773b` | `7d6bd061` (docs) | `39640997784` @ `ca95773b` | **F-GOV-003** | Wildcard suite: 3 failures before, 5/5 after; council + consumers 80/0 | **VERIFIED_CLOSED** |
| 3b | `003a53ee` | `7d6bd061` (docs) | `39653455302` @ `003a53ee` | **F-GOV-005** | Conditional-grant suite: 8 failures before, 15/15 after; regression 169/0 | **VERIFIED_CLOSED** |
| 2 | `11404ac9` | `7d6bd061` (docs) | own run `39658874815` @ `11404ac9` **failed on an unrelated pre-existing race** (F-ARC-239); the finding's evidence is the cumulative green run `39673698526` @ `bb341c60` (code identical to `11404ac9` for this finding) | **F-GOV-006 / F-GOV-023** | Reachability suite: 3 failures before, 7/7 after; regression 242 tests / 21 properties / 0 | **VERIFIED_CLOSED** |
| 4 | `cd036478` | `7d6bd061` (docs) | pushed together with the F-ARC-239 fix, so its evidence is run `39673698526` @ `bb341c60` | **F-GOV-004 / F-GOV-017** | Resume suite: 4 failures before, 6/6 after; regression 255 / 21 properties / 2 (both in the known-flaky F-ARC-238 file) | **VERIFIED_CLOSED** |
| CI | `bb341c60` | `7d6bd061` (docs) | `39673698526` @ `bb341c60` | **F-ARC-239** | The required runtime job is green with the isolated bridge test | **VERIFIED_CLOSED** |
| 5 | `ac12b3a2` | `7d6bd061` (docs) | `39677145165` @ `ac12b3a2` (Cross-Platform `39677144900` failed with the macOS job **cancelled** — F-ARC-241) | **F-ARC-007 / F-GOV-011** | Fail-closed verifier suite 13/13; the "220/220 PASS" report retired as non-evidence; the tool now has a required CI job | **VERIFIED_CLOSED** |
| 6 | `799c106d` | `7d6bd061` (docs) | `39682261149` @ `799c106d`; Cross-Platform `39682261150` @ `799c106d` | **F-GOV-013** | Kill-switch suite: 6 of 7 failed before, 7/7 after; affected runtime suites 66/0 | **VERIFIED_CLOSED** |
| — | `799c106d` (code) | `7d6bd061` (docs) | `39707868382` @ `7d6bd061` (docs; **same code as `799c106d`** — the run tested the documentation commit, whose code content is `799c106d`'s) | Batch 1 final state, re-verified | All required jobs green, including the new `tiannara_audit suite (required)` | — |
| — | `799c106d` (code) | `7d6bd061` (docs) | `39707868722` @ `7d6bd061` (same code as `799c106d`) | Batch 1 final state, cross-platform | ubuntu ✓, macos ✓, hash comparison ✓ | — |

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

## Batch 2 — runtime reachability (provisional; no closure)

These results are **not** Register 6 closures. They were produced from base `8ff5ec83` plus an uncommitted
working-tree patch (diff object `6d2cabdd`); there is no `source_code_revision`, no `evidence_record_revision` and no
CI run yet. They are recorded so the next commit can bind them without re-deriving the result.

| Step | source_code_revision | evidence_record_revision | ci_run_id | Finding | Acceptance evidence | Status |
|---|---|---|---|---|---|---|
| 2 | uncommitted (`8ff5ec83` + diff `6d2cabdd`) | uncommitted | none | F-ARC-226 boot reachability | Isolated `:minimal` boot (final-source run 7): app start ok, `all_running` true, top supervisor alive, world supervisor alive, endpoint 8004, CIS lockdown denies kill, 27 CPL events confined to scratch | provisional |
| 3 | uncommitted (`8ff5ec83` + diff `6d2cabdd`) | uncommitted | none | **F-ARC-240** | Kill-switch before: `:executed` but delivery false. After: canonical chain stops two supervised probe worlds, reports both in `killed_worlds`, supervisor survives; unrelated-world survivor and recovery checks pass; isolated regression test 9/9; full runtime suite 1863 tests + 40 properties, 0 failures | `FIXED_PENDING_VERIFICATION` |
| 4 | uncommitted (`8ff5ec83` + diff `6d2cabdd`) | uncommitted | none | F-ARC-228 / F-ARC-014 / F-ARC-235 | 4222 conflict degrades silently; EventGateway not started; `/health/live` 404; telemetry POST to 8004 hits the runtime router; prod compile fails | open |
| 5 | uncommitted (`8ff5ec83` + diff `6d2cabdd`) | uncommitted | none | F-ARC-018 / B4 persistence hygiene | CPL, Omega, Mnesia, and identity ledger redirected under `_build/test/tmp`; final full runtime suite (1863 tests, 0 failures) made zero repository writes in those stores. Test isolation is partial mitigation only; configurable Python store paths, merged store ownership, and clean-checkout persistence criteria remain outstanding | `OPEN` |

The detailed record is `certification/atlas/batch2/runtime_reachability.md`.