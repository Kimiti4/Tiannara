# Long-Horizon Prediction Engine

## Purpose

Generate predictions across multiple time horizons, with explicit uncertainty calibration and confidence decay.

## Horizon Definitions

- **Near-term** (1–5 years): High resolution, low uncertainty (0.05–0.15)
- **Medium-term** (5–25 years): Moderate resolution, bounded uncertainty (0.15–0.35)
- **Long-term** (25–100 years): Directional resolution, high uncertainty (0.35–0.60)
- **Multi-generational** (100–500 years): Broad trajectory, very high uncertainty (0.60–0.85)
- **Century-scale** (500–1000 years): Visionary, extreme uncertainty (0.85–0.95)

## Prediction Methodology

### Extrapolation
- Current trends extended with uncertainty bounds
- Historical analogs for similar transitions
- Theoretical upper and lower bounds

### Model-Based Prediction
- Reality model simulated forward
- Causal chain projections
- Cross-domain interaction modeling

### Evidence Calibration
- Historical forecast accuracy tracked
- Calibration corrections applied per domain
- Overconfidence systematically corrected

## Confidence Decay Function

Confidence decreases with horizon distance:
```
confidence(h) = confidence_0 × exp(-h / decay_constant)
```
Where h is horizon distance and decay_constant is domain-specific.

## Multi-Horizon Consistency

- Predictions at different horizons must be mutually consistent
- Near-term predictions constrain medium-term
- Medium-term predictions inform long-term
- All horizons derived from same reality model

## Constraints

- All predictions must be evidence-derived
- Confidence must decrease with horizon
- Calibration must be measured and applied
- Prediction records become constitutional artifacts
