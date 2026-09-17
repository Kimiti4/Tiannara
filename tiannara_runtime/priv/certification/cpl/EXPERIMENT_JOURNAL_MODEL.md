# Experiment Journal Model

## Purpose

The Experiment Journal Model defines the structure and behavior of experiment journals, which track every experiment through its lifecycle and enable resumption from the last completed stage.

## Journal Structure

Each experiment journal contains:

```
experiment_journal: {
  experiment_id: string,
  experiment_name: string,
  total_stages: integer,
  current_stage: integer,
  stages: [experiment_stage],
  inputs: map,
  output: map | nil,
  status: :pending | :running | :completed | :failed | :interrupted,
  created_at: integer,
  last_checkpoint_at: integer | nil,
  hash: string,
  checkpoint_root: string,
  replay_root: string,
  archaeology_root: string,
  certification_root: string
}
```

## Stage Structure

Each experiment stage contains:

```
experiment_stage: {
  stage_number: integer,
  stage_name: string,
  status: :pending | :running | :completed | :failed,
  started_at: integer | nil,
  completed_at: integer | nil,
  inputs: map,
  outputs: map | nil,
  hash: string | nil
}
```

## Stage Operations

### Start Stage

Marks a stage as running:
```
start_stage(journal, stage_number) -> updated_journal
```

### Complete Stage

Marks a stage as completed with outputs:
```
complete_stage(journal, stage_number, outputs) -> updated_journal
```

### Fail Stage

Marks a stage as failed:
```
fail_stage(journal, stage_number, reason) -> updated_journal
```

## Resume Logic

When resuming an experiment:
1. Load experiment journal
2. Verify hash chain integrity
3. Find first non-completed stage
4. Resume from that stage
5. Continue execution

## Journal Hashing

Each journal has a content-addressed hash:
```
journal_hash = SHA256(experiment_id + stages + status + created_at)
```

## Journal Checkpointing

Journals are checkpointed:
- On stage completion
- On experiment completion
- On experiment failure
- On periodic checkpoint
- On shutdown

## Journal Recovery

Recovery from journal:
1. Load journal from checkpoint
2. Verify hash integrity
3. Identify last completed stage
4. Resume from next stage
5. Continue execution

## Journal Metrics

Track:
- Total experiments
- Experiments by status
- Stages completed
- Stages failed
- Average completion time
- Resume count

## Integration

The Experiment Journal Model integrates with:
- Checkpoint Engine (journal checkpointing)
- Event Journal Engine (event recording)
- Runtime Resurrection Engine (experiment resumption)
- Observatory (experiment metrics)

## Security

Experiment journals shall:
- Never modify completed stages
- Only append new stages
- Maintain hash chain integrity
- Preserve all lineage

## Acceptance Criteria

✓ Complete journal structure
✓ Stage tracking and operations
✓ Resume logic from last completed stage
✓ Journal hashing and checkpointing
✓ Journal recovery support
✓ Journal metrics observable
