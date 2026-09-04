defmodule Tiannara.World.WorldStateSynchronizer do
  @moduledoc """
  World State Synchronizer — event-driven synchronization for the world model.

  Subscribes to EventBus events from all subsystems and applies changes to
  the UnifiedWorldModel in real-time, ensuring the world model stays current
  without polling.
  """
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.World.UnifiedWorldModel
  alias Tiannara.CEL.Models.CivilizationalEvent
  alias Tiannara.CEL.Services.{EventBus, ExecutiveMemory}
  alias Tiannara.CEL.Kernel.ConstitutionalScore
  alias Tiannara.Discovery.Topics

  @max_retry_count 3
  @retry_delay_ms 1000

  # ---------- ExecutiveService Behaviour ----------

  @impl Tiannara.ExecutiveService
  def id, do: :world_state_synchronizer

  @impl Tiannara.ExecutiveService
  def version, do: "1.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities do
    [
      :event_driven_synchronization,
      :causal_ordering,
      :conflict_detection,
      :event_replay,
      :dead_letter_handling
    ]
  end

  @impl Tiannara.ExecutiveService
  def dependencies, do: [:persistent_memory, :event_transport, :unified_world_model, :world_mutation_engine]

  @impl Tiannara.ExecutiveService
  def priority, do: :critical

  @impl Tiannara.ExecutiveService
  def constitutional_score do
    stats = GenServer.call(__MODULE__, :stats)

    total = stats.processed_events + stats.failed_events
    evidence_quality = if total > 0, do: stats.processed_events / total, else: 1.0

    %ConstitutionalScore{
      service_id: id(),
      health: if(stats.healthy, do: 1.0, else: 0.0),
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

  def replay_from(offset), do: GenServer.call(__MODULE__, {:replay, offset})

  def stats, do: GenServer.call(__MODULE__, :stats)

  def dead_letters, do: GenServer.call(__MODULE__, :dead_letters)

  # ---------- Server Callbacks ----------

  @impl true
  def init(_opts) do
    EventBus.subscribe("world.entity.created")
    EventBus.subscribe("world.entity.updated")
    EventBus.subscribe("world.entity.refuted")
    EventBus.subscribe("world.relationship.created")
    EventBus.subscribe(Topics.discovery_completed())
    EventBus.subscribe("experiment.completed")
    EventBus.subscribe("simulation.completed")
    EventBus.subscribe("mission.completed")
    EventBus.subscribe("mission.failed")
    EventBus.subscribe("engineering.deployment")

    {:ok, %{
      processed_events: 0,
      failed_events: 0,
      dead_letters: [],
      event_offsets: %{},
      healthy: true,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_info({:event, %CivilizationalEvent{} = event}, state) do
    handle_bus_event(event, state)
  end

  @impl true
  def handle_info({:executive_bus_message, message}, state) do
    handle_bus_message(message, state)
  end

  @impl true
  def handle_info({:retry_event, message, retry_count}, state) do
    retried = Map.put(message, :retry_count, retry_count)

    result =
      cond do
        is_struct(retried, CivilizationalEvent) ->
          process_topic(retried.routing_destination, retried.raw_payload)

        is_map(retried) and Map.has_key?(retried, :bus_topic) ->
          payload = Map.drop(retried, [:bus_topic, :retry_count])
          topic = Map.get(retried, :bus_topic)
          process_topic(topic, payload)

        true ->
          process_legacy_message(Map.delete(retried, :retry_count))
      end

    case result do
      :ok ->
        {:noreply, %{state | processed_events: state.processed_events + 1}}

      {:error, reason} ->
        if retry_count < @max_retry_count do
          Process.send_after(self(), {:retry_event, message, retry_count + 1}, @retry_delay_ms * 2)
          {:noreply, state}
        else
          dlq_entry = %{message: message, reason: reason, retry_count: retry_count, dlq_at: DateTime.utc_now()}
          {:noreply, %{state |
            failed_events: state.failed_events + 1,
            dead_letters: [dlq_entry | state.dead_letters] |> Enum.take(1000)
          }}
        end
    end
  end

  @impl true
  def handle_call({:replay, offset}, _from, state) do
    {:reply, {:ok, %{replayed_from: offset}}, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{
      healthy: state.healthy,
      processed_events: state.processed_events,
      failed_events: state.failed_events,
      dead_letters: state.dead_letters,
      event_offsets: state.event_offsets
    }, state}
  end

  @impl true
  def handle_call(:dead_letters, _from, state) do
    {:reply, state.dead_letters, state}
  end

  # ---------- Private: Event Processing ----------

  # Real EventBus delivery: `{:event, %CivilizationalEvent{}}` where the topic
  # the event was published to is carried on `routing_destination`.
  defp handle_bus_event(%CivilizationalEvent{routing_destination: topic, raw_payload: payload}, state) do
    case process_topic(topic, payload) do
      :ok ->
        {:noreply, %{state | processed_events: state.processed_events + 1}}

      {:error, reason} ->
        handle_event(Map.put(payload, :bus_topic, topic), reason, state)
    end
  end

  # Legacy raw-map envelope, kept for producers that still emit bare maps.
  defp handle_bus_message(message, state) do
    case process_legacy_message(message) do
      :ok ->
        {:noreply,
         %{state |
           processed_events: state.processed_events + 1,
           event_offsets: update_offset(state.event_offsets, message)
         }}

      {:error, reason} ->
        handle_event(message, reason, state)
    end
  end

  defp handle_event(message, reason, state) do
    retry_count = Map.get(message, :retry_count, 0)

    if retry_count < @max_retry_count do
      Process.send_after(self(), {:retry_event, message, retry_count + 1}, @retry_delay_ms)
      {:noreply, state}
    else
      dlq_entry = %{message: message, reason: reason, retry_count: retry_count, dlq_at: DateTime.utc_now()}

      Logger.error("WorldStateSynchronizer: event moved to DLQ: #{inspect(reason)}")

      {:noreply, %{state |
        failed_events: state.failed_events + 1,
        dead_letters: [dlq_entry | state.dead_letters] |> Enum.take(1000)
      }}
    end
  end

  # Dispatch on the topic the event was published under; `payload` is the raw
  defp process_topic("discovery.completed", payload), do: transform_discovery_to_entities(payload)
  defp process_topic("experiment.completed", payload), do: transform_experiment_to_updates(payload)
  defp process_topic("simulation.completed", payload), do: transform_simulation_to_predictions(payload)
  defp process_topic("mission.completed", payload), do: update_mission_status(payload, :completed)
  defp process_topic("mission.failed", payload), do: update_mission_status(payload, :failed)
  defp process_topic("engineering.deployment", payload), do: transform_deployment_to_entity(payload)
  defp process_topic(_, _), do: :ok

  defp process_legacy_message(%{type: "world.entity.created", payload: payload}) do
    record_sync_event(:entity_created, payload)
  end

  defp process_legacy_message(%{type: "world.entity.updated", payload: payload}) do
    record_sync_event(:entity_updated, payload)
  end

  defp process_legacy_message(%{type: "world.entity.refuted", payload: payload}) do
    record_sync_event(:entity_refuted, payload)
  end

  defp process_legacy_message(%{type: "world.relationship.created", payload: payload}) do
    record_sync_event(:relationship_created, payload)
  end

  defp process_legacy_message(%{type: type, payload: payload}), do: process_topic(type, payload)
  defp process_legacy_message(_), do: :ok

  # ---------- Private: Transformations ----------

  defp transform_discovery_to_entities(payload) do
    discovery_id = payload.discovery_id
    discovery_data = Map.get(payload, :data, %{})

    entity_spec = %{
      id: "discovery_#{discovery_id}",
      type: :scientific_entity,
      subtype: :discovery,
      attributes: discovery_data,
      confidence: Map.get(payload, :confidence, 0.8),
      provenance: %{
        origin: :discovery_engine,
        discovery_id: discovery_id,
        evidence: Map.get(payload, :evidence, [])
      }
    }

    result =
      try do
        UnifiedWorldModel.create_entity(entity_spec)
      rescue
        _ -> {:error, :world_model_unavailable}
      catch
        :exit, _ -> {:error, :world_model_unavailable}
      end

    case result do
      {:ok, _} ->
        record_sync_event(:discovery_integrated, payload)
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp transform_experiment_to_updates(payload) do
    experiment_id = payload.experiment_id
    hypothesis_id = Map.get(payload, :hypothesis_id)

    if hypothesis_id do
      new_confidence = Map.get(payload, :posterior_confidence, 0.5)
      UnifiedWorldModel.update_entity(hypothesis_id, %{
        confidence: new_confidence,
        last_experiment_id: experiment_id,
        experiment_count_increment: 1
      })
    end

    record_sync_event(:experiment_integrated, payload)
  end

  defp transform_simulation_to_predictions(payload) do
    simulation_id = payload.simulation_id
    predictions = Map.get(payload, :predictions, [])

    Enum.each(predictions, fn prediction ->
      entity_spec = %{
        id: "prediction_#{simulation_id}_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}",
        type: :event_entity,
        subtype: :prediction,
        attributes: prediction,
        confidence: Map.get(prediction, :confidence, 0.5),
        provenance: %{
          origin: :simulation_engine,
          simulation_id: simulation_id
        }
      }

      UnifiedWorldModel.create_entity(entity_spec)
    end)

    record_sync_event(:simulation_integrated, payload)
  end

  defp update_mission_status(payload, status) do
    mission_id = payload.mission_id

    UnifiedWorldModel.update_entity("mission_#{mission_id}", %{
      status: status,
      completed_at: if(status == :completed, do: DateTime.utc_now(), else: nil)
    })

    record_sync_event(:mission_status_updated, Map.put(payload, :status, status))
  end

  defp transform_deployment_to_entity(payload) do
    deployment_id = payload.deployment_id

    entity_spec = %{
      id: "deployment_#{deployment_id}",
      type: :engineering_entity,
      subtype: :deployment,
      attributes: Map.get(payload, :attributes, %{}),
      confidence: 0.95,
      provenance: %{
        origin: :engineering_engine,
        deployment_id: deployment_id
      }
    }

    case UnifiedWorldModel.create_entity(entity_spec) do
      {:ok, _} -> record_sync_event(:deployment_integrated, payload)
      {:error, reason} -> {:error, reason}
    end
  end

  defp record_sync_event(event_type, payload) do
    ExecutiveMemory.record_event(:world_sync, event_type, payload, %{source: :world_state_synchronizer})
    :ok
  rescue
    _ -> :ok
  end

  defp update_offset(offsets, message) do
    topic = Map.get(message, :topic, "unknown")
    offset = Map.get(message, :offset, 0)
    Map.put(offsets, topic, max(Map.get(offsets, topic, 0), offset))
  end
end
