defmodule Tiannara.Executive.ETSCache do
  @moduledoc """
  ETS hot cache for Executive Memory.

  Provides fast in-memory reads with periodic sync-back to DETS.
  """

  @doc "Creates a named ETS table for the given memory name."
  def create(name) do
    :ets.new(cache_name(name), [:set, :public, :named_table,
      {:write_concurrency, true}, {:read_concurrency, true}])
  end

  @doc "Looks up a key in the cache."
  def get(name, key) do
    case :ets.lookup(cache_name(name), key) do
      [{^key, value}] -> {:ok, value}
      [] -> :error
    end
  end

  @doc "Inserts a key-value pair into the cache."
  def put(name, key, value) do
    :ets.insert(cache_name(name), {key, value})
    :ok
  end

  @doc "Deletes a key from the cache."
  def delete(name, key) do
    :ets.delete(cache_name(name), key)
    :ok
  end

  @doc "Warms the cache by bulk-inserting entries from an enumerable."
  def warm(name, entries, _opts \\ []) do
    :ets.insert(cache_name(name), entries)
    :ok
  end

  @doc "Evicts a subset of keys from the cache."
  def evict(name, keys) when is_list(keys) do
    Enum.each(keys, &:ets.delete(cache_name(name), &1))
    :ok
  end

  @doc "Syncs all cache entries back to DETS."
  def sync_to_dets(name, dets_ref) do
    cache_name(name)
    |> :ets.tab2list()
    |> Enum.each(fn {k, v} -> :dets.insert(dets_ref, {k, v}) end)
    :ok
  end

  @doc "Destroys the ETS table."
  def destroy(name) do
    :ets.delete(cache_name(name))
  end

  @doc "Returns cache size."
  def size(name) do
    :ets.info(cache_name(name), :size) || 0
  end

  @doc "Returns all keys in cache."
  def keys(name) do
    :ets.match(cache_name(name), :"$1") |> List.flatten()
  end

  defp cache_name(name), do: :"#{name}_cache"
end
