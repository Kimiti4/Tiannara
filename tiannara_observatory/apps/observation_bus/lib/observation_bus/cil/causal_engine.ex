defmodule ObservationBus.CIL.CausalEngine do
  @moduledoc """
  Maintains a causal graph connecting events by causal relationships.

  Every event can have:
    * **Causal ancestors** — events that caused it
    * **Causal descendants** — events it caused

  Mission Control can trace root causes interactively by walking the
  causal graph in either direction.
  """
  use GenServer

  @table_name :cil_causal_graph

  defstruct [:table, :total_links, :total_events]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:set, :public, :named_table,
                                   write_concurrency: true,
                                   read_concurrency: true])
    {:ok, %{table: table, total_links: 0, total_events: 0}}
  end

  @doc "Record a causal link from `cause_id` to `effect_id`."
  @spec record_link(String.t(), String.t(), map()) :: :ok
  def record_link(cause_id, effect_id, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:record_link, cause_id, effect_id, metadata})
  end

  @doc "Record an event node in the causal graph."
  @spec record_event(String.t(), map()) :: :ok
  def record_event(event_id, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:record_event, event_id, metadata})
  end

  @doc "Get all causal ancestors of a given event (root causes)."
  @spec ancestors(String.t()) :: [map()]
  def ancestors(event_id) do
    traverse(:up, event_id, %{}, [])
  end

  @doc "Get all causal descendants of a given event."
  @spec descendants(String.t()) :: [map()]
  def descendants(event_id) do
    traverse(:down, event_id, %{}, [])
  end

  @doc "Get immediate causal parents of an event."
  @spec parents(String.t()) :: [String.t()]
  def parents(event_id) do
    @table_name
    |> :ets.match({{:link, :_, event_id}, :"$1"})
    |> List.flatten()
  end

  @doc "Get immediate causal children of an event."
  @spec children(String.t()) :: [String.t()]
  def children(event_id) do
    @table_name
    |> :ets.match({{:link, event_id, :_}, :"$1"})
    |> List.flatten()
  end

  @doc "Get siblings (events sharing a causal parent)."
  @spec siblings(String.t()) :: [String.t()]
  def siblings(event_id) do
    my_parents = parents(event_id)
    my_parents
    |> Enum.flat_map(&children/1)
    |> Enum.uniq()
    |> List.delete(event_id)
  end

  @doc "Trace a causal path from root to event."
  @spec causal_path(String.t()) :: [String.t()]
  def causal_path(event_id) do
    ancestors(event_id) ++ [event_id]
  end

  @doc "Return engine stats."
  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def handle_cast({:record_link, cause_id, effect_id, metadata}, state) do
    key = {:link, cause_id, effect_id}
    :ets.insert(@table_name, {key, metadata})
    {:noreply, %{state | total_links: state.total_links + 1}}
  end

  def handle_cast({:record_event, event_id, metadata}, state) do
    key = {:event, event_id}
    :ets.insert(@table_name, {key, metadata})
    {:noreply, %{state | total_events: state.total_events + 1}}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{
      total_links: state.total_links,
      total_events: state.total_events,
      table_size: :ets.info(@table_name, :size)
    }, state}
  end

  defp traverse(:up, event_id, visited, acc) do
    @table_name
    |> :ets.match({{:link, :"$1", event_id}, :_})
    |> List.flatten()
    |> Enum.reduce(acc, fn parent_id, acc2 ->
      if Map.has_key?(visited, parent_id) do
        acc2
      else
        [parent_id | traverse(:up, parent_id, Map.put(visited, parent_id, true), acc2)]
      end
    end)
    |> Enum.uniq()
  end

  defp traverse(:down, event_id, visited, acc) do
    @table_name
    |> :ets.match({{:link, event_id, :"$1"}, :_})
    |> List.flatten()
    |> Enum.reduce(acc, fn child_id, acc2 ->
      if Map.has_key?(visited, child_id) do
        acc2
      else
        [child_id | traverse(:down, child_id, Map.put(visited, child_id, true), acc2)]
      end
    end)
    |> Enum.uniq()
  end
end
