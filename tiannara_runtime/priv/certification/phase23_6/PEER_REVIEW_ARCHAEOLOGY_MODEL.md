# Peer Review Archaeology Model

## Purpose

Reconstruct the complete history of scientific critique: why discoveries were challenged, why theories were revised, how consensus changed, what criticisms improved science, and the complete review lineage of every artifact.

## Reconstructable Questions

- Why was this discovery challenged?
- What objections were raised and how were they resolved?
- How did reviewer consensus evolve?
- Which criticisms led to theory revision?
- What reproducibility issues were identified?
- How did peer review improve scientific quality?

## Archaeological Queries

| Query | Description |
|-------|-------------|
| ReviewHistory(id) | Complete review history of an artifact |
| ObjectionTimeline(claim_id) | All objections raised against a claim |
| ConsensusEvolution(artifact_id) | How consensus changed across review rounds |
| CriticImpact(critic_id) | How a specific critique changed science |
| ReproducibilityTrack(claim_id) | Reproducibility assessments over time |

## Preservation

- All review events are permanently preserved
- No pruning or summarization of review history
- Archaeology operates on the same event log as replay
