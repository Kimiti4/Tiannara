defmodule Tiannara.Simulation.Events do
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

    case Process.whereis(Tiannara.CEL.Services.EventBus) do
      nil -> :ok
      _pid ->
        try do
          Tiannara.CEL.Services.EventBus.publish(event.topic, event)
        rescue _ -> :ok end
    end

    try do
      Tiannara.CEL.Services.ExecutiveMemory.record_event(:simulation, event_type,
        Map.put(data, :entity_id, entity_id))
    rescue _ -> :ok end

    event
  end
end
