# Phase 18.6 — Decision Making & Policy Execution: Report

## Pipeline

The decision pipeline consists of 9 stages: Plan → DecisionManager → PolicyEngine → PolicyEvaluator → DecisionEvaluator → RiskAssessor → ExecutionAuthorizer → ExecutionIntent → Replay → Archaeology. Every stage produces replay, evidence, and archaeology artifacts, enabling full reconstruction and audit.

## Policy Hierarchy

Seven policy domains are evaluated in precedence order: Mission, Scientific, Safety, Mathematical, Governance, Simulation, Resource. Higher-priority policies may veto regardless of lower scores.

## Authorization Flow

Authorization is gated on the DecisionScore (aggregated from all policy evaluations) and RiskAssessment. The ExecutionAuthorizer applies threshold logic: if score ≥ threshold and risk ≤ acceptable level and no veto active, authorization is granted. Otherwise, authorization is denied with rationale.

## Risk Evaluation

The RiskAssessor evaluates four categories: existential, operational, reputational, resource. Each category produces a quantified score and a mitigation proposal. The overall risk level is computed as the maximum per-category score. High-risk decisions require additional governance approval.

## Replay

Every decision is fully replayable from its `decision_session_id`. The replay subsystem loads all artifacts in order and reconstructs each stage, verifying hash chains, input/output consistency, timestamp monotonicity, and producer identity. Replay is a prerequisite for certification.

## Archaeology

Archaeology is the long-term immutable store for all decision artifacts. Artifacts are indexed by `decision_session_id` and include replay graphs, evidence payloads, and metadata. The archaeology subsystem supports query, export, and audit traversal.

## Metrics

| Metric | Description |
|--------|-------------|
| Pipeline latency | Time from plan submission to intent issuance |
| Policy pass rate | Fraction of policies passed per decision |
| Veto rate | Fraction of decisions with at least one veto |
| Authorization rate | Fraction of decisions authorised |
| Replay success rate | Fraction of replay reconstructions that complete without error |
| Certification pass rate | Fraction of decisions that pass all certification stages |

## Limitations

- No execution policy — 18.6 terminates at intent issuance; execution correctness is out of scope.
- Policy evaluation functions are assumed correct — formal verification of evaluator logic is not covered.
- Risk assessment uses a static category set; dynamic risk categories are not supported.
- Replay depends on artifact availability; lost artifacts prevent full reconstruction.
- Cross-session consistency (decisions spanning multiple sessions) is not modelled.

## Future Work

- Dynamic risk categories extendable at runtime.
- Formal verification integration for policy evaluator functions.
- Cross-session dependency tracking and consistency enforcement.
- Real-time policy hot-reload with session migration.
- Automated certification pipelines with continuous audit feeds.
