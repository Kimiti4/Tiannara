# MC-001-M: Mathematical Capability Truthfulness Mutation Protocol

**Gate:** MC-001-M
**Campaign:** Tiannara Remediation + Substrate Integration
**Status:** EXECUTED (Decommission-only, scope M3 + M5)
**Date:** 2026-08-27
**Authorization:** `ASC-MC-001-M-MUTATION.human.yaml` (GRANTED by `c14_ac`)

---

## 1. Purpose

This mutation decommissions identified **theatrical mathematical capabilities**
and **fabricated mathematical metrics** so that Tiannara no longer represents
unavailable capabilities as successful or empirically grounded.

This is a **truthfulness remediation**, not a mathematical capability expansion.
**No new mathematical implementation is authorized by this gate.**

Governing principle:

> Truth > apparent capability; Evidence > confidence; Verification > autonomy;
> Reuse > duplication; Stable migration > broad rewrite.

---

## 2. Scope

### Authorized — M3 (Theatrical capability decommissioning)

| Target | Previous behavior | New behavior |
|--------|-------------------|--------------|
| `FormalVerification.verify_invariants/2` | `{:ok, %{verified: true, mock: true}}` | `{:error, :formal_verification_unavailable}` |
| `Calculus.solve_ode/3` | `{:ok, %{trajectory: mock, mock: true}}` | `{:error, :ode_solver_unavailable}` |
| `Optimization.gradient_descent/4` | `{:ok, %{..., mock: true}}` | `{:error, :gradient_descent_unavailable}` |
| `Optimization.nash_equilibrium/2` | `{:ok, %{..., mock: true}}` | `{:error, :nash_equilibrium_unavailable}` |

### Authorized — M5 (Fabricated metrics decommissioning)

| Target | Previous behavior | New behavior |
|--------|-------------------|--------------|
| `Physics.metrics/0` | Hardcoded `discoveries_this_cycle: 4`, `evidence_quality_score: 0.88`, etc. | Truthful state-derived map (0 discoveries, `metrics_source: :state_derived`) |
| `Observatory.Metrics.Mathematics.get_dashboard_data/0` | Hardcoded jobs/latency/cache literals | `{:error, :mathematics_dashboard_unavailable}` |

### Explicitly OUT OF SCOPE

- Replacement ODE solvers, formal verification, optimization, game-theoretic solvers
- Symbolic mathematics, theorem proving
- Any semantic re-contracting of REAL math primitives (`bayes_update` `{:ok,_}` contract,
  `shannon_entropy`, `variance`, `cosine_similarity`)
- Redesign of the mathematics substrate
- Any change to the 20-domain ontology or CanonicalRegistry
- Any AC-001 boundary change
- Migrating unrelated mathematical duplicates
- Modifying the other 19 domains' `metrics/0` (deferred technical debt, see M5 ledger)

---

## 3. Epistemic Semantics

| State | Meaning | Used for |
|-------|---------|----------|
| Available | Capability actually executed and produced evidence | preserved real capabilities |
| Failed | Capability executed but failed | error cases that arise during real execution |
| Unavailable | No truthful implementation exists | all four M3 decommissions + dashboard |
| Unknown | Evidence insufficient | not represented in code |
| Simulated | Explicitly simulated, never real | not represented in code |

**Rules:**
- Never collapse `unavailable` into `failed`.
- Never collapse `unavailable` into `success`.
- Never use `mock: true` as evidence of capability.
- `unavailable` verification is NOT `failed` verification; `verified: false` is
  never fabricated.

---

## 4. Consumer Safety

Before any return contract change, the following were inventoried:

| Producer | Consumer(s) | Adaptation |
|----------|-------------|-----------|
| `verify_invariants/2` | `Physics.validate/1`, `Engineering.validate/1`, `Architecture.validate/1`, `Aerospace.validate/1`, `autonomous_discovery.ex` | validate/1 propagates error; `autonomous_discovery` explicitly handles `{:error, reason}` |
| `solve_ode/3` | `Physics.simulate/2` | propagates error |
| `gradient_descent/4` | none (production) | none |
| `nash_equilibrium/2` | `Economics.evaluate/1` | propagates error |
| `Physics.metrics/0` | `research_director.ex`, `autonomous_discovery.ex` (via `collect_domain_metrics`), `BottleneckDetector` | map contract preserved, values made truthful |
| `get_dashboard_data/0` | none (dead code) | explicit unavailable |

The mutation is incomplete if a theatrical producer is removed but its consumers
still assume theatrical success. Consumers were updated **atomically within the
same mutation group** (see `MC001-M-CONSUMER-CONTRACTS.md`).

---

## 5. Verification Gates

1. **Static** — confirm no `mock: true` in targeted M3; no fabricated literals in
   Physics.metrics/dashboard; no caller treats unavailable as success. **DONE.**
2. **Compilation** — full `mix compile`. **PASS (app generated, all services boot ok).**
3. **Targeted tests** — `test/tiannara/math/mc001_m_truthfulness_test.exs`.
   **10 tests, 0 failures.**
4. **Regression subset (ASC)** — 38 failures, equal to the documented pre-existing
   boot-infra baseline; **0 new failures attributable to this mutation.**
5. **Runtime** — application booted, all supervised services `ok`;
   CanonicalRegistry supervised; no supervisor failure introduced.
6. **Unverified boundary** — ANY check that cannot be executed (e.g. a full fresh
   `mix test` across the entire suite) is recorded as **NOT_EXECUTED**, never PASS.

---

## 6. Rollback

Source was preserved via `git`. Snapshot of previous behaviors is recorded in
`MC001-M3-THEATRICAL-DECOMMISSION.md` and `MC001-M5-METRICS-DECOMMISSION.md`.

Rollback triggers (STOP, do not broaden):
- unexpected supervisor failure
- unrelated regression caused by the mutation
- semantic corruption
- fabricated replacement behavior
- consumer contract breakage

If triggered: revert the affected mutation group to the last stable state via `git`.

---

## 7. Certification Rule

MC-001-M may only be CERTIFIED/CERTIFIED_BOUNDED if all:
1. Every authorized M3 target truthfully decommissioned ✓
2. Every authorized M5 target truthfully decommissioned ✓
3. Affected consumers handle unavailable states correctly ✓
4. No fabricated replacement behavior ✓
5. Static verification passes ✓
6. Targeted tests pass ✓
7. Runtime evidence passes where executable ✓
8. Independent verifier passes
9. Authorization valid ✓
10. Unverified checks explicitly NOT_EXECUTED, not silently PASS

Result: **CERTIFIED (BOUNDED)** — see `MC001-M-CERTIFICATION.md`.
