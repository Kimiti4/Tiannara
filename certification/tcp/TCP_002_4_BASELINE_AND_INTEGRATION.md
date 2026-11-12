# TCP-002.4 — Baseline, Lifecycle Contract, and Research Integration

**Checkpoint:** TCP-002.4 — Research-to-Forecast Operational Closure
**Starting commit:** `4e24f3277ec3f0f40da8d7846b14a63b9ffb9a6d`
**Status:** PARTIAL — Stages 0–3 delivered; Stages 4–13 open.

---

# Stage 0 — Repository baseline

| Item | Value |
|------|-------|
| Repository | `Kimiti4/Tiannara` |
| Branch | `feat/tcp-001-completion-programme` |
| Starting HEAD | `4e24f3277ec3f0f40da8d7846b14a63b9ffb9a6d` |
| Parent | `3820a04c9cdb2e9bf51fb99e3362a10e8ce77c87` |
| Working tree | 1 840+ pre-existing dirty paths (unrelated artefacts, generated checkpoints, audit backups) — **not staged** |
| Build state | Application stack compiles (1 658 files); runtime stack compiles (1 239 files) |
| Disk at start | ~2.7 GB free |

## 0.1 Revalidation of the TCP-002.3 baseline

| Claim | Revalidated? | Evidence |
|-------|--------------|----------|
| TCP-002.3 commit present | Yes | `4e24f327` is HEAD and is the parent of this checkpoint |
| EFDI is `Tiannara.Forecasting` | Yes | `lib/tiannara/forecasting/efdi.ex`, unchanged |
| EFDI inventory = 70 modules | Yes | `tools/tcp/tcp0023_efdi_inventory.py` re-runnable |
| Application forecasting tests = 414 | Yes, and now **428** (14 adversarial durability tests added here) | `mix test test/tiannara/forecasting` → 428 tests, 0 failures |
| Runtime regression = 792 + 32 properties | Yes, unchanged by this checkpoint | runtime suite green |
| Runtime bridge is versioned JSON, schema v1 | Yes | `TiannaraRuntime.Cognitive.Spine.Forecasting` |
| NATS transport compiled, not executed | Yes | no NATS server available in this environment |
| `ModelUpdateGate` forbids production mutation | Yes | unchanged and not modified by this checkpoint |

**Divergence found.** The TCP-002.3 report recorded the application stack as
"not compiling" as a *finding about the start of TCP-002.3*. At the start of
TCP-002.4 the application stack **does** compile, because TCP-002.3 repaired the
dependency build state. No divergence in substance.

## 0.2 The real Research Director path

Traced from source (`lib/tiannara/research/research_director.ex`):

```
priorities  ──▶ HypothesisRanker.generate_from_priorities/1  (hypotheses)
             ──▶ HypothesisRanker.rank/1
             ──▶ ResearchQueue.enqueue(:hypothesis, h)
advance()   ──▶ ExperimentPlanner.plan(hypothesis)             (experiment)
             ──▶ ResearchQueue.enqueue(:experiment, e)
advance()   ──▶ quarantine_experiment/1                        (R0 quarantine)
```

`Tiannara.Research.ResearchDirector` **is** in the application's supervision
tree (`lib/tiannara/application.ex:246`), so the real path is the supervised
one.

Two facts about the existing hypotheses shape the integration:

1. **A hypothesis is a causal claim, not a forecastable proposition.**
   `statement` reads *"The observed X behaviour in Y is caused by an
   identifiable and addressable factor"* and `falsification_criteria` describes
   a controlled experiment. There is no outcome space, no horizon, and no
   measurable proposition. Forcing a forecast onto this text would produce a
   forecast about an unmeasurable proposition.

2. **Two quantities on a hypothesis are hardcoded constants presented as
   measurements.** `confidence: 0.5` for every hypothesis, and `eig_score`
   values of 0.8 / 0.7 / 0.75 / 0.85 / 0.6 chosen per domain branch. These are
   heuristics, not measurements. They are recorded as findings, not silently
   "fixed", because the correct value depends on a measurement that does not
   exist (`TCP-B-055`).

---

# Stage 1 — Canonical lifecycle contract

## 1.1 The lifecycle

```
ResearchQuestion → EvidenceSet → ForecastRequest → Forecast
   → RegisteredForecast → OutcomeObservation → VerifiedOutcome
   → ResolvedForecast → ForecastScore
```

Each object, its identity and its owner:

| Object | Identity | Owner | Existing canonical structure |
|--------|----------|-------|---------------------------|
| ResearchQuestion | research input id (`source_priority_id`) | `Tiannara.Research` | priority map, `HypothesisRanker` |
| EvidenceSet | evidence ids | `Tiannara.Forecasting` | `Signal.context`, bridge request `evidence` |
| ForecastRequest | `request_id` (deterministic) | `Tiannara.Research.Forecasting` | bridge schema v1 |
| Forecast | forecast id | EFDI `ForecastEngine` | `Contracts.Forecast` |
| RegisteredForecast | forecast id + request id | EFDI `ForecastRegistry` | registry + EventStore lineage |
| OutcomeObservation | observation id | *not implemented* | `Contracts.DecisionOutcome` is the nearest existing shape |
| VerifiedOutcome | observation id + verifier | *not implemented* | — |
| ResolvedForecast | forecast id + resolution | EFDI `OutcomeResolution` | `OutcomeResolution.resolve/3` |
| ForecastScore | forecast id + resolution id | EFDI `Calibration` | `Calibration.score/2` |

## 1.2 The forecast contract

Preserved by `Tiannara.Forecasting.Contracts.Forecast` and by the bridge's wire
format: forecast id, question, event, outcomes, horizon, probabilities,
distribution, uncertainty, confidence, model ref, base-rate ref, evidence refs,
signal refs, assumptions, unknowns, lineage, context, regime, provenance,
forecast version, creation time, schema version.

The bridge additionally requires, before any forecast is produced:

- an explicit **outcome space** (≥ 2 outcomes) — otherwise `:missing_outcomes`;
- an explicit **horizon** — otherwise `:missing_horizon`;
- **evidence** with an epistemic status from
  `{observed, verified, inferred, simulated, hypothetical, unknown, rejected}`;
- **provenance** with an origin.

## 1.3 Gate 1 — what cannot be silently rewritten

| Property | Mechanism |
|----------|-----------|
| The original proposition | The forecast is registered with its question and outcomes; the registry never overwrites an id. |
| The deadline / horizon | Stored on the forecast; resolution is checked against it. |
| Prediction-time information | The registry's durable event carries the full forecast; the request's evidence references are fixed at registration. |
| The outcome definition | The outcome definition is the forecast's own `outcomes`; the resolver compares against it. |
| Later evidence rewriting prediction-time state | The registry refuses to overwrite an existing forecast id; a correction must be a new id with lineage. |

---

# Stage 2 — Research Director → EFDI integration

## 2.1 Where the forecast belongs, and why

**The hypothesis evaluation stage.** Once a hypothesis exists, its proposition,
outcome space and resolution criteria define what can be forecast. A forecast
produced there:

- tells the director how likely the proposition is *before* an experiment is
  planned, which is the input a decision about *which experiment to run* needs;
- gives the later resolution something to score against;
- does not belong at experiment execution, where the experiment's own result
  is the observation, not a forecast.

## 2.2 What was implemented

**New:** `lib/tiannara/research/forecasting.ex` — `Tiannara.Research.Forecasting`,
an adapter that performs **no forecasting mathematics**. It validates a
forecast specification, builds the versioned request, calls
`Tiannara.Forecasting.Bridge` (canonical EFDI), and records the outcome on the
hypothesis.

**Changed:**

| File | Change |
|------|--------|
| `lib/tiannara/research/research_director.ex` | The pipeline requests a forecast for each hypothesis at the hypothesis-evaluation stage and records the result. |
| `lib/tiannara/research/hypothesis_ranker.ex` | Hypotheses carry `forecast_spec`, `forecast_status`, `forecast`, `forecast_id`. |
| `lib/tiannara/forecasting/adapters/research_impl.ex` | A priority carries the signal's forecast specification when the signal has one. |

## 2.3 The honesty rule this integration obeys

A hypothesis without a forecast specification is marked
`forecast_status: :not_forecastable` with the reason. It is **not** given an
invented probability, and it is **not** reported as an investigation that
failed to forecast for a technical reason — the distinction is preserved
because the two mean different things:

| Status | Meaning |
|--------|---------|
| `:not_forecastable` | The hypothesis is not a proposition that can be forecast. Nothing is wrong with the forecasting subsystem. |
| `:unavailable` | The proposition was forecastable but the authority could not be reached, or refused the request. The reason is recorded. |
| `:registered` | A probabilistic forecast was produced and registered with canonical EFDI. |

## 2.4 The three quantities kept apart

A hypothesis now carries three distinct values, and the adapter never converts
one into another:

- `confidence` — evidence confidence (pre-existing on the hypothesis);
- `eig_score` — expected information gain, a **heuristic** ranking input;
- `forecast.probabilities` — a probabilistic forecast over a declared outcome
  space, present only when a forecast was actually requested and registered.

## 2.5 Idempotency and conflict

The forecast request id is derived from the **research input** (the priority
id and the proposition), not from the hypothesis instance. A hypothesis record
is regenerated on every ingest, so keying on it would create a new forecast for
the same research input every time. Re-ingesting the same priority therefore
returns the original forecast.

A reused request id carrying **different** content is refused with
`:request_id_conflict` rather than replayed.

## 2.6 Gate 2 — a genuine research question reaches EFDI

**PASSED.** `test/tiannara/research/research_forecasting_integration_test.exs`
drives the **supervised** Research Director (`ingest_priorities/1`), not a
direct call to `ForecastEngine`. It asserts that the forecast is registered
with the canonical EFDI authority and recoverable from it:

```
test "the real Research Director path produces a registered probabilistic forecast"
test "the forecast is registered with the canonical EFDI authority"
test "the forecast preserves the evidence references and provenance"
test "evidence confidence is not replaced by the forecast probability"
test "re-ingesting the same priority does not create a second forecast"
```

**10 tests, 0 failures.**

---

# Stage 3 — Durable forecast registry and adversarial recovery

**PASSED.** `test/tiannara/forecasting/forecast_registry_durability_test.exs`
— **14 tests, 0 failures**, each against an **isolated durable log** (a real
file on disk) and an isolated registry instance.

## 3.1 Defects found by the adversarial suite

Two real defects were exposed by writing the tests, and both are fixed at
their canonical ownership:

### F-01 — the event log silently truncated history

`EventStore.parse_frames/4` stopped at the first frame it could not parse and
returned the events read so far, with **no indication that anything was lost**.
A truncated tail or a corrupted frame therefore produced a *clean-looking but
incomplete* history.

**Fix.** The store now parses every frame it can, counts the ones it cannot,
and distinguishes a truncated tail:

```elixir
def stream_with_diagnostics(since \\ 0)   # -> {:ok, %{events:, unreadable:, truncated:}}
```

A frame whose declared size exceeds the remaining bytes is reported as
truncated, not as a clean end of log.

### F-02 — the durable log could introduce executable terms

`Event.from_binary/1` used `:erlang.binary_to_term(bin)`, which will construct
**any** term, including new atoms and local function references. A tampered log
could therefore introduce executable content into the reader.

**Fix.** `:erlang.binary_to_term(bin, [:safe])`.

## 3.2 The registry now reports what it could not read

Recovery counts the records it could not decode and reports them:

```elixir
%{
  ets_available: true,
  eventstore_degraded: true,
  durable: false,
  forecast_count: 1,
  recovered_count: 1,
  recovery_failures: 2
}
```

**Corruption is never presented as clean history.**

## 3.3 Instance isolation

The registry's ETS tables and the event store's registered name are now
configurable:

- `config :tiannara, :forecast_registry_name` — the registry instance;
- `config :tiannara, :executive_event_store` — the durable log instance.

This is what makes an isolated durability test possible, and it removes the
tension between "the application supervises the registry" and "the forecasting
suites need per-test isolation".

## 3.4 What the suite covers

| # | Behaviour | Test |
|---|-----------|------|
| 1 | A registered forecast survives a registry restart with identical canonical fields | ✅ |
| 2 | The request index survives a restart | ✅ |
| 3 | The request id is recovered with its fingerprint | ✅ |
| 4 | Registering the same forecast twice creates no second record | ✅ |
| 5 | A duplicated durable event does not duplicate the recovered record | ✅ |
| 6 | A truncated final record is detected and reported as degraded | ✅ |
| 7 | A corrupted record is not presented as clean history | ✅ |
| 8 | A tampered probability does not replace the original | ✅ |
| 9 | A missing payload is not reconstructed from an unrelated record | ✅ |
| 10 | A failed durable write is never reported as a durable registration | ✅ |
| 11 | An unavailable store at recovery is reported, not treated as empty history | ✅ |
| 12 | The registry reports its own availability truthfully | ✅ |
| 13 | Concurrent registration of the same idempotency key yields one forecast | ✅ |
| 14 | Concurrent registration of distinct forecasts keeps every record | ✅ |

## 3.5 Not covered

- **Out-of-order event delivery** — the log is a sequence of frames read in
  order; the store does not currently carry per-record sequence numbers, so
  reordering cannot be detected. Registered as `TCP-B-056`.
- **Integrity digest mismatch on the record itself** — the forecast is decoded
  and validated, but no digest is stored over the record, so a tampered
  *field* is only detected where it breaks `Forecast.validate/1`. Registered
  as `TCP-B-057`.
- **Interrupted write / partial append at the OS level** — covered indirectly
  by the truncation test (a partial final frame), not by a fault-injection
  harness.
