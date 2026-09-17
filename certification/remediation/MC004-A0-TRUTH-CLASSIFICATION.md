# MC-004-A0 — Truth Classification

**Gate:** MC-004-A0 (Reconciliation) — **Date:** 2026-08-31 — **Mode:** READ-ONLY
Classes: REAL / PARTIAL / THEATRICAL / FABRICATED / UNKNOWN / NO. Every row cites file:line.

## A. Canonical domain module (`lib/tiannara/domains/physics.ex`)

| Surface | Classification | Evidence | Basis |
|---|---|---|---|
| `discover/1` | **HONEST-EMPTY (PARTIAL)** | physics.ex:9 (always `discoveries: []`) | Real code; truthful output; zero capability output |
| `evaluate/1` | **REAL** | physics.ex:12-14 → `Probability.bayes_update/3` (REAL substrate) | Genuine derivation possible |
| `simulate/2` | **NO** | physics.ex:17-18 → calculus.ex:5 `{:error, :ode_solver_unavailable}` | Capability absent (decommissioned MC-001-M); honest error |
| `validate/1` | **NO** | physics.ex:28-29 → formal_verification.ex:5 `{:error, :formal_verification_unavailable}` | Capability absent; honest error |
| `generate_hypotheses/1` | **HONEST-EMPTY (PARTIAL)** | physics.ex:21-22 (`{:ok, []}`) | Real; empty |
| `design_experiments/1` | **HONEST-EMPTY (PARTIAL)** | physics.ex:24-25 (`{:ok, []}`) | Real; empty |
| `translate/1` | **HONEST-EMPTY (PARTIAL)** | physics.ex:33-34 (empty applications) | Real; empty |
| `metrics/0` | **TRUTHFUL-ZERO (REAL)** | physics.ex:37-49 | All values derived from empty discover; `metrics_source: :state_derived` is an accurate claim |

Domain module truthfulness: **exemplary** — returns honest-empty and honest-unavailable; no fabrication in the module (verifier: zero `:rand.uniform`).

## B. Physics subsystem (`lib/tiannara/physics/**`)

| Surface | Classification | Evidence |
|---|---|---|
| OPC observer physics | **THEATRICAL** | opc.ex:472-475 (all four outcomes are `:rand.uniform()` coin flips), 576-577 (canned `determinism_score: 0.98`, `compilation_time: :rand.uniform(1000)`) |
| OPC stability blends | **THEATRICAL** | opc.ex:552-553 (0.95/0.05 canned blend), 544/546 (0.8/0.9 coercion) |
| OPC low-determinism rejection | **THEATRICAL** | opc.ex:652 (threshold 0.5 on theatrical score) |
| IRD base potential | **THEATRICAL** | ird.ex:483 (`:rand.uniform() * 0.5 + 0.3`) |
| IRD system amplification | **THEATRICAL** | ird.ex:487-490 (multipliers on random base) |
| IRD coordination outcome | **THEATRICAL** | ird.ex:595 (`:rand.uniform() > 0.8` success/failure) |
| IRD resonance threshold | **THEATRICAL** | ird.ex:103 (0.8 threshold over theatrical input) |
| NDE statistics aggregation | **PARTIAL** | nde.ex:336-345 (aggregates real ETS records; records themselves theatrical; KeyError on absent stats) |
| NDE differentiation/negentropy/chaos | **THEATRICAL** | nde/negentropy_calculator.ex, differentiation_engine.ex, chaos_analyzer.ex (canned/noise-derived) |
| TWP predictions | **THEATRICAL/BROKEN** | twp.ex:337-340,411 (canned `probability: 0.5, entropy: 0.5`), 452, 552; KeyError predictions path |
| TWP coherence/collapse/pruning | **PARTIAL/THEATRICAL** | twp/collapse_handler.ex, coherence_manager.ex, temporal_validator.ex, pruning_engine.ex (ETS plumbing + theatrical math) |
| Subsystem supervisor | **SUPERVISED (state REAL)** | physics/supervisor.ex wires all submodules |

NOT a single REAL physics result is produced by the subsystem: every physics-shaped number either derives from `:rand.uniform` or a canned constant, or is aggregated from ETS records that themselves originated from such values.

## C. Math/logic/verification substrate

| Substrate | Classification | Evidence |
|---|---|---|
| Probability | REAL | math/probability.ex (bayes) |
| Statistics | REAL | math/statistics.ex |
| Graphs | REAL | math/graphs.ex |
| Type-safe numerics | REAL (bounded, no ODE) | numerics.ex:19-60 (error_mode, safe_round); no integration primitive |
| Calculus / ODE | **NO** | foundations/mathematics/calculus.ex:4-5 (`:ode_solver_unavailable`; only caller physics.ex:18) |
| Formal verification | **NO** | foundations/formal_verification.ex:4-5 (`:formal_verification_unavailable`; only caller physics.ex:29) |
| Optimization | **NO** | math/optimization.ex:9,15 (`{:error, ..._unavailable}`) |
| Information theory | REAL | foundations/information_theory.ex:8,15 (shannon, kl) |
| Logic kernel | REAL (unused by physics) | lib/tiannara/logic/* |
| Linear algebra | **NO** | no module exists in `lib/` |

## D. Workflow / integration

| Surface | Classification | Evidence |
|---|---|---|
| AutonomousDiscoveryEngine chain | **DEAD** | autonomous_discovery.ex:15 `run_discovery_cycle/0` has zero callers across `lib/` |
| Domain ResearchDirector registry | **EMPTY (unwired)** | research_director.ex:9 `register_domain/1` no callers |
| Physics → RealExecution | **DISCONNECTED** | zero `RealExecution` refs in physics/domains dirs |
| Physics → Provenance | **DISCONNECTED** | zero `Provenance` refs in physics/domains dirs |
| Physics → Phase4 gateway | **DISCONNECTED** | zero `Phase4` refs in physics/domains dirs |

## E. Metrics

| Surface | Classification | Evidence |
|---|---|---|
| `Domains.Physics.metrics/0` | TRUTHFUL-ZERO | physics.ex:37-49 — every field derived or explicit zero |
| Other 19 canonical domains | STANDING DEBT (TD-MC001-M5-DOMAINS) | pattern documented at MC-001-M; full 19-domain census out of A0 scope |

## F. Overall summary

- **Domain capability:** NO for simulation/validation (honest errors), PARTIAL/honest-empty for discovery, REAL for Bayes evaluation.
- **Physics subsystem:** THEATRICAL (supervised, disconnected, partially broken).
- **Theater classification triggers:** any `:rand.uniform`-derived or hardcoded physics output → THEATRICAL; aggregate-of-theatrical → THEATRICAL-with-REAL-state-plumbing.
- **Compounding risk:** because the subsystem is supervised but disconnected, nothing surfaces its outputs today; but nothing protects them either if wiring is ever made live without decommission.

**Overall physics capability statement: THEATRICAL** (subsystem theater + non-functional domain module); **constitutional pilot answer: NO** (see PILOT-DEFINITION).