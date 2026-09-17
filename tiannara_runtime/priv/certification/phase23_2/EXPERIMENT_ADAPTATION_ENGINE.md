# Experiment Adaptation Engine

## Purpose

The Experiment Adaptation Engine enables constitutional adaptation of experiments in response to monitoring data, discoveries, resource changes, or constitutional directives. Adaptation must never erase historical lineage — every modification is recorded as a new version.

## Adaptation Actions

| Action | Description | Lineage Preserved |
|--------|-------------|-------------------|
| Continue | No change, proceed as planned | Original experiment unchanged |
| Pause | Suspend execution temporarily | State preserved for resume |
| Reschedule | Move to different time slot | Original schedule recorded |
| Expand | Add scope, parameters, or phases | New version created |
| Split | Divide into independent experiments | Both trace to original |
| Merge | Combine with another experiment | Both originals preserved |
| Cancel | Terminate without completion | Cancellation recorded |
| Escalate | Elevate priority or resource allocation | Priority change recorded |

## Adaptation Triggers

| Trigger | Source | Evaluation |
|---------|--------|------------|
| Monitoring Alert | Monitoring Engine | Adaptation engine evaluates severity |
| Discovery Event | Discovery Feedback Engine | New information changes experiment value |
| Resource Change | Resource Allocation Engine | Availability changes impact feasibility |
| Priority Change | Priority Engine | Re-prioritization affects scheduling |
| Constitutional Mandate | Governance | External directive requires change |
| Dependency Change | Dependency Engine | Prerequisite experiment modifies output |
| Time Threshold | Scheduling Engine | Experiment exceeded time allocation |

## Adaptation Decision Model

```
AdaptationDecision {
  decision_id: content-addressed,
  experiment_id: reference,
  trigger: {source, event_id, timestamp},
  action: enum,
  rationale: string,
  alternative_actions: [{action, rationale}],
  approved_by: constitutional_reference,
  original_state: experiment_snapshot,
  new_state: experiment_snapshot,
  decision_hash: string,
  timestamp: integer
}
```

## Lineage Preservation

Every adaptation creates an immutable record:
- Before-state is captured
- After-state is captured
- Decision rationale is recorded
- Alternatives considered are documented
- Approval chain is stored

## Adaptation Guardrails

The adaptation engine shall:
- Never alter recorded evidence
- Never erase failed experiments
- Never rewrite history
- Always preserve original experiment design
- Always create new version instead of modifying
- Always obtain constitutional approval for critical changes
