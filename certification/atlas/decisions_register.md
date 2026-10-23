# Architecture decision register and exceptions (System Atlas Register 7)

**Status:** R0 proposal. No decision below has been *taken*; each is a decision the program requires, with the
evidence gathered, the options, the recommendation, and the trigger that must fire before it is re-opened.
A decision is only closed by a human-authorised record; until then the status stays `PROPOSED` or `OPEN_DESIGN_QUESTION`.

Status vocabulary: `PROPOSED` (recommendation ready for review) · `OPEN_DESIGN_QUESTION` (the specification itself is
undecided or absent) · `SUPERSEDED` (an earlier decision is replaced, never silently) · `EXCEPTION` (a temporary
deviation with an expiry condition).

---

## Part A — Governance and policy decisions (derived from `decisions_GOV.md`, D-GOV-001..010)

| ID | Question | Status | Evidence | Options | Recommendation | Review trigger |
|---|---|---|---|---|---|---|
| D-GOV-001 | CAP Gate 1 regression threshold: 2 % or 5 %? | OPEN_DESIGN_QUESTION | CAP v1.0 spec not in repo (F-GOV-001); no gate implementation exists (F-GOV-009) | single threshold · per-subject-class thresholds · banded (2 % warn / 5 % fail) | Decide only after the seven gates are implemented and can fail (Batch 1.6 principles) | gate implementation lands |
| D-GOV-002 | CAP Gate 2 conditional/failure boundary | OPEN_DESIGN_QUESTION | same | boundary values · explicit state machine | Same | same |
| D-GOV-003 | CAP Gate 5 1 % / 3 % / conditional ranges | OPEN_DESIGN_QUESTION | same | same | Same | same |
| D-GOV-004 | Statistical validity: minimum samples, confidence intervals, calibration bins, insufficient-data behaviour | OPEN_DESIGN_QUESTION | same | fixed minima · per-metric minima · Bayesian priors | Insufficient data must yield "no verdict", never a pass | calibration data volume known |
| D-GOV-005 | Fail-closed versus retry semantics | OPEN_DESIGN_QUESTION | `permitted?/1` accepts `:conditional` (F-GOV-005); verifiers fail open (F-ARC-007) | timeout=retry · timeout=block · explicit third state | Block authorisation, but record a distinct `operational_failure` state so a failure is never misreported as a subject failure | Batch 1 lands |
| D-GOV-006 | Replay guarantee boundary | OPEN_DESIGN_QUESTION | replay packages not found; `REPLAY_AUDIT.md` unread in R0 (F-EPI-009) | freeze all inputs · freeze inputs + record non-determinism | Freeze policies, versions, seeds and non-deterministic outputs; external systems recorded as boundaries | replay format published (D-ARC-006) |
| D-GOV-007 | Distributed arbitration: consensus vs eventual consistency vs LWW | OPEN_DESIGN_QUESTION | federation quorum contradicts its own guarantee; votes replayable (F-GOV-015) | Raft-style quorum · LWW with audit · eventual consistency + conflict register | Cannot be chosen before the quorum arithmetic is fixed; constitutional safety must not depend on LWW | federation implementation lands |
| D-GOV-008 | Certificate binding: subject version, policies, evidence set, validity | OPEN_DESIGN_QUESTION | no signature/expiry/subject binding; "signature" is an unkeyed SHA-256 (F-GOV-010) | content hash · HMAC · asymmetric signature | Requires the operator's deferred key-management decision (Babel/C-08) first | key design decided |
| D-GOV-009 | Policy authority: who may amend `rules.md`, which version governs pending audits, how human approval is enforced | OPEN_DESIGN_QUESTION | `rules.md` (225 lines) is read by no code; the runtime authority is hard-coded structs (F-GOV-002) | document normative + parser · code normative + document derived · both with a stated precedence | Establish precedence explicitly; until then a document/code divergence is unresolvable | see D-ARC-002 |
| D-GOV-010 | Scope of the five-minute audit timeout | OPEN_DESIGN_QUESTION | no timeout implementation located | all subjects · defined subject classes only | Define by subject class and measure | CAP gates implemented |

## Part B — Ownership and architecture decisions (proposed; the five permitted outcomes are keep / merge / adapterise / retire / preserve-independent)

| ID | Question | Status | Recommendation (per `ownership_duplicates.csv`) | Evidence | Review trigger |
|---|---|---|---|---|---|
| D-ARC-001 | Which module owns executive state? | PROPOSED | One canonical executive-memory store per deployed application; the others become adapters. Currently ≥4 implementations, 3 booted, 3 different persistence formats (F-COG-012) | `ownership_duplicates.csv`; capability CAP-COG-012 | Batch 4.2 |
| D-ARC-002 | Which artefact is the authoritative constitutional policy: `rules.md` or the hard-coded policy structs? | PROPOSED | The machine-readable registry is authoritative for evaluation; the document is normative for intent and is parsed/version-checked against it. Without this, every policy question has two answers (F-GOV-002, F-GOV-020, F-ARC-003) | F-GOV-002; `deps_governance.json` | Batch 6.2 |
| D-ARC-003 | Which interface version is canonical, and where is the event registry? | PROPOSED | One registry owned by the platform, versioning every subject and payload; the current ≥7 root event buses are registered, bridged or declared legacy (F-ARC-004, F-ARC-020) | `deps_code.json` discrepancies | Batch 6.1 |
| D-ARC-004 | Which storage system owns which record? | PROPOSED | Publish the store-ownership map (CPL for cognitive state, DETS for audit logs, DB for product data); no store may be owned by two modules (F-PLT-009, F-ARC-018) | `ownership_duplicates.csv` | Batch 4.3 |
| D-ARC-005 | Are the root Elixir project and `tiannara_runtime` two applications or one? | **PROPOSED — INTERIM DEPLOYMENT BOUNDARY (operator, 2026-10-21, resolving OP-04 for the reachability phase)** | Operate the root Elixir application and `tiannara_runtime` as **separate releases/processes** for the initial reachability phase. Do **not** load both into the same BEAM runtime and do **not** merge their source trees while the 28 duplicate fully-qualified module names remain unresolved. Establish canonical ownership and an explicit communication contract before attempting co-residency or consolidation. | `certification/atlas/batch2/` (launch boundary); F-ARC-001 (28 duplicate module names), F-ARC-011 (11 redefinition warnings) | canonical ownership per namespace recorded (Batch 4.2), or a co-residency decision by the operator |
| D-ARC-006 | Which replay-package format is canonical? | PROPOSED | One format, versioned, produced by the audit chain and consumed by replay tooling; today no canonical format exists (F-EPI-009) | F-EPI-009 | Batch 6.1 |
| D-ARC-007 | Which kill switch is canonical? | **DECIDED (2026-10-21, R1/Batch 1 step 6)** | The 5F.3.5 unified module `TiannaraRuntime.MultiWorld.KillSwitch` is canonical and is the only one started. The two retired copies (`HardenedKillSwitch`, `KillSwitchCausal`) are not started and remain in the tree as unowned code pending R2 retirement. The dead consumer API (`get_killed_worlds/0`, `request_kill/2`, `confirm_kill/2`) was resolved as follows: `get_killed_worlds/0` is **implemented on the canonical module** (the reporting contract the consumer needs), `request_kill/2` delegates to the canonical `request_termination/3`, and `confirm_kill/2` is **retired** — it existed in no implementation and had no caller. | `certification/atlas/closure_records/R1-B1-07_F-GOV-013.md` | the world supervisor is started (F-ARC-240) |
| D-ARC-008 | Which code-generation path is production-supported? | PROPOSED (ESAP repository) | In `Kimiti4/autonomous-API-Gen`: one ISR authority and one emitter authority, with the fail-closed machinery wired into the certified emitters (F-ESP-001, F-ESP-010) | `esap/esap_inventory.md` | ESAP track |
| D-ARC-009 | Are the three absent frontends in scope for this repository? | PROPOSED (blocked on OP-03) | Re-vendor, submodule-pin, or record as an external boundary with an interface pin; do not leave them on disk only (F-PLT-003, F-ARC-024) | F-PLT-003 | operator answer to OP-03 |
| D-ARC-010 | Which cognitive orchestrator is canonical? | PROPOSED | One of the three parallel stacks (ECR, Sentinel.Cognition, runtime cognitive lib) is designated; the others become components of it or are retired. Today no control flow crosses the stacks (F-COG-001) | F-COG-001 | Batch 4.2 |
| D-ARC-011 | Which evaluation path is authoritative for the Council's constitutional decision? | **DECIDED (2026-10-21, R1/Batch 1 step 2)** | The **built-in assessment** in `Tiannara.Council.RuleEngine` is the authoritative evaluation path. `Tiannara.Council.PrincipleRegistry` is the registry the rule engine aliases (so it is the authoritative registry *for the Council path*), but it is **not activated**, because activating it today would change the constitutional coverage of every decision. The plugin path is fail-closed (an empty plugin set falls back to the built-in assessment) and **augments** rather than replaces the built-in assessment. `TiannaraOS.PrincipleRegistry` is a different namespace with no Council consumer and is not part of this path. | `certification/atlas/closure_records/R1-B1-04_F-GOV-006.md` | a plugin contract is designed (D-ARC-012) and the registry is proposed for activation |
| D-ARC-012 | How should plugin principle weights be scaled against the built-in weights? | OPEN_DESIGN_QUESTION | The two shipped plugin principles declare `weight 1.0` each, while the eleven built-in weights sum to 1.0. If the registry is activated, the plugins would carry two thirds of the compliance score. Options: normalise plugin weights into the built-in scale · keep plugin weights as declared and accept the dominance · split the score into a built-in and a plugin component. | `lib/tiannara/council/principles/*.ex` (`weight/0` = 1.0); `lib/tiannara/council/rule_engine.ex` (`principle_weight/1`) | the plugin contract is designed |
| D-ARC-013 | Should a decision that violates a principle be routed to `:requires_human`? | OPEN_DESIGN_QUESTION | Not now: without the human-approval resume path (F-GOV-004) such a decision would be parked with no way to resume — the same dead end the backlog records. Today a violating decision keeps its pre-change verdict and is refused by both authorisation gates, because the structural precondition (no violated principles) fails. Revisit when the resume path lands. | `certification/atlas/closure_records/R1-B1-04_F-GOV-006.md` (behaviour table) | F-GOV-004/F-GOV-017 land |
| D-ARC-015 | Should the CIS arbitration fail closed for an unrecognised (safety mode, severity) pair? | OPEN_DESIGN_QUESTION | The CIS arbitration currently approves the `:normal`/`:critical` pair and falls back to `:approve` for anything it does not recognise, which is fail-open. Denying unknown cases is the safer default, but it changes constitutional behaviour and is a decision for the operator — deliberately not made inside a stabilization batch. | `certification/atlas/closure_records/R1-B1-07_F-GOV-013.md` | the operator decides |
| D-ARC-016 | Is `Tiannara.ControlCenter` a runtime authority? | PROPOSED (Batch 2.2 disposition) | Under D-ARC-005, ControlCenter remains a **root `:tiannara` authority**, started by `Tiannara.Operations.OperationsSupervisor`. It is **not** started in `tiannara_runtime`, and the runtime's `/api/v1/system/status` does not claim it. If cross-process operational status is required, it must be an explicit interface between the two releases, not a co-loaded module. | `lib/tiannara/control_center.ex`; `lib/tiannara/operations/operations_supervisor.ex`; `certification/atlas/batch2/runtime_reachability.md` (Step 4) | operator approval; Batch 4.2 ownership pass |
| D-ARC-017 | What is the runtime event transport? | OPEN_DESIGN_QUESTION | The current `NATS` name covers an in-VM `Registry` bus, a raw TCP listener on 4222, and a hard-disabled `EventGateway` (`connect_nats/0` returns `{:error, :unavailable}`). Options: (a) wire a real `gnat` client and remove the raw listener/port collision; (b) rename the in-VM path and declare the raw listener a development-only ingest, while correcting `get_status/0` to report actual connectivity. The runtime-to-Python telemetry POST to `localhost:8004/api/v1/meta-ecology/ingest` must also have a non-colliding target. | `tiannara_runtime/lib/tiannara_runtime/nats/connection.ex`; `event_gateway.ex`; `ecology/universe_server.ex:283`; `tiannara_api/routes/meta_ecology.py:31`; `certification/atlas/batch2/runtime_reachability.md` (Step 4) | Batch 2.4 decision; F-ARC-228 |

## Part C — Temporary exceptions (each requires an expiry condition)

| ID | Exception | Scope | Expiry condition | Status |
|---|---|---|---|---|
| E-001 | 6 tests remain quarantined (omega ×2, reactivity ×2, passive population, no-mocks scope) | `tiannara_runtime` | Re-admission conditions recorded in `TIANNARA_RUNTIME_TEST_INVENTORY.md`; the quarantine job is non-blocking | ACTIVE |
| E-002 | `phase_5f2_tests.yml` runs only on `main`/`develop` | 5F.2 suite | Batch 6.4 widens the trigger or folds the job into the branch-spanning workflow | ACTIVE |
| E-003 | `ci-cd.yml` / `test.yml` run only on `main`/`master` | Python, Docker, release | Batch 6.4 | ACTIVE |
| E-004 | Three frontends are on disk but not in git | GUI, dashboard, mobile | OP-03 answer; D-ARC-009 | ACTIVE |
| E-005 | Root `*.dets` churn and 470 deleted tracked files remain in the working tree | repo root | operator decision on history hygiene (outside R0 scope) | ACTIVE |
| E-006 | `tiarnara_runtime` (typo) directory and flattened `cUsersuserTiannara…` root directories exist | `tiannara_runtime/lib`, repo root | F-ARC-237; disposition in R2 | ACTIVE |

## Part D — Superseded history (preserved, never erased)

- Prior phase-completion claims that R0 disproved (e.g. OPC "production-ready" — F-COG-101) are superseded by the capability register, not deleted; the original documents remain in the repository as history.
- The prior "23 orphaned modules" figure quoted in earlier audit documents is **not locatable** in the wiring audit (13 source disagreements) — treated as an unverified figure, superseded by the capability register's own enumeration.
- `baseline.md`'s original statement that `ci-cd.yml` triggers on `local/pr5`/`local/pr6` is **contradicted** by the workflow file (`main`/`master` only) and is corrected in `baseline_verification_report.md` N-9 / F-PLT-004.

---

# Part E — R0 review dispositions (operator, 2026-10-21)

**R0 outcome:** accepted as the static baseline. **R1 Batch 1:** approved in principle, as an ordered sequence of
reviewable changes — not as an unrestricted seven-item implementation pass.

These dispositions are recorded in this register rather than in new planning documents, per the operator's instruction.

## E.1 The five operator decisions — disposition (operator-supplied)

| ID | Decision | Disposition (operator, 2026-10-21) | Implementation status in this programme |
|---|---|---|---|
| OP-01 | Exposed credential | Rotate the credential and move runtime configuration to a secret-manager reference. Then handle history remediation under the repository's secret-handling procedure. Record evidence of rotation **without reproducing the secret**. Operational security action, not a normal code-fix item. | **Code-side removal executed** (literal values removed from the tracked overlay and from a tracked audit document; secret generator now reads from the environment). **Rotation itself requires cluster/secret-manager access that this workspace does not have** — the procedure and the evidence template are in `certification/atlas/ops/OP-01_CREDENTIAL_ROTATION.md`. Rotation is **not** claimed as done. History remediation is left to the operator's secret-handling procedure (no history rewrite performed). |
| OP-02 | Constitutional specifications | Preserve the CAE v1.1 and CAP v1.0 material previously supplied as candidate specifications, with exact text, version, source and digest. The authoritative ISD v2.0, IF-001–IF-004 and UEP documents are **not** established by the R0 report: recover their exact versions or formally defer them. Do **not** reconstruct them from summaries and call them authoritative. | Candidate specifications to be ingested into the atlas as *candidate specifications* with version + digest; recovery of ISD/IF/UEP remains **OPEN** — the operator is the source of truth, this programme will not synthesize them. Tracked as D-GOV-001..010 in Part A and OP-02 in `remediation_backlog.md`. |
| OP-03 | Three frontends | Treat `tiannara_gui`, `tiannara_internal_dashboard` and `tiannara_mobile` as **unaudited** until their authoritative repository and revision are identified. Local directories alone do not establish versioned, deployable implementations. If their sources cannot be identified, record a formal deferral rather than inventing replacement frontends. | Recorded: capability rows for these surfaces remain non-verified, E-004 stays ACTIVE, D-ARC-009 becomes a formal deferral if the operator cannot identify the sources. No replacement frontends will be created. |
| OP-04 | Root project vs `tiannara_runtime` | The launcher does not start `:tiannara_runtime` and 28 duplicate fully-qualified module names exist. **Do not start both blindly in one BEAM and do not merge their source trees.** Preserve the boundary and document the current deployment reality; choose the eventual co-deployment topology only after assigning one owner per colliding module and verifying the real launch path. | **RESOLVED for the reachability phase by the interim decision D-ARC-005 (operator, 2026-10-21): separate releases/processes.** Boundary preserved; D-ARC-005 is no longer blocked for Batch 2, and the per-module ownership decisions remain the precondition for any later co-residency (Batch 4.2). The authority boundary required before Batch 1 step 2 was resolved per step 2's prerequisite in `remediation_backlog.md` (which Council/PrincipleRegistry copy is authoritative), **not** by a topology decision. |
| OP-05 | GRCC, MSCL, world-scale figures | Mark GRCC 74.8 %, MSCL 88.5 % and the 12-world / 84-civilization / 23,800-agent run as **historical and unverified**, not as current operational measurements. Preserve their history; re-establish only with a reproducible run through a real runtime path. | Applied in the atlas wording; no figure is used as an acceptance criterion anywhere in Batch 1. Re-establishment requires a real runtime path (Batch 2 reachability) and is out of scope for Batch 1. |

**Explicit note carried forward:** the operator states that the dispositions are *handling recommendations*, not
claims that the credential has been rotated or that the missing documents have been recovered. This register uses the
same discipline: a disposition is recorded as `DISPOSITION_RECORDED`, and the underlying action keeps its own status
until evidence exists.

## E.2 Batch 1 — approval record, sequence and hard conditions

**Approved scope:** the six ordered steps of `remediation_backlog.md` Batch 1, executed as **ordered, reviewable
changes** (one commit per step, each with its own closure record and CI evidence).

**Two hard conditions attached to the approval:**

| Condition | Meaning in execution | Enforcement point |
|---|---|---|
| **HC-1** — the exposed credential must be dealt with before remediation proceeds | The literal credential must leave the tracked repository and a rotation path must be recorded before the first behavioural code change lands. | Satisfied by the OP-01 commit preceding the F-GOV-007 change. Rotation remains an operator action (cluster access required); the code-side exposure is closed by that commit. |
| **HC-2** — the runtime/authority boundary must be resolved before approvals become reachable | Making `:approved` reachable (step 2) must not proceed until the authoritative Council and `PrincipleRegistry` copies are identified. Activating the wrong duplicate would manufacture another misleading success. | Step 2 may not begin until the authority determination is recorded (per-namespace owner + the application that actually starts it). |

**Mandatory ordering constraint (from the report, confirmed by the operator):** F-GOV-007 must be fixed **and
verified** before F-GOV-006 / F-GOV-023 makes `:approved` reachable. If the order is reversed, an approval path that
bypasses hard invariants is activated.

**Per-step exit criteria (operator):**

| Step | Finding(s) | Exit criterion |
|---|---|---|
| 1 | F-GOV-007 | A negative test demonstrates that an invariant violation plus an approving policy still produces a non-approved result. The test runs in CI and is bound to the exact commit. |
| 2 | F-GOV-006 / F-GOV-023 | A compliant decision can reach an approved-equivalent verdict **through the selected authoritative application**, with the authority determination recorded first (HC-2). |
| 3 | F-GOV-003 / F-GOV-005 | `:any` matching works as intended; `Authorization.permitted?/1` rejects `:conditional` unless an explicitly designed, separately audited conditional-grant mechanism exists. |
| 4 | F-GOV-004 / F-GOV-017 | The parked decision is **re-evaluated** on approval arrival; the approval record alone never authorizes a privileged transition. |
| 5 | F-ARC-007 / F-GOV-011 | Missing expectations, absent inputs and false claims **fail**. The old "220/220 PASS" result is retired as non-evidence and is not preserved by weakening the replacement. |
| 6 | F-GOV-013 | The authoritative kill-switch implementation is identified, started through the proper supervision path, its consumers repaired, and activation **and recovery** tested. The duplicate is not chosen merely because it is easier to wire. |

**Explicitly deferred inside Batch 1:** certificate signing / key management (operator's Babel/C-08 decision). It is not
improvised during Batch 1.

## E.3 Closure-record schema (required for every remediation change)

Every change under this programme records one closure record in `certification/atlas/closure_records/`, with exactly
these fields. A change without a complete record does not move its finding's status.

| Field | What it must establish |
|---|---|
| Finding ID | The exact existing finding or root-cause cluster being addressed |
| Baseline and candidate SHA | Which code was inspected and which revision is claimed to fix it |
| Changed implementation and consumers | The actual source symbols, the authority owner, and the affected consumers |
| Before/after test evidence | A test that demonstrates the defect, then proves the intended behaviour — including denial and failure cases, not only the happy path |
| CI and execution evidence | Command, exit status, logs, environment, and run/commit references |
| Atlas update | Capability state, dependency edges, finding status, and any ownership decision |
| Closure status | `FIXED_PENDING_VERIFICATION` until the evidence is bound; `VERIFIED_CLOSED` only after the acceptance criteria pass |

**Programme-level rule (operator):** the complete runtime suite and the root project suite must pass at the candidate
SHA, with no existing test deleted or weakened to make the result green.

**Post-Batch-1 order (operator):** runtime reachability → real data and verifiers → canonical module ownership →
broader interface and architecture unification. Do not merge the 28 duplicate modules before their canonical owners are
recorded. Do not build CAE/CAP gate machinery from incomplete specifications. ESAP stays in its own repository and its
own audit ledger.

---

# Part F — Batch 2 operating constraints (operator, 2026-10-21)

These are the constraints that apply while the runtime reachability work is in progress. They exist so that an
unresolved item cannot quietly become an assumption because the system booted.

| ID | Constraint | Applies to | Evidence of compliance |
|---|---|---|---|
| BF-01 | **OP-02 — constitutional specifications.** The CAE v1.1, CAP v1.0, ISD v2.0, IF-001..IF-004 and UEP documents must be recovered with their exact source, version and digest, or formally deferred. Replacements must **not** be invented. | Any capability whose requirements are unconfirmed | No such capability is certified or activated on the basis of a successful boot. The Batch 2 evidence records which capabilities were merely *reachable* and which remain `specified_not_proven`. F-GOV-001 stays open. |
| BF-02 | **OP-03 — missing frontends.** The GUI, dashboard and mobile surfaces stay **unverified** until the repository and revision that owns them are identified. No substitute frontends are created to make the inventory look complete. | CAP-PLT-005, CAP-PLT-006, F-ARC-024 | The Batch 2 evidence does not claim any frontend connectivity. F-PLT-003 stays open. |
| BF-03 | **OP-01 — credential rotation.** F-SEC-001 stays open until rotation is independently evidenced. Repository cleanup alone authorises **no** production deployment that relies on the exposed credential, and an isolated test environment must use its own safe configuration. | Any launch in Batch 2 | The Batch 2 launch uses an isolated configuration and its own generated secrets; no production configuration is exercised. F-SEC-001 stays open. |
| BF-04 | **F-GOV-025 safeguard.** The rule engine reads two different evidence signals (`:evidence` list and `:evidence_count` key). Booting may proceed in an isolated environment, but **privileged or consequential effects stay disabled** until the conflicting decision inputs are investigated and the authorization result is shown to depend on the intended authoritative evidence. | Kill switch, world execution, resource termination, any effect with an external consequence | Batch 2 step 3 exercises the kill path against a supervised test child, not against real worlds. F-GOV-025 stays open. |
| BF-05 | **Interim deployment boundary (D-ARC-005).** The root application and `tiannara_runtime` are separate releases/processes. A separate process is **not** an integrated platform: any inter-process connection must itself be demonstrated with execution evidence. | Every claim of a working platform edge | The Batch 2 evidence distinguishes a reachable process from a demonstrated connection. |
| BF-06 | **Dirty working tree.** The pre-existing working-tree artefacts (root `*.dets` churn, 470 deleted tracked files, runtime data churn) are left untouched. Batch 2 artefacts are written outside the repository, or under `certification/atlas/batch2/` as records. | The whole batch | `git status` is unchanged apart from the atlas records. |