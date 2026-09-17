# Observation Engine

## Purpose

The Observation Engine continuously collects, classifies, and records observations from all available sources. Observations are the foundation of all scientific discovery — every discovery begins with an observation that reveals something unknown.

## Observation Sources

| Source | Description | Examples |
|--------|-------------|----------|
| Runtime | Internal system behavior | Performance metrics, state changes, errors |
| Experiments | Experimental outcomes | Simulation results, validation results |
| Planetary Models | Twin world observations | Population dynamics, entropy, pressure |
| Engineering | Engineering feedback | Build results, test outcomes, failures |
| External Data | Imported data sources | Published datasets, sensor data |
| Scientific Literature | External knowledge | Papers, theories, experimental results |
| Internal Contradictions | Self-detected inconsistencies | Conflicting evidence, prediction failures |
| Unknown Registry | Registered unknowns | Explicitly marked knowledge gaps |

## Observation Classification

Every observation is classified along multiple dimensions:

| Dimension | Categories |
|-----------|------------|
| Source | runtime, experiment, planetary, engineering, external, literature, contradiction, unknown |
| Type | measurement, event, state_change, anomaly, pattern, contradiction |
| Certainty | confirmed, suspected, ambiguous, unknown |
| Novelty | expected, unexpected, surprising, contradictory |
| Relevance | critical, high, medium, low, unknown |

## Observation Record

```
Observation {
  observation_id: content-addressed,
  source: enum,
  type: enum,
  data: map,
  timestamp: integer,
  certainty: enum,
  novelty: enum,
  relevance: enum,
  hash: string,
  previous_observation_id: string | nil
}
```

## Observation Lifecycle

```
Collection → Classification → Recording → Prioritization → Question Generation
```

1. **Collection**: Observations gathered from all sources
2. **Classification**: Source, type, certainty, novelty, relevance determined
3. **Recording**: Observation recorded immutably in CPL
4. **Prioritization**: Observations ranked by relevance and novelty
5. **Question Generation**: High-priority observations feed question generation
