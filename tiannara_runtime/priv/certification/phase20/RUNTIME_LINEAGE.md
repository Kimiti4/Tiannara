# Phase 20.5 — Runtime Lineage

## Overview

Runtime Lineage preserves the complete evolutionary history of every runtime generation from genesis through any number of generations. The lineage forms a directed acyclic graph rooted at generation 0. No generation is ever removed from the lineage.

## Lineage Structure

The lineage is a DAG where:
- Each node is a RuntimeGeneration (immutable, frozen)
- Each edge is a migration (source → target)
- Branches create divergence (one parent → multiple children)
- Merges create convergence (multiple parents → one child)
- Rollbacks create re-convergence (child → ancestor)

```
Generation 0 (genesis, Production)
    │
    ├── Generation 1 (Production, minor fix)
    │       │
    │       ├── Generation 2 (Production, feature)
    │       │       │
    │       │       ├── Generation 3 (Production, feature) ←── Generation 4 (Experimental, research)
    │       │       │                                            (merge into 3 via certification)
    │       │       │
    │       │       └── Generation 5 (Experimental, candidate test)
    │       │
    │       └── Generation 6 (Emergency, hotfix)
    │               │
    │               └── Generation 7 (Production, after hotfix certified)
    │
    └── Generation 8 (Research, long-term exploration)
            │
            └── Generation 9 (Research, sub-branch)
```

## Lineage Properties

| Property | Description |
|----------|-------------|
| Immutable | No node or edge is ever modified or deleted |
| Append-only | New nodes and edges are only added, never removed |
| Traceable | Every node has a complete ancestry path to genesis |
| Reconstructable | Full lineage can be rebuilt from cold storage |
| Verifiable | Every edge has a cryptographic hash linking parent to child |

## Lineage Tracking

Each generation stores:

| Field | Description |
|-------|-------------|
| generation_id | Content-addressed identifier |
| parent_generation | Reference to parent generation (null for genesis) |
| branch | Constitutional branch this generation belongs to |
| migration_id | Reference to migration that produced this generation |
| merge_source | If a merge, reference to source branch generation |
| constitutional_hash | SHA-256 of complete generation state |
| lineage_depth | Distance from genesis (genesis = 0) |

## Lineage Operations

### Forward Traversal
Starting from any generation, follow child references to reconstruct forward evolution. Returns ordered list of descendant generations.

### Backward Traversal
Starting from any generation, follow parent references to reconstruct ancestry. Returns ordered list of ancestor generations back to genesis.

### Branch Query
Return all generations belonging to a specific branch, in chronological order.

### Merge History
Return all merges and rollbacks for a specific generation or branch.

### Lineage Comparison
Compare two generations to find their common ancestor (lowest common ancestor in DAG).

## Lineage Registry

| Function | Description |
|----------|-------------|
| add_node | Register a new generation in the lineage |
| add_edge | Register a migration or merge edge |
| ancestry | Return ancestry path from generation to genesis |
| descendants | Return all descendant generations |
| common_ancestor | Find lowest common ancestor of two generations |
| branch_lineage | Return all generations on a given branch |
| merge_history | Return all merges involving a generation |
