defmodule Tiannara.Discovery.Events do
  require Logger

  @event_prefix "discovery"

  def topic(event_type) when is_atom(event_type), do: "#{@event_prefix}.#{event_type}"

  def event_types do
    [:discovery_created, :gap_detected, :contradiction_detected,
     :hypothesis_generated, :prediction_created, :experiment_planned,
     :experiment_dispatched, :experiment_started, :experiment_completed,
     :evidence_collected, :belief_updated, :knowledge_promoted, :discovery_completed,
     :discovery_abandoned, :discovery_failed, :cycle_started,
     :cycle_completed, :cycle_failed]
  end

  def build(event_type, discovery_id, data) when event_type in [
    :discovery_created, :gap_detected, :contradiction_detected, :hypothesis_generated,
    :prediction_created, :experiment_planned, :experiment_dispatched, :experiment_started,
    :experiment_completed, :evidence_collected, :belief_updated, :knowledge_promoted,
    :discovery_completed, :discovery_abandoned, :discovery_failed, :cycle_started,
    :cycle_completed, :cycle_failed
  ] do
    %{event_type: event_type, topic: topic(event_type), discovery_id: discovery_id,
      data: data, timestamp: DateTime.utc_now(), source: :discovery_subsystem}
  end

  def emit(event_type, discovery_id, data) do
    event = build(event_type, discovery_id, data)
    # Best-effort emission stays non-failing (scan B1) but must never be
    # silent: a down EventBus or raising ExecutiveMemory now logs instead
    # of swallowing the event invisibly.
    case Process.whereis(Tiannara.CEL.Services.EventBus) do
      nil ->
        Logger.warning("[DiscoveryEvents] EventBus not running; #{event.topic} not published (scan B1)")

      _pid ->
        try do
          Tiannara.CEL.Services.EventBus.publish(event.topic, event)
        rescue
          error ->
            Logger.warning("[DiscoveryEvents] publish failed for #{event.topic}: #{inspect(error)} (scan B1)")
            :ok
        end
    end

    try do
      Tiannara.CEL.Services.ExecutiveMemory.record_event(:discovery, event_type, Map.put(data, :discovery_id, discovery_id))
    rescue
      error ->
        Logger.warning("[DiscoveryEvents] ExecutiveMemory.record_event failed for #{event_type}: #{inspect(error)} (scan B1)")
        :ok
    end
    event
  end
end
