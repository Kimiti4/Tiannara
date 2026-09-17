# Phase 18.6 — Decision Data Model

## Abstract Definitions

### Decision
A top-level container representing the complete lifecycle of a decision. Contains references to the originating plan, all evaluations, the authorization outcome, and the resulting intent.

### DecisionCandidate
A plan submitted for evaluation. Wraps a `Plan` with a candidate ID, submission timestamp, and session context.

### DecisionScore
An aggregate score produced by the DecisionEvaluator. Contains a numeric score, per-policy scores, a veto flag (true if any policy vetoed), and a summary rationale.

### DecisionPolicy
A policy definition: name, type (Mission, Scientific, Safety, Mathematical, Governance, Simulation, Resource), evaluation function reference, priority level, and active flag.

### ExecutionAuthorization
The result of the authorization stage. Contains an authorization ID, decision reference, granted/denied status, authorizer rationale, and timestamp.

### ExecutionIntent
The final output of the pipeline. Contains the authorized plan, authorization reference, resource budget, safety constraints, governance context, and a unique intent ID for downstream execution.

### RiskAssessment
A risk evaluation produced by the RiskAssessor. Contains risk categories (existential, operational, reputational, resource), quantified risk scores, mitigation suggestions, and an overall risk level.

### PolicyEvaluation
The result of evaluating a single policy against a candidate. Contains policy reference, numeric score, pass/fail, detailed rationale, evidence references, and simulation proof references.

### DecisionEvidence
A signed evidence artifact capturing the state at any pipeline stage. Contains stage identifier, timestamp, payload hash, producer identity, and payload.

### DecisionReplay
A reconstructed decision graph assembled from replay artifacts. Contains all stages, their inputs and outputs, timing information, and cross-stage consistency proofs.

### DecisionArchaeology
A long-term immutable record of a decision suitable for audit and analysis. Contains the full decision graph, all evidence artifacts, replay information, and archival metadata.

### DecisionSession
A session context within which multiple decisions may be made. Contains session ID, active policy set, mission context, resource pool reference, and governance scope.
