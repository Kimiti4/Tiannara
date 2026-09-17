defmodule TiannaraRuntime.WorldModel.DigitalTwin.Engines.EventEngine do
  @moduledoc """
  Phase 17.7.3 — EventEngine.
  Schedules and executes deterministic simulation events.
  Supports engineering, policy, disaster, discovery, economic, medical, infrastructure, and environmental events.
  """

  alias TiannaraRuntime.WorldModel.DigitalTwin.SimulationEvent

  @doc """
  Schedules events for a simulation scenario.
  Returns {:ok, [SimulationEvent.t()]} or {:error, reason}.
  """
  def schedule(events) do
    sorted = Enum.sort_by(events, fn e -> {e.trigger_tick, e.event_id || ""} end)

    errors = Enum.filter(Enum.map(sorted, &validate_event/1), fn
      {:error, _reason} -> true
      _ -> false
    end)

    if errors == [] do
      {:ok, sorted}
    else
      {:error, :invalid_events, errors}
    end
  end

  @doc """
  Returns events due at a given tick.
  """
  def due_events(events, tick) do
    Enum.filter(events, fn e ->
      e.trigger_tick == tick && should_fire(e)
    end)
  end

  @doc """
  Applies an event's effects to the twin state.
  """
  def apply_event(event, twin_state) do
    new_model_states =
      Enum.reduce(event.effects, twin_state.model_states, fn {model_id, changes}, acc ->
        current = Map.get(acc, model_id, %{})
        Map.put(acc, model_id, Map.merge(current, changes))
      end)

    %{twin_state | model_states: new_model_states}
  end

  @doc """
  Validates a single event.
  """
  def validate_event(event) do
    cond do
      is_nil(event.name) -> {:error, :missing_name}
      is_nil(event.trigger_tick) -> {:error, :missing_trigger_tick}
      is_nil(event.effects) -> {:error, :missing_effects}
      true -> {:ok, true}
    end
  end

  defp should_fire(event) do
    case event.probability do
      nil -> true
      p when p >= 1.0 -> true
      p when p <= 0.0 -> false
      p -> :rand.uniform() <= p
    end
  end
end
