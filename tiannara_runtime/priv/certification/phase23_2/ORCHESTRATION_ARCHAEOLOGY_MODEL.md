# Orchestration Archaeology Model

## Purpose

The Orchestration Archaeology Model enables reconstruction of why orchestration decisions were made, how research programs evolved, what discoveries reshaped the portfolio, and why experiments ended as they did. Archaeology provides the scientific narrative behind every decision.

## Archaeological Questions

The model answers:
- Why were specific experiments chosen over alternatives?
- Why did priorities change over time?
- Why did experiments fail?
- Why were resources allocated in particular ways?
- How did research programs evolve?
- What discoveries reshaped the portfolio?
- What hypotheses were abandoned and why?
- What theories were revised and why?

## Archaeology Architecture

```
┌─────────────────────────────────────────────────────────┐
│             Orchestration Archaeology Engine             │
├─────────────────────────────────────────────────────────┤
│  Decision Trace Layer                                   │
│  ├─ Every decision links to its inputs                  │
│  ├─ Every decision links to its context                 │
│  └─ Every decision links to its rationale               │
├─────────────────────────────────────────────────────────┤
│  Program Evolution Layer                                │
│  ├─ Program state over time                             │
│  ├─ Program milestones and transitions                  │
│  └─ Program termination causes                          │
├─────────────────────────────────────────────────────────┤
│  Discovery Impact Layer                                 │
│  ├─ Discovery influence on portfolio                    │
│  ├─ Discovery-driven priority changes                   │
│  └─ Discovery-spawned experiments                       │
├─────────────────────────────────────────────────────────┤
│  Narrative Reconstruction Layer                         │
│  ├─ Natural language description of decision chains     │
│  ├─ Causal narrative of research evolution              │
│  └─ Summary of scientific journey                       │
└─────────────────────────────────────────────────────────┘
```

## Archaeology Record

```
OrchestrationArchaeology {
  archaeology_id: content-addressed,
  epoch: integer,
  decision_trace: [
    {
      decision_id: reference,
      decision_type: enum,
      timestamp: integer,
      inputs: [content_hash],
      rationale: string,
      context: {portfolio_state, priority_state, resource_state},
      alternatives_considered: [{alternative, rejection_reason}],
      outcome: content_hash
    }
  ],
  program_evolution: {
    program_id: reference,
    timeline: [{timestamp, state, transition}],
    milestones: [{timestamp, milestone, evidence}],
    termination: {reason, timestamp} (optional)
  },
  discovery_impact: [
    {
      discovery_id: reference,
      impacted_decisions: [decision_id],
      priority_changes: [{experiment, old, new, reason}],
      spawned_items: [item_id]
    }
  ],
  narrative: string,
  archaeology_hash: string,
  timestamp: integer
}
```

## Narrative Generation

The archaeology engine generates human-readable narratives:
- "Experiment X was chosen over Y because..."
- "Priority shifted from Domain A to Domain B after discovery of..."
- "Program C was restructured because..."
- "Experiment D failed because..."

## Archaeology Queries

| Query | Description |
|-------|-------------|
| Decision Chain | Trace all decisions leading to an outcome |
| Program Timeline | Full history of a research program |
| Discovery Influence | All decisions influenced by a discovery |
| Resource History | How resources were allocated over time |
| Failure Analysis | Why experiments failed and what was learned |
| Priority Evolution | How priorities changed and why |
| Cross-Domain Influence | How domains influenced each other |
