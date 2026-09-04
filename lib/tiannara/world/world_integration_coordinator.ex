defmodule Tiannara.World.WorldIntegrationCoordinator do
  @moduledoc """
  World Integration Coordinator — the master synchronizer of Tiannara's world state.

  Responsible for converging all existing subsystem state into the UnifiedWorldModel.
  Discovers state sources, pulls state, resolves conflicts, and maintains a
  synchronization ledger.
  """
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.World.{
    UnifiedWorldModel, WorldMutationEngine, WorldConsistencyValidator, ConflictResolver
  }
  alias Tiannara.CEL.Services.{ExecutiveMemory, EventBus}
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @sync_interval :timer.minutes(5)
  @full_sync_interval :timer.hours(1)
  @max_concurrent_syncs 3

  # ---------- ExecutiveService Behaviour ----------

  @impl Tiannara.ExecutiveService
  def id, do: :world_integration_coordinator

  @impl Tiannara.ExecutiveService
  def version, do: "1.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities do
    [
      :multi_source_synchronization,
      :conflict_resolution,
      :incremental_sync,
      :rollback_support,
      :drift_detection,
      :synchronization_auditability
    ]
  end

  @impl Tiannara.ExecutiveService
  def dependencies do
    [:persistent_memory, :event_transport, :unified_world_model,
     :world_mutation_engine, :world_state_synchronizer, :world_consistency_validator]
  end

  @impl Tiannara.ExecutiveService
  def priority, do: :critical

  @impl Tiannara.ExecutiveService
  def constitutional_score do
    stats = GenServer.call(__MODULE__, :stats)

    evidence_quality =
      if stats.total_sources > 0 do
        stats.synced_sources / stats.total_sources
      else
        1.0
      end

    health = if stats.drift_detected, do: 0.7, else: 1.0

    %ConstitutionalScore{
      service_id: id(),
      health: health,
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: evidence_quality,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now(),
    }
  end

  # ---------- Client API ----------

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def register_source(source_spec) do
    GenServer.call(__MODULE__, {:register_source, source_spec})
  end

  def unregister_source(source_id), do: GenServer.call(__MODULE__, {:unregister_source, source_id})

  def sync_all, do: GenServer.call(__MODULE__, :sync_all, :timer.minutes(5))

  def sync_source(source_id), do: GenServer.call(__MODULE__, {:sync_source, source_id})

  def sync_status, do: GenServer.call(__MODULE__, :sync_status)

  def unresolved_conflicts, do: GenServer.call(__MODULE__, :unresolved_conflicts)

  def resolve_conflict(conflict_id, resolution), do: GenServer.call(__MODULE__, {:resolve_conflict, conflict_id, resolution})

  def rollback_sync(sync_id), do: GenServer.call(__MODULE__, {:rollback, sync_id})

  def stats, do: GenServer.call(__MODULE__, :stats)

  # ---------- Server Callbacks ----------

  @impl true
  def init(_opts) do
    schedule_incremental_sync()
    schedule_full_sync()

    {:ok, %{
      sources: %{},
      sync_history: [],
      unresolved_conflicts: [],
      total_syncs: 0,
      failed_syncs: 0,
      drift_detected: false,
      healthy: true,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call({:register_source, spec}, _from, state) do
    source_state = %{
      id: spec.id,
      adapter_module: spec.adapter_module,
      adapter_opts: Map.get(spec, :adapter_opts, %{}),
      priority: Map.get(spec, :priority, :medium),
      conflict_policy: Map.get(spec, :conflict_policy, :merge),
      last_synced_at: nil,
      last_sync_version: nil,
      sync_status: :pending,
      entity_count: 0,
      error_count: 0
    }

    new_sources = Map.put(state.sources, spec.id, source_state)

    ExecutiveMemory.record_decision(
      "source_registered_#{spec.id}",
      :sync_source_registered,
      %{source_id: spec.id, adapter: spec.adapter_module}
    )

    Logger.info("WorldIntegrationCoordinator: registered source #{spec.id}")

    {:reply, :ok, %{state | sources: new_sources}}
  end

  @impl true
  def handle_call({:unregister_source, source_id}, _from, state) do
    new_sources = Map.delete(state.sources, source_id)
    {:reply, :ok, %{state | sources: new_sources}}
  end

  @impl true
  def handle_call(:sync_all, _from, state) do
    sorted_sources =
      state.sources
      |> Map.values()
      |> Enum.sort_by(&priority_to_int(&1.priority), :desc)

    {new_sources, sync_results} =
      Enum.reduce(sorted_sources, {state.sources, []}, fn source, {acc_sources, acc_results} ->
        case sync_single_source(source, acc_sources) do
          {:ok, updated_source, result} ->
            {Map.put(acc_sources, source.id, updated_source), [result | acc_results]}

          {:error, updated_source, reason} ->
            {Map.put(acc_sources, source.id, updated_source), [{:error, source.id, reason} | acc_results]}
        end
      end)

    WorldConsistencyValidator.validate_all()

    new_state = %{state |
      sources: new_sources,
      sync_history: [%{
        id: generate_sync_id(),
        type: :full_sync,
        results: sync_results,
        executed_at: DateTime.utc_now()
      } | state.sync_history] |> Enum.take(1000),
      total_syncs: state.total_syncs + 1
    }

    EventBus.publish("world.sync.completed", %{
      type: :full_sync,
      sources_synced: Enum.count(sync_results, fn
        {:ok, _, _} -> true
        _ -> false
      end),
      sources_failed: Enum.count(sync_results, fn
        {:error, _, _} -> true
        _ -> false
      end)
    })

    {:reply, {:ok, sync_results}, new_state}
  end

  @impl true
  def handle_call({:sync_source, source_id}, _from, state) do
    case Map.fetch(state.sources, source_id) do
      {:ok, source} ->
        case sync_single_source(source, state.sources) do
          {:ok, updated_source, result} ->
            new_sources = Map.put(state.sources, source_id, updated_source)
            {:reply, {:ok, result}, %{state | sources: new_sources, total_syncs: state.total_syncs + 1}}

          {:error, updated_source, reason} ->
            new_sources = Map.put(state.sources, source_id, updated_source)
            {:reply, {:error, reason}, %{state | sources: new_sources, failed_syncs: state.failed_syncs + 1}}
        end

      :error ->
        {:reply, {:error, :source_not_found}, state}
    end
  end

  @impl true
  def handle_call(:sync_status, _from, state) do
    status =
      state.sources
      |> Map.values()
      |> Enum.map(fn s ->
        %{
          source_id: s.id,
          sync_status: s.sync_status,
          last_synced_at: s.last_synced_at,
          last_sync_version: s.last_sync_version,
          entity_count: s.entity_count,
          error_count: s.error_count
        }
      end)

    {:reply, status, state}
  end

  @impl true
  def handle_call(:unresolved_conflicts, _from, state) do
    {:reply, state.unresolved_conflicts, state}
  end

  @impl true
  def handle_call({:resolve_conflict, conflict_id, resolution}, _from, state) do
    case Enum.find(state.unresolved_conflicts, &(&1.id == conflict_id)) do
      nil ->
        {:reply, {:error, :conflict_not_found}, state}

      conflict ->
        case ConflictResolver.apply_resolution(conflict, resolution) do
          {:ok, mutation_id} ->
            new_conflicts = List.delete(state.unresolved_conflicts, conflict)

            ExecutiveMemory.record_decision(
              "conflict_resolved_#{conflict_id}",
              :sync_conflict_resolved,
              %{conflict_id: conflict_id, resolution: resolution}
            )

            {:reply, :ok, %{state | unresolved_conflicts: new_conflicts}}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
    end
  end

  @impl true
  def handle_call({:rollback, sync_id}, _from, state) do
    case Enum.find(state.sync_history, &(&1.id == sync_id)) do
      nil ->
        {:reply, {:error, :sync_not_found}, state}

      sync ->
        results = Enum.map(sync.results, fn
          {:ok, _source_id, %{mutation_ids: mutation_ids}} ->
            Enum.each(mutation_ids, &WorldMutationEngine.rollback/1)
            :ok
          _ -> :ok
        end)

        {:reply, {:ok, results}, state}
    end
  end

  @impl true
  def handle_call(:stats, _from, state) do
    synced = state.sources |> Map.values() |> Enum.count(&(&1.sync_status == :synced))

    {:reply, %{
      healthy: state.healthy,
      total_sources: map_size(state.sources),
      synced_sources: synced,
      total_syncs: state.total_syncs,
      failed_syncs: state.failed_syncs,
      drift_detected: state.drift_detected,
      unresolved_conflicts: state.unresolved_conflicts,
      sync_history_size: length(state.sync_history)
    }, state}
  end

  # ---------- Background Sync ----------

  @impl true
  def handle_info(:incremental_sync, state) do
    sources_to_sync =
      state.sources
      |> Map.values()
      |> Enum.filter(fn source ->
        source.sync_status != :syncing and
        (source.last_synced_at == nil or should_sync_incremental?(source))
      end)
      |> Enum.sort_by(&priority_to_int(&1.priority), :desc)
      |> Enum.take(@max_concurrent_syncs)

    new_sources =
      Enum.reduce(sources_to_sync, state.sources, fn source, acc ->
        case sync_single_source(source, acc) do
          {:ok, updated, _} -> Map.put(acc, source.id, updated)
          {:error, updated, _} -> Map.put(acc, source.id, updated)
        end
      end)

    drift_detected = detect_drift(new_sources)

    schedule_incremental_sync()
    {:noreply, %{state | sources: new_sources, drift_detected: drift_detected}}
  end

  @impl true
  def handle_info(:full_sync, state) do
    send(self(), :do_full_sync)
    schedule_full_sync()
    {:noreply, state}
  end

  @impl true
  def handle_info(:do_full_sync, state) do
    {:reply, _, new_state} = handle_call(:sync_all, nil, state)
    {:noreply, new_state}
  end

  # ---------- Private: Sync Logic ----------

  defp sync_single_source(source, all_sources) do
    syncing_source = %{source | sync_status: :syncing}
    all_sources = Map.put(all_sources, source.id, syncing_source)
    _ = all_sources

    case source.adapter_module.pull_state(source.adapter_opts, source.last_sync_version) do
      {:ok, %{entities: entities, version: new_version, changes_only: changes_only}} ->
        mutation_ids = ingest_entities(entities, source, changes_only)

        updated_source = %{source |
          sync_status: :synced,
          last_synced_at: DateTime.utc_now(),
          last_sync_version: new_version,
          entity_count: length(entities),
          error_count: 0
        }

        result = %{
          source_id: source.id,
          status: :success,
          entities_synced: length(entities),
          mutation_ids: mutation_ids,
          version: new_version,
          changes_only: changes_only
        }

        {:ok, updated_source, result}

      {:error, reason} ->
        updated_source = %{source |
          sync_status: :failed,
          error_count: source.error_count + 1
        }

        Logger.warning("WorldIntegrationCoordinator: failed to sync #{source.id}: #{inspect(reason)}")

        {:error, updated_source, reason}
    end
  end

  defp ingest_entities(entities, source, _changes_only) do
    Enum.flat_map(entities, fn entity ->
      case UnifiedWorldModel.get_entity(entity.id) do
        {:ok, existing} ->
          if entities_differ?(existing, entity) do
            case handle_conflict(existing, entity, source) do
              {:resolved, mutation_id} -> [mutation_id]
              {:deferred, _conflict} -> []
            end
          else
            []
          end

        {:error, :not_found} ->
          case UnifiedWorldModel.create_entity(entity) do
            {:ok, _entity_id} ->
              case WorldMutationEngine.mutate(:sync_entity, %{entity_id: entity.id, source: source.id}) do
                {:ok, mutation_id} -> [mutation_id]
                _ -> []
              end
            _ -> []
          end

        _ ->
          []
      end
    end)
  end

  defp entities_differ?(existing, new_entity) do
    existing_attrs = Map.get(existing, :attributes, %{})
    new_attrs = Map.get(new_entity, :attributes, %{})

    existing_attrs != new_attrs or
    (existing.confidence || 0.5) != (new_entity.confidence || 0.5)
  end

  defp handle_conflict(existing, new_entity, source) do
    conflict = %{
      id: generate_conflict_id(),
      entity_id: existing.id,
      existing_state: existing,
      incoming_state: new_entity,
      source_id: source.id,
      detected_at: DateTime.utc_now(),
      status: :unresolved
    }

    case source.conflict_policy do
      :source_wins ->
        case UnifiedWorldModel.update_entity(existing.id, new_entity.attributes) do
          :ok ->
            case WorldMutationEngine.mutate(:resolve_conflict_source_wins, %{
              conflict_id: conflict.id,
              source: source.id
            }) do
              {:ok, mutation_id} -> {:resolved, mutation_id}
              _ -> {:deferred, conflict}
            end
          _ -> {:deferred, conflict}
        end

      :world_wins ->
        case WorldMutationEngine.mutate(:resolve_conflict_world_wins, %{
          conflict_id: conflict.id,
          source: source.id
        }) do
          {:ok, mutation_id} -> {:resolved, mutation_id}
          _ -> {:deferred, conflict}
        end

      :merge ->
        case ConflictResolver.attempt_merge(existing, new_entity) do
          {:ok, _merged, mutation_id} ->
            UnifiedWorldModel.update_entity(existing.id, new_entity.attributes)
            {:resolved, mutation_id}

          {:error, _reason} ->
            Logger.info("WorldIntegrationCoordinator: conflict #{conflict.id} deferred for merge")
            {:deferred, conflict}
        end

      :human_review ->
        {:deferred, conflict}
    end
  end

  defp detect_drift(sources) do
    world_stats = UnifiedWorldModel.stats()

    Enum.any?(sources, fn {_id, source} ->
      source.entity_count > 0 and
      source.sync_status == :synced and
      abs(source.entity_count - world_stats.entity_count) > source.entity_count * 0.1
    end)
  end

  defp should_sync_incremental?(source) do
    DateTime.diff(DateTime.utc_now(), source.last_synced_at, :second) > 300
  end

  # ---------- Private Helpers ----------

  defp priority_to_int(:high), do: 3
  defp priority_to_int(:medium), do: 2
  defp priority_to_int(:low), do: 1

  defp generate_sync_id, do: "sync_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  defp generate_conflict_id, do: "conflict_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"

  defp schedule_incremental_sync do
    Process.send_after(self(), :incremental_sync, @sync_interval)
  end

  defp schedule_full_sync do
    Process.send_after(self(), :full_sync, @full_sync_interval)
  end
end
