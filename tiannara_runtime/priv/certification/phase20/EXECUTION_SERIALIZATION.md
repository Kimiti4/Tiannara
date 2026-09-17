# Phase 20.2 — Execution Serialization Specification

Every execution artifact supports deterministic serialization and deserialization. Serialization is the foundation of content-addressing, replayability, and canonical forms.

## Core Functions

All artifacts implement:
- `serialize/1` — Convert artifact to canonical byte representation
- `deserialize/1` — Restore artifact from canonical byte representation
- `canonical_form/1` — Produce the canonical representation (stable, deterministic)
- `fingerprint/1` — SHA-256 hash of the canonical form

## Canonical Ordering

| Rule | Description |
|---|---|
| UTF-8 | All text is UTF-8 encoded |
| Stable field ordering | Fields ordered alphabetically by key name |
| Stable map ordering | Map keys sorted in alphabetical order |
| Content-addressed SHA-256 | fingerprints are SHA-256 hashes of canonical content |

## Serialization Formats

| Artifact Type | Format |
|---|---|
| Events | JSON |
| Messages | JSON |
| Evidence | JSON |
| Replay artifacts | JSON |
| Archaeology artifacts | JSON |
| Metrics | JSON |
| Hashes | Binary (32 bytes, SHA-256) |

## Canonical Form Rules

- JSON is serialized with no whitespace (compact form)
- Keys are sorted alphabetically
- No floating-point numbers in canonical form
- All integers are represented as JSON integers
- Strings are UTF-8 encoded
- Arrays maintain their order
- Null values are omitted
- Empty objects are represented as `{}`
- Empty arrays are represented as `[]`

## Fingerprint Calculation

```
fingerprint(artifact) = SHA-256(canonical_form(serialize(artifact)))
```

The fingerprint is used for content-addressing, replay chain linking, and integrity verification.
