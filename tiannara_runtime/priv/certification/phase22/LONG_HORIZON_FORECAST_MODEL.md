# Long-Horizon Forecast Model

## Purpose

Generate evidence-based forecasts across civilization-scale time horizons, with appropriate methodology selection and explicit confidence degradation for each horizon.

## Forecast Horizons

| Horizon | Range | Methodology | Expected Confidence |
|---|---|---|---|
| Near-Term | 0–5 years | Trend extrapolation, short-term dynamics | Moderate-High |
| Short-Range | 5–10 years | Causal models, scenario analysis | Moderate |
| Medium-Range | 10–25 years | Simulation ensembles, analogy matching | Low-Moderate |
| Long-Range | 25–50 years | Multi-scenario ensembles, structural models | Low |
| Extended | 50–100 years | Qualitative scenarios, trend envelopes | Very Low |
| Multi-Generational | 100–250 years | Civilization-scale archetypes, broad envelopes | Speculative |
| Century-Scale | 250–500 years | Fundamental constraints, physical limits | Highly Speculative |
| Millennial | 500–1000+ years | Physical and constitutional bounds only | Minimal |

## Horizon-Appropriate Methodology

### Near-Term to Short-Range (0–10 years)
- Historical trend analysis with short-term dynamics
- Existing institutional and infrastructure inertia
- Near-term committed developments

### Short-Range to Medium-Range (5–25 years)
- Causal models with feedback loops
- Scenario generation with moderate parameter variation
- Decision point identification and branching analysis

### Long-Range to Extended (25–100 years)
- Multi-scenario ensembles with wide parameter ranges
- Structural regime shift modeling
- Uncertainty-dominated trajectory envelopes

### Multi-Generational and Beyond (100+ years)
- Civilizational archetype analysis
- Physical and resource constraint bounding
- Constitutional principle-based long-term trajectories
- Broad civilization development envelopes

## Horizon Confidence Model

Confidence decreases with horizon according to:

```
Confidence(h) = Confidence(0) × exp(-h / τ)
```

Where τ is the characteristic confidence decay timescale, calibrated to observed forecast accuracy decay.

## Horizon-Specific Output

Each horizon produces:

- **Central Trajectory**: Most likely outcome path
- **Confidence Envelope**: Bounded uncertainty region
- **Key Uncertainties**: Dominant uncertainty sources at this horizon
- **Signposts**: Events that would increase or decrease confidence
- **Horizon-Specific Risks**: Risks that become relevant at this horizon

## Constraints

- Confidence must explicitly decrease with horizon
- Long-horizon forecast records become constitutional artifacts
- Methodology must be appropriate to horizon scale
