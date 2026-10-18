# Stage 5 Outcome Vocabulary — Design Document

**Status**: DESIGN ONLY — no code changes authorized by this document.
**Date**: 2026-10-18
**Authority**: Ordered by the operator as step 2 of the Stage 5 audit phase:
trace gates (done, scan section D) → **this vocabulary design** → contract tests
before any behavior change → then (only with confirmation) behavior change.

This document defines the five-atom outcome vocabulary for
`TiannaraOS.Stage5CivilizationAdaptation` / `TiannaraOS.CivilizationAdaptationResult`,
how each existing gate maps to exactly one outcome, how incomplete history and
missing rollback stay blocking without collapsing to a single failure flag, and
the contract tests that must lock current behavior **before** any implementation.

---

## 0. Standing constraints (non-negotiable)

1. The `stage_history >= 7` count gate (`stage5_civilization_adaptation.ex:149`)
   is **never loosened**. It may stay or tighten; never relax.
2. No stage rewiring: the 7-phase pipeline (`:adaptations_collected` → …
   → `:recorded`) and its transition table (`civilization_adaptation_result.ex:226-235`)
   stay as-is.
3. No Stage 6 certification claims may be derived from anything here.
4. Nothing in this vocabulary may upgrade pedigree: synthetic-labeled inputs
   (`evidence_source: :synthetic`) can never contribute to `:rollout_authorized`.
5. The five outcomes must never be collapsed back into a single boolean or a
   single `status: :failed` sentinel.
6. C11 (effect-sink ledger-only) stays OPEN and untouched.

---

## 1. Ground truth: how Stage 5 reports outcomes today

### 1.1 The fields involved

`CivilizationAdaptationResult` (`civilization_adaptation_result.ex:85-131`) carries:

- `:status` — **double-duty defect**: nominally "status", but `advance_stage/2`
  (`:225-254`) uses it as the stage cursor (`current_stage = result.status`,
  then `%{result | status: new_stage}`). Observed values:
  - `:pending` — fresh result (`new/2`, `:198`)
  - `:adaptations_collected` … `:recorded` — cursor after each phase; success
    path ends at **`:recorded`**
  - `:failed` — set only by `create_empty_result/2`
    (`stage5_civilization_adaptation.ex:621-629`), which overwrites the cursor
    from `:pending` → `:failed`. `:failed` is not a member of the transition
    table, so the stage machine is dead after a gate rejection (nothing
    advances afterwards — but the field can no longer answer "which stage is
    this result in?").
- `:failure_reason` — `nil` on success; `:no_valid_adaptations` on gate
  rejection. Only ever this one atom.
- `:civilization_decision` — six-valued: `:universal_adoption`,
  `:selective_adoption`, `:experimental_expansion`, `:further_validation`,
  `:reject`, `:preserve_diversity` (decided in
  `stage5_civilization_adaptation.ex:422-497`), plus `:reject` again (with
  different rationale) on the empty-result path (`:622`).
- `:constitutional_compliance` — map with `:violations` and `:is_compliant`,
  computed by `validate_constitutional_compliance/1` (`:443-486`) **after** the
  pipeline already reached `:recorded`. Violations are logged
  (`stage5_civilization_adaptation.ex:128-132`) but change nothing: they do
  not flip status, decision, or any other field.

### 1.2 The two terminal shapes produced today

| Shape | Trigger | status | failure_reason | civilization_decision |
|---|---|---|---|---|
| **Gate rejection** | 0 inputs survive `validate_adaptations/1` (`:146-168`) | `:failed` | `:no_valid_adaptations` | `:reject` |
| **Analyzed** | ≥1 input survives; 7 phases run | `:recorded` (cursor) | `nil` | one of the six decision atoms |

`validate_adaptations/1` applies four AND-ed checks per input:
(a) `length(stage_history) >= 7` — **count only, names never inspected**;
(b) `constitutional_compliance.is_compliant == true`;
(c) `rollback_available == true`;
(d) `simulation_results.evidence_source ∈ [:evidence_backed, :synthetic]`
(unlabeled → rejected; **synthetic is accepted**, pedigree is tracked separately
via `evidence_lineage.weakest_input_source`, `:179-201`).

Individual rejection reasons are discarded by `Enum.filter` — the result only
knows "0 survived", never *why* any input died.

### 1.3 What is wrong with this

1. **Collapse**: gate rejection (no evidence to analyze) and analyzer decision
   to reject (evidence analyzed, spread refused) both present as failure-ish
   signals; approval-level and analysis-level conclusions are distinguishable
   only by parsing `civilization_decision` against an undocumented six-atom set;
   there is no representation at all for "rollout authorized" vs "approved but
   not authorized".
2. **The `status` field cannot carry an outcome** because it is the stage
   cursor. Any attempt to store `:failed`-style outcomes in it destroys
   lifecycle state (and success currently reports `:recorded`, which reads as
   neither "ok" nor "failed" to an outside consumer).
3. **Compliance is advisory**: `is_compliant: false` results leave the decision
   intact. Check 4 (`prediction_history_required`) can fire on genuine success
   (prediction history is `nil` when no input carried prediction assessments —
   `stage5_civilization_adaptation.ex:607-611`), so "violated" and "misbehaved"
   are conflated.
4. **Fabricated inputs can pass the count gate**: arbitrary atoms
   `:"stage_1".."stage_8"` satisfy `>= 7` (lineage fixture,
   `stage5_evidence_lineage_test.exs:13-16`; demo script
   `run_stage5_civilization_adaptation.exs:114-133`; runner simulator
   `recursive_civilization_runner.ex:909-928`) while a genuine Stage 4 canonical
   lifecycle (5 entries, ending `:decision_recorded`) is blocked. Named-stage
   evidence exists in the data but is never consulted (scan section D).

---

## 2. The vocabulary

Five atoms, stored in a **new field `:outcome`** on
`CivilizationAdaptationResult`. `:status` (cursor), `:failure_reason`,
`:civilization_decision`, and `:constitutional_compliance` are all **kept
unchanged** for backward compatibility; `:outcome` is additive and becomes the
only field consumers consult for eligibility.

```
:evidence_insufficient   :analysis_possible       :adaptation_rejected
:adaptation_approved     :rollout_authorized
```

### 2.1 Definitions

**`:evidence_insufficient`** — The analyzer could not legitimately analyze:
zero inputs survived the analysis gates (including the empty-input case).
*Meaning*: no claim about the adaptations themselves — only about the evidence
supplied. `failure_reason` retains `:no_valid_adaptations` detail. Never
conflated with an analyzer verdict of rejection: nothing was rejected on the
merits, because nothing was examined.

**`:analysis_possible`** — Gates passed, the 7-phase analysis ran to completion,
but the conclusion is neither approval nor rejection: `civilization_decision ∈
{:further_validation, :preserve_diversity}`. *Meaning*: "we have enough evidence
to analyze, we analyzed, and the honest answer is 'not yet decidable' or 'keep
diversity'". This outcome must never be reported as failure.

**`:adaptation_rejected`** — Analysis ran; the analyzer concluded the
adaptations must not spread: `civilization_decision == :reject` on the analyzed
path. *Meaning*: a positive, evidence-based refusal. Rejected ≠ failed, and
rejected ≠ adopted: a `:adaptation_rejected` result carries the full analysis
(families, comparisons, transferability) that justified the refusal.

**`:adaptation_approved`** — Analysis ran; the analyzer approved spreading:
`civilization_decision ∈ {:universal_adoption, :selective_adoption,
:experimental_expansion}`. *Meaning*: approval **at analysis level only**. It
does **not** authorize deployment, does not bypass rollout gates, and does not
imply the compliance checks passed. Approval is a conclusion; authorization is
a separate state.

**`:rollout_authorized`** — Approval **plus** rollout tier satisfied (§4).
Reserved state: **unreachable with any input producible today** (no genuine
pilot records exist — scan E.2 — and synthetic inputs are excluded by §0.4).
It exists so that the vocabulary never has to lie later; until real pilots and
governance review records exist, every code path fails closed to
`:adaptation_approved` at most.

### 2.2 Never-collapse rule

- No field may encode these five as a boolean or as `status: :failed`.
- `:evidence_insufficient` and `:adaptation_rejected` are distinct states of
  the world and must remain separately testable.
- `:adaptation_approved` and `:rollout_authorized` are distinct: approval is
  the analyzer's conclusion; authorization is an eligibility state.
- `:outcome` defaults to `nil` (not computed yet); `nil` is never printed as
  any of the five, and consumers must treat `nil` as "no outcome — not
  eligible for anything".

### 2.3 Derivation table (S5-1 implementation spec)

Evaluated at the end of `execute_stage_5/3` and inside `create_empty_result/2`:

| Condition (in order) | `:outcome` |
|---|---|
| 0 inputs survived `validate_adaptations/1` (incl. empty input list) | `:evidence_insufficient` |
| Analysis completed AND `civilization_decision == :reject` | `:adaptation_rejected` |
| Analysis completed AND decision ∈ adoption set AND **all** supporting inputs pass rollout tier (§4) AND `constitutional_compliance.violations == []` | `:rollout_authorized` |
| Analysis completed AND decision ∈ adoption set (anything else) | `:adaptation_approved` |
| Analysis completed AND decision ∈ `{:further_validation, :preserve_diversity}` | `:analysis_possible` |

Notes:
- Compliance violations do **not** affect `:adaptation_approved` /
  `:adaptation_rejected` / `:analysis_possible` — they remain fully visible in
  the existing `:constitutional_compliance` field, and they are **hard-blocking
  only for `:rollout_authorized`** (zero-violation requirement). Rationale:
  check 4 can fire on otherwise-genuine analysis (§1.3-3), so folding violations
  into approval would make approval unreachable for honest inputs; blocking
  rollout on violations puts the strictness exactly where deployment risk lives.
  *(OQ-1 resolved per §7: violations block rollout only; stricter variants
  documented there as the rejected alternative.)*
- The adoption set is exactly `{:universal_adoption, :selective_adoption,
  :experimental_expansion}` — same set already used by compliance check 2
  (`:454`), so approval vocabulary and rollout-plan requirement cannot drift.
- The empty-result path sets `:outcome` to `:evidence_insufficient` **in
  addition to** (not instead of) `status: :failed, failure_reason:
  :no_valid_adaptations`.

---

## 3. Gate → outcome mapping (scan section D, findings 1–4)

| Existing gate | Today | Maps to | Collapse avoided |
|---|---|---|---|
| `length(stage_history) >= 7` (count-only, `:149`) | silently filters | failure of this check (with the other three) → `:evidence_insufficient` | never `:adaptation_rejected` — the input was never evaluated on merits |
| `constitutional_compliance.is_compliant == true` | silently filters | same — `:evidence_insufficient` | an input failing compliance is *unusable evidence*, not a rejected adaptation |
| `rollback_available == true` | silently filters | same — `:evidence_insufficient` | missing rollback stays blocking forever (§0.1-analog: stays AND-ed, never optional) |
| `evidence_source` labeled | silently filters; synthetic accepted | unlabeled → `:evidence_insufficient`; synthetic accepted for analysis but excluded from rollout tier (§0.4) | synthetic never upgrades to authorization |
| Analyzer decision (6 atoms) | stored in `civilization_decision` only | split into `:adaptation_rejected` / `:adaptation_approved` / `:analysis_possible` (§2.3) | analysis-level outcomes separated from evidence-level outcomes |
| Civilization compliance violations (`:443-486`) | logged, ignored | block `:rollout_authorized` only; otherwise visible in own field | "violation recorded" ≠ "failed" |
| Named-stage evidence (never inspected — scan D.2) | unused | rollout tier only (§4); **count gate untouched** | incomplete history can never authorize rollout, yet genuine short history stays excluded from *nothing else* (it was already excluded from analysis by the count gate — unchanged) |

**Incompleteness is handled by tiering, not by loosening**: inputs that fail the
count gate are excluded from analysis exactly as today (gate unchanged); inputs
that pass analysis but lack named-stage evidence are capped at
`:adaptation_approved`. Nothing incomplete ever reaches `:rollout_authorized`.

---

## 4. Tier model (eligibility separation)

Three tiers, strictly cumulative. A result's `:outcome` is capped by the tier
its evidence supports — never above.

**Tier A — Analysis** (existing gate, byte-for-byte unchanged):
`length(stage_history) >= 7` AND compliance-true AND rollback-available AND
evidence_source labeled.

**Tier B — Approval**: Tier A satisfied AND the analyzed decision is in the
adoption set. Produces `:adaptation_approved` (or `:rollout_authorized` if
Tier C also holds).

**Tier C — Rollout authorization** (all required, additive checks; today
unreachable — §2.1):
1. Every supporting input is Tier B-eligible;
2. Every supporting input carries named-stage evidence in `stage_history`,
   including at minimum `:piloted` **and** `:governance_reviewed`
   (named stages inspected — this is the deferred scan D.2 separation,
   `EXECUTION_CONTRACTS.md:680-699`, "pending product confirmation" there;
   **OQ-2 signed off per §7, implemented in S5-2 `5bb0990e`** — self-reported
   claims alone never authorize; authoritative verification required);
3. Every supporting input has `evidence_source == :evidence_backed`
   (excludes synthetic — §0.4);
4. `rollback_available == true` for every supporting input (already implied by
   Tier A, restated because rollout is where it matters);
5. `constitutional_compliance.violations == []` on the civilization result.

Tier C is **tightening only**: it can only ever *deny* `:rollout_authorized`
(which nothing can currently produce anyway), so implementing it cannot loosen
any existing behavior.

---

## 5. Data model changes (S5-1, additive)

1. New field `:outcome` in `defstruct` (`civilization_adaptation_result.ex:85`)
   and `@type t` — type `nil | :evidence_insufficient | :analysis_possible |
   :adaptation_rejected | :adaptation_approved | :rollout_authorized`,
   default `nil` in `new/2`.
2. New field `:gate_rejections` (default `[]`): per-input rejection detail
   `[%{institution_id: id, adaptation_result_id: id, reasons:
   [:lifecycle_count | :not_compliant | :no_rollback | :unlabeled_evidence_source]}]`
   — closes the silent-`Enum.filter` observability gap (§1.3-4) without
   changing acceptance decisions. The four reasons mirror checks (a)–(d)
   exactly; no new criteria are smuggled in.
3. `status` stays the stage cursor (`:pending` → `:recorded` on success,
   `:failed` on gate rejection — existing behavior, locked by contract tests).
   Documented in the struct `@moduledoc` as what it actually is. **No consumer
   may read `status` for eligibility after S5-1 — eligibility reads `:outcome`.**
4. `failure_reason` unchanged (`:no_valid_adaptations`); it stays the
   machine-readable detail under `:evidence_insufficient`.
5. Runner persistence (`recursive_civilization_runner.ex`, stage5 evidence
   writer — exact site located during S5-1) must persist `outcome` and
   `gate_rejections` alongside the already-persisted `status` /
   `failure_reason` / `civilization_decision`.
6. The semantic event `:civilization_adaptation_completed`
   (`stage5_civilization_adaptation.ex`) gains `outcome:` and
   `compliance_violation_rules:` in its metadata. **S5-1 implementation note:**
   the event is emitted *after* outcome derivation (moved from its original
   position) so it can carry `outcome:` — safe because nothing outside this
   module/docs consumes `:civilization_adaptation_completed` (verified during
   S5-1). The blocked path gains a `:civilization_adaptation_blocked` event
   with `outcome:`, `failure_reason:`, and `gate_rejection_count:`. Existing
   metadata keys (decision, generation, institutions_evaluated) untouched.

---

## 6. Phased plan

### Phase S5-0 — Contract tests first (no behavior change)

New file `test/tiannara/os/stage5_outcome_contract_test.exs`, locking **today's**
behavior so S5-1/S5-2 cannot silently weaken it:

| # | Asserts (current behavior) |
|---|---|
| CT-1 | Count boundary: 6-entry `stage_history` input → gate rejection (`status: :failed`, `failure_reason: :no_valid_adaptations`, `civilization_decision: :reject`); 7-entry input (arbitrary stage names — count-only proof) with all other checks green → analysis runs |
| CT-2 | `rollback_available: false` → gate rejection (missing rollback stays blocking) |
| CT-3 | `constitutional_compliance.is_compliant != true` → gate rejection |
| CT-4 | Unlabeled `evidence_source` → gate rejection; `:synthetic` labeled → accepted (locked as-is — synthetic acceptance is existing behavior, its restriction happens at Tier C, not here) |
| CT-5 | Success path ends `status: :recorded` (cursor semantics), `lifecycle_events` contains all 8 required stages, `failure_reason == nil` |
| CT-6 | Rejected ≠ adopted: decision `:reject` vs `:universal_adoption` produce distinct `civilization_decision`, and the reject-shaped rollout plan has `recommended_institutions: []` while adoption has ≥1 |
| CT-7 | No rollout-authorization claim exists pre-change: struct has no `:outcome` field yet (this assertion is *replaced* in S5-1 by "outcome never `:rollout_authorized` for any fixture"), and nothing in the result claims deployment authorization |
| CT-8 | Blocked-result shape: `civilization_decision == :reject`, `rollout_plan == nil`, `supporting_institutions == nil`, `evidence_lineage == nil`. The persistence half of this contract is already locked by `recursive_civilization_runner_test.exs` ("genuine stage5 … honest blocked result": persisted `status: "failed"`, `failure_reason: "no_valid_adaptations"`, `certification_claim: "none"`), so the contract file asserts the engine side and cites the runner test |
| CT-9 | Compliance violations do not flip `status`/`civilization_decision` today (e.g. inputs with no prediction assessments → `prediction_history_required` violation recorded while decision stands) |
| CT-10 | Genuine Stage 4-shaped input (5 entries ending `:decision_recorded`) is rejected by the count gate — documents the *current* blocking behavior that §4 Tier C must not "fix" by loosening |

Run: full suite green; commit as `test(stage5): lock current gate/outcome behavior (S5-0 contract tests)`.

### Phase S5-1 — Additive vocabulary — **IMPLEMENTED in `713d1de3`** (2026-10-18)

OQ-1 approved with the §7 semantics. Implementation notes:

- `validate_adaptations/1` → `classify_adaptations/1` returning
  `{valid, gate_rejections}`. Acceptance logic byte-identical (four AND-ed
  checks, count `>= 7` unchanged); reasons recorded per rejected input in
  fixed order `[:lifecycle_count, :not_compliant, :no_rollback,
  :unlabeled_evidence_source]`.
- `derive_outcome/3` (private): decision `:reject` → `:adaptation_rejected`;
  adoption decisions (universal/selective/experimental) → `:adaptation_approved`;
  `:further_validation`/`:preserve_diversity`/unrecognized → `:analysis_possible`;
  blocked path → `:evidence_insufficient`.
- **The `:rollout_authorized` row of §2.3 is deliberately not yet code**: an
  S5-1 draft `verify_rollout_tier/1` was proven dead by the type checker (its
  `:ok` branch unreachable with no rollout path) and was removed rather than
  shipped. The OQ-1/OQ-2 contract lives in `derive_outcome/3` header comments;
  S5-2 implements tier verification for real and restores the branch. §2.3
  remains the target spec.
- CT-7 replaced by the permanent invariant:

- **CT-7′**: for every constructible fixture, `outcome ∈ {nil} ∪ §2.1 set`,
  and `outcome == :rollout_authorized` is produced by **no** fixture (fails
  closed); `:evidence_insufficient` ⇔ `status == :failed`; analyzed shapes get
  exactly one of the other four per §2.3.

Plus mapping tests (CT-11): the four E2E-reachable decisions → their §2.3
outcome (`:preserve_diversity`/`:experimental_expansion` are unreachable E2E —
family success rates are only 0.0 or 1.0 by construction — covered by the
fallback branch); synthetic-only supporting set with adoption decision → capped
at `:adaptation_approved`; adoption decision with a compliance violation →
stays `:adaptation_approved` (CT-12: violations never cap analysis/approval,
and remain recorded); gate-rejection attribution in fixed order (CT-13).
Runner persists `outcome`/`gate_rejections` via explicit `Map.get` defaults
(older persisted records stay compatible). Verified: contract 26/26, lineage
5/5, runner 32/32, full recompile adds no typing violations in touched files.

### Phase S5-2 — Tier C named-stage checks — **IMPLEMENTED in `5bb0990e`** (operator GO, OQ-2 approved per §7)

Implementation notes:

- `Stage5CivilizationAdaptation.verify_rollout_tier/3` implements §4's
  Tier C as a fixed fail-closed check chain (first failure wins): named-stage
  claims → rollback → evidence-backed → zero violations (OQ-1) → provenance
  lineage present → **authoritative registry verification** (record exists
  per supporting input; record `stages` include `:piloted` AND
  `:governance_reviewed`; record `evidence_source == :evidence_backed`;
  record `verified_at` fresh — missing/future-dated/older-than-window all
  fail closed as stale).
- New module `TiannaraOS.Stage5GovernanceRegistry` is the authoritative
  source boundary: it currently returns
  `{:error, :authoritative_records_unavailable}` because no authoritative
  pilot/governance store exists (scan: no pilot has ever run; Stage 4
  appends `:governance_reviewed` unconditionally). Per the operator ruling,
  missing authoritative evidence yields an **explicit blocked tier** —
  outcome capped at `:adaptation_approved` with the denial reason recorded
  in the completed event (`rollout_tier_status: :denied`,
  `rollout_tier_reason:`) — never a guessed tier or a relaxed gate.
- Derivation: adoption decisions now consult Tier C — `:authorized` →
  `:rollout_authorized`; any denial → `:adaptation_approved`. All other
  outcomes unchanged. Count gate byte-identical.
- Tests: CT-14 (forged tier claims: absent claims / present-but-unverified /
  production fail-closed E2E), CT-15 (missing rollback), CT-16 (stale
  provenance: old, future-dated, missing lineage), CT-17 (unauthorized:
  missing `:governance_reviewed` record, inconsistent synthetic record,
  synthetic input denied pre-registry), CT-18 (positive wiring via injected
  registry → E2E `:rollout_authorized`; violations still cap at approval
  with `:compliance_violations` recorded). Contract file: 39 tests green;
  lineage 5/5; runner 32/32; zero new typing violations.

### Phase S5-3 — Stage 6 evidence review → already done (scan); C11 stays OPEN.

---

## 7. Open questions — OQ-1/OQ-2 RESOLVED (operator sign-off 2026-10-18)

- **OQ-1 — violation strictness: APPROVED as proposed** — "violations block
  rollout only" (§2.3), with these operator semantics (implemented in S5-1,
  `713d1de3`):
  - `:analysis_possible` remains available when its existing evidence and
    analysis gates pass, even with violations present.
  - `:adaptation_approved` remains available when its existing approval gates
    pass, even with violations present.
  - `:rollout_authorized` additionally requires zero blocking compliance
    violations (plus every existing rollout gate; S5-2).
  - Violations remain explicitly recorded (`:constitutional_compliance` +
    completed event's `compliance_violation_rules:`) — they must not disappear
    because they don't block lower tiers.
  - Safeguard: classify violations per the existing compliance model; no
    advisory finding is reclassified as harmless, no genuine safety violation
    becomes a non-blocking warning.
- **OQ-2 — Tier C named stages: APPROVED as proposed** — every supporting
  input must have all three: (1) named `:piloted` stage, (2) named
  `:governance_reviewed` stage, (3) `:evidence_backed` status — verified from
  authoritative records, never inferred from labels, synthetic acceptance,
  stage-cursor position, or an earlier gate passing. Missing/malformed/
  unverified evidence fails closed. **Implemented in S5-2 (`5bb0990e`)** via
  `verify_rollout_tier/3` + `Stage5GovernanceRegistry` (§6): the production
  registry serves no authoritative records, so production adoption resolves
  fail-closed to `:adaptation_approved` with the denial reason recorded.
- **OQ-3 — `status` cursor cleanup**: leaving `:failed` in the cursor slot is
  ugly but locked for compatibility (CT-5/CT-8). A later, separate refactor
  could split `stage` vs `outcome` — explicitly out of scope here (§0.2).

---

## 8. Non-goals

- No change to acceptance criteria in S5-1 (`classify_adaptations/1`, renamed
  from `validate_adaptations/1`; four checks stay AND-ed, count stays `>= 7`).
- No new effect paths, no ledger/effect-sink work (C11 untouched).
- No Stage 6 certification claims; `:rollout_authorized` is eligibility
  vocabulary, not a certification.
- No rewiring of who calls `execute_stage_5/3`.
