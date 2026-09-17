# Multi-Scale Coordination Engine

## Purpose

Define the engine that coordinates models across spatial and temporal scales within the digital twin.

## Spatial Scales

| Scale | Resolution | Extent |
|---|---|---|
| Global | 1° × 1° | Planet |
| Continental | 0.25° × 0.25° | Continents |
| Regional | 0.05° × 0.05° | Regions |
| National | 5km × 5km | Countries |
| Subnational | 1km × 1km | States/provinces |
| Urban | 100m × 100m | Cities |
| Local | 10m × 10m | Neighborhoods |
| Facility | 1m × 1m | Individual facilities |

## Temporal Scales

| Scale | Step | Horizon |
|---|---|---|
| Real-Time | Seconds | Hours |
| Operational | Hours | Days |
| Tactical | Days | Months |
| Strategic | Months | Years |
| Long-Term | Years | Centuries |

## Coordination Mechanisms

- **Downscaling** — Global models drive regional models.
- **Upscaling** — Local details aggregate to regional/global.
- **Nesting** — High-resolution regions nested in global model.
- **Coupling** — Bidirectional feedback between scales.
- **Adaptive Mesh** — Resolution dynamically adjusts based on activity.

## Scale Consistency

- All scales remain consistent with observations.
- Cross-scale consistency verified periodically.
- Scale conflicts detected and resolved.
- Scale mismatch uncertainty propagated.
- Scale transitions recorded in replay log.
