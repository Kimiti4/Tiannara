# Checkpoint 19.17 — RL-564 Adversarial Registry-Mint Regression Design and Full Council/Registry Effect-Consumer Closure Matrix

**Date:** 2026-11-11  
**Pinned implementation source:** de231a78db542a6172d7bd1ffd46e8a766deafa4  
**Audit branch at start:** audit/consolidated-findings-r0a-2026-10-31  
**Starting audit-branch head:** 8e29199228f536ccde9f9269e9fdd8ce3e092a39  
**Mode:** read-only source and test-body review; regression design only

**Disposition:** REGRESSION_DESIGN_COMPLETE — RL-564 REFINED — RL-565 ADDED — CONSUMER_MATRIX_DOCUMENTED — EXECUTION_NOT_RUN

## 1. Executive determination

CP19.17 traced the pinned implementation paths for MintRegistry mint, bind, status, binding and consume operations; the HumanDelivery and MachineAuthorization minters; identified Omega and Phase4 consumers; the WorldMutationEngine and UnifiedWorldModel machine-authority path; Council authorization callers; and existing adversarial tests.

Two distinct authority defects are established:

- **RL-564 — HIGH / OPEN, refined:** HumanDelivery.Authorization.record_mint/1 can register an arbitrary caller-selected authorization ID because MintRegistry trusts the wrapper module stack origin, not a verified grant-issuance capability. Phase4.ExecutionGovernance.begin/2 trusts the struct plus registry status/binding and does not independently verify the human issuer or authenticated principal. The existing R-2 test proves arbitrary-ID registration; the D127.6 test checks only a forged ID that remains unregistered.
- **RL-565 — HIGH / OPEN, new:** MachineAuthorization.mint/2 accepts a caller-constructed Council.Authorization struct if its public decision predicate and decided_at field pass. It hashes and registers the caller-supplied struct from an allowlisted module, but does not verify that Council issued it. UnifiedWorldModel.delete_entity/2 then trusts the registered, effect-bound machine struct after structural/hash/scope checks and does not independently verify a Council-issued decision receipt. This gives a source-derived in-node path from fabricated approval to canonical entity deletion.

The report defines adversarial regression cases that combine the currently separate tests. These tests are designed but not authored or executed in CP19.17. There was no build, ExUnit run, CI run, runtime boot, live API call, registry mutation, deployment or physical actuation.

Important effect-surface distinctions:
- GovernedEffectSink writes one internal EventStore topic; it is a bounded internal sink, not a universal executor.
- DeploymentGateway transitions a Candidate state and records a deployment; this is not proof of cloud infrastructure or hardware deployment.
- RealExecution is feature-flagged, with the flag defaulting to false; its sandbox entry is downstream of ExecutionGovernance.
- PhysicsPilotExecution uses the same admission gate but runs a physics-model computation, not physical hardware.
- The physical deployment HTTP path remains separate from Council/MintRegistry and is covered by RL-434, RL-439 and RL-470.

## 2. Source identity and scope

The recursive tree at the pinned source commit contained 28,377 entries, was not truncated, and contained 4,533 Elixir source/test files. All implementation paths used for positive claims were re-fetched at the pinned source ref. GitHub indexed search is default-branch scoped and was used only to discover candidate call sites; its negative results are not treated as proof of global absence.

### 2.1 Core implementation blob identities

| Source path | Blob SHA |
|---|---|
| lib/tiannara/omega/mint_registry.ex | 2ea06c365d4d51224edef812e27084d50244d8e3 |
| lib/tiannara/omega/human_delivery/authorization.ex | af44fa72306d56337bdfa609ff7c5f5498162c21 |
| lib/tiannara/omega/human_delivery/authenticated_human_identity.ex | 901bb2022929c3439f683a38403476ad685f9f3f |
| lib/tiannara/omega/human_delivery.ex | 53648723d716307f91784221970d509167a86cc4 |
| lib/tiannara/council/authorization.ex | b323caf37dff786953fc183b6ab5b151c42c6c92 |
| lib/tiannara/council/machine_authorization.ex | bb338fa6fc0d3e681c2370838757c858b0fdaa0e |
| lib/tiannara/council/council.ex | 26564ecd3e4b67aecb27948c591dfb294fae9dcd |
| lib/tiannara/council/human_approval_queue.ex | 7b54511eec3c41881d34f5abbd6029593b3a9165 |
| lib/tiannara/council/human_approval_resumer.ex | f0f994aa03bd218c53f4436842ce8767965f2bda |
| lib/tiannara/council/policy_registry.ex | 4059eedba21336be400b32b54cb79427fc8dd007 |
| lib/tiannara/council/constitution_repository.ex | 8ab4e4fc2ec580c8e6fe77d24725beb6abdb6678 |
| lib/tiannara/council/audit_log.ex | eb0ac2760008adba5d9ab1ffab75f01c9983c6dc |
| lib/tiannara/omega/governed_effect_sink.ex | 315c04395709095a63585764dd7cc32e75b85207 |
| lib/tiannara/omega/deployment_gateway.ex | af5ae58ec5d0b502b4324fbe8102e6c9a538b388 |
| lib/tiannara/phase4/execution_governance.ex | f791f0fbd5ed1b1babe244998ef38bd201fad14d |
| lib/tiannara/phase4/real_execution.ex | dd4d988288a0a67230e3007a7e04dda3683b2284 |
| lib/tiannara/phase4/physics_pilot_execution.ex | 7f46e333f9fcbe38144934f0d40695a03da1353e |
| lib/tiannara/phase4/experiment_orchestrator.ex | 8568b98c0997d0913b39ddf64678a200992b58f |
| lib/tiannara/world/world_mutation_engine.ex | c11153247f7d6c909ddab1b7aff94765d3ea13e1 |
| lib/tiannara/world/unified_world_model.ex | 00c166999db01d096c04fbc7e6e2e6e730d5cadb |
| lib/tiannara/cel/kernel.ex | 31823da23d55a3686ac6e393f562e2acd28bbf55 |
| lib/tiannara/cel/services/resource_manager.ex | e4fc8f69065677fbf9beee0d3c7e91411a6c7f40 |
| lib/tiannara/forecasting/adapters/decision.ex | 1dd04fce68885d35ad4193b0cb39bdb3b755c504 |
| lib/tiannara/aeo.ex | 179bdf7e3edb17595044aa45bd29d57e8ccb38ef |
| lib/tiannara/omega/verification/baseline.ex | e64cd2da993a17825930a323bb981d4d1d5db9b9 |
| lib/tiannara/omega/verification/campaign.ex | 90ed98784dc20aeebe06976b100ffffd6bfa45cf |
| lib/tiannara/control_center.ex | 7e8c675714553eea58e73d642b3c3dc87bdc3960 |
| lib/tiannara/application.ex | 142d6c18122720a332569cbdf36ae492604273a0 |

### 2.2 Relevant test blob identities

| Test path | Blob SHA |
|---|---|
| test/tiannara/omega/step13_r2_mint_authentication_test.exs | 1e4c6c7b59d5108bf0c4d56dd0cd46797095f9e3 |
| test/tiannara/omega/d127_authorization_attack_test.exs | 9caeb9c41e7f25219f09b2c331b262aca45b238b |
| test/tiannara/phase4/execution_governance_test.exs | c0cc7ce52b8614eb6e04563da2141a4ddffe2568 |
| test/tiannara/phase4/real_execution_test.exs | 9283156cb3c03cf979cde6293a4c851f35828f9f |
| test/tiannara/world/d127_council_path_evaluation_test.exs | 729649f92bdbb6be1839ba042f8e39d7e8f481f0 |
| test/tiannara/omega/deployment_gateway_adversarial_test.exs | cc682b6cb1813db9a3ba227a8e5af6139a1bbc4e |
| test/tiannara/omega/deployment_gateway_registry_test.exs | d26a4bb1243d453c21475e32490d5acb716db76f |

The UWM deletion test is test/tiannara/world/d127_uwm_delete_evaluation_test.exs. It obtains a genuine Council decision in its helper before calling MachineAuthorization.mint/2. Its D127.6 case mutates a previously minted wrap to a fresh authorization ID and confirms that the new ID is not registered. It does not call MachineAuthorization.mint/2 with a caller-constructed Authorization.approved/1 struct.

## 3. MintRegistry API and issuer-boundary review

MintRegistry is a local GenServer backed by a framed append-only file. Its in-memory state tracks grant status, binding and optional Council decision-reference digest.

| API | Function | Identified callers / consumers |
|---|---|---|
| record_mint/2 | Register ID as :granted and optional decision digest | HumanDelivery.Authorization.record_mint/1; private MachineAuthorization mint helper; Omega.Verification.Baseline.establish/1 |
| record_bind/3 | Register one effect binding for an existing unconsumed ID | MachineAuthorization.bind_effect/2; Phase4.ExecutionGovernance; Verification.Baseline |
| status/1 | Read granted/consumed/unregistered state | ExecutionGovernance; DeploymentGateway; GovernedEffectSink; WorldMutationEngine; UnifiedWorldModel |
| binding/1 | Read durable effect binding | ExecutionGovernance; DeploymentGateway; GovernedEffectSink; UnifiedWorldModel |
| decision_ref/1 | Read stored decision digest | Tests and registry inspection; not an independent issuer proof |
| consume/2 | Atomic granted-to-consumed transition | ExecutionGovernance; DeploymentGateway; GovernedEffectSink; WorldMutationEngine; UnifiedWorldModel |

### 3.1 Minting boundary

MintRegistry's minter allowlist contains Tiannara.Council.MachineAuthorization, Tiannara.Omega.HumanDelivery.Authorization and Tiannara.Omega.Verification.Baseline. The registry inspects the caller's stack origin after dropping infrastructure frames. This authenticates only that an allowlisted module appears at the expected point in the in-node call stack. It is not an opaque issuance capability, credential, signature or proof that the allowlisted function validated a real approval.

The public HumanDelivery.Authorization.record_mint/1 wrapper takes only an authorization ID and forwards it to MintRegistry. The R-2 test explicitly demonstrates that an arbitrary fresh ID becomes :granted through this wrapper. The wrapper has no grant struct, verified principal, approved queue record, issuance receipt or Council decision digest to validate.

MachineAuthorization.mint/2 is also an allowlisted mint path, but it accepts a public Council.Authorization struct and validates its structural decision predicates rather than a Council-issued receipt. This is the separate RL-565 defect.

### 3.2 Binding boundary

MintRegistry.record_bind/3 ignores the GenServer caller identity. Its handler checks whether the ID is registered, unconsumed, not already bound and whether any stored decision-reference digest matches the supplied reference. It does not require the original issuer, a reviewer capability or a verified Council/human issuance receipt.

Therefore the registry's stack-origin test on record_mint/2 does not by itself secure record_bind/3. Each consumer's exact binding check is useful defense in depth, but it does not convert an unproven mint into a valid human or Council decision.

### 3.3 Current mint and bind call graph

Human path: caller → HumanDelivery.Authorization.record_mint(id) → MintRegistry.record_mint(id). The wrapper accepts only a caller-supplied ID; no grant, identity, approval proof or Council reference is supplied.

Machine path: caller → MachineAuthorization.mint(decision_struct, opts) → public decision predicate and decided_at checks → digest of caller-supplied struct → MintRegistry.record_mint(generated_id, decision_ref).

Verification baseline path: Omega.Verification.Baseline.establish/1 creates a candidate and local identity, prepares a human grant, then explicitly calls MintRegistry.record_mint/2 and record_bind/3. Omega.Verification.Campaign.run/1 calls the baseline as part of verification scenarios. This is not evidence of a general root-production grant-issuance service.

## 4. RL-564 — wrapper-assisted human registry mint

**RL-564 — HIGH / OPEN — HumanDelivery.Authorization.record_mint/1 permits caller-selected registry IDs through an allowlisted minter wrapper, and the Phase4 admission gate relies on that registry status without validating issuer provenance.**

The R-2 test rejects direct MintRegistry.record_mint/1 from a non-allowlisted test process, then calls HumanDelivery.Authorization.record_mint(arbitrary_id), asserts :ok and MintRegistry.status(id) == :granted, and rejects a second registration only because that ID already exists.

The D127.6 human sink test creates a complete-looking Authorization struct with a new ID and checks that the sink refuses it because the ID is unregistered. It never calls the public wrapper on that ID. The two tests expose a missing composed negative case.

### 4.1 Phase4 consumer composition

ExecutionGovernance.begin/2 checks that a HumanDelivery.Authorization struct has status :granted and is not expired. It then checks MintRegistry status, derives a canonical effect ID, binds the grant if necessary, checks the registry binding, claims the effect in ETS and consumes the grant.

It does not independently require a trusted identity-provider proof, a verified human principal or reviewer role/scope, a Council or HumanDelivery issuance receipt, or proof that the grant was actually created by Authorization.human_grant/2.

RealExecution.execute/1 calls ExecutionGovernance.begin/2 before open_execution and RealHarness.run. Its initial guard checks only that a HumanDelivery.Authorization struct is present. RealExecution.enabled?/0 defaults to false unless real_execution_enabled is explicitly true; ExperimentOrchestrator.submit_experiment/1 also checks that flag. A forged grant composed through the wrapper is therefore a source-confirmed admission weakness, but no sandbox execution occurred in CP19.17. The caller must still provide a syntactically valid substrate; the separate RL-482 backend trust defect remains open.

PhysicsPilotExecution.execute/1 shares ExecutionGovernance.begin/2 and the same flag, but runs a domain-physics simulation; it is not hardware actuation.

### 4.2 Other sinks

**GovernedEffectSink.execute/3:** requires a registered grant, binding, matching effect ID and an AuthenticatedHumanIdentity whose helper predicate passes and whose human_id matches the grant. It consumes the registry authorization and appends one event to the internal EventStore topic governed.effect, then writes a Council AuditLog edge. No direct normal lib/ caller was established in this bounded source pass; it is a callable bounded sink exercised in adversarial tests. Identity remains separately weak under RL-426.

**DeploymentGateway.deploy/6:** checks candidate status, grant status/expiry, human identity predicate, candidate content hash, registry status, exact effect binding, then consumes and transitions the Candidate status. This is a candidate lifecycle/deployment record mechanism; it is not itself proof of cloud, external infrastructure or hardware deployment. The direct production module call site found is RealExecution.maybe_deploy/3. That path passes the same grant already consumed and bound to the Phase4 execution descriptor by ExecutionGovernance.begin/2. It cannot then pass DeploymentGateway's different candidate-deployment identity and unconsumed-registry checks. This is existing RL-480.

**HumanDelivery.authorize/3:** returns a grant from in-memory HumanDelivery state without durable mint/bind completion. Existing RL-479 remains open. RL-564 is a different defect: the wrapper can mint an arbitrary ID, whereas ordinary HumanDelivery.authorize/3 does not complete durable minting itself.

### 4.3 RL-564 regression design

Recommended new file: test/tiannara/omega/rl564_registry_issuance_adversarial_test.exs, with focused cross-consumer cases in Phase4 and Omega suites. Do not append these tests to PR #13; retain that PR as the two-file CP19.10 baseline.

| Case | Construction | Required safe behavior | Current source-derived behavior |
|---|---|---|---|
| R564-01 arbitrary ID via wrapper | Call Authorization.record_mint/1 with ID for which no issuance receipt exists | Reject; status remains :not_registered | Returns :ok and status becomes :granted; existing R-2 test asserts this |
| R564-02 forged grant into Phase4 | Construct complete status :granted Authorization struct; call wrapper; call ExecutionGovernance.begin/2 | Reject before binding, ETS effect claim and consume | Current source checks struct + registry and can admit it |
| R564-03 forged grant into internal sink | Wrapper-register forged grant, bind canonical descriptor, supply identity accepted by current helper, call GovernedEffectSink with instrumented sink callback | Refuse before sink callback, EventStore event and consume | Source composition satisfies current checks if dependencies are running |
| R564-04 forged grant into candidate gateway | Build approved Candidate, matching proposal ID/content hash, wrapper-register and bind fake grant, provide identity accepted by helper | Refuse before transition, consume or audit success | Source composition can satisfy current Gateway predicates; no external infrastructure effect is implied |
| R564-05 Phase4 sandbox path | Enable flag only in isolated test; pass valid controlled test substrate and forged wrapper-registered grant; instrument backend callback | Reject before RealHarness backend callback and execution ledger/event | Current source can pass ExecutionGovernance and proceed to backend if substrate requirements are satisfied |
| R564-06 direct non-allowlisted mint | Direct call MintRegistry.record_mint/2 from ordinary test process | Continue to refuse and leave no row | Existing R-2 case already asserts this |
| R564-07 unauthorized bind | Attempt record_bind/3 from a non-issuer with an existing ID | Require opaque issuance/bind capability and issuer provenance | Current handler ignores caller identity |
| R564-08 subject/digest substitution | Reuse receipt with changed ID, human, request digest, operation, policy/constitution version, expiry or candidate hash | Reject each mismatch | Human wrapper has no receipt/digest to compare |
| R564-09 race/replay | Present N copies of one legitimately issued grant concurrently | Exactly one admission/consume; all other attempts named refusals | CAS exists; preserve as a positive regression |
| R564-10 restart/corruption | Restart registry after mint/bind/consume, then query and replay; corrupt/partial record cases | Recover valid history; incomplete/corrupt state unavailable/fail-closed | Separate durability/recovery limitations remain RL-478/RL-481 |
| R564-11 standard issuance | Exercise HumanDelivery.authorize/3 through its pending request | Return a complete durable grant or explicit non-admissible pending object; never claim usability before durable steps | Current handler does not finish durable mint/binding; RL-479 |

Use unique IDs and an isolated MintRegistry path. Start isolated registry, EventStore and AuditLog dependencies under test supervision. Restore application env flags and all registered process names in after blocks. Keep tests async: false where named global services or ETS are involved. Do not use the application-owned singleton across async tests without deterministic cleanup.

For R564-02/05 and R564-03/04, assert more than the returned error: registry status and binding unchanged; effect-consumption state unchanged; ExecutionGovernance.executed?/1 false; instrumented backend/sink callback counter zero; EventStore topic event count unchanged; no execution ledger row or audit-success entry; and no Candidate transition/deployment record.

Proposed target error labels, not current implementation behavior: :grant_issuance_proof_required and :authorization_provenance_invalid.

## 5. RL-565 — public machine mint accepts fabricated Council decisions

**RL-565 — HIGH / OPEN — MachineAuthorization.mint/2 accepts caller-constructed Council.Authorization structs as Council-issued decisions, allowing the public UnifiedWorldModel.delete_entity/2 sink to accept fabricated machine authority.**

MachineAuthorization.mint/2 is public. Its inspected acceptance checks are structural: input is a Council.Authorization struct; Authorization.permitted?/1 or conditional_grant?/1 returns true; decided_at is non-nil; decision_type is a non-nil atom; and TTL is an integer.

Council.Authorization.approved/1 is also a public constructor. It returns a struct with decision :approved and current decided_at; the caller may supply policy_applied and other metadata. MachineAuthorization hashes that caller-provided struct and asks MintRegistry to register a generated ID from the allowlisted MachineAuthorization module. The registry's decision_ref digest therefore anchors the supplied struct, not proof that Council issued it.

The R-2 test explicitly constructs Authorization.approved(...) and passes it to MachineAuthorization.mint/2, then asserts that the registry says :granted. That is positive evidence of the permissive input contract.

### 5.1 Effect consumer: UnifiedWorldModel.delete_entity/2

UnifiedWorldModel is in the ControlCenter subsystem list and exposes delete_entity(entity_id, authorization) as a public GenServer API. The delete handler checks a MachineAuthorization struct; registry status :granted; expiry; authority_class == :machine; decision_type == :delete_entity; embedded Council.Authorization struct and permitted/conditional predicates; non-nil policy_applied and decided_at; matching content_hash; canonical target effect identity; matching registry binding; and successful registry consume.

The delete handler does not call Council.authorize/3 or verify a Council-issued decision receipt. It then removes the canonical UnifiedRealityGraph entity and relationships, publishes an event and audits.

Source-derived attack composition (not executed):

~~~elixir
decision =
  Tiannara.Council.Authorization.approved(
    explanation: "fabricated approval",
    policy_applied: :fabricated_policy
  )

{:ok, machine_grant} =
  Tiannara.Council.MachineAuthorization.mint(
    decision, decision_type: :delete_entity, ttl: 3600
  )

{:ok, bound} =
  Tiannara.Council.MachineAuthorization.bind_effect(
    machine_grant, Tiannara.World.UnifiedWorldModel.effect_descriptor(entity_id)
  )

Tiannara.World.UnifiedWorldModel.delete_entity(entity_id, bound)
~~~

If the target entity and supervised services exist, the source conditions are satisfiable. This is an in-node/public module API attack composition, not a remote exploit demonstration. No external HTTP route to this API was established in this checkpoint and no entity was deleted.

### 5.2 Existing test gap

- step13_r2_mint_authentication_test.exs constructs a public Authorization.approved struct and asserts that MachineAuthorization.mint succeeds.
- d127_council_path_evaluation_test.exs exercises WorldMutationEngine's internal Council.authorize path and context injection; it does not test direct MachineAuthorization.mint/2 with fake approval.
- d127_uwm_delete_evaluation_test.exs obtains decisions from Council.authorize in its helper before minting. It covers replay, concurrency, wrong operation type, field tampering, effect mismatch, unregistered ID mutation, registry unavailable and audit failure. It does not construct Authorization.approved directly and pass it to MachineAuthorization.mint.
- Its D127.6 case therefore proves that an unregistered wrap is refused, not that a fake decision cannot be minted through the public machine minter.

### 5.3 RL-565 regression cases

| Case | Construction | Required safe behavior | Current source-derived behavior |
|---|---|---|---|
| R565-01 fabricated approved struct | Authorization.approved(policy_applied: :fabricated_policy) → MachineAuthorization.mint(:delete_entity) | Reject before registry write | Current mint accepts if structural predicates pass |
| R565-02 manually reconstructed decision | Construct complete Council.Authorization with :approved, policy_applied and decided_at but no Council receipt | Reject; no registry row | Current mint can accept |
| R565-03 full UWM delete chain | Create fixture entity; fake approved struct; mint; bind to UWM descriptor; call delete_entity | Refuse before consume, audit or graph deletion; entity remains | Current handler predicates can be satisfied by source-derived sequence |
| R565-04 proof substitution | Use a genuine Council proof then alter decision, actor, policy, scope, payload, version or expiry | Reject proof mismatch | No Council proof/capability currently exists in this route |
| R565-05 wrong operation | Present update grant to delete sink | Preserve :decision_type_mismatch | Existing D127 UWM test covers this |
| R565-06 other target | Bind to entity A and present for B | Preserve effect/binding mismatch | Existing tests cover this |
| R565-07 replay/concurrency | Race same genuine machine grant against delete | Exactly one deletion and consume | Existing UWM tests cover this |
| R565-08 emergency | Activate Council emergency and attempt new machine mint/delete | No grant minted and no deletion | Existing WME emergency test does not test direct machine mint |

### 5.4 Required machine-issuer contract

MachineAuthorization.mint/2 must not treat a structurally valid Authorization struct as proof that Council issued the decision. Require an opaque Council-issued, one-time capability or issuer-verifiable receipt binding decision type and operation scope; exact canonical payload/effect descriptor or pre-issuance digest; decision, conditions and evidence digest; issuing Council identity/version; active policy and constitution versions; actor/principal and authority class; issue time, expiry and one-time nonce.

Validate the proof through a Council-controlled authority interface before minting. UnifiedWorldModel.delete_entity/2 must verify the same provenance at the effect boundary; a hash produced by the same caller-controlled object is not an issuer proof.

Proposed target error label, not current implementation behavior: :council_decision_proof_required.

## 6. Full in-scope Council and registry effect-consumer matrix

This source-level matrix distinguishes obtaining a decision object from recording a grant, binding an effect and invoking an effect.

### 6.1 MintRegistry consumers

| Consumer | Registry operations | Downstream effect | CP19.17 disposition |
|---|---|---|---|
| Phase4.ExecutionGovernance.begin/2 | status → record_bind if unbound → binding → claim effect → consume | Admission for RealExecution and PhysicsPilotExecution | RL-564: provenance and human identity not independently verified |
| Phase4.RealExecution.execute/1 | Via ExecutionGovernance | Runs RealHarness backend after admission | Feature flag defaults false; backend trust/isolation RL-482 remains open |
| Phase4.PhysicsPilotExecution.execute/1 | Via ExecutionGovernance | Physics-domain computation/simulation | Same flag; not hardware actuation |
| Omega.GovernedEffectSink.execute/3 | status → binding → consume | One internal EventStore topic and Council audit edge | Bounded sink; no normal lib/ caller established in this pass |
| Omega.DeploymentGateway.deploy/6 | status → binding → consume | Candidate status transition, deployment record and audit | RealExecution call reuses consumed execution grant; RL-480 |
| WorldMutationEngine.mutate/3 | MachineAuthorization mint → bind → status/hash verify → consume | DETS mutation record and world-change publication path | Normal path calls Council.authorize and decision checks |
| UnifiedWorldModel.delete_entity/2 | status → binding → consume | Removes entity and relationships in canonical UnifiedRealityGraph | RL-565: no Council issuer-proof check at delete boundary |
| Omega.Verification.Baseline.establish/1 | Direct mint + bind | Verification baseline/candidate grant | Verification workflow, not established as normal production deployment |
| MachineAuthorization public mint/bind | Mint + bind | Supplies machine grant to caller | RL-565: fabricated Council decision can be minted |

### 6.2 Council.authorize/3 callers

| Caller | Council request | Decision handling and effect | CP19.17 disposition |
|---|---|---|---|
| CEL.Kernel.restart_service | :architectural_change; nil context | Requires permitted? or conditional_grant? before restart | Immediate decision consumer; actor field is not authenticated by this call |
| CEL.Kernel.halt | :architectural_change; nil context | Requires strict permitted? before terminating services | Strict approval; no conditional shortcut |
| CEL.Services.ResourceManager.allocate | :resource_reallocation only for requests exceeding 50% | Accepts :approved or :conditional decision labels then allocates | Conditional consumer does not validate conditional_grant? |
| WorldMutationEngine.mutate | :world_mutation with caller context | check_decision validates approved/conditional conditions, then machine mint/bind/consume before mutation record | Canonical governed world-mutation route; graph transaction issues separately open |
| Phase4.ExperimentOrchestrator.check_constitutional_gate | :high_risk_experiment for classified high/critical | Accepts decision label :approved or :conditional | Not conditions-verified at consumer; low/medium path skips Council in this helper |
| Forecasting.Adapters.DecisionImpl.authorize | :efdi_decision | Returns Council decision; separate submit_intent calls AEO | No source invariant binding authorize result to AEO submission order |
| HumanApprovalResumer | Public resume_human_approval/3 | Records re-evaluated decision in queue history | Caller checks approved status; Council API does not enforce it itself (RL-413) |

### 6.3 Council/policy/constitution APIs without a verified effect-bound caller

| API | Caller / route evidence | Trust classification |
|---|---|---|
| HumanApprovalQueue.approve/reject | No HAI Phoenix route or bounded production caller found | Caller-supplied human ID; RL-412 |
| HumanApprovalQueue.approved_request | Council.authorize uses it for require_human policy | Exact raw-payload equality in in-memory history; reusable and no expiry; RL-414 |
| Council.resume_human_approval/3 | Normal caller is HumanApprovalResumer | Public direct resumption without checking queue record inside Council; RL-413 |
| Council.invoke_emergency/lift_emergency | Local API and tests; no router route established | Actor/human ID asserted by caller; append errors ignored; existing emergency findings |
| PolicyRegistry.register_policy/1 and disable_policy/1 | No production caller established in this pass | Direct live policy mutation without Council authorization in handler; RL-122 |
| ConstitutionRepository.commit/3 and rollback/2 | No production caller established in this pass | Direct constitution mutation without Council authorization in handler; RL-123 |
| AuditLog.append/3 | Used by Council, queue, world and effect paths | Hash chain does not authenticate actor; some Council/queue callers ignore append failures |

### 6.4 Alternate paths outside the registry gate

| Path | Council/MintRegistry relationship | Effect classification | Disposition |
|---|---|---|---|
| UnifiedWorldModel create/update/refute/relationship/stage handlers | Call WorldMutationEngine | Canonical graph writes/events | Governed route exists; graph sequencing/atomicity findings remain open |
| UnifiedWorldModel.delete_entity/2 | MachineAuthorization + MintRegistry but no Council call inside delete handler | Canonical graph deletion | RL-565 |
| Snapshot restore / VersionManager rollback / RealityCoordinator source-wins | Direct or misordered UnifiedRealityGraph writes | Canonical graph mutation | Existing RL-325–RL-327 and world-writer findings |
| AEO.submit_to_runtime/1 | Validates planned graph and adapter receipt; no Council call within AEO | Runtime adapter submission | DecisionImpl authorize is separate; ordering not enforced by AEO; caller not established here |
| ASC RealityDirector → DigitalDeploymentManager | No Council/MintRegistry in inspected call chain | In-memory deployment status/endpoint record | Not proof of live infrastructure deployment |
| Phoenix PhysicalDeploymentManager API | No Council/MintRegistry gate; API pipeline lacks visible auth plug | Default SimulatedAdapter; no HTTP execute route | RL-434/RL-439/RL-470; no hardware actuation proven |
| ToolForge request_human_review | No actual HAI/Council approval | False human-review acknowledgement | RL-559 |

### 6.5 Completeness and bounds

This matrix covers the in-scope API consumers identified and exact-pinned implementation paths inspected. It is not proof that no dynamically loaded, runtime-injected, external plugin or unindexed caller exists anywhere in the repository. Bounded search negatives remain UNKNOWN, not proof of global absence.

## 7. Existing test coverage reconciliation

| Existing test | Positive proof / negative case | Missing proof exposed by CP19.17 |
|---|---|---|
| R-2 mint authentication | Direct registry caller is refused; allowlisted wrapper registers; MachineAuthorization mint on a public approved struct succeeds | Must deny arbitrary-ID wrapper mint and fabricated Council-decision mint |
| D127.6 human sink reconstruction | Unregistered forged HumanDelivery struct is refused | Does not first use allowlisted wrapper on forged ID |
| D127.1–D127.5 human sink tests | Replay, copy, identity mismatch with nil timestamp, effect amplification and registry binding mismatch denied | Identity helper accepts arbitrary non-empty credential; no trusted issuer/session verification |
| Phase4 ExecutionGovernance tests | Unminted, denied, expired and replay grants refused; legitimate grant admitted | No forged struct registered through wrapper |
| DeploymentGateway adversarial tests | Missing grant, wrong candidate, nil-timestamp identity, invalid certification shape, expiry, candidate mutation and lineage errors refused | No wrapper-assisted forged grant |
| WME Council gate tests | Normal WME path performs Council authorize, decision checks, machine mint/bind/consume and audit | No direct fake Authorization input to MachineAuthorization.mint |
| D127 UWM delete evaluation | Council-authorized delete, replay, concurrency, wrong operation, tampering, wrong target, unregistered-ID and audit failure cases | No fake Authorization.approved → public mint → bind → delete chain |

The present tests establish registry status, binding, one-shot consumption and several sink properties. They do not establish that the mint originated from Council or a trusted human issuer.

## 8. Ordered remediation and test sequence

Do not fix these findings by merely moving record_mint/2 to a different allowlisted wrapper. The trust proof must be independent of the name of a module on the BEAM stack.

1. Define separate trusted issuer contracts: Council for machine decision provenance; a verified identity provider for human principal authentication.
2. Replace caller-selected arbitrary-ID minting with an opaque, verified issuance capability. Registry should derive or validate ID/digest binding from the receipt.
3. Bind principal, authority class, exact operation and effect descriptor, payload digest, policy/constitution versions, decision/evidence digest, expiry and one-time nonce to the mint.
4. Make effect binding require a validated issuer capability and sink-computed canonical descriptor; do not leave record_bind/3 as a capability-free public transition.
5. Verify provenance at every effect consumer: ExecutionGovernance, GovernedEffectSink, DeploymentGateway, WorldMutationEngine and UnifiedWorldModel.
6. Restrict MachineAuthorization.mint/2 to a Council-verifiable receipt; do not accept caller-created Council.Authorization structs as issuer proof.
7. Fix RL-479: standard HumanDelivery authorization must complete durable mint and binding through one recoverable workflow or return a visibly non-admissible pending object.
8. Resolve RL-480 by requiring distinct grants for distinct effects or by representing and verifying an explicit compound effect. Do not reuse a consumed grant for a different descriptor.
9. Fix consumer-side conditional authorization checks; use conditional_grant?/1 rather than trusting a :conditional label.
10. Add R564 and R565 adversarial tests first, retaining legitimate issuance and replay controls.
11. Run on Elixir 1.18 / OTP 28 with disposable checkout, isolated DETS, registry, audit and ETS state; capture exact candidate commit and full root/focused results.
12. Independently inspect and verify the exact candidate commit. Compile-only or report-only results do not close either finding.

## 9. Finding disposition

| Finding | CP19.17 disposition |
|---|---|
| RL-122 / RL-123 | Revalidated previously; OPEN |
| RL-412–414 | Queue and resumption boundaries remain OPEN |
| RL-426 | Human identity helper remains forgeable/non-validating; OPEN |
| RL-434 / RL-439 / RL-470 | Physical approval route defects remain OPEN |
| RL-478 / RL-481 | Unbound-consume registry invariant and corrupt-record recovery limitations remain OPEN |
| RL-479 | Ordinary HumanDelivery grant does not durably mint/bind; OPEN |
| RL-480 | RealExecution consumes/binds grant before optional deployment reuses it; OPEN |
| RL-482 | RealExecution backend trust/isolation policy remains unenforced; OPEN |
| RL-558 / RL-559 / RL-562 | HAI, ToolForge and constitutional evidence defects remain OPEN |
| RL-564 | HIGH / OPEN — refined with Phase4, internal-sink and gateway consumer composition |
| RL-565 | HIGH / OPEN — NEW — fabricated Council.Authorization can be minted as machine authority and accepted by UWM delete sink |
| HAI production ingress | UNKNOWN / NOT ESTABLISHED |
| GovernedEffectSink normal production ingress | No direct lib/ caller established in this bounded source pass; tests and bounded sink only |

## 10. Execution and change boundary

- Regression tests were designed but not authored or executed.
- No compile, ExUnit, root test, CI workflow, runtime boot, live API request, registry mutation, simulation, deployment or physical actuation was performed in CP19.17.
- No production source, tests, application configuration, persistent state, Council authority or runtime state was modified.
- PR #13 remains the separate CP19.10 two-file draft regression baseline and must remain unchanged.
- CP19.17 adds RL-565 and refines RL-564. No existing finding is closed.

**Checkpoint 19.17 final status:**  
RL564_REGRESSION_DESIGN_COMPLETE — FULL_IN_SCOPE_CONSUMER_MATRIX_DOCUMENTED — RL565_ADDED — TEST_EXECUTION_NOT_RUN — NO_PRODUCTION_CHANGE.

**Next checkpoint:** 19.18 — implement the isolated CP19.17 adversarial regression suite for RL-564/RL-565 (tests only), execute on Elixir 1.18 / OTP 28 in a disposable checkout, and capture red-baseline evidence. Production remediation remains a separate authorization decision after the regression behavior is proven.
