# Task Checklist: Phase 11.21 to 11.25 (TiannaraOS Grounding)

## Phase 11.21 — Civilization Kernel & World Manager (Current Sprint)

- `[x]` **Canonical State & Global Governance**
  - `[x]` Define the canonical state struct `TiannaraOS.State` in [state.ex](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/state.ex).
  - `[x]` Implement [civilization_kernel.ex](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/civilization_kernel.ex) to own the constitution, L0 invariants, ceilings, and isolation.
  - `[x]` Implement [world_manager.ex](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/world_manager.ex) to dynamically instantiate and tick worlds from templates.
  - `[x]` Restructure the folder boundaries for the Core (Think), Runtime (Act), and Product (Communicate) engines.
  - `[x]` Modify [application.ex](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/application.ex) to boot the new OS coordinator- `[/]` **Phase C: Mutation + Synthesis Engine**
  - `[ ]` Implement 4 mutation types (Improvement, Specialization, Synthesis, Paradigm Shift)
  - `[ ]` Integrate Discovery Dependency Validation (Discoveries must chain to create regional tech trees)
  - `[ ]` Implement Capability Selection Layer (decay `fitness`/`selection_score`, prune extinct capabilities)
- `[ ]` **Phase D: Promotion Engine**
  - `[ ]` Implement bottom-up promotion criteria (fitness, survival, usage, replication)
- `[ ]` **Phase E: World Capability Graphs**
  - `[ ]` Formalize World-level `capabilities` graph structures for ecological specialization
- `[ ]` **Phase F: Civilization Capability Graph**
  - `[ ]` Add global `capabilities` graph to `%TiannaraOS.State{}` for permanent technological memory
- `[ ]` **Metrics**
  - `[ ]` Implement `Technological Depth` metric (max graph depth)
  - `[ ]` Update `report_progress` to display infinite tech tree metricsnceNode` struct in [evidence_node.ex](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/evidence_node.ex).
  - `[x]` Update `TiannaraOS.State` in [state.ex](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/state.ex) to enforce typed `evidence_graph` mapping.
  - `[x]` Implement `TiannaraOS.EvidenceEngine` in [evidence_engine.ex](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/evidence_engine.ex) with graph structure, degradation limits, replication count, and PubSub event emission.
  - `[x]` Create and execute the integration test suite in [state_jtms_test.exs](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/test/tiannara/os/state_jtms_test.exs).

## Phase 11.23 — Split Tool Ecology

- `[ ]` **Tool Genome & Execution Division**
  - `[ ]` Implement the [tool_genome_engine.ex](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/tool_genome_engine.ex) to evolve and test specifications.
  - `[ ]` Implement the [tool_runtime.ex](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/tool_runtime.ex) to deploy, monitor, and rollback sandboxed Docker APIs.
  - `[ ]` Integrate `autonomous-api` as a native GenServer client.

## Phase 11.24 — Repository Digital Twin

- `[ ]` **Git Code-Twin Environment**
  - `[ ]` Implement the [repository_twin.ex](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/repository_twin.ex) validation boundary.

## Phase 11.25 — Mock Data Removal

- `[ ]` **Zero Mocks Enforcement**
  - `[ ]` Strip mock data generation. Connect all ticks directly to sandboxed runs, git outcomes, and telemetry.
