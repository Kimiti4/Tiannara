# EFDI D3 — Integration Map

## 1. Flow

```
DecisionRequest ──► DecisionEngine.decide/1 ──► Decision
      │                                            │ capture
      │                                            ▼
      │                                     DecisionSnapshot ──► DecisionQuality (ex-ante)
      │                                            │
      │                                            │   guard_outcome (hindsight-isolated)
      v                                            ▼
 PreMortem ──► posture ──────────────►     DecisionReview.decision_outcome/2
      │                                            ▲
      │                                            │ outcome (post decision time)
      ▼                                            │
 Adapters.DecisionImpl ────────────────────────────┘
      ├─ authorize/1   ──► Council.authorize/3            (authority gate)
      ├─ to_command/1  ──► Executive.Command.new(...)
      ├─ submit_intent ──► AEO.submit_to_runtime
      ├─ check_cis/1   ──► CIS risk-score check          (immune authority persists)
      ├─ request_research ──► ResearchDirector.ingest_priorities (V16)
      └─ world_consequence ──► honest boundary           (no fabrication)
```

## 2. Module wiring

| Boundary | D3 side | Existing side | Guarantee |
|----------|---------|---------------|-----------|
| Registry events | `DecisionRegistry` | `Executive.Event/EventStore` | best-effort append; degraded-tolerant |
| Authorization | `Adapters.DecisionImpl.authorize/1` | `Council.authorize/3` | never bypassed (V15) |
| Execution | `to_command/1` | `Executive.Command` | EXTEND at boundary |
| Execution intent | `submit_intent/1` | `AEO.submit_to_runtime/1` | placeholder-aware |
| Immune authority | `check_cis/1` | CIS detectors (`PathogenDetector`, `OverreactionMonitor`, `ImmuneMemory`) | V17 gate |
| Research | `request_research/1` | `ResearchDirector.ingest_priorities/1` | information, not permission |
| Prediction trace | `efdi.ex:decide/1` | `HAI.DecisionTraceExplorer` | trace-open |
| Counterfactual | `d.context[:world_snapshot_available]` | `World.TemporalWorldEngine.counterfactual_state/2` | deferred `:counterfactual` |

## 3. Deferred capabilities (honest accounting)

`status()` reports `deferred: [:counterfactual, :noise, :memory]`:
- counterfactual world-state evaluation (`World.TemporalWorldEngine`),
- noise-aware confidence bounds (D-noise layer),
- associative memory-based decision recall (D-memory layer).

These are declared but not implemented; certification treats them as **outside** the D3 claim.