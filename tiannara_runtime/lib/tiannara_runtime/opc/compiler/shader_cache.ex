defmodule Tiannara.OPC.Compiler.ShaderCache do
  @moduledoc """
  Phase 5F.6 — Shader Cache

  Caches compiled GLSL shaders to avoid redundant compilation.
  Uses cryptographic hashing of OIR instructions as cache keys.
  Supports TTL-based expiration and LRU eviction.

  ## Features

  - SHA256-based cache key generation from OIR
  - Configurable TTL (time-to-live) for cache entries
  - Maximum cache size with automatic eviction
  - Cache hit/miss metrics tracking

  ## Usage

      oir = [{:load_const, 1.0}, {:binary_exec, :+}]
      shader = "#version 310 es..."

      # Store in cache
      ShaderCache.store(oir, shader)

      # Retrieve from cache
      {:ok, cached_shader} = ShaderCache.lookup(oir)
  """

  use GenServer
  require Logger

  # Default TTL: 1 hour (3600 seconds)
  @default_ttl 3600

  # Maximum cache size: 1000 shaders
  @max_cache_size 1000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Stores a compiled shader in the cache.

  ## Parameters
  - `oir`: OIR instruction list (used to generate cache key)
  - `shader`: Compiled GLSL shader string
  - `ttl`: Time-to-live in seconds (optional, defaults to 3600)

  ## Returns
  - `:ok` on success
  """
  def store(oir, shader, ttl \\ @default_ttl) do
    GenServer.cast(__MODULE__, {:store, oir, shader, ttl})
  end

  @doc """
  Looks up a shader in the cache by OIR.

  ## Parameters
  - `oir`: OIR instruction list

  ## Returns
  - `{:ok, shader}` if found
  - `{:error, :cache_miss}` if not found
  """
  def lookup(oir) do
    GenServer.call(__MODULE__, {:lookup, oir})
  end

  @doc """
  Clears expired entries from the cache.
  """
  def cleanup() do
    GenServer.cast(__MODULE__, :cleanup)
  end

  @doc """
  Gets cache statistics.

  ## Returns
  - Map with cache metrics (size, hits, misses, hit_rate)
  """
  def stats() do
    GenServer.call(__MODULE__, :stats)
  end

  @doc """
  Clears the entire cache.
  """
  def clear() do
    GenServer.cast(__MODULE__, :clear)
  end

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    state = %{
      cache: %{},           # %{cache_key => {shader, expiry_time}}
      lru_order: [],        # List of cache keys in access order (most recent first)
      hits: 0,
      misses: 0,
      total_stores: 0
    }

    Logger.info("🗄️ [ShaderCache] Initialized with max size #{@max_cache_size}")
    {:ok, state}
  end

  @impl true
  def handle_cast({:store, oir, shader, ttl}, state) do
    cache_key = generate_cache_key(oir)
    expiry_time = System.system_time(:second) + ttl

    # Evict if cache is full
    new_state = evict_if_needed(state)

    # Store in cache
    new_cache = Map.put(new_state.cache, cache_key, {shader, expiry_time})
    new_lru = [cache_key | Enum.reject(new_state.lru_order, &(&1 == cache_key))]

    Logger.debug("💾 [ShaderCache] Stored shader (key: #{String.slice(cache_key, 0, 8)}...)")

    {:noreply, %{new_state |
      cache: new_cache,
      lru_order: new_lru,
      total_stores: new_state.total_stores + 1
    }}
  end

  @impl true
  def handle_cast(:cleanup, state) do
    now = System.system_time(:second)

    # Remove expired entries
    {valid_entries, expired_keys} = Enum.split_with(state.cache, fn {_key, {_shader, expiry}} ->
      expiry > now
    end)

    expired_count = length(expired_keys)
    new_lru = Enum.reject(state.lru_order, fn key ->
      Keyword.has_key?(expired_keys, key)
    end)

    if expired_count > 0 do
      Logger.info("🧹 [ShaderCache] Cleaned up #{expired_count} expired entries")
    end

    {:noreply, %{state | cache: valid_entries, lru_order: new_lru}}
  end

  @impl true
  def handle_cast(:clear, state) do
    Logger.info("🗑️ [ShaderCache] Cache cleared")
    {:noreply, %{state | cache: %{}, lru_order: [], hits: 0, misses: 0}}
  end

  @impl true
  def handle_call({:lookup, oir}, _from, state) do
    cache_key = generate_cache_key(oir)

    case Map.get(state.cache, cache_key) do
      nil ->
        # Cache miss
        new_state = %{state | misses: state.misses + 1}
        {:reply, {:error, :cache_miss}, new_state}

      {shader, expiry_time} ->
        now = System.system_time(:second)

        if expiry_time > now do
          # Cache hit - update LRU order
          new_lru = [cache_key | Enum.reject(state.lru_order, &(&1 == cache_key))]
          new_state = %{state | hits: state.hits + 1, lru_order: new_lru}

          Logger.debug("✅ [ShaderCache] Cache hit (key: #{String.slice(cache_key, 0, 8)}...)")
          {:reply, {:ok, shader}, new_state}
        else
          # Expired entry
          new_cache = Map.delete(state.cache, cache_key)
          new_lru = Enum.reject(state.lru_order, &(&1 == cache_key))
          new_state = %{state | misses: state.misses + 1, cache: new_cache, lru_order: new_lru}

          {:reply, {:error, :cache_miss}, new_state}
        end
    end
  end

  @impl true
  def handle_call(:stats, _from, state) do
    total_requests = state.hits + state.misses
    hit_rate = if total_requests > 0, do: (state.hits / total_requests) * 100, else: 0.0

    stats = %{
      size: map_size(state.cache),
      max_size: @max_cache_size,
      hits: state.hits,
      misses: state.misses,
      hit_rate: Float.round(hit_rate, 2),
      total_stores: state.total_stores,
      utilization: (map_size(state.cache) / @max_cache_size) * 100
    }

    {:reply, {:ok, stats}, state}
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp generate_cache_key(oir) do
    # Convert OIR to canonical string representation and hash it
    oir_string = :erlang.term_to_binary(oir)
    :crypto.hash(:sha256, oir_string) |> Base.encode16(case: :lower)
  end

  defp evict_if_needed(state) do
    if map_size(state.cache) >= @max_cache_size do
      # Evict least recently used entry
      case List.last(state.lru_order) do
        nil ->
          state

        lru_key ->
          new_cache = Map.delete(state.cache, lru_key)
          new_lru = List.delete(state.lru_order, lru_key)

          Logger.debug("🔄 [ShaderCache] Evicted LRU entry (key: #{String.slice(lru_key, 0, 8)}...)")
          %{state | cache: new_cache, lru_order: new_lru}
      end
    else
      state
    end
  end
end
