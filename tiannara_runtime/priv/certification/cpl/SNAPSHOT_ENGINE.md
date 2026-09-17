# Snapshot Engine

## Purpose

The Snapshot Engine creates point-in-time snapshots of Tiannara's complete state across all nine checkpoint domains, enabling fast recovery and long-term preservation.

## Snapshot Architecture

### Snapshot Scope

Snapshots capture:
- Runtime state (all processes, supervisors, workers)
- Knowledge graph (all discoveries, hypotheses, principles, laws, theories)
- Ontology (all concepts, relationships, versions)
- Experiments (all experiments, journals, stages)
- Evolution (all generations, laws, mutations)
- Certification (all campaigns, gates, certificates)
- Replay position (current replay state)
- Archaeology position (current archaeology state)
- Observatory state (current metrics, screens, artifacts)

### Snapshot Structure

Each snapshot contains:
```
snapshot: {
  snapshot_id: string,
  timestamp: integer,
  domains: %{
    runtime_state: checkpoint,
    knowledge_graph: checkpoint,
    ontology: checkpoint,
    experiments: checkpoint,
    evolution: checkpoint,
    certification: checkpoint,
    replay_position: checkpoint,
    archaeology_position: checkpoint,
    observatory_state: checkpoint
  },
  state_hash: string,
  previous_snapshot_id: string | nil,
  size_bytes: integer,
  compression_ratio: float,
  verification_status: :verified | :unverified
}
```

## Snapshot Creation

### Snapshot Process

1. Pause non-critical operations (optional)
2. Capture each domain state
3. Generate domain checkpoints
4. Compute snapshot hash
5. Compress snapshot (optional)
6. Store snapshot
7. Verify snapshot integrity
8. Resume operations

### Snapshot Frequency

- Hourly snapshots (local)
- Daily snapshots (remote)
- Weekly snapshots (compressed)
- Monthly snapshots (immutable)

## Snapshot Verification

### Verification Process

1. Load snapshot
2. Verify snapshot hash
3. Verify each domain checkpoint
4. Verify hash chain continuity
5. Generate verification record

### Verification Metrics

Track:
- Verification count
- Verification success rate
- Verification duration
- Verification failures

## Snapshot Restoration

### Restoration Process

1. Load snapshot
2. Verify snapshot integrity
3. Restore each domain
4. Verify restoration
5. Resume operations

### Restoration Metrics

Track:
- Restoration count
- Restoration success rate
- Restoration duration
- Restoration failures

## Snapshot Metrics

Track:
- Snapshot creation count
- Snapshot size
- Snapshot frequency
- Snapshot storage usage
- Snapshot verification count
- Snapshot restoration count

## Snapshot Integration

The Snapshot Engine integrates with:
- Checkpoint Engine (domain checkpoints)
- Backup Engine (snapshot backups)
- Storage Engine (snapshot storage)
- Observatory (snapshot metrics)
- Runtime Resurrection Engine (snapshot restoration)

## Security

Snapshot Engine shall:
- Never modify existing snapshots
- Only append new snapshots
- Maintain hash integrity
- Preserve all lineage
- Ensure zero snapshot loss

## Acceptance Criteria

✓ Complete snapshot capture (all 9 domains)
✓ Snapshot creation process
✓ Snapshot verification process
✓ Snapshot restoration process
✓ Snapshot metrics observable
✓ Integration with checkpoint and backup
