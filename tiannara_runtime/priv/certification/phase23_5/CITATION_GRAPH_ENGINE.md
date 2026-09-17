# Citation Graph Engine

## Purpose

Build and maintain a constitutional citation graph that captures lineage,
influence, communities, and knowledge diffusion across the scientific
literature.

## Graph Components

| Component | Description |
|-----------|-------------|
| Publication Nodes | Each publication is a node |
| Citation Edges | Directed edges from citing to cited |
| Citation Context | The specific claims or sections that reference a citation |
| Citation Strength | How central the citation is to the citing work |
| Citation Influence | How many subsequent works are influenced |
| Citation Communities | Clusters of mutually citing publications |

## Citation Types

| Type | Description |
|------|-------------|
| Direct | Explicit citation in the reference list |
| Methodological | Citing a method or technique |
| Foundational | Citing foundational theoretical work |
| Comparative | Citing work that is compared or contrasted |
| Contradictory | Citing work that is contradicted |
| Supportive | Citing work that supports the current claims |

## Graph Properties

- All citation edges are attributed (type, context, strength)
- Citation context is extractable from the citing text
- The graph tracks citation evolution over time
- Citation communities are dynamic and revisable
