# Phase 17.8.5 — Autonomous Experiment Scheduler

document_version: 17.8.5
phase: 17.8
status: Complete
owner: Constitutional Research Council
depends_on:
  - RESEARCH_PORTFOLIO_OPTIMIZATION.md (Phase 17.8.4)
  - AUTONOMOUS_RESEARCH_RUNTIME_FREEZE.md (APIs: ARPEScheduler)
  - RESEARCH_EXECUTION_PIPELINE.md (Stage 8: SCHEDULING)

---

## Scope

Phase 17.8.5 implements the ARPEScheduler (Stage 8 of the ARPE pipeline).

It produces deterministic `ExperimentSchedule` artifacts from a portfolio,
budget, and `ScheduleConfig`. It handles interruptions and adaptive rescheduling
without mutating existing artifacts.

---

## Constitutional Constraints (All Enforced)

- All concurrency and compute limits come from `ScheduleConfig` — never hardcoded.
- `max_parallel_campaigns` and `max_inflight_compute_units` are required fields.
- Adaptive rescheduling is only enabled when `ScheduleConfig.adaptive_scheduling_enabled`
  is `true`; calling it when disabled returns `{:error, %AdaptiveSchedulingDisabled{}}`.
- No `DateTime.utc_now()` in any artifact or ID.
- No `System.unique_integer()`, no random IDs.
- `schedule_fingerprint` is SHA-256 over the ordered dispatch_intents list — deterministic.
- `InterruptionRecord` is a separate artifact appended to archaeology lineage — never
  mutated in-place on the schedule.
- Output is an `ExperimentSchedule` struct with content-addressed ID.

---

## Files Implemented

### New Struct

| File | Module | Purpose |
|---|---|---|
| `schedule_config.ex` | `ScheduleConfig` | Epoch-frozen config: concurrency limits, adaptive flag, algorithm version |

### Rebuilt Engine

| File | Module | Violations Fixed |
|---|---|---|
| `engines/experiment_scheduler.ex` | `Engines.ExperimentScheduler` | Removed `max_parallel_campaigns: 3`, `max_compute_units: 1000`, `estimated_duration_ms: 3600000` hardcoded defaults; removed all `DateTime.utc_now()` calls; removed `last_rescheduled_at` wall-clock field; removed in-place map mutation with `|`; interruptions now return `InterruptionRecord` structs; adaptive reschedule guarded by config flag |

---

## ScheduleConfig (Epoch-Frozen Config Artifact)

Required fields:
- `max_parallel_campaigns` — positive integer
- `max_inflight_compute_units` — positive integer
- `adaptive_scheduling_enabled` — boolean
- `scheduling_algorithm_version` — frozen string

Content-addressed ID: `schcfg_<sha256>`.

---

## Schedule Production

1. Sort `selected_experiment_ids` from portfolio (ascending, deterministic)
2. Partition into waves of `max_parallel_campaigns` experiments
3. Assign `dispatch_mode`: `:parallel` for waves with > 1 experiment, `:sequential` otherwise
4. Compute `intent_id` for each intent: SHA-256 over `{experiment_id, wave, position, portfolio_id}`
5. Compute `schedule_fingerprint`: SHA-256 over sorted intent list
6. Build `ExperimentSchedule` struct with content-addressed ID

---

## Interruption Handling

`handle_interruption/4` removes the interrupted experiment from pending intents
and returns `{updated_schedule, [InterruptionRecord.t()]}`. No in-place mutation.

Each `InterruptionRecord` carries:
- `interruption_id` — content-addressed
- `experiment_id`, `reason`, `epoch_id`, `schedule_id` — all from caller

---

## Adaptive Rescheduling

`adaptive_reschedule/3` re-orders remaining intents: experiments whose
dependencies are all completed move to the front.
- Guarded by `ScheduleConfig.adaptive_scheduling_enabled`
- Returns `{:error, %AdaptiveSchedulingDisabled{}}` when disabled
- Deterministic: tie-broken by `intent_id` ascending

---

## Failure Taxonomy

| Failure | Struct | Condition |
|---|---|---|
| Config absent | `ScheduleConfigMissing` | config is nil or not `ScheduleConfig` |
| Config ID invalid | `ScheduleConfigMissing` | `verify_id/1` fails |
| Adaptive disabled | `AdaptiveSchedulingDisabled` | `adaptive_reschedule/3` called with `adaptive_scheduling_enabled: false` |

---

## Phase 17.8.5 Decision

**AUTONOMOUS SCHEDULER: COMPLETE**

Phase 17.8.6 (Theory Evolution) may now proceed.

---

## Dependency Chain

```
RESEARCH_PORTFOLIO_OPTIMIZATION (17.8.4)
    │
    ▼
AUTONOMOUS_SCHEDULER (17.8.5 — this document)
    │
    ▼
AUTONOMOUS_THEORY_EVOLUTION (17.8.6 — next)
```
