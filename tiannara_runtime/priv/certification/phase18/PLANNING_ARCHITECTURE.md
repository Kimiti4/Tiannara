# Phase 18.5 — Constitutional Planning & Deliberation: Architecture

## Overview

Planning is the first capability where Tiannara reasons about possible futures rather than past or present state. It produces no executable output — only constitutional planning artifacts that inform downstream decision making (Phase 18.6). The planning subsystem constructs, evaluates, and ranks alternative courses of action under constitutional constraints, then records the entire deliberation for replay, audit, and archaeology.

## Architecture

```
                          ┌──────────────────┐
                          │     Mission      │
                          └────────┬─────────┘
                                   │
                          ┌────────▼─────────┐
                          │  GoalDecomposer  │
                          └────────┬─────────┘
                                   │
                          ┌────────▼─────────┐
                          │   TaskPlanner    │
                          └────────┬─────────┘
                                   │
                          ┌────────▼─────────┐
                          │AlternativeGenerator│
                          └────────┬─────────┘
                                   │
                          ┌────────▼─────────┐
                          │ConstraintEvaluator│
                          └────────┬─────────┘
                                   │
                          ┌────────▼─────────┐
                          │ TradeoffAnalyzer │
                          └────────┬─────────┘
                                   │
                          ┌────────▼─────────┐
                          │   PlanRanker     │
                          └────────┬─────────┘
                                   │
                          ┌────────▼─────────┐
                          │  PlanAssembler   │
                          └────────┬─────────┘
                                   │
                   ┌───────────────┼───────────────┐
                   │               │               │
          ┌────────▼────┐  ┌──────▼──────┐  ┌─────▼────────┐
          │  PlanReplay │  │PlanArchaeology│  │ Ledger Append│
          └─────────────┘  └─────────────┘  └──────────────┘
```

### Core Pipeline

1. **Mission** — The root directive (from Phases 11/N) that seeds planning.
2. **GoalDecomposer** — Breaks mission into hierarchical goals and objectives.
3. **TaskPlanner** — Produces a directed task graph from each goal.
4. **AlternativeGenerator** — Enumerates alternative plans for each task or goal.
5. **ConstraintEvaluator** — Scores each alternative against constitutional constraints.
6. **TradeoffAnalyzer** — Compares alternatives across constraint dimensions.
7. **PlanRanker** — Produces a total ordering of alternatives by weighted score.
8. **PlanAssembler** — Wraps the selected plan into a signed PlanningSession artifact.

### Replay & Archaeology Layers

Two cross-cutting layers wrap the pipeline:

- **Replay Layer** — After every pipeline step, a replay artifact is emitted to the PlanReplay store. Each artifact is keyed by `(planning_session_id, iteration_number, step_name)` and contains the exact inputs, outputs, and internal state of the step. This enables full deterministic reconstruction of any planning session.

- **Archaeology Layer** — All replay artifacts are eventually consolidated into PlanningArchaeology records. These are structural summaries that enable cross-session analysis: goal-type frequency, constraint failure patterns, alternative diversity metrics, and ranking stability.

### Integration with Other Phases

| Phase | Integration Point |
|-------|------------------|
| Phase 18.2 (Kernel) | Planning sessions are spawned as kernel-managed lightweight processes; kernel provides scheduling and isolation |
| Phase 18.3 (WM) | Goal decompositions are written to working memory for attention routing; constraint evaluation reads WM state |
| Phase 18.4 (Attention) | Attention weights influence alternative generation diversity; constraint violations trigger attention shifts |
| Phase 18.6 (Decision) | The assembled plan is consumed by Phase 18.6 for actual decision execution; decision results feed back as archaeology annotations |

### Design Principles

- **No side effects** — Planning produces only artifacts; execution is deferred to Phase 18.6.
- **Deterministic replay** — Given the same mission and iteration number, the pipeline must produce identical artifacts.
- **Constitutional bound** — All alternatives are generated and evaluated within constitutional guardrails defined in Phase 18.1.
- **Audit-first** — Every planning decision leaves a signed, timestamped trace.
