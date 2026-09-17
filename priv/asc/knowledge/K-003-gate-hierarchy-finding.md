# K-003 — Correctness-gate environmental sensitivity (AE-002 + AE-003)

Observations:
  AE-002: recursive_ingest eliminated (1 flaky failure, machine at 100% CPU).
  AE-003: BASELINE failed with 2 failures; bulk_ingest and chunked_bulk_ingest
  eliminated with 1 failure each — while the STRONGER real-archive integrity
  gate passed all four arms (count=6000, integrity=true).

Classification error identified:
  Environmental test instability was recorded indistinguishably from
  candidate defect. A weaker gate eliminated candidates that the stronger
  domain gate cleared.

Corrected records (epistemically accurate wording):
  bulk_ingest (AE-003):        eliminated by correctness gate under observed
                               environment; NOT conclusively falsified by
                               real-archive correctness evidence.
  chunked_bulk_ingest (AE-003): same.
  recursive_ingest (AE-002):    same (retroactive annotation).

Consequence for AE-003 verdict: NONE — bulk_gc_ingest's eligibility stands
independently and the contract was applied as registered. But the Pareto /
review_band machinery was never exercised; that remains an open validation
item for the next mission.

Design requirement (queued for runner v4 / AE-004):
  1. Gate hierarchy: domain-level integrity gate is the primary falsifier;
     unit-suite results are classified RELATIVE TO the baseline arm.
  2. Failure taxonomy: candidate_defect | environment_instability |
     inconclusive — elimination records must carry environment state.
  3. One bounded retry before elimination when the baseline arm also fails.

---
## Fresh datapoint — 2026-08-19 (AE-003 adoption run-3)

The flaky containment test (test/tiannara/asc/core/resilience_test.exs,
"repeated failure is CONTAINED") passed at 220.4 ms on the run that mattered.
Same class as the observations above — environment-sensitive, unrelated to
the candidate. Strengthens AE-004's justification: the scoped suite's
timing-sensitive containment checks are exactly the gate failures the
taxonomy must classify.