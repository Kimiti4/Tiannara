# Trigger Condition Monitor

## Purpose
Monitors conditions that determine when to deploy, advance, hold, or abort intervention stages.

## Condition Types

### Readiness Conditions
- Required resources available
- Required infrastructure in place
- Required personnel trained and available
- Required permissions obtained

### Safety Conditions
- Risk level below threshold
- Side effect indicators nominal
- No active contraindications

### Effectiveness Conditions
- Environmental conditions appropriate
- Target population ready
- Supporting systems operational

### Continuation Conditions
- Stage milestones being met
- Benefits exceeding costs
- No better alternative emerged

## Monitoring Approach
- Subscribe to relevant CGON observation streams
- Subscribe to CPRIE risk updates
- Evaluate conditions continuously
- Alert when conditions are met, unmet, or ambiguous

## Output
Condition evaluation: for each active stage, which triggers are met, unmet, or unknown, alert if critical conditions become unmet, recommendation (proceed, hold, abort, modify).
