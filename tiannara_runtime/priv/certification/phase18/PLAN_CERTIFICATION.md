# Phase 18.5 — Plan Certification

## Validation Stages

### Stage 1: Structural Validation

Performed on every assembled `PlanningSession` before ledger append.

| Check | Description | Failure |
|-------|-------------|---------|
| Schema conformance | Session artifact matches PLAN_DATA_MODEL schema | Reject session |
| Goal hierarchy completeness | Every goal (except root) has a valid parent; all leaf goals have task subgraphs | Reject session |
| Task graph acyclic | PlanNode DAG contains no cycles | Reject session |
| Alternative coverage | Every plan segment has at least one alternative | Reject session |
| Constraint completeness | Every alternative has a score for every active constraint | Reject session |
| Ranking completeness | Ranking includes all alternatives | Reject session |
| Signature validity | Session artifact is cryptographically signed by PlanAssembler | Reject session |

### Stage 2: Replay Verification

Performed on a sample of sessions (configurable rate, default 100%).

| Check | Description | Failure |
|-------|-------------|---------|
| Hash chain integrity | All replay artifact hashes form a valid chain from genesis | Flag session, mark corrupt |
| Step fidelity | `replay(artifact.inputs) == artifact.outputs` for every step | Flag session, mark corrupt |
| Determinism check | Replay twice, assert identical outputs | Flag session, mark non-deterministic |
| Runtime version match | `runtime_version` in artifact matches current runtime | Warning logged |

### Stage 3: Audit Trail Verification

| Check | Description | Failure |
|-------|-------------|---------|
| Evidence completeness | Every pipeline step has a corresponding evidence artifact | Warning logged |
| Timestamp ordering | Evidence timestamps respect pipeline step order | Flag session |
| Owner traceability | Every artifact has a valid owner process identifier | Flag session |

### Stage 4: Constitutional Compliance Audit

Performed periodically (every N sessions or on demand).

| Check | Description | Failure |
|-------|-------------|---------|
| Constraint fidelity | ConstraintEvaluator correctly applied Phase 18.1 constraints | Escalate to constitutional review |
| Weight consistency | Ranking weights match current constitutional weight table | Escalate to constitutional review |
| Alternative diversity | AlternativeGenerator produced minimum number of alternatives per segment | Warning, escalate after threshold |

## Freeze Conditions

A `PlanningSession` may be frozen (marked immutable and excluded from further processing) under these conditions:

| Condition | Trigger | Action |
|-----------|---------|--------|
| Successful completion | All validation stages pass | Session is sealed and frozen automatically |
| Failed structural validation | Any Stage 1 check fails | Session frozen with status `failed` |
| Corrupt replay | Stage 2 detects hash chain break or output mismatch | Session frozen with status `corrupt`; replay artifacts preserved |
| Manual freeze | Operator command | Session frozen with status `frozen` |
| Constitutional escalation | Stage 4 detects systemic violation | Sessions frozen pending constitutional amendment |

### Frozen Session Handling

- Frozen sessions remain in the ledger but are excluded from Phase 18.6 decision input.
- A frozen session may be unfrozen only by operator intervention.
- `corrupt` sessions trigger an automatic archaeological alert.

## Certification Artifacts

After certification, the following artifacts are produced:

| Artifact | Location | Content |
|----------|----------|---------|
| Certification report | `certification/phase18/{session_id}_cert.json` | Stage-by-stage validation results |
| Replay verification log | `certification/phase18/{session_id}_replay.log` | Full replay trace |
| Compliance scorecard | `certification/phase18/{session_id}_compliance.json` | Constitutional compliance scores |
| Certification signature | `certification/phase18/{session_id}.sig` | Signed hash of certification report |
