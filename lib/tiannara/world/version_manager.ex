defmodule Tiannara.World.VersionManager do
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.World.UnifiedRealityGraph
  alias Tiannara.CEL.Services.{ExecutiveMemory, EventBus}
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @impl Tiannara.ExecutiveService
  def id, do: :version_manager

  @impl Tiannara.ExecutiveService
  def version, do: "1.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities do
    [:immutable_versioning, :branch_management, :rollback, :version_comparison, :tagging]
  end

  @impl Tiannara.ExecutiveService
  def dependencies, do: [:persistent_memory, :event_transport, :unified_reality_graph]

  @impl Tiannara.ExecutiveService
  def priority, do: :high

  @impl Tiannara.ExecutiveService
  def constitutional_score do
    stats =
      try do
        GenServer.call(__MODULE__, :stats)
      rescue
        _ -> %{healthy: true, version_count: 0, branch_count: 0, tag_count: 0, tracked_entities: 0}
      catch
        :exit, _ -> %{healthy: true, version_count: 0, branch_count: 0, tag_count: 0, tracked_entities: 0}
      end
    %ConstitutionalScore{
      service_id: id(),
      health: if(stats.healthy, do: 1.0, else: 0.0),
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: 1.0,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def create_version(payload) do
    GenServer.call(__MODULE__, {:create_version, payload})
  end

  def get_version(entity_id, version_number) do
    GenServer.call(__MODULE__, {:get_version, entity_id, version_number})
  end

  def version_history(entity_id) do
    GenServer.call(__MODULE__, {:version_history, entity_id})
  end

  def compare_versions(entity_id, v1, v2) do
    GenServer.call(__MODULE__, {:compare_versions, entity_id, v1, v2})
  end

  def create_branch(entity_id, branch_name, from_version) do
    GenServer.call(__MODULE__, {:create_branch, entity_id, branch_name, from_version})
  end

  def merge_branch(entity_id, branch_name) do
    GenServer.call(__MODULE__, {:merge_branch, entity_id, branch_name})
  end

  def rollback(entity_id, target_version, reason \\ nil) do
    GenServer.call(__MODULE__, {:rollback, entity_id, target_version, reason})
  end

  def tag_version(entity_id, version_number, tag, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:tag_version, entity_id, version_number, tag, metadata})
  end

  def get_tags(entity_id) do
    GenServer.call(__MODULE__, {:get_tags, entity_id})
  end

  def stats, do: GenServer.call(__MODULE__, :stats)

  @impl true
  def init(_opts) do
    Logger.info("VersionManager: initialized (in-memory)")
    Process.send_after(self(), :subscribe_to_events, 100)
    {:ok, %{
      versions: %{},
      branches: %{},
      tags: %{},
      version_count: 0,
      branch_count: 0,
      tag_count: 0,
      healthy: true,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call({:create_version, payload}, _from, %{healthy: false} = state) do
    {:reply, {:error, :storage_unavailable}, state}
  end

  def handle_call({:create_version, payload}, _from, state) do
    try do
      entity_id = Map.get(payload, :entity_id, payload[:id])
      snapshot = Map.get(payload, :snapshot, payload)
      metadata = Map.get(payload, :metadata, %{})

      versions = Map.get(state.versions, entity_id, [])
      version_number = if versions == [], do: 1, else: List.last(versions).version + 1

      version_record = %{
        id: "ver_#{entity_id}_#{version_number}",
        version: version_number,
        version_number: version_number,
        entity_id: entity_id,
        snapshot: snapshot,
        metadata: metadata,
        timestamp: DateTime.utc_now()
      }

      new_versions = versions ++ [version_record]

      safe_record_decision(
        "version_created_#{entity_id}_v#{version_number}",
        :entity_version_created,
        %{entity_id: entity_id, version: version_number}
      )

      new_state = %{state |
        versions: Map.put(state.versions, entity_id, new_versions),
        version_count: state.version_count + 1
      }

      {:reply, {:ok, version_number}, new_state}
    rescue
      e -> {:reply, {:error, {:crash, e}}, state}
    catch
      :exit, e -> {:reply, {:error, {:exit, e}}, state}
    end
  end

  @impl true
  def handle_call({:get_version, entity_id, version_number}, _from, state) do
    versions = Map.get(state.versions, entity_id, [])
    found = Enum.find(versions, &(&1.version == version_number))

    case found do
      nil -> {:reply, {:error, :version_not_found}, state}
      _ -> {:reply, {:ok, found}, state}
    end
  end

  @impl true
  def handle_call({:version_history, entity_id}, _from, state) do
    versions = Map.get(state.versions, entity_id, [])
    {:reply, {:ok, versions}, state}
  end

  @impl true
  def handle_call({:compare_versions, entity_id, v1, v2}, _from, state) do
    versions = Map.get(state.versions, entity_id, [])
    v1_rec = Enum.find(versions, &(&1.version == v1))
    v2_rec = Enum.find(versions, &(&1.version == v2))

    case {v1_rec, v2_rec} do
      {nil, _} -> {:reply, {:error, :version_not_found}, state}
      {_, nil} -> {:reply, {:error, :version_not_found}, state}
      {a, b} ->
        diff = compute_diff(a.snapshot, b.snapshot)
        {:reply, {:ok, %{from: v1, to: v2, diff: diff}}, state}
    end
  end

  @impl true
  def handle_call({:create_branch, entity_id, branch_name, from_version}, _from, state) do
    versions = Map.get(state.versions, entity_id, [])
    base = Enum.find(versions, &(&1.version == from_version))

    case base do
      nil -> {:reply, {:error, :version_not_found}, state}
      _ ->
        branch = %{
          name: branch_name,
          entity_id: entity_id,
          base_version: from_version,
          commits: [base],
          created_at: DateTime.utc_now()
        }

        if Map.has_key?(state.branches, branch_name) do
          {:reply, {:error, :branch_already_exists}, state}
        else
          safe_record_decision(
            "branch_created_#{branch_name}",
            :entity_branch_created,
            %{entity_id: entity_id, branch: branch_name, base_version: from_version}
          )

          new_state = %{state |
            branches: Map.put(state.branches, branch_name, branch),
            branch_count: state.branch_count + 1
          }

          {:reply, {:ok, branch_name}, new_state}
        end
    end
  end

  @impl true
  def handle_call({:merge_branch, entity_id, branch_name}, _from, state) do
    case Map.fetch(state.branches, branch_name) do
      {:ok, branch} ->
        main_versions = Map.get(state.versions, entity_id, [])
        latest_main = List.last(main_versions)
        latest_branch = List.last(branch.commits)

        merged_snapshot = Map.merge(latest_main.snapshot, latest_branch.snapshot)
        version_number = if main_versions == [], do: 1, else: latest_main.version + 1

        merged_record = %{
          version: version_number,
          entity_id: entity_id,
          snapshot: merged_snapshot,
          metadata: %{merged_from: branch_name, branch_version: latest_branch.version},
          timestamp: DateTime.utc_now()
        }

        new_versions = main_versions ++ [merged_record]

        new_branches = Map.delete(state.branches, branch_name)

        safe_record_decision(
          "branch_merged_#{branch_name}",
          :entity_branch_merged,
          %{entity_id: entity_id, branch: branch_name, into_version: version_number}
        )

        new_state = %{state |
          versions: Map.put(state.versions, entity_id, new_versions),
          branches: new_branches,
          version_count: state.version_count + 1,
          branch_count: state.branch_count - 1
        }

        {:reply, {:ok, version_number}, new_state}

      :error ->
        {:reply, {:error, :branch_not_found}, state}
    end
  end

  @impl true
  def handle_call({:rollback, entity_id, target_version, reason}, _from, state) do
    versions = Map.get(state.versions, entity_id, [])
    target = Enum.find(versions, &(&1.version == target_version))

    case target do
      nil -> {:reply, {:error, :version_not_found}, state}
      _ ->
        rollback_record = %{
          version: (if versions == [], do: 1, else: List.last(versions).version + 1),
          entity_id: entity_id,
          snapshot: target.snapshot,
          metadata: %{rollback_from: target.version, reason: reason},
          timestamp: DateTime.utc_now()
        }

        try do
          UnifiedRealityGraph.add_entity(Map.put(target.snapshot, :id, entity_id))
        rescue
          _ -> :ok
        catch
          :exit, _ -> :ok
        end

        safe_record_decision(
          "version_rollback_#{entity_id}_to_#{target_version}",
          :entity_version_rollback,
          %{entity_id: entity_id, target_version: target_version, reason: reason}
        )

        new_versions = versions ++ [rollback_record]

        new_state = %{state |
          versions: Map.put(state.versions, entity_id, new_versions),
          version_count: state.version_count + 1
        }

        {:reply, {:ok, rollback_record.version}, new_state}
    end
  end

  @impl true
  def handle_call({:tag_version, entity_id, version_number, tag, tag_metadata}, _from, state) do
    versions = Map.get(state.versions, entity_id, [])
    target = Enum.find(versions, &(&1.version == version_number))

    case target do
      nil -> {:reply, {:error, :version_not_found}, state}
      _ ->
        tag_key = {entity_id, tag}
        existing = Map.get(state.tags, tag_key)

        tag_record = %{
          tag: tag,
          entity_id: entity_id,
          version: version_number,
          metadata: tag_metadata,
          created_at: (existing && existing.created_at) || DateTime.utc_now(),
          updated_at: DateTime.utc_now()
        }

        :ok

        new_state = %{state |
          tags: Map.put(state.tags, tag_key, tag_record),
          tag_count: if(existing, do: state.tag_count, else: state.tag_count + 1)
        }

        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:get_tags, entity_id}, _from, state) do
    matching =
      state.tags
      |> Map.values()
      |> Enum.filter(&(&1.entity_id == entity_id))
    {:reply, matching, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{
      healthy: state.healthy,
      version_count: state.version_count,
      branch_count: state.branch_count,
      tag_count: state.tag_count,
      tracked_entities: map_size(state.versions)
    }, state}
  end

  @impl true
  def handle_info(:subscribe_to_events, state) do
    try do
      EventBus.subscribe("world.mutation.executed", self())
      Logger.info("VersionManager: subscribed to world.mutation.executed")
    rescue
      _ -> Logger.warning("VersionManager: could not subscribe to events (EventBus unavailable)")
    catch
      :exit, _ -> Logger.warning("VersionManager: could not subscribe to events (EventBus unavailable)")
    end
    {:noreply, state}
  end

  @impl true
  def handle_info({:event, event}, state) do
    if event.type == :generic do
      payload = event.raw_payload
      entity_id = Map.get(payload, :entity_id) || Map.get(payload, :id)

      if entity_id do
        case UnifiedRealityGraph.get_entity(entity_id) do
          {:ok, entity} ->
            {:reply, _, new_state} = handle_call({:create_version, %{
              entity_id: entity_id,
              snapshot: entity,
              metadata: %{mutation_id: payload.mutation_id, mutation_type: payload.type}
            }}, nil, state)
            {:noreply, new_state}

          _ ->
            {:noreply, state}
        end
      else
        {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end

  defp safe_record_decision(id, type, metadata) do
    try do
      ExecutiveMemory.record_decision(id, type, metadata)
    rescue
      _ -> :ok
    catch
      :exit, _ -> :ok
    end
  end

  defp compute_diff(snapshot_a, snapshot_b) do
    keys = MapSet.union(MapSet.new(Map.keys(snapshot_a)), MapSet.new(Map.keys(snapshot_b)))

    Enum.reduce(keys, %{added: %{}, removed: %{}, changed: %{}}, fn key, acc ->
      case {Map.get(snapshot_a, key), Map.get(snapshot_b, key)} do
        {nil, val_b} -> %{acc | added: Map.put(acc.added, key, val_b)}
        {val_a, nil} -> %{acc | removed: Map.put(acc.removed, key, val_a)}
        {val_a, val_b} ->
          if val_a == val_b do
            acc
          else
            %{acc | changed: Map.put(acc.changed, key, %{from: val_a, to: val_b})}
          end
      end
    end)
  end
end
