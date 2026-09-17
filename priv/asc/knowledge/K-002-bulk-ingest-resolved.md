# K-002 RESOLUTION — Transient memory retention confirmed (World 1)

Observation (ASC-AE-002):
  bulk_ingest: latency +78.7%, retained memory +31.8% (~8.6 MB in the library
  process, consistent across 15 rounds) -> rejected by K-AE002 resource gate.

Hypothesis (K-002 open question):
  The +8.6 MB is transient, GC-recoverable garbage produced by constructing
  the full row list at once — not a steady-state cost of bulk ingestion.

Intervention (ASC-AE-003, candidate bulk_gc_ingest):
  Bulk ingestion + one forced GC at end of init.

Result (paired interleaved, 15 rounds x n=15, contract K-AE003,
        oracle fidelity pass=true):
  latency:        +85.0%   CI [0.81, 0.90], 0/15 negative rounds
  transient peak:  -0.07%
  retained:        +0.03%  CI [0.0002, 0.0003]
  hard gate (real-archive boot): count=6000, integrity=true

Conclusion:
  World 1 — transient. The AE-002 memory penalty was not an unavoidable
  steady-state cost; a forced GC at end of init removes the measured retained
  component while preserving the latency gain.

Generalized causal principle:
  A large post-operation BEAM memory footprint is not evidence of retention
  until it survives forced GC. Resource gates must separate retained vs
  transient components before adjudicating a candidate.

Status: bulk_gc_ingest = accept_eligible under K-AE003.
Adoption requires human authorization. Lineage preserved:
asc-ae003-bulk_gc_ingest.

---
## Amendment — 2026-08-18 (post-adoption)

Adoption: COMPLETED via the controlled two-key pathway (mix asc.adopt).
  Authorization: a.kimityr, 2026-08-18 (artifact sha256 in adoption record)
  Production file: lib/tiannara/asc/crucible/repair_library.ex (blob 4f7024f)
  Tags: asc-pre-adoption-ASC-AE-003, asc-adopted-ASC-AE-003
  Record: priv/asc/adoptions/ASC-AE-003-adoption.eterm

Day-0 reference (priv/asc/adoptions/observations/ASC-AE-003/day0.eterm):
  ingestion p50 1800 ms | ets_size 18016 | archive_lines 18016 | mem 46.5 MB

Operational validation: OPEN (day1/day3/day7 + CLOSURE.md).
  Adopted != validated over time. Healthy bands anchored to day-0:
  p50 +/-25%, ETS <= 20000, VM mem +/-15%, tests green.

Cross-environment note: the dev-smoke ~43s reading and the day-0 1.8s are not
compared. Per the AE-001 same-environment rule, day-0 is the sole reference.