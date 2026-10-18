defmodule Tiannara.Engineering.Events do
  require Logger

  @prefix "engineering"

  @event_types [
    :insight_received, :design_generated, :design_evaluated,
    :design_approved, :design_rejected, :verification_planned,
    :verification_started, :verification_completed, :design_deployed,
    :engineering_completed,
    # L4 Engineering Proposal lifecycle events (phase.md Part II.1)
    :proposal_observed, :proposal_generated, :proposal_repaired,
    :proposal_verified, :proposal_queued, :proposal_reviewed,
    :proposal_approved, :proposal_rejected, :proposal_advanced
  ]

  def event_types, do: @event_types

  def topic(event_type) when event_type in @event_types do
    "#{@prefix}.#{event_type}"
  end

  def emit(event_type, design_id, data) when event_type in @event_types do
    event = %{event_type: event_type, topic: topic(event_type), design_id: design_id,
      data: data, timestamp: DateTime.utc_now(), source: :engineering_subsystem}

    # Best-effort emission stays non-failing (scan B1) but must never be
    # silent: a down EventBus or raising ExecutiveMemory now logs instead
    # of swallowing the event invisibly.
    case Process.whereis(Tiannara.CEL.Services.EventBus) do
      nil ->
        Logger.warning("[EngineeringEvents] EventBus not running; #{event.topic} not published (scan B1)")

      _pid ->
        try do
          Tiannara.CEL.Services.EventBus.publish(event.topic, event)
        rescue
          error ->
            Logger.warning("[EngineeringEvents] publish failed for #{event.topic}: #{inspect(error)} (scan B1)")
            :ok
        end
    end

    try do
      Tiannara.CEL.Services.ExecutiveMemory.record_event(:engineering, event_type,
        Map.put(data, :design_id, design_id))
    rescue
      error ->
        Logger.warning("[EngineeringEvents] ExecutiveMemory.record_event failed for #{event_type}: #{inspect(error)} (scan B1)")
        :ok
    end

    event
  end
end
