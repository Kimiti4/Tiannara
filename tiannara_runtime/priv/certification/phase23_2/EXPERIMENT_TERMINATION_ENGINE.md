# Experiment Termination Engine

## Purpose

The Experiment Termination Engine governs the termination of experiments — whether by successful completion, irrecoverable failure, cancellation, or constitutional order. Every termination is recorded immutably and is archaeologically traceable.

## Termination Types

| Type | Description | Evidence Preserved |
|------|-------------|-------------------|
| Completed | Experiment reached all success criteria | Full results archived |
| Failed | Experiment encountered unrecoverable error | Error state preserved |
| Inconclusive | Experiment finished without clear result | Data preserved, marked uncertain |
| Cancelled | Experiment terminated before completion | Partial results preserved |
| Superseded | Better experiment replaced this one | Original preserved, cross-referenced |
| Constitutional | Terminated by constitutional directive | Directive recorded |

## Termination Lifecycle

```
Initiation → Review → Approval → Termination → Archival
```

1. **Initiation**: Triggered by completion, failure detection, or external directive
2. **Review**: Termination justification assessed
3. **Approval**: Constitutional approval obtained (required for non-completion)
4. **Termination**: Experiment stopped, resources released
5. **Archival**: All data preserved in CPL

## Termination Criteria

### Successful Completion
- All hypotheses tested
- All data collected
- All success criteria met
- Results validated

### Failure
- Irrecoverable error condition
- Resource exhaustion beyond allocation
- Constitutional violation during execution
- Safety constraint violation

### Cancellation
- Superseded by higher-priority experiment
- Hypothesis proven impossible to test
- Research program redirected
- Resource reallocation required

### Constitutional Termination
- Directive from governance layer
- Constitutional amendment affects experiment
- Safety or ethical concern identified

## Termination Record

```
ExperimentTermination {
  termination_id: content-addressed,
  experiment_id: reference,
  type: enum,
  justification: string,
  partial_results: experiment_results (optional),
  failure_reason: string (optional),
  approval: constitutional_reference,
  preserved_data: [data_reference],
  termination_hash: string,
  timestamp: integer
}
```

## Constitutional Guarantees

- No experimental data is ever deleted
- Failed experiments are preserved in full
- Termination decisions are replayable
- Termination archaeology reconstructs why experiments ended
- All terminations have constitutional justification
