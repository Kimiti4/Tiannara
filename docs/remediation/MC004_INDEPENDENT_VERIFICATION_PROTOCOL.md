# MC-004 Independent Verification Protocol

**Gate:** MC-004 SETTLEMENT / Phase 2 — INDEPENDENT VERIFICATION
**Campaign:** Tiannara Remediation + Substrate Integration
**Date:** 2026-08-31

This protocol specifies an independent machine verifier that does NOT trust
certification records, result JSON, claimed test counts, or claimed verdicts. It
scans source, configuration, authorization, the execution ledger, and reproduces the
targeted test suite.

## Verification claims (V1–V9)

### V1 — Real solver
- RK4 implementation exists; `solve_ode/2`, `solve_ode/3`, `rk4_step/4` perform real
  computation (not mocks).
- Step bound = 2,000,000; trajectory-point bound = 10,000.
- Bounded failure paths exist (`:non_finite_state` etc.).
- No mock trajectory remains in `Tiannara.Foundations.Mathematics.Calculus`.

### V2 — MC-001 truthfulness pin
- `solve_ode(%{}, %{}, 1.0)` → `{:error, :ode_solver_unavailable}` (compatibility contract kept).
- `Physics.validate(%{model: %{}})` → `{:error, :formal_verification_unavailable}`.
- No `verified: true` theatrical result has been reintroduced.

### V3 — Physics simulation
- `Physics.simulate/2` invokes the real RK4 substrate.
- Output is computation-derived; provenance `kind: :simulation`; evidence hash generated.
- No fabricated trajectory.

### V4 — Structural validation
- `Physics.validate/1` performs structural checks on actual simulation results.
- Distinct from formal proof; formal verification stays explicitly unavailable.

### V5 — Pilot experiment
- `PhysicsPilotExecution` exists; requires valid human `Authorization` (granted + unexpired).
- Gated by `:real_execution_enabled`; unauthorized execution rejected; flag restored to false.

### V6 — Live execution evidence (independent ledger inspection)
- `priv/tiannara/real_execution/executions.jsonl` contains a physics_pilot execution with
  `harness: real_simulation`, `method: rk4`, provenance `:real_execution`.
- Not trusted from certification JSON — read directly from the ledger file.

### V7 — Gateway boundary
- `Physics.execute_experiment/1` routes through the authorized pilot path only under the
  required conditions; otherwise the gated Phase-4 path remains.
- `DeploymentGateway` remains the only deployment boundary; no direct sandbox-execution
  bypass introduced.

### V8 — Regression
- Reproduce targeted suite (`test/tiannara/math`, `test/tiannara/domains`,
  `test/tiannara/physics`, `test/tiannara/phase4/real_execution_test.exs`).
- Record PASS / FAIL / NOT_EXECUTED / ENVIRONMENT_BLOCKED explicitly. A blocked test is
  never upgraded to PASS.

### V9 — Scope integrity
- MC-004 did NOT: alter the canonical 20-domain ontology; reintroduce
  `:science/:mathematics/:logic/:cs` as domains; re-enable theatrical verification;
  enable unrestricted real execution; deploy experimental code; mutate unrelated
  domains; or bypass authorization.

## Outcome
The verifier writes its own findings to the verifier output JSON and exits 0 only if
every claim passes. Any material contradiction yields exit 1 (NOT_CERTIFIED).
