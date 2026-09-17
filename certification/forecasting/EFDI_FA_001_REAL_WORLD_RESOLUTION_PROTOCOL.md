# EFDI-FA-001 — Real-World Resolution Protocol

**artifact:** `EFDI_FA_001_REAL_WORLD_RESOLUTION_PROTOCOL.md`
**status:** FROZEN 2026-09-13
**governing contract:** `EFDI_FA_001_AUDIT_CONTRACT`
**schema:** `EFDI_FA_001_FORECAST_SCHEMA.yaml` (resolution_rule, resolution_time, resolution_source)

---

## 1. Purpose

Make outcome determination **mechanically deterministic and pre-fixed**. The
resolution rule and source are written into the forecast record BEFORE the
forecast is issued, and are NEVER reinterpreted at outcome time.

---

## 2. Pre-issue requirements (both domains)

For every live forecast, before the forecast:

- `resolution_rule`: the exact comparison (e.g., "window-end TWAP >= window-open
  TWAP"). 
- `resolution_source`: the exact stream/service and endpoint.
- `resolution_time`: the planned observation instant; for a window, the window
  end `T0 + horizon`.
- `eps` for FLAT (if any) pre-fixed; default is no FLAT class unless the audit
  contract for that series declares it.

---

## 3. Fixed resolution sources (Forecast #001 pilot)

### 3.1 BTC 5-minute Up/Down

- Rule: "Up" if `TWAP_end >= TWAP_start` over the 5-minute window, else "Down",
  where `TWAP` is the Chainlink BTC/USD time-weighted average price, mirroring
  the Polymarket recurring market's resolution semantics.
- Source: Chainlink data stream
  `https://data.chain.link/streams/btc-usd-twap-60s-streams` (for 5m windows);
  `btc-usd-twap-30s-streams` where the series is so configured.
- Recording: the `TWAP_start` and `TWAP_end` values plus the resulting verdict
  go into `outcome_metadata`.
- Baseline: the Polymarket implied probability for the SAME window recorded at
  `data_cutoff` (B4). Polymarket is NEVER truth; it is another forecaster.

### 3.2 Nairobi precipitation, 60-minute window

- Question: "Will measurable precipitation occur within the next 60 minutes?"
- Rule: measurable precipitation (>= 0.1 mm) observed at the pre-declared
  station/location during `[T0, T0+60m]`.
- Source: pre-declared authoritative observation source for that location and
  measured dataset (e.g., the official service station record for the window,
  or KNMS/dense-station observed series if so configured); a SINGLE source is
  fixed per series and never swapped for convenience.
- Recording: observed mm + verdict in `outcome_metadata`.

---

## 4. Resolution discipline

- Resolution proceeds ONLY after `resolution_time` has passed.
- ONE reader resolves the outcome from the pre-fixed source. No cross-checking
  against another source retroactively to "fix" an unfavorable outcome.
- The forecast is NEVER redone, re-justified, or softened at resolution.
- The original record is untouched; scores + outcome are APPENDED
  (`FORECAST_SCHEMA` post-resolution block; `FORECAST_LEDGER` forecast_resolved).

---

## 5. Dispute / divergence path

If the planned source is unavailable or obviously corrupted at resolution
(stream down, empty record, data discontinuity):

1. The planned rule is unaffected. The METADATA may be sourced from a recorded
   fallback ONLY IF the fallback was pre-declared in the series configuration.
2. Any substitution MUST be written as `resolution_source` substitution, citing
   the original and the reason (granule type `metadata` + `forecast_resolved`).
3. If NO pre-declared fallback exists, the forecast is marked `UNRESOLVED` and
   EXCLUDED from scoring with cause (F-10 measurement error), never silently
   dropped.
4. Nobody may reinterpret the rule to make the forecast win.

---

## 6. Outcome reconciliation

After resolution, an independent re-read (operator-driven, not Tiannara) spots a
single recorded reconciliation value for the same window from the SAME source.
Mismatch => F-10, quarantine the forecast, investigate the source discrepancy.

---

## 7. Series-level pre-registration

Before each series batch starts, the series configuration freezes:

```
question template
horizon(s)
resolution rule template
resolution source(s) + fallbacks
flat eps (if any)   -> default: no FLAT
B4 forecaster for the domain (market set / weather service)
reference window for B1/B3 (no online refit)
candidate window sampling plan (times/days/volatility regimes)
```

No element of the series configuration may be changed mid-series. A change
ends the series and starts a new one (recorded as such).

---

## 8. Real-time recording mandate (audit trail)

For each forecast the FULL audit trail is stored per `FORECAST_LEDGER.yaml` (audit_trail_fields),
including `created_at`, `question`, `domain`, `forecast_horizon`,
`available_information`, `data_cutoff`, `models_used`, `signals_used`,
`base_rates`, `assumptions`, `unknowns`, `probabilities`,
`prediction_interval`, `confidence`, `alternative_outcomes`,
`disconfirming_evidence`, `model_versions`, `random_seed`. Responses are
recorded verbatim; no response is ever edited to make scoring cleaner.