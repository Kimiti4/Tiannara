# EFDI Integration Map

**Phase:** D1 — Signal Intelligence
**Namespace:** `Tiannara.Forecasting.*`

D1 must *integrate with, not fork*, existing Tiannara infrastructure. This map
records every integration point, the canonical primitive consumed, and how D1
uses it.

## 1. Identity & events

| D1 consumer | Reused primitive | Usage |
|------------|------------------|-------|
| `Signal.new/1` | `Tiannara.Executive.Types.new_id/0` | UUID v4 signal id |
| `SignalRegistry.maybe_append_event/1` | `Tiannara.Executive.Event.new/3`, `EventStore.append/1` | append-only `efdi.signal.registered` event (best-effort) |

## 2. Mathematics & information theory

| D1 consumer | Reused primitive | Usage |
|------------|------------------|-------|
| D2+ (contract) | `Tiannara.Math.Probability.bayes_update/3` | posterior recomputation |
| `SignalValue` | `Tiannara.Foundations.InformationTheory.{shannon_entropy, kl_divergence}/` | information gain (returns raw floats) |

## 3. Numerics & constraints

| D1 consumer | Reused primitive | Usage |
|------------|------------------|-------|
| `Signal` | `Tiannara.Numerics` error modes | `measurement_uncertainty` typing (`:approximate`, `:exact`, ...) |
| `SignalQuality` | `Tiannara.Constraints.normalize_probabilities/1` | normalizing assessed reliability dimensions |

## 4. World model & discovery

| D1 consumer | Reused primitive | Usage |
|------------|------------------|-------|
| `Adapters.WorldModel` | `Tiannara.Core.WorldModel.Uncertainty` | context_for/conflicts |
| `Adapters.Research` | `ActiveLearner.compute_eig/2` | information-gain estimate |
| `Adapters.Research` | `ResearchDirector.ingest_priorities/1` | signal→priority |
| `Correlation` | `Tiannara.World.ConflictDetector` | shared-origin heuristics |

## 5. Adapter behaviours (D2–D6 implement)

These `@callback`-only modules define the integration contract without
implementing it:

- `Adapters.Evidence` — `link_to_evidence/3`, `evidence_for/1`
- `Adapters.Research` — `signal_to_priority/1`, `signals_to_priorities/1`,
  `information_gain_estimate/2`, `under_observed_regions/1`
- `Adapters.CIS` — `signal_to_telemetry/1`, `forecast_to_collapse_probability/1`,
  `signal_conflict_to_pathogen/1`
- `Adapters.WorldModel` — `ingest_signal/1`, `context_for/1`,
  `conflicts_with_world?/1`

## 6. Non-goals

- Do **not** introduce a separate ontology/hash model for provenance — reuse
  `Tiannara.Executive.*` and the content-hash in `Provenance`.
- Do **not** duplicate evidence/research/CIS/world-model logic — only define
  boundaries D2–D6 will implement against.
