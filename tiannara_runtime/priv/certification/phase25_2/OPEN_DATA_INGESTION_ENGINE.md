# Open Data Ingestion Engine

## Purpose

Define the engine that ingests observations from public open data sources.

## Data Sources

- International organizations (UN, World Bank, WHO, FAO, IEA, IMF).
- Government open data portals (data.gov, data.gov.uk, EU Open Data Portal).
- Environmental monitoring networks.
- Economic and financial data providers.
- Demographic and social statistics.
- Climate and weather data services.
- Transportation and infrastructure data.
- Health and disease surveillance data.
- Educational statistics.
- Scientific funding databases.

## Ingestion Pipeline

1. **Source Registration** — Register data source in source registry.
2. **Harvest Schedule** — Define harvest frequency based on source update pattern.
3. **Harvest** — Download data via API, FTP, or direct download.
4. **Parse** — Transform source format to standard observation format.
5. **Validate** — Check completeness, consistency, and freshness.
6. **Observation Creation** — Create structured observations.
7. **Source Health Update** — Update source health metrics.

## Data Quality

- Source reliability tracked historically.
- Data freshness monitored.
- Schema changes detected and handled.
- Missing data flagged and reported.
- Data quality metrics reported to observatory.
