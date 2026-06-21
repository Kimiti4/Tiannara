defmodule Tiannara.Core.Ontology.Cache do
  @moduledoc """
  Cache for compressed ontologies and their metadata.

  Provides fast access to frequently accessed ontologies while managing memory usage.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get(ontology_id) do
    GenServer.call(__MODULE__, {:get, ontology_id})
  end

  def put(ontology_id, ontology, opts \\ []) do
    GenServer.call(__MODULE__, {:put, ontology_id, ontology, opts})
  end

  def evict(ontology_id) do
    GenServer.call(__MODULE__, {:evict, ontology_id})
  end

  def clear() do
    GenServer.call(__MODULE__, :clear)
  end

  def get_stats() do
    GenServer.call(__MODULE__, :get_stats)
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Initialize cache with LRU eviction policy
    :ets.new(:ontology_cache, [
      :set, 
      :public, 
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    :ets.new(:cache_metadata, [
      :set,
      :public,
      :named_table
    ])

    Logger.info("Ontology cache initialized")

    {:ok, %{
      max_size: 1000,
      current_size: 0,
      hits: 0,
      misses: 0
    }}
  end

  @impl true
  def handle_call({:get, ontology_id}, _from, state) do
    case :ets.lookup(:ontology_cache, ontology_id) do
      [{^ontology_id, ontology}] ->
        # Update LRU timestamp
        :ets.insert(:cache_metadata, {ontology_id, System.system_time(:millisecond)})
        Logger.debug("Cache hit for ontology #{ontology_id}")
        {:reply, {:ok, ontology}, %{state | hits: state.hits + 1}}

      [] ->
        Logger.debug("Cache miss for ontology #{ontology_id}")
        {:reply, {:error, :not_found}, %{state | misses: state.misses + 1}}
    end
  end

  @impl true
  def handle_call({:put, ontology_id, ontology, opts}, _from, state) do
    max_size = Keyword.get(opts, :max_size, state.max_size)
    
    # Check if we need to evict items before adding new one
    new_state = maybe_evict_items(state, max_size)
    
    # Add to cache
    :ets.insert(:ontology_cache, {ontology_id, ontology})
    :ets.insert(:cache_metadata, {ontology_id, System.system_time(:millisecond)})

    Logger.debug("Added ontology #{ontology_id} to cache")
    
    {:reply, :ok, %{new_state | current_size: new_state.current_size + 1}}
  end

  @impl true
  def handle_call({:evict, ontology_id}, _from, state) do
    case :ets.lookup(:ontology_cache, ontology_id) do
      [{^ontology_id, _}] ->
        :ets.delete(:ontology_cache, ontology_id)
        :ets.delete(:cache_metadata, ontology_id)
        Logger.debug("Evicted ontology #{ontology_id} from cache")
        {:reply, :ok, %{state | current_size: max(state.current_size - 1, 0)}}

      [] ->
        {:reply, :ok, state}
    end
  end

  @impl true
  def handle_call(:clear, _from, state) do
    :ets.delete_all_objects(:ontology_cache)
    :ets.delete_all_objects(:cache_metadata)
    
    Logger.info("Cleared ontology cache")
    
    {:reply, :ok, %{state | current_size: 0}}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      size: state.current_size,
      max_size: state.max_size,
      hits: state.hits,
      misses: state.misses,
      hit_rate: calculate_hit_rate(state.hits, state.misses)
    }

    {:reply, {:ok, stats}, state}
  end

  # Helper functions
  defp maybe_evict_items(state, max_size) when state.current_size >= max_size do
    # Evict least recently used items
    evict_count = max(1, div(max_size, 10))  # Evict 10% of cache
    
    # Get LRU items
    lru_items = :ets.tab2list(:cache_metadata)
    |> Enum.sort_by(fn {_, timestamp} -> timestamp end)
    |> Enum.take(evict_count)
    
    # Evict from cache and metadata
    Enum.each(lru_items, fn {ontology_id, _} ->
      :ets.delete(:ontology_cache, ontology_id)
      :ets.delete(:cache_metadata, ontology_id)
    end)

    %{state | current_size: state.current_size - evict_count}
  end

  defp maybe_evict_items(state, _max_size), do: state

  defp calculate_hit_rate(hits, misses) when hits + misses > 0 do
    hits / (hits + misses)
  end

  defp calculate_hit_rate(_hits, _misses), do: 0.0
end