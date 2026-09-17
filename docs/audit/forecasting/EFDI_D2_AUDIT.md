# EFDI D2 — Independent Audit Report

**Gate:** EFDI-D2
**Status:** CERTIFIED_BOUNDED — V1–V12 PASS, exit 0.

## 1. Candidate boundary

D2 is a bounded dependency on D1's certified signal layer. D2 produces
immutable, evidence-linked forecasts and their calibration; it does NOT take
decisions (D3), regulate (CIS), or own the world model.

## 2. Reused (existing Tiannara capabilities)

| Capability | Module | D2 usage |
|------------|--------|----------|
| Probability normalization | `Tiannara.Constraints.normalize_probabilities/1` | `Forecast.new` |
| Bayes update | `Tiannara.Math.Probability.bayes_update/3` | `ForecastEngine.update_with_bayes` |
| Shannon entropy | `Tiannara.Foundations.InformationTheory.shannon_entropy/1` | `Calibration.sharpness` |
| ID generation | `Tiannara.Executive.Types.new_id/0` | forecast/outcome ids |
| Event lineage | `Tiannara.Executive.EventStore` | best-effort `efdi.forecast.registered` |

## 3. New (D2-owned)

`Forecast`, `BaseRateEngine`, `ForecastEngine`, `ForecastRegistry`, `Outcome`,
`Calibration`, `Adapters.{Evidence,Research,CIS,WorldModel}Impl`.

## 4. Files changed

- `lib/tiannara/forecasting/contracts.ex` — additive D2 fields on Forecast,
  BaseRate, ForecastRequest (documented exception).
- `lib/tiannara/forecasting/efdi.ex` — facade extended with D2 functions.
- 9 new D2 test files under `test/tiannara/forecasting/`.

## 5. Discovered defects during verification

1. **`Constraints.normalize_to/2` float-0 crash** — the `else` clause matches
   integer `0` only, not float `0.0`; all-zero probabilities crashed
   `Forecast.new`. Fixed by pre-checking `sum > 0` in `normalize_probs`.
2. **Silent clamp violation** — `normalize_probabilities/1` clamps OOB values
   before normalizing, which would have silently repaired invalid inputs.
   Fixed to preserve violations through `new/1` and reject them in `validate/1`.
3. **Scanner alias collision** — `Forecast` alias resolved to the
   `Contracts.Forecast` struct (no `new`/`validate`); disambiguated in engine,
   registry, and calibration.

## 6. Known limitations

- `ForecastRegistry` is in-memory ETS (no crash-safe durability this phase).
- Collective calibration uses random draws; ideal bounds asserted with tolerance.
- World Model / Research Director / CIS live loops deferred to D3+.

## 7. UNKNOWNs

- D1 `SignalQuality.assess/1` (documented placeholder) was not implemented; D2
  uses the existing `evaluate/1`. Whether `assess/1` ever lands is unstated.
- The `Contracts.Forecast.probability`/`distribution` D1 fields remain for
  backward compatibility but are not populated by D2 (the source of truth is
  `probabilities`).

## 8. STOP gate

D2 stops here by design. D3 (Decision) is NOT started per instruction.