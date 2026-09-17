# AE-003 Day-7 Observation Disposition

**Timestamp:** 2026-08-20T01:25:12Z (local)  
**Observer:** Human + Assistant (Closure Checkpoint)  
**Protocol:** K-004 Frozen Observation Sequence  
**Supersedes:** day3_investigation_resolution.md (trajectory completed)

## 1. Complete Trajectory Record

| Label | Host condition (sidecar) | p50 (ms) | Band status | Shape |
|-------|--------------------------|----------|-------------|-------|
| day0 | opencode-active session (anchor) | 1800.2 | baseline | tight 1.62–1.90s |
| day1 | loaded (external workloads) | 5329.8 | OUT ×2.4 | wide 3.25–12.27s |
| day3 | heavily loaded (~23:00) | 11813.9 | OUT ×5.2 | wide 7.45–14.51s |
| day7 | saturated: CPU 100%, RAM 1.0–1.7 GB | 7485.8 | OUT ×3.3 | wide 4.62–8.59s |
| confirm1 | residual: CPU 50–95%, RAM 3.2 GB | 2756.2 | OUT ×1.2 | tight 2.65–3.10s |
| confirm2 | residual: CPU 46–87%, RAM 3.1 GB | 2619.7 | OUT ×1.2 | tight 2.32–2.90s |
| **day7b** | **quiet: opencode + apps closed** | **1416.4** | **IN BAND** | **tight 1.41–1.47s** |

Supporting metrics (day7b): ETS 18016 (flat), archive 18016 (flat), VM mem 46.7 MB (in-band).

## 2. Pre-Registered Day-7 Decision Matrix — Application

| Matrix cell | Prediction | Observed | Verdict |
|-------------|-----------|----------|---------|
| Quiet + ~1.5–2.0s | strong evidence healthy | **1416.4 ms** | **SATISFIED** |
| Quiet + >2.25s | attribution reopens | — | not triggered |
| Loaded + >2.25s | out-of-band, hypothesis-consistent | day7 7485.8 / confirm1 2756.2 / confirm2 2619.7 | recorded out-of-band |

The day7b reading was taken with opencode and all other applications closed, i.e.
the environment's true quiet state (the observer-effect floor of ~45% CPU reported
by the human was absent). It reproduces the investigation probe (1423 ms) within 0.5%.

## 3. Formal Disposition

**Disposition label:** `CLOSE_HEALTHY / ANOMALIES_PRESERVED / ATTRIBUTION_HOST_CONTENTION / NO_ROLLBACK`

| Item | Decision |
|------|----------|
| Adoption (bulk_gc_ingest, blob `4f7024f`) | **RETAINED — healthy** |
| Day-1 / Day-3 / Day-7 anomalies | **Preserved as contract violations, attributed to host contention** |
| Confirm1 / confirm2 | Out-of-band, hypothesis-consistent (opencode-active residual load) |
| Candidate defect | **Not established** (closed) |
| Rollback | **Not authorized — not warranted** |
| Band (±25% of 1800 ms) | **Unchanged: 1350–2250 ms** |
| Observation instrument | **Unchanged (frozen through window, as designed)** |
| Freeze (K-004) | **Lifted by CLOSURE.md (see separate record)** |
| AE-004 Gate Fidelity | **Execution-eligible** (gated on human authorization) |

## 4. Epistemic Guardrails — Verified

- ✅ No band widening — day7b in-band at 1416.4 ms.
- ✅ No ad-hoc resampling — confirm1/confirm2/day7b were structured, labeled,
  sidecar-context observations under the confirmed protocol.
- ✅ No premature rollback — candidate demonstrated baseline performance under
  identical artifact + data.
- ✅ Anomalies preserved — day-1/3/7 stand as observed contract violations with
  full causal attribution (host contention, dose-response 1.4s @ low CPU →
  11.8s @ saturated CPU).
- ✅ Observer effect documented — opencode itself consumes 30–45% CPU; the band
  anchor was itself opencode-relative; the quiet cell is defined as
  opencode-and-apps-closed, which day7b satisfied.

---
*End of Day-7 Disposition Record*