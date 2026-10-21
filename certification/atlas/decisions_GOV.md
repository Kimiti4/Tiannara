# Section C — Architecture decision register: constitutional governance (seeds)

**Phase:** R0 (read-only discovery) · **Section:** C · **Branch:** `local/pr4` · **Date:** 2026-10-21
**Status of every entry below: `OPEN_DESIGN_QUESTION`.** Nothing here is decided, recommended, or
implied to be decided. Each entry records what the design inputs say, what the code actually does,
the options that exist, and the trigger that should force the question to be revisited.

**Provenance of the questions.** All ten questions come from
`certification/atlas/R0_SOURCE_PLAN.txt:1121-1153` (§7 "How we should handle CAE v1.1 and CAP v1.0"),
which states at `:1125` that the constitutional documents "should enter the System Atlas as candidate
specifications awaiting implementation reconciliation" and at `:1151` that these questions must be
resolved in the architecture decision register **before** further constitutional machinery is added.

**Standing constraint on this register.** Per `R0_SOURCE_PLAN.txt:257`: "your CAE v1.1 and CAP v1.0
specifications are design inputs for this audit. Their presence in documentation does not establish
that the corresponding runtime enforcement, certificates, or integrations are implemented." Neither
specification text is present in this checkout (verified: 0 hits for `Constitutional Arbitration
Engine` / `Constitutional Audit Pipeline` across `docs/**`, `markdown/**`, root `*.md`,
`certification/**`, `tiannara_runtime/priv/**`). Every "spec evidence" quotation below is therefore
quoted from the **R0 plan itself**, which is the only in-repo statement of the design intent — the CAE
and CAP documents themselves are outside the evidence base of this pass.

**Conventions.**

| Field | Meaning |
|---|---|
| `spec_evidence` | Direct quotation + path/line of the design intent. |
| `code_evidence` | `path:line` + symbol, or the literal string `not found in code`. |
| `options` | The distinct choices available. Presented neutrally; none is endorsed. |
| `review_trigger` | The observable event that should force the question to be reopened. |

---

## D-GOV-001 — CAP Gate 1 uses both a 2% and a 5% regression threshold

- **status:** `OPEN_DESIGN_QUESTION`
- **spec_evidence:** "CAP gate thresholds: Gate 1 uses both a 2% and a 5% regression threshold"
  — `certification/atlas/R0_SOURCE_PLAN.txt:1133`. Section C row:
  "Seven CAP gates | Capability alignment, uncertainty, adversarial robustness, explainability,
  regression, constitutional consistency, lineage" — `R0_SOURCE_PLAN.txt:231`.
- **code_evidence:** `not found in code`. Repo-wide search for a CAP Gate 1 implementation, for the
  acronyms `Gate1`/`CAP Gate`, and for any `2%` / `5%` regression-threshold constant in governance
  code returns nothing. The nearest numeric thresholds in the repository are unrelated:
  `tiannara_runtime/.../gck/chronogram_gate.ex:60,63` (`0.92`, `0.75`),
  `tiannara_runtime/.../certification/gates_06_07_08_09_10_11_12_13.ex:289-505` (13 different gates),
  `lib/tiannara/omega/governed_effect_sink.ex:34-70` (N1–N9 error taxonomy, no numeric thresholds).
- **competing-family reference:** `certification/atlas/capabilities_C_governance.csv` row
  `CAP-GOV-006`; `deps_governance.json` discrepancy `D-12`.
- **options:**
  1. Two thresholds with defined roles (e.g. 2% = warn / conditional band, 5% = hard fail) — one
     number is a soft boundary, the other a hard boundary.
  2. A single threshold with the second number retired as an earlier draft artefact.
  3. Two thresholds over *different metrics* (e.g. 2% on a primary regression metric, 5% on an
     aggregate across the subject class), making them non-conflicting.
  4. Threshold selected per subject class, with 2%/5% as the two endpoints of a class table.
- **review_trigger:** the CAP v1.0 specification text becomes available, **or** a Gate 1 implementation
  is proposed — whichever happens first. If the specification is recovered and still contains both
  numbers without roles, this question is a blocker for Gate 1 implementation and must be escalated
  before code is written.
- **related_findings:** F-GOV-009.

---

## D-GOV-002 — CAP Gate 2's conditional and failure ranges have no unambiguous boundary

- **status:** `OPEN_DESIGN_QUESTION`
- **spec_evidence:** "Gate 2's conditional and failure ranges need an unambiguous boundary"
  — `certification/atlas/R0_SOURCE_PLAN.txt:1133`. The verdict vocabulary required by the Section C
  row is "Correct PASS / CONDITIONAL / FAIL outcomes" — `R0_SOURCE_PLAN.txt:231`.
- **code_evidence:** `not found in code` for a CAP Gate 2. However, the repository *does* contain
  three decision vocabularies that could be mistaken for it, and they disagree with one another:
  - `lib/tiannara/council/rule_engine.ex:281-292` — `determine_decision/4` yields
    `:approved | :conditional | :requires_human | :rejected` with thresholds `compliance >= 0.8`,
    `>= 0.6`, `>= 0.4`, else rejected.
  - `lib/tiannara/council/authorization.ex:32` — the `decision` type is
    `:approved | :rejected | :deferred | :requires_human | :conditional`.
  - `lib/tiannara/os/phase_12_validation.ex` and the runtime campaign framework use
    `passing | degraded | failing` (`lib/tiannara/certification/tier3_constitutional.ex:28`).
  No mapping between these vocabularies exists in code.
- **competing-family reference:** `CAP-GOV-006`; discrepancies `D-12` and `D-03` (the RuleEngine can
  never reach `:approved` with the built-in scorer — see F-GOV-006, which means the `:conditional` band is currently the
  *only* reachable positive verdict for most decisions).
- **options:**
  1. Define Gate 2's bands as a strict partition of a single continuous score with explicit
     inclusivity at each boundary.
  2. Define Gate 2's bands over a non-continuous quantity (e.g. count of failed checks), where
     "conditional" is a distinct predicate rather than a range.
  3. Keep the four-value Council vocabulary as the runtime vocabulary and map
     PASS/CONDITIONAL/FAIL onto it with `requires_human` treated as a CONDITIONAL-with-obligation.
  4. Introduce a dedicated three-value CAP verdict type, separate from `Authorization.decision`.
- **review_trigger:** any CAP gate implementation begins, **or** the Council decision vocabulary is
  changed. Note that option 3 and option 4 interact with F-GOV-005 (`:conditional` currently satisfies
  `permitted?/1`, so the CONDITIONAL band is an *authorising* band, not an advisory one).
- **related_findings:** F-GOV-005, F-GOV-006, F-GOV-009.

---

## D-GOV-003 — CAP Gate 5's 1%, 3% and conditional ranges must be made consistent

- **status:** `OPEN_DESIGN_QUESTION`
- **spec_evidence:** "Gate 5's 1%, 3%, and conditional ranges must also be made consistent"
  — `certification/atlas/R0_SOURCE_PLAN.txt:1133`.
- **code_evidence:** `not found in code`. No Gate 5 implementation and no `1%` / `3%` threshold
  constants exist in governance code. The only percentage-shaped thresholds in the repository are
  `gck/chronogram_gate.ex:60,63` (`0.92`, `0.75`), `os/phase_12_validation.ex` Gate 1/1.5, and
  `lib/tiannara/omega/governed_effect_sink.ex` N-gates (categorical, not numeric).
- **notes:** Gate 5 is the *regression* gate per the Section C row ordering (capability alignment,
  uncertainty, adversarial robustness, explainability, **regression**, constitutional consistency,
  lineage) — `R0_SOURCE_PLAN.txt:231`. Gate 1 (D-GOV-001) is also described in the plan as a
  "regression threshold". Whether Gate 1 and Gate 5 measure the same quantity (regression) on
  different subjects, or different quantities, is itself unresolved and is a prerequisite to
  answering D-GOV-001 and D-GOV-003 coherently.
- **options:**
  1. One threshold set for all regression gates (Gate 1 and Gate 5 share numbers), removing the
     conflict at the root rather than per gate.
  2. Distinct thresholds per gate with the subject scope of each written down (Gate 1 = capability
     regression, Gate 5 = system-level regression).
  3. A single numeric threshold plus a separate, named "conditional range" that is expressed in the
     same units and explicitly bounded.
- **review_trigger:** the CAP v1.0 text becomes available, or any regression gate is implemented.
  If D-GOV-001 is answered first, this question inherits its answer and may close with it.
- **related_findings:** F-GOV-009.

---

## D-GOV-004 — Statistical validity: minimum sample sizes, confidence intervals, calibration bins, and insufficient data

- **status:** `OPEN_DESIGN_QUESTION`
- **spec_evidence:** "Statistical validity: Define minimum sample sizes, confidence intervals,
  calibration-bin rules, and what happens when calibration data is insufficient. **A lack of evidence
  must not automatically produce a passing score.**" — `certification/atlas/R0_SOURCE_PLAN.txt:1135`.
- **code_evidence:** `not found in code` for any CAP/CAE calibration statistic. The repository does
  contain a sample-size discipline elsewhere, and it is directly relevant as a precedent:
  `certification/audit/TIANNARA_RUNTIME_TEST_INVENTORY.md:88-89` records the P9X flake being fixed
  with "N=20 → N=64 gives P ≈ 6.3e-7 (statistically sound; no retries, no masking)" and explicitly
  rejects the alternatives "no retries, never retries". The nearest calibration machinery is
  `tiannara_runtime/lib/tiannara/audit/calibration_runner.ex`, which performs entropy/pressure fault
  injection and never writes back to a decision.
- **counter-example already in the codebase (relevant to the clause quoted in bold):**
  `lib/tiannara/council/constitutional_monitor.ex:51-59` returns
  `aggregate_constitutional_score: 1.0` when **zero** services have reported — absence of evidence
  producing a *perfect* score. The same anti-pattern appears at
  `lib/tiannara/council/rule_engine.ex:65-69` (each unscored principle dimension defaults to `1.0`)
  and at `lib/tiannara/omega/authority_verifier.ex` (no thresholds at all). This is the direct
  codebase expression of the failure mode the plan warns about.
- **options:**
  1. Minimum sample size + confidence interval per gate metric, with an explicit
     `INSUFFICIENT_EVIDENCE` verdict distinct from both PASS and FAIL.
  2. Bayesian treatment where the prior is chosen to be non-passing, so insufficient data cannot
     produce a pass without an explicit decision.
  3. Calibration bins defined on a fixed bin set with a published rule for partially-filled bins.
  4. Statistical validity delegated to the existing statistical-validation documents
     (`STATISTICAL_VALIDATION.md`) rather than redefined inside CAP.
- **review_trigger:** the CAE v1.1 calibration-feedback design becomes available, or any CAP gate
  consumes a sampled metric. Independently, this question should be revisited **immediately** if the
  `:approved` decision in the Council is ever made reachable (F-GOV-006), because the current
  fail-open defaults would then produce a real pass from no evidence.
- **related_findings:** F-GOV-008, F-GOV-006, F-GOV-001.

---

## D-GOV-005 — Fail-closed versus retry: distinguishing an operational failure from a verified negative

- **status:** `OPEN_DESIGN_QUESTION`
- **spec_evidence:** "Fail-closed versus retry: A timeout, unavailable dependency, and a verified
  negative audit result are different outcomes. Operational failures should block authorization, but
  should not be misrepresented as proof that the subject itself failed."
  — `certification/atlas/R0_SOURCE_PLAN.txt:1137`.
- **code_evidence:** the repository already implements **both** halves of this distinction, but in
  different places and with different names, which is itself the reason the question is open:
  - *Operational failure → block, do not blame the subject:* `lib/tiannara/omega/mint_registry.ex:143-144`
    converts any exit into `:registry_unavailable`, and the sink maps it to
    `{:error, :authorization_registry_unavailable}` rather than to a subject failure
    (`lib/tiannara/omega/governed_effect_sink.ex:179-186`);
    `lib/tiannara/council/audit_log.ex:152-153` returns `{:error, :storage_degraded}`.
  - *Verified negative → refuse:* `lib/tiannara/omega/governed_effect_sink.ex:239` (N6 result identity
    mismatch), `:279` (N7 audit failure).
  - *Conflated:* `lib/tiannara/cel/kernel.ex:145-154` converts a raised or foreign constitutional score
    into `ConstitutionalScore.unavailable/1`, and the comment there states the former all-`1.0` default
    "certified failures as perfect" — the fail-open shape this question forbids.
- **options:**
  1. A three-valued outcome type at every gate: `PASS | FAIL | INDETERMINATE`, where INDETERMINATE
     blocks authorization but is never recorded as a subject failure.
  2. Keep the current two-valued API and add a mandatory machine-readable reason class
     (`operational` vs `substantive`) on every refusal.
  3. A retry policy (bounded attempts with backoff) layered on INDETERMINATE, with the retry
     exhaustion state also INDETERMINATE.
  4. Defer: treat the question as answered for the Omega registry chain (which already distinguishes
     them) and only require it for CAP.
- **review_trigger:** the CAP v1.0 text becomes available, or any new gate is added that can fail for
  both operational and substantive reasons. Also reopen if the Council's `:approved` verdict becomes
  reachable (F-GOV-006) — today the fail-open defaults make the question moot only by accident.
- **related_findings:** F-GOV-006, F-GOV-008, F-GOV-005.

---

## D-GOV-006 — Replay guarantees: the boundary between deterministic replay and unreconstructable systems

- **status:** `OPEN_DESIGN_QUESTION`
- **spec_evidence:** "Replay guarantees: Specify the boundary between deterministic replay and
  external systems whose behaviour cannot be reconstructed. Freeze all relevant inputs, policies,
  versions, seeds, and nondeterministic outputs." — `certification/atlas/R0_SOURCE_PLAN.txt:1139`.
  Related Section C row: "Distributed constitutional verification | Verify decisions and signatures
  across nodes | Consensus, partition safety, and identity binding" — `R0_SOURCE_PLAN.txt:249`.
- **code_evidence:** partially present, in pieces, with no boundary declared:
  - `lib/tiannara/council/audit_log.ex:531-556` freezes a chain tip and computes a Merkle root over
    entry hashes — a replay anchor for the audit trail, but with **no located cross-node consumer**
    (`CAP-GOV-012`).
  - `lib/tiannara/os/governance/governance_replay_certificate.ex:62-99` performs a field-by-field
    replay comparison and issues a certificate — but its `manifest_id` is the hardcoded literal
    `"constitution-v13"` (`:89`) and its `sign_certificate/4` (`:248-251`) is an unkeyed SHA-256 over
    public fields.
  - `lib/tiannara/os/governance/replay_auditor.ex:32,115` calls a certificate integrity check.
  - `lib/tiannara/cel/services/workflow_engine.ex` records degraded/retry state
    (`workflow_engine_degradation_test.exs`, `workflow_engine_retry_test.exs` exist).
  - `lib/tiannara/omega/governed_effect_sink.ex:22-32` defines the five compared effect identities —
    a freezing mechanism for a single effect, not a system boundary.
- **options:**
  1. Declare an explicit replayable subset (pure functions over frozen inputs) and an explicit
     non-replayable subset (external effects), with contracts stating which gates require which.
  2. Require a captured input bundle per decision (inputs, policy version, seeds, nondeterministic
     outputs) with a content hash, making the bundle the replay unit.
  3. Restrict CAP replay guarantees to the governance decision layer only, and explicitly disclaim
     replay of effects.
  4. Require a certificate that names the replay mode (deterministic / captured / unreconstructable)
     so a consumer can tell which guarantee it holds.
- **review_trigger:** the CAP v1.0 text becomes available, **or** any distributed verification feature
  is built on `AuditLog.merkle_root/0` (currently consumer-less), **or** a replay certificate is
  cited as certification evidence anywhere.
- **related_findings:** F-GOV-010, F-GOV-012, F-GOV-008.

---

## D-GOV-007 — Distributed arbitration: consensus vs eventual consistency vs last-writer-wins vs constitutional safety

- **status:** `OPEN_DESIGN_QUESTION`
- **spec_evidence:** "Distributed arbitration: Revisit the interaction between consensus, eventual
  consistency, last-writer-wins, and constitutional safety. These choices cannot be assumed to
  provide the same guarantees." — `certification/atlas/R0_SOURCE_PLAN.txt:1141`. Section C row:
  "Consensus, partition safety, and identity binding" — `R0_SOURCE_PLAN.txt:249`.
- **code_evidence:** one implementation exists and it contradicts its own stated guarantee:
  `tiannara_runtime/lib/tiannara/phase14/federation_gateway.ex:6` documents
  "Enforces Byzantine fault tolerance: Q ≥ ⌈2/3 N⌉" while `:11` defines `@quorum_fraction 0.667` and
  `:34`, `:48` compute `trunc(total * 0.667)` — floor, not ceil. For N=1 the required quorum is **0**;
  for N=2 it is 1 of 2. `:44-56` shows votes carry no instance identity and no deduplication, so a
  single voter can reach quorum by voting repeatedly. `:62-66` publishes `approved: false` on timeout
  (a timeout is treated as a negative result rather than as an absence of result — a concrete instance
  of the D-GOV-005 conflation).
  Separately, `certification/audit/PHASE_5F_STATUS_CORRECTION.md:129-136` (C-07) records that the CRA
  supervisor does not exist, that the 5 CRA GenServers run only in tests, and that partitions,
  cross-node authority transfer, dedup, snapshot consistency and budget reconciliation are **entirely
  absent**.
- **options:**
  1. Consensus (quorum-based) for all constitutional decisions, with an explicit identity binding per
     voter and a strict duplicate-vote rejection.
  2. Eventual consistency with last-writer-wins for *state*, reserved to non-constitutional data, and
     consensus reserved for *authorizations*.
  3. Partition-tolerant design with a declared safety side (e.g. fail-closed on partition for
     authorization paths, with an explicit local-only mode).
  4. Single-node-only constitutional authority, with distributed verification (not distributed
     decision) as the cross-node requirement.
- **review_trigger:** any capability is proposed that must run on more than one node; or the Phase 14
  federation gateway is wired into a supervision tree; or C-07's external scope is scheduled. Also
  reopen if `AuditLog.merkle_root/0` gains a consumer — that would be the first cross-node
  verification path and would need a stated consistency model.
- **related_findings:** F-GOV-015, F-GOV-012, F-GOV-005.

---

## D-GOV-008 — Certificate binding: subject version, policies, evidence set, gate results, validity period

- **status:** `OPEN_DESIGN_QUESTION`
- **spec_evidence:** "Certificate binding: Ensure a certificate is bound to the exact subject version,
  applicable policies, evidence set, gate results, and validity period. **A valid signature alone does
  not establish authorization for a different artifact.**" — `R0_SOURCE_PLAN.txt:1143`. Section C row:
  "Audit Certificates | Record the result and scope of constitutional authorization | Signature
  verification, expiry, and subject binding" — `R0_SOURCE_PLAN.txt:233`.
- **code_evidence:** the binding fields do not exist in any reachable certificate:
  - `lib/tiannara/certification/certificate.ex:15-16` — `defstruct [:subsystem, :verdict,
    :invariant_verdict, :failed_invariants, :functional_gates, :issued_at, :reason]`. No signature, no
    expiry, no subject version. (Its *gate* logic is sound and tested by
    `test/tiannara/constitution/invariant_gate_test.exs`.)
  - `lib/tiannara/os/governance/governance_replay_certificate.ex:39` + `:248-251` — the only field
    named `signature`; `sign_certificate/4` is `:crypto.hash(:sha256, "#{cert_id}:#{ledger_hash}:
    #{state_fingerprint}:#{timestamp}")`, an **unkeyed hash over public fields**, so anyone who can read
    the struct can recompute a valid signature. `:89` hardcodes `manifest_id: "constitution-v13"`
    regardless of the manifest actually replayed.
  - `tiannara_runtime/.../world_model/ontology/certificate.ex:62` — `model_version` is the **only**
    version binding in the entire repository.
  - `lib/tiannara/omega/machine_authorization.ex:203-214` — `content_hash/1` binds decision,
    decision_type, granted_at, ttl and council_decision_ref, and the registry-anchored
    `council_decision_ref` comparison at bind is what actually prevents rewriting a grant. This is the
    closest existing answer to the subject-binding requirement, and it is **not a certificate**.
  - `forward_provenance/lib/certificate_lifecycle.ex:1-40` — the only lifecycle-complete certificate
    implementation (VALID / SUSPENDED / REVOKED / UNVERIFIABLE / SUPERSEDED, forbidden verbs fail
    closed, `request_signature` over the transition request), in a separate path dependency
    (`mix.exs:67`) imported by **zero** modules in `lib/` or `tiannara_runtime/lib/`.
- **options:**
  1. Extend the existing `forward_provenance` certificate schema into the main application (it already
    has lifecycle, signature and identity authority) rather than designing a third certificate model.
  2. Define a new CAP certificate schema with an explicit binding tuple
     `(subject_version, policy_set_hash, evidence_set_hash, gate_results, valid_from, valid_until)` and
     sign it with a real key.
  3. Reuse the `MachineAuthorization` `content_hash` + registry-anchored `council_decision_ref`
     mechanism as the binding primitive for certificates.
  4. Make the certificate a pure projection of an existing registry record rather than a
     independently signed artifact.
- **review_trigger:** the CAP v1.0 text becomes available, **or** any `tiannara_audit` report is cited
  as certification evidence (F-GOV-011 currently makes such citation unsound), **or** the
   `forward_provenance` project is proposed for promotion into the main application.
- **related_findings:** F-GOV-010, F-GOV-011, F-GOV-005.

---

## D-GOV-009 — Policy authority: who may amend `rules.md`, which version governs a pending audit, and how human approval is enforced

- **status:** `OPEN_DESIGN_QUESTION`
- **spec_evidence:** "Policy authority: Define exactly who can amend `rules.md`, which versions govern
  pending audits, and how human approval is enforced." — `R0_SOURCE_PLAN.txt:1145`. Section C row:
  "Constitutional Engineering Instructions (`rules.md`) | Define non-negotiable system constraints |
  One authoritative, versioned policy source" — `R0_SOURCE_PLAN.txt:221`; and "Human Authority /
  approval controls | Retain human authority over sensitive changes and self-improvement | Cannot be
  bypassed by downstream components" — `R0_SOURCE_PLAN.txt:237`.
- **code_evidence:**
  - `rules.md` is a 225-line root prose document with **no machine reader**: repo-wide grep for
    `rules.md` in `*.ex` returns 19 hits, all moduledoc prose (e.g.
    `lib/tiannara/discovery/topics.ex:9`, `lib/tiannara/cel/workflow/workflow.ex:15`,
    `lib/tiannara/council/audit_log.ex:26`). There is no `File.read` / `:file.read` / `Code.eval_file`
    consumer and no test that loads it. The de facto authority is
    `lib/tiannara/council/constitution.ex` (`Constitution.v1/0`) persisted by
    `lib/tiannara/council/constitution_repository.ex` (DETS `constitution_repository.dets`), plus the
    six policies in `lib/tiannara/council/policy_registry.ex:75-131`.
  - *Which version governs a pending audit* — `not found in code`: no certificate, authorization or
    audit record carries the constitution version that governed the decision at the time it was made.
    `lib/tiannara/council/machine_authorization.ex:216-221` hashes the **decision payload** into
    `council_decision_ref`, which pins the decision but not the governing policy version.
  - *How human approval is enforced* — the record exists, the effect does not:
    `lib/tiannara/council/human_approval_queue.ex:51-64` writes `status: :approved` into history and
    removes the request, and **no code path resumes a `:requires_human` decision**. Separately,
    `lib/tiannara/council/amendment_engine.ex:251-253` (`apply_amendment/2`) only bumps a version
    string and discards `proposed_changes`; `:45` and `:155-158` write the result into the engine's
    private state, not into `ConstitutionRepository`, so `Council.constitution/0` (`council.ex:10`) is
    unaffected by an approved amendment; `:142-160` accepts a bare `human_id`.
  - *Which evaluator owns policy* — two unreconciled evaluators coexist:
    `lib/tiannara/council/policy_registry.ex:15-21` (six policies, condition vocabulary
    `:risk_above / :touches_invariant / :actor_is / :mission_impact / :resource_cost_above`) and
    `lib/tiannara/cel/policy/runtime_policy.ex` + `lib/tiannara/cel/services/runtime_policy_engine.ex`.
  - *Who may amend* — `lib/tiannara/council/rule_engine.ex:245-246` hard-blocks
    `decision_type == :constitutional_amendment` as the `:no_self_amendment` invariant, but on the real
    path the `self_modification` policy (`policy_registry.ex:86-94`, action `:require_simulation`)
    matches first and `score_auth/3` (`council.ex:134-143`) never overrides the decision.
- **options:**
  1. `rules.md` becomes the normative source: a versioned policy document from which
     `Council.Constitution` and `PolicyRegistry` are generated (or checked) by a test.
  2. `rules.md` is demoted to prose commentary and the Elixir structs become the normative source,
     with the document explicitly linked from `Council.Constitution` and marked non-normative.
  3. A dual-source model with `rules.md` as the intent document and a machine-readable policy set
     beneath it, with an explicit precedence rule.
  4. A single canonical policy evaluator (Council or CEL) with the other routed through it and the
     question of which one closes together.
- **review_trigger:** any constitutional amendment is proposed; or the `forward_provenance` certificate
  is promoted; or a second policy evaluator is added; or a decision record needs to state which
  constitution version governed it. This question is also the natural closure point for
  F-GOV-002, F-GOV-003, F-GOV-004, F-GOV-018 and F-GOV-019.
- **related_findings:** F-GOV-002, F-GOV-003, F-GOV-004, F-GOV-018, F-GOV-019, F-GOV-020.

---

## D-GOV-010 — The five-minute audit timeout: which subject classes it applies to, and how it is tested under load

- **status:** `OPEN_DESIGN_QUESTION`
- **spec_evidence:** "Performance requirements: Establish whether the five-minute audit timeout applies
  to every subject class or only a defined subset, and test that requirement under realistic loads."
  — `R0_SOURCE_PLAN.txt:1147`.
- **code_evidence:** `not found in code` for a constitutional-audit timeout. Repo-wide search for
  `300_000` / `:timer.minutes(5)` returns no audit-timeout constant. The nearest analogues, all
  distinct from a constitutional audit, are:
  - `lib/tiannara/os/governance/validation/campaign_executor.ex:72` —
    `timeout: 300_000, # 5 minute timeout per campaign` (a **validation campaign**, not an audit);
  - `lib/tiannara/council/audit_log.ex:40` — `@merkle_interval :timer.minutes(5)` (a Merkle
    computation interval, not a timeout);
  - `lib/tiannara/cel/kernel.ex:11` — `GenServer.call(__MODULE__, :boot, 120_000)` (the CEL boot
    timeout, 2 minutes);
  - `lib/tiannara/validation_campaigns.ex:16` and `lib/tiannara/world/evidence_validator.ex:61` —
    5-minute campaign/validation timeouts.
  There is no load test anywhere in the repository that measures audit latency, and no subject-class
  taxonomy exists to which the timeout could be scoped.
- **options:**
  1. Apply the five-minute timeout to every subject class, with the rule stated in CAP v1.0 and a
     load test that asserts the bound holds.
  2. Define a subject-class taxonomy (e.g. fast-path / standard / deferred) with per-class timeouts,
     the five-minute bound applying to the slowest class.
  3. Make the timeout a property of the gate rather than the audit (per-gate budget summing to a
     total), so that a slow gate is visible rather than masked.
  4. Separate the *decision* timeout from the *effect* timeout — a decision may complete quickly while
     an effect is slow, and conflating them is what makes the current 5-minute constants ambiguous.
- **review_trigger:** the CAP v1.0 text becomes available, or any audit path is added with its own
  timeout constant, or the first load measurement of audit latency is taken. Also reopen if a subject
  class is introduced whose audit cost could exceed five minutes (for example anything touching the
  30 runtime certification campaigns).
- **related_findings:** F-GOV-021, F-GOV-009.

---

## Appendix A — Question-to-finding cross index

| Decision | Primary findings | Primary capability rows |
|---|---|---|
| D-GOV-001 | F-GOV-009 | CAP-GOV-006, CAP-GOV-106 |
| D-GOV-002 | F-GOV-005, F-GOV-006, F-GOV-009 | CAP-GOV-005, CAP-GOV-006, CAP-GOV-113 |
| D-GOV-003 | F-GOV-009 | CAP-GOV-006 |
| D-GOV-004 | F-GOV-006, F-GOV-008 | CAP-GOV-002, CAP-GOV-003, CAP-GOV-004 |
| D-GOV-005 | F-GOV-005, F-GOV-006, F-GOV-008 | CAP-GOV-005, CAP-GOV-101 |
| D-GOV-006 | F-GOV-010, F-GOV-012 | CAP-GOV-007, CAP-GOV-012, CAP-GOV-015 |
| D-GOV-007 | F-GOV-015, F-GOV-012, F-GOV-005 | CAP-GOV-015 |
| D-GOV-008 | F-GOV-010, F-GOV-011, F-GOV-005 | CAP-GOV-007, CAP-GOV-105 |
| D-GOV-009 | F-GOV-002, F-GOV-003, F-GOV-004, F-GOV-018, F-GOV-019, F-GOV-020 | CAP-GOV-001, CAP-GOV-009, CAP-GOV-109, CAP-GOV-110, CAP-GOV-117 |
| D-GOV-010 | F-GOV-021, F-GOV-009 | CAP-GOV-006, CAP-GOV-106 |

## Appendix B — Precedence note

`R0_SOURCE_PLAN.txt:1151` states: *"Resolve these design questions in the architecture decision
register. Do not add further layers of constitutional machinery until the existing design has been
reconciled with actual code and its execution paths."*

That ordering constrains the remediation sequence this register implies:

1. **Reconciliation first** (Phase R1) — decide which existing modules are canonical (D-GOV-009) and
   which competing gate families are in scope (D-GOV-001, D-GOV-003).
2. **Defect repair on the existing governance path** — the findings F-GOV-003 through F-GOV-007 are
   defects in code that *already exists* and are not contingent on any decision above. They are
   actionable independently and should not wait on the CAP v1.0 text.
3. **Decision closure** (D-GOV-001 … D-GOV-010) — required before any new constitutional machinery is
   added.

Note the asymmetry this creates: eight of the ten questions cannot be answered from in-repo evidence
today because the CAE and CAP specification texts are absent, while the ten highest-severity findings
are all answerable and fixable from the code that is present. This register deliberately does **not**
use the absence of the specifications as a reason to defer the defect repair.
