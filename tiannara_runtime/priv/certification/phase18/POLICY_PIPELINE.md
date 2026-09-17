# Phase 18.6 — Policy Pipeline

## Pipeline Stages

### 1. Plan → DecisionManager

| Field | Value |
|-------|-------|
| **Inputs** | `Plan` (from 18.2), `PolicyHierarchy`, `SessionContext` |
| **Outputs** | `DecisionCandidate` |
| **Owner** | DecisionManager |
| **Replay artifact** | `candidate_submission.replay.json` |
| **Evidence artifact** | `plan_snapshot.evidence.json` |
| **Archaeology artifact** | `decision_origin.arch.json` |

### 2. DecisionManager → PolicyEngine

| Field | Value |
|-------|-------|
| **Inputs** | `DecisionCandidate`, `PolicyHierarchy` |
| **Outputs** | `PolicyEvaluationSet` |
| **Owner** | PolicyEngine |
| **Replay artifact** | `policy_engine_evaluation.replay.json` |
| **Evidence artifact** | `policy_evaluation_set.evidence.json` |
| **Archaeology artifact** | `policy_engine_trace.arch.json` |

### 3. PolicyEngine → PolicyEvaluator

| Field | Value |
|-------|-------|
| **Inputs** | `PolicyEvaluationSet`, individual `Policy` |
| **Outputs** | Per-policy `PolicyEvaluation` (score, reason, pass/fail) |
| **Owner** | PolicyEvaluator |
| **Replay artifact** | `policy_evaluator_result.replay.json` |
| **Evidence artifact** | `policy_evaluation.evidence.json` |
| **Archaeology artifact** | `policy_evaluator_decision.arch.json` |

### 4. PolicyEvaluator → DecisionEvaluator

| Field | Value |
|-------|-------|
| **Inputs** | All `PolicyEvaluation` results |
| **Outputs** | `DecisionScore` (aggregated score, policy veto flag) |
| **Owner** | DecisionEvaluator |
| **Replay artifact** | `decision_scoring.replay.json` |
| **Evidence artifact** | `decision_score.evidence.json` |
| **Archaeology artifact** | `decision_evaluator_summary.arch.json` |

### 5. DecisionEvaluator → RiskAssessor

| Field | Value |
|-------|-------|
| **Inputs** | `DecisionScore`, `Plan`, `PolicyEvaluationSet` |
| **Outputs** | `RiskAssessment` |
| **Owner** | RiskAssessor |
| **Replay artifact** | `risk_assessment.replay.json` |
| **Evidence artifact** | `risk_assessment.evidence.json` |
| **Archaeology artifact** | `risk_assessment_trace.arch.json` |

### 6. RiskAssessor → ExecutionAuthorizer

| Field | Value |
|-------|-------|
| **Inputs** | `DecisionScore`, `RiskAssessment` |
| **Outputs** | `ExecutionAuthorization` (granted / denied) |
| **Owner** | ExecutionAuthorizer |
| **Replay artifact** | `authorization.replay.json` |
| **Evidence artifact** | `authorization.evidence.json` |
| **Archaeology artifact** | `authorization_rationale.arch.json` |

### 7. ExecutionAuthorizer → ExecutionIntent

| Field | Value |
|-------|-------|
| **Inputs** | `ExecutionAuthorization`, `Plan` |
| **Outputs** | `ExecutionIntent` |
| **Owner** | ExecutionIntent (builder) |
| **Replay artifact** | `intent.replay.json` |
| **Evidence artifact** | `intent.evidence.json` |
| **Archaeology artifact** | `intent_manifest.arch.json` |

### 8. ExecutionIntent → Replay

| Field | Value |
|-------|-------|
| **Inputs** | All replay artifacts from stages 1–7 |
| **Outputs** | `DecisionReplay` (reconstructed decision graph) |
| **Owner** | ReplaySubsystem |
| **Replay artifact** | `replay_graph.replay.json` |
| **Evidence artifact** | `replay_consistency.evidence.json` |
| **Archaeology artifact** | `replay_manifest.arch.json` |

### 9. Replay → Archaeology

| Field | Value |
|-------|-------|
| **Inputs** | `DecisionReplay`, all archaeology artifacts from stages 1–8 |
| **Outputs** | `DecisionArchaeology` (long-term decision record) |
| **Owner** | ArchaeologySubsystem |
| **Replay artifact** | `archaeology_package.replay.json` |
| **Evidence artifact** | `archaeology_metadata.evidence.json` |
| **Archaeology artifact** | `archaeology_final.arch.json` |
