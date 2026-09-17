defmodule ObservationBus.CIL.Epistemic.ContradictionDetector do
  @moduledoc """
  Continuously searches for conflicting theories, inconsistent evidence,
  circular reasoning, ontology conflicts, and experimental disagreement.

  Ranks contradictions by importance and tracks resolution status.
  """
  use GenServer

  @table_name :cil_contradictions

  defstruct [:table, :total_found]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:set, :public, :named_table,
                                   write_concurrency: true, read_concurrency: true])
    {:ok, %{table: table, total_found: 0}}
  end

  @doc "Report a contradiction."
  @spec report(atom(), String.t(), String.t(), String.t(), map()) :: {:ok, String.t()}
  def report(type, entity_a, entity_b, description, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:report, type, entity_a, entity_b, description, metadata})
  end

  @doc "List contradictions, optionally filtered by type."
  @spec list(atom()) :: [map()]
  def list(type \\ nil) do
    @table_name
    |> :ets.tab2list()
    |> Enum.map(fn {_id, c} -> c end)
    |> Enum.filter(fn c -> is_nil(type) or c.type == type end)
    |> Enum.sort_by(& &1.importance, :desc)
  end

  @doc "Resolve a contradiction."
  @spec resolve(String.t(), String.t()) :: :ok
  def resolve(id, resolution) do
    GenServer.cast(__MODULE__, {:resolve, id, resolution})
  end

  @impl true
  def handle_call({:report, type, entity_a, entity_b, description, metadata}, _from, state) do
    id = uuid_v4()
    contradiction = %{
      id: id, type: type, entity_a: entity_a, entity_b: entity_b,
      description: description, metadata: metadata,
      importance: compute_importance(type, metadata),
      resolved: false, resolution: nil,
      reported_at: DateTime.utc_now()
    }
    :ets.insert(@table_name, {id, contradiction})
    {:reply, {:ok, id}, %{state | total_found: state.total_found + 1}}
  end

  @impl true
  def handle_cast({:resolve, id, resolution}, state) do
    case :ets.lookup(@table_name, id) do
      [{^id, entry}] ->
        :ets.insert(@table_name, {id, %{entry | resolved: true, resolution: resolution}})
      _ -> :ok
    end
    {:noreply, state}
  end

  defp compute_importance(:circular_reasoning, _), do: 9
  defp compute_importance(:conflicting_theories, _), do: 8
  defp compute_importance(:ontology_conflict, _), do: 7
  defp compute_importance(:experimental_disagreement, meta) do
    Map.get(meta, :severity, 5)
  end
  defp compute_importance(:inconsistent_evidence, meta) do
    Map.get(meta, :severity, 5)
  end
  defp compute_importance(_, meta), do: Map.get(meta, :severity, 5)

  defp uuid_v4 do
    <<a::64, b::64>> = :crypto.strong_rand_bytes(16)
    <<u1::48, _::4, u2::12, _::2, u3::62>> = <<a::64, b::64>>
    <<u1::48, 4::4, u2::12, 2::2, u3::62>>
    |> Base.encode16(case: :lower)
    |> then(fn s ->
      "#{String.slice(s, 0, 8)}-#{String.slice(s, 8, 4)}-#{String.slice(s, 12, 4)}-#{String.slice(s, 16, 4)}-#{String.slice(s, 20, 12)}"
    end)
  end
end
