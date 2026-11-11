# Checkpoint 19.14 — Source-Level Failure Trace and Remediation Specification

**Date:** 2026-11-11  
**Repository:** `Kimiti4/Tiannara`  
**Audit branch:** `audit/consolidated-findings-r0a-2026-10-31`  
**Pinned source:** regression PR head `8f03c32ad10fa9ad654f987d30dde1bc9a53df5d`  
**Validation PR:** [#13 — CP19.10 HAI and constitutional negative regression baseline](https://github.com/Kimiti4/Tiannara/pull/13)  
**Root CI run:** [42931719446](https://github.com/Kimiti4/Tiannara/actions/runs/42931719446)  
**Status:** `SOURCE_TRACE_COMPLETE_REMEDIATION_SPECIFICATION_READY_NO_PRODUCTION_CHANGE`  
**Mode:** Read-only source tracing, call-site search, CI log analysis and remediation specification.

---

## 1. Executive result

Checkpoint 19.13 retrieved the completed root ExUnit log. The command `MIX_ENV=test mix test --max-failures 25 --color` completed in 203.4 seconds with:

```text
79 properties, 2535 tests, 11 failures, 2 skipped
Process completed with exit code 2.
```

**All 11 failures are the 11 CP19.10 negative-regression assertions:** four ConstitutionalAuditor cases for RL-562 and seven HAI ReviewRouter cases for RL-558. The failure messages match the expected unsafe source behavior. They are assertion-level failures, not checkout, dependency, compilation, application-startup or test-discovery failures.

The separate required jobs passed:
- `tiannara_runtime`: 40 properties, 1,863 tests, 0 failures, 6 excluded.
- `tiannara_audit`: 13 tests, 0 failures.
- Lineage regression: 11 tests, 0 failures.
- Compile, dependency retrieval, test-placement guard and test-environment startup passed.
- Cross-platform Ubuntu, macOS and hash comparison passed on the separate cross-platform workflow. That workflow used OTP 27, not the OTP 28 root-regression environment.
- The non-blocking runtime quarantine job had four distinct failures; they are unrelated to the 11 CP19.10 failures.

**Decision:** `RED_BASELINE_CONFIRMED_11_OF_11_EXPECTED_ASSERTIONS_FAIL`.

The source trace below identifies direct causes, additional affected call paths and the minimum conditions for safe remediation. No production remediation is applied in this checkpoint.

## 2. Pinned source and evidence identities

All source below was re-fetched from `audit/cp19-10-red-baseline` (PR head `8f03c32ad10fa9ad654f987d30dde1bc9a53df5d`).

| Artifact | Path | Blob SHA |
|---|---|---|
| HAI router | `lib/tiannara/hai/review_router.ex` | `54a09fc1c2b143b61edecf0b615c229011b335fa` |
| HAI domain types | `lib/tiannara/hai/domain.ex` | `4a8ffe859a2611de1a3df032509a431d1ee55163` |
| Constitutional auditor | `lib/tiannara/evolution/constitutional_auditor.ex` | `c0063363b49a8294946a5b3c2ac0225856bfc047` |
| Control Center | `lib/tiannara/control_center.ex` | `7e8c675714553eea58e73d642b3c3dc87bdc3960` |
| Evolution engine | `lib/tiannara/evolution/evolution_engine.ex` | `e433b1f519af754a6fc4a0b273e3577fbd550eec` |
| ToolForge engine | `lib/tiannara/tool_forge/tool_forge_engine.ex` | `72f96da09f40a34f56b3f8bce31acee8233f0ad4` |
| Autonomy verification | `scripts/verify_autonomy.exs` | `c6699ce22eaa3eae3316d8ea55533ccdcfd0f712` |
| Interactive review manager | `lib/tiannara/hai/collaboration/interactive_review_manager.ex` | `70ff47b5dc061fd65db7a74fdc24804d7b8d5e8a` |
| HAI event adapter | `lib/tiannara/hai/events.ex` | `561214b4de19c7a30184b3563c0296c1a94ce4a2` |
| HAI red-baseline tests | `test/tiannara/audits/checkpoint_19_10_hai_negative_regression_test.exs` | `2355ca1f871f39134a77b5176a7ee4e3961862c0` |
| Constitutional red-baseline tests | `test/tiannara/audits/checkpoint_19_10_constitutional_evidence_negative_regression_test.exs` | `89abde5feb3568ae3c7eb943676eb22f218428d7` |

## 3. RL-558 — HAI authority enforcement

**Severity:** CRITICAL  
**Status:** OPEN — runtime reproduced, source causes confirmed.  
**Scope:** impact classification, review creation, decision authorization, decision-state transitions and alternate HAI review manager.

### 3.1 Direct cause A — invalid impact levels become approvals

In `lib/tiannara/hai/domain.ex:9-24`, `ReviewRequest` declares the allowed impact levels, but `new/1` at lines 15-20 does not validate against that list. It builds defaults and merges caller attributes with `struct(attrs)`. Missing, nil, unknown-atom and string impact values are therefore not rejected by the constructor.

In `lib/tiannara/hai/review_router.ex:46-61`, the submit handler constructs the request and routes on `request.impact_level`. The routing clauses at lines 114-116 explicitly route high/critical/civilizational to pending, medium to pending, and **every other value to approved**.

Consequences:
- Missing, nil, unknown atom and string impact values all reach the catch-all approval path.
- `ReviewRequest.mandatory_review?/1` returns false for those values, so the event payload also says the review is not mandatory.
- The four CI failures at lines 3255–3287 of the root-suite log correspond to these four cases.

The constructor also merges all struct fields from caller attributes. That allows caller-supplied values for system-owned fields such as request ID, timestamps, human decision, rationale and resolution time. The router overwrites `status` with its computed route, but it does not establish ownership of the other lifecycle fields. A caller-controlled request ID can also collide with an existing key in the router map. Request creation must not accept server-owned identity or lifecycle fields.

### 3.2 Direct cause B — decision caller and transition are not authorized

The public `record_decision/3` API at `review_router.ex:20-22` accepts only review ID, decision and rationale. The GenServer handler at lines 65-86 binds the caller as `_from`, then:
- checks only whether the review ID exists;
- does not verify a reviewer identity, role, capability or authorization proof;
- does not restrict decisions to the declared status list;
- does not require the request to be pending;
- does not reject a previously resolved review;
- writes any supplied decision value into both `status` and `human_decision`;
- emits a resolution event and returns `:ok`.

This explains the three remaining HAI regression failures:
- a caller without reviewer identity resolves a mandatory review;
- an unsupported decision value is accepted;
- a conflicting second decision overwrites the first.

The decision counters are incremented only for recognized values, but the state mutation and event happen for unrecognized values too. A repeated decision can therefore overwrite the current state and produce additional events/counter changes. The current in-memory review map is initialized empty in `init/1`; no durable review-record store is established by this module. HAI event delivery is best-effort in `events.ex:18-48`, so event emission is not a substitute for authorization or durable state transition.

### 3.3 Alternate HAI path — InteractiveReviewManager

The separately supervised `Tiannara.HAI.Collaboration.InteractiveReviewManager` has the same trust-boundary pattern:
- `open_session/3` accepts `reviewer_id` as caller-supplied data (`interactive_review_manager.ex:11-13,45-71)); it does not resolve or validate that identity against an authenticated principal.
- `record_decision/4` has no reviewer identity or authorization proof (`15-17)); its handler ignores the GenServer caller as `_from` and closes any matching session without checking that it is still active (`74-123)).
- A second decision can overwrite a closed session.
- `add_comment/3` also trusts a caller-supplied reviewer ID (`19-21,127-141)).

These manager cases are **not among the 11 executed CP19.10 tests**. They are additional source-confirmed HAI authority surfaces that must be included in the remediation and regression matrix. The module is started by Control Center alongside ReviewRouter.

### 3.4 Production wiring and adjacent bypasses

Repository code search on the indexed default branch found the direct `ReviewRouter.submit_review/1` and `record_decision/3` invocations in the existing ReviewRouter tests, but no production caller. ReviewRouter is started from Control Center; starting a service is not proof that production decisions pass through it. This is a bounded code-search result, not proof that no dynamic/reflection or external caller exists.

Two adjacent production paths are important:

1. **ToolForge / RL-559 (already separately registered, HIGH, ASC-gated).** `tool_forge_engine.ex:102-118` requires `:ok` from `request_human_review/2`, then logs “Human review passed”. The helper at lines 129-143 merely constructs and discards a medium-impact `ReviewRequest`; it never submits it to ReviewRouter or waits for a reviewer. Its rescue branch also returns `:ok`. This is a false human-review acknowledgement, not one of the seven RL-558 regression assertions. Keep RL-559 separately tracked and open.

2. **Autonomy verification.** `scripts/verify_autonomy.exs:147-155` constructs a critical request and calls only `ReviewRequest.mandatory_review?/1`. It does not submit a review or prove an authorized reviewer can resolve one. Its “Human review gating enforced” check is therefore a type/predicate check, not an end-to-end enforcement test.

The existing ReviewRouter test at `test/tiannara/hai/review_router_test.exs:7-18` and the new negative test at `test/tiannara/audits/checkpoint_19_10_hai_negative_regression_test.exs:7-24` both mutate the application-owned singleton using `:sys.replace_state/2` and do not restore the prior state in teardown. The new test uses `async: false`, but still changes shared application state. This is a **test isolation defect** to fix independently; it does not explain away the seven observed product assertion failures.

### 3.5 RL-558 remediation requirements

Do not patch only the four catch-all cases. Implement one canonical HAI review policy and make every HAI entry point use it.

**Request ingress**
- Validate impact against the explicit allowlist before constructing or storing a request.
- Missing, nil, malformed, unknown and type-confused impact values must return an explicit validation error or unresolved/unknown state; they must never route to approval.
- Build request IDs, timestamps, status, resolution fields and decision metadata internally. Accept only caller-owned request fields from an allowlist.
- Validate required source, decision type, summary and evidence metadata; validate confidence/uncertainty ranges and all field types.
- Define the low/medium/high/critical/civilizational routing policy explicitly. Preserve any informational auto-approval only for explicitly valid classifications and only where the constitutional policy permits it.

**Decision authorization**
- Require an authenticated principal and a verifiable authorization capability from the trusted identity/authorization layer. A free-form caller-supplied reviewer ID or rationale is not proof.
- Verify reviewer role/scope against review impact and decision type. Define separation-of-duties and multi-person rules for critical/civilizational decisions before implementation.
- Persist actor identity, authorization evidence reference, policy version, decision, rationale, timestamp and review ID in an immutable audit record. Do not persist secret tokens.

**State machine and replay**
- Define allowed transitions; a decision is accepted only for an eligible pending review.
- Reject unsupported decisions and invalid transitions.
- A resolved request is terminal. Exact duplicate submissions may be idempotent only when the same idempotency key and payload are proven; conflicting replays must be rejected without overwriting the original decision.
- Keep final-state projections and counters consistent with the immutable decision history.
- Make the canonical review path durable and fail closed if its authoritative store/audit channel is unavailable.

**Single-path integration**
- Route production approval flows through one canonical service. Integrate or retire the parallel InteractiveReviewManager path; it must not become a weaker alternative.
- ToolForge must wait for a real review decision and fail closed when review cannot be created, assigned, authorized or completed. Merely constructing a ReviewRequest is not review.
- Change the autonomy verification to execute a real routed request and prove the denied/approved decisions with authenticated test principals; a predicate-only check is insufficient.

## 4. RL-562 — constitutional evidence integrity

**Severity:** CRITICAL  
**Status:** OPEN — runtime reproduced, source causes confirmed.  
**Scope:** required evidence completeness, unknown-state semantics, arithmetic validity, evidence provenance and production gate inputs.

### 4.1 Direct cause — missing evidence is replaced with passing defaults

In `lib/tiannara/evolution/constitutional_auditor.ex:3-29`, `audit/1` accepts any map and returns `:compliant` whenever all eight boolean checks pass. There is no required-field/schema gate and no evidence completeness state.

The check implementations make absence look safe:

| Check | Source lines | Missing-value behavior |
|---|---:|---|
| Capability verification | 37-42 | Counts default to 0; zero capabilities produces ratio 1.0 and passes |
| Uncertainty visibility | 53-63 | Missing hidden-uncertainty count defaults to 0 and passes |
| Human judgment | 66-78 | Missing required/completed review counts become 0/0 and pass |
| Lineage integrity | 81-92 | Missing violation count defaults to 0 and passes |
| Safety constraints | 94-105 | Missing violation count defaults to 0 and passes |
| Objective alignment | 107-118 | Missing score defaults to 1.0 and passes |
| Modularity | 120-131 | Missing coupling violations default to 0 and pass |
| Evolution/validation balance | 133-147 | Missing counts become 0/0; zero evolutions produces ratio 1.0 and passes |

Therefore `audit(%{})` can report all eight checks passed and `:compliant`. Partial maps can do the same. These four cases are confirmed by the root-suite failures at lines 3255–3287 of the root log.

`compliant?/1` at lines 31-35 simply calls the same auditor and checks its status, so it inherits the same defect.

### 4.2 Production caller A — ControlCenter supplies synthetic values

`lib/tiannara/control_center.ex:281-304` constructs the audit input. Only the capability count and health-history length come from ControlCenter state. It supplies fixed values for hidden uncertainty, mandatory review counts, lineage violations, safety violations, objective alignment and coupling violations; evolution counts are also hard-coded to 0/0.

The “verifications_completed” input is the length of health-history, not a demonstrated count of independently verified deployed capabilities. The auditor therefore receives synthetic zero/score values and a semantically mismatched verification count, then stores the result as `last_audit`.

This confirms and expands RL-562's earlier source finding: the root production caller manufactures passing audit inputs rather than deriving each constitutional check from an authoritative evidence source.

### 4.3 Production caller B — EvolutionEngine's circular gate

`lib/tiannara/evolution/evolution_engine.ex:84-119` audits the state and proceeds with an evolution cycle if the auditor says compliant. Its `build_system_state/1` at lines 122-136:
- uses internal `total_evolutions` as deployed capabilities;
- uses internal `total_validations` as completed verifications;
- hard-codes uncertainty, reviews, lineage, safety and coupling to zero;
- hard-codes objective alignment to 0.9;
- reuses the same internal counters for evolution and validation counts.

At initialization those counters are both zero. The auditor treats zero/zero as a 1.0 ratio and permits the first cycle. After a “compliant” result, the same branch increments both counters together. This is self-generated evidence, not independent validation. The gate can keep satisfying itself without proving an externally verifiable validation event.

### 4.4 Additional false assurance surface

`scripts/verify_autonomy.exs:84-104` passes hand-authored 30/30 counts, zeros and a fixed 0.9 objective score to the auditor, then labels the result “Constitutional constraints enforced”. This is a happy-path fixture, not production evidence. It must not be treated as certification of the ControlCenter or EvolutionEngine evidence pipelines.

Existing tests in `test/tiannara/evolution/evolution_test.exs:85-148` cover a fully populated compliant map and two explicit negative conditions, but do not test empty maps, missing fields or zero denominators. The 4 CP19.10 cases fill that gap.

### 4.5 RL-562 remediation requirements

**Evidence contract**
- Replace untyped arbitrary maps with a versioned evidence envelope and an explicit required-field schema for all eight principles.
- Each evidence value must identify its source, subject/system snapshot, measurement time, provenance/artifact digest and verifier. Verify freshness, subject binding and integrity before using it.
- Reject malformed types, negative counts, invalid numeric ranges, mismatched snapshots and provider errors as invalid/incomplete evidence; do not silently coerce them.

**Three-state evaluation**
- Represent each check as `PASS`, `FAIL` or `UNKNOWN` (or an equivalent tagged type). Missing, unavailable, stale, unverifiable or zero-denominator evidence is `UNKNOWN`, not `PASS`.
- A zero denominator must not produce a passing 1.0 ratio. Define whether the check is not applicable only through an explicit, evidence-backed policy state.
- Overall `:compliant` requires every mandatory check to be `PASS` with complete verified evidence. Any critical `UNKNOWN` blocks the gate; it cannot be averaged away by a compliance percentage.
- Keep completeness, verification status and compliance status separate in the returned result. A numeric compliance rate must never hide unknown checks.

**Production evidence providers**
- ControlCenter must consume actual health, uncertainty, review, lineage, safety, objective-alignment and coupling evidence from authoritative providers. Remove hard-coded zeroes and fixed scores from production gate inputs.
- EvolutionEngine must consume independent validation artifacts tied to the exact evolution candidate and must not use its own counters as proof of its own gate. A missing validator/provider or unverified artifact must halt promotion/evolution.
- Test fixtures and simulated evidence must be explicitly typed and excluded from production acceptance paths.

**Required regression tests**
- Empty and partial evidence maps; every required field omitted individually; wrong type, negative count and out-of-range score.
- Zero/zero and positive/zero denominators for both ratio checks.
- Stale, tampered, mismatched-subject, untrusted-source and unavailable-provider evidence.
- ControlCenter integration where one provider is unavailable or reports UNKNOWN; no compliant status may be stored.
- EvolutionEngine integration proving a candidate cannot pass based only on counters it increments itself.
- Exact-candidate, independently verifiable evidence for every PASS.

## 5. Test-harness and scope qualifications

1. The CP19.10 HAI test module and the existing ReviewRouter test both replace state inside the application-owned named GenServer without restoring it. The tests should use an isolated server/registration or a guaranteed snapshot-and-restore fixture. This is separate from product remediation.
2. The four non-blocking quarantine failures remain separate: two ColdIgnition tests and two Omega `already_started` tests. Do not conflate them with the 11 root-suite failures.
3. Cross-platform OTP 27 success does not independently reproduce the OTP 28 root regression run.
4. The code search used for caller discovery is bounded to GitHub's indexed default branch; the direct files were read at the exact regression PR head. “No production caller found” is not a proof of global nonexistence.
5. The separate `TiannaraOS.Governance.ReviewBoard` API is not shown to be wired to the HAI ReviewRouter. Do not infer that a parallel review board closes the HAI path without an explicit, verified adapter and common policy enforcement.

## 6. Required remediation sequence and acceptance gates

| Order | Work package | Required exit evidence |
|---:|---|---|
| 1 | Canonical HAI ingress validation | Invalid/missing impact and caller-owned lifecycle fields rejected; all valid impact levels routed explicitly |
| 2 | Authenticated review decision protocol | Unauthorized caller, unsupported enum, wrong state and conflicting replay rejected; valid authorized decision retained |
| 3 | InteractiveReviewManager convergence | Same policy and identity enforcement; no weaker alternate approval path |
| 4 | ToolForge review integration (RL-559) | Actual request persisted and assigned; build/deployment remains blocked until real disposition |
| 5 | Constitutional evidence schema | Required evidence completeness, provenance, freshness, integrity and type/range validation |
| 6 | ControlCenter and EvolutionEngine evidence integration | No synthetic defaults or self-generated validation proof; unavailable evidence blocks compliance/promotion |
| 7 | Isolated, adversarial regression matrix | New tests do not mutate application-owned singleton state; exact-case red-to-green proof |
| 8 | Independent candidate verification | Root ExUnit, required runtime/audit suites, targeted HAI/constitutional integration, failure injection and exact-commit evidence all pass |

Closure is not permitted on code changes alone. RL-558 and RL-562 require independent green execution of their negative-regression suites, proof that all alternate production paths use the canonical authority/evidence policy, and evidence bound to the exact candidate commit. RL-559 remains separately OPEN until its own review acknowledgement path is corrected and verified.

## 7. Finding disposition

| Finding | Severity | Checkpoint 19.14 disposition |
|---|---|---|
| RL-558 — HAI impact fail-open, missing reviewer authorization, invalid/replayed decisions | CRITICAL | OPEN — 7/7 reproduced; alternate InteractiveReviewManager path added to scope |
| RL-559 — ToolForge false human-review acknowledgement | HIGH | OPEN — re-confirmed adjacent bypass; ASC-gated |
| RL-562 — synthetic/missing constitutional evidence can report compliance | CRITICAL | OPEN — 4/4 reproduced; ControlCenter and EvolutionEngine input paths traced |
| HAI test fixture state isolation | MEDIUM / TEST-HARNESS | OPEN — shared application GenServer state is replaced without restoration |

No production code, tests, runtime configuration, persistent state, deployment, constitutional authority, or physical actuation was changed. PR #13 remains draft, open and unmerged. Its two-file scope remains unchanged.

**Checkpoint 19.14 final status:** `SOURCE_TRACE_COMPLETE_REMEDIATION_SPECIFICATION_READY_NO_PRODUCTION_CHANGE`.

**Next checkpoint:** 19.15 — Independent Remediation Plan Review and Enforcement/Call-Path Coverage Matrix. Do not begin production remediation until the work packages, authority boundaries and regression scope are independently reviewed and approved.
