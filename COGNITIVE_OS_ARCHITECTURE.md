# Phase 18.0 — Constitutional Cognitive Operating System Architecture

document_version: 18.0.0
phase: 18.0
status: Architecture Review
owner: Constitutional Cognitive Council
depends_on:
  - PHASE15_FINAL_CERTIFICATION.md
  - PHASE16_FINAL_CERTIFICATION.md
  - PHASE16_X_FINAL_CERTIFICATION.md
  - AUTONOMOUS_RESEARCH_PROGRAM_ARCHITECTURE.md
  - AUTONOMOUS_THEORY_EVOLUTION.md
supersedes: null

---

## Constitutional Architecture Review

Phase 18 defines the Constitutional Cognitive Operating System (CCOS), the
executive cognition layer that coordinates certified Tiannara subsystems.

This phase is architecture only.

No runtime, algorithms, execution behavior, or implementation may be introduced
until Phase 18.05 freezes contracts.

---

## Mission

Develop Tiannara's Constitutional Cognitive Operating System: the executive
intelligence that unifies certified discovery, research, mathematics, world
modeling, digital twin, and autonomous research subsystems into a continuously
reasoning, planning, governing, and self-improving scientific organism.

CCOS does not replace existing systems. It orchestrates them.

Every cognitive decision must remain constitutional, deterministic, replayable,
mathematically verifiable, archaeologically explainable, and independently
auditable.

---

## Phase 18+ Proof Discipline

From Phase 18 onward, the no-hardcode, no-stub, no-mock-data rule is a blocking
constitutional invariant.

- No CCOS subsystem may introduce hardcoded domain thresholds, fallback budgets,
  fabricated timestamps, placeholder IDs, inferred constants, default goals, or
  synthetic memory where a frozen config or caller-supplied artifact is required.
- No CCOS subsystem may return stub decisions, plans, memories, attention states,
  scheduler states, resource allocations, replay roots, archaeology entries, or
  certification artifacts. Missing or unverifiable artifacts must fail closed.
- Mock data is permitted only inside isolated test fixtures. It must never enter
  Phase 18 runtime cognition, planning, decision, replay, archaeology, execution,
  archive, or certification paths.
- Tiannara systems must prove themselves through real content-addressed
  artifacts, deterministic replay, mathematical verification, and independent
  audit. A simulated success surface is not evidence of cognition.
- No Phase 18 module may claim architectural compliance while hiding execution
  behind default values, implicit reasoning, mock memories, no-op supervisors, or
  placeholder plans.

---

## Constitutional Cognition Pipeline

Every executive decision follows this constitutional sequence:

Observation

↓

Context Assembly

↓

Memory Retrieval

↓

World Model Selection

↓

Reasoning

↓

Planning

↓

Simulation

↓

Research

↓

Decision

↓

Evidence

↓

Constitutional Review

↓

Execution Request

↓

Replay

↓

Archaeology

↓

Constitutional Archive

No hidden execution. No implicit reasoning. No non-replayable cognition.

---

## Phase 18 Boundaries

### In Scope

- Executive Cognitive Kernel
- Working Memory and long-term memory coordination
- Context Manager
- Attention Manager
- Goal Manager
- Mission Planner
- Planning Engine
- Decision Engine
- Executive Scheduler
- Resource Allocator
- Constitutional Supervisor
- Replay Root
- Archaeology Ledger

### Out of Scope

- Redesigning Phase 15 Scientific Discovery
- Redesigning Phase 16 Constitutional Research
- Redesigning Phase 16.X Mathematics Epistemic Substrate
- Redesigning Phase 17 World Model, Digital Twin, or ARPE systems
- Runtime cognition before Phase 18.05 contract freeze
- External actuation without constitutional execution review

---

## Canonical Ownership

| Entity | Owner |
|---|---|
| CognitiveTask | CognitiveKernel |
| Goal | GoalManager |
| Mission | MissionPlanner |
| Plan | PlanningEngine |
| WorkingMemory | MemoryManager |
| CognitiveContext | ContextManager |
| AttentionState | AttentionManager |
| SchedulerState | ExecutiveScheduler |
| ExecutiveDecision | DecisionEngine |
| ResourceAllocation | ResourceAllocator |
| ConstitutionalReview | ConstitutionalSupervisor |
| CognitiveReplayRoot | ReplayEngine |
| CognitiveArchaeologyRecord | ArchaeologyLedger |

Each entity has exactly one canonical owner. Cross-subsystem use occurs by
content-addressed artifact reference, never by duplicated mutable ownership.

---

## Phase 18.05 Freeze Targets

### Schemas

- CognitiveTask
- Goal
- Mission
- Plan
- WorkingMemory
- CognitiveContext
- ExecutiveDecision
- SchedulerState
- AttentionState
- ResourceAllocation
- CognitiveReplayRoot
- CognitiveArchaeologyRecord

### APIs

- CognitiveKernel
- ExecutiveScheduler
- GoalManager
- MissionPlanner
- PlanningEngine
- DecisionEngine
- MemoryManager
- ContextManager
- AttentionManager
- ResourceAllocator
- ConstitutionalSupervisor
- ReplayEngine
- ArchaeologyLedger

### Behaviors

- ReasoningBehaviour
- PlanningBehaviour
- SchedulingBehaviour
- AttentionBehaviour
- DecisionBehaviour
- MemoryBehaviour
- ReplayBehaviour

---

## Compliance Gate

Phase 18 implementation may begin only after this architecture is frozen into
Phase 18.05 contracts. Any proposed implementation must demonstrate:

1. all domain values come from frozen configs or input artifacts,
2. all IDs are content-addressed or caller-supplied by an owning artifact,
3. all timestamps are replay-context inputs,
4. every decision has evidence, replay, and archaeology,
5. no stubs, no mocks, and no hardcoded success paths are present outside tests.
