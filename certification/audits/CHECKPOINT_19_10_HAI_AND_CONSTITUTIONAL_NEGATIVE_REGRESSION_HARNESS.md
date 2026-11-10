# Checkpoint 19.10 — HAI and Constitutional Negative-Regression Harness

**Date:** 2026-11-11  
**Repository:** `Kimiti4/Tiannara`  
**Audit branch:** `audit/consolidated-findings-r0a-2026-10-31`  
**Regression branch:** `audit/cp19-10-red-baseline`  
**Regression branch base:** `be84d1ed2e04f22e7086ee83566edb9eb8c2909e`  
**Regression branch inspected head:** `8f03c32ad10fa9ad654f987d30dde1bc9a53df5d`  
**Status:** `NEGATIVE_REGRESSION_HARNESS_AUTHORED_EXECUTION_NOT_RUN`  
**Mode:** Isolated test-source preparation and static review; production implementation unchanged.

---

## 1. Executive result

Checkpoint 19.10 prepared an initial executable regression harness for the two critical findings carried forward from 19.08–19.09.

**Eleven focused regression cases have been authored on a separate branch. None has been executed or compiled in this session.** The available GitHub integration supports repository file operations and limited CI inspection, but not repository shell execution, Elixir/Mix invocation, general workflow-run enumeration or workflow dispatch.

The dedicated test branch is based on the 19.09 audit-register commit and is three commits ahead, with exactly two changed paths: the two new regression test files. A compare-commits inspection confirms no production implementation path was changed.

This checkpoint improves the test harness; it does not establish a runtime red baseline. The tests are source-derived expected-failure candidates. Compilation, test discovery, startup behavior and actual assertion outcomes remain UNKNOWN pending a compatible runner.

## 2. Regression branch and change isolation

**Regression branch:** `audit/cp19-10-red-baseline`  
**Base commit:** `be84d1ed2e04f22e7086ee83566edb9eb8c2909e`  
**Inspected head:** `8f03c32ad10fa9ad654f987d30dde1bc9a53df5d`

Compare-commits result:

- Status: `ahead`
- Ahead by: 3 commits
- Behind by: 0 commits
- Changed files: exactly 2, both added under `test/tiannara/audits/`
- No production source, runtime configuration, application supervision or deployment file changed.

### Added test files

| Test file | Blob SHA | Cases |
|---|---|---:|
| `test/tiannara/audits/checkpoint_19_10_hai_negative_regression_test.exs` | `2355ca1f871f39134a77b5176a7ee4e3961862c0` | 7 |
| `test/tiannara/audits/checkpoint_19_10_constitutional_evidence_negative_regression_test.exs` | `89abde5feb3568ae3c7eb943676eb22f218428d7` | 4 |

The HAI file's final update commit is `8f03c32ad10fa9ad654f987d30dde1bc9a53df5d`. The constitutional test file was added in commit `496d833888bce78e6ed4dbbcb104c7f7e0b62c95`.

## 3. HAI regression coverage — RL-558

The new HAI suite uses the existing `ReviewRouter` application process and resets its in-memory state for each test, following the isolation pattern in the existing HAI test module.

| Test case | Unsafe behavior guarded against | Source-derived current behavior |
|---|---|---|
| Missing impact | Missing impact cannot auto-approve | Constructor leaves impact nil; router catch-all approves |
| Nil impact | Nil impact cannot auto-approve | Router catch-all approves |
| Unknown atom | Unrecognized impact cannot auto-approve | Router catch-all approves |
| String impact | Wrong-type impact cannot auto-approve | Router catch-all approves |
| No reviewer identity | Decision cannot be accepted without authenticated reviewer identity/authorization | Public API has no actor argument; handler ignores GenServer caller identity and accepts decision |
| Unsupported decision value | Invalid decision enum must be rejected | Handler stores supplied term as status and returns `:ok` |
| Conflicting replay | A resolved review cannot accept a second conflicting decision | Handler does not enforce current-state transition or replay protection |

These are intended negative regression tests. The expected unsafe outcomes are directly traceable to the inspected implementation at the pinned source blobs:

- `lib/tiannara/hai/domain.ex`: `4a8ffe859a2611de1a3df032509a431d1ee55163`
- `lib/tiannara/hai/review_router.ex`: `54a09fc1c2b143b61edecf0b615c229011b335fa`

No production fix was applied. A future implementation may return a structured validation/authorization error or a safe UNKNOWN/pending state; the tests assert that the unsafe success path is not accepted rather than coupling to one exact error tuple.

## 4. Constitutional evidence regression coverage — RL-562

The new pure-function suite calls `Tiannara.Evolution.ConstitutionalAuditor.audit/1` directly.

| Test case | Required safe behavior | Source-derived current behavior |
|---|---|---|
| Empty evidence map | Missing evidence cannot produce `:compliant` | Every missing field defaults to a passing value; all eight checks pass |
| Partial evidence map | Omitted domains cannot silently default to passing | Missing fields default to zero or 1.0; audit can report `:compliant` |
| Zero verification denominator | Zero capabilities and zero verifications are not proof of verification | Ratio defaults to 1.0 |
| Zero evolution denominator | Zero evolutions and zero validations are not proof of validation balance | Ratio defaults to 1.0 |

Source reviewed:

- `lib/tiannara/evolution/constitutional_auditor.ex`: `c0063363b49a8294946a5b3c2ac0225856bfc047`

The empty-map result remains a static evaluation, not an executed Elixir observation. The new tests are designed to turn that source-derived result into a reproducible runtime assertion once executed.

## 5. Execution and CI evidence

### What was checked

- Both test files were re-fetched from `audit/cp19-10-red-baseline`; their final blob SHAs matched the written values above.
- Compare-commits confirmed precisely two added test paths and no production implementation changes.
- The regression branch exists.
- Combined commit status for the inspected head returned `statuses: []`.
- The available commit-associated workflow lookup returned `workflow_runs: []`; its wrapper is limited to PR-triggered runs and first-page results.

### What was not available/performed

- No repository shell or Elixir/Mix runtime.
- No general Actions workflow/run enumeration or workflow-dispatch capability.
- No compile, formatter, static analyzer, ExUnit invocation or application boot.
- No runtime test output or exit code.
- No deployment, production change, state mutation in a running Tiannara environment, or physical actuation.

**Execution conclusion:** `NOT_EXECUTED`. Empty CI status/run results are not proof of success or failure. Test syntax and test-discovery behavior have not been compiled/verified.

## 6. Exact execution sequence

Use a disposable checkout of the regression branch. Ensure the local path dependency `forward_provenance/` is present. Use Elixir 1.18.0 or later within the project's declared compatibility range. For the initial run, leave `TEST_PARTITION` unset because `test/test_helper.exs` removes the configured per-run DETS/storage directories before and after the suite.

Record commit, clean/dirty state, versions, stdout/stderr and exit codes.

```bash
git switch audit/cp19-10-red-baseline
git rev-parse HEAD
git status --short
elixir --version
mix --version
mix deps.get

MIX_ENV=test mix test test/tiannara/audits/checkpoint_19_10_hai_negative_regression_test.exs
MIX_ENV=test mix test test/tiannara/audits/checkpoint_19_10_constitutional_evidence_negative_regression_test.exs
```

Run each file separately first so startup/compile errors can be distinguished from the expected product assertion failures. If dependency resolution or application startup fails, classify that as an environment/build blocker; do not count it as a red product baseline. Preserve the first unmodified implementation test output before making any source changes.

The suites can also be run together after each is independently discovered and characterized:

```bash
MIX_ENV=test mix test test/tiannara/audits/checkpoint_19_10_hai_negative_regression_test.exs test/tiannara/audits/checkpoint_19_10_constitutional_evidence_negative_regression_test.exs
```

## 7. Finding disposition

| Finding | Severity | Checkpoint 19.10 disposition |
|---|---|---|
| RL-558 — invalid HAI impact auto-approval and unauthenticated/unvalidated decision mutation | CRITICAL | OPEN — 7 regression cases authored, NOT EXECUTED |
| RL-562 — missing/synthetic/defaulted constitutional evidence can pass | CRITICAL | OPEN — 4 regression cases authored, NOT EXECUTED |
| Test harness compilation/discovery | UNKNOWN | No compatible Elixir runner available |
| CI result | UNKNOWN | No verifiable run/status result |

No regression test result is labelled PASS or FAIL. The test suite itself must compile and produce output before any runtime red baseline can be claimed.

**Checkpoint 19.10 final status:** `NEGATIVE_REGRESSION_HARNESS_AUTHORED_EXECUTION_NOT_RUN`.

**Next exit criteria:** execute the two test files from a disposable checkout, retain the unmodified red baseline, resolve any harness/build errors without changing production behavior, then open a separate remediation proposal. RL-558 and RL-562 remain open until fixes and their independent verification pass.
