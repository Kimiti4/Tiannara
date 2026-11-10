# Checkpoint 19.09 — Execution Gate and Negative-Test Harness Readiness

**Date:** 2026-11-11  
**Repository:** `Kimiti4/Tiannara`  
**Branch:** `audit/consolidated-findings-r0a-2026-10-31`  
**Prior audit head:** `9984d86325a43d18a75f10c7531faadb3826bb80`  
**Prior checkpoint:** `certification/audits/CHECKPOINT_19_08_NEGATIVE_TEST_DESIGN_HAI_AUTHORITY_AND_CONSTITUTIONAL_EVIDENCE.md`  
**Status:** `EXECUTION_GATE_BLOCKED_REMOTE_RUNNER_UNAVAILABLE`  
**Mode:** Read-only execution-readiness audit; no production or test-source modifications.

---

## 1. Executive result

Checkpoint 19.09 attempted to move the critical HAI authority and constitutional-evidence findings from static negative-case design to executable baseline tests.

**The execution gate remains blocked by the available session's lack of a repository shell, Elixir runtime, or GitHub Actions dispatch/list-runs operation.** The repository and relevant test configuration were inspected through GitHub read operations. No Elixir command, test, compile, application boot, workflow dispatch, or deployment was executed.

The checkpoint did establish a reproducible local execution route and identified test-isolation constraints. It does not establish that the code passes or fails dynamically.

**RL-558 and RL-562 remain CRITICAL / OPEN.** No finding is closed by this checkpoint.

## 2. Repository and evidence integrity

The following prior checkpoint artifacts were re-fetched from the audit branch and their blob identities matched the recorded values:

| Artifact | Path | Blob SHA |
|---|---|---|
| 19.08 report | `certification/audits/CHECKPOINT_19_08_NEGATIVE_TEST_DESIGN_HAI_AUTHORITY_AND_CONSTITUTIONAL_EVIDENCE.md` | `fb2ad79e4895bf1ba81c15d6e794ea055e2b0b31` |
| R0-A register | `audits/Tiannara_AI_Audit_Findings_R0-A_to_Current_2026-10-31.md` | `d2d5c18a84e7ebf03af5b4cf2bbb46a7c14e4911` |

The preceding register commit was fetched and verified:

- Commit: `9984d86325a43d18a75f10c7531faadb3826bb80`
- Message: `Audit: synchronize R0 register through Checkpoint 19.08`
- Branch search still returns `audit/consolidated-findings-r0a-2026-10-31`.

The inspected source/test/configuration blobs were:

| Path | Blob SHA |
|---|---|
| `mix.exs` | `7c46fc697d6da837fb3cf78b9bb7dad25b098946` |
| `forward_provenance/mix.exs` | `7909bef068e8f2dd9a7d1fcaf9bca9e3bf8b1244` |
| `config/test.exs` | `2bdf2490cc5fc2a7bb7f6eaef507552bcce0f1f8` |
| `test/test_helper.exs` | `97695a5cc48d0f9ad94c43f47567a549079056e8` |
| `test/tiannara/hai/review_router_test.exs` | `20844345ec28a63d844d0c53aea1200313b6473e` |
| `test/tiannara/phase4/constitutional/constitutional_audit_test.exs` | `8ba31a6b4ab8c97b9460845003a7f3fb4080e0b6` |

## 3. Execution-path capability check

### 3.1 Available and unavailable capabilities

| Capability | Result | Meaning |
|---|---|---|
| Read repository files at the audit branch | AVAILABLE | Relevant source and test configuration could be inspected. |
| Fetch commit metadata/diff | AVAILABLE | Prior audit commit identity was confirmed. |
| Read combined commit status | EMPTY | GitHub returned `statuses: []` for the 19.08 register commit; this is not a green CI result. |
| Fetch commit-associated workflow runs | EMPTY | The exposed wrapper documents that it filters to pull-request-triggered runs and returns only its first page. An empty result does not prove that no push- or manually-triggered workflow exists. |
| Enumerate all Actions runs / workflow definitions through a dedicated action | NOT EXPOSED | No general run-list or workflow-enumeration action was available. |
| Dispatch a workflow | NOT EXPOSED | No workflow-dispatch action was available. |
| Execute shell / `mix` / `elixir` in the repository | NOT EXPOSED | No remote repository runtime was available. |
| Download workflow logs/artifacts | AVAILABLE ONLY WHEN RUN IDS/ARTIFACT IDS EXIST | This is retrieval, not workflow execution. No qualifying run was identified in this check. |

**CI conclusion:** no CI success or failure can be claimed. The evidence is `NO_VERIFIABLE_CI_RESULT`, not `CI_FAILED` and not `CI_PASSED`.

## 4. Build and test prerequisites established from source

### 4.1 Runtime and dependency constraints

- The root `mix.exs` declares Elixir `~> 1.15`.
- The local path dependency `forward_provenance` declares Elixir `~> 1.18`.
- The effective project runtime floor is therefore Elixir 1.18 or later within the compatible major-version range.
- `forward_provenance` is a local path dependency, not a separately fetched Hex/Git dependency; the checkout must include that directory.
- Root project dependencies include Phoenix, Plug/Cowboy, Gnat, Nx and other packages; dependency resolution and compilation have not been tested in this checkpoint.

### 4.2 Test-mode configuration

The checked-in `config/test.exs` establishes:

- Phoenix endpoint server disabled by default.
- `:test_mode` enabled and LLM fixtures/mock mode enabled.
- DETS and storage roots under `test_data/dets/<test_run_id>` and `test_data/storage/<test_run_id>`.
- NATS test connection configured for `nats://localhost:4222`.
- Test-specific IRD and topology mocks and adjusted timeout/topology/conservation values.

This proves the intended test configuration values, not that every startup path is isolated from external services. The application's actual boot behavior and NATS connectivity remain unverified.

### 4.3 Test-data deletion/isolation constraint

`test/test_helper.exs` removes the configured DETS run root and storage run root before the suite and removes those same roots after the suite. The default `config/test.exs` run ID combines wall-clock nanoseconds, OS PID and a monotonic unique integer. A non-empty `TEST_PARTITION` overrides that generated ID.

Execution safety requirements:

1. Use a disposable clean checkout/worktree for the first dynamic attempt.
2. Leave `TEST_PARTITION` unset for the initial attempt, allowing the configured unique run ID.
3. Do not point `TEST_PARTITION`, `:dets_base_path`, or `:storage_base` at any existing runtime, soak, or user data directory.
4. Capture the exact commit, runtime versions, command, exit code and complete test output.
5. Do not start a production release or change the production configuration to make tests pass.

## 5. Existing test coverage checked

### HAI ReviewRouter

The existing `test/tiannara/hai/review_router_test.exs`:

- Expects ReviewRouter to be started by the application.
- Resets its GenServer state in setup.
- Exercises valid `:low`, `:high`, `:critical` and `:civilizational` impact levels.
- Exercises ordinary approved/rejected decision recording and unknown review IDs.

It does **not** currently establish rejection of nil/unknown/malformed impact values, authenticated reviewer identity, invalid decision enums, valid lifecycle transitions, replay protection or concurrent-decision safety.

### Constitutional audit

The existing Phase 4 constitutional test identifies itself as a structural compliance test, not a functional test. The inspected cases do not execute the `ConstitutionalAuditor.audit/1` and `ControlCenter` evidence-production path implicated by RL-562.

The existing test files are useful as a baseline, but their presence is not evidence that either critical defect is covered.

## 6. Controlled execution sequence for the first available local runner

Run this only from a disposable checkout of the audit branch. Do not run against a production or soak working tree.

```bash
git switch audit/consolidated-findings-r0a-2026-10-31
git rev-parse HEAD
git status --short
elixir --version
mix --version
mix deps.get
MIX_ENV=test mix test test/tiannara/hai/review_router_test.exs
```

Record the exact HEAD and clean/dirty state before dependency resolution and before tests. For the first attempt, do not set `TEST_PARTITION`.

Then run the existing constitutional baseline modules separately, preserving each exit code and output:

```bash
MIX_ENV=test mix test test/tiannara/phase4/constitutional/constitutional_audit_test.exs
MIX_ENV=test mix test test/tiannara/constitution/constitutional_invariant_suite_test.exs
MIX_ENV=test mix test test/tiannara/autonomy/constitutional_validator_test.exs
```

These are baseline checks only. They do not replace new negative regression tests against the actual HAI and ConstitutionalAuditor paths.

## 7. Required red-baseline regression matrix

Before any production remediation, add isolated regression tests in a dedicated test/remediation branch and run them against the unmodified implementation. The expected outcome is a demonstrated red baseline for each reproduced defect, not a test that passes by weakening its assertions.

### RL-558 — HAI authority boundary

At minimum, test:

- Nil, missing, unknown atom, string and malformed impact values cannot route to approval.
- Unknown impact values produce a validation error or explicit UNKNOWN/mandatory-review state.
- A caller without an authenticated, authorized reviewer identity cannot decide a pending review.
- Unsupported decision terms are rejected.
- Decisions from invalid lifecycle states and repeated/replayed decisions are rejected.
- Concurrent decisions cannot produce multiple accepted outcomes.
- Accepted decisions retain independently verifiable reviewer identity, authorization context, timestamp and rationale.

### RL-562 — constitutional evidence boundary

At minimum, test:

- Empty evidence map and omitted evidence fields cannot produce `:compliant`.
- Missing, unavailable, stale, malformed, tampered or snapshot-mismatched evidence produces UNKNOWN/incomplete or non-compliant status.
- Zero denominators cannot silently yield a passing ratio.
- Missing evidence providers cannot be interpreted as zero violations.
- Evidence provenance, freshness, digest/signature and common snapshot binding are checked before compliance can be asserted.
- ControlCenter cannot manufacture evidence values or report an audit as authoritative when providers have not supplied verifiable evidence.

Tests must assert observable return values and state transitions. Tests must not rely only on source text matching, mocked assertions that restate the implementation, or status labels emitted by the component under test.

## 8. Findings and disposition

| Finding | Severity | Checkpoint 19.09 disposition |
|---|---|---|
| RL-558 — invalid HAI impact values can auto-approve; decision API lacks authenticated actor/lifecycle enforcement | CRITICAL | OPEN — static negative design retained; dynamic confirmation still unavailable |
| RL-562 — synthetic/defaulted constitutional evidence can report compliance without sufficient evidence | CRITICAL | OPEN — static negative design retained; dynamic confirmation still unavailable |
| Test runner access | EXECUTION BLOCKER | Remote shell/Elixir runtime/workflow dispatch unavailable in this session |
| CI evidence | UNKNOWN | No verifiable passing or failing run retrieved |

No tests were added, no source implementation was modified, no test or compile command was run, no workflow was dispatched, and no deployment or physical actuation occurred.

**Checkpoint 19.09 final status:** `EXECUTION_GATE_BLOCKED_REMOTE_RUNNER_UNAVAILABLE`.

**Exit criteria for the next execution checkpoint:** obtain test output from a disposable checkout on a compatible Elixir 1.18+ runtime, record the unmodified red/green regression results, distinguish environment failures from product failures, then prepare remediation separately. RL-558 and RL-562 must remain open until their regression tests pass and the resulting authorization/evidence paths are independently reviewed.
