# Phase 20.4 — Dependency Resolution Engine

## Role

The Dependency Resolution Engine constructs the complete integration dependency graph, detects conflicts, and produces a deterministic integration ordering. It ensures that no integration introduces dependency cycles or unresolved conflicts.

## Responsibilities

### 1. Dependency Graph Construction

Build a complete directed graph of all dependencies:

- Candidate's declared dependencies (modules, interfaces, data types, protocols)
- Transitive dependencies (dependencies of dependencies, recursively resolved)
- Runtime's existing dependency graph
- Cross-dependencies between candidate and existing modules
- Interface dependencies (candidate interfaces that depend on existing interfaces)

Each node represents a module, interface, data type, or protocol.
Each edge represents a dependency relationship (A depends on B).

### 2. Cycle Detection

Detect and report all cycles in the combined dependency graph:

- Direct cycles (A → B → A)
- Indirect cycles (A → B → C → A)
- Cross-domain cycles (A in candidate → B in runtime → C in candidate → A)
- Interface cycles (cyclic interface dependencies)

**Fail closed on any cycle.** No integration may proceed with unresolved cycles.

Each cycle report includes:
- Cycle path (ordered list of nodes forming the cycle)
- Cycle type (direct/indirect/cross-domain)
- Severity assessment
- Resolution suggestions

### 3. Conflict Detection

Detect and report all dependency conflicts:

| Conflict Type | Description |
|---------------|-------------|
| Version conflict | Candidate requires different version than what is installed |
| Duplicate conflict | Two modules provide the same interface with different implementations |
| Incompatible license | Dependency license conflicts with constitutional policy |
| Deprecated dependency | Candidate depends on a deprecated or retired module |
| Missing dependency | Candidate dependency does not exist in any available source |
| Privilege conflict | Candidate requires privileges not granted by current constitution |

**Fail closed on unresolved conflicts.**

### 4. Topological Ordering

Produce a deterministic integration order:

1. Compute topological sort of the combined dependency graph
2. Verify no cycles exist (precondition)
3. Order modules such that dependencies are integrated before dependents
4. Use deterministic tie-breaking for modules at the same dependency level:
   - Priority: lower priority number first (defined per module type)
   - Timestamp: earlier creation timestamps first
   - Content hash: lexicographically smaller hash first

The resulting order is deterministic and reproducible.

### 5. Obsolete Module Detection

Identify modules that will be superseded by the integration:

- Modules explicitly replaced by candidate
- Modules whose interfaces are fully subsumed by candidate
- Modules that become unreachable after integration
- Modules that have been deprecated but not yet retired

Obsolete modules are flagged for retirement planning but are not removed during integration. Retirement follows the separate Retirement Framework (Phase 20.0).

### 6. Integration Ordering Generation

Produce the final integration ordering artifact:

- Ordered list of integration steps
- Each step specifies which module to integrate/migrate/update
- Each step specifies preconditions (must be satisfied before step)
- Each step specifies postconditions (guaranteed after step)
- Each step specifies rollback inverse

## Deterministic Guarantees

- Same candidate + same runtime state → identical dependency graph, cycle detection, conflict detection, and topological order
- All intermediate data structures are content-addressed and replayable
- Topological ordering is deterministic across all platforms

## Archaeology

Dependency Resolution produces:

- Combined dependency graph (before and after)
- Cycle detection report
- Conflict detection report
- Topological ordering artifact
- Obsolete module report
- Integration ordering artifact

All artifacts are immutable, content-addressed, and archaeologically preserved.
