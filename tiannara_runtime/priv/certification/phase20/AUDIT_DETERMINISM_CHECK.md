# Audit Determinism Check (Phase 20.96)

## Purpose

Verify determinism across every subsystem in the Constitutional OS — independent of the runtime. The auditor runs the same input through the deterministic specification multiple times and confirms identical outputs.

## Determinism Verification Method

For each subsystem:

```
1. Select a set of known input artifacts from cold storage
2. For each input, deterministically compute the expected output using the subsystem's specification
3. Repeat the computation 3 times (same input, same spec)
4. Verify all 3 computations produce identical output hashes
5. Compare against the recorded output in cold storage
6. Record: deterministic (yes/no), matches recorded (yes/no)
```

## Subsystems Checked

| Subsystem | Input From | Computation Method | Expected Output |
|-----------|-----------|-------------------|----------------|
| REA | Evidence records | Evidence analysis spec | Analysis result |
| Discovery | Domain constraints | Discovery algorithm spec | Discovery set |
| Research | Hypothesis + evidence | Research method spec | Research result |
| Mathematics | Expression + rules | Rewrite/canonicalize spec | Normalized expression |
| World Model | Observations | Model update spec | Model state |
| Cognitive | Task + context | Cognitive process spec | Cognitive output |
| Civilizational | Civ state | Governance process spec | Governance action |
| Constitutional | Const state | Evolution process spec | Evolution proposal |
| Engineering | Requirements | Engineering process spec | Implementation |
| Experimentation | Experiment design | Experiment process spec | Experimental result |
| Optimization | System state | Optimization process spec | Optimization suggestion |
| Self-integration | Proposal | Integration decision spec | Integration decision |

## Non-Determinism Detection

Check that no subsystem relies on:
- `DateTime.utc_now()` — must use deterministic timestamps
- `:rand` / `Enum.random` — must use hash-based pseudo-random
- `System.system_time` — must use `:erlang.unique_integer([:positive])`
- External network calls — must be deterministic or excluded
- File system state — must be deterministic or isolated
- Any form of non-deterministic concurrency

## Success Criteria

- Every subsystem produces identical output across 3+ independent runs
- All outputs match recorded cold storage values
- No non-deterministic primitives found in any specification
- Determinism score = 1.0
