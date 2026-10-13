defmodule Tiannara.Math.MC001MTruthfulnessTest do
  use ExUnit.Case, async: true

  alias Tiannara.Foundations.FormalVerification
  alias Tiannara.Foundations.Mathematics.Calculus
  alias Tiannara.Math.Optimization
  alias Tiannara.Domains.Physics
  alias Tiannara.Observatory.Metrics.Mathematics, as: MathematicsMetrics

  describe "M3 theatrical capability decommissioning" do
    test "formal verification is explicitly unavailable, not verified" do
      assert {:error, :formal_verification_unavailable} =
               FormalVerification.verify_invariants(%{}, [
                 :conservation_of_energy,
                 :thermodynamics
               ])
    end

    test "ODE solver is explicitly unavailable" do
      assert {:error, :ode_solver_unavailable} = Calculus.solve_ode(%{}, %{}, 1.0)
    end

    test "gradient descent performs bounded real computation without certifying global optimality" do
      assert {:ok, result} =
               Optimization.gradient_descent(fn [x] -> x * x end, fn [x] -> [2.0 * x] end, [1.0],
                 max_iterations: 500
               )

      assert result.certification_eligible == false
      assert result.optimality == :local_stationary_candidate
    end

    test "nash equilibrium is explicitly unavailable" do
      assert {:error, :nash_equilibrium_unavailable} =
               Optimization.nash_equilibrium([[0, 1], [1, 0]], 0.0)
    end
  end

  describe "M3 consumer propagation" do
    test "Physics.simulate does not fabricate a trajectory" do
      assert {:error, :ode_solver_unavailable} =
               Physics.simulate(%{equations: []}, %{boundary_conditions: []})
    end

    test "Physics.validate propagates unavailable verification, never verified:true" do
      assert {:error, :formal_verification_unavailable} =
               Physics.validate(%{model: %{}})
    end

    test "unavailable verification is distinct from failed verification (not a verified:false fabricated result)" do
      assert {:error, _reason} = Physics.validate(%{model: %{}})
    end
  end

  describe "M5 fabricated metrics decommissioning" do
    test "Physics.metrics no longer reports fabricated discovery counts" do
      m = Physics.metrics()
      assert m.discoveries_this_cycle == 0
      assert m.metrics_source == :state_derived
      refute Map.has_key?(m, :mock)
    end

    test "Physics.metrics discovery count is derived from discover/1, not hardcoded" do
      {:ok, %{discoveries: discoveries}} = Physics.discover(%{})
      assert Physics.metrics().discoveries_this_cycle == length(discoveries)
    end

    test "mathematics dashboard is explicitly unavailable, not hardcoded" do
      assert {:error, :mathematics_dashboard_unavailable} =
               MathematicsMetrics.get_dashboard_data()
    end
  end
end
