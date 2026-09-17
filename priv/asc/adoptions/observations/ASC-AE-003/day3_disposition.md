# AE-003 Day-3 Observation Disposition

**Timestamp:** 2026-08-22T00:00:00Z  
**Observer:** Human Judgment (Escalation Triggered — Trajectory C)  
**Protocol:** K-004 Frozen Observation Sequence  
**Supersedes:** day1_disposition.md (provisional classification updated)

## 1. Trajectory Record

| Checkpoint | p50       | Δ vs Day-0 | Band Status              | Substrate Churn |
|------------|-----------|------------|--------------------------|-----------------|
| Day-0      | 1800 ms   | —          | baseline                 | none recorded   |
| Day-1      | 5329.8 ms | +196%      | OUT (×2.4 ceiling)       | 3 DETS repairs, 3 failed services |
| **Day-3**  | **11813.9 ms** | **+556%** | **OUT (×5.2 ceiling)** | **none recorded** |

Supporting metrics (Day-3):
- ETS size: 18016 (in-band, flat)
- Archive lines: 18016 (in-band, flat)
- VM memory: 48.2 MB (in-band, slight upward drift: 46.5 → 46.3 → 48.2)

## 2. Classification Update

| Item | Day-1 Classification | Day-3 Classification |
|------|----------------------|----------------------|
| Primary hypothesis | `environment_instability` (provisional) | **ATTRIBUTION_UNRESOLVED** |
| Candidate defect | not established | **not established** |
| Environment instability | plausible | **weakened — Day-3 had no substrate churn** |
| Rollback | not authorized | **not yet authorized** |

### Why the Day-1 hypothesis no longer holds

Day-1 had heavy substrate churn (3 DETS repairs, 3 failed services). Day-3 had **none**, yet p50 increased **+121%** from Day-1. The environmental correlation did not reproduce. This does not prove environment instability was wrong on Day-1, but it is no longer sufficient as a unified explanation for the trajectory.

### Why candidate defect is also not established

- Production candidate code unchanged since Day-0.
- Day-0 measured 1.8s **with the candidate live** — a candidate defect should have manifested at Day-0.
- ETS size, archive size, and memory remain bounded — no evidence of candidate-driven state growth.

### The actual evidentiary state

```text
candidate active (unchanged)
      │
      ▼
Day-0: 1.8s   ← candidate live, healthy
      │
      ▼
Day-1: 5.3s   ← substrate churn present
      │
      ▼
Day-3: 11.8s  ← no substrate churn, latency still increased
      │
      └── monotonic degradation
          no visible state growth in adopted library
          no obvious memory explosion
          causal chain: UNRESOLVED
```

## 3. Formal Disposition

| Item | Decision |
|------|----------|
| Day-3 trigger | **CRITICAL — fired** |
| Trajectory | **C — progressive degradation** |
| Candidate defect | **Not established** |
| Environment instability | **No longer sufficient as explanation** |
| Rollback | **Not yet authorized** |
| Production modification | **Frozen** |
| Observation instrument | **Frozen** |
| Root-cause investigation | **AUTHORIZED — read-only** |
| Next checkpoint | **Day-7 (2026-08-26)** |

**Disposition label:** `PROGRESSIVE_DEGRADATION / ATTRIBUTION_UNRESOLVED / READ_ONLY_INVESTIGATION / NO_ROLLBACK_YET`

## 4. Day-7 Decision Rule (Pre-Registered)

| Day-7 Outcome | Trajectory | Disposition |
|---------------|------------|-------------|
| Return to baseline (~2s) | 1.8 → 5.3 → 11.8 → ~2 | Transient; rollback less compelling |
| Persist ~10–12s | 1.8 → 5.3 → 11.8 → ~10 | Persistent unexplained degradation; do NOT close AE-003 as healthy |
| Continue upward (15s+) | 1.8 → 5.3 → 11.8 → 15+ | Serious reliability regression; rollback strongly justified |

## 5. Epistemic Guardrails

- **Do not downgrade the Day-3 result** because the cause is unknown.
- **Do not explain away** the monotonic trajectory.
- **Do not modify production or the observation instrument** during the window.
- **Do not widen the band** post-hoc.
- The correct state is: **observed failure, causal attribution unresolved.**

---
*End of Day-3 Disposition Record*