# Satellite Observation Engine

## Purpose

Define the engine that ingests observations from Earth observation satellites.

## Satellite Observation Types

| Type | Examples | Variables |
|---|---|---|
| Optical Imagery | Landsat, Sentinel-2, MODIS | Land cover, vegetation, urban extent |
| Radar | Sentinel-1, RADARSAT | Topography, deformation, soil moisture |
| Thermal | MODIS, ECOSTRESS | Surface temperature, heat islands |
| Atmospheric | OCO-2, TROPOMI, GOSAT | CO2, CH4, NO2, ozone, aerosols |
| Ocean Color | MODIS, VIIRS, Sentinel-3 | Chlorophyll, turbidity, ocean health |
| Altimetry | Jason-3, Sentinel-6 | Sea level, ocean topography |
| Gravity | GRACE-FO | Groundwater, ice mass, sea level |
| Precipitation | GPM, TRMM | Rainfall, snowfall intensity |
| Night Lights | VIIRS DNB | Economic activity, urbanization |

## Ingestion Pipeline

1. **Tasking** — Request satellite observations for specific regions/times.
2. **Acquisition** — Receive data from satellite operators.
3. **Preprocessing** — Georeference, calibrate, atmospheric correction.
4. **Extraction** — Extract observed variables from raw imagery.
5. **Validation** — Quality checks against known baselines.
6. **Observation Creation** — Create structured observation record.

## Data Sources

- NASA Earth Observing System.
- ESA Copernicus Programme.
- JAXA, ISRO, CNSA.
- Commercial providers (Maxar, Planet, ICEYE, Capella).
- NOAA, EUMETSAT operational satellites.
