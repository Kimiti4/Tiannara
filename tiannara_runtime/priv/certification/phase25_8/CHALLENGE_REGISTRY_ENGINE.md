# Challenge Registry Engine

## Purpose
Maintains the permanent registry of all discovery challenges — active, solved, superseded, and abandoned. Solved challenges remain permanent scientific artifacts.

## Registry Schema
Each challenge records:
- **id** — permanent unique identifier
- **title** — concise statement of the challenge
- **description** — full description including context
- **source** — how the challenge was identified (observation, theory, risk, resource, scenario, human-submitted)
- **domain** — primary scientific or engineering domain
- **subdomain** — specific sub-discipline
- **type** — unknown, bottleneck, anomaly, opportunity, problem
- **status** — identified, classified, prioritized, routed, in_progress, solved, superseded, abandoned
- **knowledge_gap** — structured representation of missing knowledge
- **prerequisites** — challenge IDs that must be solved first
- **dependents** — challenges that depend on this one
- **evidence** — links to evidence records
- **hypotheses** — candidate explanations or approaches
- **experiments** — planned, active, and completed experiments
- **discoveries** — resulting discoveries
- **engineering_applications** — engineering outcomes
- **value_scores** — scientific, engineering, civilizational value scores
- **fingerprint** — content hash
- **created_at**, **updated_at**, **solved_at**

## Registry Properties
- Append-only: once created, a challenge is never deleted
- Versioned: challenge record evolves with knowledge
- Cross-referenced: challenges link to each other and to evidence, hypotheses, experiments, discoveries
- Searchable: by domain, status, value, time, keywords
