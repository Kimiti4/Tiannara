# Unified Causal Graph

## Purpose

Define the unified directed acyclic causal graph spanning all constitutional layers, where every node represents a causal entity and every edge represents a verified causal relationship.

## Graph Structure

The Unified Causal Graph is a single constitutional artifact:

```
G = (N, E)

N = Set of causal nodes across all layers
E = Set of causal edges (directed, acyclic)
```

Sub-graphs may be extracted for domain-specific analysis while preserving full graph lineage.

## Causal Node

Every causal node contains:

- **Node ID**: Content-addressed identifier
- **Layer**: Constitutional layer (0–15)
- **Domain**: Scientific domain within layer
- **Observed Variables**: Directly measured quantities
- **Hidden Variables**: Inferred but unobserved quantities
- **Evidence**: Evidence supporting node existence
- **Confidence**: Confidence in node representation (0.0–1.0)
- **Mathematical Constraints**: Formal constraints on node behavior
- **Temporal Bounds**: Time range of node relevance
- **Spatial Bounds**: Spatial extent
- **Replay Root**: Hash for deterministic reconstruction
- **Archaeology Root**: Hash for lineage reconstruction

## Causal Edge

Every causal edge contains:

- **Edge ID**: Content-addressed identifier
- **Cause Node**: Source of causation
- **Effect Node**: Target of causation
- **Causal Type**: direct, indirect, conditional, feedback, constraint, emergence
- **Mechanism**: Physical/formal mechanism of causation
- **Evidence**: Evidence supporting causal relationship
- **Confidence**: Confidence in causal direction and strength (0.0–1.0)
- **Time Scale**: Characteristic time of causal propagation
- **Spatial Scale**: Characteristic spatial extent
- **Validation Status**: unverified, verified, contested, refuted

## Edge Types

### Direct Causation
A directly causes B with no intermediate nodes. Strongest causal claim.

### Indirect Causation
A causes B through a chain of intermediate nodes. Lineage preserved.

### Conditional Dependency
A and B are dependent conditional on context C. Probabilistic causality.

### Feedback
A affects B and B affects A. Represented as cyclic dependency with explicit time lag.

### Constraint
A constrains B's possible states without directly causing B. Top-down or bottom-up.

### Emergence
Lower-layer configuration gives rise to higher-layer property. Not reducible to lower-level causes alone.

## Graph Properties

- **Acyclic**: No causal cycles (feedback represented with temporal ordering)
- **Connected**: All nodes reachable through some path
- **Layered**: Nodes belong to exactly one layer
- **Provenanced**: Every node/edge traces to evidence
- **Versioned**: Graph evolves deterministically with full lineage

## Constraints

- No causal edge may be introduced without evidence
- Graph must remain acyclic (feedback handled via time-lagged edges)
- Graph records become constitutional artifacts
