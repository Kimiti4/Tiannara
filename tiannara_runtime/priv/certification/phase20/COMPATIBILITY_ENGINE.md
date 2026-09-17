# Phase 20.4 — Compatibility Engine

## Role

The Compatibility Engine determines whether a certified candidate can be safely integrated with the current runtime. It performs analysis across 8 compatibility dimensions. Any incompatibility in any dimension causes the integration to fail closed.

## Compatibility Dimensions

### 1. Structural Compatibility

Determines whether the candidate's architecture is structurally compatible with the current runtime.

| Check | Description |
|-------|-------------|
| Component existence | All referenced subsystems exist in current runtime |
| Interface match | All interface signatures match expected types |
| Data flow | Data flow between candidate and existing components is well-defined |
| Resource constraints | Candidate resource requirements do not exceed available capacity |
| Deployment topology | Candidate fits within existing deployment structure |

**Pass Criteria:** All checks pass. Diagnostics produced for each failure.

### 2. Behavioral Compatibility

Determines whether the candidate's runtime behavior is compatible with existing subsystems.

| Check | Description |
|-------|-------------|
| Side-effect analysis | Candidate does not produce unexpected side effects |
| Error propagation | Error modes are compatible with existing error handlers |
| Timing constraints | Timing requirements are compatible with existing schedules |
| State interactions | State mutations do not conflict with existing state machines |
| Concurrency model | Concurrency requirements are compatible with existing model |

**Pass Criteria:** All checks pass. Behavioral simulations confirm no conflicts.

### 3. Interface Compatibility

Determines whether the candidate's interfaces are compatible with existing interface contracts.

| Check | Description |
|-------|-------------|
| API signature match | Function signatures match exactly (name, parameters, return types) |
| Protocol compliance | Communication protocols are compatible |
| Message format | Message schemas are compatible |
| Error contract | Error types and handling are compatible |
| Version negotiation | Interface version negotiation is deterministic |

**Pass Criteria:** All interfaces verified compatible. No silent signature mismatches.

### 4. Replay Compatibility

Determines whether the candidate preserves replay determinism.

| Check | Description |
|-------|-------------|
| Replay chain continuity | Replay chain from before integration connects to after integration |
| Determinism preservation | Candidate does not introduce non-deterministic operations |
| Hash stability | All replay hashes remain deterministic across migration |
| Replay ordering | Replay step ordering remains consistent |
| Cold storage replay | Replay from cold storage produces identical results |

**Pass Criteria:** Replay chains remain continuous and deterministic. Hash verification passes.

### 5. Dependency Compatibility

Determines whether the candidate's dependencies are compatible with existing dependency graph.

| Check | Description |
|-------|-------------|
| Version compatibility | Dependency versions are compatible with existing constraints |
| No duplicate conflict | No conflicting versions of same dependency |
| No cycle introduction | Candidate does not introduce dependency cycles |
| No missing dependency | All candidate dependencies are satisfiable |
| No obsolete dependency | Candidate does not depend on deprecated subsystems |

**Pass Criteria:** Dependency graph remains acyclic and consistent. All dependencies satisfiable.

### 6. Knowledge Compatibility

Determines whether the candidate integrates with the existing knowledge graph.

| Check | Description |
|-------|-------------|
| Ontology compatibility | Candidate concepts map to existing ontology |
| Knowledge graph integrity | Integration does not introduce knowledge graph inconsistencies |
| Provenance compatibility | Evidence provenance chains remain intact |
| Cross-reference integrity | Cross-references between knowledge domains remain valid |
| Scientific capital | Knowledge integration does not reduce scientific capital |

**Pass Criteria:** Knowledge graph remains consistent. All cross-references valid.

### 7. Mathematical Compatibility

Determines whether the candidate integrates with the existing mathematical framework.

| Check | Description |
|-------|-------------|
| Mathematical formalism | Candidate uses compatible mathematical formalisms |
| Proof compatibility | Existing proofs remain valid after integration |
| Symbolic engine compatibility | Symbolic operations remain deterministic |
| Numerical stability | Numerical computations remain within error bounds |
| Mathematical graph integrity | Mathematical graph structure remains consistent |

**Pass Criteria:** All mathematical formalisms compatible. No proof invalidation.

### 8. Constitutional Compatibility

Determines whether the candidate complies with all constitutional rules.

| Check | Description |
|-------|-------------|
| Determinism requirement | Candidate satisfies determinism constraints |
| Replay requirement | Candidate supports full replay |
| Archaeology requirement | Candidate supports archaeological preservation |
| Evidence requirement | All integration decisions are evidence-based |
| Governance requirement | No bypass of constitutional governance |

**Pass Criteria:** All constitutional dimensions pass. No governance bypass possible.

## Engine Behavior

- Analysis is fully deterministic — same inputs always produce identical CompatibilityReport
- Each dimension produces structured diagnostics for every incompatibility found
- Integration fails closed on any dimension failure
- CompatibilityReport is immutable and content-addressed
- CompatibilityReport supports replay verification
- Compatibility archaeology records all findings, including successes

## Diagnostics Format

Each incompatibility diagnostic includes:

| Field | Description |
|-------|-------------|
| dimension | Which compatibility dimension failed |
| severity | Critical/Major/Minor/Informational |
| component | Affected component or interface |
| description | Human-readable description of incompatibility |
| evidence | Supporting evidence reference |
| resolution | Recommended resolution (if available) |
| fingerprint | SHA-256 of diagnostic entry |
