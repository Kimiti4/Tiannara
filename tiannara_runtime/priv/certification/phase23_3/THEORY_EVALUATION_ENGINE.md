# Theory Evaluation Engine

## Purpose

Score theories across multiple dimensions to enable comparison, competition,
and selection. All scores remain transparent and traceable to the data.

## Scoring Dimensions

| Dimension | Description |
|-----------|-------------|
| Predictive Accuracy | How well theory predictions match observations |
| Explanatory Power | How much evidence the theory explains |
| Engineering Utility | What the theory enables building or controlling |
| Scientific Simplicity | Occam's razor — fewest assumptions wins |
| Evidence Strength | Quality and quantity of supporting evidence |
| Generality | Breadth of the theory's scope |
| Robustness | Sensitivity to assumption violations |
| Reproducibility | How reliably results can be reproduced |
| Cross-Domain Utility | Applicability outside original domain |
| Uncertainty | Calibration of confidence estimates |

## Score Properties

- Each score includes a confidence interval
- Scores are recalculated when new evidence arrives
- Score decomposition: contributors to each score are visible
- Scores are comparable only within similar domains
- No single aggregate score — theories are multi-dimensional

## Evaluation Process

1. Gather evidence for each scoring dimension
2. Calculate dimension scores with uncertainty
3. Record score breakdown (what contributed)
4. Update theory metadata with latest scores
5. Notify Theory Ecology Engine of score changes
