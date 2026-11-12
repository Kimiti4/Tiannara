# TCP-002.3 — Stage 1: EFDI Architecture and Contract Audit

**Checkpoint:** TCP-002.3
**HEAD at audit:** `3820a04c9cdb2e9bf51fb99e3362a10e8ce77c87` (plus the TCP-002.3 changes listed in §6)
**Companion:** `TCP_002_3_SOURCE_AND_CALLER_INVENTORY.md`

---

## 1. Summary

EFDI is **not** a second forecasting engine competing with
`Tiannara.Forecasting`. It *is* `Tiannara.Forecasting`, and its components
are individually well designed. The audit found **three genuine defects**,
**one architectural gap**, and a set of **activation gaps** that together
explain why the canonical forecasting authority is not reachable.

| # | Finding | Class | Severity |
|---|---------|-------|----------|
| F-01 | The forecast registry deleted its ETS table on every `init/1` and stored only the forecast id in the durable lineage, so forecast history was lost on restart *and* could not have been recovered from the log even if it had been kept. | durability | Critical |
| F-02 | `ResearchImpl.information_gain_estimate/2` returned `{:ok, 1.0 / length(existing)}` when no measured information gain was available — a heuristic presented as a measurement. | false-success | Critical |
| F-03 | `ForecastRegistry.health/0` reported `eventstore_degraded: false` unconditionally; the lineage append swallowed every failure. | false-success | High |
| F-04 | The application stack has no compile-time path to the runtime stack, and cannot have one yet because 28 module names are defined in both. | architectural gap | Critical |
| F-05 | `Tiannara.Forecasting.ForecastRegistry` and `Tiannara.Forecasting.Bridge` were not in the application's supervision tree, so the canonical forecasting subsystem could not run in the application at all. | activation | Critical |
| F-06 | The runtime Spine's forecast stage called only `ConfidenceEstimator`/`UncertaintyAnalyzer`; there was no path by which a probabilistic forecast could be obtained. | activation | Critical |
| F-07 | `efdi.ex`'s moduledoc still states *"D1 STOPS here and does not forecast, calibrate, decide"* while the module implements all three. | documentation | Low |
| F-08 | D6 institutional forecasting memory is deferred, and 65 of 70 EFDI modules hold no state across a restart. | capability gap | High |

## 2. What is genuinely good and must be reused

The audit confirmed that the directive's caution — *"if an existing engine is
defective, repair it at its canonical ownership location"* — applies to
components that are already correct:

- **`ModelUpdateGate`** is a properly non-authorizing gate. It returns
  `authority: :none`, `authorization: :not_granted`, `deployment: :not_granted`,
  `production_mutation: :forbidden`, `human_review_required: true`,
  `acl_required: true`, `oavl_required: true`, `cel_required: true`,
  `certification_eligible: false`. It requires independent evidence for
  temporal performance, calibration, drift and holdout behaviour, and keeps
  missing evidence `UNKNOWN` rather than letting it become `PASS`. **This is
  the approval boundary the programme needs. It was not modified.**
- **`ForecastEngine.base_rate_prior/2`** refuses to fabricate a uniform
  justification when the base rate cannot be justified, returning
  `:unknown` with `:base_rate_outc[hange]_mismatch`. The audit confirmed that
  an absent base rate yields `:unknown` probabilities rather than an invented
  distribution, and that the boundary carries `:unknown` across as the
  **string** `"unknown"` — distinct from `0.0`.
- **`OutcomeResolution`** returns `:resolved_not_certified` and
  `:requires_independent_review`. A single resolution cannot establish
  calibration; that is correct and must not be weakened.
- **`TemporalFirewall`** separates decision-time from outcome-time evidence.
- **`Forecast.validate/1`** rejects out-of-bounds probabilities, outcome/
  probability count mismatch and un-normalised distributions.

## 3. Defects in detail

### 3.1 F-01 — forecast history was not durable

`ForecastRegistry.init/1` began with:

```elixir
if :ets.info(@table) != :undefined, do: :ets.delete(@table)
:ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
```

and the durable lineage event carried only `{forecast_id, question, version}`.

The registry was therefore **ephemeral and unrecoverable**: a restart lost
every forecast, and the event log could not have been replayed to restore
them even if it had been retained.

**Fix (applied).** The ETS table is now an *index*; the
`Tiannara.Executive.EventStore` log is the record of truth:

- the full forecast is persisted in the event (`forecast_binary`);
- `init/1` replays the log and rebuilds the index, the request index and the
  recovered count;
- `recover/0` exposes the replay explicitly;
- `count/0` reports *registrations made through this process*, not the size of
  the index — restoring history is not a registration.

### 3.2 F-02 — a heuristic presented as measured information gain

```elixir
def information_gain_estimate(%Signal{} = signal, existing) when is_list(existing) do
  case SignalValue.measure(signal) do
    %{information_gain: g} when is_number(g) -> {:ok, g}
    _ -> if existing == [], do: {:error, :insufficient_data}, else: {:ok, 1.0 / length(existing)}
  end
end
```

`1.0 / length(existing)` is a reciprocal of the size of the existing set. It
is not an information gain. Returning it in the `:ok` slot made an unmeasured
quantity indistinguishable from a measured one to every caller — including any
caller that uses it to choose the next investigation.

**Fix (applied).** The fallback is now `{:error, :insufficient_data}`, which
is the state the behaviour contract already declares. The measured path is
unchanged.

The audit also found that the *existing* test
(`d2_integration_test.exs`, *"ResearchImpl information gain estimate is
honest"*) only exercised the **empty** `existing` case, so the heuristic path
was never tested. `research_adapter_honesty_test.exs` now covers both.

### 3.3 F-03 — health reported durability that was not there

`health/0` returned `eventstore_degraded: state.eventstore_degraded`, and that
field was only ever set to `false`. `maybe_append_event/2` wrapped the append
in `try/catch ... -> :ok`, so a failing event store was silently ignored and
the registry reported itself as healthy while holding forecasts that existed
only in memory.

**Fix (applied).** A failed append logs an error and sets
`eventstore_degraded: true`. `health/0` now reports `eventstore_degraded`,
`durable: not eventstore_degraded`, `forecast_count` and `recovered_count`.

### 3.4 F-04 — the cross-stack boundary

The application stack (`lib/`, `:tiannara`) and the runtime stack
(`tiannara_runtime/`, `:tiannara_runtime`) have **no dependency in either
direction**. A compile-time dependency from the runtime to the application is
currently impossible: 28 module names are defined in both stacks, and a
single BEAM would redefine them. That consolidation is TCP-002's **W1**, and
it must precede any attempt to merge the stacks.

**Decision.** The boundary is a **versioned, transport-agnostic contract**
owned by the application stack:

- `Tiannara.Forecasting.Bridge` (application) — `handle_request/1` takes a
  decoded map and returns a decoded map. It can be served over NATS, HTTP or
  anything else without changing the contract.
- `TiannaraRuntime.Cognitive.Spine.Forecasting` (runtime) — a port with a
  refusing default and a NATS transport.

Both sides pin the same schema version (1) and the same field lists. The
contract is JSON-only in both directions; no struct and no executable term
crosses the boundary.

## 4. Contract disagreements found

| # | Disagreement | Resolution |
|---|--------------|------------|
| C-01 | The confidence engines and the forecasting engines have no shared vocabulary. `ConfidenceEstimator` estimates confidence from evidence quality; `ForecastEngine` produces a probability over declared outcomes. | Kept **distinct and separate**. The Spine reports both, and never converts one into the other. |
| C-02 | `Contracts.Forecast` is a struct containing atoms (`:unknown`), tuples and `DateTime` values, none of which can be transmitted faithfully. | An explicit JSON-safe wire format, with `:unknown` carried as the string `"unknown"` and documented as distinct from `0.0`. |
| C-03 | `Contracts.BaseRate` is read by dot access; the wire format has string keys. | EFDI's own `BaseRateEngine.new/1` is reused rather than re-implemented, so the bridge cannot drift from EFDI's defaults. |
| C-04 | `Forecast.new/1` reads `:probabilities` by dot access; `Map.new/2` on a struct raises. | The bridge converts with `Map.from_struct/1` before mapping. |
| C-05 | The runtime's `CognitiveContext` requires a **string** mission; `GoalDecomposer` requires a **map**. | The Spine normalises at the seam (`TCP-B-038`). |

## 5. Activation gaps

| Component | State before this checkpoint |
|---|---|
| `Tiannara.Forecasting.ForecastRegistry` | **Not supervised.** `register_forecast/1` from the application raised `no process`. The canonical forecasting subsystem could not run. |
| `Tiannara.Forecasting.Bridge` | Did not exist. There was no cross-stack entry point at all. |
| Runtime Spine forecast stage | Used `ConfidenceEstimator`/`UncertaintyAnalyzer` only. A probabilistic forecast was unreachable. |
| EFDI's 43 externally-unused modules | Unreachable from the application, from the runtime, and from each other. |
| D6 institutional memory | Deferred. |

## 6. Changes made in this checkpoint

| File | Change |
|------|--------|
| `lib/tiannara/forecasting/bridge.ex` | **New.** The canonical cross-stack boundary: versioned request/response contract, validation with exact typed errors, EFDI invocation, durable registration, idempotency by request id, conflict refusal. |
| `lib/tiannara/forecasting/forecast_registry.ex` | Durable lineage (full forecast persisted), replay on start, request index, truthful degradation in `health/0`, `count/0` semantics corrected, `recover/0`. |
| `lib/tiannara/forecasting/efdi.ex` | `register_forecast/2` accepting request metadata. |
| `lib/tiannara/forecasting/adapters/research_impl.ex` | The information-gain heuristic replaced by the honest `:insufficient_data` state. |
| `lib/tiannara/application.ex` | The EFDI bridge and the forecast registry are supervised (the registry behind `:supervise_forecast_registry`, disabled in test so the forecasting suites keep per-test isolation). |
| `config/config.exs`, `config/test.exs` | `:supervise_forecast_registry`. |
| `tiannara_runtime/lib/tiannara_runtime/cognitive/spine/forecasting.ex` | **New.** The runtime port, with a refusing default. |
| `tiannara_runtime/lib/tiannara_runtime/cognitive/spine/forecasting/nats.ex` | **New.** The NATS transport with correlation, timeout and explicit unavailability. |
| `tiannara_runtime/lib/tiannara_runtime/cognitive/spine/cognitive_execution_spine.ex` | The forecast stage now requests a probabilistic forecast through the port, keeps confidence distinct from probability, and reports unavailable capabilities rather than claiming completion. |
| `tiannara_runtime/test/cognitive/spine/forecasting_port_test.exs` | **New.** 8 tests. |
| `test/tiannara/forecasting/bridge_test.exs` | **New.** 21 tests. |
| `test/tiannara/forecasting/research_adapter_honesty_test.exs` | **New.** 3 tests. |

**Not modified:** `ModelUpdateGate`, `OutcomeResolution`, `TemporalFirewall`,
`Calibration`, `ForecastEngine`, `BaseRateEngine`, `DecisionEngine`,
`Contracts`, and the D4/D5 components. They are correct and were reused.

## 7. Verification

| Suite | Seed 0 | Seed 123456 |
|-------|--------|-------------|
| Application: `test/tiannara/forecasting` | **414 tests, 0 failures** | see §8 |
| Runtime: `test/{simulation,runtime_layers,kernel,cognitive,world_model}` | **792 tests, 32 properties, 0 failures** | see §8 |

The application's forecasting suite grew from 390 to 414 tests: the 24 new
tests are the bridge (21) and the research adapter honesty (3).

## 8. What remains open

TCP-002.3 is **not** complete. The following stages are outstanding and are
registered as blockers:

- **Research Director → EFDI** integration (the director does not yet create
  EFDI forecast requests).
- **Outcome acquisition providers** — there is no source of observed outcomes
  wired to `OutcomeResolution`.
- **Calibration against eligible resolved forecasts** — the pipeline exists
  but has never run against real resolutions.
- **Governed model-update workflow** — `ModelUpdateGate` assesses; nothing
  carries an assessment into the approval path.
- **Durable registry adversarial suite** — corruption, truncation, replay,
  duplicate and concurrent-registration tests are not yet written.
- **Independent verification** — none.

RL-565 remains `HIGH / OPEN`. RL-564 and `F-ARC-018` remain `OPEN`.
