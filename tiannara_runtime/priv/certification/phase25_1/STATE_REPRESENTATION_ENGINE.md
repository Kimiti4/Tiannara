# State Representation Engine

## Purpose

Define the engine that manages how planetary state is represented, stored, and queried.

## State Representation

Every state value is represented as:
```
{
  domain: string,
  variable: string,
  region: string,
  time: TimeRange,
  value: any,
  unit: string,
  confidence: float,
  uncertainty: Uncertainty,
  provenance: ProvenanceChain,
  version: integer,
  certified: boolean,
  metadata: object
}
```

## State Storage

- **Current State** — Latest certified state (in-memory, indexed).
- **Version History** — All versions of each state variable (time-series storage).
- **Snapshot Store** — Complete domain snapshots at checkpoints.
- **Observation Store** — Raw observations that feed state.

## State Queries

- **Point Query** — State at specific time and location.
- **Range Query** — State over time range.
- **Aggregation Query** — Statistical aggregation over region or time.
- **Comparison Query** — Compare state across times or regions.
- **Lineage Query** — Full provenance chain for a state value.

## State Indexing

- Temporal index (time range → state values).
- Spatial index (region → state values).
- Domain index (domain → state variables).
- Variable index (variable name → state values).
- Composite index (domain + variable + region + time).
