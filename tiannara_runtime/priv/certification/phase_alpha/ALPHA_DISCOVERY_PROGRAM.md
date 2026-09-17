# Alpha Discovery Program — Challenge Architecture

## Challenge Ingestion
- Sources: knowledge gaps, observational anomalies, risk-driven from CPRIE, resource-driven from CPRIE-25.6, scenario-driven from CMFCSE, experiment results, human-submitted
- Each challenge: domain, description, source, priority, prerequisites
- Automated ingestion: scan knowledge gaps → generate challenges, scan anomalies → generate challenges
- Manual ingestion: human operator can submit challenges at any time

## Challenge Routing
- Classify challenge by domain and type
- Route to appropriate scientific domain engines
- Cross-domain challenges routed to multiple domain engines
- Priority-based queue: critical > high > medium > low
- Queue sorted by priority, age, dependency position

## Challenge Prioritization
- Factors: scientific value, engineering value, civilizational value, urgency, dependency position, estimated effort
- Multi-factor weighted scoring
- Priority recalculated: after each discovery cycle, after external events, on schedule (daily)
- Dependency-aware: prerequisite challenges automatically boosted

## Challenge Execution
- Each challenge cycles through scientific or engineering workflow
- Execution time governed by resource limits
- Partial results checkpointed mid-execution
- Interrupted execution resumes from last checkpoint (not from start)

## Challenge Scoring
- On resolution: multi-dimensional score (scientific impact, engineering impact, civilizational value, resource efficiency)
- Score stored permanently with challenge record
- Historical scores used to calibrate priority model

## Challenge Retirement
- Solved: moved to permanent archive
- Superseded: replaced by more precise formulation, original preserved
- Abandoned: deprioritized indefinitely, never deleted
- Expired: challenge conditions no longer applicable (rare)
- Retirement requires human approval for non-solved cases

## Continuous Generation
- After each discovery cycle: generate new challenges from new knowledge gaps
- After each observation cycle: generate challenges from anomalies
- After each experiment: generate challenges from inconclusive results
- After each external event: generate challenges from changed conditions
- Challenge portfolio: maintain minimum N active challenges (configurable)
- Challenge diversity: maintain minimum coverage across all domains

## Lifecycle
```
Challenge Created → Classified → Prioritized → Queued → Executing → [Solved|Superseded|Abandoned] → Archived
```

Each transition recorded with fingerprint, rationale, authorizing entity. Full lifecycle replayable.
