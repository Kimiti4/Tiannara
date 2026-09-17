# Implementation Plan — Phase 12.0: Unified Dependency Resolver (JTMS++)

This plan details the design and implementation of **JTMS++ (Unified Dependency Resolver)**, incorporating the **three final architectural additions**: Split Confidence (Local vs Global), Relation Half-Life, and Cascade Budget Protection, alongside the `knowledge_velocity` metric.

By extending the Evidence Graph with weighted relations, continuous confidence/utility propagation, recovery cascades, and unified entity mappings, cascades will flow across portfolios, worlds, institutions, programs, assets, and theories.

## User Review Required

> [!IMPORTANT]
> - **Configurable Damping**: Epistemic damping per world or globally using configuration values.
> - **Confidence vs Utility**: Entities track confidence (epistemic certainty) and utility (practical usefulness) independently.
> - **Cascade Identifiers**: Cascade tracing utilizes unique `:cascade_id` strings and tracks incrementing `:cascade_depth`.
> - **Epistemic Shock & World Telemetry**: Global dashboard metrics expose shock levels and world health telemetry.
> - **Local vs Global Confidence**: `global_confidence` will be an aggregate of per-world `local_confidence` values.
> - **Relation Half-Life & Cascade Limits**: `half_life_ticks` will decay relation strength over time, and `max_cascade_operations` will pause and queue overly large cascades to prevent CPU death spirals.

## Open Questions

> [!WARNING]
> - Do you have a preferred aggregation function for `global_confidence` from `local_confidence` (e.g., average, maximum, weighted by world epoch)? Currently, an average is assumed.
> - `EvidenceEngine` already has some foundations for relation decay (`decay_relations`), cascade limits (`paused_cascades`), and `knowledge_velocity`. Shall I overwrite them or refine the existing implementations to make them fully connected with the new features?

## Proposed Changes

### State & Struct Modifications

#### [MODIFY] [state.ex](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/state.ex)
- Add `:dependency_history` list: `list(map())` (default `[]`)
- Update typespecs.

#### [MODIFY] [evidence_node.ex](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/evidence_node.ex)
- Extend `:type` list: `:theory`, `:claim`, `:hypothesis`, `:experiment`, `:evidence`, `:replication`, `:discovery`, `:research_program`, `:institution`, `:discovery_asset`, `:world`, `:tool_genome`, `:portfolio`.
- Store edge mappings in `relations: %{atom() => %{direction: atom(), relation: atom(), strength: float(), half_life_ticks: integer() | nil}}` inside the metadata field.
- Add `:confidence` (default `1.0`) and `:utility` (default `1.0`).
- Ensure `local_confidence: %{}` and `global_confidence: float()` are fully formalized.

#### [MODIFY] [discovery.ex](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/discovery.ex)
- Add `:confidence` (default `1.0`) and `:utility` (default `1.0`).
- Add `:local_confidence` and `:global_confidence`.

#### [MODIFY] [discovery_asset.ex](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/discovery_asset.ex)
- Add `:confidence` (default `1.0`) and `:utility` (default `1.0`).

#### [MODIFY] [research_program.ex](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/research_program.ex)
- Add `:risk_score` (default `0.0`)
- Add `:funding_score` (default `1.0`)

---

### Truth Maintenance Engine Upgrade (JTMS++)

#### [MODIFY] [evidence_engine.ex](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/evidence_engine.ex)
- **Relation Half-Life**: Update `add_relation/7` and `decay_relations/2` to ensure exponential relation strength decay is fully integrated into the tick cycle.
- **Cascade Budget Protection**: Ensure `cascade_jtms_delta/4` accurately enforces `state.governance.max_cascade_operations` to pause, store, and resume queues without blocking the system.
- **Local/Global Confidence Splitting**: Modify confidence updates so that discoveries or replications within a specific world update the `local_confidence` for that world. Recompute `global_confidence` organically from local values.
- Standardize relation types: `:supports`, `:refutes`, `:depends_on`, `:funds`, `:owned_by`, `:spawned_by`, `:generated_by`, `:validated_by`, `:replicated_by`, `:runs_in`, `:belongs_to`, `:competes_with`, `:inherits_from`, `:improves`, `:replaces`.
- Add recovery helper:
  - `register_successful_replication(state, replication_id, evidence_id, world_id)` - increases local evidence confidence and propagates a positive delta.
- Implement continuous propagation in `cascade_jtms/3` / `cascade_jtms_delta/4` with damping:
  - Supports configurable damping factor via `state.governance[:damping_factor]` (defaults to `0.9`).
  - Generate a unique `:cascade_id` at the root of a cascade.
  - When a node's confidence/value changes by `delta`:
    - **Damped Hop**: `effective_delta = delta * strength * damping_factor`
    - Log a dependency event mapping into `state.dependency_history`.
  - **Dynamic Entity Synced Handlers**:
    - **Asset -> Program**, **Asset -> Portfolio**, **Program -> Theory**.
- Implement dynamic telemetry API in `get_civilization_metrics(state)`:
  - Expose `knowledge_velocity = validated_discoveries / max(1, simulation_time)`.
  - Expose per-world metrics.

## Verification Plan

### Automated Tests
- Create [dependency_resolver_test.exs](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/test/tiannara/os/dependency_resolver_test.exs):
  - **Local/Global Confidence Test**: Verify that independent world updates modify local confidence without immediately overriding unrelated worlds.
  - **Relation Decay Test**: Verify that half-life configuration correctly degrades support strength over time.
  - **Cascade Budget Test**: Ensure that an artificially massive cascade is successfully paused, queued, and resumed safely.
  - **Propagation Damping & Recovery**: Verify that successful replications propagate positive deltas.
  - **Civilization Metrics**: Assert that civilization telemetry returns accurate `knowledge_velocity` and `epistemic_shock_score`.