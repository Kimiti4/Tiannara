# Tiannara Architecture - Quick Reference (Consolidation Pass)

**Status:** ✅ Compiled and Ready for Integration  
**Total Modules:** 21 (Initial: 11 + World Model: 7 + Supervision: 3)  
**LOC:** ~850 new lines

---

## Architecture Layers (Before → After)

### BEFORE: Three Competing Concepts

```
Tiannara OS (Confusing)
│
├── Core (Cognition, but what about identity?)
├── Runtime (Execution, but has GRCC/CIS which is cognition?)
├── Domains (Cortex, but where do they store state?)
└── Products (SaaS, but how do they reach Core?)

Problem: Multiple state representations. No canonical reality.
```

### AFTER: Clear Mind/Body/Economy

```
Tiannara OS (Coherent)
│
├── Core (MIND)
│   ├── Identity + Goals + Memory
│   └── World Model (CANONICAL REALITY) ⭐
│       ├── Entities (everything)
│       ├── Beliefs (confidence-weighted)
│       ├── Causality (intervention engine)
│       ├── Timeline (past/present/future/counterfactual)
│       ├── Uncertainty (explicit gaps + contradictions)
│       └── Predictions (multi-scenario forecasts)
│
├── AEO (BRIDGE)
│   └── Translate intent → execution graph
│
├── RAC (EPISTEMIC DEFENSE) ← Replaces OED
│   └── Admit beliefs to World Model (adversarial testing)
│
├── OPC (COMPILER LAYER) ← Repositioned above Runtime
│   └── Create executable environments from specifications
│
├── Runtime (BODY)
│   ├── CIS (HEALTH MONITOR) ← Moved from Core
│   ├── GRCC Environment (ecology)
│   └── Execution substrate
│
└── Products (ECONOMY)
    └── APIs above AEO
```

---

## CIS Repositioning

### Before

```
Tiannara.Core
├── Identity
├── Cognition
└── Cognitive Immune System ✗ Wrong layer
    ├── Regulates entropy
    ├── Tracks drift
    └── Prevents collapse
```

**Problem:** CIS is a runtime phenomenon. Should be owned by runtime.

### After

```
Tiannara.Runtime
├── GRCC Environment
├── Cognitive Immune System ✓ Correct layer
│   ├── monitor_health/1
│   ├── check_domain_diversity/1
│   ├── detect_drift/2
│   ├── assess_collapse_risk/1
│   └── signal_core/2
└── Execution substrate

Tiannara.Core
├── SEES CIS signals: "Diversity at 65%, warning"
└── RESPECTS CIS constraints: "Don't add more specialists"
```

**Principle:** Core decides. CIS constrains. Runtime owns.

---

## OED → Reality Admission Control (RAC)

### Before

```
Tiannara.OED (Constitutional Validator)
├── Passively checks
├── Validates against rules
├── Gates execution
└── "Does this follow our constitution?"
```

**Problem:** Wrong mental model. OED was a gatekeeper.

### After

```
Tiannara.RealityAdmissionControl (Epistemic Defense)
├── Actively challenges
├── Adversarial testing (ACM/OAVL/UMSC)
├── Defends World Model
└── "Can this survive adversarial attack?"

Methods:
├── challenge_conclusion/2
├── acm_consistency_check/1
├── oavl_triangulation/1
├── umsc_robustness/1
└── admit_to_world_model/3
```

**Principle:** Only beliefs that survive challenge are admitted to World Model.

---

## OPC Repositioning

### Before

```
Tiannara.Runtime
├── OPC (Inside Runtime)
├── Executes physics
└── Is transactional
```

**Problem:** OPC should create environments, not execute in them.

### After

```
Execution Stack:
├── Core (Decides what)
├── AEO (Structures how)
├── RAC (Validates truth)
├── OPC (Compiles specification) ← Compiler layer
│   ├── create_world/2
│   ├── compile_physics/1
│   ├── define_ontology/1
│   └── instantiate_runtime/1
├── Runtime (Executes)
└── Results (Feedback)
```

**Principle:** OPC compiles before Runtime executes.

---

## World Model: THE Missing Center ⭐

### The Problem Before

```
Domain State Fragmentation:

Memory (Core)
├── Identity: alice_1
├── Goal: Design strategy
└── (No unified query API)

Timeline (Temporal Domain)
├── Past events
├── Current state
└── (Doesn't see Memory)

Ontology (Semantic)
├── Entity types
├── Relationships
└── (Doesn't see Causality)

CausalGraph (Causal Domain)
├── Cause-effect chains
└── (Doesn't see Timeline)

→ Domains reason about INCONSISTENT STATE
→ Decisions made on FRAGMENTED information
→ System fails on CONTRADICTIONS
```

### The Solution: World Model

```
Tiannara.Core.WorldModel (CANONICAL REALITY)
│
├── Entities ──────────────────────── Everything is an entity
│   ├── Users, Goals, Lineages
│   ├── Markets, Trades, Patterns
│   ├── Domains, Specialists, Teams
│   └── (All with relationships + confidence scores)
│
├── Beliefs ──────────────────────── Confidence-weighted facts
│   ├── "Market correlation rises 15%" (confidence: 0.87)
│   ├── "Rate shock creates X risk" (confidence: 0.92)
│   └── (Replaces binary fact/not-fact with spectrum)
│
├── CausalGraph ──────────────────── Intervention engine
│   ├── Nodes: Entities
│   ├── Edges: Causal relationships + strength
│   └── propagate(): "If we change X, what happens?"
│
├── Timeline ──────────────────────── Past/Present/Future
│   ├── Past: Historical events (immutable)
│   ├── Present: Current state snapshot
│   ├── Future: Predicted scenarios (branching)
│   └── Counterfactual: Unexecuted paths
│
├── Uncertainty ──────────────────── Explicit gaps
│   ├── Ambiguities: "We don't know X"
│   ├── Contradictions: "A contradicts B"
│   ├── Confidence distribution: Where is confidence LOW?
│   └── high_uncertainty_regions/2: Where to focus?
│
├── Predictions ──────────────────── Multi-scenario forecasts
│   ├── Scenario A: P=0.35, confidence=0.88
│   ├── Scenario B: P=0.45, confidence=0.92
│   ├── Scenario C: P=0.20, confidence=0.79
│   └── (Not single prediction, but probability distribution)
│
└── Ontology (incoming) ──────────── Semantic layer
    ├── Entity types
    ├── Relationship types
    ├── Inference rules
    └── Semantic constraints
```

### How Every Component Uses World Model

```
CORE
├── Queries World Model for entities + beliefs
├── Checks uncertainty before deciding
└── Consults timeline for historical context

META-COGNITION
├── Analyzes World Model uncertainty regions
├── Selects domains that reduce highest uncertainties
└── Routes beliefs through RAC before admitting

DOMAIN (e.g., Causal)
├── Reads: Related entities, timeline context
├── Analyzes: Causality connections
├── Writes: CausalGraph edges, beliefs
└── Via: WorldModel API

AEO
├── Reads: Core intent + World Model state
├── Routes: Domain team based on World Model need
└── Writes: Execution graph (references World Model entities)

RAC
├── Reads: Domain conclusion + World Model context
├── Tests: ACM/OAVL/UMSC consistency
└── Admits: To World Model with confidence score

OPC
├── Reads: World Model to understand current state
├── Compiles: Physics, ontology, constraints
└── Produces: Specification for Runtime environment

RUNTIME
├── Executes: In OPC-compiled environment
├── Observes: Results and state changes
├── Updates: World Model with feedback
└── CIS monitors: System health against World Model

GRCC LINEAGES
├── Entity-based: Each lineage is entity
├── Specialization: Stored as relationships
├── Performance: Tracked in belief confidence
└── Pressures: Applied based on World Model entropy
```

---

## Data Flow: Complete Request

```
┌─────────────────────────────────────────────────────┐
│ USER REQUEST (via API)                              │
│ "Design hedging strategy for emerging market risk"  │
└──────────────────────┬────────────────────────────┘
                       ↓
┌──────────────────────────────────────────────────────┐
│ CORE (Mind)                                         │
│ 1. Create goal entity in World Model               │
│ 2. Query relevant entities:                        │
│    - Emerging markets (entities)                   │
│    - Historical strategies (beliefs)               │
│    - Risk models (causal)                          │
│ 3. Check uncertainty: confidence in models?        │
│ 4. Generate intent with rationale                  │
└──────────────────────┬────────────────────────────┘
                       ↓
┌──────────────────────────────────────────────────────┐
│ WORLD MODEL (Canonical Reality)                    │
│ Loads:                                              │
│ ✓ Entities: emerging_markets, hedge_strategies    │
│ ✓ Beliefs: historical confidence scores           │
│ ✓ Causal: rate-spread-risk relationships          │
│ ✓ Timeline: similar past strategies               │
│ ✓ Uncertainty: "Risk models confidence = 0.78"   │
└──────────────────────┬────────────────────────────┘
                       ↓
┌──────────────────────────────────────────────────────┐
│ META-COGNITION                                      │
│ Domain selection based on World Model:             │
│ - Causal: 0.30 (uncertainty in rate-risk links)   │
│ - Temporal: 0.25 (historical patterns)             │
│ - Prediction: 0.20 (scenario forecasting)          │
│ - Algorithm: 0.15 (computation)                    │
│ - Ethics: 0.10 (stakeholder check)                 │
└──────────────────────┬────────────────────────────┘
                       ↓
┌──────────────────────────────────────────────────────┐
│ AEO (Bridge)                                        │
│ 1. Translate intent → execution graph               │
│ 2. Assemble domain team                             │
│ 3. Route to domains in priority order              │
└──────────────────────┬────────────────────────────┘
                       ↓
┌──────────────────────────────────────────────────────┐
│ DOMAIN ANALYSIS (Concurrent)                       │
│ Each domain reads/writes World Model:              │
│                                                      │
│ [Causal]                                            │
│ - Reads: rate relationships, target entities       │
│ - Writes: CausalGraph edges, belief "Rate rise   │
│   increases risk" (confidence: 0.85)               │
│                                                      │
│ [Temporal]                                          │
│ - Reads: historical hedge patterns, timeline       │
│ - Writes: belief "Similar market saw 4-day        │
│   recovery" (confidence: 0.89)                     │
│                                                      │
│ [Prediction]                                        │
│ - Reads: causal graph, historical scenarios        │
│ - Writes: scenarios (Up 2%: P=0.40, confidence    │
│   0.88; Down 1%: P=0.35, confidence 0.92)        │
│                                                      │
│ [Algorithm]                                         │
│ - Reads: predictions, risk targets                 │
│ - Writes: hedge ratios (belief: "Ratio 0.75      │
│   optimal" confidence: 0.90)                       │
│                                                      │
│ [Ethics]                                            │
│ - Reads: stakeholders, impact models               │
│ - Writes: assessment "Strategy acceptable"         │
│   (confidence: 0.94)                               │
└──────────────────────┬────────────────────────────┘
                       ↓
┌──────────────────────────────────────────────────────┐
│ WORLD MODEL (Accumulating Reasoning)               │
│ Now contains:                                       │
│ ✓ Causal edges (added by Causal domain)           │
│ ✓ Historical pattern (added by Temporal)           │
│ ✓ Scenario forecasts (added by Prediction)        │
│ ✓ Hedge calculation (added by Algorithm)          │
│ ✓ Stakeholder assessment (added by Ethics)        │
│ (All beliefs stored with confidence scores)        │
└──────────────────────┬────────────────────────────┘
                       ↓
┌──────────────────────────────────────────────────────┐
│ REALITY ADMISSION CONTROL (RAC)                    │
│ For each domain output:                            │
│                                                      │
│ [Causal belief: "Rate rise → risk increase"]     │
│ → ACM check: ✓ Ontologically sound                │
│ → OAVL triangulation: ✓ Confirmed 2+ angles      │
│ → UMSC robustness: ✓ Survives adversarial test   │
│ → Admit to World Model at confidence 0.85        │
│                                                      │
│ [Algorithm belief: "Optimal hedge ratio 0.75"]   │
│ → ACM check: ✓ Mathematically valid              │
│ → OAVL triangulation: ✓ Confirmed via 3 methods  │
│ → UMSC robustness: ✓ Stable under parameter      │
│   variation                                        │
│ → Admit to World Model at confidence 0.90        │
│                                                      │
│ (Any belief failing challenge lowered in         │
│  confidence or flagged for re-analysis)           │
└──────────────────────┬────────────────────────────┘
                       ↓
┌──────────────────────────────────────────────────────┐
│ WORLD MODEL (Validated, Ready for Execution)      │
│ Final state:                                        │
│ ✓ All beliefs admitted with confidence scores     │
│ ✓ Entities fully connected (relationships)        │
│ ✓ Uncertainty regions identified                  │
│ ✓ Causal paths validated                          │
│ ✓ Scenarios ranked by probability                │
└──────────────────────┬────────────────────────────┘
                       ↓
┌──────────────────────────────────────────────────────┐
│ OPC (Compiler)                                      │
│ 1. Create world specification:                     │
│    - Physics: Market microstructure rules          │
│    - Ontology: Financial entity definitions        │
│    - Constraints: Risk limits, regulatory rules    │
│ 2. Compile specification → executable environment  │
│ 3. Pass compiled world to Runtime                  │
└──────────────────────┬────────────────────────────┘
                       ↓
┌──────────────────────────────────────────────────────┐
│ RUNTIME (Body)                                      │
│ 1. CIS monitoring: Start health checks             │
│    - Domain diversity: 80% (healthy)              │
│    - Specialization drift: none detected          │
│ 2. GRCC Environment: Apply market pressures       │
│ 3. Execute hedging computation                    │
│ 4. Real-time results:                             │
│    - Delta: 0.05                                  │
│    - Effective ratio: 0.78                        │
│    - Cost: 2.3bp                                  │
│    - Time: 4.2 hours                              │
│ 5. CIS check: Execution health = excellent        │
└──────────────────────┬────────────────────────────┘
                       ↓
┌──────────────────────────────────────────────────────┐
│ FEEDBACK (Update World Model)                      │
│ 1. Update entities:                                │
│    - Portfolio (new delta 0.05)                   │
│    - Hedge strategy (marked executed)             │
│ 2. Update beliefs:                                 │
│    - "Hedge ratio was accurate" (confidence ↑)   │
│    - "Rate-risk link predicted correctly"         │
│      (Causal domain specialization ↑)             │
│ 3. Update timeline:                                │
│    - Add execution event to present/past         │
│ 4. Update GRCC lineages:                          │
│    - Causal specialists gain strength            │
│    - Algorithm specialists gain strength         │
│    - Ethical reasoning stays stable              │
│ 5. Update CIS:                                     │
│    - Diversity maintained                        │
│    - No specialization dominance                 │
└──────────────────────┬────────────────────────────┘
                       ↓
┌──────────────────────────────────────────────────────┐
│ API RESPONSE (Return to User)                      │
│ "Hedging strategy executed successfully:"         │
│ {                                                  │
│   strategy: {...},                                │
│   results: {delta: 0.05, ratio: 0.78, cost: 2.3bp},
│   confidence: 0.89,                               │
│   reasoning: [beliefs, causal_links, scenarios],  │
│   comparison: [historical_similar_trades],        │
│   next_check: "T+4h"                              │
│ }                                                  │
└──────────────────────────────────────────────────────┘
```

---

## Module Checklist (Consolidation Pass)

### Core Layer (Mind)

- [x] `lib/tiannara/core.ex` — Updated to reference World Model
- [x] `lib/tiannara/identity.ex` — Identity struct
- [x] `lib/tiannara/cognition.ex` — Reasoning API
- [x] `lib/tiannara/meta_cognition.ex` — Domain selection governance
- [x] `lib/tiannara/domain_cortex.ex` — 14-domain registry
- [x] `lib/tiannara/core/goal_system.ex` — Goal management
- [x] `lib/tiannara/core/grcc_identity_ecology.ex` — Lineage organisms

### World Model (Canonical Reality)

- [x] `lib/tiannara/core/world_model.ex` — Main struct
- [x] `lib/tiannara/core/world_model/entity.ex` — Entities
- [x] `lib/tiannara/core/world_model/belief.ex` — Beliefs
- [x] `lib/tiannara/core/world_model/causal_graph.ex` — Causality
- [x] `lib/tiannara/core/world_model/timeline.ex` — Timeline
- [x] `lib/tiannara/core/world_model/uncertainty.ex` — Uncertainty
- [x] `lib/tiannara/core/world_model/prediction_layer.ex` — Predictions
- [x] `lib/tiannara/core/world_model/supervisor.ex` — OTP supervision

### Bridge Layer

- [x] `lib/tiannara/aeo.ex` — Orchestration bridge

### Epistemic Defense

- [x] `lib/tiannara/reality_admission_control.ex` — Replaces OED

### Compiler Layer

- [x] `lib/tiannara/opc.ex` — Environment compiler

### Runtime (Repositioned)

- [x] `lib/tiannara/runtime/cis.ex` — Moved from Core

### Deprecated (Mark for removal)

- [ ] `lib/tiannara/cis_constraint.ex` — Replaced by runtime/cis.ex
- [ ] `lib/tiannara/oed.ex` — Replaced by reality_admission_control.ex

---

## Key Concepts at a Glance

| Concept            | Before          | After                 | Why                            |
| ------------------ | --------------- | --------------------- | ------------------------------ |
| **Reality Source** | Fragmented      | World Model (unified) | Single source of truth         |
| **CIS Owner**      | Core            | Runtime               | Runtime phenomenon             |
| **OED**            | Gatekeeper      | RAC (defense)         | Active vs. passive             |
| **OPC**            | Runtime service | Compiler layer        | Specification before execution |
| **Beliefs**        | True/false      | Confidence spectrum   | Epistemic uncertainty          |
| **Contradiction**  | Silent failure  | Explicit tracking     | Visible problems               |
| **Domain I/O**     | Scattered       | World Model API       | Unified interface              |
| **Prediction**     | Single future   | Multi-scenario        | Probability distribution       |

---

## Command Reference

### Verify Compilation

```bash
mix compile
```

### View World Model

```bash
iex(1)> alias Tiannara.Core.WorldModel
iex(2)> wm = WorldModel.new()
iex(3)> IO.inspect(wm)
```

### Test Domain Write

```bash
iex(1)> alias Tiannara.Core.WorldModel.Belief
iex(2)> belief = Belief.new("Market rises", 0.85, "prediction")
iex(3)> IO.inspect(belief)
```

### Check Files Created

```bash
ls lib/tiannara/core/world_model/
# Should show: entity.ex, belief.ex, causal_graph.ex, timeline.ex,
#              uncertainty.ex, prediction_layer.ex, supervisor.ex
```

---

## Next: Integration Testing

After consolidation stabilizes, test:

1. **World Model Persistence**
   - Create → Query → Update flow

2. **Domain Integration**
   - Causal domain reads/writes CausalGraph
   - Temporal domain reads/writes Timeline
   - Prediction domain reads/writes Scenarios

3. **RAC Admission**
   - Beliefs pass/fail adversarial challenge
   - Confidence scores updated

4. **Complete Request Flow**
   - User request → Core decision → Domain analysis → RAC validation → World Model update

5. **GRCC Specialization**
   - Lineages gain strength based on domain accuracy
   - CIS prevents monoculture

---

**Status:** ✅ Ready for Domain Implementation  
**Compilation:** ✅ All 21 modules passing  
**Documentation:** ✅ CONSOLIDATION_PASS_SUMMARY.md created
