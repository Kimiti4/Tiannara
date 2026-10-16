# Phase A — Real Execution Contracts

Status: contract documentation only (no code changes in this phase).
Baseline: `4d982de7` — Elixir CI and Cross-Platform Verification both `success`.
Prepared: 2026-10-16, branch `local/pr4`.
Feeds: Phase B (Stage 3 genuine-analysis integration), Phase C (Stage 4/5 reassessment), Phase D (staged runner wiring).

This document records what each pipeline stage *actually computes today*, which
behavior is GENUINE (real computation over resolved evidence) and which is
SIMULATED (fabricated inputs, RNG metrics, or constant tables), and what the
contract must be before any stage is wired into a governed execution path.

Per approved scope: analyzing a proposed adaptation is **not** applying it.
Only application enters the governed effect-execution path — and must be
authorized before the effect occurs. A green CI run proves tested code passed
its checks; it does not establish any operational gate below.

## Status vocabulary

| Label | Meaning |
|---|---|
| GENUINE | Real computation over inputs resolved from real, validated evidence |
| SIMULATED | Fabricates or randomizes inputs, or emits constants as metrics |
| MIXED | Genuine orchestration whose leaf computations are simulated |
| UNKNOWN | Structurally real, but provenance/heuristic unjustified or untested |
| NOT_IMPLEMENTED | Contract declared in docs/code but with no implementing path |

`SIMULATED` ≠ `PASS`. No stage may be labeled PASS while any part of its
output is derived from fabricated inputs.

---

## C1. Episode retrieval and provenance

Owner: `TiannaraOS.MethodEvolutionPipeline` (`lib/tiannara/os/method_evolution_pipeline.ex`).
Implemented: commit `3860cfa7`. Tests: `test/tiannara/os/method_evolution_pipeline_retrieval_test.exs` (17, green).

### Contract

```
retrieve_episodes_for_analysis(institution_id, opts) ::
  {:ok, %{episodes: [ResearchEpisode.t], exclusions: [exclusion], provenance: map}}
  | {:error, {:no_evidence, %{index_entries, exclusions, provenance}}}
  | {:error, :institution_not_running}
  | {:error, {:invalid_institution_id, term}}
  | {:error, {:invalid_memory_state, term}}
```

- Authority: the `civilizational_memory` EpisodeIndex inside the kernel
  process (`Process.whereis(institution_id)`; Registry fallback is dead —
  `TiannaraOS.KernelRegistry` is never started).
- Resolution order per stored reference: index entry validity → entry/episode
  identity match → ownership (`institution_id`) → `status == :finalized`
  → full episode fetch from kernel memory.
- Exclusion reasons (each recorded, never silently dropped):
  `:stale_reference`, `:institution_mismatch`, `:index_institution_mismatch`,
  `:status_not_finalized`, `:entry_identity_mismatch`,
  `:episode_identity_mismatch`, `:invalid_index_entry`,
  `:invalid_episode_record`, `:not_indexed`, `:duplicate_reference`.
- Fail-closed: no evidence ⇒ `{:error, {:no_evidence, ...}}`; there is no
  empty-list success path.
- Determinism: candidates sorted by `{start_tick, episode_id}`.
- Time window: recorded only; `time_window_applied: false`,
  `time_window_reason: :no_tick_calendar_conversion_defined` — the
  tick↔calendar conversion is **unknown** and must stay labeled as such.

### Boundary that must hold in every consumer

Evidence identity, source linkage, and validity are established *here*, once.
Downstream analysis may not re-derive, assume, or fabricate them. Any consumer
that receives `{:error, {:no_evidence, _}}` must propagate the error, never
substitute synthetic episodes or proceed with an empty set.

### Known adjacent defect (Phase B scope)

`InstitutionKernel` carries a private, same-named retrieval stub returning
`[]` (`institution_kernel.ex:1299`) feeding its own `evaluate_method_evolution`
handler (`institution_kernel.ex:647`, public wrapper `:420`). That kernel path
never reaches `MethodEvolutionPipeline`. It must not be treated as the
retrieval contract, and its `[]` result violates fail-closed semantics if
exposed.

---

## C2. Stage 3 — genuine analysis and its failure modes

Surfaces (four — only one is the real path):

| Surface | Entry | Class |
|---|---|---|
| `MethodEvolutionPipeline.execute_pipeline/3` | `method_evolution_pipeline.ex:38` | MIXED → GENUINE-over-known-data (Phase B, see below) |
| `Stage3MethodEvolution.execute_stage_3/3` | `stage3_method_evolution.ex:35` | SIMULATED (synthesizes episodes from CSV stats or hardcoded defaults) |
| `InstitutionKernel.evaluate_method_evolution/2` | `institution_kernel.ex:647` | SIMULATED (stub retrieval + constant tables) |
| Runner `execute_stage3/2` | `recursive_civilization_runner.ex:229` | SIMULATED (self-declared; input ignored) |

### Phase B status (implemented)

Every leaf that previously emitted a constant is now either a documented
derivation over the retrieved episodes or the atom `:insufficient_data`:

| Function | Was | Now |
|---|---|---|
| `calculate_avg_replication_rate/1`, `calculate_avg_prediction_accuracy/1`, `calculate_theory_efficiency/1` | constants `0.75/0.68/0.55` | `:insufficient_data` — episodes record no replication, prediction-outcome, or hypothesis-outcome data |
| `calculate_resource_efficiency/1` | constant `0.72` | mean `value_generated/total_cost` over episodes with cost > 0; `:insufficient_data` when none carry cost data |
| `calculate_collaboration_index/1` | constant `0.45` | share of episodes with > 1 contributor |
| `calculate_validation_quality/1` | constant `0.80` | share of episodes with ≥ 1 validation transaction (coverage, not a quality score) |
| `measure_category_metric/2` | 11 category constants + `0.50` fallback | `:insufficient_data` for every category — episodes carry no per-category performance data |
| `detect_recurring_weaknesses/3` | thresholded the constants | numeric metrics only; `:insufficient_data` is never coerced or flagged |
| `count_supporting_episodes/2` | `length(episodes)` (category-blind) | `0` — no per-category episode linkage exists |
| `generate_improvement_proposals/3` | `confidence: 0.75`; cloned "Alternative approach" competitors | `confidence: :insufficient_data`; competing list always empty (no alternative-approach analysis exists) |
| `estimate_improvement_potential/1` | `gap * 0.6` forecast | `gap` — documented upper bound, not a forecast |
| `predict_impact_from_evidence/2` | `evidence_strength: :moderate`, invented ±20% interval, `take(episodes, 5)` ids | both fields `:insufficient_data`; `supporting_episode_ids: []` |

`evidence_summary.insufficient_data_metrics` lists every unknown metric.
Tests: `test/tiannara/os/method_evolution_analysis_test.exs` (evidence
sensitivity, explicit unknowns, no fabricated confidence/competitors,
deterministic replay, fail-closed error propagation).

Remaining gaps (later phases, not blockers for B): the vacuous
`success_rate` (always 1.0 under retrieval's `:finalized` filter) reflects
set composition, not outcome quality; generic mitigation templates and
category→complexity lookup tables are documented heuristics, not
measurements; the kernel duplicate path and `Stage3MethodEvolution` remain
SIMULATED surfaces.

### What is still genuine in `execute_pipeline/3` today

- Retrieval threading: Steps 2–7 consume *exactly* the retrieved episodes
  (`method_evolution_pipeline.ex:44-64`); result records
  `supporting_episodes` as real episode ids (`:75`), plus full exclusion
  provenance.
- `cluster_episodes_by_type/1`, `calculate_avg_duration/1`,
  `calculate_success_rate/1` (vacuous — retrieval guarantees `:finalized`,
  so it is always `1.0`), `calculate_severity/2`.

### Failure modes (contract)

Required, already true for retrieval; must remain true end-to-end:

1. No evidence ⇒ `{:error, {:no_evidence, ...}}`, no result struct.
2. Unresolvable institution/state ⇒ typed error, not empty analysis.
3. Exclusions are reported, never dropped; partial evidence yields a result
   *marked* partial with its exclusion list — never a confident-looking full one.
4. Invalid/malformed records ⇒ excluded with reason, not coerced.
5. Deterministic replay: same evidence set ⇒ same analysis output.
6. Unresolved semantics (time window) stay explicitly unknown in output.

All six now hold for the real path. The remaining Phase B-era requirement —
"analysis values must be functions of the evidence" — holds for every metric
that episodes can support; metrics episodes cannot support are labeled
unknown instead of fabricated.

---

## C3. Stage 4 — adaptation proposals versus actual adaptation effects

### Current state: proposals exist, effects do NOT

- Proposal producers: genuine shape from `generate_improvement_proposals/3`
  (`method_evolution_pipeline.ex:407-417`:
  `%{category, description, expected_impact, confidence, implementation_complexity, supporting_episode_count, risk_level}`);
  synthetic shape from `stage3_method_evolution.ex:391-402` (adds
  `supporting_episodes` + `evidence_quality`).
- Effect execution: **NOT_IMPLEMENTED**. Kernel `adapt_institution` handler
  returns unchanged state (`institution_kernel.ex:726-754`);
  `InstitutionAdaptationPipeline.ensure_rollback_capability` is a no-op with
  debug logs (`institution_adaptation_pipeline.ex:53, :406`); runner
  `apply_pending_adaptations/1` returns state unchanged
  (`recursive_civilization_runner.ex:538-542`). No institutional parameter,
  program, method, or ledger is ever mutated.

### Analyze vs apply (the critical distinction)

| | Analyze | Apply |
|---|---|---|
| Input | A *proposal* (from C2 analysis) | An *authorized effect* |
| Path | `execute_pipeline` / dry-run surfaces (`SelfImprovement.DryRun`, `Omega.DryRun`, `RealExecution.run_sandbox`) | Governed effect path only (C5 stack), **authorized before the effect occurs** |
| Output | Recommendation + evidence references | Mutated state + durable, fail-closed evidence record |

Analyzing a proposal must never mutate state. Applying must never happen
without: typed contract, pre-effect authorization, effect claim, post-effect
evidence persistence, and surfaced persistence failure.

### Fabricated-metric inventory (must be removed or isolated before any wiring)

*Phase C status: all `stage4_institution_adaptation.ex` rows below are now
isolated behind the explicit `:simulated` evidence mode (never on the
default `:evidence_backed` path); `institution_adaptation_result.ex` check-5
row fixed (`:governance_reviewed` no longer required in stage history).
`institution_adaptation_pipeline.ex` rows remain as documented, unwired
surfaces.*

| Location | Fabrication |
|---|---|
| `stage4_institution_adaptation.ex:383-440` | 20 pilot episodes drawn from `:rand.uniform()` reported as observed `pilot_metrics` |
| `stage4_institution_adaptation.ex:448, :476-479, :499, :701` | baseline `0.6` hardcoded; cost/duration placeholders |
| `stage4_institution_adaptation.ex:680` | `:governance_reviewed` lifecycle event appended unconditionally — no review performed |
| `stage4_institution_adaptation.ex:716-744` | formulaic rollback plan, `rollback_confidence: 0.85` |
| `institution_adaptation_pipeline.ex:193-209` | "representative baseline values" constants (`research_debt: 45`, …) |
| `institution_adaptation_pipeline.ex:217-244` | simulated historical results, hardcoded `confidence: 0.82`, `"Applied to 150 historical episodes"` |
| `institution_adaptation_pipeline.ex:265-312` | `pilot_successful: true` hardcoded; improvement constants `0.18/0.13/0.22/0.16` |
| `institution_adaptation_result.ex:214, :595-617` | `rollback_available` defaults `true`; compliance checks unreachable for Stage 4's `:partially_adopted`/`:none_adopted` decisions |

Governance gap: `validate_governance/3` guards only `spawn_campaign`
(`institution_kernel.ex:505`), never adaptation; `record_governance_review/2`
(`institution_adaptation_result.ex:415`) has zero callers.

### Cross-cutting shape trap (PRE-PHASE-C BASELINE — fixed below)

`validate_provenance/1` dot-accesses `proposal.supporting_episodes` and
`proposal.evidence_quality` (`stage4_institution_adaptation.ex:163, :166`).
Genuine proposals do not carry those keys; **only synthetic proposals pass
Stage 4's gate today.** Untested (no Stage 4 tests exist), expected outcome:
`KeyError` for genuine input. Phase C must fix the gate before any genuine
proposal can flow — and the gate must check *provenance* (real episode
references resolvable per C1), not a self-asserted `evidence_quality` tag.

### Phase C outcome (implemented)

`execute_stage_4/3` now takes `opts.evidence_mode` ∈
`[:evidence_backed (default), :simulated]` (invalid mode raises
`ArgumentError`). Both fabrication vectors above are addressed:

- **Provenance gate fixed.** `validate_provenance/2` in `:evidence_backed`
  mode accepts only proposals carrying non-empty `supporting_episode_ids`
  (genuine Phase B shape); the legacy synthetic keys
  (`supporting_episodes` + `evidence_quality`) are rejected outright.
  The synthetic gate survives only under explicit `:simulated` opt-in.
- **No fabricated pilot metrics on the evidence path.** The evidence
  pipeline performs no RNG: compatibility uses a documented complexity/risk
  cost heuristic, projections are labeled
  `projection_method: :upper_bound_decay` (efficiency
  `:insufficient_data`), and the pilot phase records
  `pilot_executed: false` with `reason: :no_pilot_execution_capability`.
  Adoption is impossible without pilot evidence — every compatible proposal
  is deferred `:awaiting_pilot_evidence`; decision is always `:none_adopted`.
- **Lifecycle honesty.** `:governance_reviewed` is no longer appended by
  `add_all_lifecycle_events` (theater removed); the evidence path appends
  only performed stages (`:proposal_received` via `new/2`, then
  `:compatibility_analyzed`, `:risk_assessed`, `:projected`,
  `:decision_recorded`) and is therefore honestly non-compliant with the
  full-adaptation checklist (fail-closed). The simulated path appends its
  historical 10-stage list (still without `:governance_reviewed`).
- **Labeling.** `simulation_results.evidence_source` is `:evidence_backed`
  on the evidence path and `:simulated` on the opt-in synthetic path (both
  result shapes; rejection results labeled too). Simulated-mode constants
  (`get_historical_success_rate` 0.6 default, placeholder baselines) remain
  but are reachable only under the explicit label.
- **Compliance fix.** `validate_constitutional_compliance` check 5
  (`institution_adaptation_result.ex`) no longer requires
  `:governance_reviewed` in stage history — governance review remains
  enforced by check 4 whenever `:adopted`/`:rejected` is recorded;
  pipeline-completeness is not a substitute for a review that never
  happened. `record_governance_review/2` still has zero callers (unchanged;
  the governance stack in C5 remains the path for future wiring).
- **Still unchanged (documented, deliberate):** `InstitutionAdaptationPipeline`
  constants and no-op `ensure_rollback_capability` (C5-adjacent surfaces,
  unwired); `Phase13Stabilization.ensure_complete_lifecycle` still
  fabricates missing stages (including `:governance_reviewed`) — noted as a
  fail-open point, untouched this phase; `RecursiveCivilizationRunner`
  untouched (Phase D, gated).
- **Tests:** `test/tiannara/os/stage4_institution_adaptation_test.exs`
  (12 tests): synthetic-shape rejected; empty references rejected; genuine
  proposals deferred never adopted with no fabricated pilot metrics;
  projection labels; lifecycle honesty; determinism (no RNG); invalid mode
  raises; simulated-mode opt-in accepts legacy shape, labels `:simulated`,
  never appends `:governance_reviewed`, and still filters genuine
  proposals (gate symmetry).

---

## C4. Stage 5 — analytical inputs and outputs

Surfaces: `Stage5CivilizationAdaptation.execute_stage_5/3`
(`stage5_civilization_adaptation.ex:49`, zero callers except a root demo
script); `CivilizationAdaptationPipeline.execute_pipeline/3`
(`civilization_adaptation_pipeline.ex:41`, reachable from
`CivilizationKernel` `:evaluate_civilization_adaptation` at
`civilization_kernel.ex:319`).

### Contract (target)

Stage 5 is an **analyzer over explicitly labeled inputs**. It aggregates and
compares adaptation results; it must not manufacture pedigree.

### Current behavior

- GENUINE arithmetic: family grouping (`:169-194`), consistency score
  (`:269-302`), transferability rules (`:308-369`), fail-closed empty-input
  handling (`create_empty_result/2`, `:580-588`, emits `:failed` with reason).
- Provenance gap (the risk): `validate_adaptations/1` (`:146-163`) checks only
  structure — ≥7 lifecycle stages, `%{is_compliant: true}`, `rollback_available`.
  **No check of where the input came from.** Synthetic Stage 4 output satisfies
  this gate exactly (11 auto-appended stages, default `rollback_available: true`)
  — i.e., the analyzer would treat RNG pilot metrics as evidence of
  civilization adaptation.
- SIMULATED leaf: `generate_rollout_plan/3` (`:486-538`) — hardcoded
  credits/benefits, `rollback_strategy: %{confidence: 0.9}`, empty
  `deployment_order`.
- Kernel path is worse: `collect_institution_data/2`
  (`civilization_adaptation_pipeline.ex:161-178`) fabricates
  `efficiency_gain: :rand.uniform() * 0.3` and random adoption statuses —
  SIMULATED, yet reachable from a kernel handler.

### Requirements (Phase C)

1. Inputs must carry provenance resolvable to C1-style evidence or be
   explicitly labeled `SIMULATED`; unlabeled synthetic input is a contract
   violation, not a silent accept.
2. Stage 5 output may never upgrade `SIMULATED` inputs into evidence of
   genuine adaptation — output provenance = input provenance, weakest link.
3. `generate_rollout_plan` stays SIMULATED-labeled until its values are
   derived from inputs.
4. Structural gate (`validate_adaptations/1`) plus provenance gate; both
   fail-closed.

### Phase C outcome (implemented)

All four requirements are implemented:

1. **Evidence-source gate.** `validate_adaptations/1` now requires each
   input to carry `simulation_results.evidence_source` ∈
   `[:evidence_backed, :synthetic]`; unlabeled inputs are filtered out
   (fail-closed) and, with no valid inputs remaining, the pipeline emits
   `create_empty_result(result, :no_valid_adaptations)` (`status: :failed`,
   no `evidence_lineage`).
2. **No pedigree upgrade.** After validation, `build_evidence_lineage/1`
   records `weakest_input_source` (`:synthetic` if ANY input is synthetic,
   else `:evidence_backed`) plus the per-input source map on
   `result.evidence_lineage` (new struct field on
   `CivilizationAdaptationResult`). Synthetic inputs are accepted for
   analysis but the output never claims stronger provenance than its
   weakest input.
3. **Rollout plan labeled.** `generate_rollout_plan/3` now includes
   `rollout_plan_source: :simulated` in the plan map.
4. **Both gates fail-closed** (structural + evidence-source, plus the
   pre-existing fail-closed empty-input handling).

Also fixed while wiring tests (pre-existing latent crash, never exercised):
`advance_stage/2` transition machine lacked the `pending → adaptations_collected`
hop that its own documented chain (`:210-216`) starts from — Stage 5's
`advance_stage(:validated)` from `new/2`'s `status: :pending` raised
`ArgumentError` for every labeled input. Added the missing hop and the
matching `advance_stage(:adaptations_collected)` call in Stage 5.
`add_lifecycle_event/3` now emits both `:type` and `:stage` keys so
`validate_constitutional_compliance`'s `e.stage` reads succeed regardless
of which API appended the event.

**Tests:** `test/tiannara/os/stage5_evidence_lineage_test.exs` (5 tests):
unlabeled inputs fail closed; empty input list fails closed; evidence-backed
lineage; mixed inputs mark weakest `:synthetic` (never upgraded); rollout
plan labeled `:simulated`.

**Still unchanged (documented, deliberate):** the kernel-reachable
`CivilizationAdaptationPipeline` path (`collect_institution_data` fabricates
`:rand.uniform()` efficiency gains) remains a SIMULATED surface — it is not
the `execute_stage_5` surface fixed here, has not been wired, and needs the
same treatment before any kernel exposure. `RecursiveCivilizationRunner`
untouched (Phase D, gated).

---

## C5. Constitutional authorization, effect claims, evidence persistence, rollback

### Genuine, enforced stack (usable as-is)

| Mechanism | Location | Status |
|---|---|---|
| Decision authorization | `Tiannara.Council.authorize/3` (`council.ex:35-50`) + `Authorization.permitted?/1` (`authorization.ex:112`) | Genuine; conditions fail closed |
| Machine grant mint/bind | `MachineAuthorization.mint/2`, `bind_effect/2` (`machine_authorization.ex:115, :148`) | Genuine; registry insert-first |
| Durable one-shot registry | `Omega.MintRegistry` status/bind/consume CAS (`mint_registry.ex:263-309`) | Fail-closed: unreadable/corrupt ⇒ refuse |
| Effect admission chain | `Phase4.ExecutionGovernance.begin/2` (`execution_governance.ex:42-59`): grant → minted → valid → unexpired → bound → unconsumed → claim → audit | Genuine; tested (`execution_governance_test.exs`) |
| Effect identity | `Omega.EffectIdentity` — `effect-v1-<sha256>` over semantic descriptor | Genuine |
| Deploy gate | `DeploymentGateway.deploy/6` (`deployment_gateway.ex:72-124`) mandatory mint+consume | Genuine |
| Hash-chained audit log | `Council.AuditLog` (DETS, Merkle) — `{:error, :storage_degraded}` propagated fail-closed by WME/governance/gateway edges | Fail-closed |
| Pre-effect claim release | `ExecutionGovernance.release/1` (`:63-70`) after *failed* execution; grant stays burned | Genuine, tested (S03) |
| Reference effect pattern | `Phase4.PhysicsPilotExecution`: human grant gate (`:156-165`) → governance begin → effect → fail-closed JSONL ledger (`:223-243`, `{:error, {:execution_ledger_write_failed, _}}`) → audit errors surfaced (`:134-146`) | **The template for any future Stage 4 effect path** (commit `5accf21a`) |

Fail-closed default flag: `:real_execution_enabled` defaults `false` and is
unset in checked-in config — real execution is off unless explicitly enabled.

### Unwired / fail-open / not-implemented (must not be assumed present)

| Item | Location | Defect |
|---|---|---|
| `GovernedEffectSink` | `governed_effect_sink.ex:136-170` | Full N1–N9 chain but zero `lib/` callers; topic `"governed.effect"` unconsumed |
| Human-grant mint in production | `Authorization.record_mint/1` | No production caller ⇒ production human grants refused `:authorization_not_registered` (fail-closed, but path effectively dead) |
| `DeploymentRegistry` | `deployment_registry.ex:11-16` | `registry_path` never supplied in production; `File.write` result discarded — replay-dedup inert, write fail-open |
| `RealExecution.record_execution` | `real_execution.ex:301-329` | Ledger write swallowed (`rescue → Logger.error`), caller `:101` ignores result — **fail-open**; untested as a failure mode (only physics sink is fail-closed) |
| Runner per-generation CSV append | `recursive_civilization_runner.ex:197` | Result of `GenerationHistory.append_to_file` discarded (`generation_history.ex:386` can return `{:error, _}`) — silent evidence loss, run still reports success |
| Rollback for applied effects | — | **NOT_IMPLEMENTED**: `WorldMutationEngine.execute_rollback` (`:593-600`) flips a record but reverts nothing (untested); `Autonomy.RollbackEngine` honest-stubs `{:error, :rollback_unavailable}`; no rollback exists for Gateway deploys, `RealExecution` effects, or MintRegistry consumption (explicitly non-revocable) |
| Governance review on adaptation | `record_governance_review/2` | Zero callers; required by `validate_constitutional_compliance` check 4 but unreachable for Stage 4's decision atoms |

### Contract requirements before any new effect path (Phase D prerequisites)

1. Authorization **before** the effect; claim before execution; consume before
   deploy — using the C5 genuine stack, never ad-hoc checks.
2. Evidence persistence **fail-closed**: a persistence failure after an effect
   is an error surfaced to the caller (physics-pilot semantics), never a log
   line with `{:ok, ...}` returned.
3. Every fail-open point in the table above is either fixed or explicitly
   waived with recorded rationale before the path it sits on is called real.
4. Rollback: where the effect is not revocable (MintRegistry consumption,
   deployed artifacts), the contract must *say* that; "rollback available"
   fields must not default to `true` (`institution_adaptation_result.ex:214`).

---

## C6. Runner integration contract (input to Phase D)

Entry: `RecursiveCivilizationRunner.execute/2` (`recursive_civilization_runner.ex:62`).
Per-generation stages, in order: apply pending adaptations → episodes →
theory → validation → Stage 3 → Stage 4 → Stage 5 → metrics/attestation.

| Stage | Class | Evidence |
|---|---|---|
| Episodes, theory, validation (`:490-536`) | SIMULATED | inline `:rand.uniform`/`Enum.random`, no engine call |
| Stage 3 (`:229-244`) | SIMULATED | `Enum.random(3..8)` fabricated results; input `_episodes` ignored; self-declared comment `:230-231` |
| Stage 4 (`:246-280`) | SIMULATED | RNG success formula; **trap**: fabricated results wear real `DateTime` stage-history timestamps (`:276, :563-574`) and hardcoded `constitutional_compliance: true` (`:277`) |
| Stage 5 (`:282-306`) | SIMULATED | deterministic cond + `Enum.random` |
| Metrics (`:346-458`) | MIXED | real modules (`ConstitutionManifest.build`, `ScientificCapitalLedger.calculate_delta`, `GenerationHistory.calculate_cai`, `ConstitutionCertificate.generate`) fed synthetic inputs (simulated transactions, hardcoded `rollback_frequency: 0.05`, `constitutional_violations: 0`) |
| `apply_pending_adaptations/1` (`:538-542`) | NOT_IMPLEMENTED | returns `state` unchanged — the documented temporal rule "approvals in G active in G+1" (moduledoc `:26-29`) has no implementing path |

Labeling (PRE-PHASE-D BASELINE): no per-stage SIMULATED/PASS vocabulary existed
in runner state — `GenerationHistory` records only counts/ids
(`generation_history.ex:113-116`). Closest signals: certificate atoms
`:harness_simulated`/`:not_verified` → `certification_level: "minimal"`
(asserted honest by `recursive_civilization_runner_test.exs:55`).

### Phase D step 1 outcome (implemented)

Machine-readable stage evidence labeling plus explicit authorization and
bounding are now enforced by the runner itself:

- **`stage_evidence_labels`** map assigns each of the 7 pipeline components
  (`episode_generation`, `theory_formation`, `distributed_validation`,
  `stage3_method_evolution`, `stage4_institution_adaptation`,
  `stage5_civilization_adaptation`, `metrics_collection`) a label from the
  vocabulary `:simulated | :evidence_backed` — never `:pass`. All labels
  start `:simulated`; a stage flips only when its genuine wiring lands via
  a later Phase D step.
- **Persistence (machine-readable state):** run-level
  `<output_dir>/stage_evidence_labels.json` (with `run_authorized`,
  `bounded` bounds, `certification_claim: "none"`); every per-generation
  attestation row in `constitution_attestations.jsonl`; every checkpoint
  file. Labels travel with the evidence, not only console text.
- **Explicit authorization:** `execute/2` raises `ArgumentError` unless
  `opts.authorized == true` (fail-closed). `ConstitutionalExecutor`
  (the documented legal path) passes `authorized: true` after its
  structural gate. The runner test passes it explicitly.
- **Bounding:** `episodes_per_generation > 0` enforced (`ArgumentError`
  otherwise); `num_generations > 0` was already enforced by the guard;
  effective bounds recorded in the labels file and attestation rows.
- **Staged wiring plumbing:** `opts.stage_modes` validates per-stage mode;
  `:evidence_backed` for any stage raises
  `ArgumentError ("does not support :evidence_backed yet")` until that
  stage's typed contract + provenance + validation + persistence wiring
  lands — the runner never pretends a stage is wired.

### Direct-bypass enforcement note (policy question unchanged)

`RecursiveEvolutionValidator`, `StatisticalValidation`, and `ValidatorAudit`
still call `execute/2` directly, bypassing `ConstitutionalExecutor` — the
open policy question stands and is NOT resolved here. Those call sites do
not pass `authorized: true`, so they now fail closed with `ArgumentError`
when invoked. Resolving how they should run (through the executor, or with
an explicit sanctioned authorization) remains a product decision.

Tests: `recursive_civilization_runner_test.exs` — 9 tests (1 provenance
regression + 8 new): unauthorized raise, bounds raise, labels file contents
(all simulated, no `:pass`), attestation labels, checkpoint labels,
unwired-stage raise, unknown-key raise, invalid-mode raise, explicit
:simulated modes accepted.

Failure semantics: no rescue anywhere — stage errors abort the run
(fail-closed), except the ignored CSV append (`:197`, fail-open).
Bounding: `num_generations > 0` only; no timeout/max-steps. Opt-out flag
`enable_adaptation` (default `true` runs stages 3–5). The single existing
test runs with adaptation **disabled**, so stages 3–5 have zero coverage.

Phase D rules (per approved plan): replace stages one at a time with typed
contracts + input/output provenance + output validation + evidence persistence
+ tested authorization/failure/recovery; each unreplaced stage must be labeled
`SIMULATED` **in machine-readable state**, not only console text; bounded,
explicitly authorized runs only; no broad autonomous real execution for
testing.

Open policy question: three lib validator modules
(`validator_audit.ex:113`, `statistical_validation.ex:115`,
`recursive_evolution_validator.ex:109`) call `execute/2` directly, bypassing
`ConstitutionalExecutor`, contradicting the documented "only legal path".
*Phase D step 1 update: those direct calls now fail closed (`ArgumentError`
from the new authorization gate) when invoked — the policy question stands.

---

## Cross-cutting open unknowns (carried forward)

1. ~~Stage 4 ingestion of genuine proposals untested; expected `KeyError` on
   missing `supporting_episodes` (C3 shape trap) — confirm at Phase C.~~
   **RESOLVED at Phase C:** the shape trap is confirmed and fixed —
   `validate_provenance/2` now branches on `evidence_mode`; genuine
   proposals flow through the `:evidence_backed` path (deferred, never
   adopted, no fabricated metrics), legacy synthetic shape flows only
   under explicit `:simulated`. Covered by
   `stage4_institution_adaptation_test.exs`.
2. ~~Kernel `evaluate_method_evolution` reachable-but-simulated; stub `[]`
   retrieval violates fail-closed if exposed (C1).~~ **RESOLVED at Phase
   B:** genuine retrieval integration; kernel surface remains SIMULATED
   (documented, not rewired — Decision 4).
3. No write-back path exists anywhere: evidence → decision → effect → new
   episode/index entry loop is NOT_IMPLEMENTED in `lib/tiannara/os/`.
4. Human-grant production wiring and `GovernedEffectSink` consumers unresolved
   (C5) — product confirmation needed, not assumptions.
5. `run_stage5_civilization_adaptation.exs` demo inputs appear to fail Stage
   5's own structural gate (`constitutional_compliance: true` boolean vs
   `%{is_compliant: true}`) — by inspection, never executed here. Phase C
   adds a second gate: demo inputs also lack `simulation_results.evidence_source`,
   so they now fail closed on provenance as well.
6. AuditLog degraded mode (`world_mutation_engine.ex:361-366` makes evidence
   gating conditional on `not AuditLog.degraded?`) — not fully traced.
7. `Phase13Stabilization.ensure_complete_lifecycle` fabricates missing
   stages (including `:governance_reviewed`) — a fail-open point recorded
   at Phase C; intentionally untouched (separate remediation).

## What this document does not certify

Nothing here is a Stage 6 PASS or certification. Certification gates (real
engine execution, data integrity, lineage, adaptation isolation, independent
verification, persistence, governance, reproducibility) remain **closed** and
require evidence-backed execution plus independent verification per the
approved gate table.
