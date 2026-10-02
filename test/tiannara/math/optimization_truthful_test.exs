defmodule Tiannara.Math.OptimizationTest do
  use ExUnit.Case, async: true
  alias Tiannara.Math.Optimization

  test "gradient descent minimizes a convex quadratic" do
    objective = fn [x] -> (x - 3.0) * (x - 3.0) end
    gradient = fn [x] -> [2.0 * (x - 3.0)] end

    assert {:ok, result} =
      Optimization.gradient_descent(objective, gradient, [0.0],
        learning_rate: 0.1, tolerance: 1.0e-7, max_iterations: 1000)

    assert_in_delta hd(result.params), 3.0, 1.0e-3
    assert result.objective < 1.0e-5
    assert result.certification_eligible == false
  end

  test "bounds iteration count" do
    objective = fn [x] -> x * x end
    gradient = fn [x] -> [2.0 * x] end

    assert {:error, :iteration_limit_exceeded} =
      Optimization.gradient_descent(objective, gradient, [1.0], max_iterations: 100_001)
  end

  test "nash equilibrium remains unavailable" do
    assert {:error, :nash_equilibrium_unavailable} =
      Optimization.nash_equilibrium([], 0.0)
  end
end
