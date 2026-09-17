# EFDI Architecture

**Subsystem:** Epistemic Forecasting, Signal & Decision Intelligence (EFDI)
**Namespace:** `Tiannara.Forecasting.*`
**Phase:** D1 — Signal Intelligence (foundational contract layer)

## 1. Purpose

EFDI is the subsystem that turns raw observations into *signals*, then (in later
phases) signals into calibrated *forecasts*, then forecasts into *decisions*,
with explicit handling of *counterfactuals*, *noise*, and *forecast memory*.

D1 (this phase) implements **only Signal Intelligence**. It defines the signal
model, its registry, quality assessment, value assessment, provenance, and
redundancy/correlation — plus the *contracts* D2–D6 will implement, and the
*adapter behaviours* by which EFDI integrates with the existing Tiannara
infrastructure.

## 2. Epistemic pipeline

EFDI never silently collapses these categories:

```
observation → signal → evidence → hypothesis → forecast → decision
```

| Stage | Meaning | Phase |
|------|---------|-------|
| Observation | a raw fact as-gathered | prior systems |
| **Signal** | a structured observation with quality + provenance | **D1** |
| Evidence | a signal admitted to a case | D2 |
| Hypothesis | a falsifiable claim about the world | D2 |
| Forecast | a calibrated, falsifiable probability | D2 |
| Decision | an action choice under uncertainty | D3 |

## 3. D1 module map

| Module | Responsibility |
|--------|---------------|
| `Signal` | Immutable signal struct; `new/1`, `validate/1`, `version/2`, `expired?/2`, `dedup_key/1` |
| `SignalRegistry` | GenServer + ETS registry; dedup, query, supersede, stats, health |
| `SignalQuality` | Pure quality scoring across 7 dimensions |
| `SignalValue` | Predictive value / information gain (D1 returns `:unknown` pre-outcome) |
| `Provenance` | Build, content-hash, integrity checks |
| `Correlation` | Shared-origin, redundancy index |
| `Contracts` | Structs for D2–D6 (`ForecastRequest`, `Forecast`, `BaseRate`) |
| `Adapters.*` | Behaviour contracts for Evidence / Research / CIS / WorldModel |
| `Tiannara.Forecasting` | Root facade (`start_link`, registration, quality, value, stats, health) |

## 4. Signal model

A `Signal` is a structured observation with **explicit epistemic metadata**:

- identity: `id` (immutable UUID), `version`, `supersedes`, `lineage`
- source: `source`, `source_reliability`, `domain`, `context`
- observation: `observation`, `observation_ref`, `observation_type`,
  `measurement_uncertainty`
- temporal: `timestamp`, `received_at`, `regime`, `expires_at`
- provenance: `provenance` (`kind`, `sha256`, `source_event_id`),
  `transformation_history`
- quality: `reliability`, `relevance`, `independence`, `persistence`,
  `predictive_value`
- state: `status`, `metadata`, `tags`

A signal is **not** a forecast, evidence, fact, or belief. It carries no
`probability`, no `decision`, and no resolved outcome.

## 5. Registry and dedup

`SignalRegistry` is a `GenServer` owning a `:public` ETS named table
(`:efdi_signal_registry`).

- **Primary index:** `{signal_id, signal}`
- **Dedup index:** `{{:dedup, dedup_key}, signal_id}`

`dedup_key` is a deterministic sha256 over `source + observation`. Registering
a signal whose dedup key already exists returns the **existing** signal and does
not double-count the observation as independent evidence.

> **ETS key caveat:** ETS keys on the *first element* of a stored tuple. The
> dedup index therefore stores a compound key `{:dedup, key}` as the first
> element, never a bare 3-tuple `{:dedup, key, id}` (whose ETS key would be the
> atom `:dedup`). See `SignalRegistry.store_signal/1` and `existing_by_key/1`.

Corrections are **append-only**: `supersede/2` creates a new version via
`Signal.version/2`, never overwrites history, and records the superseded id in
`lineage`.

## 6. Quality

`SignalQuality.evaluate/2` scores seven dimensions → `[0,1]` or `:unknown`:

`reliability, recency, completeness, measurement, independence, persistence,
validity`

The aggregate is a weighted mean over *assessed* dimensions (unknown dimensions
do not count toward the denominator). Weights are config-driven
(`:efdi_quality_weights`). `:unknown` (insufficient data) is distinct from `0.0`
(measured-and-low).

## 7. Value

`SignalValue.measure/2` computes predictive value, information gain, redundancy,
and marginal value. In D1, predictive value and information gain against
outcomes return `:unknown` because **outcomes do not yet exist** — fabricating a
value where no outcome has occurred would violate the honesty invariant.

## 8. Integration boundaries

D1 integrates with (does not fork) existing systems:

| Adapter | Existing system | Boundary |
|--------|----------------|----------|
| `Adapters.Evidence` | Evidence/provenance | link signals to evidence |
| `Adapters.Research` | Research priorities | signal→priority, information-gain estimate |
| `Adapters.CIS` | CIS telemetry/collapse | signal telemetry, collapse probability, pathogen |
| `Adapters.WorldModel` | World model | ingest, context, conflict detection |

D1 also reuses canonical primitives: `Tiannara.Executive.Types.new_id/0`,
`Tiannara.Executive.Event`, `Tiannara.Math.Probability.bayes_update/3`,
`Tiannara.Foundations.InformationTheory.*`, `Tiannara.Numerics`,
`Tiannara.Constraints.*`.

## 9. Out of scope for D1

D1 does **not** implement forecasting, calibration, decision, counterfactual,
noise, or forecast memory. Those are D2–D6 under the same namespace.
