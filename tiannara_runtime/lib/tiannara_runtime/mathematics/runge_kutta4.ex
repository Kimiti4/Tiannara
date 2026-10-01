defmodule TiannaraRuntime.Mathematics.RungeKutta4 do
  @moduledoc """
  Classical fourth-order Runge-Kutta numerical integrator.

  Its output is explicitly a numerical approximation. Agreement between step
  sizes can provide convergence evidence but does not itself prove convergence
  or correctness for the underlying real system.
  """

  def solve(rhs, initial_state, {t0, t1}, step)
      when is_function(rhs, 2) and is_map(initial_state) and is_number(t0) and
             is_number(t1) and is_number(step) and step > 0 and t1 >= t0 do
    trajectory = integrate(rhs, initial_state, t0, t1, step, [{t0, initial_state}])

    {:ok, %{
      method: :runge_kutta_4,
      order: 4,
      trajectory: trajectory,
      evidence_class: :numerical_approximation,
      solution_status: :candidate_solution,
      convergence_status: :unassessed,
      reality_status: :unvalidated,
      certification_eligible: false
    }}
  end

  def solve(_, _, _, _), do: {:error, :invalid_rk4_problem}

  defp integrate(_rhs, _state, t, t1, _h, acc) when t >= t1, do: Enum.reverse(acc)

  defp integrate(rhs, state, t, t1, h, acc) do
    dt = min(h, t1 - t)
    k1 = rhs.(t, state)
    k2 = rhs.(t + dt / 2, advance(state, k1, dt / 2))
    k3 = rhs.(t + dt / 2, advance(state, k2, dt / 2))
    k4 = rhs.(t + dt, advance(state, k3, dt))
    next_state = combine(state, k1, k2, k3, k4, dt)
    next_t = t + dt
    integrate(rhs, next_state, next_t, t1, h, [{next_t, next_state} | acc])
  end

  defp advance(state, derivative, dt) do
    Map.new(state, fn {key, value} ->
      {key, value + dt * Map.fetch!(derivative, key)}
    end)
  end

  defp combine(state, k1, k2, k3, k4, dt) do
    Map.new(state, fn {key, value} ->
      slope =
        (Map.fetch!(k1, key) + 2 * Map.fetch!(k2, key) +
           2 * Map.fetch!(k3, key) + Map.fetch!(k4, key)) / 6

      {key, value + dt * slope}
    end)
  end
end
