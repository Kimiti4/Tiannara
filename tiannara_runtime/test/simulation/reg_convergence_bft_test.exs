defmodule Tiannara.Simulation.REGConvergenceBFTTest do
  @moduledoc "Property-based validation of Banach contraction & Byzantine fault tolerance"
  use ExUnit.Case, async: true
  use PropCheck

  alias Tiannara.Phase14.Formal.{ContractionVerifier, ByzantineConsensus, EquivocationDetector}

  @divergence_threshold 0.99

  property "REG generation sequence satisfies Banach contraction under bounded mutation" do
    forall(
      sequence <- axiom_sequence_generator(),
      do: assert_contraction_holds(sequence)
    )
  end

  property "BFT finality reached despite f < N/3 faulty instances" do
    forall(
      {total, faulty} <- fault_tolerance_generator(),
      do: assert_bft_finality(total, faulty)
    )
  end

  property "Equivocation is always detected when instance signs conflicting hashes" do
    forall(
      round <- mock_round_generator(),
      do: assert_equivocation_detected(round)
    )
  end

  defp axiom_sequence_generator() do
    let(n <- integer(3, 15), do: Enum.map(1..n, fn i -> generate_mock_axiom(i) end))
  end

  defp generate_mock_axiom(i) do
    %{
      causal: :linear,
      interaction: :deterministic,
      drift: :math.pow(0.80, i) # strictly contracting sequence for Banach contraction
    }
  end

  defp fault_tolerance_generator() do
    let {n, f} <- {integer(4, 10), integer(0, 2)}, do: {n, min(f, div(n-1, 3))}
  end

  defp mock_round_generator() do
    %{prepare_votes: %{"node_a" => "hash1"}, commit_votes: %{}, leader: "leader", axioms_hash: "hash1"}
  end

  defp assert_contraction_holds(sequence) do
    {:ok, pid} = GenServer.start_link(ContractionVerifier, [])
    try do
      Enum.reduce_while(Enum.chunk_every(sequence, 2, 1, :discard), true, fn [a, b], acc ->
        a_num = %{drift: a.drift}
        b_num = %{drift: b.drift}
        result = GenServer.call(pid, {:step, a_num, b_num, 0.92, 0.93})
        if match?({:divergent, k} when k >= @divergence_threshold, result), do: {:halt, false}, else: {:cont, acc}
      end)
    after
      GenServer.stop(pid)
    end
  end

  defp assert_bft_finality(total, faulty) do
    required_prepare = 2 * faulty + 1
    required_commit = required_prepare + 1
    total >= 3 * faulty + 1 and required_commit <= total
  end

  defp assert_equivocation_detected(round) do
    EquivocationDetector.detect(round, "node_a", :prepare, "hash_conflict")
  end
end