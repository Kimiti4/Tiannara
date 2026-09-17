# Phase 18.9 — Cognitive Runtime Data Model

## Runtime Structs

### `CognitiveMission`
```elixir
%CognitiveMission{
  id: String.t(),
  status: :pending | :active | :completed | :failed | :rejected,
  plan: Plan.t() | nil,
  decision: Decision.t() | nil,
  reflection: Reflection.t() | nil,
  meta: MetaAssessment.t() | nil,
  created_at: DateTime.t(),
  completed_at: DateTime.t() | nil
}
```

### `CognitiveContext`
```elixir
%CognitiveContext{
  working_memory: WorkingMemory.t(),
  attention: AttentionState.t(),
  planning: PlanningState.t(),
  decision: DecisionState.t(),
  mission_id: String.t()
}
```

### `ExecutionState`
```elixir
%ExecutionState{
  phase: :awaiting_authorization | :executing | :collecting_evidence | :completed | :failed,
  step: non_neg_integer(),
  evidence_chain: [Evidence.t()],
  mission_id: String.t(),
  started_at: DateTime.t(),
  completed_at: DateTime.t() | nil
}
```

### `RuntimeEvidence`
```elixir
%RuntimeEvidence{
  id: String.t(),
  subsystem: :kernel | :working_memory | :attention | :planning | :decision | :reflection | :metacognition | :runtime,
  stage: String.t(),
  evidence_data: map(),
  produced_at: DateTime.t(),
  mission_id: String.t(),
  hash: String.t()
}
```

### `RuntimeReplay`
```elixir
%RuntimeReplay{
  mission_root: String.t(),
  kernel_root: String.t(),
  working_memory_root: String.t(),
  attention_root: String.t(),
  planning_root: String.t(),
  decision_root: String.t(),
  reflection_root: String.t(),
  metacognition_root: String.t(),
  built_at: DateTime.t(),
  integrity_hash: String.t()
}
```

### `RuntimeArchaeology`
```elixir
%RuntimeArchaeology{
  mission_id: String.t(),
  narrative: [ArchaeologyEntry.t()],
  subsystem_summaries: %{String.t() => String.t()},
  built_at: DateTime.t(),
  integrity_hash: String.t()
}
```

## Subsystem Structs (Referenced)

| Struct | Origin |
|--------|--------|
| `Plan` | Planning 18.5 |
| `Decision` | Decision 18.6 |
| `Reflection` | Reflection 18.7 |
| `MetaAssessment` | Meta-Cognition 18.8 |
| `WorkingMemory` | Working Memory 18.3 |
| `AttentionState` | Attention 18.4 |
| `PlanningState` | Planning 18.5 |
| `DecisionState` | Decision 18.6 |
| `Evidence` | Runtime |
| `ArchaeologyEntry` | Runtime |
