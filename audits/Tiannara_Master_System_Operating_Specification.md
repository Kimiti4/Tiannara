# Tiannara Master System Operating Specification (TMSOS)

**Document ID:** TMSOS-001  
**Version:** 0.1.0 — initial evidence-backed operating map  
**Status:** ACTIVE / INCOMPLETE — living specification; not a production certification  
**Scope:** Tiannara AI repository `Kimiti4/Tiannara` only. ESAP / `Kimiti4/autonomous-API-Gen` is a separate system and is outside this specification.  
**Initial source baseline:** `96e93475f99d6f2ca68660efcafaa9451851533b`  
**Created at:** Checkpoint 18.94, 2026-11-09  
**Companion audit ledger:** `audits/Tiannara_AI_Audit_Findings_R0-A_to_Current_2026-10-31.md`

---

## 1. Purpose and operating rules

TMSOS is the master map of Tiannara's systems, responsibilities, authority boundaries, interfaces, dependencies, data ownership, lifecycle behavior, evidence requirements and hardening work.

It exists to prevent local fixes from creating new inconsistencies elsewhere. Every subsystem must be understood both independently and as part of the whole operating environment.

### 1.1 Evidence vocabulary

Every statement in this document must distinguish:

- **INTENDED** — stated purpose or normative design.
- **IMPLEMENTED** — behavior visible in source at a named commit.
- **CONNECTED** — an actual caller, event, API or data path links the system to its consumer.
- **ENFORCED** — the relevant control is applied at the state-owning or effect-owning boundary.
- **VERIFIED** — supported by reproducible evidence tied to an exact candidate commit.
- **UNKNOWN** — evidence is missing, ambiguous, stale or insufficient.
- **BLOCKED** — an explicit gate prevents the capability from proceeding.

These statuses are not interchangeable. Documentation, a type definition, an isolated test, a running process, a simulated result or a successful API response does not by itself prove end-to-end capability.

### 1.2 Constitutional and audit invariants

1. The Constitutional Council remains above CEL and all operational subsystems.
2. CEL coordinates execution and governance workflows; it does not replace constitutional authority or human ratification.
3. Human approval must be authenticated, bound to the exact action/effect and recorded before the governed effect.
4. Evidence must precede confidence and promotion.
5. UNKNOWN must never be converted into PASS by a default, missing field, swallowed exception or optimistic status.
6. Simulated, synthetic, imported and real-execution evidence must remain distinguishable.
7. A successful operation must not be reported until its required durable postconditions are acknowledged.
8. Issuance, lifecycle status, revocation, supersession and deployment admission are separate decisions.
9. A system may not self-assign authority merely by supplying an authority name or a boolean approval field.
10. Audits are read-only unless implementation work is separately authorized. Findings are closed only with exact-candidate evidence.

## 2. System authority hierarchy

| Level | System / actor | Authoritative responsibility | Must not do |
|---|---|---|---|
| 0 | Human constitutional ratifier | Final human decisions on constitutional amendments and reserved high-impact actions | Delegate final ratification to CEL or an autonomous subsystem |
| 1 | Constitutional Council | Constitutional policy, authorization, approval and audit authority | Treat unverified service claims as proof of compliance |
| 2 | CEL Kernel / executive governance | Coordinate governed service lifecycle, boot, health and authorized workflows | Supersede Council authority or manufacture service health |
| 3 | Domain authorities | Decide within a bounded, explicitly delegated domain | Expand their own authority or bypass upstream policy |
| 4 | Execution / evidence / certification authorities | Establish execution identity, evidence integrity and certification state within their contracts | Convert a claim, simulation or unbound label into verified real evidence |
| 5 | Deployment and physical-effect gateways | Enforce authorization and verified preconditions immediately before effects | Infer approval, certification, safety or revocation state |
| 6 | Observability / dashboards / reports | Read and present system state and evidence | Ratify, authorize, certify or deploy |

This is the target authority hierarchy. Each implementation must be checked against it; a module name or declared role does not prove its authority is enforced.

## 3. Core system operating register

The following is the initial evidence-backed register. Coverage is deliberately limited to systems inspected during the audit; uninspected systems remain pending rather than being presumed compliant.

| System | Primary role | State / authority owner | Principal interfaces | Current audit position |
|---|---|---|---|---|
| Constitutional Council | Constitutional policy, approval, human authority and audit | Council services and approved human actors | Council authorization, approval queue, AuditLog | Critical authority; prior open findings remain |
| CEL Kernel | Executive orchestration, service boot and governed lifecycle coordination | CEL Kernel and service registry | service contracts, boot sequencer, Council | Coordination authority, not constitutional authority |
| Evidence.Provenance | Construct provenance records and classify evidence | Provenance module; currently caller-supplied maps can also reach predicate | `build/1`, `unknown/1`, `acceptable_as_evidence?/1` | RL-488: acceptance weaker than construction |
| Evidence.CertificationGate | Accept, reject or quarantine scientific artifacts | CertificationGate predicate | artifact provenance map | Delegates to RL-488 predicate; no independent identity resolution |
| Forward IdentityAuthority | Mint/claim and resolve execution identities | ETS registry plus identity ledger | `mint`, `claim`, `resolve`, `registered?`, `export` | RL-487: lazy registry and best-effort ledger/replay |
| Forward Producer / RuntimeContract | Model execution lifecycle and produce normalized lineage/envelope representations | Caller-owned lifecycle map | begin/terminal helpers, accept, envelope conversion | Emit/normalize boundary; not itself a durable execution store |
| Forward MetricLineage | Verify lineage and metric/evidence bundle relationships | Lineage and bundle content | lineage verification, bundle verification | Separate certification-time verification path |
| Forward Bundle | Produce byte-bound evidence bundle | Bundle directory and manifest | bundle production and verification | Explicitly invoked; not automatically integrated into every general execution path |
| Forward CertificateIdentity | Deterministically derive certificate identity | Canonical identity input | `derive/2`, canonicalization | Identity derivation only; no issuance authority |
| Forward CertificateIssuance | Validate request and issue immutable certificate record | ETS issuance registry plus issuance ledger | policy gate, authority registration, bundle/lineage verification | RL-491/RL-492: persistence and replay defects |
| Forward CertificateLifecycle | Record permitted certificate lifecycle transitions | ETS lifecycle registry plus lifecycle ledger | transition, current_state, history | Revocation and supersession explicitly blocked; persistence/replay defects |
| World.KnowledgeCoordinator | Ingest, fuse, validate and promote world knowledge | UnifiedWorldModel; coordinator controls promotion calls | KnowledgeEvolutionEngine, EvidenceValidator, WorkflowEngine, EventBus | RL-489: promotion authority/evidence bypass and target-stage mismatch |
| World.KnowledgeEvolutionEngine | Evolve, age, retire and promote knowledge entities | UnifiedWorldModel | promote_entity, retire_entity, evolve | Promotion currently advances one stage and does not enforce evidence/target contract |
| Research.KnowledgeIntegrator | Integrate research findings into executive memory | GenServer state plus ExecutiveMemory when available | integrate, recent, real_knowledge, status | RL-490: caller label/confidence accepted; persistence best-effort |
| Research.Memory.Artifact | Typed research artifact and memory-stage promotion | Artifact value passed by caller | `new/4`, `promote/2` | Local checks for stage/evidence/confidence/contradictions; canonical execution binding not established |
| OS.DiscoveryRegistry | Register discoveries and move them through simulated/reproduced/operational states | In-memory GenServer | register, update_validation_status, link_to_law | Envelope checks are structural; no durable registry or canonical provenance resolution established |
| Omega.CertificationServer | Produce and retain improvement certification results; expose in-memory revocation API | GenServer certificate list | certificates, revoke_certificate, valid_certificate? | Ephemeral revocation state; not consulted by deployment gateway |
| Omega.DeploymentGateway | Enforce candidate deployment preconditions and consume authorization | MintRegistry, candidate transition, AuditLog | deploy/6, grant/effect checks, audit | RL-484 refinement: certification check does not resolve revocation or canonical certificate state |
| DeploymentRegistry | Optional deployment replay/idempotency record | File-backed caller-selected path | record_deployment, deployment_status | Optional; distinct from mandatory MintRegistry; binary term log requires integrity/recovery review |
| MintRegistry | Mandatory authorization-grant registration, binding and one-shot consumption | Registry/ledger implementation | status, binding, consume | Gateway uses it unconditionally; exact persistence/recovery is a separate audit scope |
| ExecutiveMemory / EventStore | Memory and event persistence/recall | Respective storage services | record_decision, put, append | Must not be treated as a universal transactional evidence ledger |

## 4. Scientific artifact lifecycle

### 4.1 Intended canonical flow

```text
Observation / source input
        |
        v
Experiment or research execution
        |
        v
Canonical execution identity
        |
        v
Terminal execution lifecycle + result binding
        |
        v
Provenance construction and validation
        |
        v
Lineage + metric manifest + evidence bundle
        |
        v
Independent evidence verification
        |
        v
Scientific artifact admission
        |
        v
Knowledge-stage promotion (one governed transition at a time)
        |
        v
Certificate candidate -> authorized issuance
        |
        v
Certificate lifecycle / validity decision
        |
        v
Deployment admission (if an operational effect is requested)
        |
        v
Observed effect + independently verified postcondition
```

This is the target flow, not a claim that the frozen source currently implements it end to end.

### 4.2 Required artifact contract

Every promotable scientific artifact must bind, as applicable:

- Stable artifact ID and immutable version.
- Source identity and producer identity.
- Experiment ID and canonical execution ID.
- Execution terminal state and terminal event identity.
- Result ID and result-payload digest.
- Evidence IDs and evidence payload digests.
- Provenance kind and complete provenance record.
- Lineage identity and parent/child edges.
- Metric definition, computation, aggregation, seed dependence and corpus manifest.
- Environment/dependency lock and input/output manifests.
- Reproducibility classification and explicit gaps.
- Contradictions, falsifiers, uncertainty and confidence.
- Current stage, requested next stage and transition decision.
- Approval identity, authority, action/effect binding and expiry when approval is required.
- Verification result and verifier identity.
- Durable record location and content digest.

Missing mandatory fields produce UNKNOWN/BLOCKED or quarantine. They must not be synthesized from caller labels.

### 4.3 Promotion rules

1. One canonical promotion authority owns stage transitions.
2. Every transition is evaluated against the current authoritative version and the exact requested next stage.
3. A request to jump stages is rejected unless a separate policy explicitly defines a validated multi-stage transition.
4. Confidence is not a substitute for evidence quality, provenance or replication.
5. A boolean such as `human_approved: true` is not an approval credential.
6. High-impact or constitutionally reserved promotion requires authenticated, payload-bound human approval.
7. The state owner commits the transition and audit record atomically or reports failure.
8. Consumers receive a committed transition event only after durable state is established.
9. A failed evidence check cannot leave the artifact at the requested higher stage.
10. Simulation and synthetic fixtures remain permanently distinguishable from real operational evidence.

## 5. Certificate and deployment operating model

### 5.1 Separate certificate predicates

| Predicate | Meaning | Owning system |
|---|---|---|
| Candidate | Evidence and decision inputs assembled | Certificate bridge |
| Identity | Deterministic certificate identity derived | CertificateIdentity |
| Authorized | Issuance authority and policy checks pass | CertificateIssuance |
| Issued | Immutable issuance record committed | CertificateIssuance |
| Active / valid | Current lifecycle state permits use | CertificateLifecycle plus authoritative verifier |
| Suspended | Temporarily not admissible | CertificateLifecycle |
| Unverifiable | Evidence or status cannot be established | CertificateLifecycle |
| Revoked | Permanently invalidated under an authorized revocation policy | Not implemented in inspected forward lifecycle |
| Superseded | Replaced through an authorized successor relation | Not implemented in inspected forward lifecycle |
| Deployment-admissible | Exact certificate, lineage, approval and effect are currently valid | Deployment admission authority |

A certificate's issuance record must never be mutated to simulate lifecycle change. Lifecycle changes are separate, append-only, independently verifiable records.

### 5.2 Required deployment-admission checks

Before any deployment effect, the gateway must verify:

- The exact candidate identity and content digest.
- The exact certificate ID and immutable issuance record.
- Issuer authorization and certificate decision.
- Certificate lifecycle state from the canonical lifecycle authority.
- Revocation and supersession status from a durable, authoritative source.
- Evidence bundle, lineage and execution binding.
- Current policy version and any required re-verification.
- Authenticated human grant, exact effect binding, expiry and one-time consumption.
- Current safety and constitutional constraints.
- Audit persistence before reporting a committed deployment.
- Post-effect observation and independently verified outcome.

A caller-supplied `%{verdict: :certified}` map is not a certificate authority. A certificate ID with no resolvable state is UNKNOWN and must not be admitted.

### 5.3 Revocation design requirement

Revocation must have one canonical authority and one durable state transition protocol. All admission points must consult it. In-memory revocation flags, bundle metadata and local caches are not authoritative revocation records.

The forward CertificateLifecycle implementation explicitly blocks revocation in the inspected baseline. Omega.CertificationServer has a separate in-memory revocation API, but the inspected DeploymentGateway does not consult it. This is an integration gap, not evidence that revocation is already implemented.

## 6. Persistence and recovery model

### 6.1 Storage classes

| Storage class | Appropriate use | Cannot independently prove |
|---|---|---|
| ETS / process memory | Hot indexes, locks, caches and transient coordination | Durable history or recovery |
| DETS | Local persistent state where lifecycle/recovery semantics are verified | Distributed consensus or atomic cross-store transactions |
| JSONL append ledger | Ordered event/history records with validated append and replay | Integrity unless hashes/signatures/checkpoints are verified |
| Evidence bundle | Immutable evidence snapshot with manifest/content hashes | Current certificate lifecycle or revocation state |
| ExecutiveMemory / EventStore | Executive memory and event retrieval | Certification truth unless bound to canonical evidence |
| Telemetry / logs | Operational observation | Transactional commit or proof of effect |
| Git audit report | Versioned audit findings and evidence references | Runtime state or a substitute for application persistence |

### 6.2 Durable write contract

A state-changing operation may report success only when:

1. Input and authority validation pass.
2. The canonical event/record is constructed.
3. The durable append/write returns a checked success result.
4. Required flush/sync semantics are satisfied for the declared durability level.
5. The authoritative in-memory index is reconciled with the durable record.
6. A stable record ID/digest is returned.
7. Failure at any step leaves no misleading committed state.

### 6.3 Recovery contract

- Startup must explicitly report replay status and source ledger identity.
- Every line/record must be parsed, schema-validated and integrity-checked.
- A malformed, truncated, missing or inaccessible ledger must not yield a trusted partial registry.
- Replay must be deterministic and idempotent.
- Sequence gaps, duplicate identities and conflicting records must be surfaced.
- Recovery must verify cross-ledger relationships: execution identity → execution terminal record → result → lineage → bundle → certificate → lifecycle.
- A recovered registry must publish a verifiable recovery report before accepting protected operations.

### 6.4 Ledger configuration inventory

The inspected forward-provenance modules use these configurable application keys and default paths:

| Key | Default |
|---|---|
| `:identity_authority_ledger_path` | `data/identity_authority_ledger.jsonl` |
| `:certificate_issuance_ledger_path` | `data/certificate_issuance_ledger.jsonl` |
| `:certificate_lifecycle_ledger_path` | `data/certificate_lifecycle_ledger.jsonl` |

The paths are expanded relative to the process working directory. The root production configuration inspected at Checkpoint 18.94 did not explicitly set these keys. The effective production paths, permissions, mount persistence, backup, fsync and recovery behavior remain UNKNOWN until verified in the actual release environment.

## 7. Security and authority contracts

Every privileged operation must carry:

- Authenticated principal identity.
- Explicit role and authority scope.
- Exact target and canonical effect identity.
- Immutable request/payload digest.
- Policy and contract version.
- Expiry and replay protection.
- One-time consumption where required.
- Independent authorization decision.
- Durable audit event.
- Explicit failure result.

Authorization must be checked at the state-owning/effect-owning boundary. Caller-side validation alone is insufficient. Missing authority, invalid credentials, stale policy, replay, storage failure or unresolved certificate status must fail closed.

## 8. Integration and unification strategy

Unification means consolidating duplicated contracts and authority, not forcing every subsystem into one implementation.

### 8.1 Canonical shared services to converge on

1. **Identity Authority:** one canonical execution identity and resolution contract.
2. **Execution Ledger:** one authoritative terminal lifecycle and result-binding model.
3. **Provenance Contract:** one schema, constructor and validator shared by every producer and consumer.
4. **Evidence Verification:** one independent verifier interface with explicit evidence classes and typed verdicts.
5. **Artifact Registry:** one versioned artifact identity and promotion lifecycle.
6. **Promotion Authority:** one transition service for scientific knowledge stages.
7. **Certificate Authority:** separate deterministic identity, issuance, lifecycle and revocation predicates under one coherent authority model.
8. **Authorization / Approval:** one authenticated, payload-bound grant and human-approval contract.
9. **Deployment Admission:** one gateway that checks the canonical certificate lifecycle and effect authority.
10. **Audit / Persistence:** shared append, integrity, replay, recovery and durability contracts.
11. **Observability:** read-only views derived from authoritative state, never independent authority.

### 8.2 Preserve legitimate specialization

- Scientific domain engines may retain domain-specific methods and thresholds, but must emit the canonical artifact/evidence contract.
- Hardware adapters may retain device-specific control logic, but must pass the same authorization, safety and postcondition contracts.
- CEL, Council, REA, ASC, GRCC, AEO and other governance/operational systems retain their distinct roles; their authority and interfaces must be explicit.
- A subsystem may be retired only after its consumers, data ownership, migration path and replacement evidence are accounted for. Retirement must not silently remove a required universal capability.

### 8.3 Unification acceptance criteria

A unification is accepted only when duplicate authorities are enumerated, one owner is designated, all producers/consumers are migrated, compatibility and failure behavior are tested, old paths are disabled or safely bridged, and independent verification proves there is no bypass.

## 9. Current audit-derived hardening register

| Priority | Area | Required action | Related finding |
|---|---|---|---|
| P0 | Scientific evidence gate | Require full execution identity and verified terminal/result binding | RL-488 |
| P0 | Knowledge promotion | Enforce canonical evidence and approval at the promotion owner; prevent stage jumps | RL-489 |
| P0 | Research integration | Replace caller-supplied execution-mode trust; make persistence failure visible | RL-490 |
| P0 | Certificate issuance/lifecycle persistence | Check file-open/write results and roll back on failure | RL-491 |
| P0 | Certificate ledger replay | Reject or quarantine incomplete replay; expose degraded state | RL-492 |
| P0 | Deployment admission | Resolve certificate identity and canonical lifecycle/revocation state | RL-484 |
| P0 | Execution identity recovery | Supervised ownership, mandatory persistence semantics and verified replay | RL-487 |
| P1 | Discovery promotion | Bind envelope contents to provenance, identity, authority and durable lifecycle | Checkpoint 18.94 integration gap |
| P1 | Ledger deployment configuration | Explicit absolute storage roots, permissions, backup, restore and durability policy | Checkpoint 18.94 configuration debt |
| P1 | Cross-system lineage | Bind general RealExecution lifecycle to forward-provenance bundle/lineage | RL-486 |
| P1 | Deployment effect | Verify effect result and audit commit semantics | Existing deployment findings |

Priority is a remediation ordering proposal, not a claim that the affected systems have been fixed.

## 10. Verification and certification requirements

Every system must have a verification matrix covering:

- Static contract and schema checks.
- Unit tests for valid, invalid and boundary inputs.
- Negative/adversarial authorization and provenance tests.
- Integration tests through real production ingress paths.
- Persistence failure, restart, replay and recovery tests.
- Concurrency and idempotency tests.
- Fault injection for unavailable dependencies and partial writes.
- Cross-system end-to-end lineage verification.
- Independent verifier that does not trust the system's own status claims.
- Exact commit, configuration, environment, evidence digest and test-result references.

A system is not certified merely because it compiles, boots, has tests, or returns success. Every required predicate must have its own evidence and an explicit PASS, FAIL, BLOCKED or NOT_RUN result.

## 11. System inventory still to be completed

The following major areas are explicitly pending full TMSOS mapping:

- Council constitutional repository, amendments, human approval and emergency authority.
- CEL service registry, kernel, BootSequencer, governance and recovery.
- AEO and its adapters.
- Meta-SOPL and policy/constraint execution.
- GRCC, CIS and related integrity/consistency systems.
- ASC, its worlds, agents, adoption and deployment boundaries.
- REA graph, topology, causal constitution and evolutionary channels.
- Discovery, research, archaeology, hypothesis and scientific validation.
- Executive memory, DETS, EventStore and cross-store recovery.
- Hardware integration, physical deployment, safety, E-stop and rollback.
- Omega, Sentinel, Phase4 RealExecution, sandbox and deployment.
- Observability, Observatory, dashboards, telemetry and reporting.
- Networking, NATS/event transport, API ingress and external interfaces.
- Runtime supervision, resource management, multi-world isolation and soak/restart behavior.

Each entry will be expanded with exact source paths, ownership, call sites, contracts, dependencies, evidence and findings as its audit checkpoint is completed.

## 12. Change control and maintenance

- This document is the master operating map; the consolidated findings ledger remains the authoritative historical record of audit findings.
- Every checkpoint appends to the same findings ledger; history is never rewritten to conceal earlier evidence.
- TMSOS changes are versioned and committed alongside the checkpoint when the system map materially changes.
- Every row must carry an evidence basis and confidence status. Uninspected areas remain UNKNOWN / PENDING.
- Changes to constitutional authority or reserved human powers require the appropriate human ratification; this document cannot grant authority.
- Production code is not modified by the read-only audit.
- Finding closure requires exact-candidate verification, not merely a proposed design or implementation claim.

### Checkpoint 18.94 baseline updates

- Added evidence-gate inconsistency RL-488 to the operating map.
- Mapped scientific promotion responsibilities and identified RL-489 and RL-490.
- Identified certificate ledger append false-success behavior (RL-491) and silent replay failure (RL-492).
- Refined RL-487 identity recovery, RL-484 deployment revocation enforcement and ledger deployment configuration debt.
- No production code, runtime configuration, test or certification state was modified.
- This is an initial partial specification. It does not certify the uninspected systems listed in Section 11.

**Next specification revision:** expand the ownership and interface maps for the remaining Council/CEL, AEO, Meta-SOPL, GRCC, ASC, REA, hardware and runtime subsystems, then reconcile their authority and lifecycle contracts against this baseline.


## 13. Current-main duplicate-directory and stub map (Checkpoint 18.95)

A supplemental scan was performed against current `main` commit `b829254d032f9e0b5cf4c44725c8cf451800dad0`. This is distinct from the frozen source baseline used by Checkpoint 18.94.

The three audited roots are:
- `lib/tiannara/`
- `tiannara_runtime/lib/tiannara/`
- `tiannara_runtime/lib/tiannara_runtime/`

The recursive tree has 27,948 entries. The three roots contain 1,641 / 254 / 980 files and 263 / 65 / 167 directories respectively. The scan found 97 repeated directory basenames overall and 30 top-level basename collisions. Sixty-six requested system names have multiple directory locations when nested directories are included. These are directory collisions, not proof of duplicate implementations.

The full name-to-path map, file counts, duplicate list and explicit stub/production candidate table are maintained in:

`audits/Tiannara_System_Directory_Duplication_and_Stub_Production_Map.md`

### 13.1 Canonicalization rules

- A matching directory name does not establish a shared system.
- Same fully qualified module name defined in separate Mix projects is a module collision requiring startup/build-scope analysis.
- A production candidate is not canonical until consumers and startup ownership are established.
- A module that returns default data or success-shaped results is a stub even if it is a GenServer or has a supervisor.
- A supervisor child being alive is not proof of the capability it represents.
- Duplicate implementations must not be deleted until call sites, state, authority, data migration and rollback are mapped.

### 13.2 Explicit stub risks

Checkpoint 18.95 identified four new open findings:
- RL-493 — StubRegistry is not wired into normal application startup; stub calls are not established as observable.
- RL-494 — Stage-6 scientific capital and generation-history operations route through stubs with incompatible return contracts and false-success persistence.
- RL-495 — ASC Crucible phase resolves to a stub and the pipeline automatically advances on stub success.
- RL-496 — CTL branch validation consumes a zero-stress stub rather than an authoritative branch record.

The map also identifies partial/dormant stubs in causal traversal, longitudinal memory, pressure monitoring, survivability estimation, graph traversal, ASC protocol and REA theory classification.

### 13.3 Duplicate system owners requiring resolution

A10, CIS, OED and OCM have multiple implementations and/or startup boundaries. The map records their exact source paths, module namespaces and initial startup observations. They must be treated as competing or specialized variants until the next call-site and authority trace determines which variant owns each capability.

IRD, NDE and DFG contain larger core modules alongside supervised auxiliary GenServers that only maintain counters/status. Those auxiliary processes must not be counted as complete operational capabilities.

## 14. Checkpoint 18.95 maintenance rule

The master operating specification now tracks both:
1. The frozen-source audit baseline and findings history.
2. Supplemental current-main directory/source inventories with their own exact commit identity.

Do not mix evidence from different commits without labeling the source. No production changes are authorized by this specification. No duplicate directory is to be retired merely because another directory shares its name.
