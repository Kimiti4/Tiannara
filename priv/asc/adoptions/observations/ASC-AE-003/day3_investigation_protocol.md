# AE-003 Read-Only Investigation Protocol

**Authorization:** Day-3 disposition (2026-08-22)  
**Constraint:** K-004 freeze remains active. No modifications.

## Objective
Establish why identical observation conditions increasingly cost more time, without changing production code or the observation protocol.

## Diagnostic Checklist

### 1. Time-Budget Profiling (Where are the 11.8s spent?)
- [ ] `RepairLibrary` ingestion phase timing
- [ ] Archive reading phase timing
- [ ] ETS insertion phase timing
- [ ] Forced GC / heap behavior during ingestion
- [ ] Supervision tree startup timing
- [ ] Unrelated application startup timing
- [ ] External process / system overhead (disk I/O, scheduler contention)

### 2. Day-0 → Day-1 → Day-3 Runtime Comparison
- [ ] Process startup timing breakdown
- [ ] Scheduler/runtime statistics (`:erlang.statistics(:scheduler)`)
- [ ] ETS table characteristics (type, protection, read/write patterns — not just size)
- [ ] Archive metadata (file size on disk, read latency)
- [ ] GC behavior (frequency, duration, heap growth)
- [ ] Service initialization timing for each supervised process

### 3. Hidden-State Search (Beyond the three visible metrics)
The fact that ETS=18016, archive=18016, mem≈48MB does NOT prove identical execution-path work.
- [ ] DETS file sizes on disk (even if in-memory ETS is flat)
- [ ] Process mailbox sizes across supervision tree
- [ ] Timer / queue accumulation (pending messages, unflushed buffers)
- [ ] Counters / accumulators outside the adopted library
- [ ] File descriptor count
- [ ] Port / socket accumulation
- [ ] Logger backlog

### 4. Monotonic Accumulation Search
Degradation is monotonic while the library's principal storage metrics are flat. Look specifically for:
- [ ] Append-only logs outside the measured archive
- [ ] Cache growth in non-ETS stores (DETS, disk, process state)
- [ ] Accumulating references (process dictionary, persistent terms)
- [ ] Fragmentation in ETS/DETS (not size, but internal structure)
- [ ] Compaction pressure on DETS files

### 5. Environmental / Host Factors
- [ ] Host machine load during each observation (CPU, disk I/O, memory pressure)
- [ ] Concurrent processes on the host
- [ ] Disk latency / I/O wait
- [ ] Network filesystem effects (if applicable)
- [ ] BEAM version / scheduler configuration drift

## Output Format
For each item investigated, record:

```text
observation:     [what was measured]
hypothesis:      [what it might explain]
supporting:      [evidence in favor]
contradicting:   [evidence against]
experiment:      [what would resolve it — post Day-7 if needed]
```

Do NOT patch. Do NOT modify. Record only.

## Integration with Day-7 Decision
The diagnostic findings will be combined with the Day-7 trajectory point to produce the final rollback/closure decision. If Day-7 returns to baseline, the diagnostic may reveal a transient host condition. If Day-7 persists or escalates, the diagnostic should have identified the causal mechanism (or narrowed it to a small set of testable hypotheses).

---
*End of Investigation Protocol*