# MC-001: Mathematical Capability Inventory

**Date:** 2026-08-27
**Method:** Actual source inspection under `lib/tiannara/`. Every entry cites
the inspected `file:line`. Capabilities not located in source are NOT listed
as existing. No capability is asserted above its evidence.

## Core Mathematical Modules (inspected)

| # | Module | File | Functions (inspected) | Return contract |
|---|--------|------|----------------------|-----------------|
| 1 | Tiannara.Math | math/math.ex | cosine_similarity/2 | float() |
| 2 | Tiannara.Math.Probability | math/probability.ex | bayes_update/3, shannon_entropy/1 | {:ok, float} \| {:error, atom} |
| 3 | Tiannara.Math.Statistics | math/statistics.ex | mean/1, variance/1, standard_deviation/1 | {:ok, float} \| {:error, atom} |
| 4 | Tiannara.Math.Graphs | math/graphs.ex | shortest_path/3 | {:ok, [node]} \| {:error, atom} |
| 5 | Tiannara.Math.Optimization | math/optimization.ex | gradient_descent/4, nash_equilibrium/2 | {:ok, mock} |
| 6 | Tiannara.Numerics | numerics.ex | error_mode/1, safe_round/2, safe_divide/2, clamp/3, mean/1, std_dev/1, newton_interpolate/2, linear_interpolate/3, cubic_spline_interpolate/2, t_statistic/2, variance/1, cohens_d/2, round/2, required_n/4, qnorm/1, with_uncertainty/2, value/1, get_error_mode/1, format/1, interpolation_error/3 | {:ok, ...} \| {:error, atom} |
| 7 | Tiannara.Foundations.InformationTheory | foundations/information_theory.ex | shannon_entropy/1, kl_divergence/2 | float() |
| 8 | Tiannara.Foundations.Mathematics.Calculus | foundations/mathematics/calculus.ex | solve_ode/3 | {:ok, %{mock: true}} |
| 9 | Tiannara.Foundations.FormalVerification | foundations/formal_verification.ex | verify_invariants/2 | {:ok, %{verified: true, mock: true}} |
| 10 | Tiannara.Observatory.Metrics.Mathematics | observatory/metrics/mathematics.ex | get_dashboard_data/0 | %{hardcoded metrics} |

## Detailed Capability Inventory

### R1. Bayesian update — Tiannara.Math.Probability:5
- `bayes_update/3`: P(H|E) = (P(E|H)*P(H))/P(E); guards evidence_prob > 0; returns `{:ok, posterior}`; else `{:error, :evidence_probability_zero}`.
- Implementation: REAL (inspected arithmetic).
- Determinism: deterministic.
- Failures: handles evidence_probability_zero explicitly.

### R2. Shannon entropy — Tiannara.Math.Probability:15 AND Tiannara.Foundations.InformationTheory:8
- Probability variant: `{:ok, entropy}` (telemetry-wrapped).
- InformationTheory variant: plain `float()`.
- **Conflicting return contracts for the same mathematical operation** — DUPLICATE with contract divergence.

### R3. KL divergence — Tiannara.Foundations.InformationTheory:15
- `kl_divergence/2`: real arithmetic over zip of P,Q. Returns float.
- Implementation: REAL.

### R4. Descriptive statistics
- Tiannara.Math.Statistics: mean/1, variance/1, standard_deviation/1 (population variance, `/n`).
- Tiannara.Numerics: mean/1, std_dev/1, variance/1 (sample variance, `/(n-1)`).
- **CONFLICTING variance/stdev formulas** between the two module families.
- Implementation: REAL, but DUPLICATE + CONFLICTING formula semantics.

### R5. Inferential statistics — Tiannara.Numerics
- t_statistic/2, cohens_d/2, required_n/4, qnorm/1, interpolation_error/3.
- Implementation: REAL arithmetic (inspected).

### R6. Interpolation — Tiannara.Numerics
- newton_interpolate/2 (divided differences + Horner), linear_interpolate/3, cubic_spline_interpolate/2.
- Implementation: REAL, though cubic_spline falls back to linear interpolation on the nearest interval (documented in code comments) — PARTIAL scope.

### R7. Numeric safety / uncertainty — Tiannara.Numerics
- error_mode/1, with_uncertainty/2, safe_round/2, safe_divide/2, clamp/3, round/2, value/1, get_error_mode/1, format/1.
- Implementation: REAL; surfaces error modes explicitly.

### R8. Sparse-vector cosine similarity — Tiannara.Math:5
- map-based dot/magnitude; returns float (0.0 on zero magnitude).
- Implementation: REAL.

### R9. Graph BFS shortest path — Tiannara.Math.Graphs:3
- BFS over adjacency map; returns `{:ok, path}` or `{:error, :no_path}`.
- Implementation: REAL.

## Theatrical / Mock Capabilities (inspected)

### T1. Gradient descent — Tiannara.Math.Optimization:3
- Returns `{:ok, %{params: initial_params, loss: 0.0, iterations: ..., mock: true}}`.
- Does NOT compute descent. THEATRICAL.
- Consumer: none found in production scan.

### T2. Nash equilibrium — Tiannara.Math.Optimization:8
- Returns `{:ok, %{equilibrium: :mixed_strategy, payoff: 0.5, mock: true}}`.
- Does NOT compute equilibrium. THEATRICAL.
- Consumer: none found.

### T3. ODE solving — Tiannara.Foundations.Mathematics.Calculus:4
- `solve_ode/3` returns `{:ok, %{trajectory: mock_trajectory(), steps: 1000, mock: true}}`.
- Does NOT integrate. THEATRICAL.
- **Consumer found: Tiannara.Domains.Physics:18 `simulate/2`** delegates to this mock.

### T4. Formal invariant verification — Tiannara.Foundations.FormalVerification:4
- `verify_invariants/2` returns `{:ok, %{verified: true, counterexamples: [], mock: true}}` unconditionally.
- Fetch simulated "SMT solving and formal invariant checking" — THEATRICAL.
- **Consumer found: Tiannara.Domains.Physics:29 `validate/2`** — always reports verified:true via mock.

### T5. Math dashboard metrics — Tiannara.Observatory.Metrics.Mathematics:10
- `get_dashboard_data/0` returns hardcoded literal metrics (jobs/latency_ms/cache_hit per subsystem). Not computed from events (though handle_event inserts real durations into ETS, the dashboard returns fabricated constants). THEATRICAL metrics.

### T6. Physics domain metrics — Tiannara.Domains.Physics:36
- `metrics/0` returns hardcoded fabricated values: active_hypotheses: 142, open_experiments: 38, discoveries_this_cycle: 4, knowledge_growth_rate: 0.05, evidence_quality_score: 0.88. Not computed. THEATRICAL metrics.

## Stub / Empty-Stub Capabilities (inspected)

### S1. Tiannara.Domains.Physics
- `discover/1` → `{:ok, %{domain: :physics, discoveries: [], context: context}}` (empty).
- `generate_hypotheses/1` → `{:ok, []}`.
- `design_experiments/1` → `{:ok, []}`.
- `translate/1` → `{:ok, %{engineering_applications: []}}` (empty).
- These are scaffold stubs, not capability.

## Duplication Matrix (inspected)

| Operation | Implementations | Contract | Formula |
|-----------|----------------|----------|---------|
| shannon_entropy | Math.Probability:15, Foundations.InformationTheory:8 | {:ok,float} vs float | same |
| variance | Numerics:254, Math.Statistics:6, REA.Causal.Channel:89 | {:ok,float} / {:ok,float} / float | sample(n-1) vs population(n) vs population(n) |
| std_dev / standard_deviation | Numerics:99, Math.Statistics:12 | sample(n-1) vs population(n) | CONFLICT |
| cosine_similarity | Math:5 (map), OrbitMemoryEcology:163 (list) | map vs list input | same |

## Consumer Map (inspected)

| Capability | Consumer (file:line) |
|-----------|----------------------|
| Calculus.solve_ode/3 (THEATRICAL) | Tiannara.Domains.Physics:18 |
| FormalVerification.verify_invariants/2 (THEATRICAL) | Tiannara.Domains.Physics:29 |
| Probability.bayes_update/3 (REAL) | Tiannara.Domains.Physics:13 |
| Math.Optimization (THEATRICAL) | none found |
| Math.Statistics (REAL) | none found (canonical stats path appears to be Numerics) |
| Math.Graphs.shortest_path/3 (REAL) | (no direct consumer recorded here) |

## Not-Detected Capabilities

The following substrate capabilities were searched but NOT located as real
modules in `lib/tiannara/` (classified UNKNOWN/ABSENT — no evidence found,
not assumed absent from breadth alone; each was not found in the inspected set):

| Capability | Evidence |
|-----------|----------|
| Symbolic reasoning engine | not found in inspected scan |
| Theorem prover / proof checker | not found (FormalVerification is mock) |
| Conjecture generation | not found |
| Counterexample search | not found |
| Formal mathematical language / AST | not found |
| Derivation engine | not found |
