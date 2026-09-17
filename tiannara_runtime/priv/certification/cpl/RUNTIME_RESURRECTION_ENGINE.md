# Runtime Resurrection Engine

## Purpose

The Runtime Resurrection Engine detects abnormal termination, locates the latest certified checkpoint, validates hashes, restores runtime state, and returns Tiannara to operational state with a recovery certificate.

## Responsibilities

1. Detect abnormal termination
2. Locate latest certified checkpoint
3. Validate checkpoint hashes
4. Restore runtime state
5. Restore queues
6. Restore experiments
7. Restore observatory
8. Restore replay position
9. Restore archaeology position
10. Restore certification state
11. Generate recovery report
12. Issue recovery certificate
13. Return runtime to operational state

## Detection Phase

### Abnormal Termination Detection

The Runtime Resurrection Engine detects:
- Missing shutdown marker file
- Incomplete journal entries
- Hash chain corruption
- Missing checkpoint records
- Process crash indicators
- Power failure signatures

### Shutdown Marker

On graceful shutdown, Tiannara creates a shutdown marker:
```
shutdown_marker: {
  timestamp: integer,
  shutdown_type: :graceful | :emergency,
  last_checkpoint_id: string,
  reason: string
}
```

If this marker is missing on startup, abnormal termination is detected.

## Checkpoint Location Phase

### Locate Latest Certified Checkpoint

Search for checkpoints across all nine domains:
1. Runtime State checkpoint
2. Knowledge Graph checkpoint
3. Ontology checkpoint
4. Experiments checkpoint
5. Evolution checkpoint
6. Certification checkpoint
7. Replay Position checkpoint
8. Archaeology Position checkpoint
9. Observatory State checkpoint

Find the latest checkpoint that:
- Has valid hash chain
- Is certified (not pending)
- Has all required fields
- Passes integrity verification

### Checkpoint Validation

For each checkpoint:
1. Verify hash matches state data
2. Verify previous checkpoint exists and is valid
3. Verify hash chain is unbroken
4. Verify domain-specific invariants
5. Verify certification reference exists

## Recovery Phase

### Runtime State Recovery

Restore:
- Supervisor trees
- Worker pools
- Process registries
- Queue states
- In-flight computations
- Configuration state

### Queue Recovery

Restore:
- Message queues
- Event queues
- Task queues
- Priority queues
- Dead letter queues

### Experiment Recovery

For each active experiment:
1. Load experiment journal
2. Verify hash chain
3. Identify last completed stage
4. Resume from that stage
5. Verify inputs and outputs
6. Continue execution

### Observatory Recovery

Restore:
- Current metrics
- Screen states
- Artifact storage
- Timeline events
- Search indices

### Replay Recovery

Restore:
- Current replay position
- Replay hash chain
- Last verified hash
- Replay checkpoints
- Replay state

### Archaeology Recovery

Restore:
- Archaeology records
- Archaeology hash chain
- Last verified hash
- Archaeology checkpoints

### Certification Recovery

Restore:
- Campaign results
- Production gate results
- Readiness indices
- Production certificates
- Certification lineage

## Report Generation

### Recovery Report

Generate comprehensive recovery report:
```
recovery_report: {
  recovery_id: string,
  shutdown_type: :power_failure | :crash | :kill | :unknown,
  shutdown_detected_at: integer,
  last_checkpoint_found: boolean,
  last_checkpoint_layer: string | nil,
  replay_integrity_verified: boolean,
  experiments_recovered: integer,
  experiments_lost: integer,
  queues_restored: boolean,
  runtime_state_rebuilt: boolean,
  recovery_status: :full_recovery | :partial_recovery | :recovery_failed,
  recovery_duration_ms: integer,
  recovery_timestamp: integer
}
```

### Recovery Certificate

Issue recovery certificate:
```
recovery_certificate: {
  certificate_id: string,
  recovery_id: string,
  timestamp: integer,
  status: :certified | :partial | :failed,
  knowledge_preserved: boolean,
  replay_intact: boolean,
  experiments_continued: boolean,
  signature: string
}
```

## Recovery Policies

### Full Recovery

When all checkpoints are valid:
- Restore all domains
- Resume all experiments
- Continue all operations
- Issue full recovery certificate

### Partial Recovery

When some checkpoints are invalid:
- Restore valid domains
- Skip invalid domains
- Resume valid experiments
- Issue partial recovery certificate
- Flag invalid domains for investigation

### Recovery Failed

When no valid checkpoints exist:
- Log failure
- Generate failure report
- Request manual intervention
- Do not issue certificate

## Recovery Metrics

- Recovery count
- Recovery success rate
- Recovery duration
- Knowledge loss (count)
- Experiment loss (count)
- Replay divergence (count)
- Checkpoint validation failures

## Integration

The Runtime Resurrection Engine integrates with:
- Checkpoint Engine (checkpoint location)
- Event Journal Engine (event replay)
- Archaeology Engine (recovery recording)
- Observatory (recovery display)
- Certification Engine (certificate issuance)

## Security

The Runtime Resurrection Engine shall:
- Never modify existing checkpoints
- Never modify existing journal entries
- Never modify existing archaeology records
- Only append new recovery records
- Maintain hash chain integrity
- Issue cryptographically signed certificates

## Acceptance Criteria

✓ Detects abnormal termination
✓ Locates latest certified checkpoint
✓ Validates checkpoint hashes
✓ Restores runtime state
✓ Restores queues
✓ Restores experiments
✓ Restores observatory
✓ Restores replay position
✓ Restores archaeology position
✓ Restores certification state
✓ Generates recovery report
✓ Issues recovery certificate
✓ Returns runtime to operational state
✓ Full, partial, and failed recovery paths
