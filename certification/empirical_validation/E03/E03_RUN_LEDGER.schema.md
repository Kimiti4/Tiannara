# E03 Run Ledger — JSONL Schema

**Campaign:** E03 — Stabilizer-Only Emergence Campaign
**Date:** 2026-09-03 · **FROZEN against HEAD:** `3bd1601b9bb3c718f985d44ceaa8ef2e638d4ec6`
**Reference:** `E03_PREREGISTRATION.md` §9 (measurements), §10 (emergence provenance), §24 (provenance)

The ledger is a single append-only JSONL file: `certification/empirical_validation/E03/runs/E03_RUN_LEDGER.jsonl`. Every record is one JSON object on one line. Records are written by the run harness in temporal order. The ledger is the single source of truth for E03 measurements.

## Top-level provenance (every record)

Every record carries these fields, matching the pre-registration §24 schema:

| Field | Type | Description |
|---|---|---|
| `type` | atom-as-string | one of `run_start`, `checkpoint`, `intervention`, `emergence`, `run_end`, `error`, `stop` |
| `campaign_id` | string | always `"E03"` |
| `experiment_id` | string | e.g. `"E03-A-001"` (condition + seed) |
| `tick` | integer | tick at which the record was emitted (omitted on `run_start`/`run_end`) |
| `recorded_at` | ISO 8601 string | UTC timestamp |

## Per-record-type schemas

### `run_start` (one per run)

```json
{
  "type": "run_start",
  "campaign_id": "E03",
  "experiment_id": "E03-B-001",
  "condition": "control_b",
  "seed": 42,
  "config_hash": "<sha256 of frozen config>",
  "code_revision": "3bd1601...",
  "cycles": 10000,
  "checkpoints": [0, 100, 500, 1000, 2500, 5000, 7500, 10000],
  "started_at": "<iso8601>"
}
```

### `checkpoint` (8 per run, at frozen ticks 0/100/500/1000/2500/5000/7500/10000)

```json
{
  "type": "checkpoint",
  "campaign_id": "E03",
  "experiment_id": "E03-B-001",
  "tick": 1000,
  "ecology": {
    "entropy": 0.42,
    "dominance": 0.31,
    "lineage_count": 7,
    "total_births": 12,
    "total_deaths": 5,
    "populations": { "L1": 3, "L2": 2, "L3": 2 }
  },
  "intervention_at_tick": false,
  "recorded_at": "<iso8601>"
}
```

The `ecology` map is the **real** `Tiannara.Ecology` snapshot (via `GenServer.call(pid, :get_snapshot)`). When the Ecology GenServer is not running, `ecology.status` is `:ecology_not_running` and other fields default to zero — this is recorded honestly, not fabricated.

### `intervention` (zero or more per run; CONTROL B/C only)

```json
{
  "type": "intervention",
  "campaign_id": "E03",
  "experiment_id": "E03-B-001",
  "tick": 1000,
  "intervention_id": "INT-B001-1000-001",
  "timestamp": "<iso8601>",
  "trigger": "dominance > 0.6",
  "detected_state": { "dominance": 0.62, "entropy": 0.38 },
  "metric_values": { "dominance": 0.62, "lineage_count": 6 },
  "decision": "niche_creation",
  "action": "create_niche",
  "magnitude": 0.15,
  "affected_population": ["L1"],
  "expected_effect": "dominance < 0.55 after 500 ticks",
  "actual_effect": null,
  "recovery_time": null,
  "downstream_effects": []
}
```

`actual_effect` and `recovery_time` are filled in by a subsequent checkpoint record (not by the intervention record itself). This separation is deliberate: the intervention record is the **act**; the checkpoint records are the **measurement of its effect**.

### `emergence` (zero or more per run; per candidate novel phenomenon per pre-registration §10)

```json
{
  "type": "emergence",
  "campaign_id": "E03",
  "experiment_id": "E03-B-001",
  "tick": 2500,
  "phenomenon_id": "EMG-B001-2500-001",
  "phenomenon_type": "novel_lineage_combination",
  "description": "Hybrid L1xL3 lineage emerged at tick 2500",
  "classification": "STABILIZER_ASSISTED",
  "classification_rationale": "Stabilizer intervention INT-B001-1000-001 created the niche; the hybrid lineage arose in that niche, but the combination itself was not directly forced.",
  "stabilizer_interventions_in_window": ["INT-B001-1000-001"],
  "intervention_dependence_score": 0.6,
  "endogenous_candidate": false,
  "recorded_at": "<iso8601>"
}
```

`classification` ∈ `ENDOGENOUS | STABILIZER_ASSISTED | STABILIZER_INDUCED | ARTIFICIAL_NON_EMERGENT | UNRESOLVED` (per pre-registration §10). `intervention_dependence_score` is a 0.0–1.0 heuristic assigned by the emergence-classification review (not by the harness). The classification is **never** automatically promoted to `ENDOGENOUS` by the harness.

### `run_end` (one per run)

```json
{
  "type": "run_end",
  "campaign_id": "E03",
  "experiment_id": "E03-B-001",
  "condition": "control_b",
  "seed": 42,
  "total_cycles": 10000,
  "trajectory_summary": {
    "stagnation_detected": false,
    "epistemic_drift": false,
    "governance_violations": 0,
    "monoculture_detected": false
  },
  "stopped_reason": "completed",
  "ended_at": "<iso8601>"
}
```

`stopped_reason` ∈ `completed | collapse_invariant | stop_condition_reached | external_signal`.

### `stop` (emitted if a stop condition from master prompt §22 is triggered)

```json
{
  "type": "stop",
  "campaign_id": "E03",
  "experiment_id": "E03-B-001",
  "tick": 1234,
  "stop_condition_index": 1,
  "stop_condition_text": "Measurement integrity becomes uncertain",
  "recorded_at": "<iso8601>"
}
```

### `error` (emitted on harness/ledger failures; never crash the run)

```json
{
  "type": "error",
  "campaign_id": "E03",
  "experiment_id": "E03-B-001",
  "tick": 1000,
  "error_class": "ecology_call_failed",
  "message": "...",
  "recorded_at": "<iso8601>"
}
```

## Hash binding (for replay)

`run_id` is computed as `sha256(campaign_id | experiment_id | seed | config_hash | code_revision)` per pre-registration §24. This appears in `run_start.config_hash` and is repeated in `run_end` for binding.

## What the ledger does NOT contain

- No hardcoded "decision" / "regret" / "chosen" / "actual" records (R3 remediation: the StrategicPlanner no longer emits them).
- No fabricated emergence classifications (always `UNRESOLVED` until human review).
- No log scraping — the ledger is the only authoritative record source.

## Append-only invariant

The ledger is opened with `[:append, :utf8]` and never truncated, rewritten, or re-opened for write by the harness. If the ledger file is corrupt or missing, the harness fails closed (no execution).
