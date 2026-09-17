# EFDI Signal Lifecycle

**Phase:** D1 — Signal Intelligence

## 1. States

A signal moves through explicit states (`status` field):

```
:registered → :superseded / :expired     (immutable, never overwritten)
```

- `:registered` — accepted into the registry.
- `:superseded` — a newer version exists (`supersede/2`); the original is kept
  intact, never altered.
- `:expired` — `expires_at` is in the past (`Signal.expired?/2`).

A signal with `expires_at: nil` never expires.

## 2. Registration

```
Signal.new(attrs) → Signal
SignalRegistry.register(signal)
  ├─ Signal.validate (source & observation present; measurement_uncertainty well-formed)
  ├─ compute dedup_key (deterministic sha256 over source+observation)
  ├─ existing_by_key?
  │    ├─ HIT  → return existing signal (no double count)
  │    └─ MISS → insert {id, signal} + {{:dedup, key}, id}; increment count
  └─ best-effort: persist memory, append EventStore event
```

## 3. Correction / supersede (append-only history)

```
SignalRegistry.supersede(id, updates)
  ├─ look up existing (error :not_found if absent)
  ├─ Signal.version(existing, updates)
  │    • new immutable id
  │    • version+1
  │    • lineage = [existing.id | existing.lineage]
  │    • provenance.kind = :derived, source_event_id = existing.id
  │    • supersedes = existing.id
  ├─ new dedup_key collision? → error :dedup_collision
  └─ store new version (original untouched)
```

Constitutional guarantee: **historical signals are never overwritten.** A
correction produces a new record and preserves the original.

## 4. Query

- `get/1` — by id.
- `list_by_source/1`, `list_by_domain/1` — by provenance facet.
- `list_in_range/2` — by `timestamp` window.
- `list_active/1` — excludes expired.
- `all_ids/0` — replay enumeration (for provenance / reproducibility probes).

## 5. Epistemic invariant

The lifecycle never fabricates persistence, never overwrites history, and never
promotes a signal to evidence/forecast/decision within D1. Those promotions are
D2–D6 concerns.
