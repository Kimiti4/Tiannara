# Section C — Constitutional governance and safety: capability audit narrative

**Phase:** R0 (read-only discovery) · **Section:** C · **Branch:** `local/pr4` · **Date:** 2026-10-21
**Companion artefacts:** `capabilities_C_governance.csv` (32 rows), `deps_governance.json`, `decisions_GOV.md`

## Method, scope and honesty statement

This section was audited **read-only**. No file outside `certification/atlas/` was created, modified,
moved or deleted. No git commit, push, checkout or branch operation was performed. No test suite was
executed — every statement below is grounded in **static reading of source** plus **documented
prior evidence**, and the basis for each claim is labelled accordingly.

### Evidence vocabulary used

| Basis | Meaning in this document |
|---|---|
| `documented` | The claim is stated in a repository document; the document itself is the evidence. |
| `statically_inferred` | The claim was derived by reading source code paths (call sites, guards, branches) without running anything. |
| `dynamically_observed` | The claim was derived from an actual execution (test run, script run) — **none in this section**. |
| `independently_verified` | The claim was confirmed by a second, independent source (e.g. `GENSERVER_RECONCILIATION.csv` corroborating a grep). |

### Prior-attempt continuity

A previous R0 attempt (network-failed twice) had left `certifications/atlas/capabilities_C_governance.csv`
with 27 rows but no narrative, no dependency graph and no decision register. That CSV was **read, checked
claim-by-claim against source, corrected where wrong, and extended**. The corrections that mattered:

| Prior claim | Correction | Basis |
|---|---|---|
| `rules.md` is 473 lines | **225 lines** | `statically_inferred` (line count of root file) |
| "RuleEngine hard invariant `:no_self_amendment` rejects `:constitutional_amendment`" | **False on the real path** — the `self_modification` policy matches first and yields `:require_simulation`; `score_auth` never overrides the decision | `statically_inferred` (`policy_registry.ex:86-94`, `council.ex:96-107`, `council.ex:134-143`) |
| "no test demonstrates tamper detection" for the audit log | **Wrong** — `audit_log_recovery_test.exs:269` asserts a logical chain break fails closed; recovery at `:162` | `statically_inferred` (test source) |
| `Council.authorize` consumer list | **Confirmed correct** (6 call sites) | `statically_inferred` (repo-wide grep) |

Four findings the prior attempt **missed entirely** are recorded here as F-GOV-003, F-GOV-005,
F-GOV-006 and F-GOV-007; they are the most consequential results of this pass.

### Cross-check against sibling findings (`certification/atlas/problems_G.md`)

| Sibling | Our position |
|---|---|
| **F-ARC-002** KillSwitch triplication + dead consumer API | **AGREE** — independently confirmed at `kill_switch.ex:82-128` vs `world_supervisor.ex:111-144`; extended by F-GOV-013 (unstarted modules, unguarded `send` in SafetyCortex). |
| **F-ARC-003** Constitutional authority scattered | **AGREE and sharpen** — confirmed ≥5 constitution modules and 2 principle registries; sharpened by F-GOV-114 (the Council principle registry is *never started*, so the dynamic scoring path is dead, not merely duplicated). |
| **F-ARC-006** CAE / CAP / UEP zero implementation and zero in-repo spec | **AGREE, independently re-verified** — repo-wide grep for `Constitutional Arbitration Engine` / `Constitutional Audit Pipeline` returns 0 code hits and 0 hits in `docs/**`, `markdown/**`, root `*.md`, `certification/**`, `tiannara_runtime/priv/**`. Recorded as F-GOV-001. |
| **F-ARC-007** `tiannara_audit` verifiers always PASS | **AGREE** — re-read both verifiers; `graph_verifier.ex:29` returns `match: true` unconditionally and `proof_verifier.ex:21-22` passes on `nil`. Recorded as F-GOV-011. |
| **F-ARC-023** Missing negative tests on audit critical paths | **AGREE but NARROW** — `tiannara_audit` still has no `test/` directory; however the *root* application's authorisation chain has substantial, real denial-path coverage (CAP-GOV-104). The gap is tool-specific, not systemic to the root app. |
| *(new)* | **DISAGREE with the prior CSV's implicit claim** that Section C has no positive governance evidence. CAP-GOV-102 (`MintRegistry`), CAP-GOV-103 (`EffectIdentity`) and CAP-GOV-104 (attack suite) are genuinely `verified_operational` with real denial-path tests. Section C is not uniformly weak; it is unevenly strong, and the strong part is the Omega registry chain. |

---

## Canonical list coverage

All 15 canonical Section C IDs from `certification/atlas/R0_SOURCE_PLAN.txt:213-259` are covered, plus 17
discovered extras (`CAP-GOV-101` … `CAP-GOV-117`). Section C totals: **32 capability rows**.

| evidence_state | count |
|---|---|
| `verified_operational` | 4 |
| `implemented_incompletely_verified` | 9 |
| `partially_connected` | 10 |
| `specified_not_proven` | 2 |
| `missing_or_unresolved` | 7 |

| reconciliation | count |
|---|---|
| `MATCHED` | 3 |
| `PARTIAL` | 15 |
| `CONTRADICTED` | 8 |
| `UNKNOWN` | 6 |

**Nothing in Section C is `verified_operational` at the level the canonical list asks for.** The four
`verified_operational` rows are sub-components (a registry, an identity hash, an attack suite, a
persistence layer), not the Section C capabilities themselves.

---

## Per-capability narrative (Section C capability rows CAP-GOV-001 .. CAP-GOV-015)

### CAP-GOV-001 — Constitutional Engineering Instructions (`rules.md`)
`rules.md` is a 225-line root prose document. A repo-wide grep for `rules.md` across all `*.ex` returns
**19 hits, every one of them a moduledoc prose citation** — for example
`lib/tiannara/discovery/topics.ex:9`, `lib/tiannara/cel/workflow/workflow.ex:15`,
`lib/tiannara/council/audit_log.ex:26`. There is **no** `File.read`, `:file.read`, `Code.eval_file` or
any other functional consumer, and no test loads it. The runtime policy authority is instead the
hardcoded `Tiannara.Council.Constitution` struct persisted in `constitution_repository.dets`, plus the
six `Council.PolicyRegistry` policies. The Section C audit focus — "one authoritative, versioned policy
source" — is therefore **contradicted**, not merely unmet: a second, unrelated policy source exists and
the canonical one is inert. → F-GOV-002, F-GOV-020.

### CAP-GOV-002 — Constitutional Arbitration Engine (CAE)
Neither the CAE v1.1 specification text nor any implementation is present in this checkout. The
separation the plan demands at `R0_SOURCE_PLAN.txt:253` ("CAE evaluates epistemic justification; CAP
evaluates whether a subject is authorized to proceed") cannot be verified, because there is nothing on
either side of the line to compare. Name-adjacent code exists — `Council.authorize/3`,
`TiannaraRuntime.Meta.ObserverArbitrationLayer`, `Tiannara.Phase16.REA.ArbitrationLoop`,
`Tiannara.CIS.Supervisor.authorize_kill/3` — but each arbitrates a *different* question. Recording these
as CAE would manufacture the very evidence this audit is supposed to test for. → F-GOV-001.

### CAP-GOV-003 — CAE calibration feedback
Wholly absent, and structurally dependent on CAP-GOV-002. The nearest module,
`Tiannara.Audit.CalibrationRunner`, performs entropy/pressure fault injection; it never feeds an
outcome back into an arbitration decision. There is no reproducibility property and no bias-protection
property to test. → F-GOV-001.

### CAP-GOV-004 — Constitutional Invariant Monitor (CIM)
`Tiannara.Council.ConstitutionalMonitor` is genuinely boot-wired as a `Council.Supervisor` child
(`council/supervisor.ex:15`) and runs a 30-second cycle. Three defects:
1. **No enforced consequence.** A stressed report produces a telemetry event and a `stress_log` entry
   (`constitutional_monitor.ex:38-44`) — nothing else. The Section C audit focus is "independent
   monitoring **and enforced consequences**"; the second half is missing.
2. **Fail-open defaults.** Zero reporting services yields `aggregate_constitutional_score: 1.0`
   (`:51-59`), and each unscored dimension defaults to `1.0` (`:65-69`).
3. **Silent before first cycle.** `health_report/0` returns `state.last_report`, which is `nil` for the
   first 30 seconds; `ExecutiveStateManager.get_constitutional_status/0` then hits a `CaseClauseError`
   and is rescued to `:unknown` (`executive_state_manager.ex:192-200`).

After the first cycle with no reporters, the monitor reports a perfect constitutional score, which the
CEL executive maps to `:compliant`. The monitor is wired and running; it simply cannot fail. → F-GOV-008.

### CAP-GOV-005 — Constitutional Audit Pipeline (CAP)
No CAP module exists. The closest functional composite is:
`Council.authorize/3` → `MachineAuthorization.mint/2` → `bind_effect/2` → `Omega.MintRegistry` →
`Phase4.ExecutionGovernance.begin/2` / `Omega.DeploymentGateway.deploy/6` /
`Omega.GovernedEffectSink.execute/3`. `Council.authorize/3` has **6 production call sites**
(`world_mutation_engine.ex:297`, `cel/kernel.ex:88`, `cel/kernel.ex:102`,
`forecasting/adapters/decision.ex:55`, `phase4/experiment_orchestrator.ex:378`,
`cel/services/resource_manager.ex:101`). Three defects found in this pass:

- **`permitted?/1` accepts `:conditional`** (`authorization.ex:113`). `MachineAuthorization.mint/2`
  gates *only* on `permitted?` (`machine_authorization.ex:105`). The stricter conditions check
  (`WorldMutationEngine.conditions_met?/1`) exists only on the WME path, so any other minting path can
  convert a conditional decision into a machine grant with unmet conditions.
- **Policy `:approve` bypasses hard invariants.** The `emergency_halt` policy (priority 300, action
  `:approve`) matches `:emergency_halt` and `:circuit_breaker` and returns `Authorization.approved/1`.
  `score_auth/3` then merges score and violated principles but **never overrides `decision`**
  (`council.ex:134-143`). A payload with `bypasses_human_authority: true` therefore returns
  `decision: :approved` while `violated_principles` lists `:human_final_authority`.
- **The chain is gated on a RuleEngine that cannot approve** — see CAP-GOV-113 / F-GOV-006.

→ F-GOV-005, F-GOV-006, F-GOV-007, F-GOV-022.

### CAP-GOV-006 — Seven CAP gates
Absent. No module implements capability alignment, uncertainty, adversarial robustness, explainability,
regression, constitutional consistency or lineage as a CAP gate sequence, and no `2%` / `5%` / `1%` /
`3%` thresholds exist in any governance code path. Three unrelated gate families compete for the name:
`GovernedEffectSink` N1-N9, the runtime's 13-gate `ProductionGateFramework`
(`gates_06_07_08_09_10_11_12_13.ex`), and `Tiannara.GCK.ChronogramGate` (thresholds `0.92` / `0.75`).
None maps to the seven CAP gates. → F-GOV-009.

### CAP-GOV-007 — Audit Certificates
**Contradicted against its own audit focus** ("signature verification, expiry, and subject binding"):
- `Tiannara.Certification.Certificate` (`certification/certificate.ex:15-16`) carries `subsystem`,
  `verdict`, `invariant_verdict`, `failed_invariants`, `functional_gates`, `issued_at`, `reason` —
  **no signature, no validity period, no subject version**. Its *gate* logic is good (refuses on a
  closed invariant gate or any closed functional gate) and is tested by `invariant_gate_test.exs`.
- The only field literally named `signature` in Section C code is
  `TiannaraOS.Governance.GovernanceReplayCertificate.signature`
  (`governance_replay_certificate.ex:39`), and `sign_certificate/4` (`:248-251`) is
  `:crypto.hash(:sha256, "#{cert_id}:#{ledger_hash}:#{state_fingerprint}:#{timestamp}")` — an **unkeyed
  hash over public fields**. Anyone who can read the struct can recompute a valid signature. It is a
  checksum, not a signature.
- Worse, `manifest_id` is the hardcoded literal `"constitution-v13"` (`:89`) regardless of which
  manifest was actually replayed — so the certificate does not even correctly describe its own subject.
- The lifecycle-complete implementation (`TiannaraOS.Provenance.CertificateLifecycle`, with
  VALID / SUSPENDED / REVOKED / UNVERIFIABLE / SUPERSEDED and fail-closed forbidden verbs) lives in the
  separate `forward_provenance` path dependency (`mix.exs:67`) and is imported by **zero** modules in
  `lib/` or `tiannara_runtime/lib/`. → F-GOV-010.

### CAP-GOV-008 — Constitutional Executive / State Machine
`Tiannara.CEL.Kernel` + `Tiannara.CEL.Kernel.RuntimeStates` provide the repo's only explicit lifecycle
transition table (10 states, `runtime_states.ex:14-25`, `shutdown` terminal). Three findings:
- **The transition gate has no constitutional authorisation.** `Kernel.transition/1`
  (`kernel.ex:78-84`) checks only `RuntimeStates.valid_transition?/2`. The state machine authorises
  itself; no Council decision, certificate or policy is consulted. "No unauthorized state transitions"
  is enforced as a *syntax* rule, not a *constitutional* rule.
- **Both privileged operations are permanently denied.** `restart_service/2` and `halt/2` both call
  `Council.authorize(:architectural_change, ...)`, and the `architectural_change` policy always yields
  `:require_human` → `:requires_human`, which no code path can satisfy (F-GOV-004). The emergency-halt
  affordance for the executive kernel is therefore unreachable.
- **Latent fail-open.** `kernel.ex:92-93` treats `decision: :conditional` as allow. It is currently
  unreachable (the policy branch never yields `:conditional`), but it is a standing fail-open that
  activates the moment the policy set changes. → F-GOV-017.

### CAP-GOV-009 — Human Authority / approval controls
The **deny side is genuine and tested**: `:requires_human` is refused by
`WorldMutationEngine.check_decision/1` (`world_mutation_engine.ex:331-334`), Council emergency refuses
every mutation (`council.ex:37-44`), and `wme_council_gate_test.exs` covers both.
The **approve side is a one-way record**:
`HumanApprovalQueue.approve/3` (`human_approval_queue.ex:51-64`) sets `status: :approved`, writes to
`history` and deletes from `queue` — and **no code path anywhere resumes a `:requires_human`
decision**. The queue is a dead end; every human-gated decision is permanently suspended. This also
means `CAP-GOV-008`'s `restart_service`/`halt` can never be unblocked.
Identity is weak: `AuthenticatedHumanIdentity.valid_credential?/1` accepts **any non-empty binary**
(`authenticated_human_identity.ex:44`), and `authenticated?/1` is a nil-check on `authenticated_at`
(`:41`) — so a directly-constructed struct with the four `@enforce_keys` passes. → F-GOV-004, F-GOV-016.

### CAP-GOV-010 — Access Control / OAVL / ACL
This is the **best-evidenced** part of Section C. `Tiannara.Omega.MintRegistry` is a durable one-shot
grant registry with an atomic `granted → consumed` CAS, and it is fail-closed on every storage failure
(`mint_registry.ex:143-144` converts any exit into `:registry_unavailable`, never permissive).
Negative-authorization testing is substantial and genuinely denial-path:
`d127_authorization_attack_test.exs` covers replay, copy, concurrent copy (exactly one winner),
delegation, amplification, other-effect, reconstruction of an unminted grant, duplicate registration,
and registry-unavailable fail-closed, plus a positive negative-control.
Three gaps:
- **The institutional CBAC gate is dead code.** `TiannaraOS.Governance.CapabilityChecker`
  (`os/governance/capability_checker.ex:1-180`) is a real implementation with three deny branches, quorum
  checking and role validation — with **zero callers** (repo-wide grep finds only the module definition
  and two doctest examples). Same for `Omega.AuthorityVerifier.assert_no_deployment_capability/1`.
- **Name collision.** The in-repo acronym `OAVL` denotes *ontology assurance validators*
  (`Tiannara.OED.OAVL.*`, `Tiannara.OAVL.DiscoveryVerifier`), not access control. Section C's
  "Access Control / OAVL / ACL" row must **not** be reconciled with the repo's OAVL by name.
- `permitted?/1` accepting `:conditional` (see CAP-GOV-005) weakens the gate. → F-GOV-014, F-GOV-005.

### CAP-GOV-011 — CEL / Constitutional Council
Both subsystems are genuinely boot-wired: `Tiannara.Council.Supervisor` at `application.ex:108`
(dependency-ordered registry entry at `:288-290`), `Tiannara.CEL.Kernel.ServiceRegistry` and
`Tiannara.CEL.Kernel` at `:111`/`:122` with `deps: [:council]`. The CEL kernel boot path correctly
refuses under Council emergency (`cel/kernel.ex:39-43`).
But the "constitutional council" as a hierarchy of actors with immutable authority boundaries does not
exist: `Council.decide` is `PolicyRegistry` → `RuleEngine`, with no council of actors, no quorum and no
veto ordering. `cel.md:1-3` (the CEL charter) carries its own honesty disclaimer that executive
integration is "largely not implemented". → F-GOV-001, F-GOV-019, F-GOV-023.

### CAP-GOV-012 — Hash-chain audit infrastructure
`Tiannara.Council.AuditLog` (559 LOC) is the strongest single artefact in Section C: single-writer lock,
strict DETS open, SHA-256 chain, Merkle root every 5 minutes, `verify_integrity/0`, corruption recovery
that archives first then re-verifies, and **fail-closed** behaviour (append in degraded mode returns
`{:error, :storage_degraded}` at `:152-153`; `verify_integrity` errors in degraded mode at `:225-226`).
Tamper detection *is* tested (`audit_log_recovery_test.exs:269` — a logical chain break fails closed)
and missing-event recovery *is* tested (`:162`).
The genuine gaps are: (a) the Merkle root is computed locally with **no cross-node consumer located
anywhere in the repo** — the "distributed" half of the audit infrastructure has no consumer; (b) on
degradation, `recent/1`, `chain_tip/0` and `merkle_root/0` silently return sentinels
(`audit_log.ex:190-207`) — fail-soft observability over fail-closed persistence; (c) at least five
competing hash-chain implementations exist (`Omega.EventStoreAudit`, `OMCS.IdentityHashChain`,
`CEL.Services.EventStore`, the `OS.Governance` ledger family, and the JSONL ledgers) with no canonical
owner. → F-GOV-012, F-GOV-015.

### CAP-GOV-013 — Kill switch / Safe Mode
**Contradicted.** The CIS authorisation chain is boot-wired and contract-tested (12 pinned tests,
`boot_wiring_test.exs`, 48/48 integration) — that part is real. But:
- **No kill-switch module is ever started.** `TiannaraRuntime.MultiWorld.KillSwitch`,
  `HardenedKillSwitch` and `Tiannara.MultiWorld.KillSwitchCausal` are defined and referenced by nothing
  but their own definitions and the dead `world_supervisor` calls. `KillSwitch.request_termination/3`
  (`kill_switch.ex:82-85`) casts to a GenServer that no supervisor launches.
- **Dead consumer API.** `world_supervisor.ex:111,136,140` calls `get_killed_worlds/0`,
  `request_kill/2`, `confirm_kill/2` — none of which exist on the unified module. Confirmed at HEAD
  (this is sibling F-ARC-002 / register C-11).
- **Unguarded `send` to an unregistered name.** `SafetyCortex.freeze_world/2` sends to
  `TiannaraRuntime.MultiWorld.HardenedKillSwitch` at `safety_cortex.ex:393` **outside** any
  `try/rescue` — while the very next send, to `WorldSupervisor`, *is* wrapped (`:396-400`). Since
  `HardenedKillSwitch` never starts, this raises `ArgumentError`.
- **Approval is unobservable.** `request_termination/3` returns `:requested` unconditionally; a caller
  cannot distinguish approval from denial.
- **Arbitration defaults to approve.** `CIS.Supervisor.make_arbitration_decision/3`
  (`cis/supervisor.ex:240-248`) returns `:approve` for every unmatched mode/severity pair; only
  `:lockdown` denies.
- **Recovery is undemonstrated** — no test asserts restoration after a kill. → F-GOV-013, F-GOV-007.

### CAP-GOV-014 — Rollback and stable-state preservation
**Contradicted.** No engine restores a previously validated state.
`Autonomy.RollbackEngine` honest-stubs `{:error, :rollback_unavailable}` for every request
(`autonomy/rollback_engine.ex:48`). `WorldMutationEngine.execute_rollback/1` (`:593-600`) flips the
record's status to `:rolled_back` and reverts nothing — `EXECUTION_CONTRACTS.md:392` records this as
`NOT_IMPLEMENTED`. At least five rollback modules exist (autonomy, `asc/reality`, `opc`,
`meta/opc/runtime`, `oed/rollback/*`) with no shared contract or canonical owner. The contract
requirement that non-revocable effects say so at their call sites is unmet at
`institution_adaptation_result.ex:214`, which still defaults `rollback_available` to `true`.
What *does* exist is checkpointing (`ConstitutionalPersistenceLayer` + `SafeCPL`) — genuine, tested,
and explicitly availability-over-fidelity; it must not be counted as rollback. → F-GOV-014.

### CAP-GOV-015 — Distributed constitutional verification
**Specified, not proven, and the one implementation contradicts its own guarantee.**
`Tiannara.Phase14.FederationGateway` documents "Byzantine fault tolerance: Q ≥ ⌈2/3 N⌉"
(`federation_gateway.ex:6`) but computes `trunc(total * 0.667)` (`:34`, `:48`) — **floor, not ceil**. For
N=1 the required quorum is **0**; for N=2 it is 1 of 2. Votes carry **no instance identity and no
dedup** (`:44-56`), so a single node can reach quorum by voting repeatedly. The published consensus
result has no located consumer. C-07's external scope (partitions, cross-node authority transfer,
dedup, snapshot consistency, budget reconciliation) is entirely absent. → F-GOV-015.

### Discovered extras (CAP-GOV-101 … CAP-GOV-117)
`CAP-GOV-101` GovernedEffectSink (strongest fail-closed contract in the repo, zero production callers) ·
`CAP-GOV-102` MintRegistry (`verified_operational`) · `CAP-GOV-103` EffectIdentity (`verified_operational`) ·
`CAP-GOV-104` negative-authorization attack suite (`verified_operational`) ·
`CAP-GOV-105` forward_provenance certificate lifecycle (complete but isolated) ·
`CAP-GOV-106` runtime 13-gate production certification framework (competing naming) ·
`CAP-GOV-107` CIS safety authorisation chain (wired, contract-tested, log-only delivery) ·
`CAP-GOV-108` GCK chronogram gate + Constitution invariant gate (two different mechanisms) ·
`CAP-GOV-109` AmendmentEngine (bumps a version string, changes nothing) ·
`CAP-GOV-110` PolicyRegistry (six policies, two of them permanently dead) ·
`CAP-GOV-111` institutional CBAC gate (real implementation, zero callers) ·
`CAP-GOV-112` ConstitutionalPersistenceLayer + SafeCPL ·
`CAP-GOV-113` Council RuleEngine (cannot approve) ·
`CAP-GOV-114` dynamic principle plugin path (registry never started) ·
`CAP-GOV-115` `tiannara_audit` verification tool (verifiers cannot fail) ·
`CAP-GOV-116` Phase14 FederationGateway (quorum contradicts its own doc) ·
`CAP-GOV-117` CEL RuntimePolicyEngine (parallel, unreconciled policy evaluator).

---

## Draft findings (F-GOV-001 .. F-GOV-023)

Severity scale: **critical** (safety/authorisation bypass or false evidence) · **high**
(certification-blocking gap) · **medium** (correctness/contract gap) · **low** (hygiene).

### F-GOV-001 — CAE and CAP have zero implementation and zero in-repo specification
- **Severity:** high (certification-blocking) · **Confidence:** confirmed
- **Evidence:** repo-wide grep for `Constitutional Arbitration Engine` / `Constitutional Audit Pipeline`
  → 0 code hits, 0 hits in `docs/**`, `markdown/**`, root `*.md`, `certification/**`,
  `tiannara_runtime/priv/**`. `certification/atlas/R0_SOURCE_PLAN.txt:223,229,253,257`.
- **Affected caps:** CAP-GOV-002, CAP-GOV-003, CAP-GOV-006, CAP-GOV-011, CAP-GOV-015
- **Root cause / HYPOTHESIS:** the CAE v1.1 and CAP v1.0 design documents were produced outside this
  repository and never landed here; the plan treats them as *inputs*, so their absence is expected —
  but it means half of Section C cannot be reconciled at all.
- **Minimal remediation:** obtain the CAE v1.1 and CAP v1.0 source documents, register them in the
  System Atlas as candidate specifications, and map each gate to the code that will implement it —
  **before** any further constitutional machinery is added (`R0_SOURCE_PLAN.txt:1151`).
- **Acceptance criteria:** both spec texts are present in-repo with a version and an owner; every one
  of the seven CAP gates and every CAE veto level has a named target module or an explicit "not built".

### F-GOV-002 — `rules.md` is never read by any code; it is not the runtime policy authority
- **Severity:** high · **Confidence:** confirmed
- **Evidence:** `rules.md` (225 lines); 19 `*.ex` hits, all moduledoc prose
  (e.g. `lib/tiannara/discovery/topics.ex:9`, `lib/tiannara/cel/workflow/workflow.ex:15`,
  `lib/tiannara/council/audit_log.ex:26`); zero functional readers; zero tests.
  `R0_SOURCE_PLAN.txt:221` requires "one authoritative, versioned policy source".
- **Affected caps:** CAP-GOV-001, CAP-GOV-109, CAP-GOV-110
- **Root cause / HYPOTHESIS:** the runtime constitution was implemented as hardcoded Elixir structs and
  a policy registry; `rules.md` remained a design document and the two were never reconciled.
- **Minimal remediation:** decide (see D-GOV-009) whether `rules.md` becomes the *normative* source
  that generates `Council.Constitution`/`PolicyRegistry`, or is demoted to prose commentary; add a
  version + amendment path either way.
- **Acceptance criteria:** exactly one of {`rules.md` is machine-read}, {`rules.md` is explicitly
  demoted and linked from `Council.Constitution`}; a test asserts the chosen invariant.

### F-GOV-003 — Two `PolicyRegistry` policies are permanently dead: risk-based and invariant-based human approval
- **Severity:** critical · **Confidence:** confirmed
- **Evidence:** `council/policy_registry.ex:95-112` declares `high_risk` (`applies_to: [:any]`,
  condition `{:risk_above, 0.8}`) and `invariant_protection` (`applies_to: [:any]`, condition
  `{:touches_invariant, true}`); the matcher at `:45` tests `decision_type in &1.applies_to`
  **literally**, so `:any` matches only a decision literally named `:any`. No caller in the repo uses
  that decision type.
- **Affected caps:** CAP-GOV-005, CAP-GOV-009, CAP-GOV-110
- **Root cause / HYPOTHESIS:** `:any` was intended as a wildcard in `applies_to` but the matcher
  implements membership, not a wildcard.
- **Minimal remediation:** implement `:any` as a wildcard in the matcher (or give the two policies an
  explicit `applies_to` list) **and** add a test that a payload with `risk_assessment > 0.8` and a
  decision type of `:world_mutation` produces `:require_human`.
- **Acceptance criteria:** a negative-authorization test proves that a high-risk or invariant-touching
  decision is routed to human approval; `PolicyRegistry` has a dedicated unit test file.

### F-GOV-004 — Human approval is a one-way record with no resume path
- **Severity:** critical · **Confidence:** confirmed
- **Evidence:** `council/human_approval_queue.ex:51-64` (`approve` writes `status: :approved` to
  `history` and removes from `queue`); repo-wide grep shows **no** consumer of
  `HumanApprovalQueue.pending/0` history that resumes a `:requires_human` authorization.
  `EXECUTION_CONTRACTS.md:388` records the sibling symptom for the Omega path
  (`Authorization.record_mint/1` has zero production callers ⇒ production human grants are refused).
- **Affected caps:** CAP-GOV-009, CAP-GOV-008, CAP-GOV-109
- **Root cause / HYPOTHESIS:** the approval *record* was implemented; the approval *effect* (re-running
  the gated decision with the grant) was never implemented.
- **Minimal remediation:** implement a resume path — on `approve/3`, re-evaluate the parked decision and
  re-emit the resulting `Authorization`; wire it to `CEL.Kernel.restart_service/2` and `halt/2`.
- **Acceptance criteria:** an end-to-end test drives a `:requires_human` decision through
  `enqueue → approve → resumed decision`, and a negative test shows an *unapproved* decision is still
  refused.

### F-GOV-005 — `Authorization.permitted?/1` accepts `:conditional`, so a conditional decision can be minted into a machine grant
- **Severity:** high · **Confidence:** confirmed
- **Evidence:** `council/authorization.ex:112-114` (`permitted?` → true for `:approved` **and**
  `:conditional`); `council/machine_authorization.ex:105` gates `mint/2` on `permitted?` only; the
  strict conditions check exists solely on the WME path
  (`world_mutation_engine.ex:100-133,323-329`).
- **Affected caps:** CAP-GOV-005, CAP-GOV-010, CAP-GOV-101
- **Root cause / HYPOTHESIS:** `permitted?` was written as a "not explicitly rejected" predicate while
  the real invariant is "conditions satisfied".
- **Minimal remediation:** make `permitted?/1` reject `:conditional`, and move the conditions check into
  a shared module used by every minting path.
- **Acceptance criteria:** a test asserts `MachineAuthorization.mint/2` refuses a `:conditional`
  decision with unmet conditions on a path other than WME.

### F-GOV-006 — The RuleEngine can never return `:approved` for any real caller decision type
- **Severity:** critical · **Confidence:** confirmed
- **Evidence:** `council/rule_engine.ex:281-292` requires `compliance >= 0.8` for `:approved`;
  `:132` shows the built-in assessor emits only `:neutral` or `:violated`, never `:strengthened`;
  `:253-269` maps `neutral → 0.7`, so the maximum attainable compliance with the built-in scorer is
  **0.70** — below the 0.80 threshold. The `:strengthened` verdict exists **only** in the plugin
  path (`council/principles/evidence_before_confidence.ex:32-34` strengthens when
  `evidence_count >= 3 and confidence >= 0.7`, for **any** decision type;
  `council/principles/verification_first.ex:31-33` strengthens only for
  `decision_type in [:deploy, :activate, :scale]`), and that path is dead because
  `Tiannara.Council.PrincipleRegistry` is not a child of `Council.Supervisor`
  (`council/supervisor.ex:8-19`) and `GENSERVER_RECONCILIATION.csv:74` records it as
  `6_no_refs_at_all`.
- **Affected caps:** CAP-GOV-005, CAP-GOV-008, CAP-GOV-010, CAP-GOV-113, CAP-GOV-114
- **Root cause / HYPOTHESIS:** the 0.8 approval threshold was calibrated against a plugin-based scorer
  that could emit `:strengthened`; the built-in fallback scorer cannot, and the plugin registry was
  never added to the supervision tree — so the fallback is silently in force in production.
- **Note on the remediation trap:** starting `PrincipleRegistry` would make `:approved` reachable
  (both plugins at weight 1.0, all-strengthened ⇒ compliance 1.0), which would in turn make
  `Authorization.permitted?/1` admit `:approved` on the paths that F-GOV-007 shows are not
  hard-invariant-safe. The dead plugin path is currently masking two defects. **F-GOV-007 must be
  fixed before F-GOV-006's plugin path is revived.**
- **Minimal remediation:** decide whether `:approved` should be reachable at all; either introduce a
  `:strengthened` verdict in the built-in scorer (or start `PrincipleRegistry` **after** F-GOV-007 is
  fixed), or re-calibrate the thresholds and make the semantics explicit.
- **Acceptance criteria:** a test enumerates the six real decision types and asserts the intended
  verdict for each; `approved` is either reachable with a stated payload shape or removed as a state.

### F-GOV-007 — A policy `:approve` bypasses the RuleEngine's hard invariants
- **Severity:** critical · **Confidence:** confirmed
- **Evidence:** `council/policy_registry.ex:113-121` (`emergency_halt`, priority 300, action `:approve`,
  `applies_to: [:emergency_halt, :circuit_breaker]`); `council.ex:119-126` returns
  `Authorization.approved/1`; `council.ex:134-143` (`score_auth/3`) merges `constitutional_score`,
  `confidence`, `evidence` and `violated_principles` but **never** re-derives `decision`, so a
  `:human_final_authority` or `:audit_log_immutability` hard-invariant violation
  (`rule_engine.ex:242-249`) is recorded but the decision stays `:approved`.
- **Affected caps:** CAP-GOV-005, CAP-GOV-009, CAP-GOV-013, CAP-GOV-110
- **Root cause / HYPOTHESIS:** `score_auth` was designed to *decorate* an authorization, not to *vet* it;
  the policy branch pre-commits the decision before the vet runs.
- **Minimal remediation:** make the hard-invariant check authoritative — a violated hard invariant must
  downgrade the decision to `:rejected` regardless of the policy action.
- **Acceptance criteria:** a test asserts `Council.authorize(:circuit_breaker, %{bypasses_human_authority: true})`
  returns `:rejected` (or an explicit new verdict) and that `Authorization.permitted?/1` is false.

### F-GOV-008 — The constitutional invariant monitor has no enforced consequence and fails open
- **Severity:** high · **Confidence:** confirmed
- **Evidence:** `council/constitutional_monitor.ex:51-59` (empty service set → score `1.0`), `:65-69`
  (each dimension defaults to `1.0`), `:38-44` (stressed report → telemetry + `stress_log` only),
  `:26` (`health_report` returns `nil` before the first cycle);
  `cel/services/executive_state_manager.ex:192-200` (nil → `CaseClauseError` → rescued `:unknown`).
- **Affected caps:** CAP-GOV-004, CAP-GOV-008, CAP-GOV-108
- **Root cause / HYPOTHESIS:** the monitor was built as a *telemetry* aggregator; the "enforced
  consequence" half of the audit focus was never implemented, and the absence of data was treated as
  perfection rather than as absence of evidence.
- **Minimal remediation:** make "no data" produce an explicit `:unknown` verdict (not `1.0`), and
  define the consequence of a stressed report (degrade the executive state / block promotion).
- **Acceptance criteria:** a test asserts an empty monitor yields a non-compliant or unknown verdict, and
  a second test asserts a stressed report produces a named, observable consequence.

### F-GOV-009 — The seven CAP gates do not exist, and three unrelated gate families compete for the name
- **Severity:** high (certification-blocking) · **Confidence:** confirmed
- **Evidence:** no module implements Gate1–Gate7; no `2%` / `5%` / `1%` / `3%` thresholds exist in
  governance code. Competing families: `governed_effect_sink.ex:34-70` (N1-N9),
  `tiannara_runtime/lib/tiannara_runtime/os/governance/certification/gates_06_07_08_09_10_11_12_13.ex:289-505`
  (13 gates), `gck/chronogram_gate.ex:60,63` (`0.92` / `0.75`).
  `R0_SOURCE_PLAN.txt:231,1133`.
- **Affected caps:** CAP-GOV-006, CAP-GOV-005, CAP-GOV-106, CAP-GOV-108
- **Root cause / HYPOTHESIS:** gate-like machinery was built for three unrelated purposes and never
  mapped onto the CAP contract.
- **Minimal remediation:** publish an explicit mapping table (CAP gate → existing gate or new module)
  before writing any new gate code; see D-GOV-001 to D-GOV-003.
- **Acceptance criteria:** each of the seven CAP gates has a named implementation or an explicit
  "not built" with an owner; no new gate module is added without a row in that table.

### F-GOV-010 — No certificate carries a cryptographic signature, a validity period, or a subject-version binding
- **Severity:** high · **Confidence:** confirmed
- **Evidence:** `certification/certificate.ex:15-16` (no signature / expiry / version fields);
  `governance_replay_certificate.ex:248-251` (`sign_certificate/4` = unkeyed sha256 over public fields —
  forgeable by anyone who can read the struct) and `:89` (`manifest_id` hardcoded to
  `"constitution-v13"` regardless of the manifest replayed);
  `tiannara_runtime/.../world_model/ontology/certificate.ex:62` (`model_version`) is the only version
  binding anywhere; the lifecycle-complete `forward_provenance` certificate is imported by zero modules.
  `R0_SOURCE_PLAN.txt:233,1143`.
- **Affected caps:** CAP-GOV-007, CAP-GOV-105, CAP-GOV-115
- **Root cause / HYPOTHESIS:** "signature" was implemented as a content hash and used as a label, so
  `verify_certificate/1` returns `:valid` for anything self-consistent.
- **Minimal remediation:** define the certificate schema (subject version, policy set, evidence set,
  gate results, validity period) and implement signing with a real key; see D-GOV-008.
- **Acceptance criteria:** a forged certificate (recomputed hash, wrong subject version, expired) is
  refused by a test.

### F-GOV-011 — `tiannara_audit` verifiers cannot fail, and the tool is untested and un-CI'd
- **Severity:** critical · **Confidence:** confirmed
- **Evidence:** `tiannara_audit/lib/tiannara_audit/graph_verifier.ex:23` computes `computed_hash` and
  `:29` returns `match: true` unconditionally, with `:35` hardcoding `failures: 0`;
  `proof_verifier.ex:21-22` treats `expected == nil` as a PASS; the `tiannara_audit` project has **no
  `test/` directory**; the committed `tiannara_audit/lib/INDEPENDENT_AUDIT_REPORT.md` ("220/220 PASS")
  was produced by these verifiers.
- **Affected caps:** CAP-GOV-007, CAP-GOV-015, and every Section C capability that might cite an
  "independent audit" report as evidence
- **Root cause / HYPOTHESIS:** the verifiers were written to *produce* a report rather than to *test* a
  claim; the comparison step was never implemented.
- **Minimal remediation:** make both verifiers fail closed (mismatch → FAIL, nil expectation → FAIL),
  add FAIL-path unit tests, banner (do not erase) both historical reports, and run the tool in CI
  before any citation.
- **Acceptance criteria:** verifier unit tests prove FAIL on mismatch and on nil; the tool is compiled
  and tested in CI; no Section C evidence reference points at a pre-fix report.

### F-GOV-012 — The audit-log Merkle root has no consumer; degraded-mode reads fail soft
- **Severity:** medium · **Confidence:** confirmed
- **Evidence:** `council/audit_log.ex:62` (`merkle_root/0`), `:238-256` (periodic computation),
  `:190-207` (`recent/1` → `[]`, `chain_tip/0` → genesis sentinel, `merkle_root/0` → `nil` in degraded
  mode, with no error), versus `:152-153` (append → `{:error, :storage_degraded}`).
- **Affected caps:** CAP-GOV-012, CAP-GOV-015
- **Root cause / HYPOTHESIS:** the Merkle root was built for future cross-node verification that was
  never built; degraded-mode readers were written to be tolerant because the primary use was dashboards.
- **Minimal remediation:** either implement a consumer that verifies the root (cross-node, or a periodic
  self-check that compares against a stored expectation) or remove the root until it has one; make
  degraded reads distinguishable from empty results.
- **Acceptance criteria:** a test asserts the Merkle root changes when an entry is appended and that
  degraded reads are distinguishable from empty reads.

### F-GOV-013 — The kill switch is not running, the consumer API is dead, and the freeze path raises
- **Severity:** critical · **Confidence:** confirmed
- **Evidence:** no supervisor starts `TiannaraRuntime.MultiWorld.KillSwitch`,
  `HardenedKillSwitch` or `Tiannara.MultiWorld.KillSwitchCausal`;
  `multi_world/world_supervisor.ex:111,136,140` calls `get_killed_worlds/0`, `request_kill/2`,
  `confirm_kill/2`, none of which exist on the unified module (`kill_switch.ex:82-128`);
  `cortex/safety_cortex.ex:393` sends to the unregistered `HardenedKillSwitch` **outside** any
  `try/rescue` (contrast `:396-400`); `cis/supervisor.ex:240-248` defaults to `:approve`;
  `PHASE_5F_STATUS_CORRECTION.md:188-195` (C-11).
- **Affected caps:** CAP-GOV-013, CAP-GOV-007, CAP-GOV-015
- **Root cause / HYPOTHESIS:** the kill-switch consolidation in 5F.3.5 produced a unified module but
  the wiring and the consumer migration were deferred; the duplicate set was never removed.
- **Minimal remediation:** start exactly one kill-switch module under an existing supervisor, migrate or
  delete the dead `world_supervisor` API, and wrap the SafetyCortex send.
- **Acceptance criteria:** one kill-switch module is boot-wired and contract-tested; the repo compiles
  with zero undefined-function warnings for the kill path; `freeze_world/2` cannot raise; a negative
  test proves that a kill request in `:lockdown` mode is denied.

### F-GOV-014 — No rollback restores state; the CBAC gate and the authority verifier are dead code
- **Severity:** critical · **Confidence:** confirmed
- **Evidence (rollback):** `autonomy/rollback_engine.ex:48` (always `{:error, :rollback_unavailable}`);
  `world_mutation_engine.ex:593-600` (flips the record, reverts nothing);
  `EXECUTION_CONTRACTS.md:392` (rollback for applied effects is `NOT_IMPLEMENTED`; no rollback exists
  for Gateway deploys, `RealExecution` effects, or MintRegistry consumption);
  `institution_adaptation_result.ex:214` (`rollback_available` defaults to `true`).
  **Evidence (access control):** `os/governance/capability_checker.ex:49-63` is a working CBAC gate with
  three deny branches, but repo-wide grep finds **zero callers**; the same is true of
  `omega/authority_verifier.ex:21-28`.
- **Affected caps:** CAP-GOV-014, CAP-GOV-010, CAP-GOV-111
- **Root cause / HYPOTHESIS:** two independent gaps. For rollback, the "flip a record" shape was
  mistaken for restoration. For access control, the institutional model was built to a specification
  that no caller was ever wired to.
- **Minimal remediation (rollback):** implement real restoration for at least one effect class, or
  change every `rollback_available: true` default to `false` and state non-revocability at each call
  site, per `EXECUTION_CONTRACTS.md:404-406`.
  **Minimal remediation (access control):** wire `CapabilityChecker.authorize?/3` into the
  `DeploymentGateway` / `ExecutionGovernance` admission path and add its missing tests.
- **Acceptance criteria:** a test asserts that a rollback restores the prior state and its data
  integrity; a test asserts `CapabilityChecker.authorize?/3` denies a capability-less institution on a
  live admission path.

### F-GOV-015 — The federation quorum contradicts its own documented guarantee and votes are replayable
- **Severity:** high · **Confidence:** confirmed
- **Evidence:** `tiannara_runtime/lib/tiannara/phase14/federation_gateway.ex:6` (doc: "Q ≥ ⌈2/3 N⌉")
  vs `:11` (`@quorum_fraction 0.667`) and `:34`, `:48` (`trunc(total * 0.667)` — floor, so N=1 → 0 and
  N=2 → 1 of 2); `:44-56` (votes carry no instance identity and no dedup — one voter can vote
  repeatedly); `PHASE_5F_STATUS_CORRECTION.md:129-136` (C-07: CRA supervisor absent, partition /
  cross-node-authority / dedup / snapshot-consistency / budget-reconciliation scope entirely absent).
- **Affected caps:** CAP-GOV-015, CAP-GOV-012
- **Root cause / HYPOTHESIS:** the quorum constant was transcribed as a fraction and applied with
  `trunc`; the Byzantine voter model was documented in prose and never implemented.
- **Minimal remediation:** use `ceil` and express the quorum in **votes**, not fraction-of-members;
  require a per-instance identity and reject duplicate votes from the same instance.
- **Acceptance criteria:** a test proves a 2-node cluster cannot reach quorum with 1 vote and that a
  duplicate vote from one instance does not increment the count.

### F-GOV-016 — "Authenticated human identity" accepts any non-empty credential and is forgeable
- **Severity:** high · **Confidence:** confirmed
- **Evidence:** `omega/human_delivery/authenticated_human_identity.ex:44`
  (`valid_credential?` = `byte_size(credential) > 0`); `:41` (`authenticated?` = nil-check on
  `authenticated_at`); `:14` (`@enforce_keys` are all caller-supplied, so the struct is directly
  constructible); `omega/human_delivery/authorization.ex:114-119` (trusts `authenticated?/1`).
- **Affected caps:** CAP-GOV-009, CAP-GOV-101
- **Root cause / HYPOTHESIS:** the struct was treated as a capability rather than as a claim that
  requires verification against a credential store that does not exist.
- **Minimal remediation:** verify the credential against a configured store (or a signed assertion) and
  make the identity unforgeable — e.g. hold the authenticated fields in a private struct with an
  opaque handle, or make the struct constructor module-private.
- **Acceptance criteria:** a test asserts `authenticate/3` rejects a wrong credential and that a
  hand-built struct fails `authenticated?/1`.

### F-GOV-017 — The CEL kernel state machine authorises itself, and its privileged operations are unreachable
- **Severity:** high · **Confidence:** confirmed
- **Evidence:** `cel/kernel.ex:78-84` (`transition/1` consults only `RuntimeStates.valid_transition?/2`
  — no Council decision); `cel/kernel.ex:88` and `:102` (both privileged operations use
  `Council.authorize(:architectural_change, ...)`, whose policy always yields `:require_human`);
  `cel/kernel.ex:92-93` (`:conditional` treated as allow — a standing latent fail-open).
- **Affected caps:** CAP-GOV-008, CAP-GOV-009, CAP-GOV-005
- **Root cause / HYPOTHESIS:** the transition table and the authorisation gate were designed as two
  independent mechanisms and never joined; the join depends on the human-approval resume path that
  does not exist (F-GOV-004).
- **Minimal remediation:** require a Council decision for every transition out of `:operational`,
  and delete the `:conditional` allow-branch.
- **Acceptance criteria:** a test asserts an unauthorised transition out of `:operational` is refused,
  and a test asserts `:conditional` is not treated as allow.

### F-GOV-018 — An approved amendment changes nothing and does not reach the effective constitution
- **Severity:** high · **Confidence:** confirmed
- **Evidence:** `council/amendment_engine.ex:251-253` (`apply_amendment/2` only bumps the version
  string — `proposed_changes` is discarded); `:45` and `:155-158` (the amended constitution is written
  into the engine's private state, while the effective constitution is
  `ConstitutionRepository.current/0` read by `Council.constitution/0` at `council.ex:10`, which the
  engine never touches); `:142-160` (`approve` needs only a bare `human_id`); `:193` (`healthy?`
  always returns `true`).
- **Affected caps:** CAP-GOV-109, CAP-GOV-001, CAP-GOV-009
- **Root cause / HYPOTHESIS:** the amendment state machine was implemented for its lifecycle; the
  *effect* of an amendment (applying changes and publishing the new constitution) was never implemented.
- **Minimal remediation:** implement `apply_amendment/2` to apply `proposed_changes`, commit the result
  through `ConstitutionRepository.commit/4`, and require an authenticated approver.
- **Acceptance criteria:** a test proposes an amendment, approves it, and asserts that
  `Council.constitution/0` reflects the change and that the version advanced.

### F-GOV-019 — Two unreconciled policy evaluators operate in the same application
- **Severity:** medium · **Confidence:** confirmed
- **Evidence:** `council/policy_registry.ex:15-21` (condition vocabulary
  `:risk_above / :touches_invariant / :actor_is / :mission_impact / :resource_cost_above`)
  vs `cel/policy/runtime_policy.ex` + `cel/services/runtime_policy_engine.ex` (a second grammar).
  `council.ex:77` is the only Council policy call site; CEL services consult their own engine.
- **Affected caps:** CAP-GOV-011, CAP-GOV-110, CAP-GOV-117
- **Root cause / HYPOTHESIS:** CEL was built as a parallel executive stack with its own policy layer
  and was never reconciled with the Council.
- **Minimal remediation:** declare one canonical policy evaluator and route the other through it.
- **Acceptance criteria:** a single module owns policy evaluation; a test proves a decision evaluated
  by either entry point yields the same verdict.

### F-GOV-020 — Constitutional authority is scattered across at least five constitution modules
- **Severity:** high · **Confidence:** confirmed
- **Evidence:** `council/constitution.ex` + `council/constitution_repository.ex` (boot-wired, DETS
  `constitution_repository.dets`); `asc/constitution.ex`; `civics/constitution.ex`;
  `constitution/laws.ex`; `TiannaraRuntime.Shared.ConstitutionalLaws` (zero external refs per
  `GENSERVER_OWNERSHIP_INVENTORY.csv`); two `ConstitutionalGovernanceEngine` modules;
  `certification/atlas/ownership_duplicates.csv:2` records the same conflict.
- **Affected caps:** CAP-GOV-001, CAP-GOV-004, CAP-GOV-011, CAP-GOV-109
- **Root cause / HYPOTHESIS:** repeated constitutional work in separate subsystems with no canonical
  declaration. This is sibling F-ARC-003.
- **Minimal remediation:** declare the Council stack canonical in the architecture decision register;
  retire or explicitly mark the others `@moduledoc false` with zero boot cost.
- **Acceptance criteria:** one constitution module per deployed app; the others are removed or marked
  legacy with a recorded owner.

### F-GOV-021 — The five-minute audit timeout requirement has no implementation
- **Severity:** medium · **Confidence:** confirmed
- **Evidence:** `R0_SOURCE_PLAN.txt:1147` (establish whether the five-minute audit timeout applies to
  every subject class or only a defined subset). Repo-wide grep for `300_000` / `:timer.minutes(5)`
  returns **no** constitutional-audit timeout; the closest analogue is
  `os/governance/validation/campaign_executor.ex:72` (`timeout: 300_000, # 5 minute timeout per
  campaign`) which governs a validation campaign, not a constitutional audit; `audit_log.ex:40` is the
  5-minute Merkle computation interval.
- **Affected caps:** CAP-GOV-006, CAP-GOV-106, CAP-GOV-005
- **Root cause / HYPOTHESIS:** the requirement is a design-input constraint with no owning subsystem.
- **Minimal remediation:** name the subject classes the timeout applies to and the owning module; see
  D-GOV-010.
- **Acceptance criteria:** the timeout is implemented at a named call site with a test that asserts
  the timeout fires and blocks authorisation (not that it merely returns an error).

### F-GOV-022 — The strongest fail-closed contract in the repo has zero production callers
- **Severity:** medium · **Confidence:** confirmed
- **Evidence:** `omega/governed_effect_sink.ex:34-70` documents the full N1-N9 fail-closed contract;
  `EXECUTION_CONTRACTS.md:387` records zero `lib/` callers and an unconsumed `governed.effect` topic;
  `test/tiannara/omega/governed_effect_sink_test.exs` (8 tests) covers every documented branch.
- **Affected caps:** CAP-GOV-005, CAP-GOV-101, CAP-GOV-010
- **Root cause / HYPOTHESIS:** the sink was built and proved in isolation as a template, then the
  production effect paths were wired to a different (human-grant flavoured) clone instead.
- **Minimal remediation:** route at least one real effect path through the sink, or retire the clone and
  keep one.
- **Acceptance criteria:** exactly one governed-effect path exists and it is the sink with the N1-N9
  contract.

### F-GOV-023 — The dynamic principle plugin path is dead, and two principle registries have disjoint consumers
- **Severity:** high · **Confidence:** confirmed
- **Evidence:** `council/rule_engine.ex:85-93` (`Process.whereis(PrincipleRegistry)` → nil means the
  built-in path); `council/supervisor.ex:8-19` (the child list does not include `PrincipleRegistry`);
  `certification/audit/GENSERVER_RECONCILIATION.csv:74` records
  `Tiannara.Council.PrincipleRegistry` as `6_no_refs_at_all` with an empty `started_by`;
  `certification/atlas/ownership_duplicates.csv:22` records the two-registry conflict.
- **Affected caps:** CAP-GOV-006, CAP-GOV-011, CAP-GOV-113, CAP-GOV-114
- **Root cause / HYPOTHESIS:** the registry was built as an extension point but never added to the
  supervision tree, so the RuleEngine silently uses its fallback scorer.
- **Minimal remediation:** start `PrincipleRegistry` under `Council.Supervisor` (or delete the plugin
  path), and merge or cross-link the two registries in the same decision.
- **Acceptance criteria:** the RuleEngine's active scorer is observable at runtime; the two registries
  are merged or one is retired.

---

## Explicit unknowns

These are recorded as **UNKNOWN**, not as failures. Each is a genuine gap in what a read-only pass can
establish.

1. **Whether the CAE v1.1 and CAP v1.0 specifications exist outside this checkout.** The plan treats
   them as inputs (`R0_SOURCE_PLAN.txt:257`); if they were never written, D-GOV-001…D-GOV-003 have no
   spec text to reconcile against and must be authored, not merely reconciled.
2. **Whether the root application's governance tests currently pass.** CI configuration shows
   `mix test --max-failures 25 --color` for the root project (`.github/workflows/elixir_ci.yml:102`)
   and `mix test --exclude quarantine` for `tiannara_runtime` (`:134`), but **no test was executed in
   this pass**. Test *definitions* are not test *results*.
3. **Boot status of modules not traced to a supervisor.** `Tiannara.Phase14.FederationGateway`,
   `TiannaraRuntime.OS.Governance.Certification.*`, `Tiannara.Council.PrincipleRegistry` and the
   runtime `ProductionGateFramework` are recorded as *statically unconfirmed*, not as running or not
   running.
4. **Whether `rules.md` was ever intended to be machine-read.** Its content is prose engineering
   guidance, not a policy DSL; whether the original design expected a parser is not recoverable from
   this repository.
5. **The provenance of `TiannaraRuntime.OS.Shared.ConstitutionalLaws`** — it compiles and has zero
   external references; whether it was a spec artifact, a stub, or a superseded copy is not recorded.
6. **Whether the 30 `certification/campaign_*` runtime modules are exercised.** No campaign test was
   located; whether they are run by an operational (non-CI) process is unknown.
7. **Whether `Council.AuditLog`'s DETS chain and `MintRegistry`'s store survive a real restart in
   production.** The recovery tests cover simulated corruption and unclean holders; real disk,
   filesystem and crash-durability behaviour is untested.
8. **Whether the `tiannara_audit` "220/220 PASS" report corresponds to any real sample set.** The
   verifiers cannot fail, so the number is not informative either way.
9. **Whether `Tiannara.Omega.HumanDelivery.Authorization.record_mint/1` has an out-of-repo caller.**
   `EXECUTION_CONTRACTS.md:388` asserts zero *production* callers; an external service could not be
   excluded by a repo-local grep.
10. **The true consumer of `AuditLog.merkle_root/0`.** No in-repo consumer was located; whether a
    cross-node verifier exists outside this repository is unknown.

---

## Positive findings - evidence that must not be lost

Section C is unevenly strong. The following are `verified_operational` and must be protected from any
consolidation work:

- `Tiannara.Omega.MintRegistry` — durable, one-shot, registry-anchored, **fail-closed on every storage
  failure** (`mint_registry.ex:143-144`).
- `Tiannara.Omega.EffectIdentity` — deterministic canonical `effect-v1-<sha256>` identity; the repo's
  best existing answer to the certificate subject-binding question.
- The negative-authorization suite (`CAP-GOV-104`) — real denial-path coverage for replay, copy,
  concurrent copy, delegation, amplification, other-effect, reconstruction, duplicate registration and
  registry-unavailable failure, plus a positive negative-control.
- `Tiannara.Council.AuditLog` — fail-closed hash chain with corruption recovery and a real
  tamper-detection test.
- `Tiannara.Constitution.Suite` / `Gate` / `Tiannara.Certification.Certificate` — a genuinely fail-closed
  invariant gate, tested including the "a raising probe is a violation, never skipped" rule.
- `TiannaraRuntime.CIS.Supervisor` — the only boot-wired, contract-tested kill *authorisation* chain.
