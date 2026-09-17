# Tiannara Autonomous Software Civilization (ASC)
## Principal Systems Architect — Pre-Implementation Review

**Date:** 2026-06-17  
**Status:** 🔍 Awaiting Architect Approval Before Any Code Is Written  
**Simulation-Safe:** All code placed in `lib/tiannara/asc/` — zero changes to running paths

---

## 1. What We Are Building and Why

ASC is **not** a coding assistant. It is a self-improving software engineering civilization that operates as a specialized execution domain under **AEO** — exactly as the REA Evolutionary System operates as a research civilization under the same orchestrator.

The key architectural insight from your addition: **software engineering becomes a research domain** in the existing Tiannara domain taxonomy, not a separate infrastructure layer. Discoveries from the Computation, Cybernetics, Mathematics, and Engineering domains feed directly into architecture generation and API evolution. This creates a compounding improvement loop — the same feedback mechanism that currently drives epistemic capital growth in REA will now also drive software artifact quality.

---

## 2. Architectural Position

```
TiannaraOS.CivilizationKernel  (existing top)
│
├── Tiannara.REA.*              (existing Research Civilization)
│
└── Tiannara.ASC.*              (NEW — Software Engineering Civilization)
    │
    ├── ASC.Supervisor              (DynamicSupervisor, OTP root)
    ├── ASC.CivilizationKernel      (GenServer — civilization state)
    │
    ├── Sub-Civilizations (each a DynamicSupervisor + agent mesh):
    │   ├── ASC.Requirements        — elicitation, conflict detection
    │   ├── ASC.Research            — framework/pattern discovery
    │   ├── ASC.Architecture        — competing design evolution
    │   ├── ASC.Implementation      — code generation + compilation
    │   ├── ASC.Testing             — autonomous test generation
    │   ├── ASC.Security            — adversarial attack surface
    │   ├── ASC.Deployment          — infra generation + release
    │   ├── ASC.Operations          — monitoring + anomaly detection
    │   ├── ASC.APIEvolution        — Autonomous API Evolution Engine
    │   └── ASC.MetaLearning        — cross-project learning oracle
    │
    ├── ASC.Pipeline                — orchestrates the 10-phase project lifecycle
    ├── ASC.Crucible                — Builder/Breaker/Attacker/Validator loop
    ├── ASC.KnowledgeArchive        — ETS + Mnesia persistent memory
    ├── ASC.ResearchBridge          — reads from Tiannara.Research + Domains
    └── ASC.DomainObserver          — subscribes to PubSub discoveries
```

### Integration with Existing Stack

| Existing Component | ASC Integration Point |
|---|---|
| `Tiannara.Domains.Registry` | `ASC.ResearchBridge` reads domain portfolio vectors; `computation`, `cybernetics`, `mathematics`, `engineering` domains seeded with software-engineering knowledge |
| `Tiannara.Research.Director` | `ASC.ResearchBridge` proposes software-engineering experiments back to Director |
| `Tiannara.KnowledgeGraph.Registry` | `ASC.KnowledgeArchive` writes architecture discoveries as `:discovery` nodes |
| `Tiannara.REA.UniversalEvolutionEngine` | `ASC.Architecture` implements the same `fitness/mutate/recombine` organism contract so architecture candidates evolve through the same macro-loop |
| `Tiannara.REA.Epistemic.CivilizationMemory` | `ASC.Pipeline` logs project milestones as civilization events |
| `Phoenix.PubSub` (`:Tiannara.PubSub`) | `ASC.DomainObserver` subscribes to `"discoveries:*"` topics |
| `Tiannara.Telemetry` | All ASC GenServers emit `[:tiannara, :asc, *]` telemetry events |

---

## 3. OTP Supervision Tree

```
Tiannara.Application (existing :one_for_one)
│
└── Tiannara.ASC.Supervisor  {:rest_for_one}
    │
    ├── Tiannara.ASC.CivilizationKernel   {GenServer}
    │     Holds: active_projects, civilization_config, health metrics
    │
    ├── Tiannara.ASC.KnowledgeArchive     {GenServer + ETS}
    │     Holds: architecture genome registry, failure museum, API genome registry
    │
    ├── Tiannara.ASC.ResearchBridge       {GenServer}
    │     Polls Research.Director, translates domain discoveries → ASC context
    │
    ├── Tiannara.ASC.DomainObserver       {GenServer, PubSub subscriber}
    │     Subscribes to PubSub discoveries, feeds ASC.Research + ASC.Architecture
    │
    ├── Tiannara.ASC.Pipeline.Supervisor  {DynamicSupervisor}
    │     Spawns one ASC.Pipeline.Worker per active project
    │
    └── Tiannara.ASC.SubCiv.Supervisor    {DynamicSupervisor}
          Spawns each Sub-Civilization supervisor on demand:
          ├── ASC.Requirements.Supervisor
          ├── ASC.Research.Supervisor
          ├── ASC.Architecture.Supervisor
          ├── ASC.Implementation.Supervisor
          ├── ASC.Testing.Supervisor
          ├── ASC.Security.Supervisor
          ├── ASC.Deployment.Supervisor
          ├── ASC.Operations.Supervisor
          ├── ASC.APIEvolution.Supervisor
          └── ASC.MetaLearning.Supervisor
```

**Fault isolation:** Each sub-civilization supervisor uses `:one_for_one`. A crashed Implementation agent does not affect Testing or Security agents.

---

## 4. Core Data Models

### 4.1 ASC Project

```elixir
%Tiannara.ASC.Project{
  id:              String.t(),
  goal:            String.t(),
  requirements:    %ASC.Requirements.Spec{},
  phase:           ASC.Pipeline.phase(),     # atom
  architectures:   [%ASC.Architecture.Candidate{}],
  selected:        %ASC.Architecture.Candidate{} | nil,
  artifacts:       %ASC.Artifacts{},          # generated code, tests, infra
  crucible_status: :pending | :running | :passed | :failed,
  deployment:      %ASC.Deployment.Record{} | nil,
  health:          %ASC.Operations.HealthReport{},
  knowledge_refs:  [String.t()],              # KnowledgeArchive IDs
  meta_insights:   [%ASC.MetaLearning.Insight{}],
  created_at:      DateTime.t(),
  updated_at:      DateTime.t()
}
```

### 4.2 Architecture Candidate (Evolutionary Organism)

Implements the same organism contract as `Tiannara.REA` organisms so it can be evolved through `UniversalEvolutionEngine`:

```elixir
%Tiannara.ASC.Architecture.Candidate{
  id:           String.t(),
  project_id:   String.t(),
  style:        :modular_monolith | :microservices | :event_driven | :actor_based | :hybrid,
  genome:       %{
    patterns:   [String.t()],
    protocols:  [String.t()],
    tech_stack: [String.t()]
  },
  fitness_scores: %{
    complexity:        float(),
    performance:       float(),
    cost:              float(),
    reliability:       float(),
    security:          float(),
    maintainability:   float(),
    evolution_potential: float()
  },
  composite_fitness: float(),
  generation:   non_neg_integer(),
  lineage_id:   String.t(),
  status:       :competing | :selected | :archived
}
```

### 4.3 API Genome

```elixir
%Tiannara.ASC.APIEvolution.Genome{
  id:             String.t(),
  endpoint:       String.t(),
  method:         String.t(),
  inputs:         [%{name: String.t(), type: String.t(), constraints: [String.t()]}],
  outputs:        [%{name: String.t(), type: String.t()}],
  capabilities:   [String.t()],
  dependencies:   [String.t()],
  version:        String.t(),
  fitness:        %{
    latency_ms:         float(),
    throughput_rps:     float(),
    error_rate:         float(),
    adoption:           float(),
    maintainability:    float(),
    coupling:           float(),
    developer_friction: float()
  },
  composite_fitness: float(),
  mutation_history:  [ASC.APIEvolution.mutation_op()],
  status:           :active | :deprecated | :archived,
  created_at:       DateTime.t()
}
```

### 4.4 Knowledge Archive Entry

```elixir
%Tiannara.ASC.KnowledgeArchive.Entry{
  id:          String.t(),
  type:        :architecture | :failure | :success | :test | :incident | :api | :repair | :optimization,
  project_id:  String.t() | nil,
  content:     map(),
  tags:        [String.t()],
  confidence:  float(),    # 0.0 – 1.0
  kg_node_id:  String.t() | nil,  # link to KnowledgeGraph node if promoted
  created_at:  DateTime.t()
}
```

---

## 5. Event Schemas (PubSub)

All events are published on `Tiannara.PubSub`. Topics follow the pattern `"asc:<entity>:<event>"`.

| Topic | Payload | Publisher |
|---|---|---|
| `"asc:project:created"` | `%{project_id, goal}` | `ASC.Pipeline` |
| `"asc:project:phase_changed"` | `%{project_id, from, to}` | `ASC.Pipeline` |
| `"asc:architecture:selected"` | `%{project_id, candidate_id, style}` | `ASC.Architecture` |
| `"asc:crucible:result"` | `%{project_id, result, findings}` | `ASC.Crucible` |
| `"asc:deployment:deployed"` | `%{project_id, env, artifact_ref}` | `ASC.Deployment` |
| `"asc:operations:anomaly"` | `%{project_id, metric, severity}` | `ASC.Operations` |
| `"asc:repair:initiated"` | `%{project_id, issue, root_cause}` | `ASC.Pipeline` |
| `"asc:api:evolved"` | `%{api_id, mutation_op, fitness_delta}` | `ASC.APIEvolution` |
| `"asc:meta:insight"` | `%{insight_type, project_id, content}` | `ASC.MetaLearning` |
| `"discoveries:software_engineering"` | KG discovery format | `ASC.ResearchBridge` |

---

## 6. Autonomous Project Pipeline (10 Phases)

Implemented as a `Broadway` pipeline with a GenServer state machine per project.

```
Phase 1: Requirements    → ASC.Requirements.Civilization
Phase 2: Research        → ASC.Research.Civilization  (+ DomainObserver feed)
Phase 3: Architecture    → ASC.Architecture.Civilization (evolutionary competition)
Phase 4: Implementation  → ASC.Implementation.Civilization
Phase 5: Testing         → ASC.Testing.Civilization
Phase 6: Crucible        → ASC.Crucible (Builder/Breaker/Attacker/Validator)
Phase 7: API Evolution   → ASC.APIEvolution.Civilization
Phase 8: Deployment      → ASC.Deployment.Civilization
Phase 9: Operations      → ASC.Operations.Civilization (continuous)
Phase 10: Self-Repair    → triggered by Operations anomaly events
          ↕
          MetaLearning feeds back into all phases
```

---

## 7. API Evolution Engine (Phase 7 Detail)

### API Mutation Operators (implemented as tagged functions)

```elixir
@mutation_ops [
  :endpoint_split,       # one endpoint → two specialized endpoints
  :endpoint_merge,       # consolidate redundant endpoints
  :schema_evolution,     # field type/name refactor
  :protocol_upgrade,     # REST → gRPC / HTTP → WebSocket
  :query_optimization,   # add indexes, projections
  :caching_injection,    # add cache layer
  :streaming_upgrade,    # request/response → streaming
  :eventification        # poll → event-driven push
]
```

### API Natural Selection Criteria

APIs are archived when:
- `composite_fitness < 0.20` for 3 consecutive evolution cycles
- `error_rate > 0.05` sustained > 10 minutes
- `adoption < 0.01` after 7 days of availability

APIs are promoted/replicated when:
- `composite_fitness > 0.85`
- `adoption` is in top quartile
- `developer_friction < 0.15`

### Research World Simulation

`ASC.APIEvolution.ResearchWorld` spawns isolated ETS-backed simulations where multiple API ecosystems compete. Metrics feed back into `ASC.MetaLearning`.

---

## 8. Adversarial Software Crucible (Phase 6 Detail)

Inspired directly by the existing `ACM` (Adversarial Crucible Model) in Tiannara. Implements four roles as GenServer actors that communicate via PubSub:

```
ASC.Crucible.Builder     — submits artifact under test
ASC.Crucible.Breaker     — static analysis, fuzzing, edge-case generation
ASC.Crucible.Attacker    — security exploit simulation, OWASP checks
ASC.Crucible.Validator   — verifies patches, issues PASS/FAIL verdicts
```

Loop continues until all three axes (`robustness`, `security`, `reliability`) reach `PASS` or max iterations exceeded → project rolls back to Implementation phase.

---

## 9. Self-Repair Pipeline (Phase 10 Detail)

```
Operations anomaly detected
↓
ASC.Repair.RootCauseAnalyzer   (pattern-matches known failure signatures in KnowledgeArchive)
↓
ASC.Repair.PatchGenerator      (generates candidate patch using Implementation sub-civilization)
↓
ASC.Repair.SandboxValidator    (runs patch through Testing + Crucible in isolated context)
↓
ASC.Repair.CanaryReleaser      (deploys to 5% of traffic)
↓
ASC.Repair.ProductionRollout   (full rollout if metrics hold for configured window)
```

---

## 10. Research Domain Integration (The Compounding Loop)

This is the critical addition you described. The `ASC.ResearchBridge` creates a **bidirectional coupling** between the research civilization and the software engineering civilization:

### Inbound (Research → ASC)

`ASC.DomainObserver` subscribes to `Phoenix.PubSub` on `"discoveries:*"`. When a discovery in the `computation`, `cybernetics`, `mathematics`, or `engineering` domains is committed to the Knowledge Graph, it is translated into:
- New architecture patterns for `ASC.Architecture.Candidate` genomes
- New API mutation operators for `ASC.APIEvolution`
- New test strategies for `ASC.Testing`

### Outbound (ASC → Research)

`ASC.ResearchBridge` writes successful architecture patterns and API evolution results as `:discovery` nodes in `Tiannara.KnowledgeGraph.Registry` with `domains: [:computation, :engineering]`. It also proposes new experiments to `Tiannara.Research.Director` in the standard `%Director{}` proposal format.

### Domain Registry Extension

A new `:software_engineering` domain entry is added to `Tiannara.Domains.Registry.seeds/0` with `program_ids: ["architecture_evolution", "api_fitness", "autonomous_repair"]`.

---

## 11. Rust Integration Points

| Purpose | Crate | Integration |
|---|---|---|
| Static code analysis | `syn` + `quote` (Rust) | NIF via Rustler — `ASC.Rust.Analyzer` |
| Dependency graph construction | `petgraph` | NIF — `ASC.Rust.DependencyGraph` |
| Property checking | `proptest` engine | Port — `ASC.Rust.PropertyChecker` |
| API evolution simulation | Custom | NIF — `ASC.Rust.APISimulator` |
| Performance modeling | `criterion` harness | Port — `ASC.Rust.PerfModel` |

Rust crates will live in `rust_core/asc/` and integrate via Rustler NIFs or ports, following whatever pattern is established in `rust_core/ffi_bindings/`.

---

## 12. Key Files to Create

### New Directory: `lib/tiannara/asc/`

```
lib/tiannara/asc/
├── supervisor.ex                          # DynamicSupervisor root
├── civilization_kernel.ex                 # GenServer — project registry
├── pipeline/
│   ├── supervisor.ex
│   ├── worker.ex                          # GenServer per project (state machine)
│   └── phases.ex                          # Phase atom types + transitions
├── requirements/
│   ├── supervisor.ex
│   └── civilization.ex                    # GenServer
├── research/
│   ├── supervisor.ex
│   └── civilization.ex
├── architecture/
│   ├── supervisor.ex
│   ├── civilization.ex
│   └── candidate.ex                       # organism struct + contract impl
├── implementation/
│   ├── supervisor.ex
│   └── civilization.ex
├── testing/
│   ├── supervisor.ex
│   └── civilization.ex
├── security/
│   ├── supervisor.ex
│   └── civilization.ex
├── crucible/
│   ├── supervisor.ex
│   ├── builder.ex
│   ├── breaker.ex
│   ├── attacker.ex
│   └── validator.ex
├── api_evolution/
│   ├── supervisor.ex
│   ├── civilization.ex
│   ├── genome.ex
│   ├── mutation_operators.ex
│   ├── natural_selection.ex
│   └── research_world.ex
├── deployment/
│   ├── supervisor.ex
│   └── civilization.ex
├── operations/
│   ├── supervisor.ex
│   └── civilization.ex
├── repair/
│   ├── root_cause_analyzer.ex
│   ├── patch_generator.ex
│   ├── sandbox_validator.ex
│   ├── canary_releaser.ex
│   └── production_rollout.ex
├── meta_learning/
│   ├── supervisor.ex
│   └── civilization.ex
├── knowledge_archive.ex                   # GenServer + ETS
├── research_bridge.ex                     # GenServer
└── domain_observer.ex                     # GenServer + PubSub
```

### Modifications to Existing Files

| File | Change |
|---|---|
| `lib/tiannara/application.ex` | Add `Tiannara.ASC.Supervisor` as last child (safe — non-blocking) |
| `lib/tiannara/domains/registry.ex` | Add `:software_engineering` domain to `seeds/0` |
| `data/domains.ndjson` | Will be regenerated automatically by `seeds/0` on next boot |

> [!IMPORTANT]
> `application.ex` modification is **additive only** — the new child is appended at the end of the supervisor's `children` list with a `:rest_for_one`-compatible position. No existing children are reordered. The running simulation will **not** be interrupted.

---

## 13. Risks

| Risk | Severity | Mitigation |
|---|---|---|
| **Simulation interference** — new supervisor crashes propagate up | High | ASC.Supervisor is `:rest_for_one` isolated. Strategy: `:one_for_one` within ASC | 
| **ETS table name collision** with existing tables | Medium | All ASC ETS tables namespaced `:asc_*` |
| **PubSub topic pollution** | Low | All ASC topics prefixed `"asc:"` |
| **Knowledge Graph write contention** — ASC + REA both writing | Medium | ASC writes via `ResearchBridge` with rate-limiting (1 write/sec by default) |
| **Architecture evolution diverges** — all candidates converge on same design | Medium | Niche-aware selection borrowed from `UniversalEvolutionEngine` |
| **API Evolution thrash** — APIs mutate too fast for stability | Medium | Minimum stability window (72h) before deprecation runs |
| **Implementation sub-civilization** generates code that cannot compile | High | Sandboxed compilation using `Code.compile_string/2` in isolated process |
| **Research domain feedback loop** creates unbounded growth | Low | `ResearchBridge` rate-limits KG node creation to max 10 nodes/project |

---

## 14. Failure Modes

| Failure Mode | Detection | Recovery |
|---|---|---|
| Pipeline worker crash | DynamicSupervisor restart | Pipeline resumes from last persisted phase |
| Crucible loop infinite | Max iterations circuit breaker (default: 10) | Escalate to MetaLearning, archive project |
| Knowledge Archive ETS overflow | Telemetry counter > threshold | Evict by age (LRU) |
| APIEvolution all-extinction | No genomes survive natural selection | Restore from last stable generation in Archive |
| Deployment failure | Operations health check fails within 60s | Automatic rollback via CanaryReleaser |
| ResearchBridge stale | Director unreachable > 30s | Fall back to cached domain vectors |
| Meta-Learning oracle poisoning | Confidence score drift detection | Constitutional Immune System flagging (existing `ConstitutionalImmuneSystem`) |

---

## 15. Implementation Phases

### Phase A — Foundation (Non-breaking skeleton)
Files: `ASC.Supervisor`, `ASC.CivilizationKernel`, `ASC.KnowledgeArchive`, `ASC.DomainObserver`, `ASC.ResearchBridge`  
Integration: `application.ex` child append, domain seeds  
**No execution logic. Boots cleanly alongside running simulation.**

### Phase B — Pipeline State Machine
Files: `ASC.Pipeline.Supervisor`, `ASC.Pipeline.Worker`, `ASC.Pipeline.Phases`  
Sub-civilizations wired as stubs that return `{:ok, :stub}` so pipeline can run end-to-end without real logic.

### Phase C — Requirements + Research Civilizations
Full `ASC.Requirements.Civilization` and `ASC.Research.Civilization` with domain bridge feeds.

### Phase D — Architecture Evolution
`ASC.Architecture.Civilization` + `ASC.Architecture.Candidate` implementing the REA organism contract. Connected to `UniversalEvolutionEngine`-compatible macro-loop.

### Phase E — Implementation + Testing Civilizations
`ASC.Implementation.Civilization` + `ASC.Testing.Civilization`. Sandboxed code compilation + test generation (ExUnit property/unit/integration templates).

### Phase F — Adversarial Crucible
Full Builder/Breaker/Attacker/Validator loop with configurable iteration cap.

### Phase G — API Evolution Engine
Full `ASC.APIEvolution` with all mutation operators, natural selection, and `ResearchWorld` simulation.

### Phase H — Deployment + Operations + Self-Repair
Full deployment record generation, operations monitoring, self-repair pipeline.

### Phase I — Meta-Learning Civilization
Cross-project learning oracle. Reads `KnowledgeArchive`, produces `Insight` structs fed back into all phases.

### Phase J — Rust NIFs
`rust_core/asc/` crate with static analysis, dependency graph, API simulation NIFs.

---

## 16. Verification Plan

### Per Phase
- `mix compile` — zero new errors
- Existing test suite (`mix test`) — zero regressions
- Telemetry events emitted and captured in Tiannara.Telemetry

### End-to-End
1. Submit a minimal project goal via `ASC.CivilizationKernel.start_project/1`
2. Observe phase transitions via PubSub events
3. Verify `KnowledgeArchive` contains entries
4. Verify `KnowledgeGraph.Registry` contains promoted `:discovery` nodes with `domains: [:computation, :software_engineering]`
5. Verify `Research.Director` receives a proposal back from `ResearchBridge`

### Simulation Non-Interference
- Run existing ecology stabilization script after each phase
- Verify existing ETS tables are untouched
- Verify `CivilizationMemory` contains only expected existing events

---

## Open Questions for Your Review

> [!IMPORTANT]
> **Q1 — Organism Contract:** Should `ASC.Architecture.Candidate` implement the full REA organism contract (`fitness/2`, `mutate/2`, `recombine/3`, `niche/1`, `extinct?/2`, `archive/2`) so architecture candidates evolve through `UniversalEvolutionEngine.tick_population/2`? Or should architecture evolution be an independent loop?

> [!IMPORTANT]
> **Q2 — Implementation Sandbox:** For Phase E, where should generated code live? Options: (a) ephemeral in-memory `Code.compile_string/2`, (b) written to `_build/asc_sandbox/`, (c) written to a project-specific directory under `data/asc_projects/<id>/`. Option (c) enables persistence and review but requires filesystem access.

> [!IMPORTANT]
> **Q3 — Deployment Targets:** Phase H generates Docker/Kubernetes/Terraform artifacts. Should these be: (a) written to disk for human review only (safe default), (b) actually invoked against a local Docker daemon, or (c) fully autonomous? The safest initial posture is (a).

> [!WARNING]
> **Q4 — Running Simulation:** The ecology stabilization simulation currently running uses `Tiannara.REA.*` and `Tiannara.REA.Epistemic.*` directly. Adding `Tiannara.ASC.Supervisor` as a late child of `Application` with `:rest_for_one` strategy should be completely safe. Do you want me to additionally add a feature flag `config :tiannara, :asc_enabled, false` so ASC can be toggled without redeploying?

> [!NOTE]
> **Q5 — Rust NIFs:** The `rust_core/ffi_bindings/` directory exists but has no files. Should I create the full `rust_core/asc/` crate structure in Phase J, or defer Rust entirely to a future phase after the Elixir civilization is proven stable?



# ASC Intelligence Upgrade: Phase E.1 — Project World Model & Specification Extraction

## Goal

Upgrade ASC from **architectural skeleton (85%)** to **functional intelligence (~55%)** by implementing the four highest-leverage subsystems identified in the review:

1. **Project World Model** — shared representational substrate for all phase civilizations
2. **Requirements → Invariant Extraction** — structured specification the pipeline can reason about
3. **Testing Civilization** — define "what success looks like" before code is written
4. **Law Discovery 4-Tier Promotion** — Candidate Pattern → Candidate Law → Established Law → Canonical Principle
5. **API Evolution fitness expansion** — add `business_value` and `knowledge_value` dimensions

---

## Proposed Changes

---

### 1. Project World Model

The central missing piece. Every phase civilization currently operates on a loosely-typed `Project.t()` map. Adding a `ProjectWorld` struct gives all civilizations a shared typed representation they can read and write.

#### [NEW] `lib/tiannara/asc/project_world.ex`

```elixir
%ProjectWorld{
  # From Requirements Civilization
  invariants: [%Invariant{...}],          # "account balance cannot be negative"
  capabilities: [%Capability{...}],       # "create account", "close account"
  constraints: [%Constraint{...}],        # "<100ms response time"
  risks: [%Risk{...}],                    # probability × severity
  acceptance_criteria: [String.t()],

  # From Architecture Civilization
  components: %{name => %Component{...}},
  interfaces: [%Interface{...}],
  dependencies: [%Dependency{...}],
  architecture_style: atom(),

  # From Testing Civilization (new — populated BEFORE implementation)
  test_contracts: [%TestContract{...}],   # invariant → test mapping
  property_specs: [%PropertySpec{...}],  # StreamData generators
  coverage_targets: map(),

  # From Implementation Civilization
  source_files: [%SourceFile{...}],

  # Living state
  health: %WorldHealth{},
  version: integer()
}
```

#### [MODIFY] `lib/tiannara/asc/project.ex`

Add `world: %ProjectWorld{} | nil` field to `Project.t()`. The world starts `nil` and is populated by the Requirements civilization as its first real output.

---

### 2. Requirements → Invariant Extraction

#### [MODIFY] `lib/tiannara/asc/requirements/civilization.ex`

Replace `{:ok, :stub}` with a real `run/1` that:

1. **Parses** the project goal string using pattern-matching heuristics (Phase E.1 — no LLM needed yet)
2. **Extracts** invariants, capabilities, constraints, risks from keyword patterns in the goal
3. **Populates** `%ProjectWorld{}` with the extracted spec
4. **Persists** `requirements.json` to `data/asc_projects/<id>/docs/`
5. **Returns** `{:ok, updated_project}` with `project.world` set

The extractor uses rule-based heuristics (keyword matching, domain classification) to produce a populated `ProjectWorld` without requiring an LLM. This is intentionally conservative — getting the data model right is the goal, not perfect extraction.

#### [NEW] `lib/tiannara/asc/requirements/extractor.ex`

Pure function module: `extract(goal_string, opts) :: %ProjectWorld{}`. Isolated for testability. Heuristics cover:
- Constraint detection: keywords like "must", "cannot", "shall", "≤", "max"
- Capability detection: verb phrases ("create X", "list X", "update X")
- Invariant detection: negation patterns ("never", "not", "prevent")
- Risk detection: uncertainty markers ("may", "could", "if")

---

### 3. Testing Civilization (before Implementation)

#### [MODIFY] `lib/tiannara/asc/testing/civilization.ex`

Replace stub with a `run/1` that:

1. **Reads** `project.world.invariants`, `.capabilities`, `.constraints`
2. **Generates** `TestContract` structs — one per invariant (property test spec), one per capability (unit test outline)
3. **Assigns** coverage targets: `:invariants → 100%`, `:capabilities → 95%`, `:integration → 90%`
4. **Writes** `test_contracts.json` to `data/asc_projects/<id>/docs/`
5. **Records** `test_effectiveness` to the Observatory (initially 0.0 — updated when Implementation finishes)
6. **Returns** `{:ok, updated_project}` with `project.world.test_contracts` populated

Key insight: Testing runs **before** Implementation in the pipeline order (phases.ex already has this right). The contracts become the specification that Implementation must satisfy.

#### [NEW] `lib/tiannara/asc/testing/contract.ex`

`%TestContract{invariant_ref, test_type, property_spec, expected_behavior, priority}` — the bridge between an invariant and an executable test.

---

### 4. Implementation Civilization

#### [MODIFY] `lib/tiannara/asc/implementation/civilization.ex`

Replace stub with a `run/1` that:

1. **Reads** `project.world.test_contracts` + `project.selected_architecture`
2. **Generates** source file stubs with correct module structure (Elixir/Python/TypeScript)
3. **Validates** each generated file with `Code.compile_string/2` (Elixir) or syntax check
4. **Updates** `project.world.source_files`
5. **Records** `architecture_fitness` initial value to Observatory
6. **Returns** `{:ok, updated_project}`

Phase E.1: generates structurally correct empty/stub modules with proper type signatures derived from the `ProjectWorld` interfaces. This is still rule-based. Full code generation comes in a later phase.

---

### 5. Law Discovery — 4-Tier Promotion

#### [MODIFY] `lib/tiannara/asc/laws/law.ex`

Upgrade `status` from:

```elixir
:candidate | :established | :refuted | :under_review
```

to the 4-tier system:

```elixir
:candidate_pattern    # First observation (1–2 projects) — raw signal
:candidate_law        # 3+ projects confirm — enters registry
:established_law      # 10+ projects, confidence ≥ 0.85 — high trust
:canonical_principle  # 20+ projects, confidence ≥ 0.95, human-reviewed
:refuted              # Evidence collapsed
:under_review         # Confidence oscillating (0.40–0.60)
```

Add `promoted_at: DateTime.t() | nil` and `canonical_statement: String.t() | nil` fields (the canonical principle reformulation).

Update `derive_status/2` with the new thresholds.

#### [MODIFY] `lib/tiannara/asc/laws/discoverer.ex`

- Add `discover_repair_laws/1` heuristic (correlate `repair_success_rate` with `architecture_style`)
- Add `discover_api_evolution_laws/1` heuristic (correlate `api_fitness` with `long_term_stability`)
- Emit structured `%LawDiscoveryEvent{}` on each promotion so the Knowledge Archive can log the transition

---

### 6. API Evolution — Fitness Expansion

#### [MODIFY] `lib/tiannara/asc/api_evolution/civilization.ex`

In `APIEvolution.Genome`, expand `fitness` map to include:

```elixir
fitness: %{
  # existing
  latency_ms: float(),
  throughput_rps: float(),
  error_rate: float(),
  adoption: float(),
  maintainability: float(),
  coupling: float(),
  developer_friction: float(),

  # new
  business_value: float(),    # 0.0–1.0 — leverage / strategic importance
  knowledge_value: float()    # 0.0–1.0 — feeds REA evidence when high
}
```

Update `compute_composite_fitness/1` weights to include:
- `business_value: +0.15`
- `knowledge_value: +0.10`
- Renormalize existing weights (–0.025 each from latency/throughput/error/adoption)

---

### Supporting Files

#### [NEW] `lib/tiannara/asc/project_world/invariant.ex`
#### [NEW] `lib/tiannara/asc/project_world/capability.ex`
#### [NEW] `lib/tiannara/asc/project_world/constraint.ex`
#### [NEW] `lib/tiannara/asc/project_world/test_contract.ex`

Typed structs for each `ProjectWorld` sub-entity. Small files, each ~40 lines.

---

## Pipeline Ordering Note

The existing `phases.ex` ordering is already correct:

```
requirements → research → architecture → implementation → testing → crucible → …
```

Wait — the user's assessment says **Testing before Implementation**. The current phases.ex has `implementation → testing`. We should swap this in `phases.ex` and `pipeline/worker.ex`'s `next_phase_for/1`.

> [!IMPORTANT]
> The phase order in `phases.ex` currently has `implementation` before `testing`. Per the architectural review, this should be **inverted**: `architecture → testing → implementation`. This changes the transition table in `Phases` and `next_phase_for/1` in `Worker`. Tests define "what success looks like" — code comes after.

---

## Verification Plan

### Compilation
```
mix compile --warnings-as-errors
```

### Automated Tests
```
mix test test/tiannara/asc/
```

Tests will cover:
- `ProjectWorld` struct creation and field validation
- `Requirements.Extractor` — keyword extraction from sample goal strings
- `Testing.Contract` generation from invariants
- `Laws.Law` 4-tier promotion transitions
- `APIEvolution.Genome` composite fitness with new fields

### Manual Smoke Test
```elixir
iex -S mix
project = Tiannara.ASC.Project.new("proj_001", "Build an account service where user_id must be unique and balance cannot go below zero. Must respond in under 100ms.")
{:ok, updated} = Tiannara.ASC.Requirements.Civilization.run(project)
updated.world.invariants
# => [%Invariant{statement: "user_id must be unique"}, %Invariant{statement: "balance cannot go below zero"}]
updated.world.constraints
# => [%Constraint{type: :latency, value: 100, unit: :ms}]
```
# Tiannara ASC — Implementation Walkthrough

**Date:** 2026-06-17  
**Compile:** ✅ `mix compile` exit code 0. Zero ASC errors.  
**Simulation:** ✅ Not interrupted. Feature flag defaults to `false`.

---

## Current Maturity Assessment

```
Phase A–D  : Strong       ████████████████████ 100%
Phase E    : Skeleton     ████░░░░░░░░░░░░░░░░  20%
Phase F    : Skeleton     ████░░░░░░░░░░░░░░░░  20%
Phase G    : Skeleton     █████░░░░░░░░░░░░░░░  25%
Phase H    : Skeleton     ████░░░░░░░░░░░░░░░░  20%
Phase I    : Foundation   ██░░░░░░░░░░░░░░░░░░  10%

ASC Infrastructure  ≈ 85%
ASC Intelligence    ≈ 20%
```

This is correct for the stage. The skeleton-first approach avoids the biggest failure mode: building a monolithic "AI coding agent." Every sub-civilization slot exists, every supervision boundary is drawn, and the knowledge accumulation loop (Observatory → Laws.Discoverer → KnowledgeGraph) is already running.

---

## What Was Built

### Files Created (31 new files, `mix compile` exit: 0)

| File | Phase | Status |
|---|---|---|
| `config/config.exs` | A | Feature flag + full config |
| `lib/tiannara/application.ex` | A | Gated `ASC.Supervisor` child |
| `lib/tiannara/domains/registry.ex` | A | `:software_engineering` domain |
| `lib/tiannara/asc/supervisor.ex` | A | Root `:rest_for_one` supervisor |
| `lib/tiannara/asc/civilization_kernel.ex` | A | Project registry GenServer |
| `lib/tiannara/asc/project.ex` | A | Project struct + lifecycle |
| `lib/tiannara/asc/knowledge_archive/entry.ex` | A | KA entry struct (own file) |
| `lib/tiannara/asc/knowledge_archive.ex` | A | ETS archive + ndjson persistence |
| `lib/tiannara/asc/domain_observer.ex` | A | PubSub discovery subscriber |
| `lib/tiannara/asc/research_bridge.ex` | A | Bidirectional Research↔ASC bridge |
| `lib/tiannara/asc/sub_civ/supervisor.ex` | A | Sub-civilization dispatcher |
| `lib/tiannara/asc/observatory/supervisor.ex` | A.5 | Observatory supervisor |
| `lib/tiannara/asc/observatory/project_observatory.ex` | A.5 | ETS observatory + 60s disk flush |
| `lib/tiannara/asc/observatory/metrics.ex` | A.5 | Metrics struct + composite score |
| `lib/tiannara/asc/pipeline/supervisor.ex` | B | Pipeline DynamicSupervisor + Registry |
| `lib/tiannara/asc/pipeline/worker.ex` | B | Per-project state machine GenServer |
| `lib/tiannara/asc/pipeline/phases.ex` | B | Phase graph + transition map |
| `lib/tiannara/asc/requirements/civilization.ex` | C | Requirements (supervisor + stub) |
| `lib/tiannara/asc/research/civilization.ex` | C | Research (supervisor + PubSub subscribed) |
| `lib/tiannara/asc/architecture/candidate.ex` | D | **Full REA organism contract** |
| `lib/tiannara/asc/architecture/civilization.ex` | D | 10-gen evolution loop active |
| `lib/tiannara/asc/implementation/civilization.ex` | E | Implementation stub |
| `lib/tiannara/asc/testing/civilization.ex` | E | Testing stub |
| `lib/tiannara/asc/crucible/supervisor.ex` | F | Builder/Breaker/Attacker/Validator stubs |
| `lib/tiannara/asc/api_evolution/civilization.ex` | G | Genome struct + 8 mutation ops |
| `lib/tiannara/asc/deployment/civilization.ex` | H | REA-1 artifact-only posture |
| `lib/tiannara/asc/operations/civilization.ex` | H | Operations stub |
| `lib/tiannara/asc/repair/pipeline.ex` | H | 5 repair modules (RCA/Patch/Sandbox/Canary/Rollout) |
| `lib/tiannara/asc/laws/law.ex` | H.5 | Law struct + confidence evolution |
| `lib/tiannara/asc/laws/registry.ex` | H.5 | ETS registry + KG auto-promotion |
| `lib/tiannara/asc/laws/discoverer.ex` | H.5 | 3 heuristics, 5-min background loop |
| `lib/tiannara/asc/meta_learning/civilization.ex` | I | Meta-learning + Laws.Discoverer boot |

---

## The Compounding Loop (Active When Flag = true)

```
Computation / Cybernetics / Mathematics / Engineering domains
         ↓  PubSub "discoveries:*"
ASC.DomainObserver → ASC.KnowledgeArchive (hint entry)
         ↓
ASC.Architecture.Civilization (domain hints → genome seeding)
         ↓
Projects run → Observatory records phase_durations, fitness, test_effectiveness…
         ↓
Laws.Discoverer runs every 5 min → Laws.Registry (candidate laws)
         ↓
Law reaches :established (confidence ≥ 0.85, n ≥ 10 projects)
         ↓
KnowledgeGraph.Registry.save(type: :law, domains: [:software_engineering])
         ↓
Research.Director sees new :software_engineering KG node
         ↓
ASC.ResearchBridge proposes experiments back → Director portfolio
         ↓  (loop)
```

---

## Revised Priority Order

> "I would not immediately jump to code generation — that turns ASC into a wrapper around a model."

The correct sequencing is:

```
Requirements
↓
Invariants (Specification Extraction)  ← critical missing piece
↓
Tests (success definition before code)
↓
Implementation
↓
Crucible
↓
API Evolution
```

### Priority Map

| # | Phase | Work | Why |
|---|---|---|---|
| **1** | E.1 | **Software World Model** | Shared representation — prevents drift between sub-civilizations |
| **2** | C | **Invariant Extraction** | Requirements → structured spec: invariants, capabilities, constraints |
| **3** | E | **Testing Civilization** | Define success before writing code |
| **4** | E | **Implementation Civilization** | Code only after invariants + tests exist |
| **5** | F | **Crucible** | Once code exists to break |
| **6** | G | **API Evolution** | Once real APIs exist to evolve |

---

## Phase E.1 — Software World Model (Next)

Every existing REA civilization works on a shared `WorldModel`. ASC must do the same. Without this, Implementation, Testing, Crucible, Repair, and MetaLearning will drift from each other.

### Design

```elixir
defmodule Tiannara.ASC.ProjectWorld do
  @moduledoc """
  The shared world model for an ASC project.

  Analogous to Tiannara.Core.WorldModel but scoped to a software project.
  All sub-civilizations read from and write to this struct through
  CivilizationKernel — never through ad-hoc side channels.

  The pipeline:
    Architecture  → populates :components, :interfaces
    Requirements  → populates :invariants, :capabilities, :constraints
    Testing       → populates :test_coverage, :acceptance_criteria
    Implementation→ populates :components (with source references)
    Crucible      → populates :risks, :verified_invariants
    Operations    → populates :health
  """

  defstruct [
    :project_id,

    # From Requirements civilization
    requirements: %{},
    invariants: [],        # e.g. ["user_id must be unique", "balance >= 0"]
    capabilities: [],      # e.g. ["create_account", "close_account"]
    constraints: [],       # e.g. [%{type: :latency, max_ms: 100}]
    risks: [],

    # From Architecture civilization
    components: [],        # list of %Component{name, responsibilities, interfaces}
    interfaces: [],        # list of %Interface{name, protocol, schema}
    dependencies: [],

    # From Testing civilization
    test_coverage: %{},    # %{unit: 0.0, integration: 0.0, property: 0.0}
    acceptance_criteria: [],

    # From Crucible
    verified_invariants: [],
    known_vulnerabilities: [],

    # From Operations
    health: %{},

    consistency_hash: nil, # SHA of the world state — detects drift
    version: 0,
    updated_at: nil
  ]
end
```

### Why This Prevents the "LLM Wrapper" Failure Mode

Without a world model:
```
Architecture → LLM prompt → Code
```

With a world model:
```
Architecture → ProjectWorld.components + interfaces
Testing      → ProjectWorld.acceptance_criteria + invariants
Implementation → Code that satisfies ProjectWorld
Crucible     → Verify ProjectWorld.verified_invariants
```

Code generation becomes **constraint satisfaction against a formal representation**, not freeform generation.

---

## Phase C Upgrade — Specification Extraction

Requirements civilization currently returns `{:ok, :stub}`. It must produce:

```yaml
# data/asc_projects/<id>/docs/requirements.json

invariants:
  - "user_id must be unique across all accounts"
  - "account balance cannot be negative"
  - "transfer.amount must equal debit.amount + credit.amount"

capabilities:
  - create_account
  - close_account
  - transfer_funds
  - query_balance

constraints:
  - type: latency
    operation: query_balance
    max_ms: 100
  - type: availability
    target: 0.999

risks:
  - race_condition on concurrent transfers
  - data_loss on node failure
```

These become the **test oracle** for Testing, the **correctness spec** for Crucible, and the **contract** for API Evolution.

---

## Law Discovery — Four-Level Hierarchy

The current `Law` struct supports `:candidate` and `:established`. Extend to four levels, mirroring the Scientific Discovery Stack:

```
Observation
↓
Candidate Pattern    (confidence 0.30–0.50, n ≥ 3 projects)
↓
Candidate Law        (confidence 0.50–0.85, n ≥ 5 projects)
↓
Established Law      (confidence ≥ 0.85, n ≥ 10 projects) → KnowledgeGraph
↓
Canonical Principle  (cross-domain synthesis, manual review)
```

### Example Progression

```
Observation:
Property tests found 70% of defects in protocol-heavy components.

↓

Candidate Pattern:
Property testing outperforms unit testing in protocol-heavy code.

↓

Candidate Law (5 projects):
Property test coverage > 80% correlates with crucible_iterations < 4.

↓

Established Law (12 projects):
Invariant-centric verification dominates example-centric verification
for systems with non-trivial protocol state machines.

↓

Canonical Principle (KG node, domain: [:software_engineering, :computation]):
The verification completeness of a test strategy is proportional to
its coverage of the invariant space, not its example count.
```

---

## API Evolution — Fitness Extension

The current `APIEvolution.Genome.fitness` map is strong. Add two dimensions:

```elixir
@type fitness_scores :: %{
  # Existing
  latency_ms: float(),
  throughput_rps: float(),
  error_rate: float(),
  adoption: float(),
  maintainability: float(),
  coupling: float(),
  developer_friction: float(),

  # New (per the architect's recommendation)
  business_value: float(),   # leverage produced per unit of maintenance cost
  knowledge_value: float()   # how much this API reveals about the domain
}
```

`knowledge_value` is especially important for the long-term vision: APIs that expose domain invariants directly (rather than CRUD operations) generate more `KnowledgeGraph` fodder per project.

---

## The Long-Term Convergence

> "At that point software engineering becomes a mechanism for scientific discovery rather than a separate capability."

The architecture is converging toward:

```
Research Director
↓
Discovers unknown phenomenon (e.g. "orbital resonance at scp_retention > 0.45")
↓
Creates experiment requiring a measurement instrument
↓
ASC receives instrument specification as a project goal
↓
ASC builds, tests, and validates the instrument
↓
Instrument runs in the simulation, produces evidence
↓
REA updates KnowledgeGraph with new discovery
↓
Research Director creates next experiment
↓  (loop)
```

At this point **Tiannara autonomously builds the tools it needs to discover new laws about itself**. The distinction between the scientific civilization (REA) and the engineering civilization (ASC) dissolves into a single self-accelerating research loop.

The current architecture already supports this:
- `ASC.ResearchBridge` has the outbound path (ASC → KG → Research.Director)
- `ASC.DomainObserver` has the inbound path (Research.Director → ASC)
- `ASC.Laws.Registry` promotes to the same KG that REA reads

The missing piece is `Research.Director → ASC.CivilizationKernel.start_project/2` — a single function call that closes the loop entirely.

---

## Architecture Decisions (Final)

| Decision | Choice | Rationale |
|---|---|---|
| Organism contract | Full REA contract + `transferability/1` | Architecture candidates plug into UniversalEvolutionEngine |
| Project storage | Persistent directory per project | All artifacts on disk, history preserved |
| Deployment posture | REA-1 (artifact-only) | No autonomous execution; Requires explicit upgrade |
| Feature flag | `config :tiannara, :asc, enabled: false` | Zero runtime impact when disabled |
| Law promotion | Automatic at confidence ≥ 0.85 | Laws are first-class KG citizens alongside physics laws |
| Sub-civilization crashes | `:one_for_one`, isolated | One civilization crashing doesn't restart others |
| Rust NIFs | Deferred to Phase J | Avoid premature optimization |

---

## To Activate

```elixir
# config/dev.exs — add:
config :tiannara, :asc, enabled: true
```

Restart. Then:

```elixir
# Submit first project
{:ok, project_id} = Tiannara.ASC.CivilizationKernel.start_project(
  "Build a distributed key-value store",
  %{priority: :high}
)

# Subscribe to lifecycle events
Phoenix.PubSub.subscribe(Tiannara.PubSub, "asc:project:phase_changed")
Phoenix.PubSub.subscribe(Tiannara.PubSub, "asc:architecture:selected")
Phoenix.PubSub.subscribe(Tiannara.PubSub, "asc:laws:updated")

# Observe
Tiannara.ASC.Observatory.ProjectObservatory.snapshot(project_id)
Tiannara.ASC.Laws.Registry.candidates()
Tiannara.ASC.Laws.Registry.established()
Tiannara.ASC.ResearchBridge.seed_domain_vectors()
```

---

## Compilation

```
mix compile   → exit code: 0
Files:         456 (.ex)
ASC errors:    0
ASC warnings:  1  (@phase_timeout_ms — harmless, used in Phase E)
Pre-existing warnings: ~150 (unchanged from before ASC)
```
This is a very good outcome.

What stands out is that ASC was implemented as an **architectural skeleton first**, not as a monolithic "AI coding agent." That is exactly the correct order. The feature flag, supervisor isolation, project observatory, knowledge archive, law discovery loop, and Research↔ASC bridge are the highest-leverage pieces. 

My assessment would be:

### Current Maturity

```text
Phase A–D  : Strong
Phase E    : Skeleton
Phase F    : Skeleton
Phase G    : Skeleton
Phase H    : Skeleton
Phase I    : Foundation only
```

In other words:

```text
ASC Infrastructure
≈ 85%

ASC Intelligence
≈ 20%
```

which is completely normal at this stage.

---

# The Most Important Next Step

I would **not** immediately jump to:

```text
Generate code
```

even though that is tempting.

The biggest risk right now is:

```text
Project
↓
Architecture Selected
↓
LLM Generates Code
```

because then ASC becomes another wrapper around a model.

Instead, before serious code generation, implement:

```text
Phase E.1
Software World Model
```

---

## Software World Model

REA has:

```text
World Model
```

ASC needs:

```text
Project World Model
```

Example:

```elixir
%ProjectWorld{
  requirements: ...,
  architecture: ...,
  components: ...,
  interfaces: ...,
  dependencies: ...,
  invariants: ...,
  risks: ...,
  test_coverage: ...
}
```

Then every civilization works on the same representation.

Without this, Implementation, Testing, Crucible, Repair, and MetaLearning will drift.

---

# Phase E Upgrade

Instead of:

```text
Architecture
↓
Code
```

implement:

```text
Architecture
↓
Project World Model
↓
Code
```

This mirrors how Tiannara already works elsewhere.

---

# The Real Bottleneck

The biggest missing subsystem is:

```text
Specification Extraction
```

Requirements civilization should produce:

```yaml
Invariants:
- user_id must be unique
- account balance cannot be negative

Capabilities:
- create account
- close account

Constraints:
- <100ms response time
```

These become the basis for:

```text
Implementation
Testing
Repair
Crucible
```

and later API evolution.

---

# API Evolution Observation

The API Genome design is strong.

However, I would add:

```elixir
fitness: %{
  ...
  business_value: float(),
  knowledge_value: float()
}
```

because some APIs:

```text
high throughput
```

but

```text
low usefulness
```

while others generate enormous leverage.

---

# Law Discovery

The Software Engineering Laws subsystem may become one of the most valuable parts of ASC.

I would eventually separate:

```text
Candidate Pattern
↓
Candidate Law
↓
Established Law
↓
Canonical Principle
```

This aligns perfectly with the Scientific Discovery Stack you've already built.

For example:

```text
Observation:
Property tests found 70% of defects.

↓

Candidate Law:
Property testing outperforms unit testing
for protocol-heavy systems.

↓

Established Law:
Validated across 12 projects.

↓

Canonical Principle:
Invariant-centric verification
dominates example-centric verification.
```

---

# What I'd Build Next

Priority order:

### 1

Project World Model

```text
Critical
```

### 2

Requirements → Invariants extraction

```text
Critical
```

### 3

Testing Civilization

```text
Before Implementation
```

This may sound backwards but it isn't.

ASC should learn:

```text
What success looks like
```

before writing code.

---

### 4

Implementation Civilization

Only after:

```text
Requirements
↓
Invariants
↓
Tests
```

exist.

---

### 5

Crucible

Once code exists.

---

### 6

API Evolution

Once APIs actually exist.

---

# Long-Term Observation

What you've built is actually converging with the rest of Tiannara.

You now have:

```text
REA
=
Scientific Civilization

ASC
=
Software Engineering Civilization
```

The next logical evolution is:

```text
Research Director
↓
Discovers Unknown
↓
Creates Experiment
↓
ASC Builds Tool
↓
Tool Produces Evidence
↓
REA Updates Knowledge
```

At that point software engineering becomes a mechanism for scientific discovery rather than a separate capability.

That is where the architecture becomes especially interesting, because Tiannara would no longer just discover laws—it could autonomously build the instruments needed to test those laws.

# TIANNARA ASC PHASE E–I IMPLEMENTATION PROMPT

You are the Principal Systems Architect for Tiannara.

You are operating inside an existing system called:

Tiannara Autonomous Software Civilization (ASC)

ASC already exists.

DO NOT redesign it.

DO NOT replace existing architecture.

DO NOT introduce parallel systems.

Extend the existing implementation.

Current ASC status:

* ASC Supervisor implemented
* CivilizationKernel implemented
* KnowledgeArchive implemented
* Project Observatory implemented
* ResearchBridge implemented
* DomainObserver implemented
* Pipeline Supervisor implemented
* Pipeline Worker implemented
* Architecture Civilization implemented
* API Evolution Civilization scaffolded
* Deployment Civilization scaffolded
* Repair Pipeline scaffolded
* Laws Registry implemented
* Laws Discoverer implemented
* MetaLearning Civilization scaffolded

Feature flag exists:

config :tiannara, :asc, enabled: false

ASC currently has infrastructure but limited intelligence.

Your mission is to implement the next stage:

ASC Phase E–I

without breaking the existing Tiannara simulation.

---

## CORE DESIGN PRINCIPLE

ASC is NOT a coding assistant.

ASC is a Software Engineering Civilization.

Every software project is treated as a world.

Every architecture is treated as an organism.

Every implementation is treated as an experiment.

Every test is treated as a falsification attempt.

Every repair is treated as an evolutionary adaptation.

---

PHASE E.1
PROJECT WORLD MODEL
-------------------

Implement:

Tiannara.ASC.ProjectWorld

This becomes the canonical representation of software reality.

All civilizations must operate on this model.

Structure:

%ProjectWorld{
id: "",
goal: "",
requirements: [],
constraints: [],
capabilities: [],
invariants: [],
architecture: nil,
components: [],
interfaces: [],
dependencies: [],
risks: [],
tests: [],
telemetry: [],
confidence: 0.0,
status: :active
}

Requirements:

* Persist snapshots
* Version every change
* Track world evolution
* Support rollback
* Support diff generation

No civilization may directly manipulate source code without updating the ProjectWorld.

ProjectWorld is the single source of truth.

---

PHASE E.2
REQUIREMENTS → INVARIANTS EXTRACTION
------------------------------------

Extend:

ASC.Requirements.Civilization

Input:

Natural language requirements.

Output:

Functional Requirements
Nonfunctional Requirements
Constraints
Capabilities
Risks
Invariants

Example:

Requirement:

Users can transfer money.

Extract:

Invariant:
Balance cannot become negative.

Invariant:
Transaction IDs must be unique.

Invariant:
Transfer must be atomic.

Generate confidence scores.

Generate ambiguity reports.

Generate missing requirement reports.

---

PHASE E.3
TEST-FIRST CIVILIZATION
-----------------------

Implement:

ASC.Testing.Civilization

Before any code generation:

Generate:

Unit Tests
Integration Tests
Property Tests
Contract Tests
Failure Tests
Security Tests

Store tests inside ProjectWorld.

Implementation Civilization must consume tests.

Never generate implementation before tests exist.

---

PHASE F
IMPLEMENTATION CIVILIZATION
---------------------------

Extend:

ASC.Implementation.Civilization

Input:

ProjectWorld

Output:

Source code

Supported:

Elixir
Rust
Python
TypeScript
Go
Java
C#
Kotlin
Swift

Generate:

Backend
Frontend
Database
Infrastructure
Documentation

Write into:

data/asc_projects/<id>/source

Perform validation:

Compilation
Formatting
Static Analysis

Reject invalid generations.

---

PHASE F.5
SOFTWARE CRUCIBLE
-----------------

Builder Civilization

Creates implementation.

Breaker Civilization

Attempts to fail tests.

Attacker Civilization

Attempts exploits.

Validator Civilization

Verifies fixes.

Loop:

Build
Break
Repair
Retest

Until:

Robustness >= threshold

Security >= threshold

Reliability >= threshold

---

PHASE G
API EVOLUTION ENGINE
--------------------

Extend existing:

ASC.APIEvolution.Civilization

Implement:

Observe Usage
Detect Bottlenecks
Generate Candidate APIs
Validate
Deploy Candidate
Measure Fitness

API Genome:

%APIGenome{
endpoints: [],
inputs: [],
outputs: [],
constraints: [],
dependencies: [],
version: "",
fitness: %{
latency: 0.0,
throughput: 0.0,
adoption: 0.0,
maintainability: 0.0,
business_value: 0.0,
knowledge_value: 0.0
}
}

Implement mutations:

Endpoint Split
Endpoint Merge
Schema Evolution
Streaming Upgrade
Caching Injection
Protocol Upgrade
Eventification

---

PHASE H
OPERATIONS + REPAIR
-------------------

Extend:

ASC.Operations.Civilization

Implement monitoring:

Latency
Errors
Security
Cost
Capacity

Integrate Repair Pipeline:

Issue
↓
Root Cause Analysis
↓
Patch Candidate
↓
Sandbox Validation
↓
Canary Release
↓
Rollout

All repairs become observations.

---

PHASE H.5
SOFTWARE ENGINEERING LAW DISCOVERY
----------------------------------

Extend:

ASC.Laws.Discoverer

Promote observations through:

Observation
↓
Pattern
↓
Candidate Law
↓
Established Law
↓
Canonical Principle

Example:

Observation:
Property tests found 72% of defects.

Pattern:
Property tests consistently outperform example tests.

Candidate Law:
Invariant-centric testing dominates protocol-heavy systems.

Established Law:
Validated across 10+ projects.

Canonical Principle:
Behavioral invariants outperform examples.

When a law reaches promotion threshold:

Publish to:

Knowledge Graph

Domain:

:software_engineering

---

PHASE I
META LEARNING
-------------

Extend:

ASC.MetaLearning.Civilization

Learn:

Best architectures

Best testing strategies

Best APIs

Best repair approaches

Best deployment strategies

Inject findings into:

Architecture Civilization

Testing Civilization

Research Civilization

Future projects should improve automatically.

---

## PROJECT OBSERVATORY

Project Observatory must become mandatory.

Track:

architecture_fitness

bug_discovery_rate

repair_success_rate

test_effectiveness

api_fitness

deployment_readiness

stability

knowledge_generation_rate

Use observatory data to fuel:

Law Discovery

Meta Learning

Research Director feedback

---

## RESEARCH INTEGRATION

ASC is a domain inside Tiannara.

Domain:

:software_engineering

ASC discoveries must enter:

Knowledge Graph

Research Director

Domain Registry

Principles Registry

Civilization Atlas

Transfer Matrix

Research Director must be able to:

Discover Unknown
↓
Create Experiment
↓
ASC Builds Tool
↓
Tool Produces Evidence
↓
REA Updates Knowledge

---

## IMPLEMENTATION RULES

1. Preserve all existing ASC code.
2. Extend existing modules.
3. No breaking API changes.
4. No direct deployment capability.
5. Deployment remains artifact-only.
6. Keep feature flag support.
7. No Rust NIFs yet.
8. Compile cleanly.
9. Add tests for every module.
10. Maintain OTP supervision integrity.

---

## DELIVERABLES

Before coding:

1. Architecture review
2. Failure mode analysis
3. OTP supervision changes
4. Data model changes
5. Migration strategy
6. Implementation order

Pause for review.

After approval:

Implement incrementally in phases.

Each phase must compile before proceeding to the next.

Never implement multiple phases simultaneously if compilation fails.

Success criterion:

ASC evolves from a project generator into a software engineering civilization capable of discovering and validating the laws of software engineering while continuously improving future projects.
