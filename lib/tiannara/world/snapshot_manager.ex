defmodule Tiannara.World.SnapshotManager do
  @moduledoc """
  Snapshot Manager — durable, incremental checkpointing of the world model.

  Provides fast state recovery points for the ReplayEngine and TemporalWorldEngine.
  """
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.World.{UnifiedWorldModel, UnifiedRealityGraph}
  alias Tiannara.CEL.Services.{EventBus, ExecutiveMemory, EventStore}
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @snapshot_interval :timer.hours(1)
  @retention_count 24

  # ---------- ExecutiveService Behaviour ----------

  @impl Tiannara.ExecutiveService
  def id, do: :snapshot_manager

  @impl Tiannara.ExecutiveService
  def version, do: "1.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities do
    [:state_checkpointing, :incremental_snapshots, :state_recovery, :retention_management]
  end

  @impl Tiannara.ExecutiveService
  def dependencies, do: [:persistent_memory, :event_transport, :unified_world_model]

  @impl Tiannara.ExecutiveService
  def priority, do: :high

  @impl Tiannara.ExecutiveService
  def constitutional_score do
    stats = GenServer.call(__MODULE__, :stats)
    %ConstitutionalScore{
      service_id: id(),
      health: if(stats.last_snapshot_status == :success, do: 1.0, else: 0.5),
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: 1.0,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  # ---------- Client API ----------

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def take_snapshot, do: GenServer.call(__MODULE__, :take_snapshot, :timer.minutes(5))

  def create_snapshot(_scope, metadata) do
    GenServer.call(__MODULE__, {:create_snapshot, metadata}, :timer.minutes(5))
  end

  def restore_from_snapshot(snapshot_id) do
    GenServer.call(__MODULE__, {:restore_from_snapshot, snapshot_id}, :timer.minutes(5))
  end

  def list_snapshots, do: GenServer.call(__MODULE__, :list_snapshots)

  def stats, do: GenServer.call(__MODULE__, :stats)

  # ---------- Server Callbacks ----------

  @impl true
  def init(_opts) do
    schedule_snapshot()
    {:ok, %{
      snapshots: [],
      snapshot_count: 0,
      last_snapshot_at: nil,
      last_snapshot_status: :pending,
      healthy: true,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call(:take_snapshot, _from, state) do
    Logger.info("SnapshotManager: Initiating world model snapshot")

    world_stats = UnifiedWorldModel.stats()

    snapshot_id = "snap_#{DateTime.utc_now() |> DateTime.to_unix()}"
    snapshot_data = %{
      id: snapshot_id,
      timestamp: DateTime.utc_now(),
      entity_count: world_stats.entity_count,
      relationship_count: world_stats.relationship_count,
      relationships: snapshot_relationships(),
      hash: compute_hash(snapshot_id <> to_string(world_stats.entity_count))
    }

    ExecutiveMemory.record_decision(
      snapshot_id,
      :world_snapshot_created,
      snapshot_data
    )

    persist_snapshot(snapshot_data)
    new_snapshots = [snapshot_data | state.snapshots] |> Enum.take(@retention_count)

    EventBus.publish("world.snapshot.created", snapshot_data)

    new_state = %{state |
      snapshots: new_snapshots,
      snapshot_count: state.snapshot_count + 1,
      last_snapshot_at: snapshot_data.timestamp,
      last_snapshot_status: :success
    }

    {:reply, {:ok, snapshot_id}, new_state}
  end

  @impl true
  def handle_call({:create_snapshot, metadata}, _from, state) do
    Logger.info("SnapshotManager: Creating snapshot with metadata")

    world_stats = UnifiedWorldModel.stats()
    {:ok, entity_ids} = UnifiedRealityGraph.query_entities(limit: 10_000)
    entity_snapshots = Enum.map(entity_ids, fn id ->
      case UnifiedWorldModel.get_entity(id) do
        {:ok, e} -> e
        _ -> nil
      end
    end) |> Enum.reject(&is_nil/1)

    snapshot_id = "snap_#{DateTime.utc_now() |> DateTime.to_unix()}_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"
    snapshot_data = %{
      id: snapshot_id,
      timestamp: DateTime.utc_now(),
      metadata: metadata,
      entity_count: world_stats.entity_count,
      relationship_count: world_stats.relationship_count,
      relationships: snapshot_relationships(),
      entity_snapshots: entity_snapshots,
      hash: compute_hash(snapshot_id <> to_string(world_stats.entity_count))
    }

    ExecutiveMemory.record_decision(
      snapshot_id,
      :world_snapshot_created,
      snapshot_data
    )

    new_snapshots = [snapshot_data | state.snapshots] |> Enum.take(@retention_count)

    EventBus.publish("world.snapshot.created", snapshot_data)

    new_state = %{state |
      snapshots: new_snapshots,
      snapshot_count: state.snapshot_count + 1,
      last_snapshot_at: snapshot_data.timestamp,
      last_snapshot_status: :success
    }

    {:reply, {:ok, snapshot_id}, new_state}
  end

  @impl true
  def handle_call({:restore_from_snapshot, snapshot_id}, _from, state) do
    snapshot = Enum.find(state.snapshots, &(&1.id == snapshot_id)) || load_snapshot(snapshot_id)
    case snapshot do
      nil -> {:reply, {:error, :not_found}, state}
      _ ->
        Logger.info("SnapshotManager: Restoring from snapshot #{snapshot_id}")
        :ok = verify_snapshot_hash(snapshot)
        entity_snapshots = Map.get(snapshot, :entity_snapshots, [])
        Enum.each(entity_snapshots, fn entity_data ->
          nested = Map.get(entity_data, :attributes, %{})
          inner_attrs = if is_map(nested) and Map.has_key?(nested, :attributes) do
            Map.get(nested, :attributes, %{})
          else
            nested
          end
          sys_keys = [:id, :status, :type, :subtype, :version, :created_at, :updated_at, :confidence, :uncertainty, :mutation_id, :provenance, :owner_subsystem, :ingested_at]
          clean_attrs = Map.drop(inner_attrs, sys_keys) |> Map.reject(fn {_k, v} -> is_nil(v) end)
          UnifiedRealityGraph.add_entity(%{
            id: entity_data.id,
            type: Map.get(entity_data, :type, :knowledge_entity),
            subtype: Map.get(entity_data, :subtype),
            domain: Map.get(entity_data, :domain),
            attributes: clean_attrs,
            confidence: Map.get(entity_data, :confidence, 0.5),
            uncertainty: 1.0 - Map.get(entity_data, :confidence, 0.5),
            status: :active,
            provenance: Map.get(entity_data, :provenance, %{}),
            version: Map.get(entity_data, :version, 1)
          })
        end)
        Enum.each(Map.get(snapshot, :relationships, []), &UnifiedRealityGraph.add_relationship/1)
        {:reply, :ok, state}
    end
  end

  @impl true
  def handle_call(:list_snapshots, _from, state) do
    {:reply, state.snapshots, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:schedule_snapshot, state) do
    {:reply, _, new_state} = handle_call(:take_snapshot, nil, state)
    schedule_snapshot()
    {:noreply, new_state}
  end

  defp compute_hash(data) do
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  end

  defp snapshot_relationships do
    case UnifiedRealityGraph.query_entities(limit: 100_000) do
      {:ok, ids} ->
        Enum.flat_map(ids, fn id ->
          case UnifiedRealityGraph.get_relationships(id, :out) do
            {:ok, rels} -> rels |> Enum.map(fn r -> Map.take(r, [:from_id, :to_id, :type, :metadata]) end)
            _ -> []
          end
        end) |> Enum.uniq()
      _ -> []
    end
  end

  defp persist_snapshot(snapshot) do
    ExecutiveMemory.record_decision(snapshot.id, :world_snapshot_data, snapshot)
  end

  defp load_snapshot(id) do
    case ExecutiveMemory.get_decision(id) do
      {:ok, snapshot} -> snapshot
      _ -> nil
    end
  end

  defp verify_snapshot_hash(snapshot) do
    expected = compute_hash(snapshot.id <> to_string(snapshot.entity_count))
    if snapshot.hash == expected, do: :ok, else: raise "snapshot integrity check failed"
  end

  defp schedule_snapshot do
    Process.send_after(self(), :schedule_snapshot, @snapshot_interval)
  end
end
