defmodule Tiannara.Stabilization.OLEF.Cache do
  @moduledoc """
  Cache for OLEF pressure fields and entropy distributions.

  Provides fast access to field states with intelligent caching strategies.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_pressure_field(ontology_id) do
    GenServer.call(__MODULE__, {:get_pressure_field, ontology_id})
  end

  def put_pressure_field(ontology_id, field, opts \\ []) do
    GenServer.call(__MODULE__, {:put_pressure_field, ontology_id, field, opts})
  end

  def get_entropy_distribution() do
    GenServer.call(__MODULE__, :get_entropy_distribution)
  end

  def put_entropy_distribution(distribution) do
    GenServer.call(__MODULE__, {:put_entropy_distribution, distribution})
  end

  def get_cache_stats() do
    GenServer.call(__MODULE__, :get_cache_stats)
  end

  def clear_expired() do
    GenServer.call(__MODULE__, :clear_expired)
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Initialize ETS tables for caching
    :ets.new(:olef_pressure_cache, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    :ets.new(:olef_entropy_cache, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    :ets.new(:olef_cache_metadata, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    Logger.info("OLEF cache initialized")
    
    {:ok, %{
      max_size: 1000,
      ttl: 300_000,  # 5 minutes
      cache_hits: 0,
      cache_misses: 0,
      evictions: 0,
      last_cleanup: System.system_time(:millisecond)
    }}
  end

  @impl true
  def handle_call({:get_pressure_field, ontology_id}, _from, state) do
    case :ets.lookup(:olef_pressure_cache, ontology_id) do
      [{^ontology_id, field}] ->
        # Check if cache entry is still valid
        current_time = System.system_time(:millisecond)
        case get_cache_metadata(ontology_id) do
          {:ok, timestamp} when timestamp + state.ttl > current_time ->
            Logger.debug("Cache hit for pressure field #{ontology_id}")
            {:reply, {:ok, field}, update_cache_stats(state, :hit)}
          _ ->
            # Entry expired, remove it
            :ets.delete(:olef_pressure_cache, ontology_id)
            :ets.delete(:olef_cache_metadata, ontology_id)
            Logger.debug("Cache miss for pressure field #{ontology_id} (expired)")
            {:reply, {:error, :not_found}, update_cache_stats(state, :miss)}
        end

      [] ->
        Logger.debug("Cache miss for pressure field #{ontology_id}")
        {:reply, {:error, :not_found}, update_cache_stats(state, :miss)}
    end
  end

  @impl true
  def handle_call({:put_pressure_field, ontology_id, field, opts}, _from, state) do
    max_size = Keyword.get(opts, :max_size, state.max_size)
    
    # Check if we need to evict items
    new_state = maybe_evict_cache(state, max_size)
    
    # Store field in cache
    :ets.insert(:olef_pressure_cache, {ontology_id, field})
    :ets.insert(:olef_cache_metadata, {ontology_id, System.system_time(:millisecond)})
    
    Logger.debug("Cached pressure field for ontology #{ontology_id}")
    
    {:reply, :ok, %{new_state | 
      last_cleanup: System.system_time(:millisecond)
    }}
  end

  @impl true
  def handle_call(:get_entropy_distribution, _from, state) do
    # Get the most recent entropy distribution
    case :ets.last(:olef_entropy_cache) do
      :"$end_of_table" ->
        {:reply, {:error, :not_found}, state}
      timestamp ->
        case :ets.lookup(:olef_entropy_cache, timestamp) do
          [{^timestamp, distribution}] ->
            {:reply, {:ok, distribution}, state}
          [] ->
            {:reply, {:error, :not_found}, state}
        end
    end
  end

  @impl true
  def handle_call({:put_entropy_distribution, distribution}, _from, state) do
    timestamp = System.system_time(:millisecond)
    
    # Store entropy distribution
    :ets.insert(:olef_entropy_cache, {timestamp, distribution})
    
    # Keep only recent distributions (last 10)
    cleanup_old_entropy_distributions()
    
    Logger.debug("Cached entropy distribution at #{timestamp}")
    
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:get_cache_stats, _from, state) do
    stats = %{
      pressure_cache_size: :ets.info(:olef_pressure_cache, :size),
      entropy_cache_size: :ets.info(:olef_entropy_cache, :size),
      cache_hits: state.cache_hits,
      cache_misses: state.cache_misses,
      eviction_count: state.evictions,
      hit_rate: calculate_hit_rate(state.cache_hits, state.cache_misses)
    }
    
    {:reply, {:ok, stats}, state}
  end

  @impl true
  def handle_call(:clear_expired, _from, state) do
    current_time = System.system_time(:millisecond)
    
    # Clean up expired pressure fields
    expired_pressure = :ets.select(:olef_pressure_cache, [{
      {:"$1", :"$2"},
      [{:>, {:+, {:element, 2, {:element, 1, :"$1"}}, state.ttl}}, current_time],
      [:"$1"]
    }])
    
    Enum.each(expired_pressure, fn ontology_id ->
      :ets.delete(:olef_pressure_cache, ontology_id)
      :ets.delete(:olef_cache_metadata, ontology_id)
    end)
    
    # Clean up old entropy distributions (keep only last 100)
    cleanup_old_entropy_distributions(100)
    
    Logger.info("Cleaned up #{length(expired_pressure)} expired pressure fields")
    
    {:reply, :ok, %{state | last_cleanup: current_time}}
  end

  # Helper functions
  defp get_cache_metadata(ontology_id) do
    case :ets.lookup(:olef_cache_metadata, ontology_id) do
      [{^ontology_id, timestamp}] -> {:ok, timestamp}
      [] -> {:error, :not_found}
    end
  end

  defp maybe_evict_cache(state, max_size) when state.max_size >= max_size do
    # Evict least recently used items
    evict_count = max(1, div(max_size, 10))  # Evict 10% of cache
    
    # Get LRU items
    lru_items = :ets.tab2list(:olef_cache_metadata)
    |> Enum.sort_by(fn {_, timestamp} -> timestamp end)
    |> Enum.take(evict_count)
    
    # Evict from cache and metadata
    Enum.each(lru_items, fn {ontology_id, _} ->
      :ets.delete(:olef_pressure_cache, ontology_id)
      :ets.delete(:olef_cache_metadata, ontology_id)
    end)

    Logger.debug("Evicted #{evict_count} cache entries")
    
    %{state | evictions: state.evictions + evict_count}
  end

  defp maybe_evict_cache(state, _max_size), do: state

  defp cleanup_old_entropy_distributions(keep_count \\ 10) do
    # Get all entropy distribution timestamps
    all_timestamps =
      :ets.tab2list(:olef_entropy_cache)
      |> Enum.map(fn {k, _} -> k end)
      |> Enum.sort()
    
    # Keep only the most recent entries
    to_delete = case length(all_timestamps) do
      n when n > keep_count -> Enum.take(all_timestamps, n - keep_count)
      _ -> []
    end
    
    # Delete old entries
    Enum.each(to_delete, fn timestamp ->
      :ets.delete(:olef_entropy_cache, timestamp)
    end)
  end

  defp update_cache_stats(%{cache_hits: hits, cache_misses: _misses} = state, :hit) do
    %{state | cache_hits: hits + 1}
  end

  defp update_cache_stats(%{cache_hits: _hits, cache_misses: misses} = state, :miss) do
    %{state | cache_misses: misses + 1}
  end

  defp calculate_hit_rate(hits, misses) when hits + misses > 0 do
    hits / (hits + misses)
  end

  defp calculate_hit_rate(_hits, _misses), do: 0.0
end
