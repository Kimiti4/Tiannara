# Alert Engine

## Purpose
Generates and manages alerts across all Tiannara systems — from informational to constitutional emergency, each linked directly to evidence and replay.

## Alert Levels

### Informational
- Routine events and updates
- Milestones achieved
- Scheduled maintenance
- Periodic summaries

### Advisory
- Approaching thresholds
- Emerging trends
- Recommended attention
- Opportunity notifications

### Warning
- Thresholds exceeded
- Degraded performance
- Increased risk
- Resource constraints

### Critical
- System failures
- Active risks materializing
- Severe resource shortages
- Intervention failures

### Constitutional Emergency
- Constitutional principle violation
- Existential risk activation
- Catastrophic system failure
- Emergency protocol required

## Alert Properties
- **id** — unique identifier
- **level** — informational through constitutional emergency
- **source** — engine/system generating the alert
- **title** — concise alert headline
- **description** — detailed explanation
- **evidence** — links to supporting evidence
- **replay** — links to replay of the state that triggered the alert
- **timestamp** — when the alert was generated
- **acknowledged** — whether a human has acknowledged
- **resolved_at** — when the condition was resolved
- **fingerprint** — content hash

## Alert Routing
- Alerts routed to appropriate human operators
- Escalation based on level and unacknowledged time
- Grouping for related alerts
- Suppression for repeated alerts

## Alert Response
- Each alert includes suggested response actions
- Links to relevant intervention options (from CPISE)
- Links to relevant resources (from CPRIE-25.6)
- Links to relevant scenarios (from CMFCSE)

## Data Sources
- All Phase 25 engines — alert triggers and conditions
- Threshold configuration
- Escalation rules
