# Pareto Frontier Model

## Purpose

Represent all non-dominated civilization designs — solutions where no objective can be improved without degrading another.

## Solution Structure

Each Pareto solution contains:
- **Solution ID**: Content-addressed identifier
- **Objective Vector**: Scores across all optimization objectives
- **Constraint Satisfaction**: Status of all constitutional constraints
- **Tradeoff Profile**: Explicit trade-offs made in this solution
- **Design Reference**: Link to the civilization engineering design
- **Confidence**: Confidence in solution evaluation (0.0–1.0)
- **Replay Root**: Content-addressed replay identifier
- **Archaeology Root**: Content-addressed archaeology identifier

## Pareto Concepts

### Dominance
Design A dominates Design B if A is at least as good in all objectives and strictly better in at least one.

### Pareto-Optimal
Designs not dominated by any other feasible design in the search space.

### Pareto Frontier
The set of all Pareto-optimal designs discovered.

### Frontier Evolution
The frontier grows and shifts as the search progresses and as civilization state changes.

## Frontier Properties

- **Completeness**: How much of the true frontier has been discovered
- **Spread**: How broadly the frontier covers objective space
- **Uniformity**: How evenly solutions are distributed along the frontier
- **Stability**: How much the frontier changes with new evaluations

## Frontier Management

- Add new non-dominated solutions
- Remove dominated solutions
- Track frontier history across generations
- Support frontier visualization and analysis

## Constraints

- No single "perfect civilization" is assumed
- Pareto solutions preserve provenance
- Frontier records become constitutional artifacts
