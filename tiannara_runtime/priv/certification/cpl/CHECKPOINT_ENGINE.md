# Checkpoint Engine

## Purpose

The Checkpoint Engine creates independent, recoverable snapshots of Tiannara's runtime state across nine independent domains. Each checkpoint is content-addressed, deterministic, and archaeologically reconstructable.

## Checkpoint Domains

### Domain 1: Runtime State
- Process identifiers
- Supervisor trees
- Worker pools
- Queue states
- In-flight computations

### Domain 2: Knowledge Graph
- All discoveries
- Hypotheses
- Principles
- Laws
- Theories
- Evidence chains
- Confidence scores

### Domain 3: Ontology
- All concepts
- Relationships
- Versions
- Merge/split history
- Deprecation records

### Domain 4: Experiments
- Active experiments
- Completed experiments
- Failed experiments
- Experiment journals
- Dependencies

### Domain 5: Evolution
- Evolution generations
- Law genomes
- Mutation records
- Crossover records
- Fitness scores

### Domain 6: Certification
- Campaign results
- Production gate results
- Readiness indices
- Production certificates
- Certification lineage

### Domain 7: Replay Position
- Current replay state
- Replay hash chain
- Last verified hash
- Replay checkpoints

### Domain 8: Archaeology Position
- Archaeology records
- Archaeology hash chain
- Last verified hash
- Archaeology checkpoints

### Domain 9: Observatory State
- Current metrics
- Screen states
- Artifact storage
- Timeline events

## Checkpoint Structure

Each checkpoint contains:
- Checkpoint ID (content-addressed)
- Timestamp
- Domain
- State hash
- Previous checkpoint ID
- State data (domain-specific)
- Certification reference
- Archaeology reference
- Replay root

## Checkpoint Creation

Checkpoints are created:
1. Periodically (configurable interval)
2. On significant events (discovery, experiment completion, certification)
3. On shutdown (graceful or emergency)
4. On manual request
5. On error conditions

## Checkpoint Verification

Each checkpoint must verify:
- State hash matches state data
- Previous checkpoint exists and is valid
- Hash chain is unbroken
- Domain-specific invariants hold

## Checkpoint Recovery

Recovery from checkpoint:
1. Locate latest valid checkpoint for domain
2. Verify hash chain integrity
3. Verify previous checkpoint exists
4. Restore state from checkpoint
5. Resume from checkpoint position
6. Generate recovery record

## Checkpoint Policies

### Periodic
- Configurable interval (default: 60 seconds)
- Non-blocking checkpoint creation
- State captured atomically

### Event-Triggered
- Discovery validated
- Experiment completed
- Certification issued
- Evolution generation completed

### Shutdown-Triggered
- Graceful shutdown: all domains checkpointed
- Emergency shutdown: critical domains only

### Manual
- On-demand checkpoint for any domain

### Emergency
- Immediate checkpoint on error detection

## Checkpoint Storage

Checkpoints stored in:
- Primary: Local disk (fast recovery)
- Secondary: Remote backup (disaster recovery)
- Tertiary: Immutable archive (long-term preservation)

## Checkpoint Metrics

- Checkpoint creation latency
- Checkpoint size per domain
- Checkpoint frequency
- Checkpoint success rate
- Checkpoint verification time

## Integration

The Checkpoint Engine integrates with:
- Runtime Resurrection Engine (recovery)
- Replay Engine (position tracking)
- Archaeology Engine (recording)
- Observatory (metrics display)

## Security

Checkpoints shall:
- Never modify existing state
- Only append new checkpoints
- Maintain hash chain integrity
- Preserve all lineage

## Acceptance Criteria

✓ Nine independent checkpoint domains
✓ Deterministic checkpoint creation
✓ Content-addressed checkpoint IDs
✓ Hash chain verification
✓ Independent domain recovery
✓ Multiple checkpoint policies
✓ Checkpoint metrics observable
✓ Integration with recovery and replay
