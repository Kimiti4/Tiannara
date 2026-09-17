# Phase 18.1 — Constitutional Cognitive Ontology: Schema Report

## Overview

Phase 18.1 implements the frozen cognitive ontology defined during Phase 18.0. This report documents every implemented type, validation coverage, serialization coverage, hash coverage, version compatibility, replay compatibility, migration readiness, and known constraints.

**Status:** All types are immutable, content-addressed, deterministically serializable, and constitutionally frozen.

---

## Implemented Types

| # | Type | Module | ID Prefix | Fields | Validated |
|---|------|--------|-----------|--------|-----------|
| 1 | CognitiveTask | `TiannaraRuntime.Cognitive.CognitiveTask` | `ct_` | 14 | ✅ |
| 2 | Goal | `TiannaraRuntime.Cognitive.Goal` | `gl_` | 14 | ✅ |
| 3 | Mission | `TiannaraRuntime.Cognitive.Mission` | `ms_` | 13 | ✅ |
| 4 | Plan | `TiannaraRuntime.Cognitive.Plan` | `pl_` | 13 | ✅ |
| 5 | Decision | `TiannaraRuntime.Cognitive.Decision` | `dc_` | 13 | ✅ |
| 6 | WorkingMemory | `TiannaraRuntime.Cognitive.WorkingMemory` | `wm_` | 12 | ✅ |
| 7 | CognitiveContext | `TiannaraRuntime.Cognitive.CognitiveContext` | `cc_` | 14 | ✅ |
| 8 | AttentionState | `TiannaraRuntime.Cognitive.AttentionState` | `as_` | 11 | ✅ |
| 9 | SchedulerState | `TiannaraRuntime.Cognitive.SchedulerState` | `ss_` | 11 | ✅ |
| 10 | ExecutionRequest | `TiannaraRuntime.Cognitive.ExecutionRequest` | `er_` | 11 | ✅ |
| 11 | ExecutionResult | `TiannaraRuntime.Cognitive.ExecutionResult` | `exr_` | 12 | ✅ |
| 12 | EvidenceReference | `TiannaraRuntime.Cognitive.EvidenceReference` | `evr_` | 10 | ✅ |
| 13 | ReplayReference | `TiannaraRuntime.Cognitive.ReplayReference` | `rr_` | 10 | ✅ |
| 14 | ArchaeologyReference | `TiannaraRuntime.Cognitive.ArchaeologyReference` | `ar_` | 11 | ✅ |

**Total: 14 types, 15 modules (including CognitiveSerializer)**

---

## Validation Coverage

Every struct implements `validate/1` with the following checks:

| Check | Coverage |
|-------|----------|
| Required fields non-nil | 14/14 types |
| Schema version match | 14/14 types |
| Referential integrity (ID prefixes) | 14/14 types |
| Immutable identifier verification | 14/14 types |
| Dependency consistency (lists) | 8/14 types |
| Fingerprint presence | 14/14 types |

**Validation pass condition:** All checks must pass. Returns `:ok` or `{:error, errors}`.

---

## Serialization Coverage

The `CognitiveSerializer` module provides:

| Function | Description | Status |
|----------|-------------|--------|
| `serialize/1` | Canonical binary encoding of any cognitive struct | ✅ |
| `deserialize/2` | Restore struct from binary + module name | ✅ |
| `stable_hash/1` | Deterministic SHA-256 of canonical form | ✅ |

**Serialization properties:**
- Stable ordering: keys sorted alphabetically
- Deterministic encoding: same input always produces same binary
- No locale dependence: uses Erlang term encoding
- No runtime metadata: timestamps and IDs excluded from hash

---

## Hash Coverage

| Property | Status |
|----------|--------|
| SHA-256 fingerprint | ✅ 14/14 types |
| Fingerprint excludes mutable fields (id, fingerprint, created_at) | ✅ 14/14 types |
| Fingerprint includes schema_version | ✅ 14/14 types |
| Same canonical input → same fingerprint | ✅ Verified |
| Different canonical input → different fingerprint | ✅ Verified |

---

## Version Compatibility

Every struct contains four version fields:

| Field | Purpose | Type |
|-------|---------|------|
| `schema_version` | Current struct layout version | integer |
| `ontology_version` | Current ontology contract version | integer |
| `created_with_phase` | Phase that created this artifact | string |
| `migration_version` | Incremented on migration | integer |

**Migration readiness:** The `migration_version` field enables future schema evolution. A migration from `v1` to `v2` would:
1. Read canonical serialization from ledger
2. Apply transform function
3. Recompute fingerprint
4. Increment `migration_version`
5. Write new artifact

---

## Replay Compatibility

| Requirement | Status |
|-------------|--------|
| Replay requires only immutable artifacts | ✅ |
| No runtime memory participates in replay | ✅ |
| Artifacts are content-addressed | ✅ |
| Fingerprints are deterministic | ✅ |
| Serialization is canonical | ✅ |
| Evidence references are immutable | ✅ |

---

## Known Constraints

1. **No behaviors or protocols implemented** — This is intentional. Phase 18.1 is ontology-only. Behaviours will be defined in Phase 18.05 freeze.
2. **No cross-type validation** — Each struct validates itself independently. Cross-type consistency (e.g., Mission.goals references valid Goal IDs) is deferred to Phase 18.2 runtime.
3. **No ETS/registry integration** — Structs are pure data. No GenServer or registry wrapping exists. This is intentional for Phase 18.1.
4. **No timezone handling in created_at** — `DateTime.utc_now()` is used for creation timestamps. Replay does not depend on timestamps (uses sequence numbers).
5. **String-based ID encoding** — IDs are hex-encoded SHA-256 prefixes. This is adequate for the Phase 18 scope.

---

## Acceptance Checklist

| Criterion | Status |
|-----------|--------|
| Every ontology object is immutable | ✅ |
| Every ontology object is content-addressed | ✅ |
| Serialization is deterministic | ✅ |
| Validators reject malformed objects | ✅ |
| Replay compatibility is verified | ✅ |
| Migration fields exist | ✅ |
| No runtime behavior exists | ✅ |
| No algorithms are implemented | ✅ |
| No cognition executes | ✅ |
| Ontology is ready for Phase 18.05 freeze | ✅ |

---

*This document is Phase 18.1 deliverable. All structs subject to constitutional freeze in Phase 18.05.*
