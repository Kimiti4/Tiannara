# EFDI Provenance

**Phase:** D1 — Signal Intelligence
**Module:** `Tiannara.Forecasting.Provenance`

## 1. Purpose

`Provenance` records where a signal came from and how it was transformed, so
that any signal can be traced, replayed, and checked for integrity.

## 2. Data

A signal's `provenance` is a map:

| field | meaning |
|-------|---------|
| `kind` | `:observation` (original) or `:derived` (versioned) |
| `sha256` | content hash over source+observation |
| `source_event_id` | linked source/EventStore event id |

## 3. Operations

| function | contract |
|----------|----------|
| `build/1` | construct provenance for a signal |
| `content_hash/1` | deterministic sha256 over source+observation |
| `integrity?/1` | recompute and compare content hash |
| `valid?/1` | structural validity (kind present, etc.) |
| `derived?/1` | is this a derived (versioned) signal |

## 4. Determinism & reproducibility

`content_hash/1` is a pure function of `source + observation`. Combined with
`Signal.dedup_key/1` (which hashes the same inputs), two structurally identical
signals are provably reproducible. `all_ids/0` on the registry permits full
replay for audit.

## 5. Lineage tie-in

`Signal.lineage` holds ancestor ids; `Signal.supersedes` points at the immediate
predecessor. Versioning via `Signal.version/2` stamps `provenance.kind = :derived`
and records `source_event_id = previous_id`, giving an unbroken immutable chain.

## 6. Honesty rules

- Missing provenance never yields a false `integrity?/1 == true`.
- No historical record is ever rewritten; corrections append.
