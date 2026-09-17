# Phase 18.0 — Cognitive Pipeline

## 1. Pipeline Overview

The cognitive pipeline is a sequential, deterministic flow owned by the Executive Cognitive Kernel. Each stage produces explicit outputs that feed the next stage. Every transition is recorded for replay, evidence, and archaeology.

```
Observation
  ↓
Working Memory Ingest
  ↓
Context Builder
  ↓
Knowledge Retrieval
  ↓
World Model Selection
  ↓
Reasoning
  ↓
Planning
  ↓
Simulation (via Phase 17.7 Digital Twin)
  ↓
Evaluation
  ↓
Decision
  ↓
Execution Request
  ↓
Subsystem Execution (via Phase 15/16/17)
  ↓
Evidence Capture
  ↓
Replay Recording
  ↓
Archaeology
  ↓
Ledger Append
```

## 2. Stage Transitions

### 2.1 Observation

| Field | Value |
|---|---|
| **Inputs** | External stimuli (sensor data, user input, system events, ledger events) |
| **Outputs** | RawObservation — tagged, timestamped, source-attributed |
| **Owner** | Executive Kernel — Observation stage |
| **Replay artifact** | ObservationRecord — raw input bytes + metadata hash |
| **Evidence artifact** | ObservationEvidence — source fingerprint, timestamp, integrity proof |
| **Archaeology artifact** | ArchaeologyObservation — immutable observation entry, constitutional archive |

### 2.2 Working Memory Ingest

| Field | Value |
|---|---|
| **Inputs** | RawObservation |
| **Outputs** | WorkingMemoryState — transient structured representation |
| **Owner** | Executive Kernel — WorkingMemory manager |
| **Replay artifact** | WorkingMemorySnapshot — serialized WM at ingest time |
| **Evidence artifact** | IngestEvidence — mapping from RawObservation → WM slots |
| **Archaeology artifact** | ArchaeologyIngest — ingest lineage, constitutionally archived |

### 2.3 Context Builder

| Field | Value |
|---|---|
| **Inputs** | WorkingMemoryState, active Goal set, Mission roster |
| **Outputs** | CognitiveContext — full situational context including goals, active missions, constraints |
| **Owner** | Executive Kernel — Context stage |
| **Replay artifact** | ContextSnapshot — full context serialization |
| **Evidence artifact** | ContextEvidence — goal-mission-context mapping |
| **Archaeology artifact** | ArchaeologyContext — context reconstruction record |

### 2.4 Knowledge Retrieval

| Field | Value |
|---|---|
| **Inputs** | CognitiveContext |
| **Outputs** | RetrievedKnowledge — relevant facts, prior decisions, ledger entries |
| **Owner** | Executive Kernel — Retrieval stage (delegates to Phase 16 research index) |
| **Replay artifact** | RetrievalRecord — query + result set + relevance scores |
| **Evidence artifact** | RetrievalEvidence — source ledger references for each result |
| **Archaeology artifact** | ArchaeologyRetrieval — query archive, constitutionally preserved |

### 2.5 World Model Selection

| Field | Value |
|---|---|
| **Inputs** | CognitiveContext, RetrievedKnowledge |
| **Outputs** | ActiveWorldModels — selection of Phase 17 world models relevant to context |
| **Owner** | Executive Kernel — WorldModel stage (delegates to Phase 17.2–17.6) |
| **Replay artifact** | ModelSelectionRecord — context hash → model IDs + selection weights |
| **Evidence artifact** | ModelSelectionEvidence — fitness scores, model certifications |
| **Archaeology artifact** | ArchaeologyModelSelection — model selection archive |

### 2.6 Reasoning

| Field | Value |
|---|---|
| **Inputs** | CognitiveContext, RetrievedKnowledge, ActiveWorldModels |
| **Outputs** | ReasonedState — inferences, conclusions, confidence intervals |
| **Owner** | Executive Kernel — Reasoning stage |
| **Replay artifact** | ReasoningTrace — full inference chain (premises → conclusions) |
| **Evidence artifact** | ReasoningEvidence — confidence scores, contradiction flags, supporting citations |
| **Archaeology artifact** | ArchaeologyReasoning — reasoning chain constitutionally preserved |

### 2.7 Planning

| Field | Value |
|---|---|
| **Inputs** | ReasonedState, active Goals, Mission definitions |
| **Outputs** | Plan — ordered steps with bids from subsystems |
| **Owner** | Executive Kernel — Planning stage |
| **Replay artifact** | PlanRecord — step sequence, bid responses, selected plan |
| **Evidence artifact** | PlanEvidence — bid comparisons, cost estimates, risk assessments |
| **Archaeology artifact** | ArchaeologyPlan — plan archive, constitutionally recorded |

### 2.8 Simulation (via Phase 17.7)

| Field | Value |
|---|---|
| **Inputs** | Plan, ActiveWorldModels |
| **Outputs** | SimulationResults — projected outcomes per plan step |
| **Owner** | Executive Kernel — Simulation stage (delegates to Phase 17.7 Digital Twin) |
| **Replay artifact** | SimulationRecord — simulation parameters, random seeds, output traces |
| **Evidence artifact** | SimulationEvidence — outcome confidence, scenario coverage, calibration metrics |
| **Archaeology artifact** | ArchaeologySimulation — simulation configuration and results archived |

### 2.9 Evaluation

| Field | Value |
|---|---|
| **Inputs** | SimulationResults, ReasonedState, CognitiveContext |
| **Outputs** | Evaluation — scored alternatives with risk/benefit analysis |
| **Owner** | Executive Kernel — Evaluation stage |
| **Replay artifact** | EvaluationRecord — alternative scores, ranking, selection rationale |
| **Evidence artifact** | EvaluationEvidence — scoring methodology, weight assignments, sensitivity analysis |
| **Archaeology artifact** | ArchaeologyEvaluation — evaluation record constitutionally archived |

### 2.10 Decision

| Field | Value |
|---|---|
| **Inputs** | Evaluation, active Goals |
| **Outputs** | Decision — selected alternative with justification |
| **Owner** | Executive Kernel — Decision stage |
| **Replay artifact** | DecisionRecord — chosen alternative, rejected alternatives, justification hash |
| **Evidence artifact** | DecisionEvidence — full evidence chain backing the decision |
| **Archaeology artifact** | ArchaeologyDecision — decision constitutionally recorded |

### 2.11 Execution Request

| Field | Value |
|---|---|
| **Inputs** | Decision |
| **Outputs** | ExecutionRequest — structured command to a Phase 15/16/17 subsystem |
| **Owner** | Executive Kernel — ExecutionRequest stage |
| **Replay artifact** | ExecutionRequestRecord — request parameters, target subsystem, expected outputs |
| **Evidence artifact** | ExecutionRequestEvidence — request integrity proof, authorization chain |
| **Archaeology artifact** | ArchaeologyExecutionRequest — request archived for constitutional audit |

### 2.12 Subsystem Execution (via Phase 15/16/17)

| Field | Value |
|---|---|
| **Inputs** | ExecutionRequest |
| **Outputs** | ExecutionResult — subsystem output, status, metrics |
| **Owner** | Respective Phase 15/16/17 subsystem (within its certified scope) |
| **Replay artifact** | SubsystemExecutionRecord — full execution trace from subsystem |
| **Evidence artifact** | SubsystemEvidence — output validation, certification stamps |
| **Archaeology artifact** | ArchaeologySubsystemExecution — execution outcome archived |

### 2.13 Evidence Capture

| Field | Value |
|---|---|
| **Inputs** | ExecutionResult, SubsystemEvidence |
| **Outputs** | EvidencePackage — consolidated evidence from pipeline stage |
| **Owner** | Executive Kernel — Evidence stage |
| **Replay artifact** | EvidenceCaptureRecord — evidence assembly trace |
| **Evidence artifact** | EvidencePackageEvidence — chain-of-custody, integrity proofs |
| **Archaeology artifact** | ArchaeologyEvidence — evidence package constitutionally recorded |

### 2.14 Replay Recording

| Field | Value |
|---|---|
| **Inputs** | All replay artifacts from all prior stages |
| **Outputs** | ReplayRecord — complete replay root for this pipeline invocation |
| **Owner** | Executive Kernel — Replay stage |
| **Replay artifact** | ReplayRecord (self-referential — the record is the artifact) |
| **Evidence artifact** | ReplayEvidence — completeness proof, artifact hash chain |
| **Archaeology artifact** | ArchaeologyReplay — replay root constitutionally archived |

### 2.15 Archaeology

| Field | Value |
|---|---|
| **Inputs** | All archaeology artifacts from all prior stages |
| **Outputs** | ArchaeologyEntry — constitutional archive entry |
| **Owner** | Executive Kernel — Archaeology stage |
| **Replay artifact** | ArchaeologyRecord — archaeology assembly proof |
| **Evidence artifact** | ArchaeologyEvidence — constitutional compliance check |
| **Archaeology artifact** | ArchaeologyEntry (self-referential — the entry is the artifact) |

### 2.16 Ledger Append

| Field | Value |
|---|---|
| **Inputs** | All artifacts (replay, evidence, archaeology) |
| **Outputs** | LedgerAppend — immutable append to the cognitive ledger |
| **Owner** | Executive Kernel — Ledger stage (delegates to ledger subsystem) |
| **Replay artifact** | LedgerAppendRecord — append position, hash, timestamp |
| **Evidence artifact** | LedgerEvidence — Merkle proof, consistency proof |
| **Archaeology artifact** | ArchaeologyLedgerAppend — ledger append constitutionally preserved |

## 3. Pipeline Guarantees

- **Sequential**: Stages execute in order. No stage may begin before the prior stage completes.
- **Atomic**: Each stage either completes fully or produces no output.
- **Recorded**: Every stage produces replay, evidence, and archaeology artifacts.
- **Deterministic**: Given identical inputs, the pipeline produces identical outputs (modulo subsystem internal nondeterminism, which is captured in replay artifacts).
