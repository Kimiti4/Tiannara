# Risk Priority Engine

## Purpose

Define the engine that prioritizes risks for attention and intervention.

## Priority Factors

Every risk is scored on:
- **Probability** — Likelihood of occurrence (0–1).
- **Severity** — Expected impact if occurs (0–1).
- **Urgency** — How soon action needed (0–1).
- **Cascading Potential** — Ability to trigger other risks (0–1).
- **Recoverability** — Difficulty of recovery after event (inverted, 0–1).
- **Uncertainty** — Level of uncertainty in assessment (0–1).
- **Constitutional Significance** — Relevance to constitutional principles (0–1).

## Priority Score

Composite priority = weighted combination of factors, with weights configurable through constitutional governance.

## Priority Tiers

| Tier | Score Range | Action |
|---|---|---|
| Critical | 0.8–1.0 | Immediate escalation to Planetary Council |
| High | 0.6–0.8 | Escalate to Engineering Council |
| Medium | 0.4–0.6 | Monitor, prepare intervention options |
| Low | 0.2–0.4 | Routine monitoring |
| Informational | 0.0–0.2 | Log and track |
| Unknown | N/A | Flag for investigation |

## Priority Review

- Priority scores reviewed and updated on each risk assessment cycle.
- Priority changes tracked in risk event log.
- Priority disagreements flagged for human review.
- Priority methodology reviewed periodically.
