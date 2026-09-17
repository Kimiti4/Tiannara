# Capability Matching Engine

## Purpose

Match research problem requirements to participant capabilities. Capability matching is evidence-based and explainable.

## Matching Dimensions

| Dimension | Evaluated Against |
|-----------|-------------------|
| Scientific Expertise | Domains, methods, techniques needed |
| Engineering Expertise | Design, build, test capabilities needed |
| Computational Resources | Compute, storage, network requirements |
| Simulation Resources | Simulation types and scales required |
| Experimental Capability | Lab equipment, facilities, materials |
| Knowledge Domains | Prior work in relevant areas |
| Historical Performance | Past collaboration success |
| Current Availability | Bandwidth and timeline constraints |

## Matching Process

1. Extract capability requirements from research problem
2. Score each candidate participant against requirements
3. Rank participants by match score
4. Present ranked list for team formation

## Constitutional Rules

- Matching is deterministic given same inputs
- Matching criteria are transparent and revisable
- Matching never discriminates on non-scientific grounds
- Matching scores are explainable per dimension
