# ASC-AE-004 — Gate Fidelity (charter)

Status: DESIGN ONLY — execution gated on ASC-AE-003 closure.
Source: K-003 (correctness-gate environmental sensitivity).
Date: 2026-08-19

## Objective
Make the correctness gate epistemically reliable — environmental instability
must never again be recorded as candidate falsification.

## Requirements
1. Failure taxonomy — candidate_defect | environment_instability |
   inconclusive, recorded with machine state at failure time.
2. Gate hierarchy — domain-level integrity gate (real-archive boot: count +
   integrity) is the primary falsifier; unit-suite results are classified
   relative to the baseline arm.
3. Baseline-relative rule — if the baseline arm fails concurrently,
   same-session candidate failures downgrade to inconclusive_environment,
   never elimination.
4. Bounded retry — exactly one retry of failed arms under the same protocol;
   retry outcomes recorded separately (no silent best-of-N selection).
5. Populated-front mission — a candidate field constructed so >=2 candidates
   reach measurement, exercising Pareto front + review_band end-to-end (the
   AE-003 open item).

## Constraints
- No change to any prior contract.
- No expansion of autonomous authority — adoption stays two-key.
- The runner changes themselves go through the same validation regime.

## Acceptance
- A seeded-replay of a flaky session classifies as environment_instability.
- The populated-front mission yields a >=2-member front with a correctly
  triggered verdict under oracle fidelity pass=true.