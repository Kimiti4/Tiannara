# CPL Observability Model

## Purpose

The CPL Observability Model defines all observable metrics, displays, and APIs for the Constitutional Persistence Layer, enabling monitoring of runtime continuity, recovery events, and persistence health.

## Observable Metrics

### Runtime Continuity Metrics
- Runtime availability (percentage)
- Active runtime (milliseconds)
- Elapsed runtime (milliseconds)
- Recovery count
- Recovery success rate
- Knowledge loss count
- Experiment loss count
- Replay divergence count
- Continuity score (0-100)

### Checkpoint Metrics
- Checkpoint creation rate (per second)
- Checkpoint size per domain (bytes)
- Checkpoint frequency (per domain)
- Checkpoint latency (milliseconds)
- Checkpoint verification time (milliseconds)
- Checkpoint success rate

### Journal Metrics
- Journal entry count
- Journal entries per second
- Journal size (bytes)
- Journal growth rate (bytes/second)
- Journal query latency (milliseconds)
- Journal search latency (milliseconds)

### Recovery Metrics
- Recovery count
- Recovery success rate
- Recovery duration (milliseconds)
- Recovery time by failure type
- Recovery success by failure type
- Knowledge loss by recovery
- Experiment loss by recovery
- Replay divergence by recovery

### Storage Metrics
- Storage usage per tier (bytes)
- Storage growth rate (bytes/second)
- Storage read latency (milliseconds)
- Storage write latency (milliseconds)
- Storage error rate
- Storage availability

### Backup Metrics
- Backup creation count
- Backup size per tier (bytes)
- Backup duration (milliseconds)
- Backup success rate
- Backup restoration count
- Backup restoration success rate

### Snapshot Metrics
- Snapshot creation count
- Snapshot size (bytes)
- Snapshot frequency
- Snapshot verification count
- Snapshot verification success rate
- Snapshot restoration count
- Snapshot restoration success rate

## Observatory Integration

### Screen 1: Constitutional Health
Display:
- Runtime availability
- Recovery count
- Recovery success rate
- Knowledge loss
- Experiment loss
- Replay divergence
- Continuity score

### Screen 12: Mission Timeline
Display:
- Recovery timeline
- Checkpoint timeline
- Failure timeline
- Backup timeline
- Snapshot timeline

### Screen 13: Persistence Health (New)
Display:
- Checkpoint metrics
- Journal metrics
- Recovery metrics
- Storage metrics
- Backup metrics
- Snapshot metrics

## APIs

### Read-Only APIs

#### Latest Checkpoint
```
get_latest_checkpoint(domain) -> checkpoint
```

#### Checkpoint History
```
get_checkpoint_history(domain, since, until) -> [checkpoint]
```

#### Recovery History
```
get_recovery_history(since, until) -> [recovery_report]
```

#### Journal
```
get_journal(since, until) -> [journal_entry]
```

#### Journal Search
```
search_journal(query, since, until) -> [journal_entry]
```

#### Recovery Report
```
get_recovery_report(report_id) -> recovery_report
```

#### Continuity Status
```
get_continuity_status() -> continuity_certificate
```

#### Replay Recovery
```
get_replay_recovery() -> replay_recovery_status
```

#### Archaeology Recovery
```
get_archaeology_recovery() -> archaeology_recovery_status
```

## Observability Metrics

Track:
- Observatory display latency
- API query latency
- API query count
- API error rate

## Observability Integration

The CPL Observability Model integrates with:
- Observatory (screen displays)
- Checkpoint Engine (checkpoint metrics)
- Event Journal Engine (journal metrics)
- Runtime Resurrection Engine (recovery metrics)
- Storage Engine (storage metrics)
- Backup Engine (backup metrics)
- Snapshot Engine (snapshot metrics)

## Security

CPL Observability shall:
- Provide read-only access
- Never modify existing data
- Maintain hash chain integrity
- Preserve all lineage

## Acceptance Criteria

✓ Runtime continuity metrics
✓ Checkpoint metrics
✓ Journal metrics
✓ Recovery metrics
✓ Storage metrics
✓ Backup metrics
✓ Snapshot metrics
✓ Observatory screen integration
✓ Read-only APIs
✓ Observability metrics
