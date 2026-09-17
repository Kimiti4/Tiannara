# Collaboration Archaeology Model

## Purpose

Reconstruct the complete history of scientific collaborations: who collaborated, why teams formed, how discoveries emerged, which institutions contributed, how consensus evolved, and complete contribution lineage.

## Reconstructable Questions

- Who collaborated on a specific discovery?
- Why was this team formed?
- How did a discovery emerge from collaboration?
- Which institutions contributed to a research program?
- How did scientific consensus evolve across participants?
- What was the complete contribution lineage of an artifact?

## Archaeological Queries

| Query | Description |
|-------|-------------|
| CollaborationHistory(problem) | All collaborations on a research problem |
| ParticipantContributions(id) | All contributions by a participant |
| TeamFormationRationale(id) | Why a team was formed |
| KnowledgeFlow(source, target) | How knowledge moved between participants |
| NetworkEvolution(time_range) | How the collaboration network evolved |
| InstitutionImpact(id) | All contributions from an institution |

## Preservation

- All collaboration events are permanently preserved
- No pruning or summarization of collaboration history
- Archaeology operates on the same event log as replay
