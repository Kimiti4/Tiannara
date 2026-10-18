defmodule Tiannara.Simulation.Events do
  require Logger

  @prefix "simulation"

  @event_types [
    :scenario_created, :scenario_validated, :simulation_started,
    :horizon_forecasted, :impact_assessed, :comparison_completed,
    :deployment_plan_generated, :simulation_completed, :simulation_failed
  ]

  def event_types, do: @event_types

  def topic(event_type) when event_type in @event_types do
    "#{@prefix}.#{event_type}"
  end

  def emit(event_type, entity_id, data) when event_type in @event_types do
    event = %{event_type: event_type, topic: topic(event_type), entity_id: entity_id,
      data: data, timestamp: DateTime.utc_now(), source: :simulation_subsystem}

    # Best-effort emission stays non-failing (scan B1) but must never be
    # silent: a down EventBus or raising ExecutiveMemory now logs instead
    # of swallowing the event invisibly.
    case Process.whereis(Tiannara.CEL.Services.EventBus) do
      nil ->
        Logger.warning("[SimulationEvents] EventBus not running; #{event.topic} not published (scan B1)")

      _pid ->
        try do
          Tiannara.CEL.Services.EventBus.publish(event.topic, event)
        rescue
          error ->
            Logger.warning("[SimulationEvents] publish failed for #{event.topic}: #{inspect(error)} (scan B1)")
            :ok
        end
    end

    try do
      Tiannara.CEL.Services.ExecutiveMemory.record_event(:simulation, event_type,
        Map.put(data, :entity_id, entity_id))
    rescue
      error ->
        Logger.warning("[SimulationEvents] ExecutiveMemory.record_event failed for #{event_type}: #{inspect(error)} (scan B1)")
        :ok
    end

    event
  end
end
