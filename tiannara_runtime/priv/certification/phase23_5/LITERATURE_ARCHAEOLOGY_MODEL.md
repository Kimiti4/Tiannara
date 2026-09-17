# Literature Archaeology Model

## Purpose

Reconstruct the complete history of how scientific literature influenced
Tiannara's knowledge: why specific publications influenced theories,
which claims were rejected and why, how consensus evolved over time,
and which discoveries originated from external literature.

## Reconstructable Questions

- Why did this publication influence theory formation?
- Which claims from this publication were integrated and which rejected?
- How did consensus on a topic evolve as new publications arrived?
- What evidence caused a change in credibility?
- Which research gaps were identified and how were they filled?
- How did external literature shape Tiannara's own research directions?

## Archaeological Queries

| Query | Description |
|-------|-------------|
| PublicationInfluence(id) | How a publication affected Tiannara's knowledge |
| ClaimAdoption(claim_id) | Whether and how a claim was adopted |
| ConsensusEvolution(topic) | How consensus changed over time |
| GapResolution(gap_id) | How a research gap was filled |
| ExternalInfluence(domain) | How external literature shaped a domain |
| KnowledgeSource(claim_id) | All publications supporting a claim |

## Preservation

- All literature events are permanently preserved
- No pruning or summarization of literature history
- Archaeology operates on the same event log as replay
