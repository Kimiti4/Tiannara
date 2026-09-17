# Constitutional Readiness Index Architecture (Phase 20.98)

## Mission

Design the Constitutional Readiness Index (CRI) — the final quantitative assessment performed after Phases 20.95, 20.96, and 20.97. The CRI determines whether Tiannara has accumulated sufficient constitutional evidence to proceed to final certification (Phase 20.999).

## Constitutional Principle

Certification is binary. Readiness is quantitative. The CRI measures how close the system is to constitutional certification without issuing certification itself.

## Architecture

```
Validation Results (20.95)
    │
    ├── Campaign results
    ├── Gate status
    └── Metrics snapshots
         │
Audit Results (20.96)
    │
    ├── Subsystem verdicts
    ├── Findings
    └── Hash verification
         │
Long-Horizon Results (20.97)
    │
    ├── Generation history
    ├── Continuity reports
    └── Civilizational Resilience Index
         │
         v
+----------------------------+
|  CRI Computation Engine    |
|  (deterministic scoring)   |
+----------------------------+
    │
    ├── Per-dimension scoring (10 dimensions)
    ├── Per-domain scoring (20 domains)
    ├── Weighted aggregation
    └── Deficiency analysis
         │
         v
+----------------------------+
|  CRI Output                |
|  - Overall score (0.0–1.0) |
|  - CRI level (0–6)         |
|  - Dimension breakdown     |
|  - Domain breakdown        |
|  - Deficiencies            |
|  - Recommendation          |
+----------------------------+
```

## CRI Levels

| Level | Meaning | Required For |
|-------|---------|-------------|
| CRI-0 | Specification only | — |
| CRI-1 | Architecture complete | Phase 20.0–20.9 |
| CRI-2 | Runtime implemented | Phases 18–19 |
| CRI-3 | Validation complete | Phase 20.95 |
| CRI-4 | Independent audit complete | Phase 20.96 |
| CRI-5 | Long-horizon validation complete | Phase 20.97 |
| CRI-6 | Certification candidate | Phase 20.999 |

## Key Properties

- All scoring is deterministic and reproducible
- No subjective judgments; all scores derived from evidence
- CRI does not certify the system; it measures readiness
- Certification remains exclusive to Phase 20.999
- Full replay from cold storage produces identical scores
- Every score is explained by archaeological evidence
