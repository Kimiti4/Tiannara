# Phase 20.1 — COS Serialization Specification

## Overview
Every constitutional object supports the following serialization functions:

| Function | Signature | Description |
|----------|-----------|-------------|
| serialize/1 | `object → binary` | Serializes an object to a binary representation |
| deserialize/1 | `binary → object` | Deserializes a binary to an object |
| canonical_form/1 | `object → binary` | Produces the canonical binary form for hashing |
| fingerprint/1 | `object → string` | Returns SHA-256 of canonical_form/1 |
| replay/1 | `object → replay_chain` | Executes replay verification on the object |
| verify/1 | `object → boolean` | Verifies fingerprint matches canonical_form |

## Canonical Ordering Rules

For `canonical_form/1` to produce deterministic output:

1. **UTF-8 encoding** — all strings are encoded as UTF-8. No BOM.
2. **Stable field ordering** — fields are serialized in alphabetical order by field name.
3. **Stable map ordering** — keys within map/object values are sorted lexicographically.
4. **Content-addressed SHA-256** — the final hash is `SHA-256(canonical_form)`.

## Serialization Format

| Data Type | Serialization Format |
|-----------|---------------------|
| Artifacts (objects) | JSON (UTF-8, no pretty-printing, no trailing whitespace) |
| Hashes | Binary (raw 32-byte SHA-256 digest, not hex-encoded) |
| Integers | JSON number, no leading zeros |
| Strings | JSON string, UTF-8 |
| Arrays | JSON array, stable order as defined by the schema |
| Maps | JSON object, keys sorted lexicographically |

## Restrictions

- **No floating-point in canonical form** — all numeric values must be representable as integers or fixed-point decimals. Floating-point types are forbidden in canonical serialization due to non-deterministic rounding behavior across platforms.
- **No null values** — absent optional fields are omitted entirely from the serialized output.
- **No duplicate keys** — duplicate keys in JSON objects are prohibited.

## Fingerprint Algorithm

```
fingerprint(object) = hex(SHA-256(canonical_form(object)))
```

Where:
- `canonical_form/1` serializes the object to a UTF-8 JSON byte sequence following the canonical ordering rules.
- `SHA-256/1` computes the SHA-256 digest of that byte sequence.
- `hex/1` encodes the 32-byte digest as a 64-character lowercase hexadecimal string.

## Verification

```
verify(object) = fingerprint(object) == object.fingerprint
```

Verification succeeds if and only if the computed fingerprint matches the stored fingerprint.
