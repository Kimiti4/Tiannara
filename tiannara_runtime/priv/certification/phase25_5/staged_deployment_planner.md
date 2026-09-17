# Staged Deployment Planner

## Purpose
Plans phased deployment of interventions — most planetary interventions should not be deployed all at once but in stages with evaluation between each stage.

## Stage Structure
Each deployment stage includes:
- **Stage ID** — unique identifier
- **Trigger Conditions** — conditions that must be met to enter this stage
- **Actions** — specific interventions to execute in this stage
- **Duration** — expected duration of the stage
- **Milestones** — measurable progress indicators
- **Evaluation Criteria** — how to determine if stage succeeded
- **Hold Points** — points where deployment pauses pending evaluation
- **Rollback Plan** — how to undo if stage fails
- **Next Stage Triggers** — conditions to advance to next stage

## Planning Considerations

### Phasing Logic
- Start with least risky, most reversible interventions
- Test on small scale before scaling
- Build dependencies before dependent interventions
- Maintain option value (don't foreclose future options)

### Contingency Planning
- What if stage fails?
- What if conditions change?
- What if new information emerges?
- What if resources are insufficient?

## Output
Staged deployment plan: sequence of stages with triggers, actions, milestones, evaluation criteria, hold points, rollback plans, and contingency responses.
