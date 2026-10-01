defmodule TiannaraRuntime.Mathematics.OdeSolver do
  @moduledoc """
  Evidence-labelled explicit Euler integration.

  This is a numerical approximation engine, not a proof engine. It refuses to
  label its trajectory as exact, stable, or reality-validated.
  """

  def solve(rhs, initial_state, {t0, t1}, step)
      when is_function(rhs, 2) and is_map(initial_state) and is_number(t0) and
             is_number(t1) and is_number(step) and step > 0 and t1 >= t0 do
    points = integrate(rhs, initial_state, t0, t1, step, [{t0, initial_state}])

    {:ok, %{
      method: :explicit_euler,
      trajectory: points,
      evidence_class: :numerical_approximation,
      solution_status: :candidate_solution,
      stability_status: :unassessed,
      reality_status: :unvalidated,
      certification_eligible: false
    }}
  end

  def solve(_, _, _, _), do: {:error, :invalid_euler_problem}

  defp integrate(_rhs, _state, t, t1, _h, acc) when t >= t1, do: Enum.reverse(acc)

  defp integrate(rhs, state, t, t1, h, acc) do
    dt = min(h, t1 - t)
    derivative = rhs.(t, state)
    next_state = advance(state, derivative, dt)
    next_t = t + dt
    integrate(rhs, next_state, next_t, t1, h, [{next_t, next_state} | acc])
  end

  defp advance(state, derivative, dt) do
    Map.new(state, fn {key, value} -> {key, value + dt * Map.fetch!(derivative, key)} end)
  end
end
