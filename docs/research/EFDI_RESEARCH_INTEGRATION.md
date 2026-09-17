# EFDI Research Integration

**Phase:** D1 — Signal Intelligence

## 1. Relationship to the research subsystem

Tiannara's existing research subsystem (`Tiannara.Research.*`,
`Tiannara.Discovery.*`) generates and prioritizes hypotheses. EFDI D1 supplies
*signals* — the structured observations that inform those priorities.

Signals are **not** hypotheses. A signal may *inform* a hypothesis; the
promotion is a D2+ concern. D1 only ensures that the research subsystem can
consume signals through a stable boundary.

## 2. Adapter: Research

`Tiannara.Forecasting.Adapters.Research` declares (but D1 does not implement):

| callback | purpose |
|----------|---------|
| `signal_to_priority/1` | derive a research priority from a signal |
| `signals_to_priorities/1` | batch derivation over many signals |
| `information_gain_estimate/2` | estimate EIG of pursuing a signal (→ `ActiveLearner.compute_eig/2`) |
| `under_observed_regions/1` | which regions are under-observed given existing signals |

## 3. Reused research primitives

- `Tiannara.Discovery.Domain.{HypothesisSpec, PredictionSpec}` — the struct shapes
  signals may feed into (via adapters, D2).
- `Tiannara.Discovery.Optimization.ActiveLearner.compute_eig/2` — information-gain
  estimate seam.
- `Tiannara.Research.ResearchDirector.ingest_priorities/1` — where signal-derived
  priorities land.

## 4. Guard rails

- D1 never invents a priority; it only provides quality/value assessments and
  boundary callbacks for D2+ to implement.
- A signal with `:unknown` quality is not silently promoted to high priority.
- Research-facing adapters are behaviour-only in D1 (no side effects), keeping
  the D1 surface honest and inspectable.
