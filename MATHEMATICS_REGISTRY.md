# Phase 16.X.2 — Mathematics Registry

document_version: 16.X.2
phase: 16.X
status: Implemented
owner: Constitutional Research Council

---

## Purpose

The Mathematics Registry manages identifiers, registrations, and lifecycle definitions for all mathematical objects. Every mathematical entity in Phase 16.X has a unique content-addressed identifier, a registration record, and a lifecycle state.

---

## Registry Structure

The Mathematics Registry is a named ETS table (`:math_registry`) with `:set`, `:public`, `:named_table` semantics — the same pattern as the Phase 16.1 Knowledge Graph and Phase 16.X.3 Mathematics Knowledge Graph.

### Registration Entries

Each registration stores:

```
{registration_id, %{
  "registration_id" => String,       # content-addressed
  "artifact_type"  => String,        # e.g. "Axiom", "Theorem"
  "artifact_id"    => String,        # content-addressed ID of the artifact
  "owner"          => String,        # constitutional owner
  "lifecycle"      => String,        # current lifecycle phase
  "created_at"     => String,        # epoch timestamp
  "metadata"       => map            # extensible metadata
}}
```

### Lifecycle States

| State | Description | Valid Transitions |
|-------|-------------|-------------------|
| `:proposed` | Initial state for all new registrations | → `:active` |
| `:active` | Currently in use | → `:deprecated`, → `:archived` |
| `:deprecated` | Still present but not recommended for new use | → `:archived` |
| `:archived` | Historical record only | (terminal) |
| `:frozen` | Constitutionally sealed, cannot transition | (terminal) |

### Identifier Types

| Type | Prefix | Example |
|------|--------|---------|
| Ontology entity | `math_` | `math_a1b2c3...` |
| Knowledge Graph node | `node_` | `node_d4e5f6...` |
| Knowledge Graph edge | `edge_` | `edge_a1_b2_depends_on` |
| Registry entry | `reg_` | `reg_f7g8h9...` |
| Archaeology record | `arch_` | `arch_i0j1k2...` |

---

## API

```elixir
# Register a mathematical artifact
MathematicsRegistry.register(artifact_type, artifact_id, metadata)

# Look up an artifact by its registry ID
MathematicsRegistry.lookup(registration_id)

# Find all registrations for an artifact type
MathematicsRegistry.find_by_type(artifact_type)

# Get the lifecycle state of a registration
MathematicsRegistry.lifecycle(registration_id)

# Transition lifecycle state
MathematicsRegistry.transition(registration_id, new_state)

# List all active registrations
MathematicsRegistry.list_active()

# Check if an artifact ID is registered
MathematicsRegistry.registered?(artifact_id)
```

---

## Registration Rules

1. Every Phase 16.X artifact must have exactly one registration
2. Registration IDs are content-addressed SHA-256 of (artifact_type ++ artifact_id)
3. No duplicate registrations permitted for the same artifact_type + artifact_id
4. Lifecycle transitions must follow valid state machine
5. Frozen artifacts cannot transition
6. Archaeology records are created on every registration and transition

---

## Implementation

Module: `TiannaraRuntime.Mathematics.MathematicsRegistry`

ETS table: `:math_registry`

Dependencies:
- `MathematicalID` for content-addressed ID derivation
- `ArchaeologyRecord` for archaeology provenance

Tests: 18 tests covering registration, lookup, lifecycle, query, archaeology, replay, and validation.

---

## Audits

### Registry Integrity Audit
- [x] Every registration has a unique content-addressed ID
- [x] No duplicate artifact_type + artifact_id pairs
- [x] All ETS operations are deterministic (sorted by content hash)
- [x] Registry is reconstructable from exported JSON artifacts

### Identifier Uniqueness Audit
- [x] Content-addressed IDs are globally unique (SHA-256 collision resistance)
- [x] No two registrations share the same registration_id
- [x] Identifier derivation is deterministic (same inputs → same ID)

### Ownership Mapping Audit
- [x] Every registration has exactly one owner (Constitutional Research Council)
- [x] Owner field is non-empty and validated
- [x] Ownership cannot be changed without a new registration

### Lifecycle Audit
- [x] All lifecycle transitions follow the valid state machine
- [x] Frozen artifacts cannot be modified or transitioned
- [x] Lifecycle history is preserved in archaeology records
- [x] Invalid transitions return explicit errors

---

## Test Results

- 18 registry tests
- 0 failures
- All registration, lookup, lifecycle, and query operations verified
