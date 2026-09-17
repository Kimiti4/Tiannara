# Phase 18.8 — Constitutional Migration Record

## Source Systems

### `meta_cognition/`
- **Version:** Legacy Constitutional Prototype
- **Role:** First-generation metacognition experiment
- **Scope:** Basic self-monitoring and confidence tracking
- **Status:** No longer active

### `metacognitive/`
- **Version:** Experimental Runtime Prototype
- **Role:** Second-generation runtime integration trial
- **Scope:** Added health assessment and escalation
- **Status:** No longer active

## Destination

**Phase 18.8 Constitutional Metacognition System**
- **Namespace:** `metacognition.`
- **Scope:** Full pipeline (MetaController → MetaArchaeology)
- **Status:** Certified, frozen

## Migration Strategy

| Aspect | Approach |
|---|---|
| **Ontology** | Concepts from both source systems were unified into a single hierarchy. Conflicting term definitions were resolved in favour of the constitutional specification. |
| **Algorithms** | The confidence calibration algorithm from `meta_cognition/` and the health aggregation from `metacognitive/` were selectively reused after verification. All other algorithms were rewritten. |
| **APIs** | All public APIs were rewritten under the `metacognition.` namespace. No legacy API signatures are preserved. |
| **Namespaces** | `meta_cognition.*` and `metacognitive.*` are superseded by `metacognition.*`. No code should import from legacy namespaces. |
| **Historical lineage** | The provenance of each design decision and algorithm is documented in the decision records. Traceability from legacy to Phase 18.8 is maintained. |

## Archive Plan

- Legacy systems preserved in-place during Phase 18.8
- After Phase 18.999, both `meta_cognition/` and `metacognitive/` will be moved to the archive store
- No runtime dependency on legacy code exists after Phase 18.8
