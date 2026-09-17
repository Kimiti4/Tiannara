# Discovery Clustering Engine

## Purpose

Group validated discoveries into clusters that share structural properties,
enabling mechanism and pattern extraction for theory formation.

## Clustering Dimensions

| Dimension | Description |
|-----------|-------------|
| Shared Evidence | Discoveries referencing the same observed phenomena |
| Shared Mechanisms | Discoveries that invoke the same causal or physical mechanism |
| Shared Predictions | Discoveries whose predictions overlap or agree |
| Shared Variables | Discoveries operating on the same measurable variables |
| Shared Constraints | Discoveries governed by the same boundary conditions |
| Shared Domains | Discoveries within the same scientific domain |
| Cross-Domain Relationships | Discoveries from different domains exhibiting structural similarity |
| Hidden Common Structure | Latent shared structure not yet explicitly identified |

## Cluster Properties

Each cluster records:
- Member discovery IDs
- Similarity scores per dimension
- Cluster centroid (if applicable)
- Cluster formation timestamp
- Cluster modification history
- Evidence for cluster cohesion
- Uncertainty of cluster boundaries

## Deterministic Clustering

All clustering operations use deterministic algorithms operating on
the discovery evidence graph. Re-clustering the same evidence set
produces identical results.

## Output

Clusters feed into Mechanism Extraction and Pattern Extraction stages.
