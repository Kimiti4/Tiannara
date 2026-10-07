defmodule Tiannara.LifecycleRegistry do
  @moduledoc """
  Canonical event-sourced evolutionary ledger for Tiannara.
  
  **Infrastructure Layer** — Records immutable lifecycle events across all evolutionary layers.
  Does NOT compute analytics. Analytics (Ecology, Telemetry, OED) subscribe to this event stream.
  
  ## Architecture
  
  ```
               CapabilityRegistry
                     │
               TheoryRegistry
                     │
               OntologyRegistry
                     │
            CivilizationRegistry
                     │
                     ▼
            LifecycleRegistry  ← Immutable Event Log
                     │
        ┌────────────┼─────────────┐
        ▼            ▼             ▼
   Ecology      Telemetry      OED Audits
  ```
  
  Uses lock-free ETS tables for high-throughput event logging:
  - `:lifecycle_events` — Immutable event log (event_id → {entity_type, entity_id, event, tick, reason, metadata})
  - `:lifecycle_state` — Derived mutable state (entity_type + entity_id → {status, created_tick, removed_tick, ...})
  - `:lifecycle_stats` — Aggregated counters per entity type
  
  ## Usage
  
      # Record lifecycle events (generic API)
      Tiannara.LifecycleRegistry.record_created(:capability, cap_id, tick, metadata)
      Tiannara.LifecycleRegistry.record_removed(:capability, cap_id, tick, :selection, metadata)
      Tiannara.LifecycleRegistry.record_promoted(:capability, old_id, new_id, tick, metadata)
      
      # Query lifecycle history
      Tiannara.LifecycleRegistry.get_history(:capability, cap_id)
      Tiannara.LifecycleRegistry.get_survival_curve(:capability, current_tick)
      
      # Invariant checking (raises on failure)
      Tiannara.LifecycleRegistry.verify!(:capability, fn -> graph_size end)
  """
  
  use GenServer
  require Logger
  
  # ==================== Entity Types ====================
  
  @type entity_type ::
          :capability
        | :theory
        | :ontology
        | :civilization
        | :observer
        | :policy
        | :hypothesis
  
  # ==================== Event Types ====================
  
  @type event_type ::
          :created
        | :mutated
        | :promoted
        | :merged
        | :selected
        | :removed
        | :quarantined
        | :rolled_back
  
  # ==================== Removal Reasons ====================
  
  @type removal_reason ::
          :selection              # Failed fitness/selection criteria
        | :replacement            # Superseded by newer version
        | :merge                  # Merged into another entity
        | :promotion              # Promoted to higher layer
        | :overwrite              # Overwritten by update
        | :compaction             # Removed during graph compaction
        | :rollback               # Reverted due to contradiction/failure
        | :quarantine             # Isolated by OAVL/ACM
        | :resource_exhaustion    # System resource limits
        | :contradiction          # Logical/physical contradiction detected
        | :invalidated            # Invalidated by OAVL/epistemic check
  
  @removal_reasons [
    :selection,
    :replacement,
    :merge,
    :promotion,
    :overwrite,
    :compaction,
    :rollback,
    :quarantine,
    :resource_exhaustion,
    :contradiction,
    :invalidated
  ]
  
  # ==================== Exception Definitions ====================
  
  defmodule LifecycleInvariantError do
    @moduledoc "Raised when lifecycle accounting invariant is violated"
    defexception [:message]
  end
  
  # ==================== Public API ====================
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Initialize ETS tables for lifecycle tracking.
  Must be called once at system startup.
  """
  def init_tables do
    ensure_table(:lifecycle_events, [:bag, :public, :named_table, write_concurrency: true])
    ensure_table(:lifecycle_state, [:set, :public, :named_table, write_concurrency: true])
    ensure_table(:lifecycle_stats, [:set, :public, :named_table])
    
    # Initialize stats counters for each entity type
    entity_types = [:capability, :theory, :ontology, :civilization, :observer, :policy, :hypothesis]
    Enum.each(entity_types, fn etype ->
      :ets.insert(:lifecycle_stats, [
        {"#{etype}_created", 0},
        {"#{etype}_rediscovered", 0},
        {"#{etype}_removed", 0},
        {"#{etype}_promoted", 0},
        {"#{etype}_merged", 0},
        {"#{etype}_rolled_back", 0},
        {"#{etype}_quarantined", 0}
      ])
    end)
    
    Logger.info("🧬 [LifecycleRegistry] Event-sourced evolutionary ledger initialized")
  end
  
  @doc """
  Record a creation event for an entity.
    
  ## Parameters
  - `entity_type`: Type of entity (:capability, :theory, :ontology, etc.)
  - `entity_id`: Unique identifier for the entity
  - `tick`: Current simulation tick
  - `metadata`: Optional metadata (lineage_id, parent_ids, domain_vector, etc.)
  """
  @spec record_created(
    entity_type :: atom(),
    entity_id :: term(),
    tick :: non_neg_integer(),
    metadata :: map()
  ) :: :ok | {:error, :already_exists}
  def record_created(entity_type, entity_id, tick, metadata \\ %{}) do
    # Check if entity already exists (rediscovery detection)
    case :ets.lookup(:lifecycle_state, {entity_type, entity_id}) do
      [{_key, existing_state}] ->
        # Entity already exists - this is a rediscovery, not a new creation
        Logger.debug("🔍 [LifecycleRegistry] Rediscovery detected: #{inspect({entity_type, entity_id})} (existing since tick #{existing_state.created_tick})")
        
        # Record as rediscovery event instead of creation
        event_id = generate_event_id()
        :ets.insert(:lifecycle_events, {
          entity_type,
          entity_id,
          event_id,
          :rediscovered,
          tick,
          nil,
          Map.put(metadata, :original_creation_tick, existing_state.created_tick)
        })
        
        # Update version but don't increment created counter
        updated_state = %{existing_state | version: existing_state.version + 1}
        updated_state = Map.put(updated_state, :last_rediscovered_tick, tick)
        
        :ets.insert(:lifecycle_state, {
          {entity_type, entity_id},
          updated_state
        })
        
        # Increment rediscovered counter
        :ets.update_counter(:lifecycle_stats, "#{entity_type}_rediscovered", {2, 1}, {"#{entity_type}_rediscovered", 0})
        
        {:error, :already_exists}
      [] ->
        # New entity - proceed with normal creation
        event_id = generate_event_id()
          
        # Record immutable event
        :ets.insert(:lifecycle_events, {
          entity_type,
          entity_id,
          event_id,
          :created,
          tick,
          nil,  # No reason for creation
          metadata
        })
          
        # Update derived state
        # Key must be {entity_type, entity_id} to avoid overwriting entries with same entity_type
        :ets.insert(:lifecycle_state, {
          {entity_type, entity_id},
          %{status: :active, created_tick: tick, removed_tick: nil, version: 1}
        })
          
        # Update stats
        :ets.update_counter(:lifecycle_stats, "#{entity_type}_created", {2, 1}, {"#{entity_type}_created", 0})
          
        :ok
    end
  end
  
  @doc """
  Record a removal event for an entity.
  
  ## Parameters
  - `entity_type`: Type of entity being removed
  - `entity_id`: Unique identifier for the entity
  - `tick`: Current simulation tick
  - `reason`: Why the entity was removed (:selection, :replacement, etc.)
  - `metadata`: Optional metadata (replacement_id, failure_reason, etc.)
  """
  @spec record_removed(
    entity_type :: atom(),
    entity_id :: term(),
    tick :: non_neg_integer(),
    reason :: atom(),
    metadata :: map()
  ) :: :ok
  def record_removed(entity_type, entity_id, tick, reason, metadata \\ %{}) do
    unless reason in @removal_reasons do
      Logger.warning("⚠️  [LifecycleRegistry] Unknown removal reason: #{inspect(reason)}")
    end
    
    event_id = generate_event_id()
    
    # Record immutable event
    :ets.insert(:lifecycle_events, {
      entity_type,
      entity_id,
      event_id,
      :removed,
      tick,
      reason,
      metadata
    })
    
    # Update derived state
    case :ets.lookup(:lifecycle_state, {entity_type, entity_id}) do
      [{_key, state}] ->
        :ets.insert(:lifecycle_state, {
          {entity_type, entity_id},
          %{state | status: :removed, removed_tick: tick, removal_reason: reason}
        })
      [] ->
        Logger.warning("⚠️  [LifecycleRegistry] Removal of unknown entity: #{inspect({entity_type, entity_id})}")
    end
    
    # Update stats based on reason
    stat_key = case reason do
      :selection -> "#{entity_type}_removed"
      :promotion -> "#{entity_type}_promoted"
      :merge -> "#{entity_type}_merged"
      :rollback -> "#{entity_type}_rolled_back"
      :quarantine -> "#{entity_type}_quarantined"
      _ -> "#{entity_type}_removed"
    end
    
    :ets.update_counter(:lifecycle_stats, stat_key, {2, 1}, {stat_key, 0})
    
    :ok
  end
  
  @doc """
  Record a promotion event (entity moved to higher layer).
  
  This is both a removal from the source AND a creation in the target.
  """
  @spec record_promoted(
    entity_type :: atom(),
    old_entity_id :: term(),
    new_entity_id :: term(),
    tick :: non_neg_integer(),
    metadata :: map()
  ) :: :ok
  def record_promoted(entity_type, old_entity_id, new_entity_id, tick, metadata \\ %{}) do
    # Record removal from source
    record_removed(entity_type, old_entity_id, tick, :promotion, %{promoted_to: new_entity_id})
    
    # Record creation in target (same type, different ID)
    record_created(entity_type, new_entity_id, tick, Map.put(metadata, :promoted_from, old_entity_id))
    
    :ok
  end
  
  @doc """
  Get full lifecycle history for an entity.
  
  Returns list of events in chronological order.
  """
  @spec get_history(entity_type :: atom(), entity_id :: term()) :: [map()]
  def get_history(entity_type, entity_id) do
    :ets.match(:lifecycle_events, {entity_type, entity_id, :'$1', :'$2', :'$3', :'$4', :'$5'})
    |> Enum.map(fn [event_id, event_type, tick, reason, metadata] ->
      %{
        event_id: event_id,
        entity_type: entity_type,
        entity_id: entity_id,
        event_type: event_type,
        tick: tick,
        reason: reason,
        metadata: metadata
      }
    end)
    |> Enum.sort_by(& &1.tick)
  end
  
  @doc """
  Calculate survival curve for an entity type.
  
  Returns distribution of lifespans for all completed entities.
  """
  @spec get_survival_curve(entity_type :: atom(), current_tick :: non_neg_integer()) :: map()
  def get_survival_curve(entity_type, _current_tick) do
    # Get all birth events - returns [[entity_id, tick], ...]
    births = :ets.match(:lifecycle_events, {entity_type, :'$1', :_, :created, :'$2', :_, :_})
    
    # Get all removal events - returns [[entity_id, tick], ...]
    removals = :ets.match(:lifecycle_events, {entity_type, :'$1', :_, :removed, :'$2', :_, :_})
    
    # Calculate lifespans
    lifespans = Enum.map(removals, fn [entity_id, removal_tick] ->
      case Enum.find(births, fn [bid, _btick] -> bid == entity_id end) do
        [_, birth_tick] -> removal_tick - birth_tick
        nil -> 0
      end
    end)
    
    # Calculate statistics
    if length(lifespans) > 0 do
      sorted = Enum.sort(lifespans)
      %{
        count: length(lifespans),
        min: hd(sorted),
        max: List.last(sorted),
        median: Enum.at(sorted, div(length(sorted), 2)),
        mean: round(Enum.sum(lifespans) / length(lifespans)),
        p95: Enum.at(sorted, min(round(length(sorted) * 0.95), length(sorted) - 1))
      }
    else
      %{count: 0, min: 0, max: 0, median: 0, mean: 0, p95: 0}
    end
  end
  
  @doc """
  Verify lifecycle invariant for an entity type.
  
  Checks: Created - Removed = Active = Graph Size
  
  Raises LifecycleInvariantError if violated.
  This makes instrumentation failures impossible to ignore.
  
  ## Parameters
  - `entity_type`: Type of entity to verify
  - `graph_size_fn`: Function that returns current graph size for this entity type
  
  ## Example
  
      Tiannara.LifecycleRegistry.verify!(:capability, fn ->
        map_size(state.capabilities)
      end)
  """
  @spec verify!(entity_type :: atom(), graph_size_fn :: function()) :: :ok | no_return()
  def verify!(entity_type, graph_size_fn) do
    Logger.info("🔍 [LifecycleRegistry] verify! called for #{entity_type}")
    created = get_stat("#{entity_type}_created")
    rediscovered = get_stat("#{entity_type}_rediscovered")
    removed = get_stat("#{entity_type}_removed")
    promoted = get_stat("#{entity_type}_promoted")
    merged = get_stat("#{entity_type}_merged")
    
    total_removed = removed + promoted + merged
    expected_active = created - total_removed
    
    Logger.info("🔍 [LifecycleRegistry] Stats: created=#{created}, rediscovered=#{rediscovered}, removed=#{removed}, promoted=#{promoted}, merged=#{merged}")
    
    # Get all active entity IDs from lifecycle state
    # Key structure: {{entity_type, entity_id}, state_map}
    # Match spec: extract entity_id (second element of key tuple) where first element matches entity_type
    match_spec = [{{{entity_type, :'$1'}, :_}, [], [:'$1']}]
    
    lifecycle_active_ids = 
      :ets.select(:lifecycle_state, match_spec)
      |> MapSet.new()
    
    Logger.info("🔍 [LifecycleRegistry] Collected #{MapSet.size(lifecycle_active_ids)} lifecycle active IDs")
    
    actual_active = MapSet.size(lifecycle_active_ids)
    graph_result = graph_size_fn.()  # Should return MapSet of graph IDs
    
    Logger.info("🔍 [LifecycleRegistry] graph_result is MapSet: #{is_map(graph_result)}")
    
    # Defensive: ensure graph_result is a MapSet
    graph_ids_set = if is_map(graph_result) and Map.has_key?(graph_result, :map), do: graph_result, else: MapSet.new()
    graph_size = MapSet.size(graph_ids_set)
    
    Logger.info("🔍 [LifecycleRegistry] Graph size: #{graph_size}, Expected active: #{expected_active}, Actual active: #{actual_active}")
    
    if expected_active == actual_active and actual_active == graph_size do
      Logger.debug("✅ [LifecycleRegistry] Invariant holds for #{entity_type}: #{expected_active} active")
      :ok
    else
      # RECONCILIATION REPORT: Identify exact discrepancies
      # graph_ids_set already defined above
      
      # Calculate set differences
      in_graph_not_lifecycle = MapSet.difference(graph_ids_set, lifecycle_active_ids)
      in_lifecycle_not_graph = MapSet.difference(lifecycle_active_ids, graph_ids_set)
      
      # Get sample IDs for debugging
      graph_only_sample = Enum.take(in_graph_not_lifecycle, 20) |> Enum.to_list()
      lifecycle_only_sample = Enum.take(in_lifecycle_not_graph, 20) |> Enum.to_list()
      
      error_msg = """
      🚨 LIFECYCLE INVARIANT VIOLATION for #{entity_type}
      
      Expected: #{expected_active} (Created=#{created} - Removed=#{total_removed})
      Actual Active State: #{actual_active}
      Graph Size: #{MapSet.size(graph_ids_set)}
      
      Discrepancy Analysis:
        Lifecycle has #{actual_active} active entities
        Graph reports #{MapSet.size(graph_ids_set)} entities
        Difference: #{abs(actual_active - MapSet.size(graph_ids_set))} entities
      
      Reconciliation Report:
        In Graph but NOT in Lifecycle: #{MapSet.size(in_graph_not_lifecycle)} entities
          Sample IDs: #{inspect(graph_only_sample)}
        
        In Lifecycle but NOT in Graph: #{MapSet.size(in_lifecycle_not_graph)} entities
          Sample IDs: #{inspect(lifecycle_only_sample)}
      
      This indicates capabilities are escaping lifecycle tracking.
      Check mutation/replacement paths that bypass record_created/record_removed.
      """
      
      Logger.error(error_msg)
      raise LifecycleInvariantError, message: error_msg
    end
  end
  
  @doc """
  Get aggregated statistics for all entity types.
  """
  @spec get_stats() :: map()
  def get_stats do
    :ets.tab2list(:lifecycle_stats)
    |> Enum.into(%{})
  end
  
  # ==================== GenServer Callbacks ====================
  
  defp ensure_table(name, options) do
    case :ets.whereis(name) do
      :undefined ->
        try do
          :ets.new(name, options)
        rescue
          ArgumentError -> name
        end
      _tid ->
        name
    end
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end
  
  # ==================== Private Helpers ====================
  
  defp generate_event_id do
    # Use monotonic time + random for unique IDs
    "#{System.monotonic_time(:microsecond)}_#{:rand.uniform(1000000)}"
  end
  
  defp get_stat(key) do
    case :ets.lookup(:lifecycle_stats, key) do
      [{_, value}] -> value
      [] -> 0
    end
  end

  def track_entity(_module, _entity_id, _event_type, _metadata), do: {:ok, :stub}
end
