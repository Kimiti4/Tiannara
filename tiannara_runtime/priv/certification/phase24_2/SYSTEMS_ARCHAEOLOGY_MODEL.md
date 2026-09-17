# Systems Archaeology Model

## Purpose

Reconstruct the complete history of systems engineering decisions: why requirements existed, why architectures changed, why interfaces evolved, why risks emerged, why subsystems were redesigned, and the complete systems engineering lineage.

## Reconstructable Questions

- Why did this requirement exist?
- Why did the architecture change at a specific point?
- Why did an interface specification evolve?
- Why did a new risk emerge?
- Why was a subsystem redesigned?
- What was the complete lineage of a system requirement?

## Archaeological Queries

| Query | Description |
|-------|-------------|
| RequirementOrigin(req_id) | Why and how a requirement was created |
| ArchitectureEvolution(arch_id) | How architecture changed over time |
| InterfaceHistory(interface_id) | Complete interface decision trail |
| RiskEmergence(risk_id) | Why and when a risk was identified |
| RedesignRationale(subsystem_id) | Why a subsystem was redesigned |
| RequirementLineage(req_id) | Complete ancestry of a requirement |

## Preservation

- All systems engineering events are permanently preserved
- No pruning or summarization of systems engineering history
- Archaeology operates on the same event log as replay
