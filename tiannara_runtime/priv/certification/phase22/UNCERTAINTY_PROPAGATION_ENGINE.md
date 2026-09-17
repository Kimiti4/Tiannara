# Uncertainty Propagation Engine

## Purpose

Quantify, propagate, and preserve all forms of uncertainty through the forecasting process. Uncertainty is never hidden, averaged away, or discarded.

## Uncertainty Sources

### Observation Uncertainty
- Measurement error in civilization state variables
- Sampling uncertainty in evidence collection
- Instrument and methodology limitations

### Knowledge Gaps
- Unknown unknowns in civilizational dynamics
- Incomplete scientific understanding
- Unmodeled causal relationships
- Missing historical analogies

### Model Error
- Structural model simplifications
- Approximation errors in dynamics equations
- Parameter estimation uncertainty
- Boundary condition sensitivity

### Simulation Error
- Numerical precision limitations
- Temporal and spatial discretization error
- Stochastic approximation error (deterministic seeds)

### External Unknowns
- Exogenous events beyond model scope
- Natural phenomena with unknown timing
- Civilizational black swans
- True uncertainty (cannot be quantified)

### Long-Horizon Divergence
- Exponential divergence of trajectories over time
- Chaos sensitivity to initial conditions
- Horizon-dependent confidence collapse

## Uncertainty Representation

### Probability Distributions
- Normal, log-normal, beta, uniform, triangular distributions
- Empirical distributions from ensemble results
- Mixture distributions for multi-modal uncertainty

### Interval Representation
- Ranges with upper and lower bounds
- Confidence intervals at multiple levels (50%, 75%, 90%, 95%, 99%)
- Horizon-interval relationship functions

### Qualitative Uncertainty
- Known unknowns (categorized and tracked)
- Unknown unknowns (acknowledged but unquantified)
- Structural uncertainty (model limitations documented)

## Uncertainty Propagation Methods

### Monte Carlo Propagation
- Random sampling from input distributions
- Ensemble generation with sample size determination
- Convergence monitoring and stopping criteria

### Analytical Propagation
- Closed-form uncertainty propagation where tractable
- Taylor expansion-based uncertainty approximation
- Sensitivity-weighted uncertainty combination

### Scenario-Based Propagation
- Discrete scenario probability assignment
- Cross-scenario uncertainty comparison
- Scenario probability calibration

## Uncertainty Quality Metrics

- **Uncertainty Calibration**: Predicted vs. actual outcome distribution match
- **Uncertainty Sharpness**: Precision of uncertainty estimates
- **Coverage Probability**: Actual coverage of confidence intervals
- **Horizon Uncertainty Scaling**: Uncertainty growth with horizon

## Constraints

- Uncertainty must be explicitly represented in every forecast
- Uncertainty records become constitutional artifacts
- Known limitations of uncertainty methods are documented
