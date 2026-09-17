# Downstream Leverage Analysis

## Purpose

Analyze which discoveries, if made, would unlock the greatest downstream scientific, engineering, and civilizational value.

## Leverage Types

| Type | Description |
|------|-------------|
| Scientific Leverage | Enables many future discoveries |
| Engineering Leverage | Enables many technologies and systems |
| Economic Leverage | Enables productive industries |
| Civilizational Leverage | Enables capability jumps |

## Analysis Method

- Query the discovery dependency graph for out-degree and path counts
- Weight edges by estimated impact magnitude
- Compute criticality scores (fraction of paths that pass through a node)
- Identify bottlenecks (nodes with high criticality but low research attention)
- Rank discoveries by composite leverage score

## Properties

- Leverage scores are updated as the dependency graph evolves
- Leverage analysis is fully replayable
- Bottlenecks receive additional research priority
- Leverage scores include uncertainty estimates
