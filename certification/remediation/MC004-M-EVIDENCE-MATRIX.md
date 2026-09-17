# MC-004-M Mutation Evidence Matrix

**Gate:** MC-004-M — Domain-Physics Pilot Mutation (MU-1..MU-4)
**Campaign:** Tiannara Remediation + Substrate Integration
**Scope:** MU-1 (real bounded RK4 integrator), MU-2 (Physics domain wiring: real simulate + structural validate + provenance + pilot), MU-3 (subsystem quarantine: OPC/NDE/IRD/TWP), MU-4 (Phase4 bridge + ASC placeholder replacement)
**Status:** EVIDENCE COMPLETE — verdict CERTIFIED_BOUNDED
**Date:** 2026-08-31

This ledger records, per mutation, WHAT was changed, the verification evidence
(compile + targeted suite results), and the honest boundary (what did NOT run).

---

## MU-1 — Real bounded RK4 integrator (`Calculus.solve_ode`)

| Artifact | Pre-mutation | Post-mutation |
| --- | --- | --- |
| `lib/tiannara/foundations/mathematics/calculus.ex` | placeholder stub returning `{:error, :ode_solver_unavailable}` for every spec (MC-001 pin) | real RK4 integration for `%{type: :first_order_system, dimension, derivative, ...}`; public `rk4_step/4`; explicit bounds `@max_steps 2_000_000`, `@default_divisions 1_000`, `@max_dimension 1_024`, `@max_trajectory_points 10_000`; bounded subsampling (`sample_every`) so trajectory ≤ 10_000 points; finite-state guard ±`1.7976931348623157e308` |

- **Return shape (supported spec):** `{:ok, %{type: :trajectory, method: :rk4, order: 4, trajectory: [%{t:, x:}], steps:, dt:, t0:, t_end:, initial_state:, final_state:, params:}}`.
- **Error paths (truthful, no fabrication):** non-`:first_order_system` spec → `{:error, :ode_solver_unavailable}` (MC-001 pin preserved); malformed spec → `:invalid_equation_spec`; malformed ICs → `:invalid_initial_conditions`; dimension mismatch → `:dimension_mismatch`; non-finite state → `:non_finite_state` (e.g. RK4 instability at huge dt returns this honestly instead of a confident-but-wrong answer).
- **Evidence:** `test/tiannara/math/mc004_m_calculus_rk4_test.exs` — real trajectory production, analytic accuracy (harmonic oscillator), bounded inset, step count under extreme division count, error-path pins (incl. `{:error, :ode_solver_unavailable}` for non-first-order spec, `:invalid_equation_spec`, `:invalid_initial_conditions`, `:non_finite_state`, `:dimension_mismatch`). `mc001_m_truthfulness_test.exs` pin (`solve_ode(%{}, %{}, 1.0) == {:error, :ode_solver_unavailable}`) still green.

## MU-2 — Physics domain: real simulate + structural validate + provenance + pilot

| Artifact | Pre-mutation | Post-mutation |
| --- | --- | --- |
| `lib/tiannara/domains/physics.ex` | `validate/1` → `{:error, :formal_verification_unavailable}` everywhere; `simulate/2` consults `Maths` placeholders (no real integration) | `simulate/2` reads equations/boundary_conditions/`time_span` (default 1.0) from the context, runs `Calculus.solve_ode`, builds provenance via `Evidence.Provenance.build(kind: :simulation, source: ...)` with a sha256 evidence hash over the configuration subset → `{:ok, %{result:, provenance:}}`; `validate/1` performs structural checks on the integrated result (`verification_method: :structural_checks`, `invariants: [:energy_bounded]`, no `:verified` key) for a real trajectory / `{:error, :formal_verification_unavailable}` otherwise (MC-001 pin kept); `pilot_experiment/0` = damped harmonic oscillator (m=1.0, c=0.5, k=4.0, underdamped, x0=1.0, v0=0.0, `%{duration: 10.0, dt: 0.01}`) |

- **Providence kind:** `:simulation` only (no `:computed`, no claim of `:real_execution`).
- **Evidence:** `test/tiannara/domains/mc004_m_physics_domain_test.exs` — real trajectory + `%{kind: :simulation}` provenance with 64-hex evidence hash; underdamped decay verified against the exponential envelope e^(-c·t/2m) (max amplitude ≤ 1.0, last amplitude at t=10 ≈ 0.053 < 0.1 < envelope 0.082); energy bounded; `validate/1` structural path; `{:error, :formal_verification_unavailable}` for non-integrated model. `mc001_m_truthfulness_test.exs` pin (`validate(%{model: %{}})` → `:formal_verification_unavailable`) still green.

## MU-3 — Theatrical subsystem quarantine (OPC / NDE / IRD / TWP)

| Artifact | Change |
| --- | --- |
| `lib/tiannara/physics/opc.ex` | client API (10 functions) → `{:error, :physics_substrate_unavailable}`; `compile_observer_physics/1` → `(%{}, %{})`; `simulate_physics_compilation/1` steps all `success: false, reason: :physics_substrate_unavailable`; `compile_deterministic_physics_model/1` → determinism_score/time nil, `compilation_error: :physics_substrate_unavailable`; **no `:rand.uniform`**; `start_link`/supervisor/ETS retained (boot-neutral) |
| `lib/tiannara/physics/nde.ex` | client API (10 functions) → `{:error, :physics_substrate_unavailable}`; `start_link` retained |
| `lib/tiannara/physics/ird.ex` | client API (11 functions) → `{:error, :physics_substrate_unavailable}`; `calculate_system_resonance_potential/2` → `{:error, :physics_substrate_unavailable}` (caller made error-tolerant); `calculate_resonance_potential_for_system/2` error-tolerant; `attempt_system_coordination/1` → deterministic `:failure`; `start_link` retained |
| `lib/tiannara/physics/twp.ex` | client API (9 functions) → `{:error, :physics_substrate_unavailable}`; `start_link` retained |

- **Evidence:** `test/tiannara/physics/mc004_m_subsystem_quarantine_test.exs` — every quarantined surface honest (nothing fabricated, nothing random); `:rand.uniform` count across `lib/tiannara/physics/**` = **0** (grep-verified); application boots green (PhaseΩ 15/15 healthy; OPC/NDE/TWP/IRD initialized).
- 16 engine submodules under `physics/{opc,nde,ird,twp}/` remain untouched, documented technical debt (no callers).

## MU-4 — Phase4 bridge + ASC placeholder replacement

| Artifact | Change |
| --- | --- |
| `lib/tiannara/domains/physics.ex` | `execute_experiment/1` builds a Phase-4 spec (`to_phase4_spec/1`) and submits via `Tiannara.Phase4.ExperimentOrchestrator.submit_experiment/1` — the single gated real-execution gateway; while `:real_execution_enabled` is false this deterministically returns `{:error, :real_execution_not_enabled}` |
| `lib/tiannara/asc/autonomous_discovery.ex` | `generate_candidate_experiments/1` physics candidate now uses `Tiannara.Domains.Physics.pilot_experiment()` (candidate hypothesis = pilot hypothesis, context = pilot context, `domain_weight: 1.2`) instead of placeholder lorem; Chemistry candidate unchanged |

- **Evidence:** quarantine suite asserts `execute_experiment` returns `{:error, :real_execution_not_enabled}` deterministically at current gate flags; compile PASS.

---

## Regression battery (post-mutation, standalone run)

| Suite | Result |
| --- | --- |
| `test/tiannara/math` + `test/tiannara/domains` + `test/tiannara/physics` (captured in `priv/tiannara/remediation/results/MC004_M_suite_output.txt`) | **73 tests, 0 failures** |

Includes: `mc001_m_truthfulness_test.exs` (MC-001 pins preserved), `canonical_registry_test.exs` (physics binding + app boot), all three new MC-004-M test files, `ocs_precursor_basis_test.exs`/`mc003_m_...` regression tests located in these directories. Boot green (`mix compile` PASS; app starts; PhaseΩ 15/15 healthy).

### Pre-existing / intentional notes (NOT mutation-introduced)
- Pre-mutation codebase has ~1986 modified files (no clean repo baseline exists); full one-shot `mix test` is not runnable on this machine (>30 min) — per-directory suites are the standard.
- `---- no output ----` from certain module-boot probes reflecting the intentionally quarantined subsystem surfaces (now explicit `:physics_substrate_unavailable`).

## Honest boundary (what did NOT happen)
- `:real_execution_enabled` remains **false** everywhere; `pilot_executed` = **false**. **No pilot/live experiment was executed** by this gate.
- No formal-verification revival: `validate/1` still returns `{:error, :formal_verification_unavailable}` for non-integrated/real-evidence workflows; no correctness certificate for the integrator beyond analytic pin answers.
- No new ODE/numerics library dependency was added (pure Elixir RK4).
- Subsystem engine internals untouched (OPC/NDE/IRD/TWP engines remain dormant servers — TD).
- No fabricated verifier/authorization/signature output.

## Verbal contract carry-forward
- MC-004-P (live pilot) REQUIRES a fresh MC-004-P authorization grant before `pilot_experiment/0` may be executed or `submit_experiment/1` routed for real.
- MC-005 onward gates require `ASC-MC-005` grants (BOUNDED, 2026-08-31).