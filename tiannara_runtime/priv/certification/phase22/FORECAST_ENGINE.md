# Forecast Engine

## Purpose

Execute deterministic civilization forecasts, managing multiple forecast models and ensemble generation.

## Forecast Models

### Trend Extrapolation Model
- Historical trend continuation with uncertainty bounds
- Logistic, exponential, and saturation growth models
- Regime shift detection and adjustment

### Causal Forecast Model
- Causal relationship-based prediction
- Intervention effect estimation
- Feedback loop modeling

### Simulation-Based Forecast Model
- Monte Carlo ensemble from civilization simulator
- Parameter uncertainty propagation
- Outcome distribution estimation

### Analogy-Based Forecast Model
- Historical analogy matching
- Analogous civilization trajectory mapping
- Similarity-weighted outcome averaging

## Forecast Execution

1. **Initialize**: Select forecast model and parameters
2. **Input**: Current civilization state and evidence base
3. **Generate Baseline**: Produce baseline forecast trajectory
4. **Apply Uncertainty**: Propagate uncertainties through model
5. **Generate Ensemble**: Produce forecast ensemble with distribution
6. **Record**: Generate complete forecast artifact

## Ensemble Generation

Each forecast produces an ensemble of trajectories:

- Mean trajectory with confidence intervals
- Percentile trajectories (5th, 25th, 50th, 75th, 95th)
- Extreme scenario trajectories
- Modal trajectory clusters

## Forecast Structure

Each forecast contains:

- **Forecast ID**: Content-addressed identifier
- **Forecast Model**: Model type and parameters
- **Prediction Horizon**: Time span of the forecast
- **Starting State**: Civilization state at forecast creation
- **Assumptions**: All assumptions underlying the forecast
- **Evidence Base**: Evidence used for forecast construction
- **Scenario Set**: Scenarios included in the forecast
- **Confidence Distribution**: Uncertainty representation
- **Critical Decision Points**: Key branching events identified
- **Expected Outcomes**: Predicted outcomes with probabilities
- **Risk Factors**: Identified risks and their impact
- **Fingerprint**: Deterministic content hash

## Constraints

- Forecasts must be fully deterministic
- Forecast records become constitutional artifacts
- Forecasts are never treated as truth
