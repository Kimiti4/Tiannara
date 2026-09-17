defmodule Tiannara.EventBus do
  @moduledoc """
  Loosely coupled ecological signaling bus.
  Uses Elixir's native Registry for PubSub message choreography.
  This allows MSCL, OLEF, CIS, P9X, and GRCC to communicate without
  hard recursive dependencies.
  """

  @registry_name Tiannara.EventRegistry

  @doc """
  Subscribe the calling process to a specific topic.
  """
  def subscribe(topic) do
    Registry.register(@registry_name, topic, [])
  end

  @doc """
  Broadcast an event to all processes subscribed to a topic.
  Also emits native `:telemetry` events for operational observability.
  """
  def broadcast(topic, event_name, payload \\ %{}) do
    # 1. Native Operational Telemetry
    telemetry_event_name = 
      case topic do
        t when is_binary(t) -> String.split(t, ".") |> Enum.map(&String.to_atom/1)
        t when is_atom(t) -> [t]
        _ -> [:tiannara, :unknown_topic]
      end
    
    :telemetry.execute([:tiannara, :event_bus] ++ telemetry_event_name, %{count: 1}, payload)

    # 2. Semantic Runtime Memory (PubSub)
    message = {event_name, payload}
    Registry.dispatch(@registry_name, topic, fn entries ->
      for {pid, _} <- entries, do: send(pid, message)
    end)
    
    :ok
  end
end
