# AE-004 Phase C: Causal Discrimination Protocol

## Objective
Prove that correcting the DETS API contract (F12) resolves the false EOS emergency (F9) **and** that the system retains its ability to detect genuine failures.

## Test 1: Specificity (The False Positive Check)
**Condition:** Boot the isolated test topology with all services (DETS, EventStore, ExecutiveMemory) fully healthy and operational.
**Action:** Query `EventStore.healthy?/0`, `ExecutiveMemory.health/0`, and the EOS state classifier.

| Metric | Baseline (Expected) | Candidate (Required for Pass) |
|--------|---------------------|-------------------------------|
| `EventStore.healthy?/0` | `false` (F12 bug) | `true` |
| `ExecutiveMemory.health/0` | `:unhealthy` (F12 bug) | `:healthy` |
| EOS Classification | `:emergency` (F9 bug) | `:healthy` |

*If Candidate EOS remains `:emergency` despite health returning `true`, F9 has an independent root cause, and `candidate_f12_plus_eos_adjustment` must be evaluated.*

## Test 2: Sensitivity (The False Negative Check)
**Condition:** Boot the isolated test topology, then inject a catastrophic fault (e.g., `Process.exit(dets_pid, :kill)` or corrupt the DETS file on disk).
**Action:** Query the same health and EOS endpoints.

| Metric | Baseline (Expected) | Candidate (Required for Pass) |
|--------|---------------------|-------------------------------|
| `EventStore.healthy?/0` | `false` | `false` |
| EOS Classification | `:emergency` | `:emergency` |

*CRITICAL GATE: If the Candidate returns `:healthy` or suppresses the `:emergency` classification during a genuine fault, the candidate is **REJECTED**. We will not accept a fix that blinds the organism to actual damage.*

## Test 3: Recovery Honesty (Regression Check)
**Condition:** Restart the topology after the injected fault.
**Action:** Verify EOS transitions from `:emergency` -> `:recovering` -> `:healthy`.
**Requirement:** The candidate must not get "stuck" in a false emergency state post-recovery (which would regress F9).