# Checkpoint 19.16 — Council Human-Approval Trust Boundary and HAI Production Ingress Audit

**Date:** 2026-11-11  
**Repository:** Kimiti4/Tiannara  
**Audit branch:** audit/consolidated-findings-r0a-2026-10-31  
**Pinned source commit:** de231a78db542a6172d7bd1ffd46e8a766deafa4  
**Parent checkpoint:** CP19.15  
**Mode:** read-only source and test-body inspection; no application execution  
**Disposition:** COUNCIL_AND_HAI_AUTHORITY_BOUNDARIES_NOT_CERTIFIABLE — ONE NEW HIGH FINDING — NO PRODUCTION CHANGE

## 1. Executive determination

CP19.16 re-fetched and inspected the Council approval, grant resumption, policy, constitution, audit-log and authorization-registry source paths on the exact CP19.15 audit-branch commit. It also traced the HAI module startup topology, Phoenix route table, production endpoint configuration, physical-deployment API adapter and the bounded Omega/Phase4 effect-gate implementations.

**The remediation plan remains NO-GO for production implementation or certification.** The existing Council and HAI defects remain open. The normal HumanApprovalResumer path does perform an approved-status check before requesting resumption, but that check is not enforced inside the public Council resumption API. The queue's approver field remains caller-supplied rather than authenticated. Council policy and constitution mutation APIs are also unguarded at their own handlers.

A distinct mint-registry defect is now assigned **RL-564 (HIGH / OPEN)**. The registry's minter allowlist checks the caller's stack-origin module, but the public HumanDelivery.Authorization.record_mint/1 wrapper accepts an arbitrary caller-supplied authorization ID and forwards it from an allowlisted module without requiring or validating a grant or human identity. The repository's R-2 test explicitly asserts that this arbitrary ID is registered successfully. The D127.6 negative test does not exercise that wrapper before checking the forged grant.

The HAI modules are started through ControlCenter, but the inspected Phoenix router contains no HAI review submission or decision route and the bounded production-call-site search did not establish a production caller that feeds ReviewRouter or InteractiveReviewManager. HAI's production ingress therefore remains **UNKNOWN / NOT ESTABLISHED**. A separate physical-approval HTTP route is mounted; its authentication and decision-validation defects are already represented by RL-434, RL-439 and RL-470. CP19.16 confirms that the route is mounted in the source router, ASC is enabled in the checked base configuration, and the production endpoint is configured to bind all interfaces. This does not prove that a deployed instance is externally reachable through its network perimeter.

No test, compile, runtime boot, fault injection, live HTTP request, registry mutation, deployment or physical actuation was performed in this checkpoint.

## 2. Source identity and evidence basis

All implementation source listed below was re-fetched at pinned commit de231a78db542a6172d7bd1ffd46e8a766deafa4. Blob SHAs identify the exact source objects inspected.

| Source path | Blob SHA |
|---|---|
| lib/tiannara/council/council.ex | 26564ecd3e4b67aecb27948c591dfb294fae9dcd |
| lib/tiannara/council/human_approval_queue.ex | 7b54511eec3c41881d34f5abbd6029593b3a9165 |
| lib/tiannara/council/human_approval_resumer.ex | f0f994aa03bd218c53f4436842ce8767965f2bda |
| lib/tiannara/council/policy_registry.ex | 4059eedba21336be400b32b54cb79427fc8dd007 |
| lib/tiannara/council/constitution_repository.ex | 8ab4e4fc2ec580c8e6fe77d24725beb6abdb6678 |
| lib/tiannara/council/machine_authorization.ex | bb338fa6fc0d3e681c2370838757c858b0fdaa0e |
| lib/tiannara/council/audit_log.ex | eb0ac2760008adba5d9ab1ffab75f01c9983c6dc |
| lib/tiannara/council/authorization.ex | b323caf37dff786953fc183b6ab5b151c42c6c92 |
| lib/tiannara/council/execution_context.ex | 9aa2b3ba7fcc77ef04261fdc7f04b54e7e767f75 |
| lib/tiannara/council/supervisor.ex | 4e4e7eb4e6fd92524eae199ee77b96ce66bafe4a |
| lib/tiannara/omega/mint_registry.ex | 2ea06c365d4d51224edef812e27084d50244d8e3 |
| lib/tiannara/omega/human_delivery/authenticated_human_identity.ex | 901bb2022929c3439f683a38403476ad685f9f3f |
| lib/tiannara/omega/human_delivery/authorization.ex | af44fa72306d56337bdfa609ff7c5f5498162c21 |
| lib/tiannara/omega/human_delivery.ex | 53648723d716307f91784221970d509167a86cc4 |
| lib/tiannara/omega/governed_effect_sink.ex | 315c04395709095a63585764dd7cc32e75b85207 |
| lib/tiannara/phase4/execution_governance.ex | f791f0fbd5ed1b1babe244998ef38bd201fad14d |
| lib/tiannara/phase4/real_execution.ex | dd4d988288a0a67230e3007a7e04dda3683b2284 |
| lib/tiannara/application.ex | 142d6c18122720a332569cbdf36ae492604273a0 |
| lib/tiannara/control_center.ex | 7e8c675714553eea58e73d642b3c3dc87bdc3960 |
| lib/tiannara/hai/review_router.ex | 54a09fc1c2b143b61edecf0b615c229011b335fa |
| lib/tiannara/hai/domain.ex | 4a8ffe859a2611de1a3df032509a431d1ee55163 |
| lib/tiannara/hai/collaboration/interactive_review_manager.ex | 70ff47b5dc061fd65db7a74fdc24804d7b8d5e8a |
| lib/tiannara/hai/hai_supervisor.ex | 1020dfd1bc6673ebdfeee177e7d1d5b55c62bea5 |
| lib/tiannara/web/router.ex | 917c749e023ff86d59200798b93dfe4bfd9c11f0 |
| lib/tiannara/web/crav_challenge_controller.ex | 403b7177633cbb187d7388df86dc5bd02eb40046 |
| lib/tiannara/asc/reality/physical_deployment_manager.ex | 94030decab03ff4e92b20345390e6f3793b24c1e |
| lib/tiannara/asc/reality/digital_deployment_manager.ex | 423b1013445ec54884e4570b15421435617a7db9 |
| lib/tiannara/asc/reality/reality_director.ex | 07cdf2d5920674e4257930d2533d2a4fa20e5411 |
| config/config.exs | c2afdf8b8a35da7c9b85b36f15caf57e91e68e98 |
| config/prod.exs | 950c75fa82a25b71789d2d63ca58de5a9a23d312 |
| test/tiannara/omega/step13_r2_mint_authentication_test.exs | 1e4c6c7b59d5108bf0c4d56dd0cd46797095f9e3 |
| test/tiannara/omega/d127_authorization_attack_test.exs | 9caeb9c41e7f25219f09b2c331b262aca45b238b |
| test/tiannara/omega/human_authorization_identity_test.exs | c7313a706cd454162a12403f84fb1789f073f749 |
| test/tiannara/council/human_approval_resume_test.exs | 93e86a22565487f84c5a6a81dc14abb4d90c9da1 |
| test/tiannara/hai/review_router_test.exs | 20844355ec28a63d844d0c53aea1200313b6473e |
| test/tiannara/asc/reality/physical_deployment_manager_test.exs | 1cd4ca8784ea9a25fd8b333056b0b67295c2685b |

The audit relied on exact-branch file fetches, the recursively fetched branch tree and source/test inspection. GitHub indexed code search is default-branch scoped; its negative results are treated only as bounded discovery evidence, not proof of absence on the pinned audit branch.

## 3. Council human-approval trust boundary

### 3.1 HumanApprovalQueue: reviewer identity is still asserted by the caller

HumanApprovalQueue.approve/3 and reject/3 accept request_id, human_id and free-form notes/reason. Their GenServer handlers ignore the calling process identity (_from), do not accept an authenticated principal, do not verify a credential/session, and do not check a reviewer role, approval scope, separation-of-duties requirement or capability. The supplied human_id is copied into decided_by and the AuditLog actor.

The queue stores queue and history in GenServer memory and initializes both empty. An approval moves a request from queue into history. It then requests asynchronous resumption and returns :ok before the Council resumption outcome is available. AuditLog.append/3 results are not checked in queue/reject handlers. record_resume/2 also trusts any caller supplying a request ID and Authorization struct.

The intended resumer path is materially better than treating a queue row as authorization: it fetches the record and proceeds only when status is :approved. That improvement does not authenticate the actor or make the record durable, and it does not secure the public Council resume API.

**Existing findings revalidated:** RL-412, RL-414 and related queue/decision lifecycle items. Do not create duplicate findings for the same defects.

### 3.2 Public Council resumption does not enforce the queue invariant

Council.resume_human_approval/3 is an exported function that directly calls evaluate_with_human_grant/2, logs a request_id and returns the resulting Authorization. It does not fetch the request from HumanApprovalQueue, verify an approved status, validate the approver, compare an immutable payload digest, check expiry or one-time consumption, bind the result to policy/constitution versions, or independently check the Council GenServer's active emergency state.

HumanApprovalResumer is the normal observed caller: it fetches a queue record, checks status :approved, calls the Council function, writes the result back through record_resume/2 and appends another audit event. That is a caller-level convention, not an invariant of the public Council boundary. The Council function can be called directly without that pre-check.

**Existing finding revalidated:** RL-413. The queue history's exact decision-type/raw-payload match and non-consuming approved_request behavior remain within RL-414. No duplicate ID assigned.

### 3.3 Emergency authority

Council.invoke_emergency/2 and lift_emergency/1 accept caller-supplied actor/human_id values. Their handlers ignore GenServer caller identity. The lift path clears the emergency flag when the in-memory state is active, without an authenticated principal, signature, quorum or independent approval check. The emergency state is stored in Council GenServer memory. The call paths inspected do not establish a durable restore mechanism for an active emergency after Council restart. Audit append results are ignored by these handlers.

**Existing emergency-authority findings remain OPEN.** This checkpoint does not create another ID for the caller-asserted actor or restart-persistence behavior.

### 3.4 ExecutionContext does not authenticate the actor

ExecutionContext.new/1 accepts caller-provided actor and intent fields. Council.authorize/3 accepts a nil context by default. An ExecutionContext struct is therefore descriptive input, not evidence that its actor has authenticated or possesses the authority being asserted. The Council queue path does not consume an authenticated identity object from Omega.

The relevant source-level correction must make the verified principal originate at an authentication boundary and bind the principal, role/scope, policy version, constitution version and exact request digest to a one-time approval capability. A string/atom actor field must not be treated as proof.

### 3.5 Policy and constitution mutation are direct public APIs

PolicyRegistry.register_policy/1 and disable_policy/1 send ordinary GenServer calls whose handlers ignore _from and directly mutate the live in-memory policy map. The handlers do not invoke Council authorization or require a constitutional ratification receipt. register_policy/1 replaces a policy with the same ID; the shown handler does not validate the policy schema or immutable baseline. The default registry policy set is in memory.

ConstitutionRepository.commit/3 and rollback/2 are likewise public GenServer APIs. commit/3 accepts caller-supplied constitution data and committed_by, inserts it into DETS and updates the in-memory current_version without a Council authorization check, approved-amendment reference, immutable-core validation or checking the DETS insert result. rollback/2 changes the active version pointer based on a target version and caller-supplied actor without a Council authorization gate in the handler.

**Existing findings revalidated:** RL-122 (PolicyRegistry mutation) and RL-123 (direct constitution commit/rollback). These are local in-node APIs; this report does not assert that a public network route calls them.

### 3.6 Audit log is tamper-evident storage, not actor authentication or a universal precondition

AuditLog uses a DETS-backed sequence/hash chain and returns explicit errors while degraded. This is valuable integrity infrastructure. It does not authenticate the actor field passed by its caller. Council, HumanApprovalQueue, HumanApprovalResumer and emergency paths do not consistently check append results before reporting or advancing their in-memory state. An existing hash chain therefore cannot be used as proof that each authority decision had a verified human actor or a durable, successful audit record before the decision was treated as accepted.

No additional finding ID assigned here; existing queue, Council audit and emergency findings remain controlling.

## 4. Omega HumanDelivery and registry anti-forgery boundary

### 4.1 The identity helper remains a local constructor, not an authentication provider

AuthenticatedHumanIdentity.authenticate/3 checks only that human_id and credential are non-nil and that the credential is a non-empty binary. It computes a hash of that arbitrary string and stamps authenticated_at with the current time. authenticated?/1 returns true for any identity struct with a non-nil timestamp. The struct fields are public and may also be constructed directly.

Authorization.human_grant/2 checks this timestamp predicate and copies the caller-selected human_id into the grant. GovernedEffectSink checks the same predicate and compares identity.human_id to grant.human_id; it does not consult an identity provider, signed session, trusted issuer, credential verifier, role/scope authority or revocation service.

**Existing finding revalidated:** RL-426. No duplicate finding assigned.

### 4.2 NEW RL-564 — allowlisted public wrapper permits arbitrary registry grant-ID registration

**RL-564 — HIGH / OPEN — HumanDelivery.Authorization.record_mint/1 lets callers register arbitrary authorization IDs through an allowlisted minter wrapper.**

The registry's R-2 check is based on the first non-infrastructure frame in the calling process stack. The allowlist contains Tiannara.Omega.HumanDelivery.Authorization. The public Authorization.record_mint/1 function accepts only an authorization_id and forwards it to MintRegistry.record_mint/2. It receives no grant struct, no authenticated identity, no approval record, no decision digest and no capability proving that a human_grant operation succeeded.

The R-2 test file explicitly asserts:
- a direct call to MintRegistry.record_mint/1 from a non-allowlisted caller is refused;
- HumanDelivery.Authorization.record_mint(arbitrary_id) returns :ok;
- the registry status for that caller-chosen ID becomes :granted;
- a repeated registration is refused only because the ID is already registered.

Thus the minter allowlist is bypassable through the public wrapper it trusts. The wrapper proves only that an allowlisted module was on the call stack, not that it validated a newly issued grant. The registry's record_bind/3 handler also ignores _from and accepts a binding for any registered, unconsumed ID, without tying the caller to the grant issuer or verified human decision.

The D127.6 test constructs a complete Authorization struct with a fresh ID and verifies that the sink refuses it while the ID is unregistered. It does not first call the public Authorization.record_mint/1 wrapper for that ID or persist a binding. Consequently, the negative test proves rejection of an unregistered struct, but does not cover the wrapper-assisted registration route exposed by the same repository.

**Impact and boundary:** The durable registry can be made to report :granted for a caller-chosen ID without a genuine HumanDelivery grant issuance. Combined with the separately registered RL-426 weakness (forgeable human identity) and unrestricted record_bind/3 transition, source inspection indicates that registry-backed gate checks could be satisfied by a fabricated grant if the public sink/Phase4 admission APIs are invoked. This is a source-derived attack composition, not an executed exploit. The bounded source review did not establish a normal production caller of GovernedEffectSink.execute/3, and this sink writes one internal EventStore topic rather than directly actuating the external world. No real-world unauthorized effect is claimed.

**Required closure evidence:**
1. Remove arbitrary-ID registration from the public wrapper or make it require a one-time, opaque issuance capability created only after a verified human decision.
2. Bind the grant's canonical contents, human principal, authority scope, request/payload digest, policy/constitution versions, issue time and expiry to the registry record.
3. Make registry binding require proof of issuer/grant provenance and the effect descriptor; do not expose a caller-independent bind operation for arbitrary known IDs.
4. Rework the identity path to use a verified issuer/session credential, role/scope checks, revocation and expiry; keep identity capabilities opaque and non-forgeable to ordinary callers.
5. Add an adversarial test that constructs a forged Authorization, calls the public record_mint wrapper, attempts record_bind, then calls every sink/admission consumer. The expected result is rejection before any effect/store event, registry state mutation or success-shaped acknowledgement.
6. Run the test on a compatible Elixir 1.18 / OTP 28 runner against an isolated registry path; capture the exact candidate commit and verify both rejection and legitimate issuance.

### 4.3 Normal HumanDelivery issuance remains incomplete

HumanDelivery.authorize/3 calls human_grant/2 and stores the resulting authorization in an in-memory granted map. It does not perform the durable registry mint or durable effect binding before returning. Authorization.bind_effect/2 changes the struct but does not itself write the registry binding. The registry registration/binding operations are split into separate manual calls.

**Existing finding revalidated:** RL-479. This is the opposite edge of RL-564: the normal workflow does not complete required registration, while the public wrapper can register an arbitrary ID without validating a grant. Do not merge these two failure modes into a false claim that ordinary HumanDelivery.authorize/3 itself registers or executes a forged grant.

### 4.4 Other bounded authorization mechanisms

- MachineAuthorization.mint/2 accepts an Authorization struct and checks structural predicates such as permitted?/1 and decided_at. The R-2 test builds Authorization.approved(...) and passes it to MachineAuthorization.mint/2. That is not proof that the decision originated from Council. No normal production effect consumer for MachineAuthorization was established in this pass; do not claim a machine-class deployment bypass without such a consumer.
- MintRegistry.record_bind/3 is public and does not authenticate the GenServer caller. Its check is registry-state-based and compares a decision reference when one exists. Human-path records created through record_mint/1 have a nil decision reference. The bind caller is not tied to a verified approver or opaque grant capability.
- MintRegistry remains an append-file/GenServer registry with previously registered recovery and durability limitations (including RL-478 and RL-481). Those findings are not closed by this review.
- GovernedEffectSink implements a bounded, single internal EventStore append path. It is not a universal executor, not a physical hardware gateway and not evidence that every Tiannara effect is Council-gated.

## 5. HAI runtime ownership and production ingress

### 5.1 Startup topology

The root Application starts Council.Supervisor and OperationsSupervisor as core children. OperationsSupervisor starts ControlCenter. ControlCenter's subsystem list includes ReviewRouter and InteractiveReviewManager and starts them directly through its subsystem boot routine. The HAI.HAISupervisor module exists and starts ReviewRouter, but it was not found as a child in the inspected root Application or in the ControlCenter startup list. Its actual participation in normal root boot remains UNKNOWN; the previously corrected CP19.15 wording about a separately supervised InteractiveReviewManager remains corrected.

### 5.2 Review APIs are not authenticated and do not call Council

ReviewRouter.submit_review/1 constructs a ReviewRequest from caller attributes. ReviewRequest.new/1 uses struct(attrs) without enforcing the declared impact-level allowlist. ReviewRouter.record_decision/3 has no authenticated principal argument; the handler ignores _from and does not validate a reviewer role, decision enum or strict state transition. determine_routing/1 returns :approved for all impact levels outside its explicit mandatory/recommended sets. These remain RL-558.

InteractiveReviewManager.open_session/3 accepts caller-supplied reviewer_id; record_decision/4 also has no authenticated principal argument and its handler ignores _from. No source evidence was found that it delegates authority to Council or that its output is bound to a Council-approved grant. Include this alternate path in RL-558 remediation coverage.

### 5.3 Production ingress is not established

The full inspected Phoenix router exposes no ReviewRouter or InteractiveReviewManager submission/decision route. The HAI API methods are public GenServer calls inside the BEAM application. The bounded source search in CP19.15 found no direct production callers of ReviewRouter.submit_review/1, ReviewRouter.record_decision/3, InteractiveReviewManager.open_session/3 or InteractiveReviewManager.record_decision/4. That search is not exhaustive proof against dynamic, plugin, runtime or unindexed callers, so classify normal production HAI ingress as **UNKNOWN / NOT ESTABLISHED**, not as proven globally unreachable.

ToolForge is a separate ASC-gated consumer. Its request_human_review/2 helper still creates and discards a ReviewRequest and returns :ok, without submitting a review or receiving a reviewer disposition. That remains RL-559 and is not evidence that HAI approval is integrated.

## 6. Mounted physical approval API and effect-route comparison

### 6.1 Confirmed source route and configuration

The Phoenix router registers:
- POST /api/v1/reality/physical for planning;
- POST /api/v1/reality/physical/:id/advance;
- POST /api/v1/reality/physical/:id/approve;
- POST /api/v1/reality/physical/:id/abort.

The :api pipeline applies JSON content negotiation and contains no visible authentication plug. The controller reads approver from request parameters (default "human-operator") and forwards it to PhysicalDeploymentManager.approve/3 or reject/3. The manager stores the string in approval metadata and does not authenticate the GenServer caller.

The controller defaults a missing decision to "approved"; "reject", "abort" and "emergency_stop" have explicit clauses; every other value falls through to approve. This is already RL-470. The route/actor authentication weakness remains covered by RL-434/RL-439. No duplicate finding is assigned.

The checked config/config.exs sets asc.enabled: true. config/prod.exs configures the Phoenix endpoint to bind 0.0.0.0 and starts the server. This source configuration makes the route part of the configured production surface when that production configuration is used. Actual deployed settings, reverse-proxy behavior, firewall rules and external reachability were not tested and remain UNKNOWN.

### 6.2 Physical-effect limitation

PhysicalDeploymentManager is started inside ASC.Reality.Supervisor when the ASC subtree is enabled. Its plan path defaults the adapter to SimulatedAdapter; the controller's plan action forwards name, type, steps and params but does not expose a top-level adapter selection. The only concrete adapter implementation found in the inspected tree was SimulatedAdapter, which records actions in memory. The router exposes no HTTP execute/action route for PhysicalDeploymentManager.execute/2. Its advance/approve endpoints can move a plan through state stages, but this pass does not establish that the mounted endpoint can actuate physical hardware.

The RealityDirector physical path calls PhysicalDeploymentManager.plan/1; its higher-level deployment status does not prove a completed hardware operation. Existing physical lifecycle/status and execution-plan findings remain open. No physical actuation was performed.

## 7. Caller and authority coverage matrix

| Surface / entrypoint | Actor/authentication enforced at the boundary? | Effect or downstream consumer identified | Reachability classification | Existing finding / disposition |
|---|---|---|---|---|
| HumanApprovalQueue.approve/reject | No; caller-supplied human_id, _from ignored | HumanApprovalResumer / Council re-evaluation | Internal GenServer API; no HAI web route identified | RL-412 and related queue findings OPEN |
| Council.resume_human_approval/3 | No queue, actor, payload digest or one-time proof checked inside API | Returns Authorization from policy/rule re-evaluation | Exported module function; normal caller is resumer | RL-413 OPEN |
| HumanApprovalQueue.approved_request/2 | Exact raw payload match only; no one-time consumption/expiry | Council.authorize path | Internal GenServer API; retained in-memory history | RL-414 OPEN |
| Council.invoke_emergency/lift_emergency | Caller-supplied actor/human_id; _from ignored | Council emergency-state mutation | Internal Council API; no web route identified | Existing emergency findings OPEN |
| PolicyRegistry.register/disable | No principal or Council authorization in handlers | Mutates live policy map | Internal GenServer API | RL-122 OPEN |
| ConstitutionRepository.commit/rollback | No principal or Council authorization in handlers | Mutates persisted/current constitution version | Internal GenServer API | RL-123 OPEN |
| AuditLog.append/3 | Actor supplied by caller, not authenticated here | Hash-chained DETS log | Internal GenServer API; callers sometimes ignore failures | Existing audit/queue findings OPEN |
| AuthenticatedHumanIdentity.authenticate/3 | Any non-empty binary; human_id/method caller-selected | HumanDelivery grant / sink checks | Public library function; no identity provider integration found | RL-426 OPEN |
| HumanDelivery.Authorization.record_mint/1 | No grant or identity input; stack-origin module is allowlisted | MintRegistry :granted status checked by bounded sinks | Internal public module API; R-2 test proves arbitrary ID registration | **RL-564 NEW — HIGH / OPEN** |
| MintRegistry.record_bind/3 | No caller authorization in handler | Registry binding checked by GovernedEffectSink / Phase4 admission | Internal public GenServer API | Included in RL-564 attack chain; no independent new ID |
| HumanDelivery.authorize/3 | Requires identity struct but helper is forgeable; no durable mint/bind before response | In-memory granted map | No normal production caller established | RL-479 OPEN; RL-426 OPEN |
| GovernedEffectSink.execute/3 | Struct/registry/weak identity/effect checks; no external identity provider | One internal EventStore topic | No production caller established by bounded search | Bounded sink; no universal effect claim |
| ReviewRouter.submit/record | No authenticated actor; invalid impacts auto-approve | No Council/effect integration established | Started by ControlCenter; no route/caller established | RL-558 OPEN; ingress UNKNOWN |
| InteractiveReviewManager.open/record | Reviewer ID supplied by caller; _from ignored | No Council/effect integration established | Started by ControlCenter; no production caller established | RL-558 remediation scope; ingress UNKNOWN |
| ToolForge.request_human_review | No human decision; request discarded | ToolForge continues and logs success-shaped review message | ASC-gated internal pipeline | RL-559 OPEN |
| Physical HTTP approve | No auth plug/principal; caller-supplied approver | PDM approval state; advance API | Router-mounted; ASC enabled in checked base config; production binding 0.0.0.0 configured | RL-434/RL-439/RL-470 OPEN |
| Phase4 ExecutionGovernance.begin | Checks grant struct, registry state/binding, exact effect identity, one-shot consume and audit | RealExecution admission | In-process; RealExecution feature flag defaults false; deployment is optional | RL-478/RL-479 and related findings remain OPEN |

## 8. Revised implementation order

Do not begin by wiring ReviewRouter to the current Council queue or by treating the current Omega identity helper as an authentication provider. The trust boundary must be corrected first.

1. **Freeze and inventory authority-bearing mutations.** Enumerate every direct caller of Council authorize/emergency/resume, queue approve/reject, PolicyRegistry mutation, ConstitutionRepository commit/rollback and all registry mint/bind/consume APIs. Bind exact paths to the current source commit.
2. **Establish the identity provider contract.** Specify a verified principal, credential/session proof, revocation and expiry, reviewer role/scope and separation-of-duties semantics. No actor string or timestamp-bearing public struct is authority.
3. **Create a Council-issued one-time approval capability.** It must bind reviewer identity, request ID, exact canonical payload digest, policy version, constitution version, expiry, intended operation/effect identity and nonce. It must be independently validated at the Council/effect boundary.
4. **Close direct resumption and emergency bypasses.** Make Council resumption consume a validated capability and enforce the emergency state; secure emergency invoke/lift with the constitutional emergency protocol and durable recovery.
5. **Govern policy/constitution mutation.** Move policy register/disable and constitution commit/rollback behind the Council ratification service; validate immutable invariants and schemas; verify DETS and audit durability before acknowledging changes.
6. **Repair mint-registry issuance and bind transitions.** An allowlisted module must not accept arbitrary IDs. Bind registry state to an authenticated issuance receipt and require trusted, one-time effect binding. Cover RL-564 in particular.
7. **Make audit persistence a precondition where required.** Propagate append/sync/storage failures and define recovery behavior before any approval, policy mutation, constitution change or protected effect is reported successful.
8. **Define one canonical HAI contract.** Enforce schema, UNKNOWN/fail-closed routing, identity-bound reviewers, strict state transitions, idempotency, expiry, durable decisions and immutable review provenance.
9. **Connect HAI to actual production callers.** Inventory and name the entrypoints, route/service, request source, effect consumers and result propagation. Do not count module startup as functional production ingress.
10. **Correct physical route controls separately.** Require an authenticated principal, explicit decision enum, exact plan-digest approval and manager-side enforcement. Keep simulated and real hardware claims distinct.
11. **Repair ToolForge and every other alternate review consumer.** A discarded request or :ok from rescue must never become a human-review pass.
12. **Adversarially verify all paths.** Add tests for spoofed principals, forged structs, wrapper-assisted mint, unauthenticated bind, direct Council resume, stale/replayed approvals, policy overwrite/disable, constitution direct commit, emergency lift, degraded audit storage, unknown HAI levels, API decision typos, concurrent decisions and process restart.
13. **Independently certify the exact candidate commit.** Run the full root regression and focused authority suites with compatible Elixir/OTP, include a negative test for RL-564 and verify no protected effect or success-shaped result is produced.

## 9. Finding disposition and evidence limits

| Finding | Severity | CP19.16 disposition |
|---|---|---|
| RL-122 PolicyRegistry mutation | Existing | Reconfirmed; OPEN |
| RL-123 ConstitutionRepository direct commit/rollback | Existing | Reconfirmed; OPEN |
| RL-412 HumanApprovalQueue caller-asserted reviewer | Existing | Reconfirmed; OPEN |
| RL-413 public Council resumption bypass | Existing | Reconfirmed; OPEN |
| RL-414 reusable in-memory approved request | Existing | Reconfirmed; OPEN |
| RL-426 forged human identity / non-validating credential helper | Existing | Reconfirmed; OPEN |
| RL-434 / RL-439 physical route identity boundary | Existing | Route and config revalidated; OPEN |
| RL-470 unknown physical decision defaults to approve | Existing | Reconfirmed; OPEN |
| RL-478 registry consume without required prior binding | Existing | Remains OPEN; not tested dynamically |
| RL-479 ordinary HumanDelivery grant not durably registered/bound | Existing | Reconfirmed; OPEN |
| RL-481 MintRegistry corrupt-term recovery | Existing | Remains OPEN |
| RL-558 HAI invalid impact / caller-less decision authority | CRITICAL | Reconfirmed; OPEN; production ingress UNKNOWN |
| RL-559 ToolForge false human-review acknowledgement | HIGH | Remains OPEN |
| RL-564 allowlisted public mint wrapper registers arbitrary ID | HIGH | **NEW — OPEN** |
| HAI Supervisor / production ingress | Coverage status | NOT ESTABLISHED; no separate permanent finding ID assigned |
| MachineAuthorization minted from caller-built decision struct | Candidate | Source concern; no effect consumer established; no separate ID assigned |

The new RL-564 finding is supported by the wrapper's implementation and the explicit assertions in the R-2 test source. The test source was inspected but not executed in CP19.16. The possible forged-grant-to-sink composition is static reasoning over the inspected functions; it was not run as an exploit. No external caller, production sink or real-world effect is claimed where one was not established.

## 10. Changes, CI and PR status

- Only this checkpoint report and the consolidated audit findings register are to be changed by CP19.16.
- No production source, tests, application configuration, runtime state, governance authority, persistent registry, deployment or hardware was changed.
- No local compile/test/runtime execution or live API request was performed in this checkpoint.
- PR #13 remains open, draft and unmerged on head 8f03c32ad10fa9ad654f987d30dde1bc9a53df5d. It remains the CP19.10 two-file negative-regression baseline; no PR changes were made here.
- RL-558, RL-559, RL-562 and the existing Council/registry/physical findings remain open. No finding is closed by source revalidation.

**Checkpoint 19.16 final status:**  
AUTHORITY_BOUNDARY_GAPS_RECONFIRMED — RL-564 ADDED — HAI_INGRESS_NOT_ESTABLISHED — NO_GO_FOR_PRODUCTION_REMEDIATION_OR_CERTIFICATION.

**Next checkpoint:** 19.17 — RL-564 Adversarial Registry-Mint Regression Design and Full Council/Registry Effect-Consumer Closure Matrix.