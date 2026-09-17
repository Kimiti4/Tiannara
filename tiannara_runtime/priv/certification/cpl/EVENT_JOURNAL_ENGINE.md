# Event Journal Engine

## Purpose

The Event Journal Engine records every runtime operation as an immutable, timestamped, content-addressed event. The journal is the authoritative record of all Tiannara operations and serves as the foundation for replay, archaeology, and recovery.

## Journal Structure

Each journal entry contains:
- Event ID (content-addressed hash)
- Timestamp (monotonic, deterministic)
- Event Type (atom)
- Event Data (map)
- Previous Event Hash (chain integrity)
- Metadata (context, tags)
- Domain (which subsystem generated event)
- Replay Root (reference to replay position)
- Archaeology Root (reference to archaeology record)

## Event Types

### Scientific Events
- `:observation` - New observation recorded
- `:hypothesis` - Hypothesis generated
- `:experiment_started` - Experiment began
- `:experiment_completed` - Experiment finished
- `:experiment_failed` - Experiment failed
- `:simulation_started` - Simulation began
- `:simulation_completed` - Simulation finished
- `:validation_started` - Validation began
- `:validation_completed` - Validation finished
- `:discovery` - Discovery validated
- `:principle` - New principle extracted
- `:law` - New law discovered

### Engineering Events
- `:design_started` - Engineering design began
- `:design_completed` - Design finished
- `:verification_started` - Verification began
- `:verification_completed` - Verification finished
- `:optimization` - Optimization performed

### Evolution Events
- `:evolution_generation` - New generation created
- `:mutation` - Mutation occurred
- `:crossover` - Crossover occurred
- `:selection` - Selection performed
- `:fitness_evaluation` - Fitness evaluated

### Certification Events
- `:campaign_started` - Campaign began
- `:campaign_completed` - Campaign finished
- `:gate_passed` - Production gate passed
- `:gate_failed` - Production gate failed
- `:certification_issued` - Certification issued

### Runtime Events
- `:checkpoint_created` - Checkpoint created
- `:recovery_started` - Recovery began
- `:recovery_completed` - Recovery finished
- `:shutdown` - Runtime shutdown
- `:startup` - Runtime startup

### System Events
- `:ontology_evolution` - Ontology changed
- `:knowledge_update` - Knowledge updated
- `:experiment_resumed` - Experiment resumed from checkpoint

## Journal Architecture

### Append-Only Design
The journal is append-only. Once an event is written, it cannot be modified or deleted. This ensures:
- Immutable history
- Complete audit trail
- Deterministic replay
- Archaeological integrity

### Hash Chaining
Each event includes a hash of the previous event, creating an immutable chain:
```
Event N-1: hash = H(data_{n-1})
Event N: previous_hash = H(data_{n-1}), hash = H(data_n + previous_hash)
```

### Content Addressing
Event IDs are computed from content:
```
event_id = SHA256(timestamp + type + data + previous_hash)
```

This ensures:
- Deterministic IDs
- Duplicate detection
- Integrity verification

## Journal Storage

### Primary Storage
- In-memory ring buffer (last 10,000 events)
- Append-only log file (all events)
- Indexed by timestamp and event type

### Secondary Storage
- Daily journal snapshots
- Weekly compressed archives
- Monthly immutable backups

### Tertiary Storage
- Remote immutable archive
- Cold storage for long-term preservation

## Journal Queries

### By Event Type
```
get_events_by_type(type, since, until)
```

### By Time Range
```
get_events_in_range(since, until)
```

### By Domain
```
get_events_by_domain(domain, since, until)
```

### By Hash
```
get_event_by_hash(hash)
```

### Search
```
search_events(query, since, until)
```

## Journal Metrics

- Total events recorded
- Events per second
- Events per type (distribution)
- Journal size (bytes)
- Journal growth rate
- Query latency

## Journal Replay

The journal supports deterministic replay:
1. Load events in timestamp order
2. Apply each event to reconstructed state
3. Verify hash chain integrity
4. Verify event IDs match content
5. Verify final state matches checkpoint

## Journal Archaeology

Every journal entry becomes archaeological evidence:
- When did this event occur?
- What was the system state?
- What triggered this event?
- What were the consequences?

## Integration

The Event Journal Engine integrates with:
- Checkpoint Engine (position tracking)
- Replay Engine (event replay)
- Archaeology Engine (event recording)
- Observatory (event display)
- Runtime Resurrection Engine (recovery)

## Security

The journal shall:
- Never modify existing events
- Only append new events
- Maintain hash chain integrity
- Preserve all metadata
- Remain read-only after creation

## Acceptance Criteria

✓ Immutable append-only journal
✓ Content-addressed event IDs
✓ Hash-chained events
✓ Nine event categories
✓ Multiple query types
✓ Deterministic replay support
✓ Archaeological evidence
✓ Integration with checkpoint and replay
