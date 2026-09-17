# MC-001-M3: Theatrical Capability Decommission Ledger

**Gate:** MC-001-M / M3
**Status:** COMPLETE
**Date:** 2026-08-27

This ledger records the source-grounded decommission of every authorized M3
target: implementation, previous behavior, evidence of theatrical behavior,
callers, mutation, new unavailable semantics, consumer remediation, tests, and
final disposition.

---

## T1. `Tiannara.Foundations.FormalVerification.verify_invariants/2`

**File:** `lib/tiannara/foundations/formal_verification.ex`

### Previous behavior
```elixir
def verify_invariants(_model_ast, _invariants) do
  {:ok, %{verified: true, counterexamples: [], mock: true}}
end
```

### Evidence of theatrical behavior
- Returns `verified: true` unconditionally, ignoring both arguments.
- Hardcoded `counterexamples: []` and `mock: true` flag.
- No SMT backend exists anywhere; the module docstring ("SMT solving and formal
  invariant checking") overstates an unimplemented capability.
- Recorded as THEATRICAL in reconciliation (`MC001-MATHEMATICS-TRUTH-CLASSIFICATION.md`,
  item T4) and bottleneck `BN-MC001-002`, `BN-MC001-003`.

### Callers (production)
- `Physics.validate/1` (`physics.ex:28`)
- `Engineering.validate/1` (`engineering.ex:22`)
- `Architecture.validate/1` (`architecture.ex:21`)
- `Aerospace.validate/1` (`aerospace.ex:22`)
- `autonomous_discovery.ex:36` (through `domain_module.validate/1`)

### Mutation
```elixir
def verify_invariants(_model_ast, _invariants) do
  {:error, :formal_verification_unavailable}
end
```

### New unavailable semantics
Formal verification is **Unavailable** — no truthful implementation exists.
It is NOT `failed` (verification was never attempted) and NOT `verified: false`
(a fabricated negative). The `{:error, :formal_verification_unavailable}` tuple
is distinguishable from success and from failure.

### Consumer remediation
- `Physics.validate/1`, `Engineering.validate/1`, `Architecture.validate/1`,
  `Aerospace.validate/1` return the error directly (satisfy the
  `@callback validate(experiment) :: result()` contract, where
  `result() :: {:ok, term()} | {:error, term()}`). No change required — the
  false confidence is removed by propagation.
- `autonomous_discovery.ex` — REQUIREMENT: it previously did
  `{:ok, validation} = domain_module.validate(...)` then `if validation.verified`.
  Rewritten as an explicit `case` handling `{:ok, %{verified: true}}`,
  `{:ok, validation}`, and `{:error, reason}` (see consumer ledger). The
  autonomous discovery pipeline can no longer interpret unavailable formal
  verification as validated.

### Tests
`test/tiannara/math/mc001_m_truthfulness_test.exs`:
- "formal verification is explicitly unavailable, not verified"
- "Physics.validate propagates unavailable verification, never verified:true"
- "unavailable verification is distinct from failed verification"

### Final disposition
**DECOMMISSIONED** — returns explicit unavailable state. No `verified: true` /
`mock: true` remains.

---

## T2. `Tiannara.Foundations.Mathematics.Calculus.solve_ode/3`

**File:** `lib/tiannara/foundations/mathematics/calculus.ex`

### Previous behavior
```elixir
def solve_ode(equation, initial_conditions, time_span \\ 1.0) do
  _ = {equation, initial_conditions, time_span}
  {:ok, %{trajectory: mock_trajectory(), steps: 1000, mock: true}}
end

defp mock_trajectory, do: Enum.map(1..100, &(&1 * 0.1))
```

### Evidence of theatrical behavior
- Returns a synthetic `trajectory` (`1..100 * 0.1`) independent of the equation
  and initial conditions actually passed — i.e. a fabricated numerical result
  ignoring the ODE.
- `mock: true` flag and `mock_trajectory` private helper.
- Classified THEATRICAL in reconciliation; bottleneck `BN-MC001-003`.

### Callers (production)
- `Physics.simulate/2` (`physics.ex:17`)

### Mutation
```elixir
def solve_ode(_equation, _initial_conditions, _time_span \\ 1.0) do
  {:error, :ode_solver_unavailable}
end
```

### New unavailable semantics
ODE solving is **Unavailable**. No fabricated trajectory may be returned as a
successful simulation. A failed/unavailable simulation MUST remain
distinguishable from a successful simulation — `{:error, :ode_solver_unavailable}`.

### Consumer remediation
- `Physics.simulate/2` returns the error directly (satisfies `result()`). The
  prior fabricated trajectory is no longer surfaced.

### Tests
- "ODE solver is explicitly unavailable"
- "Physics.simulate does not fabricate a trajectory"
- "unavailable simulation is never reported as a successful simulation"

### Final disposition
**DECOMMISSIONED** — returns explicit unavailable state. `mock_trajectory` removed.

---

## T3. `Tiannara.Math.Optimization.gradient_descent/4`

**File:** `lib/tiannara/math/optimization.ex`

### Previous behavior
```elixir
def gradient_descent(_objective_fn, _grad_fn, initial_params, opts \\ []) do
  {:ok, %{params: initial_params, loss: 0.0, iterations: Keyword.get(opts, :max_iter, 100), mock: true}}
end
```

### Evidence of theatrical behavior
- Returns `params` unchanged, `loss: 0.0` fabricated, `mock: true`. No actual
  descent is performed; the objective/gradient functions are ignored.
- **No production consumer exists** (verified by source search of `lib/`).

### Callers (production)
- **None.**

### Mutation
```elixir
def gradient_descent(_objective_fn, _grad_fn, _initial_params, _opts \\ []) do
  {:error, :gradient_descent_unavailable}
end
```

### New unavailable semantics
Gradient descent is **Unavailable**. The clean arity boundary is preserved for
any test or future infrastructure; the function no longer fabricates success.

### Consumer remediation
- None required (no production consumer).

### Tests
- "gradient descent is explicitly unavailable"

### Final disposition
**DECOMMISSIONED** — returns explicit unavailable state.

---

## T4. `Tiannara.Math.Optimization.nash_equilibrium/2`

**File:** `lib/tiannara/math/optimization.ex`

### Previous behavior
```elixir
def nash_equilibrium(payoff_matrix, entropy) do
  {:ok, %{equilibrium: :mixed_strategy, payoff: 0.5, entropy: entropy, mock: true}}
end
```

### Evidence of theatrical behavior
- Returns a hardcoded `:mixed_strategy` / `payoff: 0.5` independent of the
  payoff matrix; `mock: true`.
- Classified THEATRICAL in reconciliation.

### Callers (production)
- `Economics.evaluate/1` (`economics.ex:10`)

### Mutation
```elixir
def nash_equilibrium(_payoff_matrix, _entropy) do
  {:error, :nash_equilibrium_unavailable}
end
```

### New unavailable semantics
Nash equilibrium solving is **Unavailable**. No successful empty/zero result is
fabricated.

### Consumer remediation
- `Economics.evaluate/1` returns the error directly (satisfies `result()`). The
  prior fabricated `:equilibrium` is no longer produced.

### Tests
- "nash equilibrium is explicitly unavailable"

### Final disposition
**DECOMMISSIONED** — returns explicit unavailable state.

---

## Scope-control confirmation (M3)

- No replacement mathematical implementation introduced. ✗
- No symbolic math / theorem proving introduced. ✗
- No duplicated implementations created. ✓
- No unrelated broad refactoring performed. ✓
- `mock: true` eliminated from all four targeted implementations. ✓
