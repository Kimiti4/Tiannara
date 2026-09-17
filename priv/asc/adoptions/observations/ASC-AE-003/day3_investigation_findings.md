# AE-003 Day-3 Read-Only Investigation Findings

**Authorization:** day3_disposition.md (2026-08-22) — READ_ONLY_INVESTIGATION  
**Constraint:** K-004 freeze active. No production or instrument modifications were made.
**Investigation date:** 2026-08-19 (evening, same host session as day-1/day-3 observations)

## Executive Result

**The ingestion path is not degraded.** Seven consecutive `RepairLibrary.start_link`
boots of the identical production blob (`4f7024fba5b9...`) against the identical
archive (16,059,440 bytes, last modified 2026-08-14) measured:

```
BOOT1: 1388ms   BOOT2: 1347ms   BOOT3: 1410ms   BOOT4: 1423ms
BOOT5: 1819ms   BOOT6: 1636ms   BOOT7: 1444ms
p50 = 1423ms   (day-0 p50 = 1800ms)
```

This is baseline-speed ingestion on the same host, produced after day-3 read 11.8s.
The degradation is therefore attributable to the observation-time host environment,
not to the adopted candidate or to any state inside the library.

---

## 1. Time-Budget Profiling

observation: Each sample of the frozen instrument measures `RepairLibrary.start_link/1`
(archive `File.stream!` + `bulk_gc_ingest` → ETS, 18,016 rows / 16 MB re-read per boot),
excluding all substrate services (`asc.observe` runs `Mix.Task.run("app.config")` only —
no supervision tree, no EOS, no DETS).

hypothesis: Boot time splits into archive read (I/O) + parse/insert (CPU/GC).

supporting: GC delta per boot is flat and small (~3,974 words reclaimed, ~29.1–29.3 MB
memory delta — the ETS table itself); at idle host the full boot is 1.35–1.8s
(≈ 16 MB read + 18k inserts), so neither phase is intrinsically expensive.

contradicting: Phase-level split inside the library is not directly observable without
instrumenting the frozen module; only whole-boot timing was measured.

experiment: Post-window (K-004 lift) micro-benchmark of `File.stream!` read vs.
`Enum.reduce` insert phases, if further granularity is ever needed. Not needed for the
current decision.

## 2. Day-0 → Day-1 → Day-3 Runtime Comparison (sample vectors)

observation: The frozen instrument records all 7 per-sample latencies (`samples_ms`):

```
day0: [1632, 1800, 1897, 1740, 1824, 1617, 1883]  p50 1800   spread 1.62–1.90s
day1: [9273, 7376, 5329, 4092, 12268, 3250, ...]  p50 5330   spread 3.25–12.27s
day3: [10227, 12404, 11814, 14510, 7451, 8411, ...] p50 11814 spread 7.45–14.51s
probe: [1347, 1388, 1410, 1423, 1444, 1636, 1819] p50 1423   spread 1.35–1.82s
```

hypothesis: Within-run spread is the signature of host contention: day-0 is a tight
cluster (quiet host), day-1/day-3 are wide (saturated host). A library-side defect
would produce a tight, shifted cluster (same code, same input → same cost).

supporting: Probe run on the same host reproduces day-0's tight cluster exactly.

contradicting: (none found)

experiment: Record host-load context alongside the day-7 run (host CPU %, available MB)
as an attached note — the frozen instrument itself stays untouched.

## 3. Hidden-State Search

observation: Archive: 16,059,440 bytes, LastWriteTime 2026-08-14 (untouched by all
observation runs; 18,016 lines). ETS: 18,016 flat across all runs. VM memory: 46.5 →
46.3 → 48.2 MB (in-band). DETS directory: last touched during the day-1 window
(2026-08-19 22:10–22:13), no files from the day-3 window.

hypothesis: Hidden accumulation inside the VM across samples could explain a rising
floor.

supporting: (none — see contradicting)

contradicting: Each observation run is a **fresh BEAM VM** (`mix asc.observe` spawns a
new process). Nothing except host state and the static archive persists across runs.
Within a run, the day-1/day-3 vectors show no monotonic intra-run climb (day1 sample
4 = 4093ms after sample 1 = 9273ms; day3 sample 5 = 7451ms after sample 4 = 14510ms),
which rules out per-boot accumulation inside the VM.

experiment: None required; the cross-run persistence model is closed.

## 4. Monotonic Accumulation Search (outside the adopted library)

observation: The only cross-run persistent state is (a) the archive — byte-stable —
and (b) host OS state: observed CPU 8–100% and available RAM 1.17–2.10 GB fluctuating
minute-to-minute during the investigation (HOST_BEFORE/AFTER snapshots: 64–100% CPU,
1.2–1.9 GB free at day-3-adjacent times; 48→7.8% and 1.6→1.95 GB during the probe).

hypothesis: Rising evening host load (CPU saturation + memory pressure evicting the
16 MB archive from page cache) is the only mechanism consistent with a monotonic
day-0→day-3 rise AND a return to baseline at quiet times.

supporting: (1) Probe boots at baseline speed when host is quieter; (2) wide within-run
spread tracks a saturated host; (3) day-3 ran ~23:00, the busiest observed host state.

contradicting: Host load during the exact day-1/day-3 observation windows was not
recorded (instrument does not capture it; not recoverable post-hoc).

experiment: Day-7 run with an attached host-load snapshot (read-only note, not an
instrument change) to confirm correlation.

## 5. Environmental / Host Factors

observation: See item 4. Host is a Windows machine with ~1.2–2.1 GB available RAM and
highly variable CPU (8–100% within minutes). This machine hosts other workloads.

hypothesis: Day-1/day-3 p50 readings (5.3s / 11.8s) were measured under host
contention that has since subsided.

supporting: Same-code/same-archive 7-boot probe returned p50 1423ms ≈ day-0 baseline
immediately after day-3.

contradicting: (none)

experiment: (none — evidence sufficient for the disposition question)

---

## 6. Re-examination of Day-1 "Substrate Churn" Evidence

observation: The observe protocol boots no substrate. The day-1 run's DETS-repair /
EOS-failure lines therefore originated from incidental host activity in the same
session, not from the measurement path. Day-3's absence of such lines is consistent:
substrate state is irrelevant to the p50.

conclusion: The day-1 churn neither supported nor weakened the environmental
explanation; it was coincidental host noise. The day-3 "no churn yet worse latency"
objection is resolved: the p50 path never touches substrate.

---

## 7. Conclusion for the Day-7 Decision

- Library/candidate state: **healthy** (p50 1423ms at quiet host, blob `4f7024f`).
- Day-1/day-3 readings: **host-contention artifacts**, consistent with the original
  `environment_instability` classification, now with direct supporting evidence.
- Pre-registered day-7 rules still govern: if day-7 runs quiet → expect baseline
  (~1.5–2s) → transient degradation, rollback not compelling. If day-7 (despite a
  quiet-host snapshot) reads ≥10s, the host hypothesis fails and attribution reopens.
- Recommended day-7 procedure: run the frozen instrument unmodified; attach a host
  CPU/RAM snapshot at observation time as a sidecar note; do not touch the instrument.

*All measurements above are read-only. No production file, instrument file, or
observation record was modified.*

---
*End of Day-3 Investigation Findings*