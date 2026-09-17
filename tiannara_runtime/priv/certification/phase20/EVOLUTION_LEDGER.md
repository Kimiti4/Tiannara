# Phase 20.0 — Evolution Ledger Specification

## Overview

The Evolution Ledger is an immutable, append-only record of every architectural change in Tiannara's history. It provides complete lineage from Phase 1 through Phase 20 and beyond.

## Ledger Entry Schema

Each entry records a single architectural change:

### change_id
UUID uniquely identifying this change. Globally unique, immutable.

### timestamp
ISO 8601 timestamp of when the change was constitutionally certified.

### subsystem
Identifier of the subsystem that was changed. May reference a runtime, extension, service, or component.

### type
One of:
- **create:** New subsystem created
- **modify:** Existing subsystem modified
- **retire:** Subsystem retired
- **extend:** New extension integrated
- **freeze:** Subsystem frozen
- **amend:** Freeze amendment

### description
Human-readable description of the change. Must include the specific architectural difference introduced.

### experiment_ref
UUID referencing the constitutional experiment that validated this change. Links to experiment artifacts.

### certification_ref
UUID referencing the constitutional certification document authorizing this change.

### previous_fingerprint
Cryptographic hash of the subsystem's complete state before the change. Enables verification of lineage continuity.

### new_fingerprint
Cryptographic hash of the subsystem's complete state after the change.

### rationale
Formal rationale statement explaining why this change was necessary and how it improves constitutional goal achievement.

## Ledger Properties

- **Append-only:** No entry is ever modified, deleted, or reordered
- **Immutable:** Cryptographic chaining ensures tamper detection
- **Complete:** Every constitutional change has exactly one entry
- **Verifiable:** Any entry's predecessor can be verified via fingerprint
- **Traversable:** Full lineage can be traversed forward and backward

## Fingerprint Chaining

Each entry's previous_fingerprint must match the new_fingerprint of the immediate predecessor entry for the same subsystem. This creates a cryptographic chain proving lineage continuity. The first entry for any subsystem uses a null previous_fingerprint.

## Lineage Traversal

### Forward Traversal
Starting from any entry, follow new_fingerprint → previous_fingerprint links to reconstruct forward evolution.

### Backward Traversal
Starting from any entry, follow previous_fingerprint references to reconstruct ancestry.

### Full Reconstruction
Replaying all ledger entries for a subsystem in chronological order reconstructs its complete evolutionary history.

## Query Operations

- All changes for a given subsystem
- All changes of a given type
- All changes within a time range
- All changes referencing a given experiment
- Lineage from any change to any other change
- Fingerprint verification for any subsystem state
