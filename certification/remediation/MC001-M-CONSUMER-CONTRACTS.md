# MC-001-M: Consumer Contract Report

**Gate:** MC-001-M
**Status:** COMPLETE
**Date:** 2026-08-27

For each changed producer, this report records the current contract, every
caller, the caller expectation, failure mode, required adaptation, resulting
contract, and evidence. This is mandatory to establish that consumers were
updated atomically and that no caller treats unavailable as success.

---

## P1. `Tiannara.Foundations.FormalVerification.verify_invariants/2`

| Field | Value |
|-------|-------|
| **Producer** | `FormalVerification.verify_invariants(model_ast, invariants)` |
| **Current contract (pre-mutation)** | `{:ok, %{verified: true, counterexamples: [], mock: true}}` (always) |
| **Resulting contract (post-mutation)** | `{:error, :formal_verification_unavailable}` |
| **Caller** | `Physics.validate/1` (`physics.ex:28`) |
| **Caller expectation** | `result()` :: `{:ok, term()}` or `{:error, term()}`; prior value `{:ok, %{verified: true}}` |
| **Failure mode** | previously inherits `verified: true` (false confidence) |
| **Required adaptation** | none — error propagates through `validate/1` return |
| **Evidence** | `physics.ex:28-30` |

| **Caller** | `Engineering.validate/1` (`engineering.ex:22`) |
| **Caller expectation** | `result()` |
| **Failure mode** | previously inherits `verified: true` |
| **Required adaptation** | none — error propagates |
| **Evidence** | `engineering.ex:22-24` |

| **Caller** | `Architecture.validate/1` (`architecture.ex:21`) |
| **Caller expectation** | `result()` |
| **Failure mode** | previously inherits `verified: true` |
| **Required adaptation** | none — error propagates |
| **Evidence** | `architecture.ex:21-23` |

| **Caller** | `Aerospace.validate/1` (`aerospace.ex:22`) |
| **Caller expectation** | `result()` |
| **Failure mode** | previously inherits `verified: true` |
| **Required adaptation** | none — error propagates |
| **Evidence** | `aerospace.ex:22-24` |

| **Caller** | `autonomous_discovery.ex` `execute_experiment/1` (`autonomous_discovery.ex:32`) |
| **Caller expectation** | previously `{:ok, validation} = domain_module.validate(...)`; `if validation.verified` |
| **Failure mode** | **MATCH ERROR / false-confidence risk** — the old `{:ok, validation} = ...` pattern-match would crash on `{:error, ...}`; `validation.verified` treated unavailable as success |
| **Required adaptation** | **REWRITTEN** to explicit `case`: handle `{:ok, %{verified: true}}`, `{:ok, validation}`, `{:error, reason}` |
| **Resulting contract** | unavailable verification → `{:ok, :validation_unavailable, reason}`; never integrated |
| **Evidence** | `autonomous_discovery.ex:35-51` |

---

## P2. `Tiannara.Foundations.Mathematics.Calculus.solve_ode/3`

| Field | Value |
|-------|-------|
| **Producer** | `Calculus.solve_ode(equation, initial_conditions, time_span \\ 1.0)` |
| **Current contract (pre-mutation)** | `{:ok, %{trajectory: mock list, steps: 1000, mock: true}}` |
| **Resulting contract (post-mutation)** | `{:error, :ode_solver_unavailable}` |
| **Caller** | `Physics.simulate/2` (`physics.ex:17`) |
| **Caller expectation** | `result()`; previously `{:ok, %{trajectory: [...]}}` |
| **Failure mode** | previously fabricated trajectory, indistinguishable from real simulation |
| **Required adaptation** | none — error propagates through `simulate/2` |
| **Evidence** | `physics.ex:17-19` |

| **Caller** | `autonomous_discovery.ex` `execute_experiment/1` |
| **Caller expectation** | `{:ok, sim_result}` |
| **Failure mode** | `{:ok, sim_result} = ...` would crash on `{:error, ...}` |
| **Required adaptation** | **REWRITTEN** — `case domain_module.simulate(...)` handles `{:error, reason}` |
| **Resulting contract** | unavailable simulation → `{:ok, :simulation_unavailable, reason}` |
| **Evidence** | `autonomous_discovery.ex:35` |

---

## P3. `Tiannara.Math.Optimization.gradient_descent/4`

| Field | Value |
|-------|-------|
| **Producer** | `Optimization.gradient_descent(objective_fn, grad_fn, initial_params, opts \\ [])` |
| **Current contract (pre-mutation)** | `{:ok, %{params: ..., loss: 0.0, iterations: ..., mock: true}}` |
| **Resulting contract (post-mutation)** | `{:error, :gradient_descent_unavailable}` |
| **Caller** | **none** (production) |
| **Caller expectation** | n/a |
| **Failure mode** | n/a |
| **Required adaptation** | none |
| **Evidence** | source search of `lib/` returned no caller |

---

## P4. `Tiannara.Math.Optimization.nash_equilibrium/2`

| Field | Value |
|-------|-------|
| **Producer** | `Optimization.nash_equilibrium(payoff_matrix, entropy)` |
| **Current contract (pre-mutation)** | `{:ok, %{equilibrium: :mixed_strategy, payoff: 0.5, entropy: ..., mock: true}}` |
| **Resulting contract (post-mutation)** | `{:error, :nash_equilibrium_unavailable}` |
| **Caller** | `Economics.evaluate/1` (`economics.ex:10`) |
| **Caller expectation** | `result()`; previously `{:ok, %{equilibrium: ...}}` |
| **Failure mode** | previously fabricated `:equilibrium` |
| **Required adaptation** | none — error propagates through `evaluate/1` |
| **Evidence** | `economics.ex:10-13` |

---

## P5. `Tiannara.Domains.Physics.metrics/0`

| Field | Value |
|-------|-------|
| **Producer** | `Physics.metrics/0` |
| **Current contract (pre-mutation)** | map with hardcoded fabricated literals (142/38/4/0.88/...) |
| **Resulting contract (post-mutation)** | truthful state-derived map with `metrics_source: :state_derived` |
| **Caller** | `research_director.ex:59` (`get_all_metrics/0`) |
| **Caller expectation** | map (name => metrics-map) |
| **Failure mode** | previously propagated fabricated counts downstream |
| **Required adaptation** | none — map shape preserved; values now truthful |
| **Evidence** | `research_director.ex:56-61` |

| **Caller** | `autonomous_discovery.ex:51` (`collect_domain_metrics/0`) |
| **Caller expectation** | map (module => metrics-map) |
| **Failure mode** | previously propagated fabricated counts |
| **Required adaptation** | none — map shape preserved |
| **Evidence** | `autonomous_discovery.ex:46-55` |

| **Caller** | `tool_builder.ex:157` (`metrics = #{module}.metrics()`) |
| **Caller expectation** | map |
| **Required adaptation** | none — map shape preserved |
| **Evidence** | `tool_builder.ex:157` |

| **Caller (downstream)** | `BottleneckDetector.analyze_pipeline/1` (`meta_science/bottleneck_detector.ex:10`) |
| **Caller expectation** | reads `.hypotheses_generated`, `.experiments_completed` |
| **Required adaptation** | none — both fields remain present (0) |

---

## P6. `Tiannara.Observatory.Metrics.Mathematics.get_dashboard_data/0`

| Field | Value |
|-------|-------|
| **Producer** | `get_dashboard_data/0` |
| **Current contract (pre-mutation)** | map of hardcoded subsystem metrics |
| **Resulting contract (post-mutation)** | `{:error, :mathematics_dashboard_unavailable}` |
| **Caller** | **none** (dead code — confirmed by source search) |
| **Caller expectation** | n/a |
| **Failure mode** | n/a |
| **Required adaptation** | none |
| **Evidence** | source search of `lib/` returned no caller |

---

## Synthesis

- All consumers whose control flow assumed theatrical success were updated
  **atomically** within this mutation (notably `autonomous_discovery.ex`).
- No caller treats unavailable as success or as fabricated `verified: false`.
- No REAL math primitive contract (e.g. `bayes_update` `{:ok,_}`) was changed.
- Every availability change is either propagated as an explicit `{:error, reason}`
  or represented as an explicit availability marker in a preserved map shape.
