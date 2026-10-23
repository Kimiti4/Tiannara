# Ranked root-cause remediation backlog (Phase R0 deliverable 8)

**Status:** discovery output. Nothing in this backlog has been executed, scheduled, or partially started.
Every entry is `OPEN`. A code change alone would not close a finding — closure requires the acceptance evidence named here, bound to an exact commit SHA (operator rule: *a code change is not a closed finding*).

**Ranking basis:** severity weight × breadth (distinct registered capabilities affected) × dependency centrality × blast radius × remediation prerequisite order. Not by symptom count.

**Scope note:** entries marked **[ESAP]** belong to the separate `Kimiti4/autonomous-API-Gen` repository and must be executed there; they are never merged into the platform inventory (operator §repository-boundaries).

---

## Batch 0 — operator actions that are not code changes (do first, in parallel)

| ID | Action | Findings | Rationale |
|---|---|---|---|
| OP-01 | Rotate the literal credential in the k8s production overlay and move it to a secret manager reference; scrub from history per policy | F-ARC-008, F-PLT-005, F-ARC-009 | Tracked plaintext credentials are an active exposure; code fixes do not undo exposure. Independent of every code fix. |
| OP-02 | Confirm with the operator whether CAE v1.1, CAP v1.0, ISD v2.0, IF-001..IF-004 and the UEP schema exist outside this checkout, and import them as candidate specifications **or** formally defer them with a date and scope | F-GOV-001, F-EPI-001, F-ARC-006, F-PLT-001 | 22 capabilities are "specification-only" only because their specification is not in the repository. Until this is answered, these capabilities cannot be reconciled at all, and no certification may cite them. |
| OP-03 | Confirm whether the three absent frontends (`tiannara_gui`, `tiannara_internal_dashboard`, `tiannara_mobile`) exist in another repository, submodule, or only on disk | F-PLT-003, F-ARC-024 | 3 of 5 frontends are unauditable; the WebGL Observatory capability in the plan cannot be assessed. |
| OP-04 | Decide the deployment topology: does the root Elixir project co-deploy with `tiannara_runtime`? | F-ARC-001, F-ARC-011, F-ARC-013 | 28 duplicate fully-qualified module names make every unification decision ambiguous until this is answered. |
| OP-05 | Retire or re-derive the unreproducible figures (GRCC 74.8 %, MSCL 88.5 %, 12-world/84-civ/23 800-agent run) | F-WRD-001, F-WRD-002, F-ARC-017 | A number that cannot be reproduced is not evidence; keeping it in the record is itself the risk. |

---

## Batch 1 — **RECOMMENDED NEXT BATCH**: constitutional enforcement integrity + fail-closed claim control

**Why this batch first:** it is the only cluster whose members are safety-relevant *and* whose fix is contained (no architecture change, no module moves), testable with negative tests, and immediately observable in the required CI job. It also restores the truthfulness of the evidence system: until verifiers can fail, no other closure claim can be trusted.

**Ordering constraint (must be respected):** `F-GOV-007` **before** `F-GOV-006`/`F-GOV-023` — making `:approved` reachable (by starting `PrincipleRegistry`) would expose the hard-invariant bypass to live traffic.

| # | Finding | Root cause | Minimal recommended change | Alternatives & trade-offs | Blast radius | Acceptance criteria (evidence required to close) |
|---|---|---|---|---|---|---|
| 1.1 | F-GOV-007 (critical) | `score_auth/3` decorates an authorization but never re-derives the decision, so a policy `:approve` bypasses hard invariants | Make the hard-invariant check authoritative and the policy action advisory inside `Council.authorize/3`; a violated invariant must force a non-`:approved` decision regardless of policy | (a) Reject `:approve` policy actions outright (strictest, breaks existing policies); (b) advisory-with-override (chosen, preserves policy vocabulary) | Council authorization path; all consumers of `Council.authorize/3` | New negative test: a decision violating a hard invariant with a `:approve` policy returns non-`:approved`; existing positive-path tests unchanged; runtime suite green |
| 1.2 | F-GOV-006 + F-GOV-023 (critical) | Built-in scorer can only emit `:neutral`/`:violated` (cap 0.70 < 0.80 threshold); the plugin path that could emit `:strengthened` is never started | Decide the scorer contract: either raise the built-in scorer so a compliant decision can reach the threshold, or explicitly register `PrincipleRegistry` in the supervision tree — **after 1.1** | (a) Lower threshold (rejected: weakens the invariant); (b) Add a third verdict explicitly and make `permitted?/1` treat it correctly | Rule engine, council decision flow | Test: a compliant real-world decision type reaches an approved-equivalent verdict through the *production* path, not a test-only path |
| 1.3 | F-GOV-003 (critical) | `policy_registry.ex:45` matches `decision_type in applies_to` literally, so `:any` never matches | Implement the wildcard: `:any` in `applies_to` matches every decision type (one-line semantics change, two policies become live) | Keep literal matching and rewrite the two policy descriptors (equivalent effect, but leaves the wildcard trap for future policies) | PolicyRegistry, high-risk and invariant-protection decisions | Test: a high-risk decision type reaches the `high_risk` policy; an invariant-touching decision reaches `invariant_protection`; negative test that unrelated decisions are unaffected |
| 1.4 | F-GOV-005 (critical) | `Authorization.permitted?/1` accepts `:conditional`, so a conditional decision mints a machine grant | `permitted?/1` must require `:approved` (or an explicit, separately-audited conditional grant) | Add a `permitted_with_conditions/1` for conditional use and keep `permitted?/1` strict (chosen: no call-site silence) | All authorization call sites | Negative test: a `:conditional` decision yields `false` from `permitted?/1`; positive test for `:approved` |
| 1.5 | F-GOV-004 + F-GOV-017 (critical) | Human approval records a decision but never resumes it; the state machine therefore cannot authorize itself and `restart_service/2`/`halt/2` are unreachable | Add a resume path: on approval, re-evaluate the parked decision with the grant applied, and gate the privileged transitions on the re-evaluated result | (a) Resume synchronously in the approval call; (b) Resume via a supervised coordinator (chosen: keeps the approval handler narrow) | HumanApprovalQueue, CEL kernel state machine, service control | Test: a `:requires_human` decision is parked, approved, and resumes to a terminal authorized state; a rejected approval leaves it parked and non-authorized |
| 1.6 | F-ARC-007 + F-GOV-011 (critical) | `tiannara_audit` verifiers return `match: true` unconditionally and treat a `nil` expectation as PASS, yet produced the "220/220 PASS" reports cited downstream | Fail-closed contract: missing expectation, mismatch, or absent input is FAIL; add a test that the verifier fails on a deliberately false claim | (a) Delete the tool and its reports (rejected: the tool is useful once it can fail); (b) Rebuild the comparison step (chosen) | `tiannara_audit` tool, every downstream report that cites it | Test: a false claim yields a failing verdict and a non-zero exit; a true claim still passes; CI job runs the verifier suite on every PR |
| 1.7 | F-GOV-013 (critical) | None of the three kill-switch modules is started; `world_supervisor.ex:111,136,140` calls a dead API; `safety_cortex.ex:393` sends to an unregistered name outside any `try/rescue` | Start the canonical kill switch, route `world_supervisor`/`safety_cortex` to it, and wrap the unguarded `send/2` | Retire the two dead duplicates first (defers the wiring but reduces ambiguity) | World supervision, safety cortex, CIS arbitration | Test: kill-switch activation stops a supervised subsystem and is observable; the `send/2` path no longer raises; recovery path exercised |
| 1.8 | F-GOV-010 (high) | "Signature" is an unkeyed SHA-256 with a hardcoded `manifest_id`; no validity period, no subject-version binding | **Deferred to Batch 2** — signature key management (Babel/C-08) is already deferred by the operator and must not be improvised | Keyed HMAC with a managed secret; asymmetric signing | Certificate verification | (Batch 2) Certificate binds subject version + expiry; a tampered or expired certificate fails verification |

**Batch 1 exit condition:** every item above has a test that fails before the change and passes after; the runtime suite (`mix test --exclude quarantine`) and root suite are green at the batch SHA; the affected findings move `OPEN → FIXED_PENDING_VERIFICATION` (not `VERIFIED_CLOSED`) until the evidence is bound to the exact SHA in Register 6.

---

## Batch 2 — reachability: make the runtime application actually start

**Execution record (2026-10-22/23):** `certification/atlas/batch2/runtime_reachability.md`. The isolated safe boot
and kill-switch chain were demonstrated locally on an uncommitted working tree; the full runtime suite passes (1863
tests + 40 properties, 0 failures) with CPL/Omega/Mnesia/identity-ledger test isolation. F-ARC-240 is
`FIXED_PENDING_VERIFICATION`; F-ARC-018/B4 remains `OPEN` because test isolation does not satisfy its broader
persistence-hygiene criteria. F-ARC-226,
F-ARC-228, F-ARC-235, F-ARC-014 and F-ARC-229 remain open.

**Why:** `F-ARC-226` (launcher never starts `:tiannara_runtime`) is the single highest-leverage fix: every "wired" claim inside that application is currently test-time-only wiring. 24 registered capabilities are affected by the cluster that contains it.

| # | Finding | Minimal recommended change | Acceptance criteria |
|---|---|---|---|
| 2.1 | F-ARC-226 | Add `:tiannara_runtime` to a launcher/release path (release applications list, `Procfile`/compose service, or an explicit documented single-OTP-root decision) | A boot check starts the app and asserts the top supervisor is alive; the boot tree is reachable from the launcher, not only from `mix test` |
| 2.2 | F-ARC-235 | Add `Tiannara.ControlCenter` (documented owner of ~29 subsystems) to a boot tree, or record the decision that it is not a runtime authority | Either the process starts and its ordering contract is enforced, or a Register-7 decision supersedes the documentation |
| 2.3 | F-ARC-014, F-ARC-229 (prod config / no release) | Add a fail-closed `config/prod.exs`; add `releases/0` to both Elixir projects; a CI job that produces the tarball | `MIX_ENV=prod mix compile` and `mix release` succeed; artifact hash recorded in Register 6 |
| 2.4 | F-ARC-228 | Decide the event transport: wire the real `gnat` client or rename the in-VM broadcast so it is not called NATS; correct `get_status/0` to report actual connectivity | Status reporting reflects real state; a connectivity test distinguishes connected from degraded |
| 2.5 | F-ARC-227 | Delete the silent mock fallback in the observatory API client, or mark every fabricated payload with a synthetic flag | The edge either returns live data or fails loudly; no fabricated world data can be served as measured |

---

## Batch 3 — truthfulness of evidence: fail-closed verifiers, real data, real claims

| # | Finding | Minimal change | Acceptance criteria |
|---|---|---|---|
| 3.1 | F-COG-002, F-COG-006 (booted stubs return constants; tests assert those constants) | Replace the asserting tests with tests that fail against the constant, or mark the engines `specified_not_proven` and remove the "production-ready" claim | No test asserts a constant value as correct behaviour; affected capabilities re-classified in Register 2 |
| 3.2 | F-EPI-002 (evidence ageing configured, never applied), F-EPI-003 (trust scoring from a hardcoded 0.7) | Apply the configured decay in the read path; replace the constant with a measured value or disable the feature and reclassify it | Decay demonstrably changes a read result; trust score derives from observed outcomes |
| 3.3 | F-GOV-008 (invariant monitor scores an empty set as 1.0), F-GOV-009 (seven CAP gates do not exist), F-GOV-012 (Merkle root has no consumer) | Empty input is not perfection — fail closed; map gate machinery to the CAP contract or record CAP as unimplemented | Monitor reports "no data" distinctly from "all invariants hold"; CAP capability reclassified, not claimed |
| 3.4 | F-WRD-001, F-PLT-015 (mock data served as measured) | Tag generated artefacts as synthetic at write time and propagate; remove silent fallbacks | Every synthetic artefact is identifiable by its consumer |

---

## Batch 4 — canonical ownership (operator phase R2)

| # | Finding | Minimal change | Acceptance criteria |
|---|---|---|---|
| 4.1 | F-ARC-001 + F-ARC-011 (28 duplicate fully-qualified modules; 11 redefinition warnings) | Per-namespace owner decision (keep / adapterise / retire) recorded in Register 4, then enforced by a CI check that fails on a new cross-project `defmodule` collision | No duplicate fully-qualified module names across the two Elixir projects; CI check fails on a deliberate collision |
| 4.2 | F-ARC-002, F-ARC-003, F-COG-003, F-COG-012, F-COG-015, F-ARC-005 (KillSwitch ×3, constitution ×5, CIS ×6, Executive Memory ×4, KG ×4, MindCache stores ×10) | One Register-4 decision per concept (already drafted in `ownership_duplicates.csv`), then execute the chosen outcome | Each concept has one authoritative implementation, named state owner, and explicit consumers |
| 4.3 | F-EPI-005, F-EPI-006, F-COG-014, F-PLT-009 (stores without owners/recovery) | Publish the store-ownership map; make every store path environment-configurable; stop committing DETS/binary stores to git | Every persisted store has an owner, a path source, and a documented restore procedure |

---

## Batch 5 — security defaults (independent of the above, can run in parallel)

| # | Finding | Minimal change | Acceptance criteria |
|---|---|---|---|
| 5.1 | F-PLT-002, F-ARC-009, F-ARC-019, F-GOV-016 | Authentication on unless explicitly disabled; deny on mismatch; one authentication library across entry points; remove the unauthenticated payment-admin route; replace the forgeable human identity with verification against a credential store | Negative tests: missing/incorrect credential denied at every entry point; dev bypass impossible in non-dev environments |
| 5.2 | F-ARC-012, F-ARC-013, F-ARC-237, F-ARC-233 | Break the Python import cycle; stop the root app probing runtime process names no launcher provides; remove the flattened-path root directories; track the umbrella's own CI | CI check fails on a new import cycle / untracked directory artefact / missing workflow |

---

## Batch 6 — contracts, interfaces and documents (R2/R3 entry)

| # | Finding | Minimal change | Acceptance criteria |
|---|---|---|---|
| 6.1 | F-PLT-001, F-ARC-020, F-ARC-021, F-PLT-007, F-EPI-009 (no ISD/IF contracts, no event registry, no payload schema, namespace drift) | Publish one event registry (name, version, payload schema, producers, consumers) and one replay-package format; classify every transport registered/bridged/legacy | Every published event has a schema and a consumer; a compatibility test fails on an unregistered subject |
| 6.2 | F-GOV-002, F-GOV-020, F-ARC-003 | Decide the single constitutional policy authority (`rules.md` vs hard-coded structs) and make code read the decided source | Either the code reads the authoritative document, or a Register-7 decision records the document as non-normative with a named owner |
| 6.3 | F-WRD-005, F-COG-005, F-COG-007, F-COG-009, F-COG-011 | Either implement or formally defer: Context Graph, Completion Evaluator, POMDP dialogue state, Ontological Bridge, cross-domain transfer | Every deferred capability has a decision record with scope and review trigger; no capability claims a registry it cannot satisfy |
| 6.4 | F-PLT-004, F-ARC-015, F-COG-008, F-COG-018, F-GOV-022 (test-only wiring, CI that never runs on this branch) | Widen branch filters or fold the Python/audit jobs into the branch-spanning workflow; route at least one production path through each contract currently exercised only by tests | The Python and audit suites run on the remediation branch; a CI check fails when a contract has tests but no production caller |

---

## Batch 7 — ESAP repository (separate track, never merged)

| # | Finding | Minimal change | Acceptance criteria |
|---|---|---|---|
| 7.1 | F-ESP-001, F-ESP-010 | One ISR authority, one emitter authority; typed behavioural ISR consumed by the certified emitters | A generated candidate's ISR is the same object the emitter consumed |
| 7.2 | F-ESP-002, F-ESP-003 | Wire the RBAC/ABAC engine into generated enforcement points; define and emit delivery semantics (retries, DLQ, ordering, idempotency) | Generated routes deny by default; a failed delivery is retried and then dead-lettered in a test |
| 7.3 | F-ESP-004, F-ESP-006, F-ESP-009 | Browser-level frontend verification in CI; a runtime executor for deployment targets; no pass verdict with an empty test inventory | A full UI→API→persistence journey runs in CI; evidence ledger entries cite a non-empty candidate-bound test inventory |

---

## Explicitly NOT in this backlog (operator-deferred items, preserved unchanged)

- Stage B omega isolation design; OLEF field pinning; MSCL metric 0.0; passive population decay — product findings, still open, not re-ranked here.
- Babel/C-08 unkeyed SHA-256 secret-key design — deferred pending caller, threat model and key-management design; Batch 1.8 depends on it.
- `phase_5f2_tests.yml` latent issues (main/develop-only triggers, OTP 27, `--warnings-as-errors` against ≈700 warning lines) — documented; Batch 6.4 addresses the trigger problem only.
- C-11/C-13 duplicate consolidation — superseded by Batch 4.2 (same root cause, newly discovered instances added).

## Unknowns that constrain this backlog

No finding in this backlog is backed by a runtime trace produced during R0: **zero dependency edges are dynamically observed** and no test was executed during discovery. The CI runs cited in `baseline.md` are bound to the baseline SHA and to earlier SHAs; they are historical evidence, not proof for any future change. 15 findings cannot be settled from in-repo evidence at all — each names the evidence that would settle it in `findings_ledger.md` §3.
