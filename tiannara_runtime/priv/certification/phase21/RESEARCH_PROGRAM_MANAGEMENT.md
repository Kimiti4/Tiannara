# Research Program Management (Phase 21.0)

## Purpose

Define the lifecycle and management of research programs — long-term scientific objectives that guide the research civilization's discovery efforts.

## Program Lifecycle

```
Proposal
    ↓ (Evidence chain, scientific questions, expected impact)
Review
    ↓ (Scientific council evaluation)
Approval
    ↓ (Capital allocation, priority assignment)
Active
    ↓ (Mission execution, discovery generation)
Evaluation
    ↓ (Periodic review against objectives)
Completion → Archive
    ↓
(Knowledge integration, capital settlement)
```

## Program Components

Each program contains:
- **Mission Statement** — The program's raison d'être
- **Scientific Questions** — Specific questions the program seeks to answer
- **Expected Impact** — Anticipated scientific and engineering contributions
- **Dependencies** — Other programs whose discoveries are prerequisite
- **Scientific Capital Allocation** — Capital budget for the program
- **Knowledge Gaps** — Identified gaps the program will address
- **Priority** — Deterministically assigned priority (1 = highest)
- **Replay Root** — Hash root of program execution replay
- **Archaeology Root** — Hash root of program archaeology

## Priority Assignment

Priority is determined deterministically from:
1. Scientific capital available
2. Program impact score
3. Dependency readiness
4. Cross-domain collaboration potential
5. Civilization strategic objectives

## Program Dependencies

Programs can depend on discoveries from other programs:
- Dependency must be resolvable before program can complete
- Circular dependencies are prohibited
- Dependency graph is content-addressed and replayable
- Dependency resolution is deterministic
