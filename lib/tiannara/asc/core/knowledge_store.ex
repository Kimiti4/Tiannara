defmodule Tiannara.ASC.Core.KnowledgeStore do
  @moduledoc """
  Shared evidence/knowledge memory (Data -> Information -> Knowledge path).

  Entries carry trace_id and parent_id for lineage:

      {id, trace_id, kind, payload, parent_id, seq, inserted_at}

  KNOWN BOTTLENECK (recorded, not hidden): ETS state is lost on store
  crash. Persistence through the Milestone A DETS substrate is a Milestone
  C experiment, not part of B's scope.
  """

  use GenServer

  @table :asc_knowledge

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def put(kind, payload, opts \\ []) do
    GenServer.call(__MODULE__, {:put, kind, payload, opts})
  end

  def get(id) do
    case :ets.lookup(@table, id) do
      [entry] -> {:ok, entry}
      [] -> {:error, :not_found}
    end
  end

  def by_trace(trace_id) do
    @table
    |> :ets.tab2list()
    |> Enum.filter(fn {_id, t, _k, _p, _par, _seq, _ts} -> t == trace_id end)
    |> Enum.sort_by(fn {_id, _t, _k, _p, _par, seq, _ts} -> seq end)
  end

  def search(topic) when is_binary(topic) do
    @table
    |> :ets.tab2list()
    |> Enum.filter(fn {_id, _t, _k, payload, _par, _seq, _ts} ->
      String.contains?(inspect(payload), topic)
    end)
  end

  @impl true
  def init(_) do
    if :ets.whereis(@table) == :undefined do
      :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
    end

    {:ok, %{seq: 0}}
  end

  @impl true
  def handle_call({:put, kind, payload, opts}, _from, %{seq: seq} = state) do
    id = {:k, System.unique_integer([:monotonic, :positive])}
    trace_id = Keyword.get(opts, :trace_id)
    parent_id = Keyword.get(opts, :parent_id)

    entry = {id, trace_id, kind, payload, parent_id, seq, System.system_time(:millisecond)}
    :ets.insert(@table, entry)

    {:reply, {:ok, id}, %{state | seq: seq + 1}}
  end
end