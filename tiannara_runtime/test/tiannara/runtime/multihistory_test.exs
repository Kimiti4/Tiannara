defmodule Tiannara.Runtime.MultiHistoryTest do
  use ExUnit.Case

  alias Tiannara.Runtime.MultiHistory.{BranchManager, CausalLedger, HistoryDAG, MergeEngine, SnapshotStore, VersionVector}

  setup do
    for module <- [BranchManager, CausalLedger] do
      case module.start_link() do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end
    end

    :ok
  end

  test "branch manager creates branches and returns lineage" do
    {:ok, branch_a} = BranchManager.branch(nil, %{event: "seed_a"})
    {:ok, branch_b} = BranchManager.branch(branch_a.id, %{event: "fork_b"})

    assert branch_b.parent == branch_a.id
    assert BranchManager.lineage(branch_b.id) == [branch_a.id, branch_b.id]
  end

  test "causal ledger records and replays history events" do
    assert :ok == CausalLedger.append_event(:h1, %{action: "start"})
    assert :ok == CausalLedger.append_event(:h1, %{action: "continue"})

    events = CausalLedger.replay(:h1)

    assert length(events) == 2
    assert Enum.map(events, & &1.event.action) == ["start", "continue"]
    assert Enum.all?(events, &(&1.history == :h1))
  end

  test "history dag lineage resolves parent chain" do
    dag = HistoryDAG.add_branch(%{}, nil, 1)
    dag = HistoryDAG.add_branch(dag, 1, 2)

    assert HistoryDAG.get_lineage(dag, 2) == [1, 2]
  end

  test "merge engine unifies histories and reports conflicts" do
    hist_a = [:a, :b, :c]
    hist_b = [:b, :c, :d]

    result = MergeEngine.merge(hist_a, hist_b)

    assert result.conflicts == MapSet.new([:b, :c])
    assert Enum.sort(result.merged) == Enum.sort([:a, :b, :c, :d])
  end

  test "version vector compare identifies ordering" do
    v1 = %{node_a: 2, node_b: 1}
    v2 = %{node_a: 1, node_b: 1}

    assert VersionVector.compare(v1, v2) == :after
    assert VersionVector.compare(v1, v1) == :equal
    assert VersionVector.compare(v2, %{node_a: 2, node_b: 2}) == :before
    assert VersionVector.compare(%{node_a: 1}, %{node_a: 1, node_b: 1}) == :before
  end

  test "snapshot store captures and restores state" do
    snapshot = SnapshotStore.create_snapshot(:h42, %{position: "branch"})

    assert snapshot.history == :h42
    assert SnapshotStore.restore(snapshot) == %{position: "branch"}
  end
end
