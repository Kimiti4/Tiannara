# MC-004-A0 — Pilot Definition

**Gate:** MC-004-A0 (Reconciliation) — **Date:** 2026-08-31 — **Mode:** READ-ONLY. **Pilot status: NOT_EXECUTED, NOT_SIMULATED.** Definition only.

## 1. Constitutional question

> Can Tiannara today produce one bounded Physics result whose computation, execution, observation, provenance, and verification status are all demonstrably truthful — and independently reproducible?

**Answer: NO (current).** Evidence:
- `simulate` → `{:error, :ode_solver_unavailable}` (physics.ex:17-18; calculus.ex:5) — no computation can be produced.
- `validate` → `{:error, :formal_verification_unavailable}` (physics.ex:28-29; formal_verification.ex:5) — no verification can be produced.
- No provenance path for physics results; real execution disconnected (verifier scans).
- The supervised subsystem fabricates physics numbers (`opc.ex:472-475`, `ird.ex:483`, `ird.ex:595`) — not usable as truth.

**Feasibility note (also NO-today, partially YES-after-M):** the substrate pieces the pilot needs are individually REAL (Bayes `probability.ex`, type-safe `numerics.ex`, `shannon_entropy`/`kl_divergence` `information_theory.ex:8,15`, `Evidence.Provenance`, MC-003-M gated Phase4 gateway, logic kernel). A bounded truthful pilot is **definable** and realistically buildable by a small authorized MC-004-M mutation.

## 2. Pilot specification (compact)

| Attribute | Value |
|---|---|
| Name | `MC004-P` — Damped Harmonic Oscillator via bounded RK4 |
| Domain | canonical `:physics` only |
| Model | 2nd-order linear ODE: `m x'' + c x' + k x = 0`, underdamped case (`c² < 4mk`) |
| Inputs | `m, k, c`, `x(0), v(0)`, fixed step `h`, fixed horizon `T` (deterministic, recorded) |
| Computation | bounded 4th-order Runge–Kutta integration over real floats; step count bounded; deterministic seed/config |
| New capability required (MC-004-M) | REAL `integrate_ode` (RK4) in the math substrate, unit-tested against analytic solutions — NOT a mock |
| Observation | trajectory `{t, x(t), v(t)}` sampled at `k` points |
| Verification | (a) energy check `E(t) ≤ E(0) + ε`; (b) compare against closed-form underdamped analytic solution within tolerance; (c) independent re-run reproducibility test |
| Provenance | fixed config hash + seed + step + parameter set attached via `Evidence.Provenance`; result kind `:computed` |
| Execution | via Phase4 gated gateway ONLY IF `:real_execution_enabled` is separately authorized for MC-004-P; otherwise pilot runs as pure provenance-carrying computation (still truthful), explicitly labelled `:computed` |
| Success criteria | deterministic output; within-tolerance analytic match; energy bound holds; provenance complete; reproducible on re-run |
| Failure honesty | any tolerance breach must yield `{:error, ...}` or an explicit deviation record — never a fabricated pass |

## 3. What the pilot exercises (existing REAL capability)

- Real probability: Bayes update on pilot hypotheses (physics.ex:12-14).
- Real type-safe numerics: error-mode bookkeeping for every float (`numerics.ex:19-51`).
- Real entropy/KL: if evidence distributions are compared (`information_theory.ex:8,15`).
- Real provenance substrate: `Evidence.Provenance`.
- Real gating: MC-003-M `Phase4.ExperimentOrchestrator` authorization wall.

## 4. What the pilot deliberately does NOT require

- No formal verification (kept NO unless separately authorized).
- No linear algebra, no optimization, no new subsystems, no generalization to other domains, no ODE library.
- No theatrical subsystem (OPC/NDE/IRD/TWP) participation — those must be quarantined/decommissioned first (see MUTATION-PLAN) so the pilot's numbers are provably untainted.

## 5. Execution recording rule

If MC-004-P is later authorized, its evidence record must contain: config hash, seed, step size, trajectory sample, verification results, provenance records, and the run's execution status (proposed/scheduled/simulated/attempted/completed/observed/verified) — the MC-003 vocabularies. Until then, all of this is DEFINIED, not EXECUTED.