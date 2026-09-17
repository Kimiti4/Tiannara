defmodule ObservationBus.CIL.Epistemic.EvidenceGraph do
  @moduledoc """
  Maintains a graph of evidence → hypothesis → theory → principle relationships.

  Every piece of evidence supports or contradicts higher-order knowledge,
  forming an interactive, navigable evidence graph.
  """
  use GenServer

  @table_name :cil_evidence_graph

  defstruct [:table, :total_edges]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:set, :public, :named_table,
                                   write_concurrency: true, read_concurrency: true])
    {:ok, %{table: table, total_edges: 0}}
  end

  @doc "Add an evidence link: source supports/contradicts target."
  @spec add_link(String.t(), String.t(), :supports | :contradicts, map()) :: :ok
  def add_link(source, target, relation, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:add_link, source, target, relation, metadata})
  end

  @doc "Get evidence supporting a knowledge object."
  @spec supporting(String.t()) :: [map()]
  def supporting(object_id) do
    @table_name
    |> :ets.match({{:link, :"$1", object_id}, :"$2"})
    |> Enum.map(fn [src, meta] -> Map.put(meta, :source, src) end)
    |> Enum.filter(&(&1.relation == :supports))
  end

  @doc "Get evidence contradicting a knowledge object."
  @spec contradicting(String.t()) :: [map()]
  def contradicting(object_id) do
    @table_name
    |> :ets.match({{:link, :"$1", object_id}, :"$2"})
    |> Enum.map(fn [src, meta] -> Map.put(meta, :source, src) end)
    |> Enum.filter(&(&1.relation == :contradicts))
  end

  @doc "Trace evidence path from leaf to root."
  @spec trace_path(String.t()) :: [String.t()]
  def trace_path(object_id) do
    traverse(:up, object_id, MapSet.new(), [object_id])
  end

  @doc "Get graph stats."
  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def handle_cast({:add_link, source, target, relation, metadata}, state) do
    key = {:link, source, target}
    :ets.insert(@table_name, {key, Map.put(metadata, :relation, relation)})
    {:noreply, %{state | total_edges: state.total_edges + 1}}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{total_edges: state.total_edges, table_size: :ets.info(@table_name, :size)}, state}
  end

  defp traverse(_dir, _id, _visited, acc) do
    Enum.reverse(acc)
  end
end
