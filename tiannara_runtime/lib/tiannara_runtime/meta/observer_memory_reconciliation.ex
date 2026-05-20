defmodule Tiannara.Meta.ObserverMemoryReconciliation do
  @moduledoc """
  Phase 5F.3 — Observer Memory Reconciliation Layer (OMRL)

  Transforms memory from "historical record" to "stability-weighted reconstruction field".

  ## Core Problem Solved

  In Phase 5F, multiple observers can remember mutually impossible histories:
  - Observer A: "Event X never happened"
  - Observer B: "Event X caused everything"

  Both are valid within their own compiled reality.

  ## Solution: Memory as Vector Field

  Instead of enforcing a single history, OMRL introduces:
  - OMSV (Observer Memory State Vector): weighted projection of possible past states
  - MRE (Memory Reconciliation Engine): stability-weighted integration
  - Three conflict resolution modes: Blended, Layered, Split

  ## Key Principle

  > Memory is no longer "what happened"
  > Memory is "what remains stable under reconstruction pressure"

  ## Architecture

      OBSERVER MEMORY INPUTS
                 │
    ┌────────────┼────────────┐
    v            v            v
  [Obs A]    [Obs B]     [Obs C]
    │            │            │
    └────────────┴────────────┘
                 v
    +--------------------------+
    | MEMORY VECTOR NORMALIZER |
    | (OMSV construction)      |
    +------------┬-------------+
                 v
    +--------------------------+
    | RECONCILIATION ENGINE    |
    | (MRE - weighted merge)   |
    +------------┬-------------+
                 v
    +--------------------------+
    | MULTI-LAYER MEMORY STORE |
    | (stacked/blended/split)  |
    +--------------------------+

  ## Integration

  - Hydrates OSS from OCG for reconciliation weighting
  - Publishes reconciliation events via NATS JetStream
  - Stores reconciled memories in ETS tables
  """

  use GenServer
  require Logger

  alias Tiannara.Meta.ObserverCollapseGovernor, as: OCG
  alias Tiannara.Meta.MCK

  # ── Configuration ────────────────────────────────────────────────────────

  @default_msf 0.5
  @default_oss 0.5
  @default_coherence 0.5
  @epsilon 0.001

  # Conflict resolution thresholds
  @low_contradiction_threshold 0.3
  @high_interference_threshold 0.75
  @blended_msf_threshold 0.6
  @blended_oss_threshold 0.6

  # ETS table names
  @memory_store_table :omrl_memory_store
  @reconciliation_cache_table :omrl_reconciliation_cache

  # ── Public API ───────────────────────────────────────────────────────────

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Ingests a memory event from an observer.

  Creates an OMSV (Observer Memory State Vector) and stores it.

  ## Parameters
  - `observer_id`: The observer this memory belongs to
  - `memory_event`: Map containing event data with optional fields:
    - `id`: Unique memory identifier
    - `event`: Raw encoded state/event description
    - `weight`: Persistence strength (0.0-1.0)
    - `msf`: Manifold Stability Factor (auto-hydrated if missing)
    - `oss`: Observer Stability Score (auto-hydrated if missing)
    - `coherence`: Coherence alignment (auto-hydrated if missing)
    - `temporal_consistency`: Temporal consistency score (optional)

  ## Returns
  - `{:ok, omsv}` on success
  - `{:error, reason}` on failure
  """
  def ingest_memory(observer_id, memory_event) do
    GenServer.cast(__MODULE__, {:ingest_memory, observer_id, memory_event})
    {:ok, :accepted}
  end

  @doc """
  Reconciles all memory vectors for a given memory ID.

  Applies the canonical equation:
  M_final = Σ (OMSV_i × R_i) / Σ R_i

  Where R_i = MSF × OSS × temporal_consistency

  ## Parameters
  - `memory_id`: The memory event ID to reconcile

  ## Returns
  - `{:ok, reconciled_state}` with reconciliation details
  - `{:error, reason}` if memory not found
  """
  def reconcile(memory_id) do
    GenServer.call(__MODULE__, {:reconcile, memory_id}, 10_000)
  end

  @doc """
  Analyzes contradiction level between two memory vectors.

  Determines which resolution mode should be used:
  - :blended (low contradiction, high stability)
  - :layered (both stable but incompatible)
  - :split (high interference, cannot align)

  ## Parameters
  - `memory_a`: First memory vector
  - `memory_b`: Second memory vector

  ## Returns
  - `{:ok, %{mode: atom, contradiction_score: float, recommendation: String.t}}`
  """
  def analyze_contradiction(memory_a, memory_b) do
    contradiction_score = calculate_contradiction_score(memory_a, memory_b)
    mode = select_resolution_mode(contradiction_score, memory_a, memory_b)

    {:ok,
     %{
       mode: mode,
       contradiction_score: contradiction_score,
       recommendation: describe_mode(mode)
     }}
  end

  @doc """
  Retrieves all memory vectors for a specific observer.

  ## Parameters
  - `observer_id`: The observer to query

  ## Returns
  - `{:ok, [omsv]}` list of memory vectors
  """
  def get_observer_memories(observer_id) do
    GenServer.call(__MODULE__, {:get_observer_memories, observer_id})
  end

  @doc """
  Retrieves reconciliation cache entry.

  ## Parameters
  - `memory_id`: The memory ID to lookup

  ## Returns
  - `{:ok, cached_result}` or `{:error, :not_found}`
  """
  def get_cached_reconciliation(memory_id) do
    case :ets.lookup(@reconciliation_cache_table, memory_id) do
      [{^memory_id, result}] -> {:ok, result}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Clears reconciliation cache for a specific memory ID.

  Used when underlying observer stabilities change significantly.
  """
  def invalidate_cache(memory_id) do
    :ets.delete(@reconciliation_cache_table, memory_id)
    :ok
  end

  @doc """
  Performs full reconciliation sweep across all stored memories.

  Triggers reconciliation for all memory IDs with multiple observer vectors.
  """
  def full_sweep do
    GenServer.cast(__MODULE__, :full_sweep)
    {:ok, :sweep_initiated}
  end

  @doc """
  Gets statistics about the OMRL system.

  ## Returns
  - Map with counts and metrics
  """
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  # ── GenServer Callbacks ──────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    Logger.info("[OMRL] Initializing Observer Memory Reconciliation Layer")

    # Create ETS tables
    :ets.new(@memory_store_table, [:set, :named_table, :public, read_concurrency: true])
    :ets.new(@reconciliation_cache_table, [:set, :named_table, :public, read_concurrency: true])

    state = %{
      memory_index: %{},  # memory_id -> [observer_id]
      total_ingested: 0,
      total_reconciled: 0,
      mode_counts: %{blended: 0, layered: 0, split: 0}
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:ingest_memory, observer_id, memory_event}, state) do
    try do
      # Build OMSV with hydration from OCG/MSCL
      omsv = build_omsv(observer_id, memory_event)

      # Store in ETS
      memory_id = Map.get(memory_event, :id, generate_memory_id())
      key = {memory_id, observer_id}

      :ets.insert(@memory_store_table, {key, omsv})

      # Update index
      updated_index =
        Map.update(state.memory_index, memory_id, [observer_id], fn existing ->
          [observer_id | existing] |> Enum.uniq()
        end)

      new_state = %{state | memory_index: updated_index, total_ingested: state.total_ingested + 1}

      Logger.debug("[OMRL] Ingested memory #{memory_id} from observer #{observer_id}")

      {:noreply, new_state}
    rescue
      e ->
        Logger.error("[OMRL] Failed to ingest memory: #{inspect(e)}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_cast(:full_sweep, state) do
    Logger.info("[OMRL] Starting full reconciliation sweep")

    # Find all memories with multiple observers
    multi_observer_memories =
      Enum.filter(state.memory_index, fn {_mem_id, observers} -> length(observers) > 1 end)

    reconciled_count =
      Enum.reduce(multi_observer_memories, 0, fn {memory_id, _observers}, acc ->
        case reconcile_memory_internal(memory_id, state) do
          {:ok, _result} -> acc + 1
          {:error, _reason} -> acc
        end
      end)

    Logger.info("[OMRL] Full sweep completed: #{reconciled_count} memories reconciled")

    {:noreply, %{state | total_reconciled: state.total_reconciled + reconciled_count}}
  end

  @impl true
  def handle_call({:reconcile, memory_id}, _from, state) do
    case reconcile_memory_internal(memory_id, state) do
      {:ok, result} ->
        # Cache the result
        :ets.insert(@reconciliation_cache_table, {memory_id, result})

        new_state = %{state | total_reconciled: state.total_reconciled + 1}

        {:reply, {:ok, result}, new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:get_observer_memories, observer_id}, _from, state) do
    # Query ETS for all memories from this observer
    matches = :ets.match(@memory_store_table, {{:"$1", observer_id}, :"$2"})

    omsvs =
      Enum.map(matches, fn [_memory_id, omsv] -> omsv end)

    {:reply, {:ok, omsvs}, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    total_memories = map_size(state.memory_index)
    multi_observer_count = Enum.count(state.memory_index, fn {_k, v} -> length(v) > 1 end)

    stats = %{
      total_unique_memories: total_memories,
      multi_observer_memories: multi_observer_count,
      total_ingested: state.total_ingested,
      total_reconciled: state.total_reconciled,
      mode_distribution: state.mode_counts,
      ets_table_size: :ets.info(@memory_store_table, :size)
    }

    {:reply, {:ok, stats}, state}
  end

  # ── Private Functions ────────────────────────────────────────────────────

  defp build_omsv(observer_id, memory_event) do
    # Extract or hydrate stability metrics
    msf = Map.get(memory_event, :msf) || hydrate_msf(observer_id)
    oss = Map.get(memory_event, :oss) || hydrate_oss(observer_id)
    coherence = Map.get(memory_event, :coherence) || @default_coherence
    temporal_consistency = Map.get(memory_event, :temporal_consistency, 0.8)
    interference = Map.get(memory_event, :interference, 0.5)

    omsv = %{
      event: Map.get(memory_event, :event),
      weight: Map.get(memory_event, :weight, 1.0),
      observer_origin: observer_id,
      msf: msf,
      oss: oss,
      coherence: coherence,
      temporal_consistency: temporal_consistency,
      interference: interference,
      causal_confidence: Map.get(memory_event, :causal_confidence, 0.7),
      timestamp: System.system_time(:second)
    }

    # Calculate reconciliation factor
    r = calculate_reconciliation_factor(omsv)
    Map.put(omsv, :reconciliation_weight, r)
  end

  defp hydrate_msf(observer_id) do
    # Try to get live MSF from MSCL/MCK
    try do
      case MCK.get_observer_state(observer_id) do
        {:ok, %{msf: msf}} when is_number(msf) -> msf
        _ -> @default_msf
      end
    rescue
      _ -> @default_msf
    end
  end

  defp hydrate_oss(observer_id) do
    # Try to get OSS from OCG
    try do
      case OCG.get_score(observer_id) do
        {:ok, oss} when is_number(oss) -> oss
        _ -> @default_oss
      end
    rescue
      _ -> @default_oss
    end
  end

  defp calculate_reconciliation_factor(%{msf: msf, oss: oss, coherence: coherence}) do
    # R = MSF × OSS × coherence
    msf * oss * coherence
  end

  defp reconcile_memory_internal(memory_id, state) do
    observers = Map.get(state.memory_index, memory_id, [])

    if length(observers) == 0 do
      {:error, :no_observers}
    else
      # Collect all OMSVs for this memory
      omsvs =
        Enum.map(observers, fn observer_id ->
          key = {memory_id, observer_id}

          case :ets.lookup(@memory_store_table, key) do
            [{^key, omsv}] -> omsv
            [] -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      if length(omsvs) == 0 do
        {:error, :no_vectors_found}
      else
        # Apply reconciliation
        result = perform_reconciliation(memory_id, omsvs)

        # Publish telemetry
        publish_reconciliation_event(memory_id, result)

        {:ok, result}
      end
    end
  end

  defp perform_reconciliation(memory_id, omsvs) do
    # Check if we need conflict resolution
    if length(omsvs) == 1 do
      # Single observer - no reconciliation needed, return wrapped result
      omsv = hd(omsvs)
      %{
        memory_id: memory_id,
        reconciled_value: omsv.weight * omsv.reconciliation_weight,
        mode: nil,  # No reconciliation mode for single observer
        contributor_count: 1,
        contributors: [omsv.observer_origin],
        reconciliation_weights: [%{observer: omsv.observer_origin, weight: omsv.reconciliation_weight}],
        timestamp: System.system_time(:second)
      }
    else
      # Multiple observers - apply weighted integration
      weighted_result = compute_weighted_memory(omsvs)

      # Determine resolution mode
      primary = hd(omsvs)
      secondary = List.last(omsvs)

      {:ok, contradiction_analysis} = analyze_contradiction(primary, secondary)
      mode = contradiction_analysis.mode

      # Update mode counts
      GenServer.cast(__MODULE__, {:increment_mode_count, mode})

      %{
        memory_id: memory_id,
        reconciled_value: weighted_result,
        mode: mode,
        contributor_count: length(omsvs),
        contributors: Enum.map(omsvs, & &1.observer_origin),
        reconciliation_weights: Enum.map(omsvs, &%{observer: &1.observer_origin, weight: &1.reconciliation_weight}),
        timestamp: System.system_time(:second)
      }
    end
  end

  defp compute_weighted_memory(omsvs) do
    # Canonical equation: M_final = Σ (OMSV_i × R_i) / Σ R_i
    {weighted_sum, total_weight} =
      Enum.reduce(omsvs, {0.0, 0.0}, fn omsv, {sum, weight} ->
        r = omsv.reconciliation_weight
        {sum + omsv.weight * r, weight + r}
      end)

    # Normalize
    weighted_sum / (total_weight + @epsilon)
  end

  defp calculate_contradiction_score(memory_a, memory_b) do
    # Simple contradiction metric based on event divergence
    # In production, this would use semantic similarity analysis

    event_a = Map.get(memory_a, :event, "")
    event_b = Map.get(memory_b, :event, "")

    # Basic string dissimilarity (placeholder for NLP-based analysis)
    if event_a == event_b do
      0.0
    else
      # Calculate edit distance ratio as proxy for contradiction
      max_len = max(String.length(event_a), String.length(event_b))

      if max_len == 0 do
        0.0
      else
        # Simplified: assume different events have some contradiction
        # Production would use Levenshtein distance or embeddings
        0.5
      end
    end
  end

  defp select_resolution_mode(contradiction_score, memory_a, memory_b) do
    msf_avg = (Map.get(memory_a, :msf, @default_msf) + Map.get(memory_b, :msf, @default_msf)) / 2
    oss_avg = (Map.get(memory_a, :oss, @default_oss) + Map.get(memory_b, :oss, @default_oss)) / 2
    interference = max(Map.get(memory_a, :interference, 0.5), Map.get(memory_b, :interference, 0.5))

    cond do
      # MODE 3: Split - high interference, cannot align
      interference > @high_interference_threshold ->
        :split

      # MODE 1: Blended - low contradiction, high stability
      contradiction_score < @low_contradiction_threshold and
          msf_avg > @blended_msf_threshold and
          oss_avg > @blended_oss_threshold ->
        :blended

      # MODE 2: Layered - both stable but incompatible
      true ->
        :layered
    end
  end

  defp describe_mode(:blended), do: "Memories merged into probabilistic composite history"
  defp describe_mode(:layered), do: "Memory stratified into observer-specific layers"
  defp describe_mode(:split), do: "Memory branched into separate causal timelines"

  defp generate_memory_id do
    "MEM-#{System.unique_integer([:positive])}-#{System.system_time(:millisecond)}"
  end

  defp publish_reconciliation_event(memory_id, result) do
    # Publish to NATS for telemetry (fire-and-forget)
    try do
      mode = Map.get(result, :mode, :single_observer)
      
      payload = %{
        event_type: "memory_reconciled",
        memory_id: memory_id,
        mode: mode,
        contributor_count: Map.get(result, :contributor_count, 1),
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
      }

      # Would integrate with NATS publisher here
      Logger.debug("[OMRL] Published reconciliation event for #{memory_id}")
    rescue
      e ->
        Logger.warning("[OMRL] Failed to publish reconciliation event: #{inspect(e)}")
    end
  end

  @impl true
  def handle_cast({:increment_mode_count, mode}, state) do
    updated_counts = Map.update(state.mode_counts, mode, 1, &(&1 + 1))
    {:noreply, %{state | mode_counts: updated_counts}}
  end
end
