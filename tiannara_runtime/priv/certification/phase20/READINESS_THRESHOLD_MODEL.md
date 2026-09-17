# Readiness Threshold Model (Phase 20.98)

## Purpose

Define objective thresholds for constitutional readiness. These thresholds determine CRI level assignment and certification eligibility.

## CRI Level Thresholds

| Level | Minimum Score | Requirements |
|-------|--------------|-------------|
| CRI-0 | — | Phase 20 architecture documents exist |
| CRI-1 | ≥ 0.10 | All Phase 20 architecture docs + schemas exist |
| CRI-2 | ≥ 0.30 | Phases 18+19 runtime implemented and tested |
| CRI-3 | ≥ 0.50 | Phase 20.95 validation campaigns defined |
| CRI-4 | ≥ 0.70 | Phase 20.96 independent audit passed |
| CRI-5 | ≥ 0.85 | Phase 20.97 long-horizon validation passed |
| CRI-6 | ≥ 0.95 | All phases complete, all dimensions ≥ 0.90, no critical deficiencies |

## Certification Eligibility Thresholds

For CRI-6 (eligible for Phase 20.999):

| Criterion | Threshold |
|-----------|-----------|
| Overall CRI | ≥ 0.95 |
| All dimension scores | ≥ 0.90 |
| No critical deficiencies | = true |
| Major deficiencies | ≤ 2 |
| Minor deficiencies | ≤ 5 |
| Validation completeness | = 1.0 (all 8 campaigns passed) |
| Audit completeness | = 1.0 (all 17 subsystems intact) |
| Replay completeness | = 1.0 (all replay chains verified) |
| Archaeology completeness | = 1.0 (all generations preserved) |
| Long-horizon replay | = 1.0 (all hashes match Gen 1 → Gen 100K) |

## Threshold Objectivity

All thresholds are:
- Deterministic (same evidence → same readiness level)
- Evidence-based (derived from cold storage)
- Objective (no subjective adjustments)
- Verifiable (reproducible by independent auditor)
- Frozen (thresholds cannot change after Phase 20.98)
