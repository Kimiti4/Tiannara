# MC-004-A0 — Physics Inventory

**Gate:** MC-004-A0 (Reconciliation) — **Date:** 2026-08-31 — **Mode:** READ-ONLY
**Initiative:** Tiannara Remediation + Substrate Integration

## 1. Canonical boundary

- `lib/tiannara/domains/canonical_registry.ex` — `:physics` is a member of the canonical domain list (line 34) and is bound to `Tiannara.Domains.Physics` (`defp domain_module(:physics), do: Tiannara.Domains.Physics`, line 220). Exactly 20 canonical domains are registered (foreign-key archaeology: one canonical registry, no duplicate owner).
- Domain behaviour contract: `lib/tiannara/domains/domain.ex:17-24` — 8 callbacks (`discover`, `evaluate`, `simulate`, `generate_hypotheses`, `design_experiments`, `validate`, `translate`, `metrics`), all `result()`-shaped (`{:ok, term} | {:error, term}`).

## 2. Domain module inventory (`lib/tiannara/domains/physics.ex`, `Tiannara.Domains.Physics`)

| Callback | File:line | Behavior | Classification |
|---|---|---|---|
| `discover/1` | physics.ex:9 | Always `{:ok, %{domain: :physics, discoveries: [], context}}` | HONEST-EMPTY (real code, zero output) |
| `evaluate/1` | physics.ex:12-14 | `Probability.bayes_update/3` on `%{prior, likelihood, evidence}` | REAL (substrate is REAL) |
| `simulate/2` | physics.ex:17-18 | `Calculus.solve_ode(hypothesis.equations, context.boundary_conditions, 1.0)` | UNAVAILABLE (solver decommissioned MC-001-M) |
| `generate_hypotheses/1` | physics.ex:21-22 | `{:ok, []}` | HONEST-EMPTY |
| `design_experiments/1` | physics.ex:24-25 | `{:ok, []}` | HONEST-EMPTY |
| `validate/1` | physics.ex:28-29 | `FormalVerification.verify_invariants(experiment.model, [:conservation_of_energy, :thermodynamics])` | UNAVAILABLE (verifier decommissioned) |
| `translate/1` | physics.ex:33-34 | `{:ok, %{engineering_applications: []}}` | HONEST-EMPTY |
| `metrics/0` | physics.ex:37-49 | All-zero metrics; `discoveries_this_cycle: length(discoveries)` from empty discover; `metrics_source: :state_derived` | TRUTHFUL-ZERO |

No `:rand.uniform` / fabricated constant appears in the domain module (see verifier `no_theatrics_in_domain_module`).

## 3. Physics subsystem inventory (`lib/tiannara/physics/**`, `Tiannara.Physics.*`)

| Module | File:line evidence | Classification |
|---|---|---|
| OPC (Observer-Physics Calculus) | `physics/opc.ex:100-101` thresholds 0.95/0.8; `:449` default determinism 0.5; `:472-475` observer/quantum/paradox outcomes are `:rand.uniform()` coin flips; `:544/:546` coercion multipliers 0.8/0.9; `:552-553` stability blend 0.95/0.05; `:576-577` canned `determinism_score: 0.98` + `compilation_time: :rand.uniform(1000)`; `:652` low-determinism rejection band; `:712` stability bands | THEATRICAL |
| OPC subcomponents (`opc/supervisor.ex`, `physics_compiler.ex`, `observer_manager.ex`, `determinism_validator.ex`, `stability_monitor.ex`) | Present, stateful ETables | PARTIAL (state-trace REAL, outputs theatrical) |
| IRD (Intervention Resonance Dynamics) | `physics/ird.ex:103` threshold 0.8; `:483` `base_potential = :rand.uniform() * 0.5 + 0.3`; `:487-490` system multipliers; `:595` coordination coin-flip `:rand.uniform() > 0.8` | THEATRICAL |
| IRD subcomponents (`ird/resonance_calculator.ex`, `dampening_engine.ex`, `coordinator.ex`, `nats_integration.ex`) | ETS-state plumbing + NATS placeholder | PARTIAL/THEATRICAL |
| NDE (Noise-Driven Evolution) | `physics/nde.ex:48-49,336-345` statistics aggregation of ETS `:chaos_reduction_stats`; machine-populated fields; broken KeyError paths on absent stats | THEATRICAL/BROKEN |
| NDE subcomponents (`nde/negentropy_calculator.ex`, `differentiation_engine.ex`, `chaos_analyzer.ex`, `pattern_optimizer.ex`) | ETS-state plumbing, theatrical math | PARTIAL/THEATRICAL |
| TWP (Timewalker Physics) | `physics/twp.ex:48-49,337-340` temporal predictions; `:411` canned `probability: 0.5, entropy: 0.5`; `:452` default entropy 0.5; `:552` confidence band 0.5; `:599-617` prediction generator over ETS states; broken KeyError predictions path | THEATRICAL/BROKEN |
| TWP subcomponents (`twp/collapse_handler.ex`, `coherence_manager.ex`, `temporal_validator.ex`, `pruning_engine.ex`, `supervisor.ex`) | ETS-state plumbing | PARTIAL/THEATRICAL |
| Subsystem supervisor | `physics/supervisor.ex` wires OPC/NDE/TWP/IRD | SUPERVISED |

The subsystem is real ETS-state machinery wrapped around fabricated physics math, and it is **disconnected from the domain module and the discovery pipeline** (see TRUTH-CLASSIFICATION / WORKFLOW-TRACE).

## 4. Math-substrate dependencies (`Tiannara.Domains.Physics` direct deps)

| Substrate | File | Capability | Classification |
|---|---|---|---|
| Probability | `lib/tiannara/math/probability.ex` | `bayes_update/3` | REAL |
| Numerics | `lib/tiannara/math/numerics.ex` → `lib/tiannara/numerics.ex` (type-safe ops: `error_mode/1`, `safe_round/2`, interpolation, validators) | bounded floats, error modes, interpolation | REAL (no ODE, no linear algebra) |
| Statistics | `lib/tiannara/math/statistics.ex` | descriptive stats | REAL |
| Graphs | `lib/tiannara/math/graphs.ex` | graph ops (BFS) | REAL |
| Calculus | `lib/tiannara/foundations/mathematics/calculus.ex:4-5` | `solve_ode/3` → `{:error, :ode_solver_unavailable}` | UNAVAILABLE (only caller: physics.ex:18) |
| Formal verification | `lib/tiannara/foundations/formal_verification.ex:4-5` | `verify_invariants/2` → `{:error, :formal_verification_unavailable}` | UNAVAILABLE (only caller: physics.ex:29) |
| Optimization | `lib/tiannara/math/optimization.ex:9,15` | `gradient_descent/4`, `nash_equilibrium/2` → `{:error, ..._unavailable}` | UNAVAILABLE |
| Information theory | `lib/tiannara/foundations/information_theory.ex:8,15` | `shannon_entropy/1`, `kl_divergence/2` | REAL |
| Logic kernel | `lib/tiannara/logic/*` (`rule.ex`, `transition.ex`, `invariant.ex`, `contradiction.ex`, `complementarity.ex`) | MC-002-M certified | REAL but **not referenced by physics** |
| Linear algebra | — | no module exists in `lib/` | NO |

## 5. Consumer inventory

| Consumer | File:line | Physics surface used | Live? |
|---|---|---|---|
| AutonomousDiscoveryEngine | `lib/tiannara/asc/autonomous_discovery.ex:35,37,54-68` | `simulate`, `validate`, `metrics`; hardcoded gravity/time_dilation experiment (weight 1.2) | DEAD (`run_discovery_cycle` at :15 has zero callers) |
| Domain ResearchDirector | `lib/tiannara/domains/research_director.ex:9,21` | registry `register_domain`, `get_all_metrics` | registry empty (no `register_domain` callers) |
| CanonicalRegistry | `canonical_registry.ex:34,220` | binding only | LIVE (metadata) |
| LiveView dashboards | `web/live/*` | registry metadata only | LIVE (read-only) |
| Entropy/WorldEpistemic | `lib/tiannara/os/world_epistemic_physics.ex` | derived computations | Independent, not a consumer of `Domains.Physics` |

## 6. Integration inventory

- **Real execution:** zero references to `RealExecution`, `Provenance`, or `Phase4` across `lib/tiannara/physics/**` and `lib/tiannara/domains/**` (verifier `no_real_execution_reference_in_physics_domains`). DISCONNECTED.
- **Provenance:** `Tiannara.Evidence.Provenance` is real and exercised by evidence/phase4 code, but no physics module attaches provenance to any result. NO path.
- **Safety:** physics callbacks are plain public functions — no authz, no sandbox, no timeout, no resource cap (see SAFETY-EXECUTION).

## 7. Summarized census

- Domain module: real, honest-empty, but **operationally non-functional** for simulation/validation.
- Subsystem: supervised, theatrical, broken in places, **not consumed**.
- Substrate: no ODE solver, no formal verifier, no linear algebra → physics cannot compute dynamics or verify invariants.
- Workflow: primary discovery chain is dead code.
- Real-execution/provenance integration: absent.

Bottom line: the `:physics` canonical domain is **reconciled as NO/PARTIAL (honest-empty), with a THEATRICAL disconnected subsystem**, on an incomplete math substrate.