# Scenario Branching Engine

## Purpose

Represent scenario trees where each branch represents a distinct future path. Support multiple competing futures simultaneously.

## Branching Model

Discovery → Initial Branch → Branch → Branch → Validated Futures

At each branching point:
- Multiple branches are possible
- Branches are distinguished by key variables
- Branch probabilities are recorded with uncertainty
- Branches can converge or diverge
- Dead-end branches are removed but preserved archaeologically

## Tree Properties

- Trees are fully deterministic given assumptions
- Branching points are recorded with their rationale
- Pruned branches remain archaeologically accessible
- Tree structure supports observatory visualization
