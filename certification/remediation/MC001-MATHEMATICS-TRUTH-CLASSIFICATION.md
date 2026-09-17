# MC-001: Mathematical Truth Classification

**Date:** 2026-08-27
**Method:** Classified strictly from inspected source. A capability is REAL
only if it computes the stated mathematics and has executable evidence. A
`mock: true` tuple is NEVER upgraded to REAL. No capability is asserted above
its evidence.

## Classification Results

| Capability | Truth Class | Evidence (file:line) | Confidence |
|-----------|-------------|----------------------|------------|
| bayes_update/3 | REAL | math/probability.ex:5 | HIGH |
| KL divergence (kl_divergence/2) | REAL | foundations/information_theory.ex:15 | HIGH |
| Descriptive metrics (mean/variance/stdev) | PARTIAL | numerics.ex, math/statistics.ex | MEDIUM — duplicated + formula conflict |
| Inferential stats (t, cohens_d, required_n, qnorm) | REAL | numerics.ex:230-383 | HIGH |
| Interpolation (newton/linear) | REAL | numerics.ex:120-193 | HIGH |
| Cubic spline | PARTIAL | numerics.ex:199-219 | MEDIUM — falls back to linear |
| Numeric safety / uncertainty | REAL | numerics.ex:33-449 | HIGH |
| Sparse cosine similarity | REAL | math/math.ex:5 | HIGH |
| BFS shortest path | REAL | math/graphs.ex:3 | HIGH |
| Shannon entropy | PARTIAL (DUPLICATE) | probability.ex:15 + information_theory.ex:8 | MEDIUM — conflicting contracts |
| Gradient descent | THEATRICAL | optimization.ex:3 | HIGH |
| Nash equilibrium | THEATRICAL | optimization.ex:8 | HIGH |
| ODE solving (solve_ode) | THEATRICAL | calculus.ex:4 | HIGH |
| Formal invariant verification | THEATRICAL | formal_verification.ex:4 | HIGH |
| Math dashboard metrics | THEATRICAL | observatory/metrics/mathematics.ex:10 | HIGH |
| Physics domain metrics | THEATRICAL | domains/physics.ex:36 | HIGH |
| Symbolic reasoning | UNKNOWN | not found in inspected set | — |
| Proof verification | UNKNOWN | not found (formal_verification is mock) | — |
| Conjecture generation | UNKNOWN | not found | — |
| Counterexample search | UNKNOWN | not found | — |
| Formal representation | UNKNOWN | not found | — |
| Derivation | UNKNOWN | not found | — |
| Equation solving | PARTIAL | only solve_ode mock / numeric interpolation | MEDIUM |
| Mathematical discovery | NO | no reproducible discovery mechanism found | HIGH |

## Summary Counts (evidenced)

| Truth Class | Count |
|-------------|-------|
| REAL | 8 (bayes_update, kl_divergence, interpolation group, numeric-safety group, cosine, BFS, t-stats group) |
| PARTIAL | 4 (descriptive stats, cubic spline, shannon entropy, equation solving) |
| THEATRICAL | 6 (gradient descent, nash, solve_ode, verify_invariants, math-dashboard metrics, physics metrics) |
| UNKNOWN | 6 (symbolic, proof, conjecture, counterexample, formal, derivation) |
| NO | 1 (mathematical discovery) |
| DUPLICATE operations | 4 identified (entropy, variance, stdev, cosine) |

## Critical Findings

1. **Two canonical-domain modules depend on theatrical mocks:**
   - `Tiannara.Domains.Physics:18` simulate → `Calculus.solve_ode` (mock)
   - `Tiannara.Domains.Physics:29` validate → `FormalVerification.verify_invariants` (mock, always verified:true)

2. **Physics domain reports fabricated metrics** (`physics.ex:36`) — hardcoded
   numbers not derived from state. This is a claim of capability (e.g.,
   "evidence_quality_score: 0.88", "discoveries_this_cycle: 4") with no
   computational grounding.

3. **Conflicting statistical formulas** — `Numerics.variance` uses sample
   variance (n-1); `Math.Statistics.variance` uses population variance (n).
   Same operation, different results. Also `Math.Statistics.standard_deviation`
   (population) vs `Numerics.std_dev` (sample).

4. **Conflicting entropy contracts** — `Math.Probability.shannon_entropy`
   returns `{:ok, float}`; `Foundations.InformationTheory.shannon_entropy`
   returns `float()`.

5. **Formal verification is entirely mock** — `FormalVerification.verify_invariants`
   always returns verified:true with zero counterexamples. Any downstream
   "verification" claim inheriting from it is false confidence.

## Substrate Layer Assessment (from inspected evidence)

| Layer | Status | Evidence basis |
|-------|--------|----------------|
| Mathematical Representation | STRUCTURAL/UNKNOWN | cosine uses maps/lists; no formal AST found |
| Mathematical Operations | PARTIAL | real arithmetic modules exist, duplicated |
| Symbolic / Numerical Computation | PARTIAL | Numerics real; symbolic absent |
| Derivation | ABSENT | not found |
| Verification | THEATRICAL | FormalVerification is mock |
| Proof / Formal Reasoning | ABSENT | not found |
| Conjecture Generation | ABSENT | not found |
| Conjecture Testing | ABSENT | not found |
| Discovery | ABSENT | not found |
| Knowledge Integration | PARTIAL | metrics telemetry exists but dashboard fabricated |

## Bottom Line

The repository contains a genuine core of REAL numerical/statistical primitives
(notably `Tiannara.Numerics` and the probability/entropy/BFS functions), a
cluster of THEATRICAL mocks (optimization, ODE, formal verification) that are
actively consumed by the Physics canonical domain, fabricated metric reporting,
and no evidence of symbolic reasoning, proof, conjecture, or discovery
infrastructure above the primitive level.
