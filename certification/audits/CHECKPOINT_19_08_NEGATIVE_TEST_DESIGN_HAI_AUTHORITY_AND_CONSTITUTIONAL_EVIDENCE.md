# Checkpoint 19.08 — Negative-Test Design and Static Evaluation of HAI Authority and Constitutional Evidence

**Date:** 2026-11-10  
**Repository:** `Kimiti4/Tiannara`  
**Branch:** `audit/consolidated-findings-r0a-2026-10-31`  
**Source baseline:** `07b1a6b4e9871b297386595982683ee9512b8725`  
**Tree:** `17d9d632aebcd130e7a5deb46451c44dc9c47524`  
**Prior checkpoint:** `certification/audits/CHECKPOINT_19_07_INDEPENDENT_FALSE_SUCCESS_AND_HUMAN_AUTHORITY_VERIFICATION.md`  
**Status:** `STATIC_NEGATIVE_CASES_CONFIRMED — EXECUTION NOT RUN`  
**Mode:** Read-only source and test review; negative-test specification.

---

## 1. Executive result

Checkpoint 19.08 re-opened the pinned HAI request/router and ConstitutionalAuditor implementations, reviewed their checked-in tests, and evaluated the negative cases directly from the source logic.

**The two critical failure conditions are statically reproducible from the implementation, but no Elixir tests were executed.** The available GitHub connector provides repository read/write and CI-status inspection, but no repository shell or workflow-dispatch operation was available in this session. No test files were added, no workflow was dispatched, and no production code was changed.

The source review establishes:

1. An empty constitutional evidence map `%{}` is sufficient for the current auditor logic to produce all eight checks as passed and status `:compliant`. This is a source-derived evaluation of the function's defaults, not an executed Elixir result.
2. A ReviewRequest with nil or an unrecognized impact value is not rejected by the constructor. The router's catch-all routing clause classifies it as `:approved`.
3. The public `record_decision/3` API accepts any decision term, does not validate the review's current status, and does not use the GenServer caller identity. This means the implementation cannot substantiate the phrase “human approval” from the stored fields alone.
4. Existing HAI tests exercise the declared valid impact levels and ordinary decision calls; they do not cover invalid impact values, authenticated reviewer identity, replay, or invalid decision terms.
5. The checked-in Phase 4 “constitutional audit” test exercises `ReviewRequest.mandatory_review?/1` for valid levels, not `Tiannara.Evolution.ConstitutionalAuditor.audit/1` and not the ControlCenter evidence producer. Its own module documentation says it is not a functional test.

These defects remain open. The audit does not establish an external network exploit or prove a production deployment is currently running this code.

## 2. Pinned source and test evidence

| Path | Blob SHA | Role |
|---|---|---|
| `lib/tiannara/hai/domain.ex` | `4a8ffe859a2611de1a3df032509a431d1ee55163` | ReviewRequest construction and impact enum |
| `lib/tiannara/hai/review_router.ex` | `54a09fc1c2b143b61edecf0b615c229011b335fa` | Submission routing and decision recording |
| `lib/tiannara/evolution/constitutional_auditor.ex` | `c0063363b49a8294946a5b3c2ac0225856bfc047` | Eight constitutional checks and status aggregation |
| `lib/tiannara/control_center.ex` | `7e8c675714553eea58e73d642b3c3dc87bdc3960` | Evidence construction and audit scheduling |
| `test/tiannara/hai/review_router_test.exs` | `20844345ec28a63d844d0c53aea1200313b6473e` | Existing HAI tests |
| `test/tiannara/phase4/constitutional/constitutional_audit_test.exs` | `8ba31a6b4ab8c97b9460845003a7f3fb4080e0b6` | Phase 4 structural compliance tests |
| `mix.exs` | `7c46fc697d6da837fb3cf78b9bb7dad25b098946` | Root Elixir project/test configuration |

## 3. RL-558 — HAI negative-case evaluation

### 3.1 Constructor and route

The declared impact enum is:

`[:low, :medium, :high, :critical, :civilizational]`.

However, `ReviewRequest.new/1` pipes the default struct through `struct(attrs)`; it performs no enum validation and permits the caller to overwrite `:impact_level` with nil or an unrecognized value.

The router then applies these clauses:

- high/critical/civilizational → `:pending`
- medium → `:pending`
- every other value → `:approved`

Consequently, nil, an unknown atom, or a malformed value that survives struct construction reaches the automatic-approval clause. The request is also counted as non-mandatory because `mandatory_review?/1` only matches the three mandatory levels.

### 3.2 Decision recording

`handle_call({:decide, ...}, _from, state)` discards the caller identity. It writes the supplied `decision` directly into request status and `human_decision`, without:
- authenticating an actor;
- authorizing that actor as a human reviewer;
- validating the decision against `ReviewRequest.statuses/0`;
- requiring the request to be pending;
- preventing repeat decisions or decision replay;
- checking whether the request's impact level mandates human review.

A GenServer caller being able to invoke a local function is not evidence of human identity. The current stored `human_decision` field therefore cannot, by itself, prove that a human made the decision.

### 3.3 Negative test matrix

| Test ID | Input / action | Required result | Current source-derived expectation | Execution |
|---|---|---|---|---|
| HAI-N01 | Submit request with impact nil | Reject with validation error | Constructor accepts; router catch-all approves | NOT RUN |
| HAI-N02 | Submit unknown atom impact | Reject with validation error | Catch-all approves | NOT RUN |
| HAI-N03 | Submit malformed string impact | Reject; no coercion to approval | If struct accepts value, catch-all approves | NOT RUN |
| HAI-N04 | Omit impact level | Reject or explicit UNKNOWN/pending | Default nil is not validated; catch-all approves | NOT RUN |
| HAI-N05 | Submit high/critical/civilizational | Pending until authorized decision | Existing route returns pending | NOT RUN |
| HAI-N06 | Record arbitrary decision term | Reject invalid decision | Current handler stores arbitrary term | NOT RUN |
| HAI-N07 | Record decision from unauthorized actor | Reject and preserve pending state | Caller identity is ignored | NOT RUN |
| HAI-N08 | Decide already resolved request | Reject transition | Current handler overwrites existing status | NOT RUN |
| HAI-N09 | Replay prior approval | Reject duplicate/stale decision | No replay/state-transition check | NOT RUN |
| HAI-N10 | Decision lacks authenticated reviewer/provenance | Reject; no human-approved state | Current API accepts rationale string only | NOT RUN |

**Required HAI invariant:** an unknown or missing impact value cannot authorize anything. A high-impact request remains pending until a valid decision is recorded by an authenticated, authorized human reviewer, bound to that exact request and decision version.

### 3.4 Test-suite gap

The current `review_router_test.exs` checks valid low, high, critical and civilizational impact routing. Its decision tests call `record_decision/3` with an approval/rejection and rationale string and assert the stored fields. They do not supply an authenticated actor or test the negative cases above.

The Phase 4 constitutional test checks that the three valid high-impact levels satisfy `ReviewRequest.mandatory_review?/1`; it does not test malformed levels or the router's catch-all branch.

## 4. RL-562 — ConstitutionalAuditor negative-case evaluation

### 4.1 Missing evidence is treated as safe evidence

The auditor uses `Map.get/3` defaults that make missing fields appear safe:
- hidden uncertainty defaults to zero;
- mandatory reviews completed and required default to zero;
- lineage violations default to zero;
- safety violations default to zero;
- objective alignment defaults to 1.0;
- coupling violations default to zero;
- evolutions deployed and validations default to zero.

Two ratios also default to 1.0 when their denominators are zero:
- verifications/capabilities when capabilities are zero;
- validations/evolutions when evolutions are zero.

The human-judgment check passes when mandatory reviews required is zero. The auditor then sets status to `:compliant` when all eight checks pass.

**Source-derived negative case:** passing an empty map `%{}` supplies no evidence, yet every default satisfies its check. The source therefore permits `:compliant` with no evidence fields at all. This is not an executed test result; it follows directly from the inspected implementation.

### 4.2 ControlCenter is a synthetic evidence producer

ControlCenter constructs the input map itself and hardcodes the review counts, hidden uncertainty, lineage/safety/coupling violations and evolution counts to zero, and objective alignment to 0.9. The values are not linked to an authoritative evidence ledger or independent verification result in this function.

The periodic audit stores the auditor's result as `last_audit`. This confirms a scheduled local status-production path. A downstream release/deployment consumer of this status remains UNKNOWN and is not claimed here.

### 4.3 Negative test matrix

| Test ID | Input / action | Required result | Current source-derived expectation | Execution |
|---|---|---|---|---|
| CON-N01 | Empty map `%{}` | UNKNOWN/incomplete, not compliant | All default checks pass; compliant | NOT RUN |
| CON-N02 | Omit mandatory-review fields | UNKNOWN/incomplete | 0/0 treated as passed | NOT RUN |
| CON-N03 | Omit safety/lineage/uncertainty fields | UNKNOWN/incomplete | Missing values treated as zero | NOT RUN |
| CON-N04 | Zero capabilities and zero verifications | UNKNOWN until evidence source confirms denominator | Ratio defaults to 1.0 | NOT RUN |
| CON-N05 | Zero deployed evolutions and zero validations | UNKNOWN until evidence source confirms denominator | Ratio defaults to 1.0 | NOT RUN |
| CON-N06 | Supply stale evidence | Reject or UNKNOWN | No freshness validation in auditor input contract | NOT RUN |
| CON-N07 | Supply tampered/unsigned evidence | Reject or UNKNOWN | No signature/provenance validation in auditor | NOT RUN |
| CON-N08 | Supply evidence for a different system snapshot | Reject or UNKNOWN | No snapshot binding in auditor | NOT RUN |
| CON-N09 | Provider unavailable/throws | UNKNOWN, never zero violations | ControlCenter currently supplies hardcoded values | NOT RUN |
| CON-N10 | Contradictory evidence sources | UNKNOWN/non-compliant pending resolution | No contradiction handling in auditor | NOT RUN |
| CON-N11 | Explicit safety violation > 0 | Non-compliant | Existing check should fail | NOT RUN |
| CON-N12 | Explicit mandatory reviews outstanding | Non-compliant | Existing check should fail | NOT RUN |

**Required constitutional invariant:** absence of evidence is not evidence of absence. No compliance status is possible unless every required evidence source returns a valid, current, independently verifiable result bound to the same audited snapshot.

## 5. Proposed executable test structure

The following are test requirements, not files committed by this checkpoint.

### 5.1 HAI unit tests

Add a dedicated invalid-impact describe block to `ReviewRouterTest`:
- constructor validation tests for nil, omitted, unknown atom and malformed string;
- router-boundary tests that bypass the constructor and ensure malformed input still cannot approve;
- decision enum validation;
- transition tests for pending → approved/rejected/modified/deferred/expired only;
- rejection of repeat, replayed and stale decisions;
- reviewer identity/authorization checks using a test identity provider;
- event/audit assertions proving actor, request digest, decision, timestamp and policy version are recorded.

The current public API `record_decision/3` has no actor parameter. The eventual design should accept a trusted authenticated principal or a signed decision envelope; it must not trust a caller-provided `human: true` flag.

### 5.2 ConstitutionalAuditor unit tests

Add a dedicated `constitutional_auditor_test.exs` suite that tests:
- empty map;
- each missing mandatory field independently;
- missing and zero denominators;
- stale, invalid, mismatched and contradictory evidence;
- explicit nonzero violations;
- valid evidence for one exact snapshot;
- provider errors and timeouts.

The auditor should consume typed evidence results with explicit states such as `verified`, `failed`, `unknown`, and `not_run`. It should not infer a zero count from a missing field. The aggregate status must be tri-state or richer; `:compliant` is permitted only when every mandatory check is verified.

### 5.3 ControlCenter integration tests

The audit producer should be injected with test evidence providers. Tests must prove:
- any missing provider prevents compliance;
- provider errors never become zero;
- all evidence binds to the same snapshot digest;
- a forged or stale evidence bundle cannot pass;
- a valid complete bundle can pass only after independent verification.

Do not use the current ControlCenter-generated literal counts as the test oracle.

## 6. Execution and environment record

| Activity | Result |
|---|---|
| Re-fetch pinned HAI and auditor source | DONE |
| Re-fetch existing HAI and constitutional test files | DONE |
| Static negative-case evaluation | DONE |
| Elixir `mix test` | NOT RUN |
| New negative tests committed | NO |
| Root application boot | NOT RUN |
| GenServer calls against a live process | NOT RUN |
| CI workflow dispatch | NOT AVAILABLE through the connected GitHub operations in this session |
| Production changes | NONE |
| Runtime/deployment/physical actuation | NONE |

This checkpoint must not be interpreted as a green test run or remediation.

## 7. Remediation gate and ordering

1. **RL-558:** validate impact enum at both constructor and router boundary; remove catch-all approval; bind every decision to authenticated reviewer identity, request digest, allowed decision enum and valid lifecycle transition.
2. **RL-562:** replace synthetic ControlCenter counters with authoritative evidence providers; make missing, stale, failed and contradictory evidence UNKNOWN/non-compliant; require independent evidence verification and snapshot binding.
3. Add the negative suites above and execute them in an isolated repository environment.
4. Only after unit and integration tests pass, trace and test all downstream approval/compliance consumers.
5. Obtain the appropriate human/Constitutional Council ratification before remediation affecting governance or constitutional authority.

No code remediation is authorized by this report. ControlCenter and CEL do not become constitutional authorities by producing an audit status; the Constitutional Council remains the higher authority.

## 8. Disposition

- RL-558: OPEN / CRITICAL — invalid impact can statically route to `:approved`; decision provenance/authentication is also insufficient.
- RL-562: OPEN / CRITICAL — missing evidence can statically satisfy all checks; ControlCenter supplies synthetic evidence inputs.
- New finding IDs: none; existing findings strengthened.
- Tests executed: none.
- Test cases specified: HAI-N01–N10 and CON-N01–N12.
- Production changes: none.
- CI/build/runtime: not run.
- Release/deployment consumer reachability: UNKNOWN.

**Final status:** `STATIC_NEGATIVE_CASES_CONFIRMED — EXECUTION NOT RUN`.

**Next checkpoint 19.09:** implement no production changes. First obtain an isolated checkout/runtime capable of executing the focused ExUnit tests. Run the new negative cases against the current implementation as a red baseline, capture exact failures, then run the tests against a separately approved remediation branch. Do not merge failing regression tests into the production branch as though they were passing.
