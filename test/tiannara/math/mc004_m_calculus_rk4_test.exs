defmodule Tiannara.Foundations.Mathematics.CalculusTest do
  use ExUnit.Case, async: true

  alias Tiannara.Foundations.Mathematics.Calculus

  @tolerance 1.0e-3

  test "solves a harmonic oscillator (undamped) close to the analytic solution" do
    omega = :math.pi()
    derivative = fn _t, [x, v] -> [v, -omega * omega * x] end
    equation = %{type: :first_order_system, dimension: 2, derivative: derivative, params: %{omega: omega}}

    assert {:ok, result} = Calculus.solve_ode(equation, [1.0, 0.0], %{duration: 1.0, dt: 1.0e-4})
    assert result.method == :rk4
    assert result.order == 4

    duration = result.t_end

    %{t: last_t} = last_point = List.last(result.trajectory)
    assert_in_delta last_t, duration, 1.0e-9
    [x_last, _] = last_point.x
    analytic_x = :math.cos(omega * duration)
    assert_in_delta x_last, analytic_x, @tolerance
  end

  test "solves an exponential decay close to the analytic solution" do
    lambda = 2.0
    derivative = fn _t, [x] -> [-lambda * x] end
    equation = %{type: :first_order_system, dimension: 1, derivative: derivative, params: %{lambda: lambda}}

    assert {:ok, result} = Calculus.solve_ode(equation, [1.0], 1.0)
    duration = result.t_end
    [x_last] = List.last(result.trajectory).x
    analytic = :math.exp(-lambda * duration)
    assert_in_delta x_last, analytic, @tolerance
  end

  test "returns ode_solver_unavailable for unsupported and empty specs (MC-001 pin)" do
    assert {:error, :ode_solver_unavailable} = Calculus.solve_ode(%{}, %{}, 1.0)
    assert {:error, :ode_solver_unavailable} = Calculus.solve_ode(%{}, [], 1.0)
    assert {:error, :ode_solver_unavailable} = Calculus.solve_ode([], [], 1.0)
    assert {:error, :ode_solver_unavailable} = Calculus.solve_ode(%{type: :unknown}, [], 1.0)
    assert {:error, :invalid_equation_spec} = Calculus.solve_ode(%{type: :first_order_system}, [], 0.0)
  end

  test "rejects invalid initial conditions and missing derivative truthfully" do
    equation = %{type: :first_order_system, dimension: 2, derivative: fn _t, [x, v] -> [v, -x] end}

    assert {:error, :invalid_initial_conditions} = Calculus.solve_ode(equation, [1.0], 1.0)
    assert {:error, :invalid_equation_spec} = Calculus.solve_ode(%{type: :first_order_system, dimension: 2}, [1.0, 0.0], 1.0)
  end

  test "bounded step budget never exceeds the cap and trajectory stays sampled" do
    omega = 1.0
    derivative = fn _t, [x, v] -> [v, -omega * omega * x] end
    equation = %{type: :first_order_system, dimension: 2, derivative: derivative, params: %{}}

    # dt small enough to request 10M steps; the cap must clamp to 2M and the
    # trajectory must stay sampled to <= 10k points.
    assert {:ok, result} = Calculus.solve_ode(equation, [1.0, 0.0], %{duration: 1.0, dt: 1.0e-7})
    assert result.steps == 2_000_000
    assert length(result.trajectory) <= 10_000
    assert Enum.all?(result.trajectory, fn p -> Enum.all?(p.x, &is_number/1) end)
  end

  test "rk4_step returns a full state vector" do
    omega = 1.0
    derivative = fn _t, [x, v] -> [v, -omega * omega * x] end
    step = Calculus.rk4_step(derivative, 0.0, [1.0, 0.0], 0.01)
    assert length(step) == 2
    assert Enum.all?(step, &is_number/1)
  end
end