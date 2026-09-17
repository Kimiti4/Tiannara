# Readiness Archaeology Model (Phase 20.98)

## Purpose

Define the archaeology model for readiness assessment. Every readiness assessment must explain: why was this score assigned, which evidence contributed, how can the score be reproduced.

## Per-Score Archaeology

Each readiness score's archaeology answers:

| Question | Answer |
|----------|--------|
| Why was this score assigned? | Calculation steps + evidence chain |
| Which evidence contributed? | Evidence root hash references |
| Which validation campaigns contributed? | Phase 20.95 campaign references |
| Which audit findings contributed? | Phase 20.96 finding references |
| Which mathematical evidence contributed? | Math validation evidence (20.95/E) |
| Which scientific evidence contributed? | Science validation evidence (20.95/F) |
| Which engineering evidence contributed? | Engineering evidence (20.95/A, 20.97) |
| How can the score be reproduced? | Replay chain reference |

## Archaeology Deposit Structure

Per CRI assessment:
```
CRI Assessment Archaeology
  ├── ReadinessIndex record
  ├── Per-dimension ReadinessDimension records
  ├── Per-score ReadinessScore records (× sub-metrics)
  ├── Per-domain DomainReadiness records (× 20 domains)
  ├── ReadinessReplay record
  ├── ReadinessCertificate record
  ├── Deficiency analysis
  └── Improvement recommendations
```

## Evidence Traceability

Every score's archaeology includes:
- Direct evidence references (campaign/scenario results)
- Calculated evidence (dimension scores from sub-metrics)
- Composite evidence (domain scores from dimensions)
- Replay verification (hash chain continuity)
- Cross-references to Phase 20.95, 20.96, 20.97 artifacts
