# K-001 — Falsified hypothesis: parallel worker bootstrap

Hypothesis: Parallelizing four trivial ASC worker startups (Task.async_stream)
improves boot latency.

Prediction: p50 boot latency improves >= 15%.

Initial evidence (ASC-AE-001 C5, single-shot, cross-environment): +15.3%. ACCEPT under first-PASS rule.

Confounding identified: baseline measured in main-repo VM; candidate measured
in fresh sandbox VM. Environment, not treatment, carried the difference.

Verification (paired, counterbalanced, 15 rounds x n=15, pre-registered):
  median improvement: -24.39%
  95% CI: [-48.78%, -19.61%]
  negative rounds: 13/15
  correctness: 6/6 PASS; memory: unchanged

Updated conclusion: REJECTED for this workload. Concurrency primitives add
scheduling overhead exceeding the cost of four trivial sequential starts.

Generalized principles:
  P1. Single-shot cross-environment comparisons confound environment with treatment.
  P2. Near-boundary gate passes require confidence-interval confirmation before adoption.
  P3. A verification instrument that overturns its own system's ACCEPT is the
      system working, not failing.

Lineage: asc-ae001-d1_parallel_boot (preserved, never merged).