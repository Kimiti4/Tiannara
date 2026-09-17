# Observatory Domain Model

## Data Flow Architecture

Every observable transition in the Observatory is an explicit, versioned, auditable step.
The following pipeline defines how Runtime state becomes operator decisions and back again.

```
┌─────────────────────────────────────────────────────────────┐
│                         RUNTIME                             │
│  Tiannara Discovery Engine (constitution-governed)         │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│ 1. OBSERVATION                                              │
│    Raw signals from Runtime: metrics, logs, events          │
│    Protocol: NATS / HTTP push / telemetry handler           │
│    Guarantee: At-least-once delivery                        │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│ 2. TELEMETRY                                                │
│    Structured, schematized, timestamped                     │
│    Attaches: identity, source, version, clock, provenance   │
│    Validation: reject malformed, log rejection with reason  │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│ 3. VALIDATION                                               │
│    Schema check: does the event match its declared domain?  │
│    Integrity check: does the signature chain verify?        │
│    Freshness check: is the clock within acceptable skew?    │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│ 4. PERSISTENCE                                              │
│    Append-only event store: immutable, ordered, indexed     │
│    Deduplication: UUID-based, idempotent writes             │
│    Retention: policy-driven, archivable                     │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│ 5. AGGREGATION                                              │
│    Metrics engine: counters, gauges, histograms             │
│    Windows: 1s, 5s, 30s, 5m, 1h, 24h                      │
│    State engine: ETS tables for each domain                 │
│    Snapshots: periodic ETS → PG persistence                 │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│ 6. CERTIFICATION                                            │
│    Automatic quality assessment: freshness, completeness,   │
│    consistency, trust. Produces certification status per    │
│    data stream, metric, and composite visualization.        │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│ 7. VISUALIZATION                                           │
│    Widgets: certified data + spec + renderer                │
│    Dashboards: layouts of certified widgets                 │
│    Every visualization is versioned and reconstructable     │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│ 8. OPERATOR                                                 │
│    Human or automated agent with a declared role            │
│    Sees only data permitted by role + certification level   │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│ 9. DECISION                                                 │
│    Interpretation of visualization leads to decision        │
│    Decision is recorded: who, what, when, why, alternative  │
│    Decision may trigger intervention (via API)              │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│ 10. AUDIT                                                  │
│     Every step is auditable backward:                      │
│     Decision → Operator → Visualization → Certification → │
│     Aggregation → Persistence → Validation → Telemetry →  │
│     Observation → Runtime                                  │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│ 11. REPLAY                                                 │
│     Given a timestamp T and event stream up to T:          │
│     Reconstruct Aggregation → Certification → Visualization│
│     → exactly as it appeared at T.                         │
│     Bit-identical output for identical input.              │
└──────────────────────────────────────────────────────────────┘
```

## Domain Transition Properties

Every transition `A → B` satisfies:

| Property | Requirement |
|----------|------------|
| **Identity** | Every item at B carries the original identity from A |
| **Provenance** | Source at A is preserved through B |
| **Version** | Schema version is propagated |
| **Timestamp** | Original observation timestamp is never lost |
| **Certification** | Certification status follows the data; transformations may degrade it |
| **Nullability** | If A fails, B does not produce fabricated data; gap is explicit |

## Cross-Cutting Concerns

| Concern | Coverage |
|---------|----------|
| **Audit** | Every transition logs: source, target, transformation, duration |
| **Backpressure** | Each stage can signal upstream to slow or pause |
| **Health** | Each stage exposes: queue depth, processing rate, error rate, last success timestamp |
| **Replay** | Each stage can be replayed independently given the correct input stream |
