defmodule Tiannara.HAI.HAIEvents do
  @prefix "hai"

  @event_types [
    :review_submitted, :review_resolved, :explanation_generated,
    :trace_requested, :presentation_generated, :human_override,
    :mandatory_review_bypass_attempted
  ]

  def event_types, do: @event_types

  def topic(event_type) when event_type in @event_types do
    "#{@prefix}.#{event_type}"
  end

  def emit(event_type, entity_id, data) when event_type in @event_types do
    event = %{event_type: event_type, topic: topic(event_type), entity_id: entity_id,
      data: data, timestamp: DateTime.utc_now(), source: :human_augmentation_interface}

    case Process.whereis(Tiannara.CEL.Services.EventBus) do
      nil -> :ok
      _pid ->
        try do
          Tiannara.CEL.Services.EventBus.publish(event.topic, event)
        rescue _ -> :ok end
    end

    try do
      Tiannara.CEL.Services.ExecutiveMemory.record_event(:hai, event_type,
        Map.put(data, :entity_id, entity_id))
    rescue _ -> :ok end

    event
  end
end
