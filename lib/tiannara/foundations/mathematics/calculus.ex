defmodule Tiannara.Foundations.Mathematics.Calculus do
  @moduledoc """
  Foundational calculus and differential equations.

  MC-004-M (MU-1): provides a REAL, bounded 4th-order Runge-Kutta (RK4)
  integrator for first-order ODE systems encoded as a `:first_order_system`
  equation spec.

  Truthfulness contract:
    - Supported spec: `%{type: :first_order_system, derivative: fun, dimension: n, params: map}`.
    - Every other input — including the empty/unknown inputs that the
      MC-001-M-decommissioned stub rejected — still returns
      `{:error, :ode_solver_unavailable}`. Capability is bounded: this solver
      claims only the one supported spec shape, never mocks a result, and never
      fabricates a trajectory.
    - Integration is genuinely reduced from the derivative function. Errors that
      arise during reduction (thrown ArithmeticError / non-finite values /
      dimension mismatch) are surfaced truthfully, never hidden.
  """

  @max_steps 2_000_000
  @default_divisions 1_000
  @max_dimension 1_024
  @max_trajectory_points 10_000

  @type equation_spec :: %{
          required(:type) => :first_order_system,
          required(:derivative) => function,
          required(:dimension) => pos_integer(),
          optional(:params) => map()
        }

  @type trajectory_point :: %{t: float(), x: [float()]}

  @doc """
  Numerically integrate an ODE system with the 4th-order Runge-Kutta method.

  Accepts a `:first_order_system` equation spec plus initial conditions and a
  time span (duration in seconds, or `%{duration: .., dt: ..}`). Returns
  `{:ok, result}` with a bounded trajectory, or `{:error, reason}`.

  Unsupported or empty/unknown specs return `{:error, :ode_solver_unavailable}` —
  the truthful unavailability of the decommissioned stub (MC-001-M pin), now
  restricted to exactly "specs this solver does not accept".
  """
  @spec solve_ode(map(), map() | [number()], float() | map()) :: {:ok, map()} | {:error, term()}
  def solve_ode(equation, initial_conditions, time_span \\ 1.0)

  def solve_ode(%{type: :first_order_system} = equation, initial_conditions, time_span) do
    with {:ok, dim, t0, t1, dt} <- parse_time_geometry(equation, time_span),
         {:ok, x0} <- parse_initial_state(initial_conditions, dim),
         {:ok, derivative} <- derivative_fn(equation, dim) do
      bounded_integrate(derivative, dim, x0, t0, t1, dt, equation)
    end
  end

  def solve_ode(_equation, _initial_conditions, _time_span) do
    {:error, :ode_solver_unavailable}
  end

  @doc """
  Advance one explicit RK4 step: `x(t + dt)` from `(t, x)`.
  """
  @spec rk4_step(function, float(), [number()], float()) :: [number()]
  def rk4_step(derivative, t, x, dt) when is_number(t) and is_number(dt) do
    k1 = derivative.(t, x)
    k2 = derivative.(t + dt / 2.0, vec_add(x, vec_scale(k1, dt / 2.0)))
    k3 = derivative.(t + dt / 2.0, vec_add(x, vec_scale(k2, dt / 2.0)))
    k4 = derivative.(t + dt, vec_add(x, vec_scale(k3, dt)))

    vec_add(x, vec_scale(vec_add(k1, vec_add(vec_scale(k2, 2.0), vec_add(vec_scale(k3, 2.0), k4))), dt / 6.0))
  end

  # --- geometry / validation ---

  defp parse_time_geometry(equation, time_span) do
    dim = Map.get(equation, :dimension)

    cond do
      not is_integer(dim) or dim < 1 or dim > @max_dimension ->
        {:error, :invalid_equation_spec}

      is_number(time_span) and is_finite_number(time_span) and time_span > 0 ->
        duration = time_span / 1.0
        dt = duration / @default_divisions
        {:ok, dim, 0.0, duration, max(dt, duration / @max_steps)}

      is_map(time_span) and is_number(time_span.duration) and
          is_finite_number(time_span.duration) and time_span.duration > 0 ->
        duration = time_span.duration / 1.0
        requested_dt = Map.get(time_span, :dt)
        dt =
          cond do
            is_number(requested_dt) and is_finite_number(requested_dt) and requested_dt > 0 ->
              requested_dt / 1.0

            true ->
              duration / @default_divisions
          end

        {:ok, dim, 0.0, duration, max(dt, duration / @max_steps)}

      true ->
        {:error, :ode_solver_unavailable}
    end
  end

  defp parse_initial_state(initial_conditions, dim) do
    cond do
      is_list(initial_conditions) and length(initial_conditions) == dim and
          Enum.all?(initial_conditions, &is_finite_number/1) ->
        {:ok, Enum.map(initial_conditions, &(&1 / 1.0))}

      true ->
        {:error, :invalid_initial_conditions}
    end
  end

  defp derivative_fn(equation, dim) do
    deriv = Map.get(equation, :derivative)

    if is_function(deriv, 2) do
      {:ok, deriv}
    else
      {:error, :invalid_equation_spec}
    end
  end

  # --- integration (bounded) ---

  defp bounded_integrate(derivative, dim, x0, t0, t1, dt, equation) do
    steps = min(ceil((t1 - t0) / dt), @max_steps)
    actual_dt = (t1 - t0) / steps
    sample_every = max(1, ceil(steps / @max_trajectory_points))

    try do
      {last_x, trajectory, step_count} =
        iterate(derivative, dim, x0, t0, actual_dt, steps, sample_every, [], 0)

      {:ok,
       %{
         type: :trajectory,
         method: :rk4,
         order: 4,
         trajectory: Enum.reverse(trajectory),
         steps: step_count,
         dt: actual_dt,
         t0: t0,
         t_end: t1,
         initial_state: x0,
         final_state: last_x,
         params: Map.get(equation, :params, %{})
       }}
    rescue
      ArithmeticError -> {:error, :non_finite_state}
      FunctionClauseError -> {:error, :dimension_mismatch}
    catch
      :throw, {:state_error, reason} -> {:error, reason}
    end
  end

  defp iterate(_derivative, _dim, x, _t, _dt, steps, _sample_every, acc, step_count)
       when step_count >= steps do
    {x, acc, step_count}
  end

  defp iterate(derivative, dim, x, t, dt, steps, sample_every, acc, step_count) do
    x_next = rk4_step(derivative, t, x, dt)

    case check_state(x_next, dim) do
      :ok ->
        t_next = t + dt
        recorded =
          if rem(step_count + 1, sample_every) == 0 or step_count + 1 == steps do
            [%{t: t_next, x: x_next} | acc]
          else
            acc
          end

        iterate(derivative, dim, x_next, t_next, dt, steps, sample_every, recorded, step_count + 1)

      {:error, reason} ->
        throw({:state_error, reason})
    end
  end

  defp check_state(state, dim) do
    cond do
      not is_list(state) or length(state) != dim -> {:error, :dimension_mismatch}
      true ->
        if Enum.all?(state, &is_finite_number/1), do: :ok, else: {:error, :non_finite_state}
    end
  end

  defp is_finite_number(value) do
    is_number(value) and is_float(value) and value == value and
      value > -1.7976931348623157e308 and value < 1.7976931348623157e308
  end

  # --- vector helpers ---

  defp vec_add(a, b) when is_list(a) and is_list(b) do
    Enum.zip_with(a, b, fn x, y -> x + y end)
  end

  defp vec_scale(v, s) when is_list(v) do
    Enum.map(v, fn x -> x * s end)
  end
end