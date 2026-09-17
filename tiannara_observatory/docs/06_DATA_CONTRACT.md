# Observatory Data Contract

## Event Schema

Every event entering or flowing through the Observatory must satisfy this schema.
Fields are classified as **Core** (always present) or **Domain** (vary by event taxonomy).

### Core Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID v7 | Yes | Globally unique event identifier. K-sortable for chronological ordering. |
| `source` | URI | Yes | Origin of the event, e.g., `runtime://generation/42/node/alpha` or `observatory://gateway/phx-1`. Never opaque. |
| `version` | semver | Yes | Schema version that this event conforms to. Currently `1.0.0`. |
| `timestamp` | ISO 8601 | Yes | Wall-clock time at the source when the event was emitted. Nanosecond precision. |
| `clock` | Hybrid Logical Clock | Yes | HLC value for causal ordering across distributed sources. |
| `provenance` | Provenance | Yes | Chain of custody: who/what produced this event, through which pipeline stages. |
| `signature` | Signature | Conditional | Cryptographic signature of the event body. Required for certified domains (science, governance, certification). |
| `schema` | URI | Yes | Full schema URI that validates this event, e.g., `obs://schemas/v1/runtime/health`. |
| `domain` | Domain | Yes | One of the official taxonomy domains (O0.5). |
| `classification` | Classification | Yes | Security classification: `public`, `internal`, `restricted`, `secret`, `constitutional`. |
| `replay_id` | UUID v7 | Conditional | Links this event to a specific replay session. Present if event was produced during replay. |
| `lineage` | Lineage | Conditional | Parent event IDs that causally preceded this event. Required for derived events. |
| `compression` | Compression | Conditional | Compression algorithm if `payload` is compressed: `none`, `gzip`, `zstd`. |
| `retention` | Duration | Yes | How long this event must be retained before archival. Default: 90 days. |
| `certification` | Certification | Conditional | Certification status at time of ingestion. Set by the Certification layer, not the source. |

### Provenance Schema

```
Provenance {
  producer:    URI          // the entity that created this event
  pipeline:    [Stage]      // ordered list of pipeline stages this event passed through
  generation:  integer      // Runtime generation at time of emission
  constitution: semver      // Constitution version in effect at time of emission
  operator:    URI | null   // Human operator who triggered this event, if applicable
}
```

### Signature Schema

```
Signature {
  algorithm:   "ed25519" | "hmac-sha256"
  key_id:      URI          // identifies the signing key
  value:       hex string   // signature of the canonical JSON payload
  signed_at:   ISO 8601     // when the signature was computed
}
```

### Lineage Schema

```
Lineage {
  parent_ids:     [UUID]    // immediate causal parents (typically 1, may be 0 for root events)
  root_id:        UUID      // the original event in this causal chain
  depth:          integer   // number of hops from root
  branch:         string | null  // branching label for parallel lineage
}
```

### Classification Schema

```
Classification {
  level:       "public" | "internal" | "restricted" | "secret" | "constitutional"
  compartment: [string]    // optional compartments (e.g., ["science", "governance"])
  reason:      string | null  // reason for classification level
}
```

### Certification Schema

```
Certification {
  status:     "certified" | "provisional" | "degraded" | "stale" | "uncertain"
  checked_at: ISO 8601       // when certification was evaluated
  checked_by: URI            // the certifier component
  confidence: float [0, 1]  // confidence score
  reasons:    [string]       // reasons for the certification status
  upstream:   [Certification] // certification of data sources this depends on
}
```

### Payload Schema (Domain Fields)

The `payload` field is a JSON object whose shape is determined by the `domain` and `schema` fields.
Example payload shapes:

**Domain: runtime/health**
```json
{
  "uptime_seconds": 1234567,
  "cpu_percent": 42.5,
  "memory_percent": 67.1,
  "discovery_rate": 3.2,
  "active_challenges": 14,
  "cpl_checkpoint_id": "chk-a1b2c3"
}
```

**Domain: science/discovery**
```json
{
  "discovery_id": "disc-007",
  "hypothesis": "observational asymmetry in dark matter distribution",
  "confidence": 0.89,
  "experiments_run": 12,
  "experiments_passed": 11,
  "peer_review_status": "pending"
}
```

## Data Contract Guarantees

| Guarantee | Description |
|-----------|-------------|
| **Completeness** | No core field is ever omitted. If a field has no value, it is explicitly `null`, not absent. |
| **Ordering** | Events from the same source are globally ordered by clock. |
| **Idempotency** | Replaying the same event with the same UUID produces the same state. |
| **Immutability** | Once written to the event store, an event is never modified. |
| **Traceability** | Every event's provenance chain can be followed end-to-end. |
| **Schema Evolution** | Schemas are versioned. New fields are additive. Breaking changes produce a new schema URI. |

## Event Wire Format

```json
{
  "id": "0193b5c0-7a2f-7f00-8000-000000000001",
  "source": "runtime://generation/42/node/phoenix-1",
  "version": "1.0.0",
  "timestamp": "2026-07-16T14:30:00.123456789Z",
  "clock": {
    "wall_time": 20260716143000123456789,
    "logical": 42
  },
  "provenance": {
    "producer": "runtime://generation/42/node/phoenix-1",
    "pipeline": [
      {"stage": "observation", "timestamp": "2026-07-16T14:30:00.123Z"},
      {"stage": "telemetry_gateway", "timestamp": "2026-07-16T14:30:00.200Z"}
    ],
    "generation": 42,
    "constitution": "1.0.0",
    "operator": null
  },
  "signature": {
    "algorithm": "ed25519",
    "key_id": "runtime://keys/42",
    "value": "a1b2c3d4...",
    "signed_at": "2026-07-16T14:30:00.124Z"
  },
  "schema": "obs://schemas/v1/runtime/health",
  "domain": "runtime/health",
  "classification": {
    "level": "internal",
    "compartment": [],
    "reason": null
  },
  "replay_id": null,
  "lineage": {
    "parent_ids": [],
    "root_id": "0193b5c0-7a2f-7f00-8000-000000000001",
    "depth": 0,
    "branch": null
  },
  "compression": "none",
  "retention": "P90D",
  "certification": {
    "status": "certified",
    "checked_at": "2026-07-16T14:30:00.250Z",
    "checked_by": "obs://certification/v1",
    "confidence": 1.0,
    "reasons": ["fresh", "signed", "valid_schema"],
    "upstream": []
  },
  "payload": {
    "uptime_seconds": 1234567,
    "cpu_percent": 42.5,
    "memory_percent": 67.1
  }
}
```
