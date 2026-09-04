defmodule Tiannara.World.RealityCoordinator do
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.World.{UnifiedRealityGraph, GraphAdapter, ConflictResolver}
  alias Tiannara.World.WorldMutationEngine
  alias Tiannara.CEL.Services.{ExecutiveMemory, EventBus}
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @sync_interval :timer.minutes(2)

  @impl Tiannara.ExecutiveService
  def id, do: :reality_coordinator

  @impl Tiannara.ExecutiveService
  def version, do: "1.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities do
    [:graph_migration, :incremental_sync, :multi_graph_merging, :conflict_resolution]
  end

  @impl Tiannara.ExecutiveService
  def dependencies do
    [:persistent_memory, :event_transport, :unified_reality_graph,
     :world_mutation_engine, :conflict_resolver]
  end

  @impl Tiannara.ExecutiveService
  def priority, do: :high

  @impl Tiannara.ExecutiveService
  def constitutional_score do
    stats = GenServer.call(__MODULE__, :stats)
    evidence_quality =
      if stats.total_migrations > 0,
        do: stats.successful_migrations / stats.total_migrations,
        else: 1.0

    %ConstitutionalScore{
      service_id: id(),
      health: if(stats.healthy, do: 1.0, else: 0.0),
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: evidence_quality,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def register_adapter(adapter_id, adapter_module, opts \\ %{}) do
    GenServer.call(__MODULE__, {:register_adapter, adapter_id, adapter_module, opts})
  end

  def unregister_adapter(adapter_id) do
    GenServer.call(__MODULE__, {:unregister_adapter, adapter_id})
  end

  def migrate_all, do: GenServer.call(__MODULE__, :migrate_all, :timer.minutes(5))

  def migrate_graph(adapter_id) do
    GenServer.call(__MODULE__, {:migrate_graph, adapter_id}, :timer.minutes(5))
  end

  def sync_all, do: GenServer.call(__MODULE__, :sync_all)

  def sync_graph(adapter_id) do
    GenServer.call(__MODULE__, {:sync_graph, adapter_id})
  end

  def adapter_status, do: GenServer.call(__MODULE__, :adapter_status)

  def stats, do: GenServer.call(__MODULE__, :stats)

  @impl true
  def init(_opts) do
    schedule_sync()
    {:ok, %{
      adapters: %{},
      migration_results: [],
      sync_count: 0,
      total_migrations: 0,
      successful_migrations: 0,
      healthy: true,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call({:register_adapter, adapter_id, adapter_module, opts}, _from, state) do
    if Map.has_key?(state.adapters, adapter_id) do
      {:reply, {:error, :already_registered}, state}
    else
      adapter_state = %{
        id: adapter_id,
        module: adapter_module,
        opts: opts,
        status: :pending,
        last_offset: nil,
        last_synced_at: nil,
        entity_count: 0,
        error_count: 0,
        conflict_policy: Map.get(opts, :conflict_policy, :merge)
      }

      Logger.info("RealityCoordinator: registered adapter #{adapter_id} (#{inspect(adapter_module)})")

      ExecutiveMemory.record_decision(
        "adapter_registered_#{adapter_id}",
        :graph_adapter_registered,
        %{adapter_id: adapter_id, module: inspect(adapter_module)}
      )

      new_state = %{state | adapters: Map.put(state.adapters, adapter_id, adapter_state)}
      {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:unregister_adapter, adapter_id}, _from, state) do
    new_adapters = Map.delete(state.adapters, adapter_id)
    {:reply, :ok, %{state | adapters: new_adapters}}
  end

  @impl true
  def handle_call(:migrate_all, _from, state) do
    sorted =
      state.adapters
      |> Map.values()
      |> Enum.sort_by(&priority_to_int(&1.opts[:priority] || :medium), :desc)

    {new_adapters, results} =
      Enum.reduce(sorted, {state.adapters, []}, fn adapter, {acc_adapters, acc_results} ->
        case migrate_single(adapter, acc_adapters) do
          {:ok, updated, result} ->
            {Map.put(acc_adapters, adapter.id, updated), [result | acc_results]}
          {:error, updated, reason} ->
            {Map.put(acc_adapters, adapter.id, updated), [{:error, adapter.id, reason} | acc_results]}
        end
      end)

    new_state = %{state |
      adapters: new_adapters,
      migration_results: [%{
        id: generate_migration_id(),
        type: :full_migration,
        results: results,
        executed_at: DateTime.utc_now()
      } | state.migration_results] |> Enum.take(100)
    }

    EventBus.publish("reality.coordinator.migration.completed", %{
      type: :full,
      migrated: Enum.count(results, fn
        {:ok, _, _} -> true
        _ -> false
      end),
      failed: Enum.count(results, fn
        {:error, _, _} -> true
        _ -> false
      end)
    })

    {:reply, {:ok, results}, new_state}
  end

  @impl true
  def handle_call({:migrate_graph, adapter_id}, _from, state) do
    case Map.fetch(state.adapters, adapter_id) do
      {:ok, adapter} ->
        case migrate_single(adapter, state.adapters) do
          {:ok, updated, result} ->
            new_adapters = Map.put(state.adapters, adapter_id, updated)
            {:reply, {:ok, result}, %{state | adapters: new_adapters}}
          {:error, updated, reason} ->
            new_adapters = Map.put(state.adapters, adapter_id, updated)
            {:reply, {:error, reason}, %{state | adapters: new_adapters}}
        end
      :error ->
        {:reply, {:error, :adapter_not_found}, state}
    end
  end

  @impl true
  def handle_call(:sync_all, _from, state) do
    syncable =
      state.adapters
      |> Map.values()
      |> Enum.filter(fn a -> a.status != :syncing end)
      |> Enum.sort_by(&priority_to_int(&1.opts[:priority] || :medium), :desc)

    new_adapters =
      Enum.reduce(syncable, state.adapters, fn adapter, acc ->
        case sync_single(adapter, acc) do
          {:ok, updated, _} -> Map.put(acc, adapter.id, updated)
          {:error, updated, _} -> Map.put(acc, adapter.id, updated)
        end
      end)

    new_state = %{state |
      adapters: new_adapters,
      sync_count: state.sync_count + 1
    }

    EventBus.publish("reality.coordinator.sync.completed", %{
      synced_adapters: map_size(new_adapters)
    })

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:sync_graph, adapter_id}, _from, state) do
    case Map.fetch(state.adapters, adapter_id) do
      {:ok, adapter} ->
        case sync_single(adapter, state.adapters) do
          {:ok, updated, result} ->
            new_adapters = Map.put(state.adapters, adapter_id, updated)
            {:reply, {:ok, result}, %{state | adapters: new_adapters}}
          {:error, updated, reason} ->
            new_adapters = Map.put(state.adapters, adapter_id, updated)
            {:reply, {:error, reason}, %{state | adapters: new_adapters}}
        end
      :error ->
        {:reply, {:error, :adapter_not_found}, state}
    end
  end

  @impl true
  def handle_call(:adapter_status, _from, state) do
    status =
      state.adapters
      |> Map.values()
      |> Enum.map(fn a ->
        %{
          adapter_id: a.id,
          module: a.module,
          status: a.status,
          last_synced_at: a.last_synced_at,
          entity_count: a.entity_count,
          error_count: a.error_count
        }
      end)

    {:reply, status, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{
      healthy: state.healthy,
      total_adapters: map_size(state.adapters),
      total_migrations: state.total_migrations,
      successful_migrations: state.successful_migrations,
      sync_count: state.sync_count,
      started_at: state.started_at
    }, state}
  end

  @impl true
  def handle_info(:incremental_sync, state) do
    {:reply, _, new_state} = handle_call(:sync_all, nil, state)
    schedule_sync()
    {:noreply, new_state}
  end

  defp migrate_single(adapter, all_adapters) do
    syncing = %{adapter | status: :migrating}
    all_adapters = Map.put(all_adapters, adapter.id, syncing)
    _ = all_adapters

    case adapter.module.pull_graph(adapter.opts, nil) do
      {:ok, %{entities: entities, offset: new_offset}} ->
        mutation_ids = ingest_entities(entities, adapter)

        updated = %{adapter |
          status: :synced,
          last_offset: new_offset,
          last_synced_at: DateTime.utc_now(),
          entity_count: length(entities),
          error_count: 0
        }

        result = %{
          adapter_id: adapter.id,
          status: :success,
          entities_migrated: length(entities),
          mutation_ids: mutation_ids,
          offset: new_offset
        }

        {:ok, updated, result}

      {:error, reason} ->
        updated = %{adapter |
          status: :failed,
          error_count: adapter.error_count + 1
        }

        Logger.warning("RealityCoordinator: migration failed for #{adapter.id}: #{inspect(reason)}")
        {:error, updated, reason}
    end
  end

  defp sync_single(adapter, all_adapters) do
    syncing = %{adapter | status: :syncing}
    all_adapters = Map.put(all_adapters, adapter.id, syncing)
    _ = all_adapters

    case adapter.module.pull_graph(adapter.opts, adapter.last_offset) do
      {:ok, %{entities: entities, offset: new_offset}} ->
        mutation_ids = ingest_entities(entities, adapter)

        updated = %{adapter |
          status: :synced,
          last_offset: new_offset,
          last_synced_at: DateTime.utc_now(),
          entity_count: adapter.entity_count + length(entities),
          error_count: 0
        }

        result = %{
          adapter_id: adapter.id,
          status: :success,
          entities_synced: length(entities),
          mutation_ids: mutation_ids,
          offset: new_offset
        }

        {:ok, updated, result}

      {:error, reason} ->
        updated = %{adapter |
          status: :failed,
          error_count: adapter.error_count + 1
        }

        Logger.warning("RealityCoordinator: sync failed for #{adapter.id}: #{inspect(reason)}")
        {:error, updated, reason}
    end
  end

  defp ingest_entities(entities, adapter) do
    Enum.flat_map(entities, fn entity ->
      case UnifiedRealityGraph.get_entity(entity.id) do
        {:ok, existing} ->
          if entities_differ?(existing, entity) do
            case resolve_conflict(existing, entity, adapter) do
              {:resolved, mutation_id} -> [mutation_id]
              {:deferred} -> []
            end
          else
            []
          end

        {:error, :not_found} ->
          case UnifiedRealityGraph.add_entity(entity) do
            {:ok, _eid} ->
              {:ok, mutation_id} = WorldMutationEngine.mutate(:graph_migration, %{
                entity_id: entity.id, source: adapter.id
              })
              [mutation_id]
            _ -> []
          end

        _ ->
          []
      end
    end)
  end

  defp entities_differ?(existing, new_entity) do
    existing_attrs = Map.get(existing, :attributes, %{}) || %{}
    new_attrs = Map.get(new_entity, :attributes, %{}) || %{}

    existing_attrs != new_attrs or
    (existing.confidence || 0.5) != (new_entity.confidence || 0.5)
  end

  defp resolve_conflict(existing, new_entity, adapter) do
    case adapter.conflict_policy do
      :source_wins ->
        UnifiedRealityGraph.add_entity(new_entity)
        {:ok, mutation_id} = WorldMutationEngine.mutate(:resolve_conflict_source_wins, %{
          entity_id: existing.id, source: adapter.id
        })
        {:resolved, mutation_id}

      :world_wins ->
        {:ok, mutation_id} = WorldMutationEngine.mutate(:resolve_conflict_world_wins, %{
          entity_id: existing.id, source: adapter.id
        })
        {:resolved, mutation_id}

      :merge ->
        case ConflictResolver.attempt_merge(existing, new_entity) do
          {:ok, _merged_attrs, mutation_id} ->
            {:resolved, mutation_id}
          {:error, _reason} ->
            Logger.info("RealityCoordinator: conflict deferred for #{existing.id}")
            {:deferred}
        end

      :human_review ->
        ExecutiveMemory.record_decision(
          "conflict_escalated_#{existing.id}",
          :graph_conflict_escalated,
          %{entity_id: existing.id, adapter_id: adapter.id}
        )
        {:deferred}
    end
  end

  defp priority_to_int(:high), do: 3
  defp priority_to_int(:medium), do: 2
  defp priority_to_int(:low), do: 1
  defp priority_to_int(_), do: 2

  defp generate_migration_id,
    do: "mig_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"

  defp schedule_sync do
    Process.send_after(self(), :incremental_sync, @sync_interval)
  end
end
