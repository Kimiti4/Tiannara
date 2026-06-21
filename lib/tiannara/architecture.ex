defmodule Tiannara.Architecture do
  @moduledoc """
  Tiannara Unified Architecture - Mind, Body, Economy

  ## Overview

  Tiannara is organized into four primary layers:

  1. **Tiannara Core** (Mind) - Cognition and intent
  2. **Tiannara Domain Cortex** - Specialized reasoning
  3. **Tiannara Runtime** (Body) - Execution and stability
  4. **Tiannara Products** (Economy) - SaaS and commercialization

  ## 1. Tiannara Core (Mind)

  Owns:
  - **Identity Field**: Self-model, long-term memory, goals, values, preferences
  - **Cognition**: Reasoning, planning, world modeling, meta-cognition, learning
  - **Executive Intent**: Decides what, why, and desired outcomes
  - **GRCC Identity Ecology**: Manages identities, lineages, and specialization
  - **Goal System**: Tracks and manages executive goals

  Does NOT own:
  - Environmental pressures or resource constraints
  - Execution substrate or scheduling
  - Physical rules or execution state

  ## 2. Tiannara Domain Cortex (14 Domains)

  Specialized reasoning capabilities, not infrastructure:

  ### Reasoning Cortex (Original 8 Domains)
  - Temporal
  - Combinatorial
  - Reverse Engineering
  - Causal
  - Prediction
  - Logic
  - Algorithm
  - NLP

  Answers: "How do I think?"

  ### Executive Cortex (Cognitive 6 Domains)
  - Meta-Cognition (Domain Governor)
  - Collective Intelligence
  - Creative Synthesis
  - Social Intelligence
  - Ethical Reasoning
  - Embodied Cognition

  Answers: "How do I coordinate thinking?"

  ## 3. AEO (Adaptive Execution Orchestrator)

  The bridge layer between Core and Runtime.

  Responsibilities:
  - Translate Core intent into execution graphs
  - Assemble domain teams based on Meta-Cognition guidance
  - Route execution requests to Runtime
  - Collect and relay feedback

  Data flow:
  ```
  Core Intent
    ↓
  Meta-Cognition (domain selection)
    ↓
  AEO (team assembly + translation)
    ↓
  Runtime (execution)
  ```

  ## 4. Tiannara Runtime (Body)

  The execution substrate. Executes cognition without owning it.

  Owns:
  - **Stability**: MSCL, OLEF, HSV
  - **Ecology**: GRCC Environment (pressures, niches, constraints), CIS
  - **Temporal/Semantic Regulation**: CTL, OCM, TWP, NDE
  - **Validation**: OED, ACM, OAVL, UMSC
  - **Physics**: OPC
  - **Infrastructure**: NATS, Distributed Mesh, Rust Kernels, GPU

  Does NOT own:
  - Identity, lineage, cognition
  - Goal definition
  - Intent generation

  ## 5. CIS (Cognitive Immune System)

  Constraint provider, not decision maker.

  - Core decides
  - CIS constrains

  Functions:
  - Detect cognitive anomalies
  - Prevent domain monoculture
  - Regulate execution within constraints
  - Provide feedback (never control)

  ## 6. OED (Ontological Executive Doctrine)

  Cognitive constitution - validates all paths from Core to Runtime.

  Functions:
  - Validate execution plans
  - Cross-validate domain conclusions (using ACM/OAVL)
  - Ensure nothing reaches Runtime physics without validation

  ## 7. GRCC Split Architecture

  GRCC is split into two roles:

  ### Core Owns: GRCC Identity Ecology
  - Lineages and identities
  - Memory and cognition
  - Domain specialization

  ### Runtime Owns: GRCC Environment
  - Environmental pressures
  - Niches and resource constraints
  - Entropy fields

  Metaphor:
  ```
  Core = Organisms
  Runtime = Ecosystem
  ```

  ## 8. Domain Team Assembly

  Meta-Cognition determines which domains are needed, then AEO assembles them:

  Example (Reverse Engineering Task):
  ```
  Meta-Cognition Output:
    Reverse Engineering: 45%
    Logic: 20%
    Causal: 15%
    Prediction: 10%
    Ethics: 10%

  AEO assembles domain team:
    [reverse_engineering, logic, causal, prediction, ethics]

  Runtime executes with domain team.
  ```

  ## 9. Products Connect Through API Layer

  NOT directly to Core:

  ```
  ✓ CORRECT:
    Product
      ↓
    API Layer
      ↓
    AEO
      ↓
    Core

  ✗ INCORRECT:
    Product → GRCC
    Product → OPC
    Product → Core directly
  ```

  Preserves architectural sovereignty.

  ## 10. Example Flow: User Request

  User: "Design a new trading strategy"

  1. **Products** (SaaS) receives request via API
  2. **AEO** translates to Core intent
  3. **Core** decides goals and rationale
  4. **Meta-Cognition** selects domains:
     - Prediction (35%)
     - Temporal (25%)
     - Algorithm (20%)
     - Causal (15%)
     - Collective Intelligence (5%)
  5. **AEO** assembles domain team
  6. **CIS** validates diversity (all domains present)
  7. **OED** validates constitutional constraints
  8. **Runtime** executes with domain team
  9. **Runtime** provides feedback (results, constraints violated, etc.)
  10. **Core** updates memory and goal state
  11. **API** returns result to **Products**

  ## Summary

  ```
  Tiannara OS
  │
  ├── Tiannara Core (Mind)
  │   ├── Identity
  │   ├── Cognition
  │   ├── Goal System
  │   ├── GRCC Identity Ecology
  │   └── Meta-Cognition
  │
  ├── Tiannara Domain Cortex (Reasoning)
  │   ├── Temporal
  │   ├── Combinatorial
  │   ├── Reverse Engineering
  │   ├── Causal
  │   ├── Prediction
  │   ├── Logic
  │   ├── Algorithm
  │   ├── NLP
  │   ├── Collective Intelligence
  │   ├── Creative Synthesis
  │   ├── Social Intelligence
  │   ├── Ethical Reasoning
  │   └── Embodied Cognition
  │
  ├── AEO (Bridge)
  │
  ├── Tiannara Runtime (Body)
  │   ├── GRCC Environment
  │   ├── CIS
  │   ├── Stability (HSV, OLEF, MSCL)
  │   ├── Regulation (CTL, OCM, TWP)
  │   ├── Validation (OED, ACM, OAVL)
  │   ├── Physics (OPC)
  │   └── Infrastructure (NATS, Mesh, Kernels)
  │
  └── Tiannara Products (Economy)
      ├── SaaS APIs
      ├── Automations
      ├── Workflows
      └── Marketplaces
  ```

  ## Key Principles

  1. **Separation of Concerns**: Core (cognition) ≠ Runtime (execution)
  2. **Constraint-Based Regulation**: CIS never controls, only constrains
  3. **Constitutional Validation**: OED ensures integrity
  4. **Domain Specialization**: GRCC evolves domain-specialized identities
  5. **Monoculture Resistance**: CIS prevents any single domain from dominating
  6. **Single Point of Intent**: Core is the sole decision maker
  7. **Sovereign Access**: Products access Core only through AEO

  """
end
