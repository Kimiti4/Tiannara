# Checkpoint 19.12 — Executable Regression Baseline and Evidence Capture

**Date:** 2026-11-11  
**Repository:** `Kimiti4/Tiannara`  
**Audit branch:** `audit/consolidated-findings-r0a-2026-10-31`  
**Regression branch:** `audit/cp19-10-red-baseline`  
**Regression head:** `8f03c32ad10fa9ad654f987d30dde1bc9a53df5d`  
**Draft validation PR:** [#13 — CP19.10 HAI and constitutional negative regression baseline](https://github.com/Kimiti4/Tiannara/pull/13)  
**Status:** `EXECUTION_ACTIVE_ROOT_SUITE_RESULT_PENDING`  
**Mode:** CI execution, job/log inspection and evidence capture; no production remediation.

---

## 1. Executive result

Checkpoint 19.12 obtained an executable GitHub Actions runner for the isolated Checkpoint 19.10 regression branch by opening draft, unmerged PR #13. The repository's existing workflows ran using the PR's regression commit.

**This is the first real CI execution attempt for the regression branch.** The environment and compile blockers from 19.11 were bypassed by GitHub Actions:

- Git checkout, Elixir/OTP setup, dependency retrieval, root source compilation and application smoke test passed.
- The CI test-placement guard passed.
- The required `tiannara_runtime` suite passed with 40 properties, 1,863 tests, 0 failures and 6 excluded.
- The `tiannara_audit` suite and lineage-regression job passed.
- Cross-platform verification completed successfully on both Ubuntu and macOS; the compare-hashes job passed.
- The non-blocking `tiannara_runtime quarantine` job failed with four unrelated quarantined test failures; it is configured `continue-on-error: true`.
- **The root Mix project's full `suite` job is still in progress at the time of this evidence capture.** It executes `MIX_ENV=test mix test --max-failures 25 --color`, which includes the two newly added test files. No completed log or exit code is yet available for this job.

Therefore no final case-level red-baseline count is claimed in this checkpoint. The actual root ExUnit suite has been invoked, but the 11 HAI/constitutional assertions' individual outcomes remain pending the completed root suite log.

## 2. Trigger and identity

A draft PR was created to invoke the existing CI without merging the deliberately negative tests or changing production code:

- PR: [#13](https://github.com/Kimiti4/Tiannara/pull/13)
- Title: `[Audit validation] CP19.10 HAI and constitutional negative regression baseline`
- State: OPEN / DRAFT / NOT MERGED
- Base: `audit/consolidated-findings-r0a-2026-10-31`
- Head: `audit/cp19-10-red-baseline`
- Head SHA: `8f03c32ad10fa9ad654f987d30dde1bc9a53df5d`
- Changed files: exactly the 2 new test files (153 additions, 0 deletions).

The branch-local workflow `.github/workflows/elixir_ci.yml` was verified to configure Elixir `1.18` / OTP `28`, and its root `suite` job runs `mix test --max-failures 25 --color`.

## 3. Workflow run evidence

### 3.1 Elixir CI

- Workflow run: [42931719446](https://github.com/Kimiti4/Tiannara/actions/runs/42931719446)
- Name: `Elixir CI`
- Run number: `622`
- Workflow ID: `369661312`
- Regression SHA: `8f03c32ad10fa9ad654f987d30dde1bc9a53df5d`
- State at capture: `in_progress`

Job outcomes captured:

| Job | Job ID | State/conclusion | Evidence |
|---|---:|---|---|
| `compile` | 130231848324 | COMPLETED / SUCCESS | `mix deps.get`, `mix compile --force --color`, and `MIX_ENV=test mix run -e ":ok"` all completed successfully |
| `test-placement` | 130231848618 | COMPLETED / SUCCESS | Fail-closed scan for ExUnit modules under `lib/` passed |
| `suite` | 130232472167 | IN_PROGRESS | `MIX_ENV=test mix test --max-failures 25 --color`; includes the 11 added root-project regression cases; no final logs/exit code yet |
| `lineage-regression` | 130232472246 | COMPLETED / SUCCESS | Dedicated discovery lineage test job passed |
| `tiannara_audit suite (required)` | 130232472176 | COMPLETED / SUCCESS | Independent audit verifier suite passed |
| `tiannara_runtime suite (required)` | 130232472419 | COMPLETED / SUCCESS | Full required runtime suite log: `40 properties, 1863 tests, 0 failures, 6 excluded` |
| `tiannara_runtime quarantine (non-blocking)` | 130232472073 | COMPLETED / FAILURE | Non-blocking quarantined tests produced 4 failures; details below |

### 3.2 Cross-Platform Verification

- Workflow run: [42931719461](https://github.com/Kimiti4/Tiannara/actions/runs/42931719461)
- Name: `Cross-Platform Verification`
- Run number: `1408`
- Workflow ID: `306275411`
- State: COMPLETED / SUCCESS

Both platform jobs passed:

| Job | Job ID | Result |
|---|---:|---|
| Verify — Ubuntu | 130231848471 | SUCCESS |
| Verify — macOS | 130231848212 | SUCCESS |
| Compare Cross-Platform Hashes | 130232342044 | SUCCESS |

The final hash comparison step completed successfully. This is evidence for the workflow's Phase 14 cross-platform package/hashing path, not a substitute for the HAI or ConstitutionalAuditor negative regression tests.

## 4. Non-blocking quarantine failure classification

The `tiannara_runtime quarantine (non-blocking)` job is configured `continue-on-error: true`; its failure does not represent failure of the required runtime suite or the root CP19.10 suite.

Its completed log reported:

```text
Finished in 36.0 seconds (4.0s async, 32.0s sync)
40 properties, 1863 tests, 4 failures, 1897 excluded
Process completed with exit code 2.
```

The four failures shown in that quarantine log were:

1. `ColdIgnition.ReactivityTest` — “constraint load spikes after perturbation”; constraint load remained `0.0 -> 0.0`.
2. `ColdIgnition.PassiveModeTest` — “no mutations occur in passive mode”; fingerprint differed (`6547843 != 121855514`).
3. `TiannaraRuntime.OmegaRobustnessTest` — “CPL reloads persisted events and checkpoints without state marker”; `start_link` returned `{:error, {:already_started, pid}}`.
4. `TiannaraRuntime.OmegaRobustnessTest` — “Omega supervisor provides readiness primitives without external services”; child startup failed with `already_started`.

These failures are from the separate runtime quarantine test selection. They do not correspond to either new root-project test file and must not be counted as RL-558 or RL-562 results.

The required runtime suite subsequently completed successfully with 0 failures.

## 5. Regression tests and static behavior mapping

The regression branch still contains exactly these two new files:

| Test file | Blob SHA | Test count |
|---|---|---:|
| `test/tiannara/audits/checkpoint_19_10_hai_negative_regression_test.exs` | `2355ca1f871f39134a77b5176a7ee4e3961862c0` | 7 |
| `test/tiannara/audits/checkpoint_19_10_constitutional_evidence_negative_regression_test.exs` | `89abde5feb3568ae3c7eb943676eb22f218428d7` | 4 |

The expected negative cases, derived from source inspection, remain:

### RL-558 — HAI authority

- Missing impact cannot auto-approve.
- Nil impact cannot auto-approve.
- Unknown atom impact cannot auto-approve.
- String impact cannot auto-approve.
- Caller without reviewer identity cannot resolve a mandatory review.
- Unsupported decision value must be rejected.
- Resolved review cannot accept a conflicting second decision.

### RL-562 — constitutional evidence

- Empty evidence map cannot produce compliance.
- Partial evidence cannot silently default omitted fields to passing.
- Zero verification denominator is not proof of verification.
- Zero evolution denominator is not proof of validation balance.

These are expected to expose current unsafe source behavior, but **the root suite's individual assertions have not yet been observed in completed test output**.

## 6. Execution classification

| Layer | Current evidence | Classification |
|---|---|---|
| Checkout / toolchain | Checkout and Elixir 1.18 / OTP 28 setup completed | PASS |
| Dependencies | Root `mix deps.get` completed | PASS |
| Root compilation | `mix compile --force --color` completed | PASS |
| Root test-environment app smoke | `MIX_ENV=test mix run -e ":ok"` completed | PASS |
| ExUnit placement gate | Scan passed | PASS |
| Root full suite including CP19.10 test files | Command started; still in progress | PENDING |
| Required `tiannara_runtime` suite | 1,863 tests, 0 failures, 6 excluded | PASS |
| Required `tiannara_audit` suite | Job completed successfully | PASS |
| Lineage regression | Job completed successfully | PASS |
| Runtime quarantine | 4 failures; `continue-on-error` | NON-BLOCKING FAILURE |
| Cross-platform verification | Ubuntu + macOS + hash compare all succeeded | PASS |

CI has not produced a final overall Elixir CI conclusion at the time this report was assembled.

## 7. Finding disposition

| Finding | Severity | Checkpoint 19.12 disposition |
|---|---|---|
| RL-558 — invalid impact auto-approval and unauthenticated/unvalidated review decisions | CRITICAL | OPEN — root suite execution active; case-level result pending |
| RL-562 — missing/defaulted/synthetic evidence may report compliance | CRITICAL | OPEN — root suite execution active; case-level result pending |
| Test compilation | — | ROOT COMPILE PASS |
| Root test discovery and assertion outcomes | — | PENDING root suite completion |
| Runtime suite regressions | — | Required suite PASS; quarantine has four unrelated non-blocking failures |
| Cross-platform verification | — | PASS |

No production implementation, runtime configuration, deployment or physical actuation was changed. The draft PR remains open and unmerged.

**Checkpoint 19.12 status:** `EXECUTION_ACTIVE_ROOT_SUITE_RESULT_PENDING`.

**Exit criteria:** retrieve the completed log and exit code for job `130232472167`. Confirm whether both new regression modules were discovered and whether all 11 assertions failed for the expected product behaviors. Distinguish any earlier unrelated failures or test-discovery/build issues. Only then record the red-baseline count and decide whether the tests need isolation from the general suite. RL-558 and RL-562 remain open until remediation and independent green regression verification.
