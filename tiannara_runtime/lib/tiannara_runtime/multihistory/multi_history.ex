defmodule Tiannara.Runtime.MultiHistory.BranchManager do
  @moduledoc """
  Manages branching and parent lineages.
  """
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def branch(parent_id, _event) do
    GenServer.call(__MODULE__, {:branch, parent_id})
  end

  def lineage(branch_id) do
    GenServer.call(__MODULE__, {:lineage, branch_id})
  end

  @impl true
  def init(_opts) do
    {:ok, %{branches: %{}, counter: 0}}
  end

  @impl true
  def handle_call({:branch, parent_id}, _from, state) do
    new_id = state.counter + 1
    new_branch = %{id: new_id, parent: parent_id}
    new_branches = Map.put(state.branches, new_id, new_branch)
    {:reply, {:ok, new_branch}, %{state | branches: new_branches, counter: new_id}}
  end

  @impl true
  def handle_call({:lineage, branch_id}, _from, state) do
    lineage = build_lineage(branch_id, state.branches, [])
    {:reply, lineage, state}
  end

  defp build_lineage(nil, _branches, acc), do: acc
  defp build_lineage(id, branches, acc) do
    case Map.get(branches, id) do
      nil -> [id | acc]
      branch -> build_lineage(branch.parent, branches, [id | acc])
    end
  end
end

defmodule Tiannara.Runtime.MultiHistory.CausalLedger do
  @moduledoc """
  Ledger of causal events for history replay.
  """
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def append_event(history_id, event) do
    GenServer.call(__MODULE__, {:append_event, history_id, event})
  end

  def replay(history_id) do
    GenServer.call(__MODULE__, {:replay, history_id})
  end

  @impl true
  def init(_opts) do
    {:ok, %{events: %{}}}
  end

  @impl true
  def handle_call({:append_event, history_id, event}, _from, state) do
    list = Map.get(state.events, history_id, [])
    new_events = Map.put(state.events, history_id, list ++ [%{event: event, history: history_id}])
    {:reply, :ok, %{state | events: new_events}}
  end

  @impl true
  def handle_call({:replay, history_id}, _from, state) do
    {:reply, Map.get(state.events, history_id, []), state}
  end
end

defmodule Tiannara.Runtime.MultiHistory.HistoryDAG do
  @moduledoc """
  Directed Acyclic Graph representing history paths.
  """

  def add_branch(dag, parent_id, id) do
    Map.put(dag, id, parent_id)
  end

  def get_lineage(dag, id) do
    build_lineage(dag, id, [])
  end

  defp build_lineage(_dag, nil, acc), do: acc
  defp build_lineage(dag, id, acc) do
    parent = Map.get(dag, id)
    build_lineage(dag, parent, [id | acc])
  end
end

defmodule Tiannara.Runtime.MultiHistory.MergeEngine do
  @moduledoc """
  Unifies diverging histories and detects conflicts.
  """

  def merge(hist_a, hist_b) do
    set_a = MapSet.new(hist_a)
    set_b = MapSet.new(hist_b)
    
    conflicts = MapSet.intersection(set_a, set_b)
    merged = Enum.uniq(hist_a ++ hist_b)
    
    %{conflicts: conflicts, merged: merged}
  end
end

defmodule Tiannara.Runtime.MultiHistory.VersionVector do
  @moduledoc """
  Compares version vectors for causal ordering.
  """

  def compare(v1, v2) do
    keys = Enum.uniq(Map.keys(v1) ++ Map.keys(v2))
    
    results =
      Enum.map(keys, fn k ->
        val1 = Map.get(v1, k, 0)
        val2 = Map.get(v2, k, 0)
        
        cond do
          val1 > val2 -> :after
          val1 < val2 -> :before
          true -> :equal
        end
      end)
      |> Enum.uniq()

    cond do
      results == [:equal] -> :equal
      :after in results and :before in results -> :concurrent
      :after in results -> :after
      :before in results -> :before
      true -> :equal
    end
  end
end

defmodule Tiannara.Runtime.MultiHistory.SnapshotStore do
  @moduledoc """
  Saves and restores historical state snapshots.
  """

  def create_snapshot(history_id, state) do
    %{history: history_id, state: state}
  end

  def restore(snapshot) do
    snapshot.state
  end
end
