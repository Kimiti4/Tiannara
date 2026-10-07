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
    defexception [
      :message,
      :entity_type,
      :created,
      :removed,
      :expected_active,
      :actual_active,
      :graph_size,
      :missing_from_graph,
      :missing_from_lifecycle
    ]
  end
  
  # ==================== Public API ====================
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Initialize ETS tables for lifecycle tracking.
  Idempotent: safe to call from any process, any number of times.
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
    :ok
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
    record_removal(entity_type, entity_id, tick, reason, metadata, removal_stat_key(entity_type, reason))
  end
  
  @doc """
  Record a promotion event (entity moved to higher layer).

  This is both a removal from the source AND a creation in the target.

  ## Cross-type promotion (legacy contract)

  ```elixir
  record_promoted(:capability, old_id, tick, :theory, %{theory_id: "t1"})
  ```

  Removes `old_id` from `entity_type` and creates a new entity in
  `target_type` whose id is drawn from metadata (`:theory_id`,
  `:theory_name` or `:target_id`) or generated.

  Source-side accounting is exclusive so the conservation law stays exact:
  when metadata names the successor, the old identity is counted in the
  `removed` bucket; when it does not, the transition is counted in the
  `promoted` bucket.

  ## Same-type promotion (operational contract)

  ```elixir
  record_promoted(:capability, old_id, new_id, tick, %{})
  ```

  Removes `old_id` and creates `new_id` within the same `entity_type`.
  """
  @spec record_promoted(
    entity_type :: atom(),
    old_entity_id :: term(),
    arg3 :: term(),
    arg4 :: term(),
    metadata :: map()
  ) :: :ok
  def record_promoted(entity_type, old_entity_id, arg3, arg4, metadata \\ %{}) do
    if is_atom(arg4) do
      # Cross-type contract: (entity_type, old_id, tick, target_type, metadata)
      cross_type_promotion(entity_type, old_entity_id, arg3, arg4, metadata)
    else
      # Same-type contract: (entity_type, old_id, new_id, tick, metadata)
      same_type_promotion(entity_type, old_entity_id, arg3, arg4, metadata)
    end
  end

  defp cross_type_promotion(entity_type, old_entity_id, tick, target_type, metadata) do
    successor_id =
      Map.get(metadata, :theory_id) ||
        Map.get(metadata, :theory_name) ||
        Map.get(metadata, :target_id)

    stat_key =
      if successor_id do
        "#{entity_type}_removed"
      else
        "#{entity_type}_promoted"
      end

    # Record removal from source
    record_removal(entity_type, old_entity_id, tick, :promotion, %{promoted_to: target_type}, stat_key)

    # Derive the new entity id in the target type
    new_entity_id = successor_id || "#{old_entity_id}_promoted"

    # Record creation in target type
    record_created(target_type, new_entity_id, tick, Map.put(metadata, :promoted_from, old_entity_id))

    :ok
  end

  defp same_type_promotion(entity_type, old_entity_id, new_entity_id, tick, metadata) do
    # Record removal from source
    record_removed(entity_type, old_entity_id, tick, :promotion, %{promoted_to: new_entity_id})

    # Record creation in target (same type, different ID)
    record_created(entity_type, new_entity_id, tick, Map.put(metadata, :promoted_from, old_entity_id))

    :ok
  end

  @doc """
  Record a mutation event for an existing entity.

  Mutations do not affect the active count — they are pure history log
  entries used for archaeology/traceability.
  """
  @spec record_mutated(
    entity_type :: atom(),
    entity_id :: term(),
    tick :: non_neg_integer(),
    mutation_type :: atom(),
    metadata :: map()
  ) :: :ok
  def record_mutated(entity_type, entity_id, tick, mutation_type, metadata \\ %{}) do
    event_id = generate_event_id()

    :ets.insert(:lifecycle_events, {
      entity_type,
      entity_id,
      event_id,
      :mutated,
      tick,
      mutation_type,
      metadata
    })

    :ok
  end

  @doc """
  Get full lifecycle history for an entity.

  Returns a list of `{event_type, tick, metadata}` tuples in chronological
  order. For removal events the metadata always carries the `:removal_reason`.
  """
  @spec get_history(entity_type :: atom(), entity_id :: term()) :: [{atom(), non_neg_integer(), map()}]
  def get_history(entity_type, entity_id) do
    :ets.match(:lifecycle_events, {entity_type, entity_id, :'$1', :'$2', :'$3', :'$4', :'$5'})
    |> Enum.map(fn [_event_id, event_type, tick, reason, metadata] ->
      enriched_metadata =
        if event_type == :removed and reason not in [nil, :unknown] do
          Map.put(metadata, :removal_reason, reason)
        else
          metadata
        end

      {event_type, tick, enriched_metadata}
    end)
    |> Enum.sort_by(fn {_, tick, _} -> tick end)
  end
  
  @doc """
  Calculate survival curve for an entity type.

  Returns a map keyed by tick, where each value is the number of entities
  alive at that tick. Keys span `1..max_tick`, where `max_tick` is the
  largest observed creation/removal tick (or `current_tick`).
  """
  @spec get_survival_curve(entity_type :: atom(), current_tick :: non_neg_integer()) :: %{non_neg_integer() => non_neg_integer()}
  def get_survival_curve(entity_type, current_tick) do
    # Collect birth and removal ticks from the derived state table
    states = :ets.match(:lifecycle_state, {{entity_type, :_}, :'$1'}) |> List.flatten()

    birth_ticks = Enum.map(states, & &1.created_tick)
    removal_ticks = Enum.map(states, fn s -> s.removed_tick || s.created_tick end)

    max_tick = Enum.max([current_tick | birth_ticks] ++ removal_ticks)

    if max_tick < 1 do
      %{}
    else
      Enum.reduce(1..max_tick, %{}, fn tick, acc ->
        alive =
          Enum.count(states, fn s ->
            s.created_tick <= tick and (s.removed_tick == nil or s.removed_tick > tick)
          end)

        Map.put(acc, tick, alive)
      end)
    end
  end

  @doc """
  Return the ancestry lineage for an entity.

  Reads the `:lineage` value stored in the entity's creation metadata.
  """
  @spec get_lineage(entity_type :: atom(), entity_id :: term()) :: [term()]
  def get_lineage(entity_type, entity_id) do
    case :ets.match(:lifecycle_events, {entity_type, entity_id, :_, :created, :'$1', :_, :'$2'}) do
      [] ->
        []
      rows ->
        rows
        |> Enum.sort_by(fn [tick, _metadata] -> tick end)
        |> List.first()
        |> List.last()
        |> Map.get(:lineage, [])
    end
  end

  @doc """
  Calculate innovation efficiency for an entity type.

  Ratio of genuinely new creations to total creation attempts
  (`new / (new + rediscovered)`).
  """
  @spec innovation_efficiency(entity_type :: atom()) :: float()
  def innovation_efficiency(entity_type) do
    created = get_stat("#{entity_type}_created")
    rediscovered = get_stat("#{entity_type}_rediscovered")

    total = created + rediscovered
    if total == 0, do: 0.0, else: created / total
  end
  
  @doc """
  Verify lifecycle invariant for an entity type.
  
  Checks: Created - Removed - Promoted - Merged = Active = Graph Size
  
  Raises LifecycleInvariantError if violated.
  This makes instrumentation failures impossible to ignore.
  
  ## Parameters
  - `entity_type`: Type of entity to verify
  - `graph_size_fn`: Function that returns current graph size for this entity
    type, either as a `MapSet` of active entity IDs (enables detailed
    reconciliation) or as an integer count.
  
  ## Example
  
      Tiannara.LifecycleRegistry.verify!(:capability, fn ->
        map_size(state.capabilities)
      end)
  """
  @spec verify!(entity_type :: atom(), graph_size_fn :: function()) :: :ok | no_return()
  def verify!(entity_type, graph_size_fn) do
    created = get_stat("#{entity_type}_created")
    rediscovered = get_stat("#{entity_type}_rediscovered")
    removed = get_stat("#{entity_type}_removed")
    promoted = get_stat("#{entity_type}_promoted")
    merged = get_stat("#{entity_type}_merged")
    
    total_removed = removed + promoted + merged
    expected_active = created - total_removed
    
    Logger.info("🔍 [LifecycleRegistry] Stats for #{entity_type}: created=#{created}, rediscovered=#{rediscovered}, removed=#{removed}, promoted=#{promoted}, merged=#{merged}")
    
    # Get all active entity IDs from lifecycle state.
    # Key structure: {{entity_type, entity_id}, state_map}. Only rows whose
    # status is NOT :removed count as active — removed entities remain in
    # the table for lineage/history.
    lifecycle_active_ids = active_entity_ids(entity_type)
    actual_active = MapSet.size(lifecycle_active_ids)
    
    graph_result = graph_size_fn.()
    
    graph_ids_set =
      case graph_result do
        %MapSet{} = set -> set
        _ -> nil
      end
    
    graph_size =
      case graph_result do
        %MapSet{} = set -> MapSet.size(set)
        size when is_integer(size) -> size
        _ -> 0
      end
    
    if expected_active == actual_active and actual_active == graph_size do
      Logger.debug("✅ [LifecycleRegistry] Invariant holds for #{entity_type}: #{expected_active} active")
      :ok
    else
      # RECONCILIATION REPORT: Identify exact discrepancies
      known_graph_ids = graph_ids_set || MapSet.new()

      in_graph_not_lifecycle = MapSet.difference(known_graph_ids, lifecycle_active_ids)
      in_lifecycle_not_graph = MapSet.difference(lifecycle_active_ids, known_graph_ids)

      # Get sample IDs for debugging
      graph_only_sample = Enum.take(in_graph_not_lifecycle, 20) |> Enum.to_list()
      lifecycle_only_sample = Enum.take(in_lifecycle_not_graph, 20) |> Enum.to_list()

      missing_from_lifecycle =
        if graph_ids_set do
          MapSet.to_list(in_graph_not_lifecycle)
        else
          []
        end

      error_msg = """
      🚨 LIFECYCLE INVARIANT VIOLATION for #{entity_type}

      Expected: #{expected_active} (Created=#{created} - Removed=#{total_removed})
      Actual Active State: #{actual_active}
      Graph Size: #{graph_size}
      
      Discrepancy Analysis:
        Lifecycle has #{actual_active} active entities
        Graph reports #{graph_size} entities
        Difference: #{abs(actual_active - graph_size)} entities
      
      Reconciliation Report:
        In Graph but NOT in Lifecycle: #{MapSet.size(in_graph_not_lifecycle)} entities
          Sample IDs: #{inspect(graph_only_sample)}
        
        In Lifecycle but NOT in Graph: #{MapSet.size(in_lifecycle_not_graph)} entities
          Sample IDs: #{inspect(lifecycle_only_sample)}
      
      This indicates capabilities are escaping lifecycle tracking.
      Check mutation/replacement paths that bypass record_created/record_removed.
      """
      
      Logger.error(error_msg)

      raise LifecycleInvariantError,
        message: error_msg,
        entity_type: entity_type,
        created: created,
        removed: total_removed,
        expected_active: expected_active,
        actual_active: actual_active,
        graph_size: graph_size,
        missing_from_graph: MapSet.to_list(in_lifecycle_not_graph),
        missing_from_lifecycle: missing_from_lifecycle
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

  @doc """
  Get statistics for a single entity type.

  Returns a map with `:created`, `:rediscovered`, `:removed`, `:promoted`,
  `:merged`, `:rolled_back` and `:quarantined` counters, zeroed when empty.
  """
  @spec get_stats(entity_type :: atom()) :: map()
  def get_stats(entity_type) do
    %{
      created: get_stat("#{entity_type}_created"),
      rediscovered: get_stat("#{entity_type}_rediscovered"),
      removed: get_stat("#{entity_type}_removed"),
      promoted: get_stat("#{entity_type}_promoted"),
      merged: get_stat("#{entity_type}_merged"),
      rolled_back: get_stat("#{entity_type}_rolled_back"),
      quarantined: get_stat("#{entity_type}_quarantined")
    }
  end
  
  # ==================== GenServer Callbacks ====================
  
  @impl true
  def init(_opts) do
    {:ok, %{}}
  end
  
  # ==================== Private Helpers ====================

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

  # Shared removal pipeline: immutable event + derived state + stat counter.
  # The stat bucket is passed in explicitly so cross-type promotion can pick
  # the bucket while the event/state still record the canonical reason.
  defp record_removal(entity_type, entity_id, tick, reason, metadata, stat_key) do
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
        updated_state =
          state
          |> Map.put(:status, :removed)
          |> Map.put(:removed_tick, tick)
          |> Map.put(:removal_reason, reason)

        :ets.insert(:lifecycle_state, {
          {entity_type, entity_id},
          updated_state
        })
      [] ->
        Logger.warning("⚠️  [LifecycleRegistry] Removal of unknown entity: #{inspect({entity_type, entity_id})}")
    end
    
    :ets.update_counter(:lifecycle_stats, stat_key, {2, 1}, {stat_key, 0})
    
    :ok
  end

  # Default stat bucket per removal reason, so that the invariant
  # `created - removed - promoted - merged == active` stays exact.
  defp removal_stat_key(entity_type, reason) do
    case reason do
      :selection -> "#{entity_type}_removed"
      :promotion -> "#{entity_type}_promoted"
      :merge -> "#{entity_type}_merged"
      :rollback -> "#{entity_type}_rolled_back"
      :quarantine -> "#{entity_type}_quarantined"
      _ -> "#{entity_type}_removed"
    end
  end

  defp active_entity_ids(entity_type) do
    :ets.match_object(:lifecycle_state, {{entity_type, :_}, :_})
    |> Enum.filter(fn {_key, state} -> Map.get(state, :status) != :removed end)
    |> Enum.map(fn {{_type, entity_id}, _state} -> entity_id end)
    |> MapSet.new()
  end

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
