# EFDI Signal Model

**Phase:** D1 — Signal Intelligence
**Module:** `Tiannara.Forecasting.Signal`

## 1. What a signal is

A **signal** is a structured observation with explicit epistemic metadata. It is
a D1-concept between a raw *observation* and *evidence*:

```
observation (raw) → SIGNAL (structured + quality + provenance) → evidence
```

A signal is NOT a prediction, NOT evidence, NOT a fact, and NOT a belief.

## 2. Fields

### Identity
| field | meaning |
|------|---------|
| `id` | immutable UUID v4, never reused |
| `version` | starts at 1; incremented by `version/2` |
| `supersedes` | id this version replaced (nil for originals) |
| `lineage` | list of ancestor ids (parent first) |

### Source
| field | meaning |
|------|---------|
| `source` | origin (required) |
| `source_reliability` | trust in the source `[0,1]` |
| `domain` | `:cross_domain` by default |
| `context` | situational context |

### Observation
| field | meaning |
|------|---------|
| `observation` | the observed value (required) |
| `observation_ref` | reference to the underlying observation record |
| `observation_type` | `:unknown` by default |
| `measurement_uncertainty` | Numerics error mode / map with `:type` |

### Temporal
| field | meaning |
|------|---------|
| `timestamp` | when it was observed |
| `received_at` | when it entered the system |
| `regime` | regime/era label |
| `expires_at` | validity deadline (nil = never expires) |

### Provenance
| field | meaning |
|------|---------|
| `provenance.kind` | `:observation` default |
| `provenance.sha256` | content hash |
| `provenance.source_event_id` | linked source event |
| `transformation_history` | ordered transforms applied |

### Quality & state
| field | meaning |
|------|---------|
| `reliability` | `[0,1]` or `:unknown` |
| `relevance` | `[0,1]` or `:unknown` |
| `independence` | `[0,1]` or `:unknown` |
| `persistence` | `[0,1]` or `:unknown` |
| `predictive_value` | `[0,1]` or `:unknown` |
| `status` | `:registered` default |
| `metadata` | map |
| `tags` | list |

## 3. Operations

| function | contract |
|----------|----------|
| `new/1` | build from map/keyword with defaults |
| `validate/1` | `{:ok, s}` or `{:error, reason}` |
| `version/2` | new version, original preserved |
| `expired?/2` | temporal validity check |
| `dedup_key/1` | deterministic sha256(source+observation) |

## 4. Canonical fingerprint

`dedup_key` = lowercase hex sha256 over
`:erlang.term_to_binary(%{source, observation})`.

Used for deduplication so the same observation is not double-counted as
independent evidence.

## 5. Governance

- Historical signals are immutable.
- Corrections create new versions; nothing is rewritten.
- `:unknown`/`nil` is a valid value where evidence is insufficient; it is never
  silently coerced to `0.0`.
