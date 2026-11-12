# TCP-002.4 — Research-to-Forecast Operational Closure: Implementation Report

**Checkpoint:** TCP-002.4
**Workstream:** W0 — Activate Existing Capabilities
**Starting commit:** `4e24f3277ec3f0f40da8d7846b14a63b9ffb9a6d`
**Status:** **PARTIAL** — Stages 0–3 delivered; Stages 4–13 open.
**Date:** 2026-11-13

---

## 1. Executive disposition

| Stage | Disposition | Reason |
|-------|-------------|--------|
| 0 — Baseline | **PASS** | Repository, source, caller and dependency state recorded and revalidated. |
| 1 — Lifecycle contract | **PASS** | Contract defined against the existing canonical structures; the rewrite properties are mechanically enforced by the registry and the bridge. |
| 2 — Research Director → EFDI | **PASS** | The supervised Research Director produces a registered probabilistic forecast through canonical EFDI. |
| 3 — Durable registry + adversarial recovery | **PASS** | 14 adversarial tests against a real on-disk log; two real defects found and fixed at source. |
| 4 — Outcome acquisition | **BLOCKED** | No live external source is available in this environment; the observation half of the lifecycle cannot be demonstrated with real-world evidence. |
| 5 — Independent resolution | **OPEN** | `OutcomeResolution`/`TemporalFirewall` exist and are correct, but there is no observation to resolve. |
| 6 — Forecast scoring | **OPEN** | `Calibration.score/2` exists; no eligible resolved forecast exists to score. |
| 7 — Calibration readiness | **OPEN** | Depends on 6. |
| 8 — Governed model update | **OPEN** | `ModelUpdateGate` is unchanged and still forbids production mutation; no performance record exists to assess. |
| 9 — Spine integration | **PASS (partial)** | The Spine retains confidence, uncertainty and probability as separate outputs; the NATS transport remains unexecuted. |
| 10 — End-to-end demonstration | **PARTIAL** | The research → forecast → durable registration half is demonstrated; the outcome, resolution and scoring halves are not. |
| 11 — Test programme | **PASS** | See §5. |
| 12 — Observability | **OPEN** | Not started. |
| 13 — Register reconciliation | **PASS** | See §7. |

**Overall: `IMPLEMENTED_WITH_PARTIAL_EVIDENCE` / `VERIFICATION_BLOCKED`.**

TCP-002.4 does **not** claim a demonstrated operational vertical slice. The
forecast half of the lifecycle is now real, durable and adversarially tested;
the observation half is not built, and no real-world predictive performance
exists.

## 2. What was delivered

### 2.1 Stage 2 — the Research Director now reaches EFDI

**New:** `lib/tiannara/research/forecasting.ex` — an adapter that performs no
forecasting mathematics. It validates a forecast specification, builds the
versioned request, calls `Tiannara.Forecasting.Bridge`, and records the
outcome on the hypothesis.

**Changed:** the supervised Research Director pipeline requests a forecast at
the hypothesis-evaluation stage; hypotheses carry `forecast_spec`,
`forecast_status`, `forecast` and `forecast_id`; an EFDI research priority
carries the signal's forecast specification when it has one.

The integration obeys three rules:

1. **A hypothesis that is not a forecastable proposition is not given an
   invented probability.** The hypotheses the director generates today are
   causal claims (*"the observed behaviour is caused by an identifiable
   factor"*) with no outcome space and no horizon. Forcing a forecast onto
   them would forecast an unmeasurable proposition. They are marked
   `:not_forecastable` with the reason — which is a different statement from
   `:unavailable`, and the two are kept distinct.
2. **Evidence confidence, expected information gain and forecast probability
   stay separate.** A confidence score is never converted into a probability.
3. **The forecast request is identified by the research input**, not by the
   hypothesis instance, so re-ingesting the same priority returns the original
   forecast instead of creating a second one.

### 2.2 Stage 3 — the durable registry, adversarially verified

`test/tiannara/forecasting/forecast_registry_durability_test.exs` — 14 tests,
each against an **isolated durable log on disk** and an isolated registry
instance.

Writing those tests exposed two real defects, both fixed at their canonical
ownership:

| Defect | Consequence before the fix | Fix |
|--------|--------------------------|-----|
| `EventStore.parse_frames/4` stopped at the first unreadable frame and returned what it had read | A truncated tail or corrupted frame produced a **clean-looking but incomplete** history | The store counts unreadable frames, distinguishes a truncated tail, and exposes `stream_with_diagnostics/1`; the registry reports `recovery_failures` and `durable: false` |
| `Event.from_binary/1` used `:erlang.binary_to_term(bin)` | A tampered log could introduce **executable terms** into the reader | `:erlang.binary_to_term(bin, [:safe])` |

The registry and the event store are now instance-isolatable
(`:forecast_registry_name`, `:executive_event_store`), which is what makes an
isolated durability test possible and removes the tension between application
supervision and per-test isolation.

### 2.3 Fail-closed behaviour added

Three places now fail closed with an explicit reason instead of crashing or
silently degrading:

| Component | Before | After |
|-----------|--------|-------|
| `Bridge.forecast/2` | an unavailable registry raised an exit | `{:error, :forecast_registry_unavailable}` |
| `Research.Forecasting.request_forecast/2` | an unavailable authority raised an exit | `{:error, :forecast_engine_unavailable}` |
| `ForecastRegistry.rehydrate/3` | unreadable records were silently dropped | counted and reported as `recovery_failures`, with `durable: false` |

## 3. Existing modules reused, unmodified

`ModelUpdateGate`, `OutcomeResolution`, `TemporalFirewall`, `Calibration`,
`ForecastEngine`, `BaseRateEngine`, `DecisionEngine`, `Contracts`, `Hypothesis
Ranker`'s ranking logic, and the D4/D5 components were **not** changed.
`ModelUpdateGate` still returns `authority: :none`,
`production_mutation: :forbidden`, `human_review_required: true`,
`certification_eligible: false`.

## 4. New modules, and why they were unavoidable

| Module | Why |
|--------|-----|
| `Tiannara.Research.Forecasting` | The Research Director needed *a* way to ask the canonical authority for a forecast. It contained no forecasting mathematics; it builds a versioned request and calls EFDI. Reusing `Tiannara.Forecasting.Bridge` directly would have put request construction inside the research pipeline and duplicated validation. |

## 5. Verification

| Suite | Command | Result |
|-------|---------|--------|
| Application forecasting | `MIX_ENV=test mix test test/tiannara/forecasting --seed 0 --no-deps-check` | **428 tests, 0 failures** (414 at TCP-002.3, +14 adversarial) |
| Research → EFDI integration | `MIX_ENV=test mix test test/tiannara/research/research_forecasting_integration_test.exs --seed 0 --no-deps-check` | **10 tests, 0 failures** |
| Registry durability | `MIX_ENV=test mix test test/tiannara/forecasting/forecast_registry_durability_test.exs --seed 0 --no-deps-check` | **14 tests, 0 failures** |
| Runtime regression | `MIX_ENV=test mix test test/{simulation,runtime_layers,kernel,cognitive,world_model} --seed 0 --no-deps-check` | see §9 |

Seeds `0` and `123456` were used. Exact counts are recorded in §9.

**Not executed:** the NATS transport (no NATS server in this environment) and
the observation half of the lifecycle (no outcome provider).

## 6. Epistemic limitations

- **No real-world predictive performance exists.** No forecast has been resolved
  against an actual observation, so no score has been computed and no
  calibration claim is possible.
- **The NATS transport is compiled but unexecuted.** The refusing default
  covers the absent-authority path instead.
- **Two hypothesis quantities are hardcoded heuristics** — `confidence: 0.5`
  and per-domain `eig_score` constants — and are presented as measurements
  (`TCP-B-056`). They were not "fixed" because the correct value requires a
  measurement that does not exist.
- **The forecast horizon is free text**, so a resolver cannot yet enforce the
  declared window automatically (`TCP-B-059`).
- **The durable log has no per-record sequence number**, so reordering cannot
  be detected (`TCP-B-057`), and **no integrity digest covers the record**,
  so a tampered field is only caught where it breaks validation (`TCP-B-058`).
- **The correlation between the runtime Spine and the Research Director is
  not yet established.** The Spine reaches EFDI through its own port; the
  research pipeline reaches it in-process. Both use the same canonical
  authority, but they are not yet one invocation.

## 7. Blocker register

60 rows: 42 open, 17 resolved, 1 partial.

Reconciled in this checkpoint: `TCP-B-047` (Research Director → EFDI) **RESOLVED**;
`TCP-B-050` (adversarial persistence suite) **RESOLVED**; `TCP-B-048` (outcome
acquisition) remains **OPEN** with updated evidence.

New: `TCP-B-053` … `TCP-B-060`.

`TCP-B-046` (the cross-stack compile-time boundary) remains **open**. It was
not closed through an adapter workaround.

## 8. Security and governance

| Finding | Status | Change in this checkpoint |
|---------|--------|---------------------------|
| `RL-565` | `HIGH / OPEN` | none |
| `RL-564` | `OPEN` | none |
| `F-ARC-018` | `OPEN` | none |

No constitutional authority was changed. `ModelUpdateGate` was not modified and
still forbids production mutation without human review. No registry promotion,
no deployment, no merge, no physical actuation.

The one security-relevant change is a **tightening**: `Event.from_binary/1` no
longer constructs arbitrary terms from the durable log.

## 9. Next checkpoint

**TCP-002.5 — Outcome observation, independent resolution, and the first
score.**

The dependency order is forced:

1. **An observation contract** that binds an acquired observation to a
   forecast's declared outcome definition, with source and acquisition
   timestamps, an evidence reference and a verification status
   (`TCP-B-060`).
2. **An acquisition adapter** over a real, declared source. This is the gate
   that cannot be met from inside this environment: if no live source is
   reachable, the honest result is a refusal path plus a blocked gate, not a
   simulated observation presented as evidence.
3. **Independent resolution** through the existing `OutcomeResolution` and
   `TemporalFirewall`, with the temporal-leakage adversarial suite.
4. **Scoring** through the existing `Calibration.score/2`, verified against
   hand-calculated Brier and log-loss vectors.
5. **Calibration readiness** — sample sufficiency and cohort eligibility
   reported honestly, with a single resolved forecast explicitly *not* being
   enough.

Why it is next: the forecast half of the lifecycle now exists, is durable and
is adversarially tested. Nothing about it can be *learned from* until an
observation exists to score it against. The remaining programme — calibration,
governed model update, and the live demonstration — is all downstream of that
one missing observation.
