# Intervention Modeling Engine

## Purpose
Models the expected outcomes of interventions — given a strategy and the current planetary state, project the likely trajectory across all relevant domains.

## Modeling Approach

### Digital Twin Integration
- Load current planetary state from PSE
- Load the digital twin scenario from CPDT
- Apply intervention actions to the twin
- Simulate forward under multiple scenarios

### Outcome Dimensions
- **Primary** — direct intended effects (e.g., CO2 reduction, infrastructure restored)
- **Secondary** — indirect effects (e.g., economic impact of infrastructure restoration)
- **Tertiary** — systemic effects (e.g., changed behavior patterns)
- **Side Effects** — unintended consequences (e.g., ecological disruption)

### Time Horizons
- Short-term (days to months)
- Medium-term (months to years)
- Long-term (years to decades)
- Legacy (decades to centuries)

### Output
A structured projection with: before/after state comparison, probability distributions for each outcome dimension, confidence intervals, key assumptions, and sensitivity analysis.
