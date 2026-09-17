# Phase 18.6 — Decision Replay Model

## Root Identifier

Every replay is rooted at `decision_session_id`. This identifier links all artifacts produced during the decision lifecycle.

## Reconstruction Stages

Given a `decision_session_id`, the replay subsystem reconstructs the decision by loading artifacts in order:

### 1. Policy Evaluation Reconstruction
- **Source artifacts:** `policy_engine_evaluation.replay.json`, `policy_evaluator_result.replay.json`
- **Reconstructs:** The set of policies evaluated, their inputs, outputs, and the evaluation function applied.
- **Output:** Ordered list of `PolicyEvaluation` records with policy type, score, pass/fail, and rationale.

### 2. Scoring Reconstruction
- **Source artifacts:** `decision_scoring.replay.json`
- **Reconstructs:** The aggregation function, per-policy scores, veto detection, and final score computation.
- **Output:** `DecisionScore` with full scoring breakdown.

### 3. Risk Reconstruction
- **Source artifacts:** `risk_assessment.replay.json`
- **Reconstructs:** The risk model applied, risk categories evaluated, quantification method, and mitigation proposals.
- **Output:** `RiskAssessment` with per-category risk levels.

### 4. Authorization Reconstruction
- **Source artifacts:** `authorization.replay.json`
- **Reconstructs:** The authorization decision, authorizer identity, threshold checks, and rationale.
- **Output:** `ExecutionAuthorization` including granted/denied status and triggering conditions.

### 5. Intent Reconstruction
- **Source artifacts:** `intent.replay.json`
- **Reconstructs:** The final `ExecutionIntent` built from the authorized plan and associated bindings.
- **Output:** Complete `ExecutionIntent` with resource budget, safety constraints, and governance context.

## Consistency Verification

Replay verifies that:
- Each artifact's payload hash matches its recorded hash.
- Stage outputs are consistent with subsequent stage inputs (input/output chaining).
- Timestamps are monotonic across stages.
- Producer identities match expected owners.

## Failure Handling

If any artifact is missing or hash-invalid, the replay is marked as `INCOMPLETE` with a record of the missing or corrupted stage. Partial reconstruction up to the failure point is still provided.
