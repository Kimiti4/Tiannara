# 🔍 Phase 4C: Causal Tracing System - Implementation Complete

## Overview

Phase 4C adds **full cognitive forensics** to Tiannara, enabling complete introspection of decision lineage. Every event now carries a trace_id that links it to its causal ancestors and descendants, creating a navigable graph of cognitive causality.

---

## ✅ What Was Built

### 1. TraceID Propagation System

**Module:** `TiannaraRuntime.Causality.TracePropagation`  
**Location:** `tiannara_runtime/lib/tiannara_runtime/causality/trace_propagation.ex`

**Features:**
- Generates unique trace_id for every event (UUID format)
- Maintains parent-child relationships across event chains
- Tracks trace depth (distance from root event)
- Stores trace context with metadata
- Provides chain reconstruction from any point

**Trace Context Structure:**
```elixir
%{
  trace_id: "trace_a3f8b2c1d4e5",
  parent_trace_id: "trace_9x8y7z6w5v4u" | nil,
  root_event: "cal_arbitration",
  depth: 3,
  started_at: "2026-05-19T10:30:00Z",
  metadata: %{coalition_id: "C1", action: "select"}
}
```

**API:**
```elixir
# Start new trace (root event)
trace_id = TracePropagation.start_trace("cal_decision", %{...})

# Continue existing trace (child event)
child_id = TracePropagation.continue_trace(parent_id, "cis_intervention", %{...})

# Get full trace chain
{:ok, chain} = TracePropagation.get_trace_chain(trace_id)

# Get ancestry (all parents up to root)
ancestors = TracePropagation.get_ancestry(event_id)
```

---

### 2. Causal Graph Builder

**Module:** `TiannaraRuntime.Causality.CausalGraph`  
**Location:** `tiannara_runtime/lib/tiannara_runtime/causality/causal_graph.ex`

**Features:**
- Constructs directed graph of causal relationships
- Nodes = Events (CAL decisions, CIS interventions, coalition changes)
- Edges = Causal relationships with types:
  - `"caused_by"`: Direct causation
  - `"influenced_by"`: Indirect influence
  - `"intervened_by"`: CIS intervention
  - `"arbitrated_by"`: CAL arbitration
- Maintains adjacency lists for efficient traversal
- Supports BFS/DFS queries for ancestors/descendants

**Graph Structure:**
```
Root Event (CAL Arbitration)
    ↓ caused_by
Decision Event (Select C1)
    ↓ triggered
Intervention Event (CIS Damping)
    ↓ affected
Coalition Update (C2 stabilized)
```

**API:**
```elixir
# Add event node
CausalGraph.add_node(event_id, "cal_decision", %{score: 0.87})

# Add causal edge
CausalGraph.add_edge(source_id, target_id, "influenced_by")

# Get full causal chain
{:ok, chain} = CausalGraph.get_causal_chain(event_id, max_depth: 10)

# Get ancestors only
{:ok, ancestors} = CausalGraph.get_ancestors(event_id)

# Get CIS interventions affecting event
{:ok, interventions} = CausalGraph.get_interventions(event_id)

# Get graph statistics
{:ok, stats} = CausalGraph.get_stats()
# Returns: %{node_count: 150, edge_count: 320, ...}
```

---

### 3. Trace Query API

**Module:** `TiannaraRuntime.Causality.TraceQuery`  
**Location:** `tiannara_runtime/lib/tiannara_runtime/causality/trace_query.ex`

**Features:**
- High-level query interface for UI components
- Builds hierarchical decision trees from flat trace chains
- Generates human-readable causal explanations
- Supports replay of entire causal sequences
- Provides statistics and metrics per trace

**Query Types:**
1. **Decision Tree**: Hierarchical view of all events in trace
2. **Ancestry**: Linear chain from root to specific event
3. **Interventions**: All CIS actions affecting an event
4. **Decisions**: All CAL choices influencing an event
5. **Explanation**: Natural language summary of causality
6. **Replay**: Chronological step-by-step playback

**API:**
```elixir
# Get complete decision tree
{:ok, tree} = TraceQuery.get_decision_tree(trace_id)
# Returns: %{root: {...}, children: [%{node: ..., children: [...]}]}

# Get causal explanation (human-readable)
{:ok, explanation} = TraceQuery.explain_causality(event_id)
# Returns: "🔍 Causal Explanation for Event: ...\n\n📊 Chain Overview: ..."

# Replay entire chain
{:ok, steps} = TraceQuery.replay_chain(trace_id)
# Returns: [%{step: 1, event_type: "...", timestamp: "..."}, ...]

# Get trace statistics
{:ok, stats} = TraceQuery.get_trace_stats(trace_id)
# Returns: %{chain_length: 5, intervention_count: 2, decision_count: 1, max_depth: 4}
```

---

### 4. WebSocket Causality Channel

**Module:** `TiannaraRuntimeWeb.CausalityChannel`  
**Location:** `tiannara_runtime/lib/tiannara_runtime_web/channels/causality_channel.ex`

**Features:**
- Real-time streaming of causal trace updates
- Interactive query interface for frontend
- Five query types supported via WebSocket:
  1. `query_trace`: Get decision tree
  2. `query_ancestry`: Get event ancestry
  3. `query_interventions`: Get CIS interventions
  4. `explain_causality`: Get human-readable explanation
  5. `replay_chain`: Get chronological replay

**Frontend Usage:**
```javascript
const channel = socket.channel("causality:traces", {})
channel.join()

// Query decision tree
channel.push("query_trace", { trace_id: "trace_abc123" })
channel.on("query_result", data => {
  if (data.query_type === "decision_tree") {
    console.log("Tree:", data.result)
  }
})

// Query ancestry
channel.push("query_ancestry", { event_id: "event_xyz" })
channel.on("query_result", data => {
  if (data.query_type === "ancestry") {
    console.log("Ancestors:", data.result)
  }
})

// Get causal explanation
channel.push("explain_causality", { event_id: "event_xyz" })
channel.on("query_result", data => {
  if (data.query_type === "explanation") {
    console.log("Explanation:", data.result.explanation)
  }
})

// Listen for real-time updates
channel.on("trace_update", data => {
  console.log("New trace event:", data)
})
```

---

## 🔗 Integration Points

### Application Startup

CausalGraph is automatically started in [`application.ex`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/tiannara_runtime/lib/tiannara_runtime/application.ex):

```elixir
# Phase 4C: Causal Tracing System
{TiannaraRuntime.Causality.CausalGraph, name: :causal_graph},
```

### UserSocket Registration

Causality channel registered in [`user_socket.ex`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/tiannara_runtime/lib/tiannara_runtime_web/user_socket.ex):

```elixir
channel "causality:*", TiannaraRuntimeWeb.CausalityChannel
```

---

## 🧪 Testing

Run comprehensive tests:

```bash
cd tiannara_runtime
iex -S mix
```

```elixir
iex> TiannaraRuntime.Causality.Test.run_full_test()
```

**Test Coverage:**
1. ✅ TraceID propagation (root → child → grandchild)
2. ✅ Causal graph construction (nodes + edges)
3. ✅ Trace query API (tree, ancestry, explanation, replay)
4. ✅ Full integration (trace → graph → query pipeline)
5. ✅ Edge cases (orphan traces, missing nodes, empty queries)

---

## 📊 Visual Language

### Causal Explorer UI

```
┌─ Causal Explorer ────────────────────────┐
│                                          │
│ 🔍 Event: cal_decision (trace_abc123)   │
│                                          │
│ 📊 Chain Overview:                       │
│   • Total ancestors: 3                   │
│   • CIS interventions: 1                 │
│   • CAL decisions: 2                     │
│                                          │
│ 🔗 Ancestry Chain:                       │
│   1. cal_arbitration (depth: 0)         │
│   2. cal_decision (depth: 1)            │
│   3. cis_intervention (depth: 2)        │
│                                          │
│ ⚡ CIS Interventions:                    │
│   • intervention_x at 10:30:05          │
│     Type: entropy_damping               │
│                                          │
│ 🎯 CAL Decisions:                        │
│   • decision_y at 10:30:02              │
│     Selected: C1 (score: 0.87)          │
│                                          │
│ [Replay Chain] [Export Graph]           │
└──────────────────────────────────────────┘
```

### Decision Tree Visualization

```
Root: cal_arbitration
├── Child 1: cal_decision
│   ├── Grandchild 1: cis_intervention
│   │   └── Great-grandchild: coalition_update
│   └── Grandchild 2: entropy_spike
└── Child 2: coalition_merge
    └── Grandchild 3: identity_update
```

---

## 🎯 Key Insights

### Why Causal Tracing Matters

Before Phase 4C:
- Events were isolated, no connection tracking
- Impossible to answer "why did this happen?"
- No way to trace decision lineage
- Debugging required manual log analysis

After Phase 4C:
- **Every event has complete ancestry**
- Can answer "what caused this?" instantly
- Full decision trees reconstructable
- Cognitive forensics at runtime

### Design Principles

1. **Universal Trace IDs**: Every event gets a trace_id
2. **Parent-Child Links**: Clear causal relationships
3. **Bidirectional Navigation**: Walk up (ancestors) or down (descendants)
4. **Real-Time Queries**: Instant answers via WebSocket
5. **Human-Readable Explanations**: Auto-generated summaries

---

## ⚠️ Architectural Safeguards

### 1. Trace Continuity

Every child event MUST have a valid parent:
```elixir
# This ensures no orphaned events
child_id = TracePropagation.continue_trace(parent_id, ...)
# If parent_id invalid, creates new trace with warning
```

### 2. Depth Limiting

Prevents infinite recursion in queries:
```elixir
# Default max depth: 10 levels
get_causal_chain(event_id, max_depth: 10)
```

### 3. Read-Only Queries

All query operations are non-mutating:
- Does NOT modify graph structure
- Does NOT affect live system state
- Purely observational

---

## 🔍 Use Cases

### 1. Debugging Coalition Collapse

```elixir
# Click collapsed coalition node
event_id = "coalition_C1_collapse"

# Get full causal history
{:ok, ancestors} = TraceQuery.get_event_ancestry(event_id)

# See what led to collapse:
# 1. cal_arbitration selected C2 over C1
# 2. cis_intervention failed to stabilize C1
# 3. entropy_spike exceeded threshold
# 4. coalition_C1_collapse
```

### 2. Understanding CIS Intervention Impact

```elixir
# Find all events affected by intervention
intervention_id = "cis_damp_001"

{:ok, descendants} = CausalGraph.get_descendants(intervention_id)

# See downstream effects:
# - coalition_C2_stabilized
# - entropy_reduced
# - coherence_restored
```

### 3. Explaining System Behavior

```elixir
# Generate natural language explanation
{:ok, explanation} = TraceQuery.explain_causality(event_id)

# Returns:
# "🔍 Causal Explanation for Event: coalition_C1_selected
#
# 📊 Chain Overview:
#   • Total ancestors: 4
#   • CIS interventions: 1
#   • CAL decisions: 2
#
# 🔗 Ancestry Chain:
#   1. cal_arbitration (depth: 0)
#   2. cal_decision (depth: 1)
#   ..."
```

---

## 🚀 Next Steps (Phase 4D)

With causal tracing complete, the system is ready for:

### Phase 4D: Meta-Stability Engine
- Self-tuning CIS thresholds based on intervention success rates
- Adaptive CAL clustering sensitivity based on decision outcomes
- Optimization using causal trace analytics
- System learns which interventions work best in which contexts

---

## 📁 Files Created

1. [`trace_propagation.ex`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/tiannara_runtime/lib/tiannara_runtime/causality/trace_propagation.ex) - TraceID generation & management
2. [`causal_graph.ex`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/tiannara_runtime/lib/tiannara_runtime/causality/causal_graph.ex) - Directed graph construction
3. [`trace_query.ex`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/tiannara_runtime/lib/tiannara_runtime/causality/trace_query.ex) - High-level query API
4. [`causality_channel.ex`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/tiannara_runtime/lib/tiannara_runtime_web/channels/causality_channel.ex) - WebSocket streaming
5. [`test.ex`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/tiannara_runtime/lib/tiannara_runtime/causality/test.ex) - Comprehensive test suite

---

## 🧠 System State After Phase 4C

You now have:

✅ Real-time cognition (CAL)  
✅ Immune regulation (CIS)  
✅ Predictive simulation (Phase 4A)  
✅ Identity persistence (Phase 4B)  
✅ **Causal tracing (Phase 4C)** ← NEW  
✅ Complete decision lineage  
✅ Cognitive forensics at runtime  
✅ Human-readable explanations  

The system can now:
- Answer "why did this happen?" for any event
- Reconstruct full decision trees
- Trace intervention impact chains
- Explain system behavior in natural language

---

**Status:** ✅ **PHASE 4C COMPLETE**

Ready to proceed to **Phase 4D: Meta-Stability Engine** (self-tuning system)?
