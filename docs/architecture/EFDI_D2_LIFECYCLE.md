# EFDI D2 — Lifecycle

## 1. Forecast lifecycle

```
                new evidence             outcome observed
                    │                         │
 ┌──────────────────▼──────────────────────────▼──────────────┐
 │ requests ─► ForecastEngine ─► Forecast (v1) ─► Registry    │
 │                    │                                          │
 │                    ▼                                          │
 │            Forecast.version/2 (v2, v3, …)                     │
 │            new immutables chained by lineage                  │
 └──────────────────────────┬─────────────────────────────────────┘
                            │ (later)
                            ▼
                    Outcome.guard!/2 ─► Calibration.score ─► reliability / mean scores
```

| Stage | Action | Guarantees |
|-------|--------|------------|
| Build | `ForecastEngine.forecast/1` | normalized, valid, immutable |
| Register | `ForecastRegistry.register/1` | validate → ETS insert (no double count) |
| Update | `Forecast.version/2` | new identity, lineage, never overwrite |
| Observe | `Outcome.new/3` + `guard!/2` | hindsight-isolated linkage |
| Score | `Calibration.score/3` | attribute-safe, `:unknown`-aware |
| Judge | `Calibration.reliability/1` | `INSUFFICIENT_DATA` vs `POOR` |

## 2. Event lineage

Registry appends `efdi.forecast.registered` to the existing `EventStore`
(best-effort; degradation is reported via `health/0`, not silently dropped
data). Forecast history itself lives in the ETS registry; lineage lists enable
"what did Tiannara believe at time T".

## 3. Evidence update with immutable versioning

New evidence never mutates a forecast. It produces a new version whose
`evidence_refs`/`signal_refs` extend the record; the prior version remains
retrievable. Hindsight is structurally impossible because `Outcome.guard!/2`
rejects `observed_at < forecast.created_at`.

## 4. Degradation handling

- `EventStore` failure → best-effort skip, `eventstore_degraded: true` in health.
- Missing base rate → honest `:unknown` prior.
- Unscorable forecast → `sample_size: 0`, no fabricated value.