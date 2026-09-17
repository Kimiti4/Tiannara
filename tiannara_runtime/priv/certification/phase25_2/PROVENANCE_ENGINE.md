# Provenance Engine

## Purpose

Define the engine that records and maintains complete provenance for every observation.

## Provenance Model

Every observation records:
- **Source Identity** — Who/what produced the observation.
- **Source Type** — Satellite, sensor, publication, dataset, human.
- **Capture Time** — When the observation was originally captured.
- **Capture Location** — Geographic context of capture.
- **Instrument** — Instrument or method used.
- **Calibration** — Calibration status of instrument.
- **Version** — Observation schema version.
- **Collector** — Entity that collected the observation.
- **Processing Lineage** — Every transformation applied.
- **Validation Status** — Result of each validation check.
- **Confidence** — Aggregate confidence score.
- **Uncertainty** — Measurement and processing uncertainty.

## Provenance Chain

```
Raw Data (source)
    ↓
Ingestion (timestamp, source metadata)
    ↓
Preprocessing (algorithm, version, parameters)
    ↓
Validation (method, result, confidence, reviewer)
    ↓
Fusion (source observations, fusion method)
    ↓
Evidence (certified observation)
    ↓
State Update (domain, variable, timestamp)
```

Each link is immutable and cryptographically linked to the previous link.

## Provenance Queries

- Full provenance for any piece of evidence.
- Source audit for any observation.
- Processing history for any derived value.
- Validation history for any observation.
- Trust path from source to state.
