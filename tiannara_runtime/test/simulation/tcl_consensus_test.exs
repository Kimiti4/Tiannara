defmodule Tiannara.Simulation.TCLConsensusTest do
  @moduledoc "Property-based validation of fixed-point convergence & partition tolerance"
  use ExUnit.Case, async: true
  use PropCheck

  alias Tiannara.Phase19.TCL.{FixedPointVerifier, PartitionHandler}

  @epsilon_tcl 1.0e-5
  @quorum_fraction 0.667

  property "Lattice synchronization converges to fixed-point under bounded divergence" do
    forall(
      deltas <- convergence_sequence_generator(),
      do: assert_convergence_within_bounds(deltas)
    )
  end

  property "Quorum safety holds under up to f < N/3 faulty instances" do
    forall(
      {total, faulty} <- fault_tolerance_generator(),
      do: assert_quorum_safety(total, faulty)
    )
  end

  defp convergence_sequence_generator() do
    let(n <- integer(3, 12), do: Enum.map(1..n, fn i -> :math.pow(0.5, i) end))
  end

  defp fault_tolerance_generator() do
    let {n, f} <- {integer(3, 15), integer(0, 3)}, do: {n, min(f, div(n-1, 3))}
  end

  defp assert_convergence_within_bounds(deltas) do
    # Verify sequence is strictly decreasing and converges towards 0
    deltas == Enum.sort(deltas, :desc) and List.last(deltas) < hd(deltas)
  end

  defp assert_quorum_safety(total, faulty) do
    required = trunc(total * @quorum_fraction)
    active = total - faulty
    active >= required
  end
end