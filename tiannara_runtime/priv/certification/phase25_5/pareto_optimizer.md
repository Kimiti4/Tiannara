# Pareto Optimizer

## Purpose
Multi-objective optimization across competing strategies — finds the set of Pareto-optimal strategies that cannot be improved in one objective without degrading another.

## Objectives
- **Effectiveness** — total risk reduction achieved
- **Cost** — total resource consumption (minimized)
- **Risk** — probability of intervention failure or severe side effects
- **Speed** — time to achieve significant effect
- **Equity** — fairness of outcome distribution
- **Reversibility** — ability to undo if wrong

## Pareto Frontier

### Construction
- Enumerate feasible strategies after constraint checking
- Score each strategy on all objectives
- Identify Pareto-dominant strategies
- Generate Pareto frontier visualization

### Frontier Analysis
- Knee points (best tradeoff regions)
- Objective conflicts (which objectives compete)
- Sensitivity to preference weights

### Preference Integration
- Decision-makers provide preference weights or rankings
- Weighted scoring within Pareto-optimal set
- Ranked recommendation list

## Output
Pareto frontier with Pareto-optimal strategies, tradeoff curves, recommended strategy rankings under different preference scenarios, and sensitivity analysis.
