defmodule Tiannara.REA.LineageRegistry do
  @moduledoc """
  Global registry of all evolutionary identities.
  
  This is what makes universal lineage tracking possible.
  Sentinel, archaeology engines, and meta-pressures all query this
  instead of maintaining per-type lineage trackers.
  
  Uses ETS for O(1) reads, GenServer for writes and ancestry queries.
  """
  use GenServer
  
  alias Tiannara.REA.EvolutionaryIdentity
  
  # --- Client API ---
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc "Register a new identity."
  @spec register(EvolutionaryIdentity.t()) :: :ok
  def register(%EvolutionaryIdentity{} = id) do
    GenServer.call(__MODULE__, {:register, id})
  end
  
  @doc "Look up an identity by ID."
  @spec get(binary()) :: EvolutionaryIdentity.t() | nil
  def get(id) do
    try do
      :ets.lookup_element(__MODULE__, id, 2)
    rescue
      ArgumentError -> nil
    end
  end
  
  @doc "Mark an identity extinct. Returns the frozen identity."
  @spec mark_extinct(binary(), non_neg_integer()) :: EvolutionaryIdentity.t() | nil
  def mark_extinct(id, epoch) do
    GenServer.call(__MODULE__, {:mark_extinct, id, epoch})
  end
  
  @doc "Get all living descendants of a given identity."
  @spec descendants(binary()) :: [EvolutionaryIdentity.t()]
  def descendants(id), do: GenServer.call(__MODULE__, {:descendants, id})
  
  @doc "Full lineage (ancestors) of an identity."
  @spec ancestors(binary()) :: [EvolutionaryIdentity.t()]
  def ancestors(id), do: GenServer.call(__MODULE__, {:ancestors, id})
  
  @doc "All living identities at a given level."
  @spec living_at_level(atom()) :: [EvolutionaryIdentity.t()]
  def living_at_level(level) do
    :ets.match_object(__MODULE__, {:_, %{level: level, extinction_epoch: nil}})
    |> Enum.map(fn {_, id} -> id end)
  end
  
  @doc "Total counts by level (living / extinct)."
  @spec stats() :: map()
  def stats, do: GenServer.call(__MODULE__, :stats)
  
  @doc "Reset the registry for testing."
  def reset, do: GenServer.call(__MODULE__, :reset)
  
  # --- Server ---
  
  @impl true
  def init(_opts) do
    table = :ets.new(__MODULE__, [:named_table, :public, :set, {:read_concurrency, true}])
    # Inverse index: parent_id -> [child_ids] for fast ancestry traversal
    children_table = :ets.new(:"#{__MODULE__}.children", [:named_table, :public, :bag])
    {:ok, %{table: table, children: children_table}}
  end
  
  @impl true
  def handle_call({:register, id}, _from, state) do
    :ets.insert(state.table, {id.id, id})
    for parent <- id.parent_ids do
      :ets.insert(state.children, {parent, id.id})
    end
    {:reply, :ok, state}
  end
  
  @impl true
  def handle_call({:mark_extinct, id, epoch}, _from, state) do
    case :ets.lookup(state.table, id) do
      [{^id, existing}] ->
        frozen = EvolutionaryIdentity.mark_extinct(existing, epoch)
        :ets.insert(state.table, {id, frozen})
        {:reply, frozen, state}
      [] ->
        {:reply, nil, state}
    end
  end
  
  @impl true
  def handle_call({:descendants, root_id}, _from, state) do
    result = traverse_down(root_id, state.children, state.table, MapSet.new())
    {:reply, MapSet.to_list(result), state}
  end
  
  @impl true
  def handle_call({:ancestors, id}, _from, state) do
    result = traverse_up(id, state.table, MapSet.new())
    {:reply, MapSet.to_list(result), state}
  end
  
  @impl true
  def handle_call(:stats, _from, state) do
    all = :ets.tab2list(state.table) |> Enum.map(fn {_, id} -> id end)
    stats =
      all
      |> Enum.group_by(& &1.level)
      |> Enum.map(fn {level, ids} ->
        {living, dead} = Enum.split_with(ids, &is_nil(&1.extinction_epoch))
        {level, %{living: length(living), extinct: length(dead)}}
      end)
      |> Map.new()
    {:reply, stats, state}
  end
  
  @impl true
  def handle_call(:reset, _from, state) do
    :ets.delete_all_objects(state.table)
    :ets.delete_all_objects(state.children)
    {:reply, :ok, state}
  end
  
  defp traverse_down(id, children_t, main_t, acc) do
    if MapSet.member?(acc, id) do
      acc
    else
      acc = MapSet.put(acc, id)
      child_ids = :ets.lookup(children_t, id) |> Enum.map(fn {_, cid} -> cid end)
      Enum.reduce(child_ids, acc, fn cid, a ->
        case :ets.lookup(main_t, cid) do
          [{_, identity}] ->
            if is_nil(identity.extinction_epoch), do: traverse_down(cid, children_t, main_t, MapSet.put(a, cid)), else: a
          [] -> a
        end
      end)
    end
  end
  
  defp traverse_up(id, main_t, acc) do
    if MapSet.member?(acc, id) do
      acc
    else
      case :ets.lookup(main_t, id) do
        [{_, identity}] ->
          acc = MapSet.put(acc, id)
          Enum.reduce(identity.parent_ids, acc, fn pid, a -> traverse_up(pid, main_t, a) end)
        [] -> acc
      end
    end
  end
end
