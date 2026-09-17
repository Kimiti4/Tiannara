# Transfer Adaptation Engine

## Purpose

Adapt validated transfers from source domain to target domain, translating
variables, constraints, units, scales, and causal relationships while
preserving the original lineage and evidence chain.

## Adaptation Dimensions

| Dimension | Translation |
|-----------|-------------|
| Variable | Map source variables to target variables |
| Constraint | Adapt boundary conditions and conservation laws |
| Unit | Convert measurement units and scales |
| Scale | Adjust for differences in time, space, magnitude |
| Causal | Preserve causal structure under different semantics |
| Semantic | Maintain meaning across domain vocabularies |

## Adaptation Properties

- Original source is never modified
- Adapted version maintains a provenance link to source
- All translation decisions are recorded and justified
- Adaptation uncertainty is quantified
- Multiple adaptations of the same source can coexist

## Constitutional Rules

- Adaptation must preserve the original evidence chain
- Adaptation must not fabricate new evidence
- Adapted knowledge is provisional until independently validated
- Adaptation lineage is fully replayable
