# Observation Observability Model

## Purpose

Define observability for the CGON.

## Observable Dimensions

| Dimension | Description |
|---|---|
| Live Observation Streams | Real-time observation flow |
| Observation Coverage | Geographic and domain coverage maps |
| Sensor Health | Status and health of all sensors |
| Evidence Freshness | Age of latest evidence per domain |
| Confidence Heatmaps | Geographic confidence distribution |
| Missing Regions | Geographic areas with no observations |
| Unknown Events | Observations that don't match known patterns |
| Fusion Status | Current fusion operations and health |
| Replay Integrity | Replay system status and accuracy |
| Pipeline Status | Each pipeline stage status |

## Observatory Displays

- **Live Stream Dashboard** — Real-time observation flow visualization.
- **Coverage Map** — Geographic coverage visualization by domain.
- **Sensor Health Board** — Sensor status and health indicators.
- **Confidence Heatmap** — Geographic confidence visualization.
- **Evidence Freshness Map** — Age of latest evidence by region.
- **Fusion Dashboard** — Active fusion operations and results.
- **Pipeline Status** — Pipeline stage throughput and latency.
- **Source Diversity** — Source diversity metrics by domain.

## Alerting

| Alert Level | Condition |
|---|---|
| Info | New source registered |
| Warning | Source quality degrading |
| Critical | Source offline |
| Critical | Coverage gap detected |
| Warning | Validation failure rate increasing |
| Info | Unknown event detected |
| Emergency | Pipeline failure |
