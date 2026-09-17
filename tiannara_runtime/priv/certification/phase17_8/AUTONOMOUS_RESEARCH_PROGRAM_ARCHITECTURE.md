# Phase 17.8 — Autonomous Research Program Architecture

## Overview

Phase 17.8 transforms Tiannara from a simulation platform (Phases 17.2–17.7) into an
**autonomous scientist** that continuously identifies knowledge gaps, designs experiments,
prioritizes them, executes them inside the Civilization Digital Twin, analyzes results,
and updates its research agenda — all under constitutional governance.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Constitutional Layer                           │
│  (invariants, replay, archaeology, math verification, evidence)  │
└─────────────────────────────────────────────────────────────────┘
                              │
     ┌───────────────────────────────────────┐
     │           ResearchProgramEngine        │
     │  (orchestrator — manages lifecycle)    │
     └───────────────────────────────────────┘
         │        │          │           │
         ▼        ▼          ▼           ▼
   ┌────────┐ ┌────────┐ ┌────────┐ ┌──────────┐
   │ Gap    │ │Experiment│ │Portfolio│ │ Theory   │
   │Detector│ │Planner  │ │Manager  │ │ Updater  │
   └────────┘ └────────┘ └────────┘ └──────────┘
         │        │          │           │
         └────────┴──────────┴───────────┘
                      │
                      ▼
            ┌──────────────────┐
            │  Scheduler       │
            │  (campaign exec) │
            └──────────────────┘
                      │
                      ▼
            ┌──────────────────┐
            │  Digital Twin    │
            │  (Phase 17.7)    │
            └──────────────────┘
                      │
                      ▼
            ┌──────────────────┐
            │  Evidence        │
            │  Collection      │
            └──────────────────┘
                      │
                      ▼
            ┌──────────────────┐
            │  Archaeology     │
            │  + Replay        │
            └──────────────────┘
```

## Integration with Phases 15–17

| Phase | Integration Point |
|---|---|
| Phase 15 | Scientific discovery pipeline feeds candidate theories |
| Phase 16 | Knowledge gap detector, question generator, hypothesis engine |
| Phase 16.X | Mathematics epistemic substrate for verification |
| Phase 17.2 | World model construction for experiment substrate |
| Phase 17.3 | Causal structure learning informs experiment design |
| Phase 17.4 | Prediction & forecasting validates expected outcomes |
| Phase 17.5 | Counterfactual modeling for what-if analysis |
| Phase 17.6 | Multi-model composition for complex experiments |
| Phase 17.7 | Civilization Digital Twin for experiment execution |

## Autonomy Boundaries

1. **Knowledge Gap Discovery**: Autonomous — system continuously scans for gaps
2. **Question Generation**: Autonomous — from gaps
3. **Hypothesis Formation**: Autonomous — from questions
4. **Experiment Design**: Autonomous — within constitutional constraints
5. **Priority Assignment**: Autonomous — governed by constitution weights
6. **Execution**: Inside Digital Twin only — never in production reality
7. **Evidence Evaluation**: Autonomous — statistical validation required
8. **Theory Update**: Autonomous — evidence-driven
9. **Program Termination**: Autonomous — ineffective programs are pruned
10. **Replay Certification**: Mandatory — all research must be replayable

## Constitutional Governance

Every autonomous research action is governed by:

- **Replay Fingerprint**: Immutable record of every research decision
- **Archaeology Lineage**: Full traceability of all research artifacts
- **Mathematical Verification**: Proof of correctness for all computations
- **Evidence Chain**: Every claim backed by reproducible evidence
- **Resource Budget**: Constitutional limits on computation and storage
