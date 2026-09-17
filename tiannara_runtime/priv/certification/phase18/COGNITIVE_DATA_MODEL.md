# Phase 18.0 — Cognitive Data Model

## 1. Abstract Data Model

This document defines the abstract data model for the Executive Cognitive Kernel. No implementation details, data structures, or storage backends are specified.

---

### 1.1 CognitiveTask

| Field | Value |
|---|---|
| **Purpose** | Atomic unit of cognitive work. Represents a single invocation of the cognitive pipeline. |
| **Lifecycle** | Created by Kernel scheduler → active → completed/failed → archived. |
| **Ownership** | Executive Kernel — SchedulerState manager. |
| **Replay requirements** | Full pipeline replay artifacts must be recoverable from the task's replay root. |
| **Evidence requirements** | Task outcome must link to all evidence produced during pipeline execution. |

---

### 1.2 Goal

| Field | Value |
|---|---|
| **Purpose** | Desired outcome. Goals are the highest-level drivers of cognition. Derived from constitutional values. |
| **Lifecycle** | Established constitutionally → adopted by Kernel → satisfied/amended/removed via constitutional process. |
| **Ownership** | Constitution (via Phase 18.05 freeze document). |
| **Replay requirements** | Goal state at time of any pipeline invocation must be reconstructable. |
| **Evidence requirements** | Goal provenance must be traceable to constitutional source. |

---

### 1.3 Mission

| Field | Value |
|---|---|
| **Purpose** | Collection of goals that form a coherent cognitive objective. A mission aggregates one or more goals. |
| **Lifecycle** | Created by Kernel → active goals assigned → planned → executed → completed/abandoned → archived. |
| **Ownership** | Executive Kernel — Planning stage. |
| **Replay requirements** | Mission replay root (`mission_id`) anchors all replay artifacts for that mission. |
| **Evidence requirements** | Mission evidence chain must connect goals → decisions → execution outcomes. |

---

### 1.4 Plan

| Field | Value |
|---|---|
| **Purpose** | Ordered sequence of steps to achieve a mission. Each step maps to a CognitiveTask or subsystem execution. |
| **Lifecycle** | Created during Planning stage → bid collection → finalized → executed → revised if needed → completed. |
| **Ownership** | Executive Kernel — Planning stage. |
| **Replay requirements** | Full plan structure, including all bids and revisions, must be replayable. |
| **Evidence requirements** | Plan evidence must include bid comparisons, cost estimates, risk assessments. |

---

### 1.5 Decision

| Field | Value |
|---|---|
| **Purpose** | A choice among alternatives. Decisions are the atomic output of the Decision pipeline stage. |
| **Lifecycle** | Created during Decision stage → recorded → executed → archived. |
| **Ownership** | Executive Kernel — Decision stage. |
| **Replay requirements** | Decision must be reconstructable from DecisionRecord + evidence chain. |
| **Evidence requirements** | Decision evidence must include all alternatives, selection rationale, and supporting citations. |

---

### 1.6 WorkingMemory

| Field | Value |
|---|---|
| **Purpose** | Transient active state of the Kernel. Holds current observation, context, intermediate reasoning, and pending state. |
| **Lifecycle** | Created at Observation ingest → mutated through pipeline → snapshotted for replay → cleared after decision or on replay. |
| **Ownership** | Executive Kernel — WorkingMemory manager (transient). |
| **Replay requirements** | WorkingMemory snapshots must be archived at decision points for context reconstruction. |
| **Evidence requirements** | WorkingMemory contents are not directly evidentiary; evidence is derived from pipeline stage outputs. |

---

### 1.7 CognitiveContext

| Field | Value |
|---|---|
| **Purpose** | Full situational context including active goals, missions, constraints, and environment state. |
| **Lifecycle** | Built at Context stage → used throughout pipeline → finalized at Decision → archived. |
| **Ownership** | Executive Kernel — Context stage. |
| **Replay requirements** | Full context must be reconstructable from ContextSnapshot artifact. |
| **Evidence requirements** | ContextEvidence must map context elements to their sources (goals, observations, retrieved knowledge). |

---

### 1.8 AttentionState

| Field | Value |
|---|---|
| **Purpose** | Describes where cognition is focused. Includes active mission IDs, priority levels, and urgency signals. |
| **Lifecycle** | Computed by Kernel attention allocation → updated on mission/goal changes → recorded with each decision. |
| **Ownership** | Executive Kernel — Attention stage. |
| **Replay requirements** | AttentionState must be reconstructable for any pipeline invocation. |
| **Evidence requirements** | Attention allocation decisions must be recorded with urgency signals from subsystems. |

---

### 1.9 SchedulerState

| Field | Value |
|---|---|
| **Purpose** | Queue management state. Tracks pending tasks, active tasks, completed tasks, and scheduling order. |
| **Lifecycle** | Continuously updated as tasks are queued, dispatched, and completed. |
| **Ownership** | Executive Kernel — SchedulerState manager. |
| **Replay requirements** | Full scheduler queue state must be reconstructable for any point in time. |
| **Evidence requirements** | Scheduling decisions must be recorded with priority justifications. |

---

### 1.10 ExecutionRequest

| Field | Value |
|---|---|
| **Purpose** | Structured request to a Phase 15/16/17 subsystem for execution. |
| **Lifecycle** | Created at ExecutionRequest stage → dispatched → acknowledged → completed/failed → result returned. |
| **Ownership** | Executive Kernel — ExecutionRequest stage (ownership of request); subsystem (ownership of execution). |
| **Replay requirements** | Request parameters, target identity, and expected outputs must be replayable. |
| **Evidence requirements** | Request must carry authorization chain and integrity proof. |

---

### 1.11 ExecutionResult

| Field | Value |
|---|---|
| **Purpose** | Outcome of a subsystem execution. Includes status, output data, metrics, and certification stamps. |
| **Lifecycle** | Produced by subsystem → consumed by Evidence stage → archived. |
| **Ownership** | Respective Phase 15/16/17 subsystem (production); Executive Kernel (consumption). |
| **Replay requirements** | Full execution trace from the subsystem must accompany the result. |
| **Evidence requirements** | Result must carry subsystem certification stamps and output validation. |

---

### 1.12 EvidenceReference

| Field | Value |
|---|---|
| **Purpose** | Pointer to evidence in the cognitive ledger. Enables evidence chain construction without duplicating evidence data. |
| **Lifecycle** | Created whenever evidence is recorded → referenced by decisions, plans, and audits. |
| **Ownership** | Executive Kernel — Evidence stage. |
| **Replay requirements** | EvidenceReference must resolve to an immutable ledger entry. |
| **Evidence requirements** | Reference must include ledger position, content hash, and Merkle proof. |

---

### 1.13 ReplayReference

| Field | Value |
|---|---|
| **Purpose** | Pointer to a replay root. Enables deterministic replay of any past pipeline invocation. |
| **Lifecycle** | Created at Replay stage → stored in replay index → used for audit/debug/replay. |
| **Ownership** | Executive Kernel — Replay stage. |
| **Replay requirements** | ReplayReference must resolve to a complete set of replay artifacts. |
| **Evidence requirements** | ReplayReference must include completeness proof and artifact hash chain. |

---

### 1.14 ArchaeologyReference

| Field | Value |
|---|---|
| **Purpose** | Pointer to an archaeology entry in the constitutional archive. |
| **Lifecycle** | Created at Archaeology stage → stored in archaeology index → referenced by audits. |
| **Ownership** | Executive Kernel — Archaeology stage. |
| **Replay requirements** | ArchaeologyReference must resolve to an immutable archaeology entry. |
| **Evidence requirements** | Reference must include constitutional compliance verification. |

## 2. Entity Relationships (Abstract)

```
Goal (1..N) ──contains── Mission (1)
Mission (1) ──planned_by── Plan (0..N)
Plan (1) ──composed_of── CognitiveTask (1..N)
CognitiveTask (1) ──produces── Decision (0..1)
Decision (0..1) ──triggers── ExecutionRequest (0..N)
ExecutionRequest (1) ──yields── ExecutionResult (0..1)
ExecutionResult (1) ──produces── EvidenceReference (1..N)
CognitiveTask (1) ──produces── ReplayReference (1)
CognitiveTask (1) ──produces── ArchaeologyReference (1)
WorkingMemory (1) ──feeds── CognitiveTask (1..N)
CognitiveContext (1) ──feeds── CognitiveTask (1)
AttentionState (1) ──informs── ExecutiveKernel (1)
SchedulerState (1) ──manages── CognitiveTask (0..N)
```
