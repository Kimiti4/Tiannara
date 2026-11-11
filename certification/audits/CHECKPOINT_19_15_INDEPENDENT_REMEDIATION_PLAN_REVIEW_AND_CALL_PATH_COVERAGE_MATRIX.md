# Checkpoint 19.15 — Independent Remediation Plan Review and Enforcement/Call-Path Coverage Matrix

**Date:** 2026-11-11  
**Repository:** Kimiti4/Tiannara  
**Audit branch:** audit/consolidated-findings-r0a-2026-10-31  
**Source branch:** audit/cp19-10-red-baseline  
**Pinned source head:** 8f03c32ad10fa9ad654f987d30dde1bc9a53df5d  
**Prior plan:** CHECKPOINT_19_14_SOURCE_LEVEL_FAILURE_TRACE_AND_REMEDIATION_SPECIFICATION.md  
**Validation PR:** #13 — HAI and constitutional negative regression baseline  
**Status:** REMEDIATION_PLAN_REQUIRES_REVISION_NO_GO_FOR_PRODUCTION_CHANGES  
**Mode:** Separate source re-fetch, challenge review, caller/supervisor tracing and coverage-matrix construction. No implementation changes.

---

## 1. Executive decision

Checkpoint 19.15 performed a separate review of the 19.14 remediation plan against the exact regression-source branch. The review re-fetched the HAI, Council, ConstitutionalAuditor, ControlCenter, EvolutionEngine, ToolForge and application-startup implementations. It also searched the repository for direct callers and examined the existing Council human-approval, policy and audit-log interfaces before accepting Council as the intended constitutional authority boundary.

### Decision

**The 19.14 remediation direction is substantially correct, but it is not yet implementation-ready.**

REMEDIATION_PLAN_REQUIRES_REVISION_NO_GO_FOR_PRODUCTION_CHANGES

The most important omission is that the existing Council approval infrastructure cannot yet be assumed to provide authenticated human authority:

1. HumanApprovalQueue.approve/3 and reject/3 accept a caller-supplied human_id; their handlers do not authenticate the caller or verify a reviewer credential.
2. Council.resume_human_approval/3 is a public function that can re-evaluate a decision with the human grant without first proving that the referenced request was approved by the trusted queue.
3. The queue invokes the resumer asynchronously and returns :ok before the resumption result is available.
4. The queue is in-memory. Its audit-log appends are not checked for failure.
5. Council's ordinary authorization path does not write an immutable authorization record for every outcome, and its existing audit-log append calls ignore degraded-storage errors.
6. Council authorization accepts a nil execution context; ExecutionContext records an actor but does not authenticate that actor.
7. PolicyRegistry exposes policy registration and disable operations without an authorization check. Its default policy set does not encode the HAI impact_level taxonomy.

Therefore **do not connect HAI directly to the current Council human-grant APIs and call that an authorization fix**. The Council approval/identity/audit boundary must first be independently specified and made verifiable. Council must remain the final constitutional authorizer; HAI may capture and present a human review, but must not acquire an independent execution grant.

A second material correction concerns runtime topology: the HAI HAISupervisor module exists, but the inspected application startup path does not include it. ControlCenter starts ReviewRouter and InteractiveReviewManager directly through its subsystem list. The 19.14 report's description of InteractiveReviewManager as “separately supervised” should be treated as imprecise and corrected: it is a ControlCenter-started process in the inspected boot path; no HAI supervisor wiring was found.

This review is independent in the sense that the 19.14 proposals were challenged against re-fetched implementation bodies and separate call-path searches. It is not represented as an external third-party review or as a runtime test of the newly identified Council paths.

## 2. Scope, method and evidence boundary

The review was read-only. It:
- Re-fetched the production source from audit/cp19-10-red-baseline.
- Re-read the 19.14 report and current R0-A register.
- Searched indexed repository code for direct callers of ReviewRouter, InteractiveReviewManager, ReviewRequest.new, ConstitutionalAuditor.audit, Council approval functions and HAI supervisor references.
- Traced root application startup through OperationsSupervisor and ControlCenter.
- Examined Council, PolicyRegistry, ExecutionContext, Authorization, HumanApprovalQueue, HumanApprovalResumer, RuleEngine and AuditLog.
- Compared the proposed remediation order with Tiannara's authority rule: Council is the constitutional authority; CEL/orchestration and HAI cannot create or replace that authority.

Caller search is bounded by the GitHub code-search index and the inspected branch. Absence of a static search hit is not proof against dynamic dispatch, external callers or unindexed code. Such cases remain UNKNOWN until an exhaustive repository scan and runtime ingress trace are provided.

### Re-fetched source identities

| Component | Source path | Blob SHA |
|---|---|---|
| Council | lib/tiannara/council/council.ex | 26564ecd3e4b67aecb27948c591dfb294fae9dcd |
| Council authorization result | lib/tiannara/council/authorization.ex | b323caf37dff786953fc183b6ab5b151c42c6c92 |
| Execution context | lib/tiannara/council/execution_context.ex | 9aa2b3ba7fcc77ef04261fdc7f04b54e7e767f75 |
| Policy registry | lib/tiannara/council/policy_registry.ex | 4059eedba21336be400b32b54cb79427fc8dd007 |
| Human approval queue | lib/tiannara/council/human_approval_queue.ex | 7b54511eec3c41881d34f5abbd6029593b3a9165 |
| Human approval resumer | lib/tiannara/council/human_approval_resumer.ex | f0f994aa03bd218c53f4436842ce8767965f2bda |
| Constitutional rule engine | lib/tiannara/council/rule_engine.ex | 22ee088c6b10255586f2c3b236c325dd899c5482 |
| Council audit log | lib/tiannara/council/audit_log.ex | eb0ac2760008adba5d9ab1ffab75f01c9983c6dc |
| Council supervisor | lib/tiannara/council/supervisor.ex | 4e4e7eb4e6fd92524eae199ee77b96ce66bafe4a |
| HAI ReviewRouter | lib/tiannara/hai/review_router.ex | 54a09fc1c2b143b61edecf0b615c229011b335fa |
| HAI ReviewRequest | lib/tiannara/hai/domain.ex | 4a8ffe859a2611de1a3df032509a431d1ee55163 |
| InteractiveReviewManager | lib/tiannara/hai/collaboration/interactive_review_manager.ex | 70ff47b5dc061fd65db7a74fdc24804d7b8d5e8a |
| HAI supervisor | lib/tiannara/hai/hai_supervisor.ex | 1020dfd1bc6673ebdfeee177e7d1d5b55c62bea5 |
| ControlCenter | lib/tiannara/control_center.ex | 7e8c675714553eea58e73d642b3c3dc87bdc3960 |
| Root application | lib/tiannara/application.ex | 142d6c18122720a332569cbdf36ae492604273a0 |
| Operations supervisor | lib/tiannara/operations/operations_supervisor.ex | d7cccc0135ec2e907a7e4178f8a4ad822cc9028f |
| Autonomous loop | lib/tiannara/operations/autonomous_loop.ex | 0fb51f19aefa8f2234c9e41269eda53f3245a1ed |
| ConstitutionalAuditor | lib/tiannara/evolution/constitutional_auditor.ex | c0063363b49a8294946a5b3c2ac0225856bfc047 |
| EvolutionEngine | lib/tiannara/evolution/evolution_engine.ex | e433b1f519af754a6fc4a0b273e3577fbd550eec |
| ToolForge engine | lib/tiannara/tool_forge/tool_forge_engine.ex | 72f96da09f40a34f56b3f8bce31acee8233f0ad4 |
| ToolForge supervisor | lib/tiannara/tool_forge/tool_forge_supervisor.ex | d4dd7bfd218697fd776d61e09bc9a79e4478e206 |

## 3. Independent review of the 19.14 plan

| Proposed 19.14 requirement | Review result | Required adjustment |
|---|---|---|
| Validate HAI impact at ingress | SOUND BUT INCOMPLETE | Validate constructor, every API/adapter ingress and all server-owned lifecycle fields; first prove which ingress is actually used in production |
| Authenticate reviewer | CORRECT REQUIREMENT, AUTHORITY PROVIDER UNPROVEN | Define the trusted principal/capability issuer and make Council's current queue/resume path safe before integrating it |
| Enforce one-way review state machine | SOUND | Cover both ReviewRouter and InteractiveReviewManager; also cover Council human queue state and replay |
| Make decisions durable and immutable | SOUND | Audit every outcome; check storage writes; stop on degraded authoritative audit storage |
| Converge InteractiveReviewManager | SOUND | Correct startup/ownership model; decide whether to retire it or make it a strict adapter to the canonical review service |
| Fix ToolForge | SOUND | Keep RL-559 separate; the path is ASC-gated and currently does not create or await a review |
| Replace ConstitutionalAuditor map defaults | SOUND | Include all eight evidence providers, typed evidence envelope, three-state checks, independent verification and downstream consumers |
| Use Council as the final authority | NECESSARY, NOT YET SAFE TO IMPLEMENT | Council's queue, resumer, policy mutation and audit failure paths must be addressed first |
| Run negative regressions | INCOMPLETE | Add adversarial tests for Council authority, policy tampering, audit degradation, queue restarts, provider failures and real production ingress |
| Close on independent green CI | SOUND | Require exact candidate commit, all required suites and effect-boundary tests; CI green alone is not sufficient |

**Review conclusion:** the 19.14 specification is an adequate statement of intended HAI/evidence behavior, but it omitted prerequisite Council defects and did not establish the actual production HAI entrypoint. The implementation sequence must change.

## 4. Enforcement and call-path coverage matrix

### 4.1 Application startup, ownership and HAI reachability

| Path | Observed source path | What is established | Gap / required proof |
|---|---|---|---|
| Root app boot | Tiannara.Application.start/2 → root supervision tree | Operations.OperationsSupervisor is a root child; Council.Supervisor is also a core child | Boot success does not prove review-flow enforcement |
| Operations control | OperationsSupervisor → ControlCenter + AutonomousLoop | ControlCenter is supervised by OperationsSupervisor | Continue tracing the services ControlCenter starts itself |
| HAI process startup | ControlCenter.@subsystems includes ReviewRouter and InteractiveReviewManager; boot_all_subsystems/1 calls start_subsystem/2 | Both HAI modules are started by ControlCenter in the inspected boot path | Neither module's start is evidence that production decisions call it |
| HAI supervisor | lib/tiannara/hai/hai_supervisor.ex defines a supervisor for ReviewRouter | A supervisor module exists | No usage was found in Application's root children or ControlCenter's subsystem list; its runtime participation is UNKNOWN / NOT ESTABLISHED |
| ReviewRouter ingress | Public submit_review/1 → GenServer handler | A callable API and in-memory state exist | Indexed source search found no production caller; current production ingress is UNKNOWN |
| ReviewRouter decision | Public record_decision/3 → handler | A callable API and mutation handler exist | Indexed source search found no production caller; caller identity is discarded |
| Interactive manager ingress | open_session/3 | A callable API and in-memory sessions exist | Indexed source search found no production caller |
| Interactive manager decision | record_decision/4 | Callable API exists and closes stored session | Indexed source search found no production caller; decision is not tied to an authenticated principal |
| HAI events | HAIEvents.emit/3 → EventBus / ExecutiveMemory | Best-effort event attempts and warnings exist | Best-effort events are not an authoritative, durable approval record |

**Critical distinction:** the code search did not find an established production call from an actual application route, UI endpoint or decision executor into ReviewRouter/InteractiveReviewManager. The modules are started and exposed, but actual use is not proven. The remediation must not stop after making a currently uncalled API safer.

### 4.2 Council authority prerequisites

| Path / API | Current behavior from source | Why it blocks reuse as trusted HAI authority | Required acceptance evidence |
|---|---|---|---|
| Council.authorize/3 | Accepts a decision type, payload and optional context; context defaults to nil | The method itself does not authenticate a human principal. A nil context is allowed | Authenticated principal and capability provenance at the trust boundary; reject missing/invalid identity for human-authorized decisions |
| ExecutionContext.new/1 | Requires actor and intent values; copies the supplied actor into a struct | Presence/type is not proof of identity; a caller can construct a context naming another actor | Context must be issued or attested by a trusted identity boundary, bound to requester/session/decision and verified by Council |
| HumanApprovalQueue.approve/3 | Takes request_id, human_id, notes; the handler ignores _from, records the supplied ID and returns :ok | No authenticated reviewer proof, role check, separation-of-duties check or actor binding | Forged ID, unauthorized principal, wrong scope and missing credential all rejected; immutable actor identity evidence retained |
| HumanApprovalQueue.reject/3 | Same caller-supplied human_id shape; stores the reason and returns :ok | Rejection records need authenticated provenance too | Same identity/authorization checks as approval; rejection cannot be spoofed |
| Council.resume_human_approval/3 | Public function calls evaluate_with_human_grant/2 and logs the request ID; it does not first retrieve/verify a completed queue approval | Direct call can reach the human-grant re-evaluation path without a verified approval record | Make private or require a verifiable grant record bound to exact request ID, decision payload digest, policy version and reviewer authorization; replay/tamper tests |
| HumanApprovalResumer.resume/1 | Casts asynchronous resumption; Queue approve returns before the resumer finishes | :ok from approve means the record operation was accepted, not that final constitutional resumption succeeded | Expose explicit pending/resumed/rejected/failed states; the caller must not treat queue approval as final permission |
| HumanApprovalQueue storage | init/1 creates empty in-memory queue and history maps | Restart loses queue state/history; AuditLog events are not a reconstructable full approval record | Restart/recovery tests; durable canonical request and decision record; no approval based on stale or incomplete recovery |
| PolicyRegistry.register_policy/1 / disable_policy/1 | Public GenServer APIs mutate active policies; handlers do not validate a trusted authorizer | A policy intended to enforce mandatory human review can be modified/disabled by an in-node caller able to invoke these APIs | Policy mutation must be Council-authorized, versioned and audited; unauthorized policy changes rejected |
| Policy matching | Default policy set uses risk, invariant, architecture, resource and self-modification categories; no explicit HAI impact-level policy exists | impact_level: high/critical/civilizational alone does not necessarily match a require-human policy; risk has a default of 0.0 | Explicit HAI decision-type/impact policy tests, including all valid levels and malformed levels |
| Council audit writes | AuditLog.append/3 returns {:error, :storage_degraded} in degraded mode; several Council/Queue call sites ignore the return value | Authorization, queue changes or resumption may continue without a durable audit record | Audit degraded, insert error and sync failure must block protected decision completion; assert no side effect/approval is released |
| General authorization audit | Council.authorize/3 evaluates and returns authorization; normal approval does not append a complete authorization decision record in the inspected path | The existence of an immutable AuditLog does not prove every authorization is recorded there | Every authorization result and subsequent effect reference must be appended and verified before protected execution |
| Conditional authorization | Authorization.permitted?/1 allows only :approved; conditional grant has its own conditions predicate | Consumers must not treat “not rejected” or :conditional as permission | Effect consumers must use strict permitted?/1 or the documented conditional-grant predicate with all required conditions; adversarial consumer scan |

**Council decision:** retain Council as the constitutional authority, but do not yet treat its current human-approval APIs as an authenticated, immutable, fail-closed grant service. CEL, HAI, ControlCenter and EvolutionEngine must not be allowed to manufacture or bypass Council authorization.

### 4.3 RL-558 HAI implementation coverage

| Requirement | Required ingress / implementation coverage | Required negative tests | State |
|---|---|---|---|
| Impact schema | ReviewRequest.new/1, ReviewRouter submit, all direct ReviewRequest construction and any API adapter | missing, nil, unknown atom, string, unexpected struct/map, invalid nested fields | SOURCE-CONFIRMED DEFECT |
| Server-owned fields | request IDs, status, human decision, rationale, timestamps, resolved_at | caller attempts to set every server-owned field; duplicate/colliding request ID | SOURCE-CONFIRMED DEFECT |
| Routing table | every valid impact level and all decision types | all valid levels; boundary and malformed levels; no catch-all auto-approval | SOURCE-CONFIRMED DEFECT |
| Principal identity | trusted authentication-to-review boundary; Council context/grant | absent, forged, revoked, expired, wrong-role, wrong-scope actor; replayed credential | SOURCE-CONFIRMED DEFECT + COUNCIL PREREQUISITE |
| Decision enum | ReviewRouter and InteractiveReviewManager | every valid enum; unsupported atom/string; nil | SOURCE-CONFIRMED DEFECT |
| State machine | pending → terminal decision, with explicit allowed transitions | decision before pending, second decision, approval after rejection, conflicting replay, duplicate exact replay | SOURCE-CONFIRMED DEFECT |
| Atomicity | review state + immutable event + decision projection | crash between write steps; duplicate concurrent calls; stale version | NOT YET TESTED |
| Durability | authoritative request/event store | node restart, store unavailable, corrupted chain, write/sync failure | NOT ESTABLISHED |
| Parallel HAI API | InteractiveReviewManager open/comment/decision | forged reviewer, wrong reviewer, closed session, second decision, session replay | SOURCE-CONFIRMED WEAKNESS; NO PRODUCTION CALLER FOUND |
| HAI event adapter | EventBus and ExecutiveMemory | bus down, memory down, partial write | BEST-EFFORT ONLY; NOT AN AUTHORITY RECORD |
| Production ingress | real API/UI/workflow/tool entrypoint → canonical review API | endpoint-to-effect E2E; bypass attempt that calls effect directly | UNKNOWN / NOT ESTABLISHED |
| ToolForge | ASC-gated ToolForge pipeline | no queue record, no reviewer, reject/defer, audit unavailable, resumer failure | RL-559 OPEN; separate finding |
| Test isolation | existing HAI tests and CP19.10 HAI test | restore prior global state or isolate named server; run order/randomized/repeated suite | TEST-HARNESS DEFECT |

### 4.4 RL-562 constitutional evidence coverage

The auditor has eight principles; each needs its own authoritative evidence provider and independent verifier. A single map of counters is not enough.

| Constitutional check | Current production input path | Required source contract | Required negative tests |
|---|---|---|---|
| Capability vs verification | ControlCenter uses subsystem map size and health-history length; EvolutionEngine uses its own counters | Deployed capability inventory plus candidate/capability-specific verification artifacts, each bound to subject/version | no evidence, mismatched counts, unrelated health checks, stale evidence, zero denominator |
| Uncertainty visibility | ControlCenter and EvolutionEngine hard-code zero | Uncertainty register/epistemic evidence with completeness and provenance | provider absent, unknown entries, stale register, hidden/missing fields |
| Human judgment | Both production builders hard-code 0 completed / 0 required | Durable mandatory-review requirements joined to authenticated Council decisions for the same subjects | missing decision, pending decision, forged reviewer, zero/zero, duplicated decision |
| Lineage integrity | Both production builders hard-code zero violations | Versioned lineage verification report for exact candidate and parent chain | missing lineage, broken digest, unknown parent, wrong candidate |
| Safety constraints | Both production builders hard-code zero violations | Current safety monitor/invariant evidence and relevant effect outcomes | unavailable monitor, unknown safety state, active emergency, stale safety report |
| Objective alignment | Both use a fixed score (0.9) | Defined objective/constitution evaluation, method/version, source evidence and verifier | missing score, synthetic score, out-of-range score, stale constitution version |
| Modularity/coupling | Both production builders hard-code zero | Executable dependency/coupling analysis with exact repository/candidate digest | analysis unavailable, incomplete scan, wrong source digest |
| Evolution vs validation | ControlCenter supplies 0/0; EvolutionEngine reuses its internal counters for both sides | Independent, candidate-specific validation result produced outside the state being gated | 0/0, deployed-without-validation, counter self-increment, stale/mismatched candidate |

Required global semantics:
- Check outcomes are PASS, FAIL or UNKNOWN.
- Missing, unavailable, stale, malformed, untrusted, tampered or wrong-subject evidence is UNKNOWN, never PASS.
- A zero denominator is UNKNOWN unless a separate, explicit, versioned and evidence-backed applicability decision says the check is not applicable. It must not be rewritten as a ratio of 1.0.
- Overall compliance requires every mandatory check to be PASS with verified complete evidence. A percentage cannot average away an UNKNOWN.
- A not-applicable exception must itself be authorized under constitutional policy and retained in the audit record.
- Evidence must bind source, verifier, measurement time, system/candidate snapshot, constitution/policy version and canonical digest.
- Test/simulation fixtures must carry an explicit non-production evidence class; they cannot satisfy production gates.
- The convenience compliant?/1 must return false unless full compliance is proven; the richer audit result must retain UNKNOWN detail.

### 4.5 Constitutional call-path coverage

| Call path | Observed behavior | Required enforcement |
|---|---|---|
| Application → OperationsSupervisor → ControlCenter | ControlCenter starts the engine and periodic audit path | Prove provider startup, source ownership, exact snapshots and unavailable-provider behavior |
| ControlCenter scheduled audit | 24-hour timer calls run_constitutional_audit/1 | Same evidence contract; missing providers cannot produce compliant status |
| AutonomousLoop → ControlCenter | AutonomousLoop calls constitutional_audit/0 every 12 cycles, in addition to the scheduled timer | Both triggers must consume identical versioned evidence and report provenance; caller frequency must not affect compliance |
| ControlCenter result | Logs warning when non-compliant and stores last_audit | Clarify whether this is observational health telemetry or an actual gate; it currently does not itself block an executive effect |
| ControlCenter → EvolutionEngine | ControlCenter starts EvolutionEngine as a subsystem | Verify the actual evolution candidate cannot proceed on the separate synthetic/counter-based evidence path |
| EvolutionEngine scheduled cycle | Builds its own evidence map, calls auditor, increments its own counters when compliant | Independent validator evidence tied to candidate; no self-generated proof; unknown provider blocks the cycle |
| EvolutionEngine public trigger | trigger_evolution/0 sends the evolve cast | Test direct trigger and scheduled trigger against the same Council/evidence gate |
| Autonomy verification script | Supplies hand-authored 30/30, zero counts and fixed score; labels the audit “enforced” | Convert to a real provider integration check or clearly mark fixture-only; never call a fixture pass production evidence |
| Reports/dashboards/consumers | Auditor status and numeric score may be exposed downstream | Search all consumers; preserve UNKNOWN and evidence references instead of treating status/percentage as sufficient |

## 5. Corrected application/runtime call graph

The inspected startup path is:

    Tiannara.Application.start/2
      └─ root supervisor
           ├─ Tiannara.Council.Supervisor
           │    ├─ AuditLog
           │    ├─ PolicyRegistry
           │    ├─ HumanApprovalQueue
           │    ├─ HumanApprovalResumer
           │    └─ Council
           └─ Tiannara.Operations.OperationsSupervisor
                ├─ Tiannara.ControlCenter
                │    ├─ ReviewRouter (started through @subsystems)
                │    ├─ InteractiveReviewManager (started through @subsystems)
                │    └─ EvolutionEngine (started through @subsystems)
                └─ Tiannara.Operations.AutonomousLoop

ToolForge is a separate conditional branch:

    Tiannara.Application.asc_children(true)
      └─ Tiannara.ToolForge.ToolForgeSupervisor
           ├─ ToolBuilder
           └─ ToolForgeEngine
                └─ request_human_review/2
                     └─ ReviewRequest.new(...)   [discarded]
                          └─ returns :ok         [not an approval]

The module Tiannara.HAI.HAISupervisor declares a child list containing ReviewRouter, but the inspected root application children and ControlCenter subsystem list do not include that supervisor. The current boot path starts ReviewRouter and InteractiveReviewManager directly from ControlCenter. Do not describe them as children of HAISupervisor until the startup graph is actually wired and verified.

## 6. Gaps discovered in the 19.14 specification

### G-19.15-01 — Council human approval is not an authenticated principal boundary

The queue APIs accept human_id as ordinary input and do not verify it against an authenticated session, identity provider, role or capability. ExecutionContext.actor is likewise descriptive input, not identity proof. This makes “require an authenticated principal” in the 19.14 document an unimplemented dependency, not a satisfied capability.

**Required action:** define the trusted identity source and actor assertion contract; verify it at the server-side Council/queue boundary. Never accept a human identity merely because a request payload names it.

### G-19.15-02 — public human-grant resumption is not bound to an approved queue record

Council.resume_human_approval/3 directly invokes the human-grant evaluation branch. It does not verify request existence, approved status, reviewer identity, decision digest, freshness or one-time use before applying that grant.

**Required action:** eliminate the callable bypass or require a verifiable one-time grant record from the canonical queue. The grant must be bound to the exact immutable payload and policy/constitution version. The human grant satisfies only the relevant review requirement; it must never override a constitutional rejection or hard invariant.

### G-19.15-03 — Council audit persistence is not an enforced precondition

AuditLog correctly exposes a degraded state and returns an error from append when storage is degraded. Council and HumanApprovalQueue call sites ignore that result. Normal authorization outcomes also do not all append a complete authorization record. A hash-chained log existing in the repository is not evidence that the protected decision/effect was durably recorded.

**Required action:** define a transactional/outbox or equivalent fail-closed commit protocol. A protected decision cannot be released for execution until its authorization and evidence references have been durably recorded and verified. Audit store failure must yield UNKNOWN/denied, not a warning followed by success.

### G-19.15-04 — policy mutation is not tied to constitutional authority

PolicyRegistry exposes register_policy/1 and disable_policy/1; the inspected handler code applies changes without actor authorization. The default HAI policy match is not explicit: the declared conditions cover risk, invariants, mission impact, resource usage, architecture and self-modification, but not the full five-value HAI impact taxonomy.

**Required action:** govern policy mutation through Council, version every policy set and audit changes. Add explicit HAI impact/decision policy coverage; never rely on a missing risk field defaulting to zero to determine that review is unnecessary.

### G-19.15-05 — production HAI route is not established

ReviewRouter and InteractiveReviewManager are started, but the bounded code search found no direct production caller to their submit/decision APIs. ToolForge only constructs a ReviewRequest and discards it. The autonomy script tests a predicate, not an end-to-end review. The current code therefore does not demonstrate that production approval/effect paths actually traverse the reviewed HAI APIs.

**Required action:** map every real API/UI/workflow/ToolForge/evolution/physical-effect ingress to its authorization boundary. Identify and remove or gate bypass routes. Do not close RL-558 by making an uncalled module safe while live effects remain elsewhere.

### G-19.15-06 — HAI process ownership description is incorrect/incomplete

The HAI supervisor module is not in the inspected app startup path. ControlCenter starts the HAI modules from its own subsystem list. This is not the stated HAI supervisor boundary and must be treated as a supervision/ownership design gap.

**Required action:** choose one canonical supervisor owner, start the HAI services as supervised children exactly once, and test restart, shutdown, duplicate-start and degraded-start behavior. The ownership choice must not give HAI execution authority.

### G-19.15-07 — ControlCenter constitutional audit is observational

The inspected ControlCenter audit function logs a warning and stores last_audit; it does not itself reject or suspend an executive effect. The AutonomousLoop invokes it, but does not consume a typed PASS/FAIL/UNKNOWN result in the shown caller.

**Required action:** declare which paths are monitoring only and which effects require a pre-effect constitutional gate. Every protected effect must be gated at its actual execution boundary, not by a periodic dashboard status.

These are checkpoint review gaps/candidate subfindings. They do not retroactively alter the 11 executed CP19.10 regression outcomes. Assign new permanent RL identifiers only after a focused exact-path finding review and register decision.

## 7. Revised mandatory implementation order

The sequence in 19.14 must be amended. Do not implement HAI integration before the Council prerequisites.

| Order | Work package | Mandatory exit gate |
|---:|---|---|
| 0 | Freeze and map all effect entrypoints | Complete caller-to-effect graph, including HTTP/UI/workflow/ToolForge/evolution/AEO/physical routes; UNKNOWN paths remain blockers |
| 1 | Council identity and grant contract | Trusted principal verification; authenticated approve/reject; no caller-asserted human ID; role/scope and separation-of-duties rules |
| 2 | Council human-grant/resumer hardening | No direct resume bypass; exact request/digest/policy binding; one-time grant; explicit asynchronous completion state |
| 3 | Council audit/policy integrity | Durable append checked before permission/effect; degraded storage blocks; all outcomes audited; policy mutation Council-authorized and versioned |
| 4 | Canonical HAI review contract | Validated impact/request schema; system-owned fields; explicit route matrix; state machine; replay/idempotency; durable review state |
| 5 | HAI supervision and path convergence | One supervised HAI owner; InteractiveReviewManager retired or a strict adapter; no secondary decision authority |
| 6 | Real production ingress wiring | Every effect-bearing path uses canonical HAI request + Council authorization where required; no parallel bypass |
| 7 | ToolForge / RL-559 remediation | A real review is queued, authenticated and completed before deployment; failed/unavailable review returns failure; ASC gating preserved |
| 8 | Constitutional evidence envelope | Required evidence schema for all eight checks; provenance, subject binding, freshness, digest and verifier; PASS/FAIL/UNKNOWN |
| 9 | Provider integrations | ControlCenter and EvolutionEngine use independent authoritative sources; no fixed values, self-counters or health-history proxy |
| 10 | Effect-boundary gates | Protected evolution, self-improvement and other governed effects check current Council authorization and exact-candidate evidence immediately before execution |
| 11 | Adversarial test and verifier suite | HAI, Council, audit storage, evidence providers, all alternate routes and global-state isolation tested; no skipped security assertions |
| 12 | Independent candidate certification | Exact commit, full root Elixir, required runtime/audit, relevant CI, fail-injection and end-to-end effect tests all green; immutable evidence retained |

The order can be refined by the implementing team, but no earlier step can be marked complete by a document-only assertion. Council's human identity/grant/audit boundaries are explicit prerequisites, not optional parallel hardening.

## 8. Expanded acceptance matrix

### A. Council and HAI authorization

- Unauthenticated/forged/revoked/expired human cannot approve or reject.
- Caller-supplied human_id cannot substitute for authenticated principal evidence.
- Role/scope does not authorize a decision outside its assigned impact/decision type.
- HAI request cannot change request ID, payload digest, source, impact, decision history or actor after submission.
- Council human grant cannot be invoked without an approved, exact-match, one-time queue record.
- Grant cannot be replayed against a different request or changed payload.
- Invalid policy, unknown impact or unknown decision is rejected/UNKNOWN; there is no implicit pass.
- Policy registration/disable attempts without Council-authorized provenance fail.
- AuditLog degraded, append error, sync error or chain-verification failure blocks the protected approval path.
- A :conditional, :requires_human, :deferred or UNKNOWN Council result never reaches an effect executor as approved.
- Every approved/rejected/conditional/unknown authorization has an immutable, correlated record before downstream use.

### B. HAI routing and state machine

- All five declared valid levels have explicit documented policy outcomes.
- Missing, nil, malformed and unknown values never auto-approve.
- Only a trusted identity can create/resolve a human decision.
- Only an eligible pending review can transition to a terminal outcome.
- Repeated exact request is idempotent only when the same idempotency key and payload digest match.
- A conflicting replay, second decision or stale record is rejected without overwriting history.
- Concurrent approve/reject attempts have one atomic winner; all losers receive a conflict result.
- InteractiveReviewManager cannot create a weaker alternate path.
- If retained, session identity and active/closed state are validated server-side for comments and decisions.
- EventBus failure cannot erase or fabricate the authoritative audit record.

### C. Constitutional evidence

- Empty/partial maps cannot be compliant.
- Each of eight fields is required or explicitly not-applicable under a signed/versioned rule.
- Wrong-type, negative, inconsistent, out-of-range, stale and tampered evidence is UNKNOWN or FAIL.
- Zero/zero and positive/zero are not successful verification ratios.
- Evidence from one candidate cannot satisfy another candidate's audit.
- EvolutionEngine cannot use a counter that it increments itself as independent evidence.
- ControlCenter cannot translate health-check count into capability-verification count.
- Provider unavailability leaves the audit incomplete and blocks the required effect.
- A numeric compliance score cannot override one critical UNKNOWN.
- Only independently verified PASS evidence can be used to satisfy a production gate.

### D. Runtime integration and effects

- Boot graph shows one owner and one process instance for each HAI service.
- Review service restart does not lose queued/terminal review state or a stale approval.
- Direct tool/API/UI calls cannot bypass the Council/HAI effect gate.
- ToolForge's successful return is impossible until a real, valid human review is complete when policy requires it.
- EvolutionEngine scheduled and direct triggers both stop on missing/UNKNOWN evidence or missing Council authorization.
- Council emergency state blocks normal executive decisions through every HAI/Evolution/ToolForge entrypoint.
- AEO/physical effect adapters revalidate the exact authorization/evidence immediately before the effect.

## 9. Finding and checkpoint disposition

| Item | Severity | Disposition at 19.15 |
|---|---|---|
| RL-558 — HAI authority enforcement | CRITICAL | OPEN — 7/7 negative cases reproduced; Council dependency and ingress gaps added to the remediation prerequisites |
| RL-559 — ToolForge false human-review acknowledgement | HIGH | OPEN — ASC-gated false acknowledgement; must be covered in effect-path work |
| RL-562 — constitutional evidence integrity | CRITICAL | OPEN — 4/4 negative cases reproduced; provider and effect-gate matrix expanded |
| Council human identity/grant path | Candidate additional authority gap | OPEN / needs separate permanent finding assignment |
| Council audit/policy mutation integrity | Candidate additional authority gap | OPEN / needs separate permanent finding assignment |
| HAI startup/call-path reachability | Integration evidence gap | UNKNOWN / not certified |
| HAI test singleton state isolation | Test-harness defect | OPEN |

No finding is closed by this checkpoint. No production source, test, configuration, runtime state, constitutional authority, deployment or physical actuation was modified.

## 10. Deliverables and next checkpoint

This report is the 19.15 call-path and enforcement coverage matrix. The R0-A register must reference it and retain all open statuses.

**Checkpoint 19.15 final status:** REMEDIATION_PLAN_REQUIRES_REVISION_NO_GO_FOR_PRODUCTION_CHANGES.

**Next checkpoint:** 19.16 — Council Human-Approval Trust Boundary and HAI Production Ingress Audit. It should independently inventory every Council grant/queue/policy/audit entrypoint and every real HAI/effect ingress, assign any new findings, and produce a corrected authority contract before production remediation is authorized.
