# Tiannara Lifecycle API Specification

**Version**: 1.0  
**Status**: FROZEN (Phase 11.5)  
**Module**: `Tiannara.LifecycleRegistry`

---

## Overview

The Lifecycle Registry provides a canonical event-sourced evolutionary ledger for all entities in Tiannara ASC. It separates **events** (what happened) from **entities** (what exists), enabling precise accounting of evolutionary dynamics.

---

## Type Definitions

```elixir
@type entity_type ::
        :capability
      | :theory
      | :ontology
      | :civilization
      | :observer
      | :policy
      | :hypothesis
      | :physics_candidate

@type entity_id :: term()

@type tick :: non_neg_integer()

@type event_type ::
        :created
      | :rediscovered
      | :removed
      | :promoted
      | :selected
      | :merged
      | :rolled_back
      | :quarantined
      | :specialized
      | :synthesized

@type removal_reason ::
        :selection              # Failed fitness criteria
      | :replacement            # Superseded by newer version
      | :merge                  # Merged into another entity
      | :promotion              # Promoted to higher tier
      | :rollback               # Rolled back due to error
      | :quarantine             # Quarantined for investigation
      | :contradiction          # Found contradictory
      | :invalidated            # Invalidated by evidence

@type lifecycle_metadata :: %{
  optional(:world_id) => term(),
  optional(:program_id) => term(),
  optional(:parent_id) => term(),
  optional(:discovery_id) => term(),
  optional(:source) => atom(),
  optional(:generation) => non_neg_integer(),
  optional(:lineage) => [term()],
  optional(:version) => non_neg_integer(),
  optional(:extinction_risk) => float(),
  optional(:fitness) => float(),
  optional(:depth) => non_neg_integer(),
  any() => any()
}
```

---

## Public API

### Entity Creation

```elixir
@spec record_created(
  entity_type :: entity_type(),
  entity_id :: entity_id(),
  tick :: tick(),
  metadata :: lifecycle_metadata()
) :: :ok | {:error, :already_exists}
```

**Purpose**: Record novel entity invention.

**Behavior**:
- Checks if entity already exists in state
- If new: Inserts into `:lifecycle_state`, emits `:created` event, increments created counter
- If exists: Emits `:rediscovered` event instead, returns `{:error, :already_exists}`

**Event Emitted**:
```elixir
{
  entity_type,
  entity_id,
  event_id,
  :created,
  tick,
  nil,  # removed_tick
  metadata
}
```

**Example**:
```elixir
LifecycleRegistry.record_created(:capability, "mathematics", 100, %{
  world_id: "world_1",
  program_id: "prog_42",
  parent_id: "arithmetic",
  discovery_id: "disc_99",
  generation: 5,
  lineage: ["root", "arithmetic", "mathematics"]
})
```

---

### Entity Rediscovery

```elixir
@spec record_rediscovered(
  entity_type :: entity_type(),
  entity_id :: entity_id(),
  tick :: tick(),
  metadata :: lifecycle_metadata()
) :: :ok
```

**Purpose**: Record re-discovery of existing entity (typically called internally by `record_created/4`).

**Behavior**:
- Emits `:rediscovered` event
- Increments rediscovered counter
- Updates entity version and `last_rediscovered_tick`

**Event Emitted**:
```elixir
{
  entity_type,
  entity_id,
  event_id,
  :rediscovered,
  tick,
  nil,
  Map.put(metadata, :original_creation_tick, original_tick)
}
```

**Note**: Usually not called directly. Use `record_created/4` which auto-detects rediscoveries.

---

### Entity Removal

```elixir
@spec record_removed(
  entity_type :: entity_type(),
  entity_id :: entity_id(),
  tick :: tick(),
  reason :: removal_reason(),
  metadata :: lifecycle_metadata()
) :: :ok
```

**Purpose**: Record entity removal from graph with classified reason.

**Behavior**:
- Marks entity as removed in `:lifecycle_state`
- Sets `removed_tick` and `removal_reason`
- Emits `:removed` event
- Increments removed counter

**Event Emitted**:
```elixir
{
  entity_type,
  entity_id,
  event_id,
  :removed,
  tick,
  tick,  # removed_tick
  Map.merge(metadata, %{removal_reason: reason})
}
```

**Example**:
```elixir
LifecycleRegistry.record_removed(:capability, "obsolete_tech", 5000, :selection, %{
  extinction_risk: 0.95,
  fitness: 0.02
})
```

---

### Entity Promotion

```elixir
@spec record_promoted(
  entity_type :: entity_type(),
  entity_id :: entity_id(),
  tick :: tick(),
  promoted_to :: entity_type(),
  metadata :: lifecycle_metadata()
) :: :ok
```

**Purpose**: Record entity promotion to higher tier (e.g., capability → theory).

**Behavior**:
- Marks original entity as removed with reason `:promotion`
- Creates new entity in promoted tier
- Emits both `:removed` and `:created` events
- Increments promoted counter

**Events Emitted**: Two events (removal + creation)

**Example**:
```elixir
LifecycleRegistry.record_promoted(:capability, "advanced_math", 8000, :theory, %{
  theory_name: "number_theory"
})
```

---

### Entity Mutation/Update

```elixir
@spec record_mutated(
  entity_type :: entity_type(),
  entity_id :: entity_id(),
  tick :: tick(),
  mutation_type :: atom(),
  metadata :: lifecycle_metadata()
) :: :ok
```

**Purpose**: Record entity version update without removal.

**Behavior**:
- Updates entity version in `:lifecycle_state`
- Emits `:mutated` event
- Does NOT affect active count

**Event Emitted**:
```elixir
{
  entity_type,
  entity_id,
  event_id,
  :mutated,
  tick,
  nil,
  Map.merge(metadata, %{mutation_type: mutation_type})
}
```

**Example**:
```elixir
LifecycleRegistry.record_mutated(:capability, "mathematics", 3000, :parameter_update, %{
  old_params: %{x: 1},
  new_params: %{x: 2}
})
```

---

### Invariant Verification

```elixir
@spec verify!(
  entity_type :: entity_type(),
  graph_size_fn :: (-> MapSet.t() | non_neg_integer())
) :: :ok | no_return()
```

**Purpose**: Verify entity conservation law holds.

**Invariant**:
```
UniqueCreated - Removed = ActiveUnique
```

**Behavior**:
- Queries `:lifecycle_stats` for created/removed counts
- Calls `graph_size_fn()` to get current graph size
- Compares expected vs actual active entities
- Raises `LifecycleInvariantError` on mismatch

**Parameters**:
- `entity_type`: Which entity type to verify
- `graph_size_fn`: Function returning either:
  - `MapSet.t()` of active entity IDs, OR
  - Integer count of active entities

**Example**:
```elixir
# Pass MapSet (preferred - enables detailed reconciliation)
LifecycleRegistry.verify!(:capability, fn ->
  programs
  |> Enum.flat_map(fn prog -> Map.keys(prog.capabilities) end)
  |> MapSet.new()
end)

# Or pass integer count
LifecycleRegistry.verify!(:capability, fn ->
  graph_size()
end)
```

**Error Raised**:
```elixir
%LifecycleInvariantError{
  entity_type: :capability,
  created: 100,
  removed: 20,
  expected_active: 80,
  actual_active: 75,
  graph_size: 75,
  missing_from_graph: [...],
  missing_from_lifecycle: [...]
}
```

---

### Query API

#### Get Entity History

```elixir
@spec get_history(
  entity_type :: entity_type(),
  entity_id :: entity_id()
) :: [lifecycle_event()]
```

**Purpose**: Retrieve complete lifecycle history for an entity.

**Returns**: List of events sorted by tick (ascending)

**Example**:
```elixir
history = LifecycleRegistry.get_history(:capability, "mathematics")
# [
#   {:created, 100, %{...}},
#   {:rediscovered, 500, %{...}},
#   {:mutated, 1200, %{...}},
#   {:rediscovered, 2000, %{...}}
# ]
```

---

#### Get Entity Lineage

```elixir
@spec get_lineage(
  entity_type :: entity_type(),
  entity_id :: entity_id()
) :: [entity_id()]
```

**Purpose**: Retrieve ancestry chain for an entity.

**Returns**: List of parent IDs from root to current

**Example**:
```elixir
lineage = LifecycleRegistry.get_lineage(:capability, "quantum_computing")
# ["computing", "classical_computing", "quantum_computing"]
```

---

#### Get Survival Curve

```elixir
@spec get_survival_curve(
  entity_type :: entity_type(),
  cohort_tick :: tick()
) :: %{tick() => non_neg_integer()}
```

**Purpose**: Track survival rate of entities created in a specific tick.

**Returns**: Map of tick → surviving count

**Example**:
```elixir
curve = LifecycleRegistry.get_survival_curve(:capability, 1000)
# %{1000 => 50, 2000 => 35, 3000 => 20, 4000 => 12}
```

---

#### Get Statistics

```elixir
@spec get_stats(entity_type :: entity_type()) :: %{
  created: non_neg_integer(),
  rediscovered: non_neg_integer(),
  removed: non_neg_integer(),
  promoted: non_neg_integer(),
  merged: non_neg_integer(),
  rolled_back: non_neg_integer(),
  quarantined: non_neg_integer()
}
```

**Purpose**: Retrieve aggregate statistics for an entity type.

**Example**:
```elixir
stats = LifecycleRegistry.get_stats(:capability)
# %{
#   created: 38,
#   rediscovered: 1833,
#   removed: 0,
#   promoted: 0,
#   merged: 0,
#   rolled_back: 0,
#   quarantined: 0
# }
```

---

#### Compute Innovation Efficiency

```elixir
@spec innovation_efficiency(entity_type :: entity_type()) :: float()
```

**Purpose**: Calculate ratio of novel creations to total discoveries.

**Formula**:
```
efficiency = created / (created + rediscovered)
```

**Returns**: Float between 0.0 and 1.0

**Example**:
```elixir
efficiency = LifecycleRegistry.innovation_efficiency(:capability)
# 0.02 (2% exploration, 98% exploitation)
```

---

## Internal Implementation

### ETS Tables

#### `:lifecycle_events` (Bag Table)

Stores immutable event log.

**Key Structure**:
```elixir
{entity_type, entity_id, event_id, event_type, tick, removed_tick, metadata}
```

**Properties**:
- Append-only (never modified after insertion)
- Bag table allows multiple events per entity
- Write concurrency enabled

---

#### `:lifecycle_state` (Set Table)

Stores derived mutable state (current status of each entity).

**Key Structure**:
```elixir
{{entity_type, entity_id}, state_map}
```

**State Map Fields**:
```elixir
%{
  status: :active | :removed,
  created_tick: tick(),
  removed_tick: tick() | nil,
  removal_reason: removal_reason() | nil,
  version: non_neg_integer(),
  last_rediscovered_tick: tick() | nil,
  last_mutated_tick: tick() | nil
}
```

**Properties**:
- Updated on every lifecycle event
- Compound key prevents overwriting
- Write concurrency enabled

---

#### `:lifecycle_stats` (Set Table)

Stores aggregate counters per entity type.

**Key Structure**:
```elixir
{"#{entity_type}_#{metric}", count}
```

**Metrics**:
- `created`
- `rediscovered`
- `removed`
- `promoted`
- `merged`
- `rolled_back`
- `quarantined`

**Properties**:
- Updated via `:ets.update_counter` for atomicity
- Read-heavy workload

---

### Event ID Generation

```elixir
@spec generate_event_id() :: reference()
```

**Implementation**: Uses `make_ref()` for unique identifiers.

**Rationale**: References are globally unique, compact, and sortable by creation time.

---

### Match Specifications

ETS queries use match specifications for efficient pattern matching:

```elixir
# Get all active entity IDs for a type
match_spec = [{{{entity_type, :'$1'}, :_}, [], [:'$1']}]
active_ids = :ets.select(:lifecycle_state, match_spec)
```

**Note**: Match specs require literal atoms in patterns, not variables.

---

## Usage Patterns

### Dual-Write Migration Pattern

During transition from legacy ecology tracking to lifecycle registry:

```elixir
# Legacy call (to be retired)
record_capability_birth(cap_id, tick, metadata)

# New lifecycle call
LifecycleRegistry.record_created(:capability, cap_id, tick, metadata)
```

Both systems run in parallel until lifecycle registry is validated.

---

### Invariant Check After Selection

After every capability selection pass:

```elixir
try do
  LifecycleRegistry.verify!(:capability, fn ->
    state.research_programs
    |> Map.values()
    |> Enum.flat_map(fn prog -> Map.keys(prog.capabilities) end)
    |> MapSet.new()
  end)
rescue
  e ->
    Logger.error("Invariant violation: #{inspect(e)}")
    raise e
end
```

---

### Enriched Event Payload

Always include rich context when recording events:

```elixir
LifecycleRegistry.record_created(:capability, cap_id, tick, %{
  # Required context
  world_id: world.id,
  program_id: program.id,
  
  # Lineage tracking
  parent_id: parent_cap_id,
  discovery_id: discovery.id,
  generation: depth,
  lineage: full_lineage_chain,
  
  # Version tracking
  version: 1,
  
  # Domain-specific metadata
  fitness: computed_fitness,
  depth: tree_depth,
  parameters: capability_params
})
```

**Rule**: More context is always better. Future analytics will depend on this metadata.

---

## Error Handling

### LifecycleInvariantError

Raised when entity conservation law is violated.

**Fields**:
```elixir
defexception [
  entity_type: atom(),
  created: non_neg_integer(),
  removed: non_neg_integer(),
  expected_active: non_neg_integer(),
  actual_active: non_neg_integer(),
  graph_size: non_neg_integer(),
  missing_from_graph: [term()],
  missing_from_lifecycle: [term()]
]
```

**Handling**: Should never be caught except for logging. Indicates fundamental state corruption.

---

### AlreadyExistsError

Returned when `record_created/4` detects rediscovery.

**Handling**: Normal flow. Caller should treat as successful rediscovery, not error.

---

## Performance Characteristics

| Operation | Complexity | Notes |
|-----------|-----------|-------|
| `record_created/4` | O(1) | Single ETS lookup + insert |
| `record_removed/4` | O(1) | Single ETS update |
| `verify!/2` | O(n) | Scans all active entities |
| `get_history/2` | O(log n) | ETS select by key |
| `get_stats/1` | O(1) | Direct counter read |
| `innovation_efficiency/1` | O(1) | Computed from stats |

**Scalability**: Tested up to 100k ticks, 2k programs, 10k+ entities.

---

## Testing

### Invariant Tests

Located in `test/tiannara/validation/lifecycle_invariant_test.exs`.

**Coverage**:
- Entity conservation law
- Event conservation law
- Rediscovery detection
- Removal tracking
- Promotion handling
- Cross-entity-type isolation

**Run**:
```bash
mix test test/tiannara/validation/lifecycle_invariant_test.exs
```

---

### Regression Suite

Must pass after any architectural change:

```bash
mix test
mix run run_run16_ecology_campaign.exs  # Full simulation
```

---

## Migration Guide

### From Legacy Ecology Tracking

**Before**:
```elixir
record_capability_birth(id, tick)
record_capability_death(id, tick)
```

**After**:
```elixir
LifecycleRegistry.record_created(:capability, id, tick, metadata)
LifecycleRegistry.record_removed(:capability, id, tick, :selection, metadata)
```

**Dual-Write Period**: Both systems run in parallel during validation.

---

### From Ad-Hoc State Tracking

**Before**:
```elixir
# Manual state management
state = Map.put(state, cap_id, %{status: :active})
```

**After**:
```elixir
# Canonical lifecycle tracking
LifecycleRegistry.record_created(:capability, cap_id, tick, metadata)
```

**Benefit**: Automatic invariant verification, event sourcing, audit trail.

---

## Future Extensions

### Planned Event Types

- `:adopted` - Cross-program adoption
- `:cited` - Citation event
- `:replicated` - Independent replication
- `:deprecated` - Marked for removal
- `:archived` - Moved to cold storage

### Planned Metrics

- Diffusion coefficient
- Adoption latency
- Independent rediscovery rate
- Promotion latency
- Extinction half-life

All extensions must preserve backward compatibility with existing API.

---

**End of Lifecycle API Specification**
