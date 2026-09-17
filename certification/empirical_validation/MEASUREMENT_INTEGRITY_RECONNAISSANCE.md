# Measurement Integrity Remediation — Reconnaissance (R1)

**Mission:** TIANNARA — EMPIRICAL VALIDATION — MEASUREMENT INTEGRITY REMEDIATION (master prompt R1–R8).
**Phase:** R1 (live reconnaissance). No code modified. D1–D5 remain frozen `CERTIFIED_BOUNDED`.
**Date:** 2026-09-03 · **HEAD:** `3bd1601b9bb3c718f985d44ceaa8ef2e638d4ec6` · **App:** `:tiannara` v0.3.5

## 0. Method

Source inspection of the live repository (read-only). For each requested R1 question, the evidence is the actual file and line, not a filename or docstring. Where a question concerns a "caller" or "consumer", the evidence is a `grep` over the full `lib/` tree. Where the original Phase 3 probe transcript is the live runtime evidence, it is referenced.

The R1 scope is strictly the **StrategicPlanner → DecisionArchive** path. No other subsystem is touched.

---

## 1. The exact live code path

**Producer (the only caller in the entire codebase):**

`lib/tiannara/forecasting/planner.ex:40-48`

```elixir
def evaluate_and_act(scenario, _payload) do
  case scenario do
    :intervention_quality ->
      Logger.info("♟️ [Planner] Evaluating multiple intervention strategies...")
      chosen = "Quarantine node X"
      Logger.info("♟️ [Planner] Chose strategy: #{chosen}. Outperforms alternatives.")
      Aggregator.push_event([:tiannara, :forecasting, :intervention_effectiveness], 0.94)
      Aggregator.push_event([:tiannara, :forecasting, :regret_score], 0.04)
      DecisionArchive.record(%{predicted: "Stabilization",
                               chosen:   chosen,
                               actual:   "Stabilization",
                               regret:   0.04})
    ...
  end
end
```

**Target:**

`lib/tiannara/forecasting/auditor.ex:32-42`

```elixir
defmodule Tiannara.Forecasting.DecisionArchive do
  @moduledoc """
  The forecasting equivalent of ImmuneMemory or FossilRecord.
  Stores predicted outcome, chosen intervention, actual outcome, and regret score.
  """
  require Logger

  def record(decision) do
    Logger.debug("📜 [DecisionArchive] Persisting strategic decision record: #{inspect(decision)}")
  end
end
```

**Verdict on the "archive":** it is **not a persistent archive**. It is a **logging facade**: a single `Logger.debug` call. There is no `GenServer`, no `ETS`, no `DETS`, no on-disk store, no `:ets` table, no `start_link/0`. The `record/1` argument is interpolated into one log line and **immediately discarded by the function's tail**. The `moduledoc`'s claim that it "stores" the record is **false**; the implementation only logs it.

---

## 2. R1 question-by-question

### 2.1 Every caller of `DecisionArchive`

Repo-wide grep (lib/, *.ex) for `DecisionArchive`:

| File | Line | Reference |
|---|---|---|
| `lib/tiannara/forecasting/auditor.ex` | 32 | definition (`defmodule Tiannara.Forecasting.DecisionArchive`) |
| `lib/tiannara/forecasting/auditor.ex` | 40 | implementation (`def record(decision)`) |
| `lib/tiannara/forecasting/planner.ex` | 38 | `alias Tiannara.Forecasting.DecisionArchive` |
| `lib/tiannara/forecasting/planner.ex` | 48 | **the only call** — `DecisionArchive.record(%{...})` |

**There is exactly one caller in the entire codebase:** the `:intervention_quality` branch of `Tiannara.Forecasting.StrategicPlanner.evaluate_and_act/2`.

### 2.2 Every consumer (read side)

**No module reads from `DecisionArchive`.** There is no reader function at all — the module exposes only `record/1`. Repo-wide grep for `DecisionArchive.` returns only the two writer-side matches (alias + record). There is no `DecisionArchive.read/0`, no `DecisionArchive.list/0`, no `DecisionArchive.query/0`.

### 2.3 Every field written

| Field | Value | Origin |
|---|---|---|
| `predicted` | `"Stabilization"` | hardcoded string literal in planner.ex:48 |
| `chosen` | `"Quarantine node X"` | hardcoded string literal in planner.ex:44 |
| `actual` | `"Stabilization"` | hardcoded string literal in planner.ex:48 |
| `regret` | `0.04` | hardcoded float in planner.ex:48 |

**All four fields are constants in the source.** None are computed from `_payload`, the scenario branch, or any other input.

### 2.4 Every field read

**None.** No reader exists.

### 2.5 Whether records carry provenance

**No.** The map written to `DecisionArchive.record/1` is `%{predicted, chosen, actual, regret}`. It carries no `kind`, no `provenance` field, no `source`, no `producer`, no `produced_at`, no `execution_id`, no `experiment_id`, no `evidence_hash`, no `audit_trail`. The `Tiannara.Evidence.Provenance` schema (`lib/tiannara/evidence/provenance.ex:15-32`) defines a `provenance_kind` taxonomy `:real_execution | :simulation | :synthetic_fixture | :imported_evidence | :unknown`, but **the planner does not call `Provenance.build/1` and does not pass a provenance record at all.**

### 2.6 Whether records can be distinguished as synthetic

**No — and that is the defect.** The log line emitted by `DecisionArchive.record/1` reads:

```
📜 [DecisionArchive] Persisting strategic decision record:
  %{actual: "Stabilization", chosen: "Quarantine node X", predicted: "Stabilization", regret: 0.04}
```

A log scraper, a log-shipping pipeline, an observability tool, or any human reading the logs would see "decision record" with a value that *looks* like a measured record. There is **no in-line marker** indicating the record is fabricated / simulated / synthetic / replay. The only contextual hint is the class name "DecisionArchive" and the emoji "📜", neither of which conveys provenance.

### 2.7 Whether records can reach D3 / D4 / D5

In-process: **No.** None of the D1–D5 modules reads `DecisionArchive` (the only references to `DecisionArchive` in the entire `lib/` tree are the two writer-side matches in `planner.ex` and the definition in `auditor.ex`). D3 (`Tiannara.Forecasting`), D4 (`Tiannara.Forecasting.Counterfactual` / `Attribution` / `RegressionToMean` / `TemporalFirewall`), and D5 (`Tiannara.Forecasting.D5.*`) do not import, alias, call, or reference `DecisionArchive`.

Via logs: **Yes, in principle.** A downstream log-shipping pipeline, an observatory that scrapes log lines, or a future consumer that ingests logs as evidence could read the line and treat the `actual: "Stabilization"`, `regret: 0.04` values as measurements. The risk surface is the **log output**, not the in-process archive.

### 2.8 Whether records can enter empirical evidence

The `Tiannara.Evidence.Provenance.acceptable_as_evidence?/1` predicate (`provenance.ex:93-96`) is the single gate for whether a record counts as scientific evidence:

```elixir
def acceptable_as_evidence?(%{kind: :real_execution}), do: true
def acceptable_as_evidence?(%{kind: :imported_evidence, source: s})
    when is_binary(s) and s != "", do: true
def acceptable_as_evidence?(_), do: false
```

Because the planner record carries **no provenance record at all** (no `kind` field, no source, nothing that satisfies the `:real_execution` shape), any code that ran the record through `Provenance.build/1` would receive `{:error, {:invalid_provenance_kind, nil}}` (provenance.ex line 110) and therefore `acceptable_as_evidence?` would return `false`. **The existing provenance gate already rejects bare records.**

The defect is therefore **not** that the record passes the evidence gate; it is that the record **never goes through the evidence gate** because the planner does not call `Provenance.build/1` at all. Any future consumer that **assumes** "this is a measured record because it has a regret value and an actual field" — without running it through `Provenance` — could be misled.

### 2.9 Whether records can influence metrics

Partially. The same `evaluate_and_act/2` call (planner.ex:46-47) also does:

```elixir
Aggregator.push_event([:tiannara, :forecasting, :intervention_effectiveness], 0.94)
Aggregator.push_event([:tiannara, :forecasting, :regret_score], 0.04)
```

These push hardcoded metrics to `Tiannara.Metrics.Aggregator`. Per the Phase 0 recon (I-12), `metrics/aggregator.ex` is a real GenServer but the relevant cast clauses for the simulated `:forecasting` events are **no-op drops** (`{:noreply, state}`). So the hardcoded metrics are **never actually recorded** into the metrics store. The aggregator's `metrics/export.ex` → `data/metrics_snapshot.ndjson` would never see these.

The Phase 3 recon (I-18) further confirmed that the root `metrics_export.csv` contains only a single 1-row placeholder.

**Net:** the hardcoded metrics pushed to `Aggregator` are not stored, and the hardcoded "decision record" is only a log line. The defect is the **log line's format**, not the persistence layer.

### 2.10 Whether records can influence future decisions

**No, in the current code.** The DecisionArchive has no read API, and no module reads it. The MetaGovernor's `ForecastConsumer.consume/2` (in `lib/tiannara/meta_governor/systems.ex:35-60`) claims in its moduledoc to "Integrate with the StrategicPlanner to govern based on forecasted consequences", but its implementation is **another theatrical scenario handler** (logs + pushes a constant `:forecast_integration_gain` 0.25 to a no-op aggregator). It does **not** read `DecisionArchive`.

A **second** StrategicPlanner exists at `lib/tiannara/asc/forecasting/strategic_planner.ex` (`Tiannara.ASC.Forecasting.StrategicPlanner`) — this one is genuinely algorithmic (real `CounterfactualSimulator.simulate_future/3`, real `CollapsePredictor.calculate_risk_of_ruin/1`, real logging). It does **not** call `DecisionArchive.record`. It lives in the **ASC subsystem**, which the application supervisor starts only if `Application.get_env(:tiannara, :asc, [])[:enabled]` is true — and the default is `false` (see `Tiannara.Application.asc_enabled?/0`). So this second planner is **real but disabled by default**, and it is not the source of the fabrication.

---

## 3. R1 summary: the actual defect surface

| Question | Answer |
|---|---|
| Caller of `DecisionArchive` | ONE: `Tiannara.Forecasting.StrategicPlanner.evaluate_and_act(:intervention_quality, _)` at `planner.ex:48` |
| Consumer of `DecisionArchive` | NONE (no read API; no module reads it) |
| Fields written | `predicted`, `chosen`, `actual`, `regret` — all hardcoded literals in the source |
| Fields read | NONE |
| Provenance on record | NONE — no `kind`, no `source`, no `producer`, no `execution_id`, no `evidence_hash` |
| Distinguishable as synthetic? | NO — the log line *looks* like a measured record; no in-line marker |
| Reaches D3/D4/D5 in-process? | NO (in-process archive is write-only, no reader) |
| Reaches empirical evidence? | NO via the existing `Provenance.acceptable_as_evidence?/1` gate (which rejects bare records) — but YES in principle for any consumer that reads logs without going through `Provenance` |
| Reaches metrics? | NO — the hardcoded pushes go to `Aggregator` cast clauses that are no-op drops |
| Reaches future decisions? | NO — no in-process reader; the only consumer (`ForecastConsumer.consume/2`) is itself theatrical and does not read `DecisionArchive` |

**Severity, re-assessed honestly:** the Phase 3 report's framing of "storage-layer fabrication poisoning downstream measurement" is **partly overstated**. The DecisionArchive is **not a persistent archive** — it is a **logging facade**. There is no on-disk state, no in-memory ETS/DETS, and no in-process consumer. The fabricated record lives **only as one log line per call** with a format that *looks* like a measured record.

The real defect is narrower: the planner **emits a log line whose content (chosen strategy, regret, actual outcome) is fabricated**, with **no provenance marker**, in a format that **masquerades as a measured decision record**. This is a **log-format integrity defect** that could mislead any log-shipping, observatory, or future consumer that ingests logs as evidence.

---

## 4. Existing mechanisms available for R2

The recon identified three relevant existing mechanisms in the live codebase:

| Mechanism | Location | Pattern |
|---|---|---|
| **Provenance gate** | `lib/tiannara/evidence/provenance.ex:93-96` | `acceptable_as_evidence?/1` returns `true` only for `:real_execution` (with `execution_id`) and `:imported_evidence` (with non-empty `source`). All other shapes return `false`. |
| **R0 quarantine** | `lib/tiannara/research/research_director.ex:171-179` | `quarantine_experiment/1` logs a warning, emits telemetry, and **does not persist a fabricated result**. The reason is `:fabrication_path_disabled`. |
| **Provenance fallback** | `lib/tiannara/evidence/provenance.ex:71-84` | `Provenance.unknown/1` returns a record with `kind: :unknown` and `audit_trail: ["unknown_provenance: #{reason}"]`. This is the honest fallback for "I don't know where this came from." |

**These three mechanisms exist and are usable. R2 must choose the minimum change that uses them (or a simpler approach if sufficient) and does not invent a fourth architecture.**

---

## 5. Non-goals honored (R1)

- No code modified.
- D1–D5 remain frozen `CERTIFIED_BOUNDED`.
- No caller of `DecisionArchive` was added, removed, or changed.
- No reader of `DecisionArchive` was added (none existed; none invented).
- No new subsystem was introduced.
- The Phase 3 E06/E07 findings (FALSIFIED) are **not altered** by R1.
- R1 produces only this document; R2 onward require separate authorization per the master prompt's STOP discipline.
