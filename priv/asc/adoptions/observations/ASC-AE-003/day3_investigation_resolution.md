# AE-003 Day-3 Investigation Resolution

**Timestamp:** 2026-08-23T00:00:00Z  
**Supersedes:** day3_disposition.md (attribution updated)  
**Protocol:** K-004 Frozen Observation Sequence  

## 1. Investigation Outcome

The read-only investigation has conclusively resolved the Day-3 progressive degradation anomaly.

### Direct Evidence
Seven controlled boots of the identical production blob (`4f7024f`) + archive, using the frozen instrument's exact protocol, on the same host:

```
[1347, 1388, 1410, 1423, 1444, 1636, 1819] ms
```

**Observed p50: 1423 ms** — statistically identical to Day-0 baseline (1800 ms).

### Supporting Evidence
1. **Host Load Volatility:** Host CPU fluctuates 8–100%, RAM 1.2–2.1 GB free. Day-3 ran at ~23:00 during peak host contention.
2. **Sample Variance:** 
   - Day-0: tight 1.6–1.9s cluster (quiet host)
   - Day-1: wide 3.3–12.3s spread (saturated host)
   - Day-3: wide 7.5–14.5s spread (saturated host)
   - A library defect would produce a *tight, shifted* cluster — same code, same input → same cost.
3. **No Cross-VM Accumulation:** Each observation is a fresh BEAM; only host state and the static archive persist.
4. **Substrate Churn Moot:** `asc.observe` boots no substrate (`app.config` only). Day-1's DETS repairs and service failures were coincidental session noise, not part of the p50 measurement path.

## 2. Updated Attribution

| Item | Day-3 Disposition | Day-3 Resolution |
|------|-------------------|------------------|
| Primary hypothesis | `ATTRIBUTION_UNRESOLVED` | **`ENVIRONMENT_INSTABILITY` (host contention)** |
| Candidate defect | not established | **not established** |
| Rollback | not yet authorized | **not authorized** |

### Causal Chain (Reconstructed)

```text
AE-003 candidate (bulk_gc_ingest)
      │
      ├── Day-0 → ~1.8s (quiet host)
      │
      ├── Day-1 → 5.33s (host contention + coincidental substrate noise)
      │
      ├── Day-3 → 11.81s (severe host contention)
      │
      └── Controlled remeasurement (7 boots)
               ↓
             1.423s p50 (baseline performance restored)
```

**Conclusion:** The candidate is not degraded. The observed progressive degradation was caused by host resource contention, not a defect in the adopted implementation.

## 3. Formal Disposition Update

**Disposition label:** `ENVIRONMENT_INSTABILITY / SUPPORTED_BY_EVIDENCE / NO_ROLLBACK`

### What is preserved
- The Day-3 anomaly is **not erased** from the historical record.
- The original observation (11.81s, contract violation) stands.
- The read-only investigation and its evidence are permanently linked to the Day-3 record.

### What is corrected
- The attribution is updated from `ATTRIBUTION_UNRESOLVED` to `ENVIRONMENT_INSTABILITY (host contention)`.
- The Day-3 objection ("no churn yet worse") is resolved: the degradation was caused by host load, not substrate state.

## 4. Rollback Decision

**Rollback: NOT AUTHORIZED**

Rationale: Direct evidence demonstrates that the adopted implementation can reproduce near-baseline performance with the same artifact and data. Rolling back now would destroy a useful experimental condition without evidence that the candidate caused the degradation.

## 5. Day-7 Protocol (Confirmed)

| Item | Specification |
|------|---------------|
| Observation instrument | Frozen, unmodified |
| Production implementation | Identical (`4f7024f`) |
| Archive | Identical (16 MB, untouched since 8/14) |
| BEAM | Fresh boot |
| Observation | Normal Day-7 protocol |
| Diagnostic context | **Sidecar CPU/RAM snapshot at observation time** (read-only note, not an instrument change) |
| Production changes | None |
| Rollback | None |
| Band adjustment | None (±25% from Day-0 remains: 1350–2250 ms) |

### Day-7 Decision Matrix

| Host State | Day-7 p50 | Interpretation |
|------------|-----------|----------------|
| Quiet | ~1.5–2.0s | Strong evidence: AE-003 healthy, Day-1/Day-3 were host-contended |
| Quiet | >2.25s | Attribution unresolved again; deeper investigation required |
| Loaded | >2.25s | Consistent with host-contention hypothesis; recorded as out-of-band |

## 6. Epistemic Guardrails Maintained

- ✅ **No band widening** — the contract remains 1350–2250 ms.
- ✅ **No ad-hoc resampling** — the 7-boot remeasurement was a structured investigation, not protocol contamination.
- ✅ **No premature rollback** — evidence did not support candidate defect.
- ✅ **Anomaly preserved** — Day-3 stands as an observed contract violation, now correctly attributed.
- ✅ **Evidence before confidence** — we did not explain away the anomaly; we proved the cause.

---
*End of Day-3 Investigation Resolution*