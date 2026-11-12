# TCP-002.3 — EFDI Canonical Forecasting Integration: Implementation Report

**Checkpoint:** TCP-002.3 — EFDI Canonical Forecasting Integration, Research Connectivity and Institutional Calibration
**Workstream:** W0 — Activate Existing Capabilities
**Status:** **PARTIAL** — Stages 0–2 and the Stage 3 information-gain remediation are delivered; Stages 3–12 remain open.
**Date:** 2026-11-12

---

## 1. What this checkpoint did and did not do

TCP-002.3 was instructed as an integration and operationalization checkpoint
with EFDI as the canonical owner. It was explicitly **not** to build a second
forecasting engine, and the implementation order was to begin with the
source-and-caller inventory.

**Delivered:**

| Stage | Deliverable | State |
|-------|-------------|-------|
| 0 | `TCP_002_3_SOURCE_AND_CALLER_INVENTORY.md` + `TCP_002_3_EFDI_INVENTORY.{csv,md}` | Done |
| 1 | `TCP_002_3_EFDI_CONTRACT_AUDIT.md` | Done |
| 2 | Canonical cross-stack boundary (application bridge + runtime port + NATS transport) | Done |
| 3.1 | Information-gain honesty remediation | Done |
| 5 (partial) | Durable forecast registry: full forecast persisted, replay on start, truthful health | Done |
| 10 (partial) | Spine invokes EFDI through the governed port; confidence and probability stay distinct | Done |
| 11 (partial) | Unit, contract, integration and adversarial tests for the delivered surface | Done |
| 3.2–3.4, 4, 6, 7, 8, 9, 12 | Research Director connectivity, outcome acquisition, calibration against eligible forecasts, governed model update, end-to-end demonstration | **Open** |

The checkpoint is therefore recorded as **PARTIAL**, not complete. The
definition-of-done criteria in the directive are listed with their state in
§6.

## 2. The central architectural finding

EFDI **is** `Tiannara.Forecasting`. It is not a second forecasting engine
beside the forecasting machinery; it is the epistemic coordination layer over
it, implemented under the same namespace. This was verified against the source
rather than the architecture documents.

The inventory of 70 EFDI modules produced the finding that reframed the
checkpoint:

| Measure | Value |
|---|---|
| Modules with a test reference | 27 of 70 |
| Modules with a caller outside the forecasting directory | 27 of 70 |
| Modules with **no** external caller | **43 of 70** |
| Modules with **any** persistence | **5 of 70** |

So the canonical forecasting authority is real, substantial, and almost
entirely unreachable — and what it does hold in memory, it does not keep.

## 3. The cross-stack boundary

The two stacks have no compile-time dependency in either direction, and
**cannot have one yet**: 28 module names are defined in both
(`Tiannara.Sentinel.*`, `Tiannara.OED.*`, `Tiannara.A10.*`,
`Tiannara.CIS.*`, `Tiannara.P9X.*`, `Tiannara.Core.Ontology.Index`,
`Tiannara.Meta.CausalTensegrityEngine`, `CivilizationState`). A single BEAM
would redefine them. That consolidation is TCP-002's **W1** and must precede
any merge (`TCP-B-046`).

The boundary is therefore a **versioned, transport-agnostic contract**:

- **Application side** — `Tiannara.Forecasting.Bridge`. `handle_request/1`
  takes a decoded map and returns a decoded map. It validates, invokes the
  canonical EFDI API, registers the forecast durably, and never performs
  forecasting mathematics itself.
- **Runtime side** — `TiannaraRuntime.Cognitive.Spine.Forecasting`, a port with
  a refusing default, plus a NATS transport with correlation ids, timeouts
  and explicit unavailability.

Both sides pin schema version **1** and the same field lists. Only JSON
crosses the boundary: no struct, no atom, no executable term.

### 3.1 The guarantees the contract provides

| Guarantee | How |
|---|---|
| Typed requests and responses | Explicit field lists, pinned on both sides |
| Schema/version identification | `"v" => 1`, refused with `:unsupported_schema_version` |
| Correlation | `request_id`; the NATS response subject is derived from it |
| Idempotency | The request id indexes its forecast; a repeat returns the original |
| Conflict refusal | A reused request id with **different** content is refused with `:request_id_conflict`, not replayed |
| Timeouts | `:forecast_engine_timeout` |
| Explicit unavailable states | `:forecast_engine_unavailable`, `:missing_reference_class`, `:missing_outcomes`, … |
| Request provenance | `provenance.origin` is required; the bridge refuses a request without it |
| Traceable errors | Every refusal carries a reason and a message |
| No untrusted terms | JSON only, in both directions |

### 3.2 The distinction the boundary protects

The runtime Spine already had an **evidence-confidence** capability and an
**uncertainty decomposition**. Neither is a probabilistic forecast:

- confidence asks *how strongly does the available evidence support this?*;
- a forecast asks *how likely is this specified outcome over this horizon?*

The Spine's forecast stage now reports both, separately, and never converts
one into the other. When EFDI is unreachable, the port reports
`{:error, :forecast_engine_unavailable}` — the Spine does not substitute the
confidence score, and it reports the investigation as **not complete**:
`unavailable_capabilities: [:probabilistic_forecast]`, `complete?: false`.

## 4. Defects found and repaired

| # | Defect | Repair |
|---|--------|--------|
| **F-01** | The forecast registry deleted its ETS table on every `init/1` and stored only the forecast id in the durable lineage. History was lost on restart *and* was unrecoverable from the log. | The EventStore log is now the record of truth (full forecast persisted); `init/1` replays it; `recover/0` exposes the replay; `count/0` reports registrations, not index size. |
| **F-02** | `ResearchImpl.information_gain_estimate/2` returned `{:ok, 1.0 / length(existing)}` — a heuristic presented as a measurement — in the `:ok` slot. | The fallback is now the contract's honest `{:error, :insufficient_data}`. The measured path is unchanged. Both the empty and non-empty cases are now tested; the pre-existing test only covered the empty case. |
| **F-03** | `ForecastRegistry.health/0` reported `eventstore_degraded: false` unconditionally while the lineage append swallowed every failure. | A failed append logs and sets the flag; `health/0` reports `eventstore_degraded`, `durable`, `forecast_count` and `recovered_count`. |
| **F-05** | `Tiannara.Forecasting.ForecastRegistry` was not supervised, so `register_forecast/1` raised `no process` — the canonical forecasting subsystem could not run in the application at all. | The registry and the bridge are supervised. The registry is behind `:supervise_forecast_registry` (true by default, false in test) so the forecasting suites keep per-test isolation. |
| **F-06** | The Spine's forecast stage could not obtain a probabilistic forecast at all. | The forecasting port, wired into the stage. |

**Not modified**, because they are correct and were reused: `ModelUpdateGate`,
`OutcomeResolution`, `TemporalFirewall`, `Calibration`, `ForecastEngine`,
`BaseRateEngine`, `DecisionEngine`, `Contracts`, and the D4/D5 components.

## 5. A note on the environment

The application stack did not compile at the start of this checkpoint, and
the cause was **not** a code defect: `_build/test/lib` held zero compiled
dependencies, so `@derive Jason.Encoder` could not resolve. The 56 dependency
sources were present but had never been built. The compiled dependencies were
restored from the CP19.20 worktree; the application then compiled cleanly
(1 658 files).

This is recorded because it means **no application-stack evidence could have
been produced for any earlier checkpoint** without this repair, and because
it is exactly the shape of failure that is mistaken for a defect.

## 6. Definition-of-done criteria

| Criterion | State |
|-----------|-------|
| EFDI inventoried and its canonical API established | **Done** |
| Existing forecasting and calibration components reused | **Done** — none reimplemented |
| Runtime/application integration operational | **PARTIAL** — the contract and both adapters exist; the NATS transport is compiled but not exercised end-to-end (no NATS server in this environment) |
| Research Director creates genuine EFDI forecast requests | **Open** |
| Evidence and signal provenance preserved | **Done at the boundary** — `provenance.origin` is required, evidence carries an epistemic status |
| Forecast targets and resolution contracts explicit | **Done** — `outcomes` and `horizon` are required; a missing outcome contract is refused |
| Forecasts durably registered and recoverable | **Done** — full forecast persisted, replay on start; the adversarial persistence suite is still open |
| Historical forecasts remain immutable | **Done** — the registry refuses to overwrite an id |
| Outcomes acquired through real or classified sources | **Open** |
| Temporal isolation verified | **Open** — `TemporalFirewall` exists; the adversarial leakage suite is open |
| Independent outcome resolution | **Open** |
| Calibration executes against eligible resolved forecasts | **Open** — the machinery exists and has never run |
| Statistical limitations and sample sizes reported | **Open** |
| Model-update assessments use actual performance evidence | **Open** — `ModelUpdateGate` assesses; the approval path is not wired |
| Model improvements remain approval-bound | **Done** — `ModelUpdateGate` is unchanged and non-authorizing |
| Knowledge integration uses the canonical lifecycle | **Open** |
| The Spine invokes EFDI through the governed adapter | **Done** |
| Confidence and probabilistic forecasting remain distinct | **Done** |
| End-to-end investigation reproducible | **Open** |
| Adversarial and persistence/recovery tests pass | **PARTIAL** — boundary-level adversarial tests pass; the registry persistence suite is open |
| Affected regression suites pass | **Done** |
| Evidence manifests and digests complete | **PARTIAL** — see §7 |
| Independent verification performed | **Open** — none available |

## 7. Evidence

| Suite | Result |
|-------|--------|
| Application `test/tiannara/forecasting` | **414 tests, 0 failures** (seed 0); 390 before this checkpoint |
| Runtime `test/{simulation,runtime_layers,kernel,cognitive,world_model}` | **792 tests, 32 properties, 0 failures** (seed 0) |

New tests: 21 bridge, 3 research-adapter honesty, 8 forecasting-port — 32 in
total, covering exact refusals, idempotency, conflict refusal, base-rate
honesty, the unknown-probability distinction, port unavailability, and the
confidence/probability separation.

The **NATS transport is compiled but not executed**: no NATS server is
available in this environment. The transport's behaviour under an absent
authority is covered by the refusing default instead.

## 8. Register

52 rows: 39 open, 12 resolved, 1 partial. New in TCP-002.3: `TCP-B-041` …
`TCP-B-052`.

## 9. Disposition

**`IMPLEMENTED_WITH_PARTIAL_EVIDENCE` / `VERIFICATION_BLOCKED`.**

The checkpoint is explicitly **not complete**. The central architectural
question — whether EFDI is the canonical forecasting authority — is answered
**yes**, and the boundary that makes it reachable from the cognitive runtime
is in place and tested. The operational half — a forecast that is resolved
against a real observed outcome and scored — is not yet demonstrated, and
that is the work that remains.

RL-565 remains `HIGH / OPEN`. RL-564 and `F-ARC-018` remain `OPEN`. No
merge, deployment, registry promotion or physical actuation was performed.
