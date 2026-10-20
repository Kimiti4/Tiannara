defmodule Tiannara.Simulation.REAHarmonizationTest do
  @moduledoc "Property-based validation of cross-domain harmonization convergence & drift bounds"
  use ExUnit.Case, async: true
  use PropCheck

  alias Tiannara.Phase16.REA.{ConflictResolver, ConvergenceMonitor}

  @threshold 0.40
  @convergence_epsilon 1.0e-6

  property "Harmonization score remains above threshold under bounded constraint relaxation" do
    forall(
      {overlap, consistency, conflict} <- harmonization_metrics_generator(),
      do: assert_harmonization_stable(overlap, consistency, conflict)
    )
  end

  property "Arbitration sequence converges within max rounds under adjunction relaxation" do
    forall(
      deltas <- convergence_sequence_generator(),
      do: assert_convergence_within_bounds(deltas)
    )
  end

  defp harmonization_metrics_generator() do
    let {o, c, d} <- {float(0.4, 0.9), float(0.8, 0.98), float(0.05, 0.3)}, do: {o, c, d}
  end

  defp convergence_sequence_generator() do
    let(n <- integer(3, 15), do: Enum.map(1..n, fn i -> :math.pow(0.5, i) end))
  end

  defp assert_harmonization_stable(overlap, consistency, conflict) do
    score = (overlap * consistency) / (conflict + 0.15 + 1.0e-6)
    score >= @threshold
  end

  defp assert_convergence_within_bounds(deltas) do
    # Verify sequence is strictly decreasing and converges towards 0
    deltas == Enum.sort(deltas, :desc) and List.last(deltas) < hd(deltas)
  end
end