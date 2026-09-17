# World API v1.0 — Frozen

**Status:** FROZEN as of Phase 3.5
**Compatibility:** All Phase 4+ components MUST use these interfaces to interact with the world model.
**Deprecation Policy:** 2-phase deprecation (warn in N, remove in N+2).

---

## Tiannara.World.UnifiedWorldModel

| Function | Signature | Notes |
| :--- | :--- | :--- |
| `create_entity/1` | `(spec :: map()) -> {:ok, entity_id} \| {:error, reason}` | Create entity |
| `get_entity/1` | `(entity_id :: String.t()) -> {:ok, entity} \| {:error, reason}` | Retrieve entity |
| `update_entity/2` | `(entity_id, updates :: map()) -> :ok \| {:error, reason}` | Update entity |
| `refute_entity/2` | `(entity_id, reason :: String.t()) -> :ok \| {:error, reason}` | Mark as refuted |
| `create_relationship/1` | `(spec :: map()) -> {:ok, edge} \| {:error, reason}` | Create relationship |
| `get_relationships/2` | `(entity_id, opts :: keyword()) -> {:ok, [map()]} \| {:error, reason}` | Get relationships |

### Entity Spec (required fields)

| Field | Type | Notes |
| :--- | :--- | :--- |
| `id` | `String.t()` | Unique identifier |
| `domain` | `atom()` | One of `CanonicalWorldState.domains/0` |
| `type` | `atom()` | One of `CanonicalWorldState.entity_types_for(domain)` |
| `confidence` | `float()` | 0.0 to 1.0 |
| `uncertainty` | `float()` | 0.0 to 1.0 (must sum with confidence to ~1.0) |
| `provenance` | `map()` | Must contain `:origin`, `:produced_by`, `:produced_at` |

---

## Tiannara.World.WorldQueryEngine

| Function | Signature | Notes |
| :--- | :--- | :--- |
| `find/1` | `(opts :: keyword()) -> {:ok, result} \| {:error, reason}` | Query entities |
| `search/2` | `(query_text, opts) -> {:ok, result} \| {:error, reason}` | Text search |
| `trace/1` | `(entity_id) -> {:ok, lineage} \| {:error, reason}` | Provenance lineage |
| `predict/2` | `(entity_id, change_type) -> {:ok, predictions} \| {:error, reason}` | Downstream effects |
| `explain/1` | `(entity_id) -> {:ok, explanation} \| {:error, reason}` | Why is this true? |
| `blast/1` | `(entity_id) -> {:ok, blast_radius} \| {:error, reason}` | What breaks if removed? |
| `temporal/1` | `(timestamp) -> {:ok, state} \| {:error, reason}` | Historical state |

---

## Tiannara.World.KnowledgeCoordinator

| Function | Signature | Notes |
| :--- | :--- | :--- |
| `ingest_discovery/1` | `(spec :: map()) -> {:ok, entity_id} \| {:error, reason}` | Ingest new discovery |
| `fuse_evidence/3` | `(entity_id, evidence, weight) -> {:ok, new_confidence} \| {:error, reason}` | Bayesian evidence fusion |
| `promote_memory_stage/3` | `(entity_id, target_stage, context) -> {:ok, stage} \| {:error, reason}` | Promote through memory chain |
| `validate_knowledge/2` | `(entity_id, protocol) -> {:ok, workflow_id} \| {:error, reason}` | Trigger validation |

---

## Tiannara.World.ConflictResolutionEngine

| Function | Signature | Notes |
| :--- | :--- | :--- |
| `record_conflict/1` | `(spec :: map()) -> {:ok, conflict_id} \| {:error, reason}` | Record contradiction |
| `resolve_conflict/2` | `(conflict_id, resolution) -> {:ok, record} \| {:error, reason}` | Resolve conflict |
| `active_conflicts/0` | `() -> [map()]` | List unresolved conflicts |

### Resolution Types

| Resolution | Argument | Effect |
| :--- | :--- | :--- |
| `{:experiment_to_resolve, spec}` | Experiment spec | Dispatch new experiment |
| `{:deprecate_lower_confidence, entity_id}` | Entity to deprecate | Mark as refuted, preserve |
| `{:merge_with_uncertainty, spec}` | New entity spec | Merge with widened uncertainty |
| `:request_human_review` | None | Escalate to HumanApprovalQueue |

---

## Tiannara.World.BeliefState

| Function | Signature | Notes |
| :--- | :--- | :--- |
| `new/3` | `(prior, evidence_strength, evidence_quality) -> t()` | Create belief state |
| `update/3` | `(state, new_strength, new_quality) -> t()` | Bayesian update |
| `decay/2` | `(state, days_stale) -> t()` | Temporal decay |
| `promotion_ready?/3` | `(state, min_conf, min_evidence) -> boolean()` | Check promotion threshold |
| `explain/1` | `(state) -> String.t()` | Human-readable explanation |

### Invariants (enforced by property tests)

- `confidence + uncertainty == 1.0` (within float tolerance)
- `evidence_count` monotonically increases with updates
- `revision_history` records every update
- `decay/2` never produces negative confidence

---

## Tiannara.World.VersionManager

| Function | Signature | Notes |
| :--- | :--- | :--- |
| `create_version/1` | `(spec :: map()) -> {:ok, version} \| {:error, reason}` | Create version |
| `get_version/2` | `(entity_id, version_number) -> {:ok, version} \| {:error, reason}` | Retrieve version |
| `version_history/1` | `(entity_id) -> {:ok, [version]}` | Full history |
| `compare_versions/3` | `(entity_id, v_a, v_b) -> {:ok, diff} \| {:error, reason}` | Structured diff |
| `rollback/3` | `(entity_id, target_version, reason) -> {:ok, version} \| {:error, reason}` | Restore previous state |
| `tag_version/4` | `(entity_id, version_number, tag_name, metadata) -> :ok` | Named tag |
