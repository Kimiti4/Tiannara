# K-004 — ASC evolution ordering policy

Status: POLICY
Date: 2026-08-19
Decided by: human (a.kimityr), recorded by ASC assistant

## Policy
1. No new autonomous capability is added to ASC before the measurement /
   adoption machinery itself is hardened.
2. The evolution system improves its own scientific reliability FIRST,
   before it increases its autonomy.

## Consequence
- AE-004 (Gate Fidelity, per K-003) precedes any further autonomous-capability
  work.
- Current posture: AE-003 observation window open (day1/day3/day7 ->
  CLOSURE.md); AE-004 designed but execution-gated on AE-003 closure.

## Instrument freeze (observation window ASC-AE-003)
- Do not modify the AE-004 gate, the observation instrument (asc.observe), or
  the adoption machinery during the AE-003 observation window unless a
  safety-critical defect is discovered.
- This preserves the causal boundary between the instrument that selected the
  candidate and the later knowledge that evaluates whether the instrument
  itself should change.
- If a genuine instrument defect is discovered: record it as a separate
  incident/amendment; do not silently change the frozen system.
- Escalation outside healthy bands: stop, record the observation, escalate to
  human judgment. No mid-window fixes of candidate or instrument.

## Closure criterion (day 7)
- If day1/day3/day7 all remain within the declared healthy bands, write
  priv/asc/adoptions/observations/ASC-AE-003/CLOSURE.md stating: ASC-AE-003 is
  empirically validated in production; the adoption of bulk_gc_ingest is
  considered stable; the instrument freeze is lifted.
- Only after CLOSURE.md exists does the AE-004 charter transition from
  DESIGNED to EXECUTION ELIGIBLE.

## Attached posture (for the record)
- Ω.R (OOM investigation): remains CLOSED. Evidence chain complete:
  OOM -> retention attribution -> static confirmation -> bounded remediation
  -> stress validation -> regression -> evidence package. repair_library is
  bounded at 20,000 entries; the archive remains append-only.
- F2 72-hour soak: remains DEFERRED unless deliberately authorized. It must
  not silently attach itself to the ASC progression.