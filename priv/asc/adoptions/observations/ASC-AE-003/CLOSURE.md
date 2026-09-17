# ASC-AE-003 CLOSURE

**Mission:** ASC-AE-003 — Controlled Two-Key Adoption of `bulk_gc_ingest` (RepairLibrary)
**Status:** **CLOSED — HEALTHY**
**Closure date:** 2026-08-20 (post day7b observation)
**Protocol:** K-004 Frozen Observation Sequence (day0 → day1 → day3 → day7 → closure)

## 1. Final Verdict

**Adoption RETAINED.** Candidate blob `4f7024fba5b9197a27bbc1c7390327977a1e504e`
(production file `lib/tiannara/asc/crucible/repair_library.ex`) is closed as healthy.

| Item | Value |
|------|-------|
| Day-0 p50 (anchor) | 1800.2 ms |
| Day-7b p50 (quiet host, apps closed) | **1416.4 ms — in band (1350–2250)** |
| Controlled remeasurement (investigation) | 1423 ms (7 boots, identical blob/archive) |
| ETS size | 18016 flat throughout |
| Archive lines | 18016 flat throughout (16 MB, untouched since 2026-08-14) |
| VM memory | 46.3–48.2 MB (in band 39.5–53.5) |
| Tests | 9/9 green at adoption (validation) |
| Rollback | Not authorized, not warranted |

## 2. Anomaly Record (Preserved, Not Erased)

| Checkpoint | p50 | Classification |
|------------|-----|----------------|
| Day-1 | 5329.8 ms | Contract violation → provisional `environment_instability` |
| Day-3 | 11813.9 ms | Contract violation → `ATTRIBUTION_UNRESOLVED` → resolved by read-only investigation |
| Day-7 | 7485.8 ms | Contract violation → out-of-band, hypothesis-consistent (host saturated) |
| confirm1/2 | 2756.2 / 2619.7 ms | Out-of-band, opencode-active residual load |

**Attribution (supported by direct evidence):** monotonic host-contention
dose-response — CPU ~30–60% → 1.4s; 46–87% → 2.6–2.8s; 100% → 7.5–11.8s.
The day-7b quiet reading (1416.4 ms) reproduces the controlled remeasurement
(1423 ms) and confirms the candidate executes at baseline under identical
artifact + data. **No candidate defect was ever established.**

## 3. Evidence Trail (permanent)

- `day0.eterm`, `day1.eterm`, `day3.eterm`, `day7.eterm`, `confirm1.eterm`,
  `confirm2.eterm`, `day7b.eterm` — raw sample vectors
- `day1_disposition.md` — provisional classification
- `day3_disposition.md` — trajectory C, attribution unresolved
- `day3_investigation_protocol.md` / `day3_investigation_findings.md` —
  read-only diagnostic evidence (p50 1423 ms)
- `day3_investigation_resolution.md` — `ENVIRONMENT_INSTABILITY / SUPPORTED_BY_EVIDENCE`
- `day7_disposition.md` — closure cell satisfied

## 4. K-004 Freeze — LIFTED

Per K-004 policy: CLOSURE.md exists → the observation-window freeze is lifted.
Instrument (`asc.observe`), adoption machinery, and production are no longer
frozen by the AE-003 window.

**AE-004 (Gate Fidelity) is now EXECUTION-ELIGIBLE**, per its charter
(`priv/asc/missions/ASC-AE-004/charter.md`): execution remains gated on explicit
human authorization (matching the AE-003 two-key pattern).

## 5. Follow-up (Priority-0 substrate audit — Milestone U0)

Unchanged from prior posture. The day-1/day-7 EOS boot failures
(`executive_memory`, `event_store`, `unified_world_model`) and DETS repairs remain
standing signals for the U0 substrate audit. U0 probes remain gated on human
authorization. Measurement, not features.

---
*End of Closure Record — ASC-AE-003*