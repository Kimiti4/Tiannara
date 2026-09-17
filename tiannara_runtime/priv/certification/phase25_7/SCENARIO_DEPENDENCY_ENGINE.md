# Scenario Dependency Engine

## Purpose
Maps dependencies between scenarios, branches, and evidence — understanding how scenarios relate to each other and what assumptions they share.

## Dependency Types

### Causal Dependencies
- Scenario A must happen before Scenario B can occur
- Scenario A causes Scenario B
- Scenario A prevents Scenario B

### Evidence Dependencies
- Scenarios that share the same evidence base
- Scenarios that would be confirmed or refuted by the same evidence
- Evidence that differentiates between scenarios

### Assumption Dependencies
- Scenarios that share common assumptions
- Critical assumptions that many scenarios depend on
- Assumption sensitivity (which scenario sets are robust to assumption changes)

### Probability Dependencies
- Competing scenarios (higher probability for one reduces others)
- Hierarchical scenarios (parent/child probabilities in branching tree)
- Mutually exclusive scenarios

## Dependency Graph
- Nodes: scenarios, branches, evidence, assumptions
- Edges: dependency relationships with type and strength
- Analysis: connected components, critical nodes, failure propagation

## Analysis
- Which scenarios are most interconnected?
- Which assumptions affect the most scenarios?
- What evidence would resolve the most dependencies?
- Where are the leverage points in the future space?

## Output
Scenario dependency graph, critical assumption identification, evidence prioritization, dependency propagation paths.
