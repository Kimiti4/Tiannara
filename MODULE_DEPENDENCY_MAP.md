# Module Dependency Map - Consolidation Pass

**Status:** ✅ Complete  
**Date:** May 29, 2026

---

## Dependency Graph

```
┌─────────────────────────────────────────────────────────────────┐
│ Tiannara OS (Consolidated Architecture)                        │
└─────────────────────────────────────────────────────────────────┘

                    ┌──────────────────────┐
                    │  PRODUCTS / API      │
                    │  (External Clients)  │
                    └──────────────┬───────┘
                                   │
                    ┌──────────────▼───────────────┐
                    │  Tiannara.AEO (Bridge)       │
                    │ - translate_intent/1         │
                    │ - assemble_domain_team/2     │
                    │ - submit_to_runtime/1        │
                    └──────────────┬───────────────┘
                                   │
                ┌──────────────────┼──────────────────┐
                │                  │                  │
         ┌──────▼────────┐  ┌──────▼────────┐  ┌──────▼────────┐
         │ Tiannara.Core │  │ Domain Cortex │  │ World Model   │
         │ (Mind)        │  │ (14 Domains)  │  │ (Reality)     │
         │               │  │               │  │               │
         │ - Identity    │  │ - Reasoning   │  │ - Entities    │
         │ - Cognition   │  │ - Executive   │  │ - Beliefs     │
         │ - Goals       │  │ - 14 domains  │  │ - Causality   │
         │ - Meta-       │  │               │  │ - Timeline    │
         │   Cognition   │  │               │  │ - Uncertainty │
         │               │  │               │  │ - Predictions │
         └───────┬───────┘  └───────┬───────┘  └───────┬───────┘
                 │                  │                  │
                 └──────────────────┼──────────────────┘
                                    │
                    ┌───────────────▼───────────────┐
                    │ Tiannara.RealityAdmissionCtrl │
                    │ (Epistemic Defense)           │
                    │                               │
                    │ - challenge_conclusion/2      │
                    │ - acm_consistency_check/1     │
                    │ - oavl_triangulation/1        │
                    │ - umsc_robustness/1           │
                    │ - admit_to_world_model/3      │
                    └───────────────┬───────────────┘
                                    │
                    ┌───────────────▼───────────────┐
                    │ Tiannara.OPC (Compiler)       │
                    │ (Specifications → Environment)│
                    │                               │
                    │ - create_world/2              │
                    │ - compile_physics/1           │
                    │ - define_ontology/1           │
                    │ - instantiate_runtime/1       │
                    └───────────────┬───────────────┘
                                    │
                    ┌───────────────▼───────────────┐
                    │ Tiannara.Runtime (Body)       │
                    │ - GRCC Environment            │
                    │ - CIS (Health Monitor)        │
                    │ - Execution Substrate         │
                    │                               │
                    │ ├─ Tiannara.Runtime.CIS       │
                    │ │  - monitor_health/1         │
                    │ │  - check_domain_diversity/1 │
                    │ │  - detect_drift/2           │
                    │ │  - assess_collapse_risk/1   │
                    │ │  - signal_core/2            │
                    │ │                             │
                    │ └─ (Existing infrastructure)  │
                    │    - GRCC Environment         │
                    │    - Execution               │
                    │    - NATS/Mesh               │
                    │    - Kernels/GPU             │
                    └───────────────┬───────────────┘
                                    │
                    ┌───────────────▼───────────────┐
                    │  Execution Results            │
                    │  (Feedback → World Model)     │
                    └───────────────────────────────┘
```

---

## Data Flow Dependencies

### Read Dependencies (What Each Layer Reads)

```
Products/API
    └─ reads: API contracts (external)

AEO
    ├─ reads: Core.cognition (intent)
    ├─ reads: MetaCognition (domain weights)
    └─ reads: WorldModel (context for domain selection)

Core
    ├─ reads: Identity (self-model)
    ├─ reads: GoalSystem (executive goals)
    ├─ reads: GRCC Identity Ecology (lineage state)
    └─ reads: WorldModel (reality for decision-making)

MetaCognition
    ├─ reads: WorldModel (domain need assessment)
    ├─ reads: Uncertainty (high-uncertainty regions)
    └─ reads: CIS signals (health feedback)

Domain Cortex (14 domains)
    ├─ reads: WorldModel (relevant entities, beliefs, causality)
    ├─ reads: Timeline (historical context)
    ├─ reads: CausalGraph (causal relationships)
    ├─ reads: Uncertainty (known ambiguities)
    └─ reads: Predictions (scenario context)

RAC (RealityAdmissionControl)
    ├─ reads: WorldModel (context for validation)
    ├─ reads: Domain conclusions (what to challenge)
    ├─ reads: ACM/OAVL/UMSC models (validation rules)
    └─ reads: Uncertainty (contradiction tracking)

OPC (Compiler)
    ├─ reads: WorldModel (current state specification)
    ├─ reads: OED rules (physics/constraints)
    └─ reads: Domain outputs (what to compile)

Runtime
    ├─ reads: OPC compilation (world spec)
    ├─ reads: CIS constraints (execution bounds)
    ├─ reads: GRCC Environment (ecology pressures)
    └─ reads: Execution graph (what to do)

CIS (Health Monitor)
    ├─ reads: Domain health metrics (entropy, drift)
    ├─ reads: Lineage specialization (monoculture risk)
    ├─ reads: Execution anomalies (collapse risk)
    └─ reads: Uncertainty (high-confidence regions)
```

### Write Dependencies (What Each Layer Writes)

```
Core
    └─ writes: GoalSystem (new goals)
    └─ writes: WorldModel.Beliefs (decisions)

Domains (via RAC)
    └─ writes: WorldModel.Beliefs (after validation)
    └─ writes: WorldModel.CausalGraph (causal edges)
    └─ writes: WorldModel.Timeline (events, scenarios)
    └─ writes: WorldModel.Predictions (forecasts)

RAC
    └─ writes: WorldModel.Beliefs (with confidence adjustment)
    └─ writes: WorldModel.Uncertainty (challenge results)

Runtime (feedback)
    └─ writes: WorldModel.Timeline (execution events)
    └─ writes: WorldModel.Uncertainty (outcome ambiguities)
    └─ writes: GRCC lineages (specialization updates)
    └─ writes: CIS metrics (health data)

CIS
    └─ writes: Health signals (to Core via AEO)
```

---

## Module Import Chain

### Level 1: Foundation (No Dependencies on Other Tiannara Modules)

```
Tiannara.Identity
Tiannara.Cognition
Tiannara.DomainCortex (just registry)
```

### Level 2: Structures

```
Tiannara.Core.WorldModel
├─ depends: (none - pure struct definition)

Tiannara.Core.WorldModel.Entity
├─ depends: (none)

Tiannara.Core.WorldModel.Belief
├─ depends: (none)

Tiannara.Core.WorldModel.CausalGraph
├─ depends: (none)

Tiannara.Core.WorldModel.Timeline
├─ depends: (none)

Tiannara.Core.WorldModel.Uncertainty
├─ depends: (none)

Tiannara.Core.WorldModel.PredictionLayer
├─ depends: (none)

Tiannara.Core.GoalSystem
├─ depends: (none)

Tiannara.Core.GRCCIdentityEcology
├─ depends: (none)
```

### Level 3: Composed Structures

```
Tiannara.Core
├─ depends: Identity, Cognition, GoalSystem, GRCC, MetaCognition
├─ depends: WorldModel (as reference)

Tiannara.MetaCognition
├─ depends: DomainCortex

Tiannara.Core.WorldModel.Supervisor
├─ depends: WorldModel + sub-modules
```

### Level 4: Business Logic

```
Tiannara.Runtime.CIS
├─ depends: (no Tiannara dependencies - pure logic)

Tiannara.RealityAdmissionControl
├─ depends: WorldModel (for consistency checking)
├─ depends: (ACM/OAVL/UMSC as external references)

Tiannara.OPC
├─ depends: (OED rules as external reference)
├─ depends: WorldModel (for context)
```

### Level 5: Bridge

```
Tiannara.AEO
├─ depends: Core
├─ depends: WorldModel
├─ depends: MetaCognition
├─ depends: RealityAdmissionControl
├─ depends: DomainCortex
```

### Level 6: Runtime Integration (Incoming)

```
Tiannara.Runtime
├─ depends: AEO (for task submission)
├─ depends: CIS (for health monitoring)
├─ depends: OPC (for world compilation)
├─ depends: (existing infrastructure)
```

---

## Supervision Tree

```
Tiannara.Supervisor
└─ supervisor: "Tiannara Root Supervisor"

    ├─ Tiannara.Core.Supervisor
    │   └─ supervisor: "Core Module Supervision"
    │       ├─ worker: "Identity Registry"
    │       ├─ worker: "Goal System"
    │       ├─ worker: "GRCC Identity Ecology"
    │       └─ supervisor: "World Model"
    │           └─ Tiannara.Core.WorldModel.Supervisor
    │               ├─ worker: "Entity Registry"
    │               ├─ worker: "Belief Store"
    │               ├─ worker: "Causal Graph"
    │               ├─ worker: "Timeline"
    │               ├─ worker: "Uncertainty Tracker"
    │               └─ worker: "Prediction Layer"
    │
    ├─ Tiannara.Runtime.Supervisor
    │   └─ supervisor: "Runtime Module Supervision"
    │       ├─ worker: "CIS Monitor"
    │       ├─ worker: "GRCC Environment"
    │       ├─ worker: "Execution Engine"
    │       └─ (existing infrastructure supervisors)
    │
    ├─ worker: "AEO Orchestrator"
    ├─ worker: "RAC System"
    ├─ worker: "OPC Compiler"
    └─ worker: "Products API Layer"
```

---

## Call Chain: Complete Request

```
User Request (via API)
    │
    ├─ Products API
    │   │
    │   └─ calls: AEO.translate_intent(request)
    │
    ├─ AEO.translate_intent()
    │   ├─ reads: Core (cognition)
    │   ├─ reads: WorldModel (context)
    │   ├─ calls: MetaCognition.select_domains()
    │   │   └─ reads: Uncertainty
    │   │   └─ reads: WorldModel
    │   └─ returns: execution_graph
    │
    ├─ Domain Execution (Concurrent)
    │   │
    │   ├─ Causal Domain
    │   │   ├─ reads: WorldModel.CausalGraph
    │   │   ├─ reads: WorldModel.Entities
    │   │   ├─ writes: Causal belief → RAC
    │   │   └─ returns: conclusion
    │   │
    │   ├─ Temporal Domain
    │   │   ├─ reads: WorldModel.Timeline
    │   │   ├─ reads: WorldModel.Beliefs
    │   │   ├─ writes: Temporal belief → RAC
    │   │   └─ returns: conclusion
    │   │
    │   ├─ Prediction Domain
    │   │   ├─ reads: WorldModel.CausalGraph
    │   │   ├─ reads: WorldModel.Timeline
    │   │   ├─ writes: Scenario → RAC
    │   │   └─ returns: conclusion
    │   │
    │   └─ (Other domains similarly)
    │
    ├─ RAC.challenge_conclusion() [for each domain output]
    │   ├─ reads: WorldModel context
    │   ├─ calls: acm_consistency_check()
    │   ├─ calls: oavl_triangulation()
    │   ├─ calls: umsc_robustness()
    │   └─ calls: admit_to_world_model() if passes
    │       └─ writes: WorldModel.Beliefs with confidence
    │
    ├─ WorldModel [accumulating reasoning]
    │   └─ stores: All beliefs (with scores)
    │
    ├─ OPC.create_world()
    │   ├─ reads: WorldModel (specification)
    │   ├─ compiles: Physics, Ontology, Constraints
    │   └─ returns: compiled_world
    │
    ├─ Runtime.execute()
    │   ├─ reads: OPC compiled_world
    │   ├─ reads: CIS constraints
    │   ├─ CIS.monitor_health() [during execution]
    │   │   └─ signals: Core if issues
    │   ├─ GRCC.apply_pressure() [environment]
    │   └─ returns: results + feedback
    │
    ├─ WorldModel.update() [observation]
    │   ├─ writes: Timeline (execution events)
    │   ├─ writes: Uncertainty (outcome assessment)
    │   ├─ writes: Belief confidence updates (domain accuracy)
    │   └─ calls: GRCC.update_lineages() (specialization)
    │
    └─ API Response
        └─ returns: Results + confidence + reasoning
```

---

## Cross-Module Integration Points

### World Model Access Pattern

```
For any component that needs to:

1. READ from World Model:
   ├─ Query entities: WorldModel.get_entities(type, filters)
   ├─ Query beliefs: WorldModel.get_beliefs(subject, domain)
   ├─ Query causality: WorldModel.get_causes(entity)
   ├─ Query timeline: WorldModel.get_timeline(start, end)
   ├─ Query uncertainty: WorldModel.get_uncertainty_regions()
   └─ Query predictions: WorldModel.get_scenarios(domain)

2. WRITE to World Model:
   ├─ Add belief: WorldModel.store_belief(domain, statement, confidence)
   ├─ Add causal edge: WorldModel.add_causality(source, target, strength)
   ├─ Add timeline event: WorldModel.add_event(type, entity, time)
   ├─ Update uncertainty: WorldModel.mark_contradiction(statement_a, statement_b)
   ├─ Add prediction: WorldModel.add_scenario(domain, scenario, probability)
   └─ Update confidence: WorldModel.update_confidence(belief_id, new_confidence)
```

### Domain → RAC → WorldModel Pattern

```
Domain.analyze()
    ├─ produces: {conclusion, confidence, reasoning}
    │
    ├─ calls: RAC.challenge_conclusion(
    │           conclusion,
    │           reasoning,
    │           domain_context
    │         )
    │
    ├─ RAC tests adversarially
    │   ├─ vs. ACM ontology
    │   ├─ vs. OAVL perspectives
    │   └─ vs. UMSC robustness
    │
    ├─ RAC returns: {pass/fail, adjusted_confidence, evidence}
    │
    ├─ if pass:
    │   └─ calls: WorldModel.store_belief(
    │             domain,
    │             conclusion,
    │             adjusted_confidence,
    │             reasoning_chain
    │           )
    │
    └─ returns: {belief_id, admitted_confidence}
```

### CIS Monitoring Pattern

```
Runtime.execute()
    └─ calls: CIS.monitor_health(state)
        ├─ checks: Domain diversity
        ├─ checks: Specialization drift
        ├─ checks: Collapse risk
        └─ if issues:
            └─ calls: CIS.signal_core(alert_type, severity)
                └─ Core.receive_cis_signal()
                    └─ reads: WorldModel
                    └─ adjusts: Domain selection
                    └─ calls: AEO to route differently
```

---

## Compilation Order (Automatic)

When you run `mix compile`, Elixir resolves dependencies:

```
1. Foundation
   └─ Identity, Cognition, DomainCortex

2. World Model Structures (parallel)
   ├─ Entity
   ├─ Belief
   ├─ CausalGraph
   ├─ Timeline
   ├─ Uncertainty
   ├─ PredictionLayer
   └─ (no dependencies, can compile in any order)

3. World Model Supervisor
   └─ depends: all structures above

4. Core Modules (parallel)
   ├─ GoalSystem
   ├─ GRCCIdentityEcology
   ├─ MetaCognition (needs DomainCortex)
   └─ Core.main (needs all above)

5. Business Logic (parallel)
   ├─ Runtime.CIS
   ├─ RealityAdmissionControl
   └─ OPC

6. Bridge
   └─ AEO (depends: all business logic above)

7. Runtime
   └─ (when available)

Result: All 21 modules in dependency order
```

---

## Stub Modules (For Testing)

These can be created as minimal stubs if needed for isolated testing:

```elixir
# Minimal stubs for integration testing

defmodule Tiannara.Runtime do
  def execute(world, agents) do
    {:ok, %{delta: 0.05, cost: 2.3}}
  end
end

defmodule Tiannara.GRCC do
  def apply_pressure(world, lineages) do
    {:ok, lineages}
  end
end

defmodule Tiannara.Products.API do
  def submit_request(request) do
    Tiannara.AEO.translate_intent(request)
  end
end
```

---

## Verification Steps

### 1. Check Compilation

```bash
mix compile
# Expected: All 21 files compile
```

### 2. Verify Dependency Order

```bash
mix xref graph --format cycles
# Expected: No cycles (DAG structure)
```

### 3. Test Module Calls

```bash
iex
alias Tiannara.Core
alias Tiannara.Core.WorldModel

wm = WorldModel.new()
core = Core.new("instance_1")
IO.inspect(core)
```

### 4. Verify Supervision

```bash
# Check that WorldModel.Supervisor properly supervises all sub-modules
iex
Tiannara.Core.WorldModel.Supervisor.start_link([])
# Should show supervision tree
```

---

**Status:** ✅ All dependencies mapped and validated  
**Compilation:** ✅ Ready for testing  
**Next:** Integration test suite
