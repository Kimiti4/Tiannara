# Multi-Reviewer Architecture

## Purpose

Coordinate multiple independent reviewers operating in parallel on the same scientific artifact. Reviewers are drawn from different subsystems to ensure independence.

## Reviewer Types

| Reviewer Source | Independence |
|----------------|-------------|
| Discovery Engine | Independent from theory synthesis |
| Theory Synthesis Engine | Independent from experiments |
| Experiment Orchestrator | Independent from engineering |
| Engineering Runtime | Independent from science |
| Cross-Domain Engine | Checks cross-domain consistency |
| Independent Constitutional Reviewer | Purely constitutional perspective |

## Coordination Model

1. Artifact submitted for review
2. Reviewer pool selected from available independent sources
3. Each reviewer produces independent critique
4. Critiques are collected before any reviewer sees others' results
5. Review Consensus Engine aggregates all critiques
6. Individual critiques remain visible alongside consensus

## Properties

- Reviewers operate in parallel without communication
- Reviewers are blind to each other's identities
- Review order is deterministic
- Review independence is measured and reported
